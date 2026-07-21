import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_session.dart';
import '../core/constants/app_colors.dart';
import '../core/immersive_mode_provider.dart';
import '../core/theme/app_typography.dart';
import '../features/collection/providers/card_collection_provider.dart';
import '../features/daily/widgets/level_up_overlay.dart';
import '../features/daily/widgets/streak_milestone_overlay.dart';
import '../features/quests/providers/quests_provider.dart';
import '../features/quests/widgets/first_steps_overlay.dart';
import '../features/tour/models/onboarding_tour_step.dart';
import '../features/tour/providers/deferred_celebrations_provider.dart';
import '../features/tour/providers/onboarding_tour_controller.dart'
    show
        onboardingTourControllerProvider,
        tourActiveRouteProvider;
import '../features/tour/providers/tour_route_observer.dart';
import '../services/analytics_events.dart';
import '../services/analytics_provider.dart';
import '../services/economy_events.dart';
import '../services/xp_service.dart';
import '../widgets/achievement_toast.dart';
import '../widgets/coachmark/tour_anchor.dart';
import '../widgets/quest_completion_toast.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  StreamSubscription<EconomyEvent>? _econSub;

  @override
  void initState() {
    super.initState();
    _econSub = EconomyEvents.stream.listen((event) {
      if (event is XpGranted) {
        // Analytics — fire for EVERY XP grant (the recurring engagement
        // signal), plus a discrete level_up when the grant crossed a
        // threshold. Wrapped so a track() failure can't break the overlay
        // logic below. `ref` is the persistent ConsumerState ref.
        try {
          final analytics = ref.read(analyticsProvider);
          analytics.track(AnalyticsEvents.xpAwarded, properties: {
            'amount': event.amount,
            'source': event.source.name,
            'new_total': event.newTotal,
          });
          if (event.leveledUp) {
            final toLevel = event.newState.level;
            // rewards is non-null whenever leveledUp is true (xp_service couples
            // them), so the first branch always wins for real level-ups; the
            // fallback is defensive only.
            final fromLevel = event.rewards != null
                ? toLevel - event.rewards!.levelsGained
                : toLevel - 1;
            analytics.track(AnalyticsEvents.levelUp, properties: {
              'from_level': fromLevel,
              'to_level': toLevel,
            });
          }
        } catch (_) {}
      }
      if (event is XpGranted && event.leveledUp && event.rewards != null) {
        // Use addPostFrameCallback (NOT microtask) to match muhasabah_screen's
        // streak-milestone push timing. Microtasks run BEFORE post-frame
        // callbacks, which would let the level-up overlay race ahead of the
        // streak milestone overlay on same-tick events. Pinned by the
        // race-ordering regression test.
        //
        // Capture locals before the callback — the event object may be GC'd
        // by the time the callback fires, and closure-capturing `event` in a
        // post-frame callback is safe but capturing the fields is cleaner.
        final rewards = event.rewards!;
        final newState = event.newState;
        // Defer the rank-up modal while the guided tour is running — it's a
        // blocking route that would interrupt the coachmark flow. Replayed on
        // first home arrival after the tour. See deferred_celebrations_provider.
        if (shouldDeferCelebrations(ref)) {
          ref
              .read(deferredCelebrationsProvider.notifier)
              .enqueue(LevelUpCelebration(newState, rewards));
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _pushLevelUpOverlay(newState, rewards);
          });
          // Ensure a frame is scheduled so the post-frame callback fires even
          // when the stream event arrives outside of an active build cycle
          // (e.g. from a background async operation between pumps in tests,
          // or from a service callback that doesn't trigger a Riverpod rebuild).
          WidgetsBinding.instance.scheduleFrame();
        }
      }
    });
  }

  @override
  void dispose() {
    _econSub?.cancel();
    super.dispose();
  }

  /// Returns the push future so the deferred-celebration drain can await
  /// dismissal before showing the next celebration.
  Future<void> _pushLevelUpOverlay(XpState xpState, LevelUpRewards rewards) {
    final nav = Navigator.of(context, rootNavigator: true);
    return nav.push(
      PageRouteBuilder(
        settings: const RouteSettings(name: 'LevelUpOverlay'),
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => LevelUpOverlay(
          levelNumber: xpState.level,
          title: xpState.title,
          titleArabic: xpState.titleArabic,
          rewards: rewards,
          onContinue: nav.pop,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Pushes the First Steps bundle celebration. Returns the push future (for
  /// the deferred drain) and clears the pending flag when dismissed.
  Future<void> _pushFirstStepsOverlay(int tokens, int scrolls) {
    final navigator = Navigator.of(context, rootNavigator: true);
    return navigator
        .push(
          MaterialPageRoute(
            settings: const RouteSettings(name: 'FirstStepsOverlay'),
            fullscreenDialog: true,
            builder: (_) => FirstStepsOverlay(
              tokensAwarded: tokens,
              scrollsAwarded: scrolls,
            ),
          ),
        )
        .whenComplete(() {
          ref.read(questsProvider.notifier).clearPendingBundleCelebration();
        });
  }

  /// Pushes the streak-milestone celebration overlay drained from the deferred
  /// queue. The milestone was enqueued by muhasabah_screen's `onReturnHome`
  /// callback when the user backed out of BeatRevealFlow before tapping Ameen.
  /// Awaited so subsequent celebrations show sequentially. clearStreakMilestone
  /// already ran at enqueue time (in onReturnHome) to prevent double-fire on
  /// any future navigation back to muhasabah.
  Future<void> _pushStreakMilestoneOverlay(StreakMilestoneCelebration c) {
    final nav = Navigator.of(context, rootNavigator: true);
    return nav.push(
      PageRouteBuilder(
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => StreakMilestoneOverlay(
          streakCount: c.streak,
          xpAwarded: c.xp,
          scrollsAwarded: c.scrolls,
          onContinue: nav.pop,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Drains celebrations withheld during the tour, once, on the first home
  /// arrival after the tour (and its trailing paywall) clears. Modals show
  /// one-at-a-time (awaited) so the headline rewards lead; ambient toasts then
  /// flush through the existing sequential toast queue.
  bool _draining = false;
  void _maybeDrainDeferredCelebrations() {
    if (_draining || !mounted) return;
    // Only once the tour is fully resolved and no blocking modal is on top.
    if (ref.read(onboardingTourControllerProvider).isActive) return;
    if (tourRouteObserver.isBlockingRouteOnTop) return;
    // BUG B FIX: do not drain while the onboarding gate still owes a hard
    // paywall. After the tour completes the stage is `hardPaywall` (tour done,
    // wall not cleared); the router is about to push the paywall route. If we
    // drain in that brief home-mount gap, the level-up modal pushes, then the
    // paywall covers it — its `await _pushLevelUpOverlay` never completes, so
    // the toast-flush loop after it never runs and the achievement/quest toasts
    // are lost (the reported bug: level-up shows pre-paywall, no toasts after).
    // Mirror resolveOnboardingStage's app-vs-gate test: only drain once the gate
    // is fully resolved to `app` (paywall cleared / premium / bypass / flow off).
    // Defensive: a failure reading the session must not strand the queued
    // celebrations (and the test harness doesn't always override the provider).
    bool gatePending = false;
    try {
      final session = ref.read(appSessionProvider);
      gatePending = session.hardPaywallFlowEnabled &&
          !session.paywallCleared &&
          !session.gateValveBypass &&
          !session.isPremiumCached;
    } catch (_) {
      gatePending = false;
    }
    if (gatePending) return;
    final items = ref.read(deferredCelebrationsProvider.notifier).takeAll();
    if (items.isEmpty) return;
    _draining = true;
    () async {
      try {
        for (final c in items) {
          if (!mounted) return;
          if (c is LevelUpCelebration) {
            await _pushLevelUpOverlay(c.xpState, c.rewards);
          } else if (c is FirstStepsCelebration) {
            await _pushFirstStepsOverlay(c.tokens, c.scrolls);
          } else if (c is StreakMilestoneCelebration) {
            await _pushStreakMilestoneOverlay(c);
          }
        }
        if (!mounted) return;
        for (final c in items) {
          if (c is AchievementToastCelebration) {
            showAchievementToast(c.achievement);
          } else if (c is QuestToastCelebration) {
            showQuestCompletionToast(c.quest);
          }
        }
      } finally {
        _draining = false;
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    // Bundle celebration: show overlay no matter which tab the user is on.
    ref.listen<QuestsState>(questsProvider, (prev, next) {
      final celebration = next.pendingBundleCelebration;
      if (celebration != null && prev?.pendingBundleCelebration == null) {
        final tokens = celebration.tokens;
        final scrolls = celebration.scrolls;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // Defer during the tour; otherwise show now (clears pending on
          // dismiss). When deferring, clear pending immediately so it can't
          // re-fire, and replay from the queue after the tour.
          if (shouldDeferCelebrations(ref)) {
            ref.read(deferredCelebrationsProvider.notifier).enqueue(
                  FirstStepsCelebration(tokens: tokens, scrolls: scrolls),
                );
            ref.read(questsProvider.notifier).clearPendingBundleCelebration();
          } else {
            _pushFirstStepsOverlay(tokens, scrolls);
          }
        });
      }
    });

    // Quest completion toasts: react when pendingCompletions becomes non-empty.
    ref.listen<QuestsState>(questsProvider, (prev, next) {
      if (next.pendingCompletions.isNotEmpty &&
          (prev?.pendingCompletions.isEmpty ?? true)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final quests =
              ref.read(questsProvider.notifier).consumePendingCompletions();
          final analytics = ref.read(analyticsProvider);
          // Analytics always fires (the quest really completed); only the toast
          // is withheld during the tour and replayed afterward.
          final defer = shouldDeferCelebrations(ref);
          for (final quest in quests) {
            // Wrapped so a telemetry throw can't skip the toast / break the loop.
            try {
              analytics.track(AnalyticsEvents.questCompleted, properties: {
                'quest_id': quest.id,
                'quest_type': AnalyticsEvents.questTypeStandard,
                'xp_reward': quest.xpReward,
                'token_reward': quest.tokenReward,
              });
            } catch (_) {}
            if (defer) {
              ref
                  .read(deferredCelebrationsProvider.notifier)
                  .enqueue(QuestToastCelebration(quest));
            } else {
              showQuestCompletionToast(quest);
            }
          }
        });
      }
    });

    // First Steps beginner quest completion toasts.
    ref.listen<QuestsState>(questsProvider, (prev, next) {
      final beginner = next.pendingBeginnerCompletion;
      if (beginner != null && prev?.pendingBeginnerCompletion == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Wrapped so a telemetry throw can't skip the toast below.
          try {
            ref.read(analyticsProvider).track(
              AnalyticsEvents.questCompleted,
              properties: {
                'quest_id': beginner.id.key,
                'quest_type': AnalyticsEvents.questTypeBeginner,
                'xp_reward': beginner.xpReward,
                'token_reward': beginner.tokenReward,
              },
            );
          } catch (_) {}
          final quest = Quest(
            id: beginner.id.key,
            cadence: QuestCadence.daily,
            title: beginner.title,
            description: beginner.description,
            icon: beginner.icon,
            xpReward: beginner.xpReward,
            tokenReward: beginner.tokenReward,
            scrollReward: beginner.scrollReward,
            poolIndex: -1,
            target: 0,
          );
          if (shouldDeferCelebrations(ref)) {
            ref
                .read(deferredCelebrationsProvider.notifier)
                .enqueue(QuestToastCelebration(quest));
          } else {
            showQuestCompletionToast(quest);
          }
          ref
              .read(questsProvider.notifier)
              .clearPendingBeginnerCompletion();
        });
      }
    });

    // Replay any celebrations withheld during the tour, once we're back on a
    // normal tab screen (AppShell only builds for tab routes, so reaching here
    // after the tour means its trailing paywall has cleared). Post-frame so the
    // navigator is settled before we push the replay modals.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeDrainDeferredCelebrations();
    });

    // Publish the current route path so the guided-tour overlay host can
    // advance `navigate`-trigger steps (the bottom-nav tab steps) on the
    // actual route change rather than a racy icon pointer-Listener (Bug 1).
    // Written post-frame so we don't mutate a provider during this build.
    final currentPath = GoRouterState.of(context).uri.path;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(tourActiveRouteProvider) != currentPath) {
        ref.read(tourActiveRouteProvider.notifier).state = currentPath;
      }
    });

    final tabIndex = _currentIndex(context);
    final isOffTab = tabIndex < 0;

    // Immersive surfaces (the beat reveal flow) hide the bottom nav so the
    // emerald canvas fills the whole screen. The Scaffold gives the body full
    // height when bottomNavigationBar is null.
    final immersive = ref.watch(immersiveModeProvider);
    // Unseen tier-cards drive a badge on the Collection tab, so a fresh grant
    // (e.g. the premium Emerald retro-bump) is discoverable from anywhere — the
    // on-tile shimmer alone is too easy to miss.
    // select() so the shell only rebuilds when the count itself changes, not on
    // every collection mutation. Cap the label at 99+ so a 3-digit count (a
    // day-one premium user can have many unseen tiers) doesn't overflow the badge.
    final unseenCards =
        ref.watch(cardCollectionProvider.select((s) => s.unseenCount));
    Widget collectionTabIcon(Widget inner) => Badge(
          isLabelVisible: unseenCards > 0,
          backgroundColor: AppColors.primary,
          textColor: Colors.white,
          label: Text(unseenCards > 99 ? '99+' : '$unseenCards'),
          child: inner,
        );

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: immersive
          ? null
          : BottomNavigationBar(
        // BottomNavigationBar requires a valid index. When the user is on a
        // pushed sub-route (e.g. /quests, /settings, /store) we still need
        // to pass a legal index, but we visually deselect everything by
        // collapsing selected/unselected colors so no tab looks active.
        currentIndex: isOffTab ? 0 : tabIndex,
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor:
            isOffTab ? AppColors.textTertiaryLight : AppColors.primary,
        unselectedItemColor: AppColors.textTertiaryLight,
        selectedLabelStyle:
            isOffTab ? AppTypography.bodySmall : AppTypography.labelMedium,
        unselectedLabelStyle: AppTypography.bodySmall,
        // When off-tab, use the outlined icon as activeIcon too so no tab
        // appears filled/selected. This keeps BottomNavigationBar happy
        // (still needs a valid currentIndex) without lying to the user
        // about where they are.
        items: [
          BottomNavigationBarItem(
            icon: const TourAnchor(
              surface: TourSurface.appShell,
              anchorId: 'tabHome',
              child: Icon(Icons.home_outlined),
            ),
            activeIcon:
                Icon(isOffTab ? Icons.home_outlined : Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: collectionTabIcon(const TourAnchor(
              surface: TourSurface.appShell,
              anchorId: 'tabCollection',
              child: Icon(Icons.style_outlined),
            )),
            activeIcon: collectionTabIcon(
                Icon(isOffTab ? Icons.style_outlined : Icons.style)),
            label: 'Collection',
          ),
          BottomNavigationBarItem(
            icon: const TourAnchor(
              surface: TourSurface.appShell,
              anchorId: 'tabReflect',
              child: Icon(Icons.favorite_outline),
            ),
            activeIcon:
                Icon(isOffTab ? Icons.favorite_outline : Icons.favorite),
            label: 'Reflect',
          ),
          BottomNavigationBarItem(
            icon: const TourAnchor(
              surface: TourSurface.appShell,
              anchorId: 'tabDuas',
              child: Icon(Icons.auto_awesome_outlined),
            ),
            activeIcon: Icon(
                isOffTab ? Icons.auto_awesome_outlined : Icons.auto_awesome),
            label: 'Duas',
          ),
          BottomNavigationBarItem(
            icon: const TourAnchor(
              surface: TourSurface.appShell,
              anchorId: 'tabJournal',
              child: Icon(Icons.book_outlined),
            ),
            activeIcon: Icon(isOffTab ? Icons.book_outlined : Icons.book),
            label: 'Journal',
          ),
        ],
      ),
    );
  }

  /// Returns the bottom-nav index for tab routes, or `-1` for pushed
  /// sub-routes that live inside the shell but aren't tabs (Quests,
  /// Settings, Store). The shell uses `-1` to deselect every tab so the
  /// nav bar doesn't claim the user is on Home when they aren't.
  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/collection')) return 1;
    if (location.startsWith('/reflect')) return 2;
    if (location.startsWith('/duas')) return 3;
    if (location.startsWith('/journal')) return 4;
    if (location.startsWith('/quests') ||
        location.startsWith('/settings') ||
        location.startsWith('/store')) {
      return -1;
    }
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/collection');
      case 2:
        context.go('/reflect');
      case 3:
        context.go('/duas');
      case 4:
        context.go('/journal');
    }
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../features/daily/widgets/level_up_overlay.dart';
import '../features/quests/providers/quests_provider.dart';
import '../features/quests/widgets/first_steps_overlay.dart';
import '../features/tour/providers/tab_bar_key_provider.dart';
import '../services/economy_events.dart';
import '../services/xp_service.dart';
import '../widgets/quest_completion_toast.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  StreamSubscription<EconomyEvent>? _econSub;
  // GlobalKey for the bottom tab bar — published into `tabBarKeyProvider`
  // so the Home tour's 3rd coachmark can anchor to it. Per eng review 1.5,
  // ownership stays here (per-screen) rather than in a global TourKeys
  // provider.
  final GlobalKey _tabBarKey = GlobalKey(debugLabel: 'tour.tabBar');
  // Cached notifier so dispose() doesn't have to call `ref.read` (which
  // throws once the ConsumerStatefulElement is disposed). Set in the
  // post-frame callback below alongside the publish.
  StateController<GlobalKey?>? _tabBarKeyController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = ref.read(tabBarKeyProvider.notifier);
      _tabBarKeyController = controller;
      controller.state = _tabBarKey;
    });
    _econSub = EconomyEvents.stream.listen((event) {
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
    });
  }

  @override
  void dispose() {
    _econSub?.cancel();
    // Only clear if our key is still the published one — avoids stomping on
    // a fresh AppShell that already registered its own key during a
    // hot-reload remount. Use the cached controller so we don't touch `ref`
    // after the ConsumerStatefulElement is disposed (which throws).
    final controller = _tabBarKeyController;
    if (controller != null && controller.state == _tabBarKey) {
      controller.state = null;
    }
    super.dispose();
  }

  void _pushLevelUpOverlay(XpState xpState, LevelUpRewards rewards) {
    final nav = Navigator.of(context, rootNavigator: true);
    nav.push(
      PageRouteBuilder(
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

  @override
  Widget build(BuildContext context) {
    // Bundle celebration: show overlay no matter which tab the user is on.
    ref.listen<QuestsState>(questsProvider, (prev, next) {
      final celebration = next.pendingBundleCelebration;
      if (celebration != null && prev?.pendingBundleCelebration == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final navigator = Navigator.of(context, rootNavigator: true);
          navigator
              .push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => FirstStepsOverlay(
                    tokensAwarded: celebration.tokens,
                    scrollsAwarded: celebration.scrolls,
                  ),
                ),
              )
              .whenComplete(() {
                ref
                    .read(questsProvider.notifier)
                    .clearPendingBundleCelebration();
              });
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
          for (final quest in quests) {
            showQuestCompletionToast(quest);
          }
        });
      }
    });

    // First Steps beginner quest completion toasts.
    ref.listen<QuestsState>(questsProvider, (prev, next) {
      final beginner = next.pendingBeginnerCompletion;
      if (beginner != null && prev?.pendingBeginnerCompletion == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showQuestCompletionToast(Quest(
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
          ));
          ref
              .read(questsProvider.notifier)
              .clearPendingBeginnerCompletion();
        });
      }
    });

    final tabIndex = _currentIndex(context);
    final isOffTab = tabIndex < 0;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        key: _tabBarKey,
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
            icon: const Icon(Icons.home_outlined),
            activeIcon:
                Icon(isOffTab ? Icons.home_outlined : Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.style_outlined),
            activeIcon:
                Icon(isOffTab ? Icons.style_outlined : Icons.style),
            label: 'Collection',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_outline),
            activeIcon:
                Icon(isOffTab ? Icons.favorite_outline : Icons.favorite),
            label: 'Reflect',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(
                isOffTab ? Icons.auto_awesome_outlined : Icons.auto_awesome),
            label: 'Duas',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book_outlined),
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

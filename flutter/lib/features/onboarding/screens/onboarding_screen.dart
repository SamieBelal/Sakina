import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_session.dart';
import '../../../core/env.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/analytics_events.dart';
import '../../../services/app_config_service.dart';
import '../providers/onboarding_provider.dart';
import 'age_range_screen.dart';
import 'aspirations_screen.dart';
import 'attribution_screen.dart';
import 'commitment_pact_screen.dart';
import 'common_emotions_screen.dart';
import 'daily_commitment_screen.dart';
import 'dua_topics_screen.dart';
import 'encouragement_screen.dart';
import 'familiarity_screen.dart';
import 'first_checkin_screen.dart';
import 'generating_screen.dart';
import 'intention_screen.dart';
import 'name_input_screen.dart';
import 'notification_screen.dart';
import 'paywall_screen.dart';
import 'personalized_plan_screen.dart';
import 'prayer_frequency_screen.dart';
import 'quran_connection_screen.dart';
import 'rating_gate_screen.dart';
import 'reminder_time_screen.dart';
import 'save_progress_screen.dart';
import 'sign_up_email_screen.dart';
import 'sign_up_password_screen.dart';
import 'social_proof_screen.dart';
import 'struggle_support_interstitial_screen.dart';
import 'value_prop_screen.dart';
import 'your_journey_screen.dart';

/// Returns true when [resumedAt] is more than 24 hours after [pausedAt].
/// Extracted as a top-level helper so the abandonment threshold logic is
/// directly unit-testable (see test/features/onboarding/abandonment_telemetry_test.dart).
@visibleForTesting
bool shouldFireAbandonment({
  required DateTime pausedAt,
  required DateTime resumedAt,
}) {
  return resumedAt.difference(pausedAt) > const Duration(hours: 24);
}

/// Last valid page index for the active onboarding flow. Trimmed flow ends at
/// [onboardingLastPageIndex] (19/18); legacy at [onboardingLegacyLastPageIndex]
/// (26/25). Pure top-level fn so the dual-flow bound (used by `_next`, the
/// paywall-event triggers, and the abandonment paywall gate) is directly
/// unit-testable without driving the full PageView. See
/// test/features/onboarding/onboarding_dual_flow_test.dart.
@visibleForTesting
int activeOnboardingLastPageIndex({required bool trimmed}) =>
    trimmed ? onboardingLastPageIndex : onboardingLegacyLastPageIndex;

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  late final Future<bool> _useTrimmedFlowFuture;
  // Resolved flow: trimmed (default, 20 pages) vs legacy (27 pages). Starts
  // optimistic-true to match the FutureBuilder default, then corrected once
  // `_useTrimmedFlowFuture` resolves. Used by `_next`, the abandonment gate,
  // and the paywall-event triggers so they reference the ACTIVE flow's last
  // index instead of the hardcoded trimmed index.
  bool _trimmed = true;
  bool _navigating = false;
  bool _paywallEventsFired = false;
  final Set<int> _viewedEmitted = <int>{};
  final Set<int> _completedEmitted = <int>{};

  // Abandonment telemetry (Task A10): when the app is backgrounded mid-
  // onboarding for 24h+, fire `onboarding_abandoned_at_page` on resume so
  // the funnel can attribute drop-offs to specific pages.
  DateTime? _pausedAt;
  int? _pausedAtPage;
  // Set as soon as _completeOnboarding starts so a backgrounding during the
  // post-paywall Supabase round-trip doesn't log abandonment-at-last-page.
  bool _completing = false;

  /// Last valid page index for the ACTIVE flow. The trimmed flow ends at
  /// [onboardingLastPageIndex] (19/18); legacy ends at
  /// [onboardingLegacyLastPageIndex] (26/25). Used to drive `_next`'s upper
  /// bound, the paywall-event triggers, and the abandonment paywall gate so
  /// they all track the flow the user is actually in.
  int get _activeLastPageIndex =>
      activeOnboardingLastPageIndex(trimmed: _trimmed);

  void _emitStepViewedOnce(int index) {
    if (!_viewedEmitted.add(index)) return;
    ref.read(analyticsProvider).trackStepViewed(index, trimmed: _trimmed);
  }

  void _emitStepCompletedOnce(int index) {
    if (!_completedEmitted.add(index)) return;
    ref.read(analyticsProvider).trackStepCompleted(index, trimmed: _trimmed);
  }

  void _firePaywallEventsOnce() {
    if (_paywallEventsFired) return;
    _paywallEventsFired = true;
    final analytics = ref.read(analyticsProvider);
    analytics.track(AnalyticsEvents.paywallViewed);
    analytics.track(AnalyticsEvents.paywallPlanSelected,
        properties: {'plan': 'annual'});
  }

  @override
  void initState() {
    super.initState();
    _useTrimmedFlowFuture = ref
        .read(appConfigServiceProvider)
        .getBool('onboarding_trim_enabled', fallback: true);
    // Mirror the resolved flow into a field so `_next`, the abandonment gate,
    // and the paywall triggers (all outside `build`) can read it. The
    // FutureBuilder in `build` remains the authoritative source for rendering.
    _useTrimmedFlowFuture.then((value) {
      if (mounted && value != _trimmed) setState(() => _trimmed = value);
    });
    WidgetsBinding.instance.addObserver(this);
    final restoredPage = ref.read(onboardingProvider).currentPage;
    // Clamp against the LEGACY max since the dual-flow decision (trimmed vs
    // legacy) is async — clamping against trimmedLastIndex prematurely would
    // strand a legacy-flow returner (e.g. saved currentPage=24, YourJourney)
    // at the trimmed paywall. The FutureBuilder + PageView will re-correct
    // bounds once the flow resolves. legacyMax >= trimmedMax always, so
    // trimmed-flow users are unaffected.
    const maxInitial =
        onboardingLegacyLastPageIndex > onboardingLastPageIndex
            ? onboardingLegacyLastPageIndex
            : onboardingLastPageIndex;
    final initialPage = restoredPage.clamp(0, maxInitial);
    _pageController = PageController(initialPage: initialPage);
    if (initialPage != restoredPage) {
      Future(() => ref.read(onboardingProvider.notifier).setPage(initialPage));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emitStepViewedOnce(initialPage);
      if (initialPage == 0) {
        ref
            .read(analyticsProvider)
            .timeEvent(AnalyticsEvents.onboardingCompleted);
      }
      if (initialPage == _activeLastPageIndex) {
        _firePaywallEventsOnce();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      _pausedAtPage = ref.read(onboardingProvider).currentPage;
    } else if (state == AppLifecycleState.resumed && _pausedAt != null) {
      final resumedAt = DateTime.now();
      // Suppress abandonment fire when:
      // (a) Paused on the paywall (final page) — they reached the end of the
      //     funnel, they're not "abandoned at page N", they just didn't buy.
      //     The funnel has paywall_viewed for that signal.
      // (b) Mid-completion — _completing flips on as soon as the paywall's
      //     onComplete fires; a backgrounded app during the await chain
      //     would otherwise log both "completed" and "abandoned at last page".
      final isPaywallPage = _pausedAtPage == _activeLastPageIndex;
      if (_pausedAtPage != null &&
          !isPaywallPage &&
          !_completing &&
          shouldFireAbandonment(pausedAt: _pausedAt!, resumedAt: resumedAt)) {
        final gone = resumedAt.difference(_pausedAt!);
        ref.read(analyticsProvider).track(
          AnalyticsEvents.onboardingAbandonedAtPage,
          properties: {
            'page': _pausedAtPage,
            'gone_hours': gone.inHours,
          },
        );
      }
      _pausedAt = null;
      _pausedAtPage = null;
    }
  }

  void _goToPage(int page) {
    if (_navigating) return;
    _navigating = true;

    FocusManager.instance.primaryFocus?.unfocus();

    final current = ref.read(onboardingProvider).currentPage;
    ref.read(onboardingProvider.notifier).setPage(page);

    // Only fire step_completed on forward navigation — back navigation is abandonment, not completion
    if (page > current) {
      _emitStepCompletedOnce(current);
    }
    _emitStepViewedOnce(page);
    if (page == _activeLastPageIndex) {
      _firePaywallEventsOnce();
    }

    if ((page - current).abs() > 1) {
      _pageController.jumpToPage(page);
      _navigating = false;
    } else {
      _pageController
          .animateToPage(
            page,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          )
          .whenComplete(() => _navigating = false);
    }
  }

  void _next() {
    final current = ref.read(onboardingProvider).currentPage;
    if (current < _activeLastPageIndex) _goToPage(current + 1);
  }

  /// Trimmed-flow social-auth landing: jump to Generating (16).
  void _skipToPostSignup() => _goToPage(onboardingPostSignupPageIndex);

  /// Legacy-flow social-auth landing: jump to Encouragement (21).
  /// Kept while the dual-flow kill switch is live; PR-2b will delete the
  /// legacy children + this helper after 7 days stable in prod.
  void _skipToEncouragement() =>
      _goToPage(onboardingLegacyEncouragementPageIndex);

  void _back() {
    final current = ref.read(onboardingProvider).currentPage;
    if (current > 0) {
      _goToPage(current - 1);
    } else if (context.canPop()) {
      context.pop();
    }
  }

  Future<void> _completeOnboarding() async {
    _completing = true;
    final analytics = ref.read(analyticsProvider);
    analytics.track(AnalyticsEvents.onboardingCompleted);
    analytics.setSuperProperties({'onboarding_completed': true});

    final state = ref.read(onboardingProvider);
    final profileProps = <String, dynamic>{};
    if (state.intention != null) profileProps['intention'] = state.intention;
    if (state.familiarity != null) {
      profileProps['familiarity'] = state.familiarity;
    }
    if (state.attribution.isNotEmpty) {
      profileProps['attribution'] = state.attribution.toList();
    }
    if (state.ageRange != null) profileProps['age_range'] = state.ageRange;
    if (state.prayerFrequency != null) {
      profileProps['prayer_frequency'] = state.prayerFrequency;
    }
    if (state.starterNameId != null) {
      profileProps['starter_name_id'] = state.starterNameId;
    }
    if (state.duaTopics.isNotEmpty) {
      profileProps['dua_topics'] = state.duaTopics.toList();
    }
    if (state.duaTopicsOther != null) {
      profileProps['dua_topics_other'] = state.duaTopicsOther;
    }
    if (state.dailyCommitmentMinutes != null) {
      profileProps['daily_commitment_minutes'] = state.dailyCommitmentMinutes;
    }
    if (state.reminderTime != null) {
      profileProps['reminder_time'] = state.reminderTime;
    }
    profileProps['commitment_accepted'] = state.commitmentAccepted;
    if (profileProps.isNotEmpty) analytics.setUserProperties(profileProps);

    analytics.flush();

    try {
      await ref
          .read(onboardingProvider.notifier)
          .completeOnboarding(ref.read(appSessionProvider));
    } catch (_) {}
    if (mounted) context.go('/');
  }

  /// Trimmed 20-screen flow (Phase A target, 2026-05-25 trim).
  List<Widget> _trimmedChildren() {
    return [
      // 0 — First check-in hook (gacha overlay fires here, not a separate page).
      FirstCheckinScreen(onNext: _next, onBack: _back),
      // 1 — Name input
      NameInputScreen(onNext: _next, onBack: _back),
      // 2 — Age range
      AgeRangeScreen(onNext: _next, onBack: _back),
      // 3 — Intention
      IntentionScreen(onNext: _next, onBack: _back),
      // 4 — Prayer frequency
      PrayerFrequencyScreen(onNext: _next, onBack: _back),
      // 5 — Familiarity with the 99 Names
      FamiliarityScreen(onNext: _next, onBack: _back),
      // 6 — Dua topics
      DuaTopicsScreen(onNext: _next, onBack: _back),
      // 7 — Daily commitment minutes
      DailyCommitmentScreen(onNext: _next, onBack: _back),
      // 8 — Attribution
      AttributionScreen(onNext: _next, onBack: _back),
      // 9 — Reminder time
      ReminderTimeScreen(onNext: _next, onBack: _back),
      // 10 — Notifications permission
      NotificationScreen(onNext: _next, onBack: _back),
      // 11 — Commitment pact
      CommitmentPactScreen(onNext: _next, onBack: _back),
      // 12 — Social proof (pre-signup)
      SocialProofScreen(onNext: _next, onBack: _back),
      // 13 — Save progress (sign-up choice)
      SaveProgressScreen(
        onNext: _next,
        onBack: _back,
        onSocialAuthComplete: _skipToPostSignup,
      ),
      // 14 — Sign-up email
      SignUpEmailScreen(onNext: _next, onBack: _back),
      // 15 — Sign-up password
      SignUpPasswordScreen(onNext: _next, onBack: _back),
      // — Paywall flow begins. Progress bar hidden on these. —
      // 16 — Generating (loader)
      GeneratingScreen(onNext: _next),
      // 17 — Personalized plan
      PersonalizedPlanScreen(onNext: _next, onBack: _back),
      // 18 — Rating gate (gated by Env.ratingGateEnabled)
      if (Env.ratingGateEnabled)
        RatingGateScreen(onNext: _next, onBack: _back),
      // 19 — Paywall
      PaywallScreen(onComplete: _completeOnboarding),
    ];
  }

  /// Legacy 27-screen flow. Retained behind the
  /// `onboarding_trim_enabled=false` app_config flag so we can kill-switch
  /// back without a redeploy. PR-2b will delete this method + the seven
  /// referenced screen files after 7 days stable in prod.
  List<Widget> _legacyChildren() {
    return [
      // 0 — First check-in hook (gacha overlay fires here, not a separate page).
      FirstCheckinScreen(onNext: _next, onBack: _back),
      // 1 — Name input
      NameInputScreen(onNext: _next, onBack: _back),
      // 2 — Age range
      AgeRangeScreen(onNext: _next, onBack: _back),
      // 3 — Intention
      IntentionScreen(onNext: _next, onBack: _back),
      // 4 — Prayer frequency
      PrayerFrequencyScreen(onNext: _next, onBack: _back),
      // 5 — Quran connection
      QuranConnectionScreen(onNext: _next, onBack: _back),
      // 6 — Familiarity with the 99 Names
      FamiliarityScreen(onNext: _next, onBack: _back),
      // 7 — Dua topics
      DuaTopicsScreen(onNext: _next, onBack: _back),
      // 8 — Common emotions
      CommonEmotionsScreen(onNext: _next, onBack: _back),
      // 9 — Aspirations
      AspirationsScreen(onNext: _next, onBack: _back),
      // 10 — Daily commitment minutes
      DailyCommitmentScreen(onNext: _next, onBack: _back),
      // 11 — Attribution
      AttributionScreen(onNext: _next, onBack: _back),
      // 12 — "You're not alone" support interstitial
      StruggleSupportInterstitialScreen(onNext: _next, onBack: _back),
      // 13 — Reminder time
      ReminderTimeScreen(onNext: _next, onBack: _back),
      // 14 — Notifications permission
      NotificationScreen(onNext: _next, onBack: _back),
      // 15 — Commitment pact
      CommitmentPactScreen(onNext: _next, onBack: _back),
      // 16 — Value prop
      ValuePropScreen(onNext: _next, onBack: _back),
      // 17 — Social proof (pre-signup)
      SocialProofScreen(onNext: _next, onBack: _back),
      // 18 — Save progress (sign-up choice)
      SaveProgressScreen(
        onNext: _next,
        onBack: _back,
        onSocialAuthComplete: _skipToEncouragement,
      ),
      // 19 — Sign-up email
      SignUpEmailScreen(onNext: _next, onBack: _back),
      // 20 — Sign-up password
      SignUpPasswordScreen(onNext: _next, onBack: _back),
      // 21 — Encouragement #2 (social-auth users land here)
      EncouragementScreen(onNext: _next, onBack: _back),
      // — Paywall flow begins. Progress bar hidden on these. —
      // 22 — Generating (loader)
      GeneratingScreen(onNext: _next),
      // 23 — Personalized plan
      PersonalizedPlanScreen(onNext: _next, onBack: _back),
      // 24 — Your Journey
      YourJourneyScreen(onNext: _next, onBack: _back),
      // 25 — Rating gate (gated by Env.ratingGateEnabled)
      if (Env.ratingGateEnabled)
        RatingGateScreen(onNext: _next, onBack: _back),
      // 26 — Paywall
      PaywallScreen(onComplete: _completeOnboarding),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(
      onboardingProvider.select((state) => state.currentPage),
    );

    return FutureBuilder<bool>(
      future: _useTrimmedFlowFuture,
      builder: (context, snapshot) {
        // Optimistic default — trim is the new shipping flow. Cached value
        // resolves synchronously on subsequent launches via AppConfigService.
        final trimmed = snapshot.data ?? true;
        // Belt-and-braces: keep the field in lockstep with the rendered flow
        // so `_next`/abandonment/paywall triggers (which read `_trimmed`
        // outside build) never lag the FutureBuilder. Plain assignment — no
        // setState; build is already running.
        _trimmed = trimmed;
        final children = trimmed ? _trimmedChildren() : _legacyChildren();

        // Re-clamp once the flow resolves: if the user's restored page is
        // past the end of the chosen flow's children, snap them to the last
        // valid page. Defer to the next frame so we don't setState during
        // build. Idempotent — no-op when currentPage is already in bounds.
        final maxIdx = children.length - 1;
        if (currentPage > maxIdx) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref.read(onboardingProvider.notifier).setPage(maxIdx);
            if (_pageController.hasClients) {
              _pageController.jumpToPage(maxIdx);
            }
          });
        }

        // Pages that should NOT resize for keyboard:
        //   trimmed: 0 (first check-in) and 6 (dua topics)
        //   legacy:  0 (first check-in) and 7 (dua topics)
        final keepBottomInset = trimmed
            ? (currentPage != 0 && currentPage != 6)
            : (currentPage != 0 && currentPage != 7);

        return Scaffold(
          resizeToAvoidBottomInset: keepBottomInset,
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: children,
          ),
        );
      },
    );
  }
}

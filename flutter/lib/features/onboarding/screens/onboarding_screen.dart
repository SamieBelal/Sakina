import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_session.dart';
import '../../../core/env.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/analytics_events.dart';
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

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  bool _navigating = false;
  bool _paywallEventsFired = false;
  final Set<int> _viewedEmitted = <int>{};
  final Set<int> _completedEmitted = <int>{};

  void _emitStepViewedOnce(int index) {
    if (!_viewedEmitted.add(index)) return;
    ref.read(analyticsProvider).trackStepViewed(index);
  }

  void _emitStepCompletedOnce(int index) {
    if (!_completedEmitted.add(index)) return;
    ref.read(analyticsProvider).trackStepCompleted(index);
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
    final restoredPage = ref.read(onboardingProvider).currentPage;
    final initialPage = restoredPage.clamp(0, onboardingLastPageIndex);
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
      if (initialPage == onboardingLastPageIndex) {
        _firePaywallEventsOnce();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    if (page == onboardingLastPageIndex) {
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
    if (current < onboardingLastPageIndex) _goToPage(current + 1);
  }

  void _skipToEncouragement() => _goToPage(onboardingEncouragementPageIndex);

  void _back() {
    final current = ref.read(onboardingProvider).currentPage;
    if (current > 0) {
      _goToPage(current - 1);
    } else if (context.canPop()) {
      context.pop();
    }
  }

  Future<void> _completeOnboarding() async {
    final analytics = ref.read(analyticsProvider);
    analytics.track(AnalyticsEvents.onboardingCompleted);
    analytics.setSuperProperties({'onboarding_completed': true});

    final state = ref.read(onboardingProvider);
    final profileProps = <String, dynamic>{};
    if (state.intention != null) profileProps['intention'] = state.intention;
    if (state.familiarity != null) {
      profileProps['familiarity'] = state.familiarity;
    }
    if (state.quranConnection != null) {
      profileProps['quran_connection'] = state.quranConnection;
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
    if (state.commonEmotions.isNotEmpty) {
      profileProps['common_emotions'] = state.commonEmotions.toList();
    }
    if (state.aspirations.isNotEmpty) {
      profileProps['aspirations'] = state.aspirations.toList();
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

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(
      onboardingProvider.select((state) => state.currentPage),
    );

    return Scaffold(
      resizeToAvoidBottomInset: currentPage != 0 && currentPage != 7,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
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
          // 16 — Value prop  (was 18 pre-2026-05-05; +2 from removing Generating + PersonalPlan)
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
          // 21 — Encouragement #2  (social-auth users land here; tease added 2026-05-05)
          EncouragementScreen(onNext: _next, onBack: _back),
          // — Paywall flow begins. Progress bar hidden on these. —
          // 22 — Generating (loader; relocated from old page 16; copy updated to 4 steps)
          GeneratingScreen(onNext: _next),
          // 23 — Personalized plan (relocated from old page 17; reskinned to plain Scaffold)
          PersonalizedPlanScreen(onNext: _next, onBack: _back),
          // 24 — Your Journey (NEW 2026-05-05)
          YourJourneyScreen(onNext: _next, onBack: _back),
          // 25 — Rating gate (NEW 2026-05-14, gated by Env.ratingGateEnabled —
          //   when flag is false the gate is elided at compile time and
          //   paywall sits at index 25 exactly as before. See
          //   docs/superpowers/plans/2026-05-14-rating-gate.md.)
          if (Env.ratingGateEnabled)
            RatingGateScreen(onNext: _next, onBack: _back),
          // 26 — Paywall (was 25 — see Env.ratingGateEnabled)
          PaywallScreen(onComplete: _completeOnboarding),
        ],
      ),
    );
  }
}

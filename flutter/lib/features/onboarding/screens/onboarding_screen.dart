import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_session.dart';
import '../providers/onboarding_provider.dart';
import 'attribution_screen.dart';
import 'encouragement_screen.dart';
import 'familiarity_screen.dart';
import 'feature_dua_screen.dart';
import 'feature_journal_screen.dart';
import 'feature_names_screen.dart';
import 'feature_quests_screen.dart';
import 'first_checkin_screen.dart';
import 'generating_screen.dart';
import 'intention_screen.dart';
import 'notification_screen.dart';
import 'paywall_screen.dart';
import 'quran_connection_screen.dart';
import 'save_progress_screen.dart';
import 'sign_up_email_screen.dart';
import 'sign_up_name_screen.dart';
import 'sign_up_password_screen.dart';
import 'social_proof_screen.dart';
import 'struggles_screen.dart';
import 'value_prop_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final restoredPage = ref.read(onboardingProvider).currentPage;
    final initialPage = restoredPage.clamp(0, onboardingLastPageIndex);
    _pageController = PageController(initialPage: initialPage);
    if (initialPage != restoredPage) {
      Future(() =>
          ref.read(onboardingProvider.notifier).setPage(initialPage));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    final current = ref.read(onboardingProvider).currentPage;
    ref.read(onboardingProvider.notifier).setPage(page);

    // Jump instantly when crossing multiple pages to avoid flickering through
    // intermediate screens. Keep smooth animation for adjacent page transitions.
    if ((page - current).abs() > 1) {
      _pageController.jumpToPage(page);
    } else {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _next() {
    final current = ref.read(onboardingProvider).currentPage;
    if (current < onboardingLastPageIndex) _goToPage(current + 1);
  }

  void _goToPaywall() {
    _goToPage(onboardingLastPageIndex);
  }

  void _back() {
    final current = ref.read(onboardingProvider).currentPage;
    if (current > 0) {
      _goToPage(current - 1);
    } else if (context.canPop()) {
      context.pop();
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      await ref.read(onboardingProvider.notifier).completeOnboarding(ref.read(appSessionProvider));
    } catch (_) {}
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // 0: Intention
          IntentionScreen(onNext: _next, onBack: _back),
          // 1: Encouragement
          EncouragementScreen(onNext: _next, onBack: _back),
          // 2: First Check-in (core loop — moved early)
          FirstCheckinScreen(
            onNext: _next,
            onBack: _back,
          ),
          // 3: Feature — Collect 99 Names
          FeatureNamesScreen(onNext: _next, onBack: _back),
          // 4: Feature — Build a Dua
          FeatureDuaScreen(onNext: _next, onBack: _back),
          // 5: Feature — Quests & Ranks
          FeatureQuestsScreen(onNext: _next, onBack: _back),
          // 6: Feature — Journal
          FeatureJournalScreen(onNext: _next, onBack: _back),
          // 7: Struggles
          StrugglesScreen(onNext: _next, onBack: _back),
          // 8: Value Prop
          ValuePropScreen(onNext: _next, onBack: _back),
          // 9: Familiarity
          FamiliarityScreen(onNext: _next, onBack: _back),
          // 10: Quran Connection
          QuranConnectionScreen(onNext: _next, onBack: _back),
          // 11: Attribution
          AttributionScreen(onNext: _next, onBack: _back),
          // 12: Social Proof
          SocialProofScreen(onNext: _next, onBack: _back),
          // 13: Notifications
          NotificationScreen(onNext: _next, onBack: _back),
          // 14: Sign-Up Choice
          SaveProgressScreen(
            onNext: _next,
            onBack: _back,
            onSocialAuthComplete: _goToPaywall,
          ),
          // 15: Sign-Up Email
          SignUpEmailScreen(onNext: _next, onBack: _back),
          // 16: Sign-Up Password
          SignUpPasswordScreen(onNext: _next, onBack: _back),
          // 17: Sign-Up Name
          SignUpNameScreen(onNext: _next, onBack: _back),
          // 18: Paywall
          PaywallScreen(onComplete: _completeOnboarding),
        ],
      ),
    );
  }
}

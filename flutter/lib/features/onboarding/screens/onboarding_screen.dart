import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_provider.dart';
import 'attribution_screen.dart';
import 'encouragement_screen.dart';
import 'familiarity_screen.dart';
import 'first_checkin_screen.dart';
import 'generating_screen.dart';
import 'hook_screen.dart';
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

  static const _paywallPage = 16;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    ref.read(onboardingProvider.notifier).setPage(page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    final current = ref.read(onboardingProvider).currentPage;
    if (current < _paywallPage) _goToPage(current + 1);
  }

  void _back() {
    final current = ref.read(onboardingProvider).currentPage;
    if (current > 0) _goToPage(current - 1);
  }

  void _goToPaywall() {
    _goToPage(_paywallPage);
  }

  Future<void> _completeOnboarding() async {
    try {
      await ref.read(onboardingProvider.notifier).completeOnboarding();
    } catch (_) {}
    if (mounted) context.go('/');
  }

  void _goToSignIn() {
    context.push('/signin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // 0: Hook
          HookScreen(onNext: _next, onSignIn: _goToSignIn),
          // 1: Intention
          IntentionScreen(onNext: _next, onBack: _back),
          // 2: Struggles
          StrugglesScreen(onNext: _next, onBack: _back),
          // 3: Value Prop
          ValuePropScreen(onNext: _next, onBack: _back),
          // 4: Familiarity
          FamiliarityScreen(onNext: _next, onBack: _back),
          // 5: Quran Connection
          QuranConnectionScreen(onNext: _next, onBack: _back),
          // 6: Attribution
          AttributionScreen(onNext: _next, onBack: _back),
          // 7: Encouragement
          EncouragementScreen(onNext: _next, onBack: _back),
          // 8: Social Proof
          SocialProofScreen(onNext: _next, onBack: _back),
          // 9: Notifications
          NotificationScreen(onNext: _next, onBack: _back),
          // 10: Generating
          GeneratingScreen(onNext: _next),
          // 11: First Check-in
          FirstCheckinScreen(
            onNext: _next,
            onBack: _back,
          ),
          // 12: Sign-Up Choice
          SaveProgressScreen(
            onNext: _next,
            onBack: _back,
            onSkipToPaywall: _goToPaywall,
          ),
          // 13: Sign-Up Name
          SignUpNameScreen(onNext: _next, onBack: _back),
          // 14: Sign-Up Email
          SignUpEmailScreen(onNext: _next, onBack: _back),
          // 15: Sign-Up Password
          SignUpPasswordScreen(onNext: _next, onBack: _back),
          // 16: Paywall
          PaywallScreen(onComplete: _completeOnboarding),
        ],
      ),
    );
  }
}

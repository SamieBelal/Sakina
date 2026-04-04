import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_provider.dart';
import 'hook_screen.dart';
import 'intention_screen.dart';
import 'struggles_screen.dart';
import 'social_proof_screen.dart';
import 'notification_screen.dart';
import 'first_checkin_screen.dart';
import 'paywall_screen.dart';

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
    if (current < 6) _goToPage(current + 1);
  }

  void _back() {
    final current = ref.read(onboardingProvider).currentPage;
    if (current > 0) _goToPage(current - 1);
  }

  Future<void> _completeOnboarding() async {
    try {
      await ref.read(onboardingProvider.notifier).completeOnboarding();
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
          HookScreen(onNext: _next),
          IntentionScreen(onNext: _next, onBack: _back),
          StrugglesScreen(onNext: _next, onBack: _back),
          SocialProofScreen(onNext: _next, onBack: _back),
          NotificationScreen(onNext: _next, onBack: _back),
          FirstCheckinScreen(
            onNext: _next,
            onBack: _back,
            onComplete: _completeOnboarding,
          ),
          PaywallScreen(onComplete: _completeOnboarding),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/feelings/screens/home_screen.dart';
import '../features/feelings/screens/result_screen.dart';
import '../features/names/screens/names_screen.dart';
import '../features/journal/screens/journal_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../widgets/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter({required bool onboardingCompleted}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: onboardingCompleted ? '/' : '/onboarding',
    redirect: (context, state) {
      final isOnboarding = state.uri.path == '/onboarding';
      if (!onboardingCompleted && !isOnboarding) return '/onboarding';
      if (onboardingCompleted && isOnboarding) return '/';
      return null;
    },
    routes: [
      // Onboarding (no bottom nav)
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Result screen (no bottom nav — full screen)
      GoRoute(
        path: '/result',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ResultScreen(),
      ),

      // Main app with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/names',
            builder: (context, state) => const NamesScreen(),
          ),
          GoRoute(
            path: '/journal',
            builder: (context, state) => const JournalScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

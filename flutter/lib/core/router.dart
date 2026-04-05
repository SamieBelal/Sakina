import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/progress/screens/progress_screen.dart';
import '../features/reflect/screens/reflect_screen.dart';
import '../features/duas/screens/duas_screen.dart';
import '../features/feelings/screens/home_screen.dart';
import '../features/journal/screens/journal_screen.dart';
import '../features/quests/screens/quests_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/collection/screens/collection_screen.dart';
import '../features/discovery/screens/discovery_quiz_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../widgets/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter({required bool onboardingCompleted}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: onboardingCompleted ? '/' : '/onboarding',
    routes: [
      // Onboarding (no bottom nav)
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Sign in (full screen, no bottom nav)
      GoRoute(
        path: '/signin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignInScreen(),
      ),

      // Discovery quiz (full screen, no bottom nav)
      GoRoute(
        path: '/discovery-quiz',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DiscoveryQuizScreen(),
      ),

      // Main app with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const ProgressScreen(),
          ),
          GoRoute(
            path: '/reflect',
            builder: (context, state) => const ReflectScreen(),
          ),
          GoRoute(
            path: '/collection',
            builder: (context, state) => const CollectionScreen(),
          ),
          GoRoute(
            path: '/duas',
            builder: (context, state) => const DuasScreen(),
          ),
          GoRoute(
            path: '/journal',
            builder: (context, state) => const JournalScreen(),
          ),
          GoRoute(
            path: '/quests',
            builder: (context, state) => const QuestsScreen(),
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

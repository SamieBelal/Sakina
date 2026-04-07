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
import '../features/daily/screens/muhasabah_screen.dart';
import '../features/discovery/screens/discovery_quiz_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../widgets/achievement_toast.dart';
import '../widgets/app_shell.dart';

final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter({required bool onboardingCompleted}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: onboardingCompleted ? '/' : '/onboarding',
    routes: [
      // Onboarding (no bottom nav)
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Sign in (full screen, no bottom nav)
      GoRoute(
        path: '/signin',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SignInScreen(),
      ),

      // Discovery quiz (full screen, no bottom nav)
      GoRoute(
        path: '/discovery-quiz',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DiscoveryQuizScreen(),
      ),

      // Muhasabah (full screen, no bottom nav)
      GoRoute(
        path: '/muhasabah',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MuhasabahScreen(),
      ),

      // Main app with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProgressScreen(),
            ),
          ),
          GoRoute(
            path: '/reflect',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReflectScreen(),
            ),
          ),
          GoRoute(
            path: '/collection',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CollectionScreen(),
            ),
          ),
          GoRoute(
            path: '/duas',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DuasScreen(),
            ),
          ),
          GoRoute(
            path: '/journal',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: JournalScreen(),
            ),
          ),
          GoRoute(
            path: '/quests',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: QuestsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

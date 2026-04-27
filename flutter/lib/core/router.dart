import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/progress/screens/progress_screen.dart';
import '../features/reflect/screens/reflect_screen.dart';
import '../features/duas/screens/duas_screen.dart';
import '../features/journal/screens/journal_screen.dart';
import '../features/quests/screens/quests_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/collection/screens/collection_screen.dart';
import '../features/daily/screens/muhasabah_screen.dart';
import '../features/discovery/screens/discovery_quiz_screen.dart';
import '../features/onboarding/screens/hook_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/onboarding/screens/paywall_screen.dart';
import '../widgets/achievement_toast.dart';
import '../widgets/app_shell.dart';
import '../features/collection/widgets/silver_card_preview.dart';
import '../features/collection/widgets/gold_card_preview.dart';
import '../features/collection/widgets/bronze_card_preview.dart';
import '../features/collection/widgets/emerald_card_preview.dart';
import '../features/settings/screens/dev_tools_screen.dart';
import '../features/store/screens/store_screen.dart';
import 'app_session.dart';

final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter({required AppSessionNotifier appSession}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: appSession.hasOnboarded ? '/' : '/welcome',
    refreshListenable: appSession,
    redirect: (context, state) {
      final path = state.uri.path;

      // Always allow onboarding, signin, and welcome (including sub-paths)
      if (path.startsWith('/onboarding') ||
          path.startsWith('/signin') ||
          path.startsWith('/welcome')) {
        return null;
      }

      if (!appSession.hasOnboarded || !appSession.isAuthenticated) {
        return '/welcome';
      }

      return null;
    },
    routes: [
      // Onboarding (no bottom nav)
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Standalone paywall (for already-onboarded users hitting the upgrade
      // sheet from journal save limits, etc). Does NOT fire completeOnboarding.
      GoRoute(
        path: '/paywall',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PaywallScreen(
          inOnboardingFlow: false,
          onComplete: () => GoRouter.of(context).pop(),
        ),
      ),

      // Welcome / auth landing (full screen, no bottom nav)
      GoRoute(
        path: '/welcome',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => HookScreen(
          onNext: () => GoRouter.of(context).push('/onboarding'),
          onSignIn: () => GoRouter.of(context).push('/signin'),
        ),
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

      // DEBUG: Card design previews (temporary)
      GoRoute(
        path: '/silver-preview',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SilverCardPreviewScreen(),
      ),
      GoRoute(
        path: '/gold-preview',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GoldCardPreviewScreen(),
      ),
      GoRoute(
        path: '/bronze-preview',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const BronzeCardPreviewScreen(),
      ),
      GoRoute(
        path: '/emerald-preview',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const EmeraldCardPreviewScreen(),
      ),

      // DEBUG: Dev tools (debug builds only)
      if (kDebugMode)
        GoRoute(
          path: '/dev-tools',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const DevToolsScreen(),
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
          GoRoute(
            path: '/store',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StoreScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

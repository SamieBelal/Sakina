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
import '../features/onboarding/onboarding_stage.dart';
import '../features/onboarding/screens/hook_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/onboarding/screens/paywall_screen.dart';
import '../services/analytics_events.dart';
import '../features/paywall/screens/cancellation_feedback_deeplink_screen.dart';
import '../features/referrals/screens/my_referrals_screen.dart';
import '../widgets/achievement_toast.dart';
import '../features/tour/providers/tour_route_observer.dart';
import '../widgets/app_shell.dart';
import '../features/collection/widgets/silver_card_preview.dart';
import '../features/collection/widgets/gold_card_preview.dart';
import '../features/collection/widgets/bronze_card_preview.dart';
import '../features/collection/widgets/emerald_card_preview.dart';
import '../features/settings/screens/dev_tools_screen.dart';
import '../features/store/screens/store_screen.dart';
import 'app_session.dart';

final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Full-screen route for the post-tour hard entry wall (no bottom nav, no X).
/// Distinct from the soft `/paywall` upsell so the gate can force it and block
/// navigation away from it.
const String kOnboardingPaywallPath = '/onboarding-paywall';

/// Pure routing decision for the post-onboarding gate. Returns the path to
/// redirect to, or `null` to stay put. Extracted so it is unit-testable without
/// a live GoRouter. [currentPath] is the path the user is navigating to.
String? onboardingGateRedirect({
  required String currentPath,
  required AppSessionNotifier appSession,
}) {
  // Always allow the pre-auth funnel through (incl. sub-paths). NOTE: match
  // '/onboarding' exactly or its '/onboarding/...' subpaths — NOT a bare
  // prefix, which would also swallow '/onboarding-paywall' (the hard wall) and
  // make the gate un-enforceable.
  final isOnboardingFunnel =
      currentPath == '/onboarding' || currentPath.startsWith('/onboarding/');
  if (isOnboardingFunnel ||
      currentPath.startsWith('/signin') ||
      currentPath.startsWith('/welcome')) {
    return null;
  }

  if (!appSession.isAuthenticated || !appSession.hasOnboarded) {
    return '/welcome';
  }

  final stage = resolveOnboardingStage(
    isAuthenticated: appSession.isAuthenticated,
    hasOnboarded: appSession.hasOnboarded,
    tourCompleted: appSession.tourCompleted,
    // Session-only valve bypass counts as "cleared" for THIS session only.
    paywallCleared: appSession.paywallCleared || appSession.gateValveBypass,
    isPremium: appSession.isPremiumCached,
    hardPaywallFlowEnabled: appSession.hardPaywallFlowEnabled,
  );

  switch (stage) {
    case OnboardingStage.welcome:
      return '/welcome';
    case OnboardingStage.hardPaywall:
      // Force the no-X wall; block navigating anywhere else.
      return currentPath == kOnboardingPaywallPath
          ? null
          : kOnboardingPaywallPath;
    case OnboardingStage.tour:
    case OnboardingStage.app:
      // The tour runs as an overlay over the home shell, so a tour-stage user
      // just stays in the app (the overlay drives them). If a tour/cleared
      // user is somehow sitting on the hard wall, send them home.
      return currentPath == kOnboardingPaywallPath ? '/' : null;
  }
}

GoRouter buildRouter({required AppSessionNotifier appSession}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    // Singleton tour route observer (lib/features/tour/providers/tour_route_observer.dart).
    // Tracks the topmost route's settings.name so OnboardingTourOverlayHost
    // can hide while a blocking modal (NameRevealOverlay, etc.) is up, and
    // detect the DuaDetailPage back-gesture for step 13 completion.
    observers: [tourRouteObserver],
    initialLocation: appSession.hasOnboarded ? '/' : '/welcome',
    refreshListenable: appSession,
    redirect: (context, state) => onboardingGateRedirect(
      currentPath: state.uri.path,
      appSession: appSession,
    ),
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
          placement: AnalyticsEvents.placementSoftInApp,
          onComplete: () => GoRouter.of(context).pop(),
        ),
      ),

      // Post-tour hard entry wall (full screen, no bottom nav, NO X). The
      // gate redirect forces this and blocks navigation away from it. On a
      // successful trial start the paywall sets the cleared latch, which flips
      // the stage to `app` and lets the user through.
      GoRoute(
        path: kOnboardingPaywallPath,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PaywallScreen(
          inOnboardingFlow: false,
          hardGate: true,
          placement: AnalyticsEvents.placementHardWall,
          onComplete: () => GoRouter.of(context).go('/'),
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

      // My Referrals (full screen, no bottom nav). Settings → "Refer a friend"
      // pushes here. See docs/superpowers/plans/2026-05-23-my-referrals-screen.md.
      GoRoute(
        path: '/my-referrals',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MyReferralsScreen(),
      ),

      // Cancellation feedback push deep-link target
      // (sakina://cancellation-feedback). Presents the survey directly then
      // returns home. See docs/superpowers/specs/2026-05-31-cancellation-feedback-design.md.
      GoRoute(
        path: '/cancellation-feedback',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CancellationFeedbackDeepLinkScreen(),
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
            pageBuilder: (context, state) {
              // E5 win-back deep link: `sakina://settings?action=replay_tour`.
              // SettingsScreen consumes the param on first build via a
              // post-frame callback that mirrors the user-tap Replay path.
              final action = state.uri.queryParameters['action'];
              return NoTransitionPage(
                child: SettingsScreen(autoAction: action),
              );
            },
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

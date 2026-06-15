import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_lifecycle_observer.dart';
import 'core/app_session.dart';
import 'core/env.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'features/daily/providers/daily_loop_provider.dart';
import 'features/duas/providers/duas_provider.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/reflect/providers/reflect_provider.dart';
import 'features/tour/widgets/onboarding_tour_overlay_host.dart';
import 'services/analytics_events.dart';
import 'services/analytics_provider.dart';
import 'services/analytics_service.dart';
import 'services/app_config_service.dart';
import 'services/auth_service.dart';
import 'services/card_collection_service.dart';
import 'services/consumable_grants_service.dart';
import 'services/gating_service.dart';
import 'services/streak_service.dart';
import 'features/paywall/widgets/daily_cap_sheet.dart';
import 'services/notification_service.dart';
import 'services/public_catalog_service.dart';
import 'services/purchase_service.dart';
import 'widgets/billing_issue_banner.dart';
import 'widgets/iap_to_sub_upsell_banner.dart';

/// SharedPreferences key for an inbound referral code captured via the
/// `sakina://r/<code>` custom scheme. NOT user-scoped: the user is typically
/// not yet authenticated when the deep link fires (they may not have signed
/// up). The signup flow consumes the key in [_applyPendingReferral] (see
/// [ReferralService.applyPendingReferralIfAny]) and clears it on success.
const String pendingReferralPrefsKey = 'pending_referral';

/// Max length of a referral code we will persist from a deep link.
/// Current `ensure_referral_code` (supabase/migrations/20260514175600_referrals.sql)
/// emits 8 chars from alphabet `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`. Capped at
/// 16 to leave headroom if we ever widen the alphabet, while still rejecting
/// pathological inputs (e.g. a 10KB blob from a hostile URL).
const int referralCodeMaxLength = 16;

/// Charset matching the `ensure_referral_code` alphabet — uppercase letters
/// minus I/O, plus digits 2-9. Anything else is rejected before we ever touch
/// SharedPreferences (the server would reject it as `invalid_code` anyway, but
/// validating up front prevents storing junk).
final RegExp referralCodeRegex = RegExp(r'^[A-HJ-NP-Z2-9]+$');

/// Pure validator extracted from [_persistReferralFromUri] for testability.
/// Returns the validated code, or null if the URI is not a referral link or
/// the code shape is invalid. Visible-for-test.
String? extractValidReferralCode(Uri uri) {
  if (uri.scheme != 'sakina' || uri.host != 'r') return null;
  if (uri.pathSegments.isEmpty) return null;
  final code = uri.pathSegments[0];
  if (code.isEmpty) return null;
  if (code.length > referralCodeMaxLength) return null;
  if (!referralCodeRegex.hasMatch(code)) return null;
  return code;
}

/// Captures an inbound `sakina://r/<code>` link and persists the code to
/// SharedPreferences. The signup flow consumes it on the next authenticated
/// session. Called from [main] BEFORE [runApp] so the cold-launch URI is
/// committed before any code that might read it.
///
/// Universal-link handling (`https://sakina.app/r/<code>`) is OUT OF SCOPE
/// for v1 — we don't own the domain, so AASA/assetlinks.json hosting isn't
/// available. See docs/superpowers/plans/2026-05-14-refer-unlock.md.
Future<void> _captureInboundReferral(AppLinks appLinks) async {
  try {
    final initial = await appLinks.getInitialLink();
    if (initial != null) await _persistReferralFromUri(initial);
  } catch (_) {
    // First-launch on Android can throw on getInitialLink — non-fatal.
  }
  // Warm-launch deep links: subscribe AFTER awaiting the initial-link so
  // the cold-launch URI is committed first.
  appLinks.uriLinkStream.listen(_persistReferralFromUri);
}

Future<void> _persistReferralFromUri(Uri uri) async {
  // v1: custom scheme only. Universal-link path (https://sakina.app/r/<code>)
  // is deferred to Phase 2 (post-domain-acquisition).
  //
  // Validation matches the ensure_referral_code alphabet + length cap so a
  // hostile URL (e.g. `sakina://r/<10KB blob>`) can't bloat SharedPreferences.
  // Silent reject on bad shape — no crash, no UI error. The server would
  // reject it as `invalid_code` anyway; this just trims the attack surface.
  final code = extractValidReferralCode(uri);
  if (code == null) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(pendingReferralPrefsKey, code);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Capture any inbound referral deep link BEFORE further init so the
  // pending_referral prefs key is committed by the time the signup flow runs.
  await _captureInboundReferral(AppLinks());

  // Load onboarding flag and cached onboarding state
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  final cachedOnboardingState = await OnboardingNotifier.loadFromPrefs();

  // Env values are compile-time constants, fed by --dart-define-from-file.
  // See lib/core/env.dart for the full list.
  const supabaseUrl = Env.supabaseUrl;
  const supabaseAnonKey = Env.supabaseAnonKey;
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  await bootstrapPublicCatalogs();
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    unawaited(refreshPublicCatalogsFromSupabase());
    // Parallel prefetch (1.2C) — prime the AppConfigService cache so the
    // first router decision sees fresh values for the onboarding-trim +
    // guided-tour kill switches. Fire-and-forget with a hard timeout so a
    // slow network never delays cold launch beyond 1.5s. On miss the next
    // launch reads fresh values from the populated cache.
    unawaited(
      AppConfigService(Supabase.instance.client)
          .primeCache(const [
            'onboarding_trim_enabled',
            'guided_tour_enabled',
            // Onboarding→tour→hard-paywall gate. MUST be primed: a cold-cache
            // miss reads the `false` fallback, which drops the user into the
            // legacy opportunistic (skippable) tour instead of the forced gated
            // flow. Caught in the simulator on a fresh launch.
            'hard_paywall_after_tour_enabled',
            // Slim-vs-full guided-tour A/B. Off → everyone gets the slim tour;
            // on → 50/50 stable per-user split (see OnboardingTourController).
            'tour_ab_enabled',
          ])
          .timeout(const Duration(milliseconds: 1500), onTimeout: () {}),
    );
  }

  if (!kIsWeb) {
    try {
      await PurchaseService().initialize(
        appleApiKey: Env.revenueCatApiKeyApple,
        googleApiKey: Env.revenueCatApiKeyGoogle,
      );
      // Register the consumable orphan-recovery listener. Fires every time
      // RC's customerInfo updates (purchase, restore, login, syncPurchases).
      // It detects un-credited consumable transactions and replays the
      // local grant — covers the "app killed mid-purchase" scenario where
      // Apple charged the user but `_buyTokensIAP` never reached the
      // synchronous earnTokens call.
      final consumableGrants = ConsumableGrantsService();
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        // Don't await — listener must not block the SDK callback. Errors
        // are logged inside processCustomerInfo.
        unawaited(consumableGrants.processCustomerInfo(customerInfo));
      });
      // Flush any pending receipts (e.g., StoreKit had a transaction in its
      // queue from a prior session that never fully completed). This will
      // trigger the listener if anything is pending.
      unawaited(Purchases.syncPurchases());
    } catch (_) {
      // Best-effort — app should launch even if RevenueCat is unavailable.
      // PurchaseService methods will return safe defaults when not initialized.
    }
  }

  final notificationService = NotificationService();
  if (!kIsWeb) {
    await notificationService.initialize(Env.oneSignalAppId);
    notificationService.addForegroundListener();
    notificationService.addClickListener();
  }

  // Initialize Mixpanel analytics (not supported on web)
  final analytics = AnalyticsService();
  if (!kIsWeb) {
    await analytics.initialize(Env.mixpanelToken);
  }
  analytics.setSuperPropertiesOnce({
    'first_open_date': DateTime.now().toIso8601String(),
  });
  // Experiment-context super properties: attach the active feature-flag state +
  // real app version to EVERY event, so the entire onboarding→tour→paywall
  // funnel is segmentable by flag combination (and by release) in Mixpanel with
  // no per-question instrumentation. Flag reads are cache-fast (AppConfigService
  // returns cached-or-fallback instantly, refreshing in the background); the
  // fallbacks mirror each flag's own default. See
  // docs/analytics/funnel-flags-and-querying.md.
  // Guarded: PackageInfo.fromPlatform() can throw (MissingPluginException
  // during a plugin-registration race, platform-channel failure). This whole
  // block is best-effort telemetry — a bare throw here would crash cold launch
  // before runApp. Fall back to an explicit sentinel version.
  String appVersion;
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
  } catch (_) {
    appVersion = 'unknown';
  }
  final appConfigForAnalytics = AppConfigService(Supabase.instance.client);
  // Resolve `is_premium` for the boot super property. Best-effort — a
  // failed/slow premium read defaults to false and is refreshed on the next
  // resume by AppLifecycleObserver. Never block launch on it.
  bool isPremiumAtBoot;
  try {
    isPremiumAtBoot = await PurchaseService().isPremium();
  } catch (_) {
    isPremiumAtBoot = false;
  }
  // Register the experiment-context super properties (platform, app_version,
  // the four flag_* flags, is_premium) and fire the once-ever app_install
  // event. Extracted to registerBootstrapAnalytics so the guard + super-prop
  // shape is unit-testable; behavior is identical to the previous inline code.
  await registerBootstrapAnalytics(
    analytics: analytics,
    prefs: prefs,
    platform: defaultTargetPlatform.name,
    appVersion: appVersion,
    flagOnboardingTrim: await appConfigForAnalytics
        .getBool('onboarding_trim_enabled', fallback: true),
    flagHardPaywall: await appConfigForAnalytics
        .getBool('hard_paywall_after_tour_enabled', fallback: false),
    flagTourAb:
        await appConfigForAnalytics.getBool('tour_ab_enabled', fallback: false),
    flagGuidedTour: await appConfigForAnalytics
        .getBool('guided_tour_enabled', fallback: true),
    isPremium: isPremiumAtBoot,
  );
  analytics.track(AnalyticsEvents.appOpened, properties: {
    'is_first_open': !onboardingCompleted,
  });

  // Wire AI-bypass funnel hooks (PR 3 of plan 2026-05-23). Service-layer
  // and widget-layer code in those files has no Riverpod access; the static
  // hook indirection lets them emit telemetry without taking on an
  // analytics dependency. Tests leave both null.
  GatingService.onAnalyticsEvent = (event, props) =>
      analytics.track(event, properties: props);
  DailyCapSheet.onAnalyticsEvent = (event, props) =>
      analytics.track(event, properties: props);
  // Retention core-loop telemetry (2026-06-01): the daily-loop notifier has no
  // Riverpod access, so bridge its check_in_completed event the same way.
  DailyLoopNotifier.onAnalyticsEvent = (event, props) =>
      analytics.track(event, properties: props);
  // Duas + Journal telemetry (2026-06-15): the Duas/Reflect notifiers have no
  // Riverpod access, so bridge `dua_built` / `journal_entry_created` the same
  // way (so the 6/19 reassessment can measure both guided-tour features).
  DuasNotifier.onAnalyticsEvent = (event, props) =>
      analytics.track(event, properties: props);
  ReflectNotifier.onAnalyticsEvent = (event, props) =>
      analytics.track(event, properties: props);
  // Re-engagement attribution (2026-06-01): notification taps emit
  // `notification_opened` so we can measure push CTR / notification→session.
  NotificationService.onAnalyticsEvent = (event, props) =>
      analytics.track(event, properties: props);

  // Engagement & economy analytics (retention audit 2026-06-01). The card
  // grant + streak service functions are top-level (no Riverpod), so they emit
  // through these static hooks. See
  // docs/superpowers/plans/2026-06-01-engagement-economy-analytics.md.
  CardCollectionAnalytics.onAnalyticsEvent = (event, props) =>
      analytics.track(event, properties: props);
  StreakAnalytics.onAnalyticsEvent = (event, props) =>
      analytics.track(event, properties: props);
  // Identity hygiene (2026-06-15 audit, D2): reset Mixpanel's distinct_id on
  // sign-out so a shared/QA device doesn't bleed one user's identity into the
  // next. AppSessionNotifier has no Riverpod access, so it calls this static
  // hook from its signedOut branch (after final events are queued).
  AppSessionNotifier.onAnalyticsReset = analytics.resetForSignOut;

  final appSession = AppSessionNotifier(
    authService: AuthService(),
    notificationService: notificationService,
    initialOnboarded: onboardingCompleted,
  );

  runApp(
    ProviderScope(
      overrides: [
        appSessionProvider.overrideWithValue(appSession),
        cachedOnboardingStateProvider.overrideWithValue(cachedOnboardingState),
        analyticsProvider.overrideWithValue(analytics),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: AppLifecycleObserver(
        child: SakinaApp(appSession: appSession),
      ),
    ),
  );
}

class SakinaApp extends StatelessWidget {
  const SakinaApp({required this.appSession, super.key});

  final AppSessionNotifier appSession;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sakina',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: buildRouter(appSession: appSession),
      builder: (context, child) => Column(
        children: [
          const BillingIssueBanner(),
          const IapToSubUpsellBanner(),
          Expanded(
            child: OnboardingTourOverlayHost(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_lifecycle_observer.dart';
import 'core/app_session.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'services/analytics_events.dart';
import 'services/analytics_provider.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/public_catalog_service.dart';
import 'services/purchase_service.dart';
import 'widgets/billing_issue_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Load onboarding flag and cached onboarding state
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  final cachedOnboardingState = await OnboardingNotifier.loadFromPrefs();

  // Initialize Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  await bootstrapPublicCatalogs();
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    unawaited(refreshPublicCatalogsFromSupabase());
  }

  if (!kIsWeb) {
    try {
      await PurchaseService().initialize(
        appleApiKey: dotenv.env['REVENUECAT_API_KEY_APPLE'] ?? '',
        googleApiKey: dotenv.env['REVENUECAT_API_KEY_GOOGLE'] ?? '',
      );
    } catch (_) {
      // Best-effort — app should launch even if RevenueCat is unavailable.
      // PurchaseService methods will return safe defaults when not initialized.
    }
  }

  final notificationService = NotificationService();
  if (!kIsWeb) {
    await notificationService.initialize(dotenv.env['ONESIGNAL_APP_ID'] ?? '');
    notificationService.addForegroundListener();
    notificationService.addClickListener();
  }

  // Initialize Mixpanel analytics (not supported on web)
  final analytics = AnalyticsService();
  if (!kIsWeb) {
    await analytics.initialize(dotenv.env['MIXPANEL_TOKEN'] ?? '');
  }
  analytics.setSuperPropertiesOnce({
    'first_open_date': DateTime.now().toIso8601String(),
  });
  analytics.setSuperProperties({
    'platform': defaultTargetPlatform.name,
    'app_version': '1.0.0',
  });
  analytics.track(AnalyticsEvents.appOpened, properties: {
    'is_first_open': !onboardingCompleted,
  });

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
          Expanded(child: child ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}

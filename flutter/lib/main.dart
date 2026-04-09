import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_session.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'services/auth_service.dart';

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

  final appSession = AppSessionNotifier(
    authService: AuthService(),
    initialOnboarded: onboardingCompleted,
  );

  runApp(
    ProviderScope(
      overrides: [
        appSessionProvider.overrideWithValue(appSession),
        cachedOnboardingStateProvider.overrideWithValue(cachedOnboardingState),
      ],
      child: SakinaApp(appSession: appSession),
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
    );
  }
}

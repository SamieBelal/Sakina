/// Compile-time environment values, injected via `--dart-define-from-file`.
///
/// Replaces the prior `flutter_dotenv` runtime asset load. Bundled-as-asset
/// `.env` was extractable from the signed IPA; `String.fromEnvironment`
/// values land inside the compiled Dart snapshot which is meaningfully
/// harder (though not impossible) to extract.
///
/// ## Local dev
///   flutter run --dart-define-from-file=env.json
///
/// ## TestFlight / release
///   flutter build ios --release --dart-define-from-file=env.json
///
/// ## Server-only secrets
/// `SUPABASE_SERVICE_ROLE_KEY` and `REVENUECAT_WEBHOOK_SECRET` are NOT in
/// `env.json` — they must never reach the client binary. Keep those in
/// the local `.env` (for tools/scripts) and Supabase Edge Function secrets.
///
/// ## Future hardening
/// `OPENAI_API_KEY` should move behind a Supabase Edge Function so the
/// client never holds it. Bundling it (even as a compile-time constant)
/// is a credit-spend risk if extracted.
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String revenueCatApiKeyApple =
      String.fromEnvironment('REVENUECAT_API_KEY_APPLE');
  static const String revenueCatApiKeyGoogle =
      String.fromEnvironment('REVENUECAT_API_KEY_GOOGLE');
  static const String mixpanelToken = String.fromEnvironment('MIXPANEL_TOKEN');
  static const String oneSignalAppId =
      String.fromEnvironment('ONESIGNAL_APP_ID');
  static const String googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const String googleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
}

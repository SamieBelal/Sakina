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

  /// Compile-time kill switch for the onboarding rating gate. Defaults to
  /// `true` so a missing env entry doesn't silently disable the gate; flip
  /// to `"false"` in `env.json` and rebuild to roll back without an App
  /// Review cycle. See docs/superpowers/plans/2026-05-14-rating-gate.md
  /// (Rollback / Kill Switch).
  static const bool ratingGateEnabled =
      bool.fromEnvironment('RATING_GATE_ENABLED', defaultValue: true);

  /// Compile-time kill switch for paywall animations (breathing CTA Text
  /// and gold shimmer on the SAVE badge). Defaults to `true`; flip to
  /// `"false"` in `env.json` and rebuild to disable both without an App
  /// Review cycle. See docs/superpowers/plans/2026-05-14-paywall-rebuild.md
  /// (Rollback / Kill Switch).
  static const bool paywallAnimationsEnabled =
      bool.fromEnvironment('PAYWALL_ANIMATIONS_ENABLED', defaultValue: true);

  /// Compile-time kill switch for the rotating testimonials overlay on
  /// `GeneratingScreen`. Defaults to `false` in v1 because Sakina is
  /// pre-launch and has no real, attributable reviews to quote — fabricated
  /// testimonials violate Apple guideline 3.1.1 and FTC endorsement rules.
  /// Flip to `"true"` only after replacing the `FAKE_DO_NOT_SHIP_`
  /// placeholders in `AppStrings.generatingTestimonials` with real,
  /// permissioned reviews. The CI grep gate
  /// (`scripts/check_no_fake_strings.sh`) is the second line of defense.
  static const bool paywallTestimonialsEnabled =
      bool.fromEnvironment('PAYWALL_TESTIMONIALS_ENABLED', defaultValue: false);

  /// Compile-time kill switch for the Blinkist-style explicit honest-billing
  /// footer beneath the paywall CTA. Defaults to `true`; flip to `"false"`
  /// in `env.json` and rebuild to hide the footer without an App Review
  /// cycle (e.g. if App Review pushes back on the literal price quote,
  /// which is the Blinkist pattern Apple has approved elsewhere).
  static const bool paywallHonestBillingEnabled =
      bool.fromEnvironment('PAYWALL_HONEST_BILLING_ENABLED',
          defaultValue: true);
}

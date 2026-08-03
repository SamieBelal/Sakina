/// The home-screen widgets offered during onboarding (One Ship W2 Wave G).
///
/// These mirror the three entries in `ios/SakinaWidget/SakinaWidgetBundle.swift`
/// — the names here MUST match the `configurationDisplayName` strings exactly,
/// because the instructional sheet tells the user to search the widget gallery
/// for them. A rename on either side breaks the instruction silently, which is
/// why `onboarding_widget_carousel_test.dart` pins the strings.
///
/// **Order MATCHES the gallery exactly** (founder decision 2026-07-29):
/// Duʿā Times → A Name for What You're Carrying → Your Lantern.
///
/// An earlier draft led with the lantern, on the reasoning that the user had
/// just watched it light. That was rejected in favour of the simpler and more
/// honest thing: the carousel is a preview of a list the user is about to go
/// find in the iOS widget gallery, and a preview whose order differs from the
/// real thing makes the how-to sheet harder to follow, not easier. Reordering
/// the BUNDLE was never on the table — it would change the gallery for every
/// existing user.
library;

/// One card in the onboarding widget carousel.
class OnboardingWidgetOption {
  const OnboardingWidgetOption({
    required this.kind,
    required this.galleryName,
    required this.line,
    required this.previewAsset,
  });

  /// Stable snake_case key for analytics. Never localized.
  final String kind;

  /// EXACT `configurationDisplayName` from the widget bundle — what the user
  /// will read in the iOS widget gallery.
  final String galleryName;

  /// One line on what it does for them.
  final String line;

  /// A REAL screenshot of this widget on a Home Screen, cropped to the card
  /// plus ~8pt of wallpaper (founder, 2026-07-29). See `WidgetPreviewCard` for
  /// what the crop may and may not contain — Apple's Home Screen rule is the
  /// binding constraint, not taste.
  ///
  /// Registered under `assets/images/widget_previews/` in `pubspec.yaml`; that
  /// directory needs its own entry because Flutter asset dirs are not
  /// recursive, and a missing one fails at RUNTIME.
  final String previewAsset;
}

/// The one option whose widget cannot work without location. A widget extension
/// can never request it, so choosing this card is the only point of use the app
/// can reach to ask.
const String kDuaTimesWidgetKind = 'dua_times';

const List<OnboardingWidgetOption> onboardingWidgetOptions = [
  OnboardingWidgetOption(
    kind: 'dua_times',
    galleryName: 'Duʿā Times',
    line: 'The next window for duʿā.',
    previewAsset: 'assets/images/widget_previews/widget_dua_times.png',
  ),
  OnboardingWidgetOption(
    kind: 'daily_name',
    galleryName: "A Name for What You're Carrying",
    line: "Today's Name, on your home screen.",
    previewAsset: 'assets/images/widget_previews/widget_daily_name.png',
  ),
  OnboardingWidgetOption(
    kind: 'lantern',
    galleryName: 'Your Lantern',
    line: 'Your streak, lit.',
    previewAsset: 'assets/images/widget_previews/widget_lantern.png',
  ),
];

/// The home-screen widgets offered during onboarding (One Ship W2 Wave G).
///
/// These mirror the three entries in `ios/SakinaWidget/SakinaWidgetBundle.swift`
/// — the names here MUST match the `configurationDisplayName` strings exactly,
/// because the instructional sheet tells the user to search the widget gallery
/// for them. A rename on either side breaks the instruction silently, which is
/// why `onboarding_widget_carousel_test.dart` pins the strings.
///
/// **Order deliberately differs from the gallery.** The bundle declares
/// Duʿā Times → Name → Lantern (product priority). Onboarding leads with the
/// lantern because the user has just watched it light, and the carousel is that
/// moment's continuation. Reordering the bundle itself was considered and
/// rejected: it would change the gallery for every existing user (open item 3
/// in the W2 plan).
library;

/// One card in the onboarding widget carousel.
class OnboardingWidgetOption {
  const OnboardingWidgetOption({
    required this.kind,
    required this.galleryName,
    required this.line,
  });

  /// Stable snake_case key for analytics. Never localized.
  final String kind;

  /// EXACT `configurationDisplayName` from the widget bundle — what the user
  /// will read in the iOS widget gallery.
  final String galleryName;

  /// One line on what it does for them.
  final String line;
}

const List<OnboardingWidgetOption> onboardingWidgetOptions = [
  OnboardingWidgetOption(
    kind: 'lantern',
    galleryName: 'Your Lantern',
    line: 'Your streak, lit.',
  ),
  OnboardingWidgetOption(
    kind: 'daily_name',
    galleryName: "A Name for What You're Carrying",
    line: "Today's Name, on your home screen.",
  ),
  OnboardingWidgetOption(
    kind: 'dua_times',
    galleryName: 'Duʿā Times',
    line: 'The next window for duʿā.',
  ),
];

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
    kind: 'dua_times',
    galleryName: 'Duʿā Times',
    line: 'The next window for duʿā.',
  ),
  OnboardingWidgetOption(
    kind: 'daily_name',
    galleryName: "A Name for What You're Carrying",
    line: "Today's Name, on your home screen.",
  ),
  OnboardingWidgetOption(
    kind: 'lantern',
    galleryName: 'Your Lantern',
    line: 'Your streak, lit.',
  ),
];

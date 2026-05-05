import 'package:flutter_test/flutter_test.dart';

import 'package:sakina/core/constants/allah_names.dart';
import 'package:sakina/features/progress/screens/progress_screen.dart';
import 'package:sakina/services/card_collection_service.dart';

/// Regression tests for the home dashboard hero-tile selection.
///
/// Bug history (2026-05-04): home tile in `progress_screen.dart` always
/// rendered `getTodaysName()` (date-rotation), so a brand-new user who
/// had just bonded with their starter Name in onboarding would see a
/// completely different Name as soon as they reached the home screen.
/// User reported it as "Al-Quddus persisting across account deletions"
/// — actually just today's date hitting `allahNames[3]` for every user.
///
/// Fix: on day 0 (`streakCount == 0`) and only when a starter Name is
/// available, surface the starter Name with the label "Your Starting
/// Name". Once the user begins their first muhasabah and accrues a
/// streak, the date-rotation takes over.
void main() {
  const todays = AllahName(
    id: 4,
    arabic: 'الْقُدُّوسُ',
    transliteration: 'Al-Quddus',
    english: 'The Most Holy',
    meaning: 'Free from imperfection.',
    lesson: 'Your anchor of purity.',
  );

  const starter = CollectibleName(
    id: 9,
    arabic: 'الْجَبَّارُ',
    transliteration: 'Al-Jabbar',
    english: 'The Compeller',
    meaning: 'The mender of broken things.',
    lesson: 'He restores what life has shattered.',
  );

  test('day 0 + starter set → renders starter Name with starter label', () {
    final hero = resolveHomeHero(
      streakCount: 0,
      starter: starter,
      todays: todays,
    );

    expect(hero.label, 'Your Starting Name');
    expect(hero.arabic, 'الْجَبَّارُ');
    expect(hero.transliteration, 'Al-Jabbar');
    expect(hero.english, 'The Compeller');
    expect(hero.lesson, 'He restores what life has shattered.');
  });

  test('day 0 + no starter (older user, or pref not yet hydrated) → '
      'falls back to today\'s date-rotation Name', () {
    final hero = resolveHomeHero(
      streakCount: 0,
      starter: null,
      todays: todays,
    );

    expect(hero.label, "Today's Name");
    expect(hero.arabic, 'الْقُدُّوسُ');
    expect(hero.transliteration, 'Al-Quddus');
    expect(hero.english, 'The Most Holy');
    expect(hero.lesson, 'Your anchor of purity.');
  });

  test('day 1+ → date-rotation Name even when starter is still set, '
      'so the home tile evolves once the user starts engaging', () {
    final hero = resolveHomeHero(
      streakCount: 1,
      starter: starter,
      todays: todays,
    );

    expect(hero.label, "Today's Name");
    expect(hero.transliteration, 'Al-Quddus',
        reason:
            'Once the user has a streak, the daily-changing framing takes over.');
  });

  test('long-streak user with no starter set → date-rotation Name (sanity)',
      () {
    final hero = resolveHomeHero(
      streakCount: 42,
      starter: null,
      todays: todays,
    );

    expect(hero.label, "Today's Name");
    expect(hero.transliteration, 'Al-Quddus');
  });

  test(
      'switching from day 0 to day 1 with the same starter swaps both '
      'label and Name in lockstep — no half-state', () {
    final day0 = resolveHomeHero(
      streakCount: 0,
      starter: starter,
      todays: todays,
    );
    final day1 = resolveHomeHero(
      streakCount: 1,
      starter: starter,
      todays: todays,
    );

    expect(day0.label, 'Your Starting Name');
    expect(day0.transliteration, 'Al-Jabbar');
    expect(day1.label, "Today's Name");
    expect(day1.transliteration, 'Al-Quddus');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/intake_questions.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One Ship W2-H — the four single-tap intake questions and their consequences.
///
/// Spec §2 is the governing constraint and §10 turns it into a test: *for each
/// question, changing the answer changes something rendered.* These assert the
/// consequence FUNCTIONS the plan screen reads, so a later wave that deletes a
/// consequence and leaves the question standing fails here rather than shipping
/// an extractive form.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('H2 — when is it heaviest', () {
    test('keys are unique, stable and cover the spec set', () {
      final keys = heaviestTimes.map((o) => o.key).toList();
      expect(keys.toSet(), hasLength(keys.length));
      expect(keys, ['mornings', 'daytime', 'nights', 'alone', 'relentless']);
      expect(heaviestTimesByKey.keys, containsAll(keys));
    });

    test('every answer derives a distinct whole-hour reminder time', () {
      final times = <String>{};
      for (final option in heaviestTimes) {
        final time = heaviestReminderTime(option.key);
        expect(time, isNotNull, reason: option.key);
        expect(RegExp(r'^\d{2}:00$').hasMatch(time!), isTrue,
            reason: '${option.key} → $time is not a whole hour');
        times.add(time);
      }
      // Not strictly required by anything downstream, but a collision would
      // mean two answers the user experiences as different buy the same thing.
      expect(times, hasLength(heaviestTimes.length));
    });

    test('an unanswered question derives no time — never a guessed one', () {
      expect(heaviestReminderTime(null), isNull);
      expect(heaviestReminderTime('afternoonish'), isNull);
    });

    test('every answer changes the plan line', () {
      final lines = {
        for (final option in heaviestTimes) heaviestPlanLine(option.key),
      };
      expect(lines, hasLength(heaviestTimes.length));
      for (final line in lines) {
        expect(line, isNot(heaviestPlanLine(null)));
      }
    });

    test('answering writes the reminder time in the same mutation', () {
      final notifier = OnboardingNotifier();
      addTearDown(notifier.dispose);

      notifier.setHeaviestTime('nights');
      expect(notifier.state.heaviestTime, 'nights');
      expect(notifier.state.reminderTime, '21:00');

      // Re-answering must re-derive: a user who backs up and changes their mind
      // would otherwise keep a reminder at the hour they just rejected.
      notifier.setHeaviestTime('mornings');
      expect(notifier.state.reminderTime, '07:00');
    });
  });

  group('H3 — have you told anyone', () {
    test('keys are unique, stable and cover the spec set', () {
      final keys = toldAnyoneOptions.map((o) => o.key).toList();
      expect(keys.toSet(), hasLength(keys.length));
      expect(keys, ['someone_knows', 'a_little', 'no_one', 'rather_not_say']);
      expect(toldAnyoneOptionsByKey.keys, containsAll(keys));
    });

    test('"no one" and "a little" put the flow in the unspoken register', () {
      expect(toldAnyoneRegister('no_one'), ToldAnyoneRegister.unspoken);
      expect(toldAnyoneRegister('a_little'), ToldAnyoneRegister.unspoken);
      expect(toldAnyoneRegister('someone_knows'), ToldAnyoneRegister.spoken);
      // A decline is NOT read as "nobody knows" — that would put words in the
      // mouth of someone who withheld them on purpose.
      expect(toldAnyoneRegister('rather_not_say'), ToldAnyoneRegister.spoken);
      expect(toldAnyoneRegister(null), ToldAnyoneRegister.spoken);
    });

    test('the register changes the first notification body', () {
      expect(
        toldAnyoneFirstNotificationBody('no_one'),
        isNot(toldAnyoneFirstNotificationBody('someone_knows')),
      );
      expect(
        toldAnyoneFirstNotificationBody('a_little'),
        toldAnyoneFirstNotificationBody('no_one'),
      );
    });

    test('the binding condition: "no one" and "a little" change the plan line',
        () {
      final neutral = toldAnyonePlanLine(null);
      expect(toldAnyonePlanLine('no_one'), isNot(neutral));
      expect(toldAnyonePlanLine('a_little'), isNot(neutral));
      expect(toldAnyonePlanLine('someone_knows'), isNot(neutral));
      // Declining costs the user nothing and gets the same line as silence.
      expect(toldAnyonePlanLine('rather_not_say'), neutral);
    });
  });

  group('H4 — how many Names', () {
    test('keys are unique, stable and cover the spec set', () {
      final keys = namesKnownOptions.map((o) => o.key).toList();
      expect(keys.toSet(), hasLength(keys.length));
      expect(keys, ['few', 'ten', 'many', 'all']);
      expect(namesKnownOptionsByKey.keys, containsAll(keys));
    });

    test('baselines increase with the answer and stay inside the 99', () {
      final baselines = [
        for (final option in namesKnownOptions) namesKnownBaseline(option.key)!,
      ];
      for (var i = 1; i < baselines.length; i++) {
        expect(baselines[i], greaterThan(baselines[i - 1]));
      }
      expect(baselines.last, lessThanOrEqualTo(99));
    });

    test('unanswered has no baseline and therefore no projection', () {
      expect(namesKnownBaseline(null), isNull);
      expect(namesKnownBaseline('most of them'), isNull);
      expect(namesKnownProjectionLine(null), isNull);
    });

    test('the projection names the user\'s own number back at them', () {
      final line = namesKnownProjectionLine('few')!;
      expect(line, contains('5'));
      expect(line, contains('35'));
      // Every answer projects a different sentence — the whole point of asking.
      final lines = {
        for (final option in namesKnownOptions)
          namesKnownProjectionLine(option.key),
      };
      expect(lines, hasLength(namesKnownOptions.length));
    });

    test('the projection never promises a hundredth Name', () {
      expect(namesKnownProjectionLine('all'), isNot(contains('100')));
      expect(
        namesKnownBaseline('all')! + namesKnownProjectionGain,
        lessThanOrEqualTo(99),
      );
    });
  });

  group('H6 — how much time', () {
    test('keys are unique, stable and cover the spec set', () {
      final keys = dailyTimeOptions.map((o) => o.key).toList();
      expect(keys.toSet(), hasLength(keys.length));
      expect(keys, ['minute', 'few_minutes', 'as_long']);
      expect(dailyTimeOptionsByKey.keys, containsAll(keys));
    });

    test('every answer changes the pacing line', () {
      final lines = {
        for (final option in dailyTimeOptions) dailyTimePacingLine(option.key),
      };
      expect(lines, hasLength(dailyTimeOptions.length));
      for (final line in lines) {
        expect(line, isNot(dailyTimePacingLine(null)));
      }
    });

    test('deck length varies by answer and defaults to standard', () {
      expect(dailyTimeDeckLength('minute'), DeckLength.short);
      expect(dailyTimeDeckLength('few_minutes'), DeckLength.standard);
      expect(dailyTimeDeckLength('as_long'), DeckLength.full);
      expect(dailyTimeDeckLength(null), DeckLength.standard);
    });

    test('no option reads as the failure choice', () {
      // "Longer when I can" was rejected for implying a scarcity the user should
      // feel bad about. Nothing here may apologise for the answer it names.
      for (final option in dailyTimeOptions) {
        expect(option.label.toLowerCase(), isNot(contains('only')));
        expect(option.label.toLowerCase(), isNot(contains('when i can')));
        expect(option.label.toLowerCase(), isNot(contains('at least')));
      }
    });
  });

  group('H7 — the note', () {
    test('an empty or whitespace note clears rather than persists', () {
      final notifier = OnboardingNotifier();
      addTearDown(notifier.dispose);

      notifier.setIntakeNote('  my father died in March.  ');
      expect(notifier.state.intakeNote, 'my father died in March.');

      notifier.setIntakeNote('   ');
      expect(notifier.state.intakeNote, isNull);

      notifier.setIntakeNote('back again');
      expect(notifier.state.intakeNote, 'back again');
      notifier.setIntakeNote(null);
      expect(notifier.state.intakeNote, isNull);
    });

    test('a pathological paste is capped in graphemes', () {
      final notifier = OnboardingNotifier();
      addTearDown(notifier.dispose);

      notifier.setIntakeNote('e' * (intakeNoteMaxGraphemes + 500));
      expect(notifier.state.intakeNote, hasLength(intakeNoteMaxGraphemes));
    });
  });

  test('the intake answers survive a prefs round trip, order included', () {
    final notifier = OnboardingNotifier();
    addTearDown(notifier.dispose);
    notifier
      ..setHeaviestTime('nights')
      ..setToldAnyone('no_one')
      ..setNamesKnown('ten')
      ..setDailyTime('as_long')
      ..setIntakeNote('something to add')
      ..toggleHelpWith('sense')
      ..toggleHelpWith('words');

    final restored = OnboardingState.fromJson(notifier.state.toJson());

    expect(restored.heaviestTime, 'nights');
    expect(restored.reminderTime, '21:00');
    expect(restored.toldAnyone, 'no_one');
    expect(restored.namesKnown, 'ten');
    expect(restored.dailyTime, 'as_long');
    expect(restored.intakeNote, 'something to add');
    // Order is load-bearing — the blend weights by it.
    expect(restored.helpWith, ['sense', 'words']);
  });
}

// THE HARD RULE: the user's own words never leave the device.
//
// CLAUDE.md states it without qualification. The user types how they feel —
// "my father is dying", "I can't stop crying" — and that text goes to OpenAI to
// SELECT content. It must never reach analytics, a People profile, a log, or
// anything persisted as telemetry. Only bucketed or categorical derivatives.
//
// Two live violations were found by review on 2026-08-02, both pre-existing on
// master and both shipping with this branch:
//
//   1. `first_checkin_screen.dart` sent `emotion_text: _controller.text` —
//      the user's verbatim description of their emotional state.
//   2. `dua_topics_screen.dart` sent the free-text "other" topic as an EVENT
//      property, and `onboarding_screen.dart` also wrote it to the Mixpanel
//      PEOPLE profile — durable and queryable forever, which is strictly worse
//      than an event.
//
// Neither is reachable while `reel_first_onboarding_enabled` is true, because
// both screens live in the trimmed/legacy flows. That is not comfort: the kill
// switch IS the rollback path, so these were one config flip away from live —
// and an emergency rollback becoming a privacy incident is the worst possible
// time to discover it.
//
// This test is a SWEEP, not two assertions, because the class matters more than
// the instances. A grep over every analytics call site in `lib/` for a
// controller-backed value, which is what both violations looked like.
//
// MUTATION: restore `'emotion_text': _controller.text` in
// first_checkin_screen.dart → the sweep fails and names the file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no analytics call site passes raw controller text', () {
    // Checked per VALUE, not per call. The first version of this sweep allowed
    // an escape if the call contained `.isEmpty` anywhere — and the real
    // violation was:
    //
    //     'input_method': _controller.text.isEmpty ? 'chip' : 'typed',
    //     'emotion_text': _controller.text,
    //
    // where the bucketed line on top made the raw line below it invisible. A
    // guard that grades a whole call on its best line is not a guard.
    //
    // So: flag `.text` appearing as a BARE value — a map value or a positional
    // argument — regardless of what its neighbours do.
    final bareValue = RegExp(
      r"(?::\s*|,\s*)[\w.]*[Cc]ontroller\.text\s*[,)}]",
    );

    final offenders = <String>[];
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();
      for (final match in RegExp(
        r'(track|trackOnboardingAnswer\w*|setUserProperties|onAnalyticsEvent\?\.call)\s*\(',
      ).allMatches(source)) {
        final end = source.indexOf(';', match.start);
        final call =
            source.substring(match.start, end == -1 ? source.length : end);
        if (bareValue.hasMatch(call)) {
          offenders.add('${file.path}: ${call.split('\n').first.trim()}');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'These emit the user\'s own typed words. CLAUDE.md: the answer '
            'text NEVER leaves the device — send a bucket or a category.\n'
            '${offenders.join('\n')}');
  });

  test('no known free-text STATE field is emitted raw', () {
    // The `.text` sweep above only sees a controller. Once free text lands on
    // state it looks like any other field, so those are named explicitly —
    // honest and maintainable beats clever and wrong.
    //
    // Wave C (journaling) put four more on state. `tonightEntry` and
    // `timeMachineEntry` are whole `SavedReflection`s — the user's answer, their
    // appends and their resolve — and `lastNightAzm` / `azm` are the resolve on
    // its own. Storing them on the user's own RLS row is permitted (design D2);
    // putting any of them, or anything derived from them, into telemetry is not.
    //
    // **This list is an ALLOWLIST OF KNOWN NAMES, and that is its ceiling.** It
    // cannot see a field nobody added to it, so it is the mitigation for plan
    // risk 6 and not a solution to it: every wave that puts user text on state
    // owes this list a line in the same PR. Wave H's audit added the ones below
    // the Wave C block — several of them (`userText`, `checkinAnswers`,
    // `buildNeed`) predate Wave C entirely and were simply never named.
    const freeTextFields = [
      'duaTopicsOther',
      'intakeNote',
      'firstProblemText',
      // Wave C — the night's row, on the daily loop's state.
      'tonightEntry',
      'timeMachineEntry',
      'lastNightAzm',
      'azm',
      // Wave H audit. Pre-existing and unnamed until now:
      // `ReflectState.userText` is the Reflect free-write body verbatim, and
      // `SavedReflection.userText` is the same text on the row.
      'userText',
      // `DailyLoopState.checkinAnswers` / `checkinAnswer` — the muḥāsabah
      // answer. `daily_question_answered` already sends `charCountBucket` of
      // it, which is the only permitted shape.
      'checkinAnswers',
      'checkinAnswer',
      // `DuasState.buildNeed` / `findNeed` / `browseQuery` and
      // `SavedBuiltDua.need` — what the user typed they needed a duʿā for.
      // Wave E put `need` on a resurfacing card, so it now travels.
      'buildNeed',
      'findNeed',
      'browseQuery',
      'need',
      // Wave C's appends, as a list on the row. `thread.length` is fine and is
      // what `muhasabah_thread_appended` sends; `thread` itself is the words.
      'thread',
      // Wave E. `WeeklyRecap.oneLine` is documented as "one line the user
      // wrote, verbatim" — the single most quotable string in the app.
      'oneLine',
      // Wave E / C locals that WRAP a whole entry: `resolveOnThisNight`'s
      // result and the time-machine anchor. Named because a card's props are
      // the obvious thing to hand an emit.
      'onThisNight',
      'anchor',
    ];
    final offenders = <String>[];

    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();
      // `onAnalyticsEvent?.call` is in this sweep and was not before Wave H.
      // The first sweep has always included it, and the omission here was the
      // hole that mattered most: every provider in Waves B–E emits through the
      // static hook and NOT through `track()`, so the four Wave C fields this
      // list was created for were being checked at call sites they can never
      // reach. The ONE emit path they can reach was unscanned.
      for (final match in RegExp(
        r'(track|trackOnboardingAnswer\w*|setUserProperties|onAnalyticsEvent\?\.call)\s*\(',
      ).allMatches(source)) {
        final end = source.indexOf(';', match.start);
        final call =
            source.substring(match.start, end == -1 ? source.length : end);
        for (final field in freeTextFields) {
          final bare = RegExp(
            r'(?::\s*|,\s*)[\w.]*\b' + field + r'\b\s*[,)}]',
          );
          if (bare.hasMatch(call)) {
            offenders.add('${file.path}: $field');
          }
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'A free-text state field is being emitted raw:\n'
            '${offenders.join('\n')}');
  });

  test('no People profile property carries a free-text field', () {
    // Worse than an event: a People property is durable and queryable forever,
    // so one bad write outlives every session that produced it.
    final source =
        File('lib/features/onboarding/screens/onboarding_screen.dart')
            .readAsStringSync();

    expect(
      source.contains("profileProps['dua_topics_other']"),
      isFalse,
      reason: 'the free-text "other" duʿā topic must not become a durable '
          'Mixpanel profile attribute — a user can write anything there',
    );
  });

  test('the sweep is not vacuous — it finds emits at all', () {
    // A regex that matches nothing passes forever and guards nothing. This
    // asserts the sweep's own machinery still sees the codebase.
    final emitPattern = RegExp(r'(track|onAnalyticsEvent\?\.call)\s*\(');
    var seen = 0;
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      seen += emitPattern.allMatches(file.readAsStringSync()).length;
    }
    expect(seen, greaterThan(50),
        reason: 'the sweep should be scanning hundreds of emit sites');
  });
}

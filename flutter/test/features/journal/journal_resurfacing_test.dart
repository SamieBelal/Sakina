// Wave E — the three resurfacing rules, as pure functions.
//
// Everything here is a rule about WHEN the app speaks, and every one of them is
// mostly a rule about when it stays quiet. The failure mode these tests exist to
// catch is not "the card is wrong", it is "the card is there" — an archive that
// opens with three prompts every day is the thing the design brief forbids.

import 'package:flutter_test/flutter_test.dart';

import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/journal/journal_resurfacing.dart';
import 'package:sakina/features/journal/journal_themes.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';

void main() {
  SavedReflection muhasabah({
    required String day,
    String id = 'm',
    String words = 'I could not sleep.',
    String name = 'Al-Halim',
    List<ReflectionThreadEntry> thread = const [],
  }) =>
      SavedReflection(
        id: '$id-$day',
        date: '${day}T21:00:00.000',
        userText: words,
        name: name,
        nameArabic: 'الحليم',
        reframePreview: 'x',
        source: reflectionSourceMuhasabah,
        entryLocalDay: day,
        thread: thread,
      );

  SavedBuiltDua builtDua({
    required String id,
    required String savedAt,
    String need = 'A job that lets me pray on time.',
    String status = builtDuaStatusOpen,
    String? answeredAt,
  }) =>
      SavedBuiltDua(
        id: id,
        savedAt: savedAt,
        need: need,
        arabic: 'ا',
        transliteration: 't',
        translation: 'tr',
        status: status,
        answeredAt: answeredAt,
      );

  group('E1 — On This Night', () {
    test('reuses Wave C\'s anchor rule rather than a second lookup', () {
      // The proof that these are one rule and not two: the journal resolver and
      // the completion screen's lookup must answer identically over the same
      // entries. If someone re-implements one of them, this diverges.
      final entries = [
        muhasabah(day: '2026-07-03'), // -30
        muhasabah(day: '2026-08-01'),
      ];
      final direct = selectTimeMachineAnchor(entries, '2026-08-02');
      final viaE1 = resolveOnThisNight(
        entries: entries,
        todayLocalDay: '2026-08-02',
      );
      expect(viaE1, isNotNull);
      expect(viaE1!.entry.id, direct!.id);
      expect(viaE1.offsetDays, 30);
    });

    test('prefers the nearest anchor, so a month beats a year', () {
      final onThisNight = resolveOnThisNight(
        entries: [
          muhasabah(day: '2025-08-02', words: 'a year ago'), // -365
          muhasabah(day: '2026-07-03', words: 'a month ago'), // -30
        ],
        todayLocalDay: '2026-08-02',
      );
      expect(onThisNight!.offsetDays, 30);
      expect(onThisNight.entry.userText, 'a month ago');
    });

    test('matches the exact day and nothing near it', () {
      // The pattern's whole force is "this is what you wrote on this same
      // date". A fuzzy window turns it into "here is an old entry".
      expect(
        resolveOnThisNight(
          entries: [muhasabah(day: '2026-07-04')], // -29
          todayLocalDay: '2026-08-02',
        ),
        isNull,
      );
    });

    test('a Reflect save is never an anchor, even on the exact day', () {
      // "On this night" is about the nightly accounting. A Reflect save is not
      // a night, and it has no entry_local_day to be filed under.
      const reflectSave = SavedReflection(
        id: 'r1',
        date: '2026-07-03T10:00:00.000',
        userText: 'not a night',
        name: 'Al-Wakeel',
        nameArabic: 'الوكيل',
        reframePreview: 'x',
      );
      expect(
        resolveOnThisNight(
            entries: [reflectSave], todayLocalDay: '2026-08-02'),
        isNull,
      );
    });

    test('says nothing for a user younger than the nearest anchor', () {
      expect(
        resolveOnThisNight(
          entries: [muhasabah(day: '2026-08-01')],
          todayLocalDay: '2026-08-02',
        ),
        isNull,
      );
    });

    test('says nothing when the local day could not be resolved', () {
      expect(
        resolveOnThisNight(
          entries: [muhasabah(day: '2026-07-03')],
          todayLocalDay: null,
        ),
        isNull,
      );
    });
  });

  group('E2 — the weekly recap', () {
    test('summarises the trailing seven nights, today included', () {
      final recap = resolveWeeklyRecap(
        entries: [
          muhasabah(day: '2026-08-02', words: 'work is crushing me', name: 'Al-Wakeel'),
          muhasabah(day: '2026-07-30', words: 'anxious about the exam', name: 'Al-Halim'),
          muhasabah(day: '2026-07-27', words: 'grateful for today', name: 'Al-Wakeel'),
          // Outside the window (7 nights counting today = 2026-07-27..08-02).
          muhasabah(day: '2026-07-26', words: 'should be excluded', name: 'Al-Barr'),
        ],
        todayLocalDay: '2026-08-02',
      );

      expect(recap, isNotNull);
      expect(recap!.entryCount, 3);
      // Newest first, de-duplicated.
      expect(recap.names, ['Al-Wakeel', 'Al-Halim']);
      expect(recap.themes, isNotEmpty);
      expect(recap.oneLine, isNot(contains('excluded')));
    });

    test('one entry is not a week', () {
      expect(
        resolveWeeklyRecap(
          entries: [muhasabah(day: '2026-08-02')],
          todayLocalDay: '2026-08-02',
        ),
        isNull,
      );
    });

    test('a Reflect save counts, filed by its saved_at date', () {
      // The fallback that covers every row with no entry_local_day — Reflect
      // saves, and everything written before Wave B.
      final recap = resolveWeeklyRecap(
        entries: [
          muhasabah(day: '2026-08-02'),
          const SavedReflection(
            id: 'r1',
            date: '2026-07-31T09:00:00.000',
            userText: 'the interview is tomorrow',
            name: 'Al-Wakeel',
            nameArabic: 'الوكيل',
            reframePreview: 'x',
          ),
        ],
        todayLocalDay: '2026-08-02',
      );
      expect(recap!.entryCount, 2);
    });

    test('the one line is a LINE, and thread appends are eligible', () {
      final recap = resolveWeeklyRecap(
        entries: [
          muhasabah(
            day: '2026-08-02',
            words: 'short\nI have been carrying this since February and '
                'tonight is the first time I said it out loud',
            thread: const [],
          ),
          muhasabah(day: '2026-08-01', id: 'b', words: 'also short'),
        ],
        todayLocalDay: '2026-08-02',
      );
      expect(recap!.oneLine, startsWith('I have been carrying this'));
      expect(recap.oneLine, isNot(contains('\n')),
          reason: 'a recap promises one line, not six paragraphs under a lead '
              'that says "you wrote:"');

      final withAppend = resolveWeeklyRecap(
        entries: [
          muhasabah(
            day: '2026-08-02',
            words: 'short',
            thread: const [
              ReflectionThreadEntry(
                at: '2026-08-02T22:00:00.000Z',
                text: 'the append is often the more candid half of the night '
                    'and it is eligible on purpose',
              ),
            ],
          ),
          muhasabah(day: '2026-08-01', id: 'b', words: 'also short'),
        ],
        todayLocalDay: '2026-08-02',
      );
      expect(withAppend!.oneLine, startsWith('the append is often'));
    });

    test('is deterministic — the same journal recaps the same way', () {
      List<SavedReflection> entries() => [
            muhasabah(day: '2026-08-02', words: 'worried about work'),
            muhasabah(day: '2026-08-01', id: 'b', words: 'worried about money'),
          ];
      final a = resolveWeeklyRecap(
          entries: entries(), todayLocalDay: '2026-08-02')!;
      final b = resolveWeeklyRecap(
          entries: entries(), todayLocalDay: '2026-08-02')!;
      expect(a.themes, b.themes);
      expect(a.names, b.names);
      expect(a.oneLine, b.oneLine);
    });

    test('survives a week whose words match no theme bucket', () {
      final recap = resolveWeeklyRecap(
        entries: [
          muhasabah(day: '2026-08-02', words: 'zzz qqq'),
          muhasabah(day: '2026-08-01', id: 'b', words: 'mmm nnn'),
        ],
        todayLocalDay: '2026-08-02',
      );
      expect(recap, isNotNull);
      expect(recap!.themes, isEmpty);
      expect(recap.entryCount, 2);
    });
  });

  group('the shared theme buckets', () {
    test('the lifetime line and the recap read the same list', () {
      final entries = [
        muhasabah(day: '2026-08-02', words: 'anxious'),
        muhasabah(day: '2026-08-01', id: 'b', words: 'stressed'),
        muhasabah(day: '2026-07-31', id: 'c', words: 'worried'),
      ];
      expect(journalTopTheme(entries), 'Anxiety & Worry');
      expect(journalTopThemes(entries, limit: 1), ['Anxiety & Worry']);
    });

    test('the lifetime line stays quiet under three entries', () {
      expect(
        journalTopTheme([muhasabah(day: '2026-08-02', words: 'anxious')]),
        isNull,
      );
    });
  });

  group('E3 — the answered duʿā prompt', () {
    final now = DateTime.utc(2026, 8, 2, 20);

    test('asks about the OLDEST still-open duʿā', () {
      final prompt = selectAnsweredDuaPrompt(
        duas: [
          builtDua(id: 'recent', savedAt: '2026-06-02T10:00:00.000Z'),
          builtDua(id: 'oldest', savedAt: '2026-04-02T10:00:00.000Z'),
        ],
        now: now,
      );
      expect(prompt!.dua.id, 'oldest');
      expect(prompt.elapsedLabel, 'four months');
    });

    test('never asks about one already marked answered', () {
      expect(
        selectAnsweredDuaPrompt(
          duas: [
            builtDua(
              id: 'done',
              savedAt: '2026-04-02T10:00:00.000Z',
              status: builtDuaStatusAnswered,
              answeredAt: '2026-07-01T10:00:00.000Z',
            ),
          ],
          now: now,
        ),
        isNull,
      );
    });

    test('never asks about a duʿā younger than the floor', () {
      // "You asked for this a month ago" has to be true. Twenty-nine days is a
      // receipt for something the user did this month.
      expect(
        selectAnsweredDuaPrompt(
          duas: [builtDua(id: 'fresh', savedAt: '2026-07-20T10:00:00.000Z')],
          now: now,
        ),
        isNull,
      );
    });

    test('"Not yet" is honoured until it expires, then the duʿā returns', () {
      final duas = [builtDua(id: 'd1', savedAt: '2026-04-02T10:00:00.000Z')];

      expect(
        selectAnsweredDuaPrompt(
          duas: duas,
          now: now,
          snoozedUntil: {'d1': now.add(const Duration(days: 30))},
        ),
        isNull,
      );

      expect(
        selectAnsweredDuaPrompt(
          duas: duas,
          now: now,
          snoozedUntil: {'d1': now.subtract(const Duration(days: 1))},
        ),
        isNotNull,
        reason: 'a snooze expires — it is "not now", never "never again"',
      );
    });

    test('one at a time, always — there is no queue to work through', () {
      final prompt = selectAnsweredDuaPrompt(
        duas: [
          for (var i = 0; i < 10; i++)
            builtDua(id: 'd$i', savedAt: '2026-0${i % 5 + 1}-02T10:00:00.000Z'),
        ],
        now: now,
      );
      // The selector's return type is the guarantee: one, or none.
      expect(prompt, isA<AnsweredDuaPrompt?>());
      expect(prompt, isNotNull);
    });

    test('an unparseable saved_at is skipped, not crashed on', () {
      expect(
        selectAnsweredDuaPrompt(
          duas: [builtDua(id: 'bad', savedAt: 'not-a-date')],
          now: now,
        ),
        isNull,
      );
    });
  });

  group('describeDuaAge — vague on purpose', () {
    test('rounds to the words a person would use', () {
      expect(describeDuaAge(30), 'a month');
      expect(describeDuaAge(44), 'a month');
      expect(describeDuaAge(60), 'two months');
      expect(describeDuaAge(122), 'four months');
      expect(describeDuaAge(300), 'ten months');
      expect(describeDuaAge(365), 'a year');
      expect(describeDuaAge(800), 'two years');
    });

    test('never emits a raw day count', () {
      for (var days = 30; days < 3000; days += 7) {
        expect(describeDuaAge(days), isNot(contains(RegExp(r'\d'))),
            reason: 'precision here reads as surveillance, not memory');
      }
    });
  });
}

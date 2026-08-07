// A second muḥāsabah on the same day keeps its words (2026-08-07).
//
// Reported from a QA device as *"a new check-in was processed, but the app
// retained the previous entry and showed 'Today already had an entry'"*.
//
// The path is the completion screen's own primary CTA. **"Seek Another Name"
// calls `resetToday()`**, which wipes state to `const DailyLoopState()` and
// deletes the day blob — so `checkinDone` and `deeperDone` go false and the
// whole ceremony re-runs: a new question, a NEW TYPED ANSWER, a new Name, new
// beats, "Ameen". `_persistMuhasabahEntry` then builds a row,
// `saveMuhasabahReflection` refuses it at the local cache check, and the
// completion screen falls back to the FIRST run's row.
//
// Everything the user typed the second time was dropped on the floor. It lived
// only in `checkinAnswers` and the per-day blob, and the blob is never read
// again once the day rolls over. Free users reach this by paying 25 tokens at
// the cap sheet; premium has 30/day fair-use. Either way they spent something
// and got no artifact.
//
// ⚠️ The dartdoc on `DailyLoopState.tonightEntryIsReplay` claimed the
// `!checkinDone` gate made this rare and second-device-only. It does not:
// `resetToday()` clears `checkinDone`, so this is deterministic, on ONE device,
// from the CTA the screen puts in front of every reader.
//
// The fix keeps the one-row-per-local-day invariant — the time machine joins on
// it, `setTonightAzm` and the thread assume it, and "one day, one accounting" is
// the concept — and folds the refused answer into that row's THREAD, which is
// the mechanism the app already has for "more words on today's entry".
//
// MUTATION: delete the fold call in `_persistMuhasabahEntry` → group 1 fails and
// names the words that went missing.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';

import '../../support/fake_supabase_sync_service.dart';

/// A sync service whose row UPDATE throws rather than returning false.
///
/// The real [SupabaseSyncService.upsertRawRow] catches its own exceptions, but
/// the fold's other half does not: `_replaceInReflectionCache` writes prefs, and
/// a prefs write can throw on a full or unavailable store. This is the shape of
/// that failure, and the point is that it must not travel any further.
class _ThrowingUpdateSync extends FakeSupabaseSyncService {
  _ThrowingUpdateSync({super.userId});

  @override
  Future<bool> upsertRawRow(
    String table,
    Map<String, dynamic> data, {
    String? onConflict,
  }) async {
    if (table == 'user_reflections') throw StateError('prefs unavailable');
    return super.upsertRawRow(table, data, onConflict: onConflict);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  late FakeSupabaseSyncService fakeSync;

  /// 2026-08-03 01:27 UTC — 6:27pm on Aug 2 in Los Angeles. The same instant the
  /// Wave B and C suites use, so all three agree about which night this is.
  final tonight = DateTime.utc(2026, 8, 3, 1, 27);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'America/Los_Angeles';
    debugDailyLoopClock = () => tonight;
  });

  tearDown(() {
    debugDailyLoopClock = () => DateTime.now().toUtc();
    debugUserTimeZoneOverride = null;
    debugResetUserLocalDay();
    SupabaseSyncService.debugReset();
    DailyLoopNotifier.onAnalyticsEvent = null;
    ReflectNotifier.onAnalyticsEvent = null;
  });

  const response = ReflectResponse(
    name: 'Al-Halim',
    nameArabic: 'الحليم',
    reframe: 'Al-Halim withholds, and gives you the room to return.',
    story: 'The companions rose. The Prophet did not.',
    duaArabic: 'اللهم',
    duaTransliteration: 'Allahumma',
    duaTranslation: 'O Allah, make me forbearing.',
    duaSource: 'Bukhari 220',
    relatedNames: [],
    offTopic: false,
    reframeKey: 'He did not answer your anger with His',
    reframeBody: 'Forbearance is not indifference.',
    storyTitle: 'The Bedouin in the Masjid',
    storyBeats: ['The companions rose.', 'The Prophet did not.'],
    storySource: 'Bukhari 220',
    takeaway: 'Forbearance is a choice made when it costs most.',
  );

  const firstWords = 'I snapped at my brother and I have been sitting with it.';
  const secondWords = 'I went back and said sorry, and he barely looked up.';

  const answeredNight = DailyLoopState(
    loaded: true,
    checkinDone: true,
    checkinAnswers: [firstWords],
    checkinName: 'Al-Halim',
    checkinNameArabic: 'الحليم',
    reflectResult: response,
  );

  List<Map<String, dynamic>> reflectionInserts() => fakeSync.insertCalls
      .where((c) => c['table'] == 'user_reflections')
      .map((c) => c['data'] as Map<String, dynamic>)
      .toList();

  Future<List<SavedReflection>> cachedReflections() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(fakeSync.scopedKey('saved_reflections'));
    if (raw == null) return const [];
    return (jsonDecode(raw) as List)
        .map((e) => SavedReflection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  DailyLoopNotifier notifierWith(DailyLoopState state) {
    final notifier = DailyLoopNotifier(skipInitForTests: true);
    addTearDown(notifier.dispose);
    notifier.debugSetState(state);
    return notifier;
  }

  /// The first run of the night, on a notifier that is then thrown away — the
  /// `resetToday()` in "Seek Another Name" wipes state to a fresh
  /// `DailyLoopState`, so the second run must not be able to lean on anything
  /// the first one left in memory.
  Future<void> firstRun() async {
    final first = DailyLoopNotifier(skipInitForTests: true);
    first.debugSetState(answeredNight);
    await first.completeDeeper();
    first.dispose();
  }

  /// The second run: a different answer, a different Name, same local day.
  DailyLoopNotifier secondRun({
    List<String> answers = const [secondWords],
    String name = 'Al-Majeed',
  }) =>
      notifierWith(answeredNight.copyWith(
        checkinAnswers: answers,
        checkinName: name,
        checkinNameArabic: 'الْمَجِيدُ',
      ));

  /// Writes the reflections cache directly, for the cases that need a day whose
  /// entry is already in a particular shape (a full thread, words already
  /// added). Cheaper and far clearer than driving twenty real appends.
  Future<void> seedDayEntry({
    String userText = firstWords,
    List<ReflectionThreadEntry> thread = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      fakeSync.scopedKey('saved_reflections'),
      jsonEncode([
        SavedReflection(
          id: 'seeded-entry',
          date: '2026-08-03T01:00:00.000Z',
          userText: userText,
          name: 'Al-Halim',
          nameArabic: 'الحليم',
          reframePreview: '',
          duaTranslation: 'O Allah, make me forbearing.',
          source: reflectionSourceMuhasabah,
          entryLocalDay: '2026-08-02',
          thread: thread,
        ).toJson(),
      ]),
    );
  }

  // ── The words survive ─────────────────────────────────────────────────────

  group('a second run the same day keeps its words', () {
    test('the answer is folded into the day\'s entry as a thread append',
        () async {
      await firstRun();
      await secondRun().completeDeeper();

      final entry = (await cachedReflections()).single;
      expect(entry.thread, hasLength(1),
          reason: 'the second answer is what the fix exists to keep');
      expect(entry.thread.single.text, secondWords);
      expect(entry.thread.single.at, isNotEmpty,
          reason: 'an append is stamped, like every other one');
    });

    test('and the first run\'s words are not touched', () async {
      await firstRun();
      await secondRun().completeDeeper();

      final entry = (await cachedReflections()).single;
      expect(entry.userText, firstWords,
          reason: 'the fold is an append, never an overwrite — the first run '
              'is still the night\'s answer');
      expect(entry.name, 'Al-Halim',
          reason: 'and the row keeps the Name it was written with');
    });

    test('the day still has exactly ONE muḥāsabah row', () async {
      await firstRun();
      await secondRun().completeDeeper();

      expect(reflectionInserts(), hasLength(1),
          reason: 'uniq_muhasabah_per_local_day is the invariant, and the fold '
              'is precisely how we keep it without losing the writing');
      expect(await cachedReflections(), hasLength(1));
    });

    test('the state the completion screen reads carries the appended thread',
        () async {
      await firstRun();
      final second = secondRun();
      await second.completeDeeper();

      expect(second.state.tonightEntry, isNotNull);
      expect(second.state.tonightEntry!.thread, hasLength(1),
          reason: 'the screen renders the thread — if state is stale the user '
              'still sees their words vanish');
      expect(second.state.tonightEntry!.thread.single.text, secondWords);
    });

    test('the fold is flagged, so the screen can say where the words went',
        () async {
      await firstRun();
      final second = secondRun();
      await second.completeDeeper();

      expect(second.state.tonightAnswerFolded, isTrue);
      expect(second.state.tonightEntryIsReplay, isTrue,
          reason: 'the row on screen is still one this run did not write, so '
              'the Name label must stay honest');
    });

    test('an ordinary first night folds nothing and is untouched', () async {
      final first = notifierWith(answeredNight);
      await first.completeDeeper();

      expect(first.state.tonightAnswerFolded, isFalse);
      expect(first.state.tonightEntryIsReplay, isFalse);
      expect(first.state.tonightEntry!.thread, isEmpty);
    });

    test('a third run folds too — the day accumulates', () async {
      await firstRun();
      await secondRun().completeDeeper();
      await secondRun(answers: const ['and now I cannot sleep']).completeDeeper();

      final entry = (await cachedReflections()).single;
      expect(entry.thread.map((t) => t.text).toList(),
          [secondWords, 'and now I cannot sleep']);
    });
  });

  // ── Never duplicate the user's own words ──────────────────────────────────

  group('the fold does not duplicate', () {
    test('identical words are not appended a second time', () async {
      await firstRun();
      // The same answer typed again — a cold-restart replay, or a reader who
      // wrote the same sentence twice. Echoing it back under "Added today"
      // would read as the app duplicating their entry.
      final second = secondRun(answers: const [firstWords]);
      await second.completeDeeper();

      expect((await cachedReflections()).single.thread, isEmpty);
      expect(second.state.tonightAnswerFolded, isFalse,
          reason: 'nothing was folded, so the screen must not claim it was');
    });

    test('whitespace-only differences still count as the same words', () async {
      await firstRun();
      await secondRun(answers: const ['  $firstWords  ']).completeDeeper();

      expect((await cachedReflections()).single.thread, isEmpty);
    });

    test('words already in the thread are not appended again', () async {
      await seedDayEntry(
        thread: const [ReflectionThreadEntry(at: '', text: secondWords)],
      );

      final second = secondRun();
      await second.completeDeeper();

      expect((await cachedReflections()).single.thread, hasLength(1),
          reason: 'the reader already added this line by hand from "Something '
              'else for today"');
      expect(second.state.tonightAnswerFolded, isFalse);
    });
  });

  // ── The fold can never cost the night ─────────────────────────────────────

  group('the fold is best-effort, exactly like the write it follows', () {
    test('a second run with no words appends nothing', () async {
      await firstRun();
      final second = secondRun(answers: const []);
      await second.completeDeeper();

      expect((await cachedReflections()).single.thread, isEmpty);
      expect(second.state.tonightAnswerFolded, isFalse);
      expect(second.state.tonightEntryIsReplay, isTrue,
          reason: 'there is still an entry on screen this run did not write');
    });

    test('a full thread refuses the fold without breaking the completion',
        () async {
      await seedDayEntry(
        thread: [
          for (var i = 0; i < 20; i++)
            ReflectionThreadEntry(at: '', text: 'append $i'),
        ],
      );

      final second = secondRun();
      await second.completeDeeper();

      expect(second.state.currentStep, DailyLoopStep.completed,
          reason: 'completion is the user-visible contract and outranks every '
              'piece of bookkeeping below it');
      expect(second.state.tonightEntry, isNotNull,
          reason: 'the day\'s entry is still shown');
      expect(second.state.tonightAnswerFolded, isFalse);
      expect((await cachedReflections()).single.thread, hasLength(20),
          reason: 'the twenty-append cap is the server\'s and is not widened '
              'by this path');
    });

    test('a server refusal on the append leaves the entry exactly as it was',
        () async {
      await firstRun();
      fakeSync.nextUpsertShouldFail = true;

      final second = secondRun();
      await second.completeDeeper();

      expect(second.state.currentStep, DailyLoopStep.completed);
      expect(second.state.tonightEntry, isNotNull,
          reason: 'the fold failing must not also take away the row the screen '
              'was already falling back to');
      expect(second.state.tonightAnswerFolded, isFalse);
      expect((await cachedReflections()).single.thread, isEmpty,
          reason: 'nothing is cached that the server does not have');
    });

    test('a THROWING fold still leaves the day\'s entry on the screen',
        () async {
      // The fold runs BEFORE the state write and inside the same catch, so an
      // exception from it (a prefs store that is full, a client that throws
      // instead of returning false) would swallow the whole tail of the method:
      // no `tonightEntry`, no replay flag, no time-machine anchor. The reader
      // would then see the completion screen with NOTHING on it — strictly
      // worse than the "Today already had an entry" they get today, and caused
      // by the code that exists to stop losing things.
      await firstRun();

      final throwing = _ThrowingUpdateSync(userId: 'user-A');
      SupabaseSyncService.debugSetInstance(throwing);

      final second = secondRun();
      await second.completeDeeper();

      expect(second.state.currentStep, DailyLoopStep.completed);
      expect(second.state.tonightEntry, isNotNull,
          reason: 'the fold is bookkeeping; the artifact outranks it');
      expect(second.state.tonightEntry!.userText, firstWords);
      expect(second.state.tonightEntryIsReplay, isTrue,
          reason: 'and the Name label must still be told it is a replay');
      expect(second.state.tonightAnswerFolded, isFalse);
    });

    test('no row on the day at all is still the plain "nothing was saved" case',
        () async {
      // Nothing revealed and nothing written: `_persistMuhasabahEntry` returns
      // before the write, so there is neither a row nor anything to fold.
      final notifier = notifierWith(answeredNight.copyWith(
        checkinName: '',
        checkinNameArabic: '',
        checkinAnswers: const [],
      ));
      await notifier.completeDeeper();

      expect(notifier.state.tonightEntry, isNull);
      expect(notifier.state.tonightEntryIsReplay, isFalse);
      expect(notifier.state.tonightAnswerFolded, isFalse);
    });
  });

  // ── What it tells Mixpanel ────────────────────────────────────────────────

  group('the fold is counted as an append, never as a second entry', () {
    test('it emits muhasabah_thread_appended from its own surface', () async {
      await firstRun();

      final events = <(String, Map<String, dynamic>)>[];
      DailyLoopNotifier.onAnalyticsEvent = (e, p) => events.add((e, p));

      await secondRun().completeDeeper();

      final appends = events
          .where((e) => e.$1 == AnalyticsEvents.muhasabahThreadAppended)
          .toList();
      expect(appends, hasLength(1));
      expect(appends.single.$2[AnalyticsEvents.propSurface],
          AnalyticsEvents.surfaceSecondMuhasabah,
          reason: 'a fold is not a reader tapping "Something else for today" — '
              'sharing the muhasabah surface would hide the whole behaviour');
      expect(appends.single.$2[AnalyticsEvents.propThreadLength], 1);
    });

    test('and never a second journal_entry_created', () async {
      await firstRun();

      final events = <String>[];
      ReflectNotifier.onAnalyticsEvent = (e, _) => events.add(e);

      await secondRun().completeDeeper();

      expect(events.where((e) => e == AnalyticsEvents.journalEntryCreated),
          isEmpty,
          reason: 'the row count is still one — counting the fold as an entry '
              'would inflate the journal\'s own denominator');
    });

    test('a fold that appends nothing emits nothing', () async {
      await firstRun();

      final events = <String>[];
      DailyLoopNotifier.onAnalyticsEvent = (e, _) => events.add(e);

      await secondRun(answers: const [firstWords]).completeDeeper();

      expect(events.where((e) => e == AnalyticsEvents.muhasabahThreadAppended),
          isEmpty);
    });

    test('the folded words never reach analytics', () async {
      await firstRun();

      final events = <(String, Map<String, dynamic>)>[];
      DailyLoopNotifier.onAnalyticsEvent = (e, p) => events.add((e, p));
      ReflectNotifier.onAnalyticsEvent = (e, p) => events.add((e, p));

      await secondRun().completeDeeper();

      expect((await cachedReflections()).single.thread.single.text, secondWords,
          reason: 'the user\'s own RLS row is where the words are allowed to be');
      for (final event in events) {
        expect(jsonEncode(event.$2), isNot(contains('barely looked up')),
            reason: '${event.$1} carries the user\'s own words');
      }
    });
  });
}

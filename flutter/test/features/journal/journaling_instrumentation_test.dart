// Wave H — the journaling instrumentation, on the provider side.
//
// Waves B–E shipped an entire feature that emitted nothing: the nightly
// muḥāsabah wrote a durable journal row and fired no `journal_entry_created`,
// the append and the ʿazm were invisible, and a completed night left no trace
// that could be counted. Every event below exists to answer one question the
// plan asks and the code could not.
//
// Two rules are load-bearing across the whole file and each has its own group:
//
//   1. **An event counts what was KEPT.** A deduped replay, a refused server
//      write, a blank append and an ʿazm re-saved unchanged are all silent. An
//      emit at the call site rather than at the write would have counted every
//      one of them as a journal entry that does not exist.
//   2. **No user text, ever.** The last group asserts it over every payload the
//      whole wave can produce, not per call site — the rule is about the class.
//
// MUTATION: move the `journal_entry_created` emit out of
// `saveMuhasabahReflection` and into `completeDeeper` → the dedupe and
// server-refusal tests fail with a phantom second entry.

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

typedef _Event = (String name, Map<String, dynamic> props);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  late FakeSupabaseSyncService fakeSync;
  late List<_Event> loopEvents;
  late List<_Event> reflectEvents;

  /// 2026-08-03 01:27 UTC = 6:27pm on Aug 2 in Los Angeles — the same instant
  /// the Wave B and C suites use, so all three agree which night this is.
  final tonight = DateTime.utc(2026, 8, 3, 1, 27);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'America/Los_Angeles';
    debugDailyLoopClock = () => tonight;

    loopEvents = [];
    reflectEvents = [];
    DailyLoopNotifier.onAnalyticsEvent = (e, p) => loopEvents.add((e, p));
    ReflectNotifier.onAnalyticsEvent = (e, p) => reflectEvents.add((e, p));
  });

  tearDown(() {
    DailyLoopNotifier.onAnalyticsEvent = null;
    ReflectNotifier.onAnalyticsEvent = null;
    debugDailyLoopClock = () => DateTime.now().toUtc();
    debugResetUserLocalDay();
    SupabaseSyncService.debugReset();
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

  /// The one string every privacy assertion in this file hunts for.
  const answer = 'I snapped at my brother and I have been sitting with it.';

  const answeredNight = DailyLoopState(
    loaded: true,
    checkinDone: true,
    checkinAnswers: [answer],
    checkinName: 'Al-Halim',
    checkinNameArabic: 'الحليم',
    reflectResult: response,
    streakCount: 4,
  );

  DailyLoopNotifier notifierWith(DailyLoopState state) {
    final notifier = DailyLoopNotifier(skipInitForTests: true);
    addTearDown(notifier.dispose);
    notifier.debugSetState(state);
    return notifier;
  }

  Future<DailyLoopNotifier> completedNight([DailyLoopState? from]) async {
    final notifier = notifierWith(from ?? answeredNight);
    await notifier.completeDeeper();
    return notifier;
  }

  List<_Event> named(List<_Event> from, String name) =>
      from.where((e) => e.$1 == name).toList();

  group('journal_entry_created gained a `source` — it was not forked', () {
    test('the nightly muhasabah emits the JOURNAL event, not a sibling',
        () async {
      await completedNight();

      final created =
          named(reflectEvents, AnalyticsEvents.journalEntryCreated);
      expect(created, hasLength(1));
      expect(created.single.$2, {
        AnalyticsEvents.propEntryType: AnalyticsEvents.entryTypeReflection,
        // Nothing asked the user to save; the night saved itself. Same
        // semantics as the auto-saved built duʿā.
        AnalyticsEvents.propAuto: true,
        AnalyticsEvents.propSource: AnalyticsEvents.journalSourceMuhasabah,
      });

      // And no `muhasabah_entry_created`-shaped sibling snuck in alongside it:
      // the whole point of the property is that one event name still covers
      // every journal write, so historical charts survive T0.
      expect(
        reflectEvents.map((e) => e.$1).where((n) => n.contains('journal')),
        [AnalyticsEvents.journalEntryCreated],
      );
    });

    test('the wire values ARE the column values', () {
      // The other half of the property — a Reflect save emitting
      // `source: reflect` — is asserted where that writer already has a suite
      // (`reflect_provider_save_test.dart`). What belongs here is the
      // invariant that ties the two: the event's value space is the
      // `user_reflections.source` CHECK constraint, so a row and its event can
      // never disagree, and a rename on either side fails in one place rather
      // than producing a silent third value in Mixpanel.
      expect(reflectionSourceReflect, AnalyticsEvents.journalSourceReflect);
      expect(reflectionSourceMuhasabah, AnalyticsEvents.journalSourceMuhasabah);
      expect(AnalyticsEvents.journalSourceReflect, 'reflect');
      expect(AnalyticsEvents.journalSourceMuhasabah, 'muhasabah');
    });

    test('a same-day replay emits NOTHING — the row already existed', () async {
      final notifier = await completedNight();
      reflectEvents.clear();

      // A second completion on the same day. `saveMuhasabahReflection` returns
      // false without writing (the local check + the unique index), so there is
      // no second entry and there must be no second event.
      notifier.debugSetState(answeredNight);
      await notifier.completeDeeper();

      expect(named(reflectEvents, AnalyticsEvents.journalEntryCreated), isEmpty,
          reason: 'the day already had its entry — counting the replay would '
              'inflate journal writes by every re-completion');
    });

    test('a server-refused write emits NOTHING', () async {
      fakeSync.nextInsertShouldFail = true;
      await completedNight();

      expect(named(reflectEvents, AnalyticsEvents.journalEntryCreated), isEmpty,
          reason: 'the row is not cached and does not exist server-side — an '
              'event here would count a journal entry nobody has');
    });
  });

  group('muhasabah_completion_shown — the denominator for the whole wave', () {
    test('a night with an entry and no anchor', () async {
      await completedNight();

      final shown =
          named(loopEvents, AnalyticsEvents.muhasabahCompletionShown);
      expect(shown, hasLength(1));
      expect(shown.single.$2[AnalyticsEvents.propHasEntry], isTrue);
      expect(shown.single.$2[AnalyticsEvents.propHasTimeMachine], isFalse);
      expect(shown.single.$2[AnalyticsEvents.propThreadLength], 0);
      expect(shown.single.$2[AnalyticsEvents.propHasAzm], isFalse);
      expect(shown.single.$2.containsKey(AnalyticsEvents.propOffsetDays),
          isFalse,
          reason: 'an absent property and a null one break down differently — '
              'omit it rather than send a null that reads as a real value');
    });

    test('a night whose write was refused still reports, with has_entry false',
        () async {
      // The case the event exists for. A completion that left no artifact is
      // invisible from the row side by definition; this is the only signal
      // that it happened at all.
      fakeSync.nextInsertShouldFail = true;
      await completedNight();

      final shown =
          named(loopEvents, AnalyticsEvents.muhasabahCompletionShown);
      expect(shown, hasLength(1));
      expect(shown.single.$2[AnalyticsEvents.propHasEntry], isFalse);
    });

    test('the time machine anchor is reported with its exact offset', () async {
      // A muḥāsabah exactly 30 nights before tonight — the nearest anchor.
      await saveMuhasabahReflection(
        buildSavedReflection(
          userText: 'A month ago I could not sleep either.',
          response: response,
          source: reflectionSourceMuhasabah,
          entryLocalDay: '2026-07-03',
          date: '2026-07-03T21:00:00.000Z',
        ),
      );
      loopEvents.clear();
      reflectEvents.clear();

      await completedNight();

      final shown =
          named(loopEvents, AnalyticsEvents.muhasabahCompletionShown).single;
      expect(shown.$2[AnalyticsEvents.propHasTimeMachine], isTrue);
      expect(shown.$2[AnalyticsEvents.propOffsetDays], 30,
          reason: '30 / 90 / 365 are exact anchors, never a window — the '
              'offset is the only thing that says which one landed');
    });

    test('exactly one per completed night, and idempotent re-entry is silent',
        () async {
      final notifier = await completedNight();
      loopEvents.clear();

      // `completeDeeper` short-circuits when the step is already `completed`.
      await notifier.completeDeeper();
      expect(named(loopEvents, AnalyticsEvents.muhasabahCompletionShown),
          isEmpty);
    });
  });

  group('muhasabah_thread_appended — only committed appends', () {
    test('a committed append reports its surface and the new thread length',
        () async {
      final notifier = await completedNight();
      loopEvents.clear();

      expect(await notifier.appendToTonight('One more thing, before I sleep.'),
          isTrue);

      final appended =
          named(loopEvents, AnalyticsEvents.muhasabahThreadAppended);
      expect(appended, hasLength(1));
      expect(appended.single.$2, {
        // The default. The completion screen is the surface that existed first.
        AnalyticsEvents.propSurface: AnalyticsEvents.surfaceMuhasabah,
        AnalyticsEvents.propThreadLength: 1,
      });

      await notifier.appendToTonight('And one more.',
          surface: AnalyticsEvents.surfaceJournal);
      final second =
          named(loopEvents, AnalyticsEvents.muhasabahThreadAppended)[1];
      expect(second.$2[AnalyticsEvents.propSurface],
          AnalyticsEvents.surfaceJournal,
          reason: "D3's compose sheet is the ONLY thing this property "
              'distinguishes — without it the Journal control cannot be shown '
              'to earn its place');
      expect(second.$2[AnalyticsEvents.propThreadLength], 2,
          reason: 'the count AFTER the append, so "appended once" is separable '
              'from "kept going" without a session aggregate');
    });

    test('a blank append is silent', () async {
      final notifier = await completedNight();
      loopEvents.clear();

      expect(await notifier.appendToTonight('   '), isFalse);
      expect(named(loopEvents, AnalyticsEvents.muhasabahThreadAppended),
          isEmpty);
    });

    test('an append with no row to append to is silent', () async {
      // A day that never completed: `appendToMuhasabahThread` returns null and
      // the append is refused rather than filed against yesterday.
      final notifier = notifierWith(const DailyLoopState(loaded: true));
      expect(await notifier.appendToTonight('Nowhere to put this.'), isFalse);
      expect(named(loopEvents, AnalyticsEvents.muhasabahThreadAppended),
          isEmpty);
    });

    test('a server-refused append is silent', () async {
      final notifier = await completedNight();
      loopEvents.clear();
      fakeSync.nextUpsertShouldFail = true;

      expect(await notifier.appendToTonight('This one will not land.'), isFalse);
      expect(named(loopEvents, AnalyticsEvents.muhasabahThreadAppended),
          isEmpty,
          reason: 'the entry stands as it was — nothing was appended');
    });
  });

  group('muhasabah_azm_set — an edit, not a keystroke', () {
    test('the first resolve of the night', () async {
      final notifier = await completedNight();
      loopEvents.clear();

      expect(await notifier.setTonightAzm('Call him in the morning.'), isTrue);

      final set = named(loopEvents, AnalyticsEvents.muhasabahAzmSet);
      expect(set, hasLength(1));
      expect(set.single.$2[AnalyticsEvents.propFirstTime], isTrue);
      expect(set.single.$2[AnalyticsEvents.propCleared], isFalse);
      expect(set.single.$2[AnalyticsEvents.propCharCountBucket], '21_60');
    });

    test('re-saving the SAME line is not an edit', () async {
      final notifier = await completedNight();
      await notifier.setTonightAzm('Call him in the morning.');
      loopEvents.clear();

      expect(await notifier.setTonightAzm('Call him in the morning.'), isTrue);
      expect(named(loopEvents, AnalyticsEvents.muhasabahAzmSet), isEmpty,
          reason: 'the ʿazm is editable until rollover, so a save that changes '
              'nothing must not make the resolve look re-worked');
    });

    test('a later edit is not first_time, and emptying it reports cleared',
        () async {
      final notifier = await completedNight();
      await notifier.setTonightAzm('Call him in the morning.');
      loopEvents.clear();

      await notifier.setTonightAzm('Call him tonight.');
      expect(
        named(loopEvents, AnalyticsEvents.muhasabahAzmSet)
            .single
            .$2[AnalyticsEvents.propFirstTime],
        isFalse,
      );

      loopEvents.clear();
      await notifier.setTonightAzm('');
      final cleared = named(loopEvents, AnalyticsEvents.muhasabahAzmSet).single;
      expect(cleared.$2[AnalyticsEvents.propCleared], isTrue);
      expect(cleared.$2[AnalyticsEvents.propFirstTime], isFalse);
    });
  });

  group('the rule that outranks every metric here', () {
    test('nothing the user wrote appears in ANY payload this wave emits',
        () async {
      // Every emitting path in Waves B–E, driven once, then swept together.
      // Per-payload assertions would have to be remembered for each new event;
      // this one is about the class and inherits every event added later.
      final notifier = await completedNight();
      await notifier.appendToTonight('One more thing, before I sleep.');
      await notifier.setTonightAzm('Call him in the morning.');

      final haystack = [...loopEvents, ...reflectEvents]
          .map((e) => '${e.$1} ${e.$2}')
          .join('\n');

      for (final secret in const [
        answer,
        'snapped',
        'brother',
        'One more thing, before I sleep.',
        'sleep',
        'Call him in the morning.',
        'morning',
      ]) {
        expect(haystack.contains(secret), isFalse,
            reason: 'the user\'s own words reached telemetry: "$secret"\n'
                '$haystack');
      }

      // And the sweep is not vacuous — those paths really did emit.
      expect(loopEvents, isNotEmpty);
      expect(reflectEvents, isNotEmpty);
    });

    test('the ʿazm sends a BUCKET, and the bucket cannot be the line', () async {
      final notifier = await completedNight();
      loopEvents.clear();
      await notifier.setTonightAzm('Fast Monday.');

      final props =
          named(loopEvents, AnalyticsEvents.muhasabahAzmSet).single.$2;
      // Structurally impossible to leak: `charCountBucket` takes an int, so no
      // refactor can hand it the String. This asserts the value space.
      expect(props[AnalyticsEvents.propCharCountBucket], '1_20');
      expect(props.values.whereType<String>(), ['1_20']);
    });
  });
}

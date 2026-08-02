// "Add to tonight" — the night stays open, and NOTHING ELSE happens (Wave C1).
//
// This file exists for one finding, restated in the plan as *"the single most
// likely serious bug in this wave"*: an append must not re-enter the economy.
// The reveal, the streak mark, the reward-ladder claim, the queue unseal, the
// card engage and the allowance consumption all fire exactly ONCE per night, at
// first submit. The `!state.checkinDone` gate in `_showsQuestion`
// (`muhasabah_screen.dart`) is what holds that line — it is the defence against
// the "phantom second gacha" bug class documented at the top of
// `daily_loop_provider.dart`. Wave C deliberately does NOT widen it; it adds a
// separate path that bypasses it, and the first group below is what proves that
// path is inert.
//
// The second and third groups pin the two things that make the write survivable:
// the day the append belongs to (resolved fresh, so a post-midnight append is
// tomorrow's), and the clamps (element, char AND byte — the byte one is the gap
// the Wave B review flagged and this wave had to close).
//
// MUTATION: make `appendToTonight` call `discoverName()` → group 1 fails and
// names the write it made.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Counts calls to the one method an append must never reach. Overriding it is
/// the literal form of the assertion — a spy on the real name, so a future
/// refactor that routes the append through `discoverName` under another alias
/// still trips the RPC/insert assertions below even if this one goes quiet.
class _DiscoverSpy extends DailyLoopNotifier {
  _DiscoverSpy() : super(skipInitForTests: true);

  int discoverCalls = 0;

  @override
  Future<void> discoverName({
    bool consumeFreeUsage = true,
    bool? isPremiumHint,
  }) async {
    discoverCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  late FakeSupabaseSyncService fakeSync;

  /// 2026-08-03 01:27 UTC — 6:27pm on Aug 2 in Los Angeles. The same instant the
  /// Wave B suite uses, so the two agree about which night this is.
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
    debugResetUserLocalDay();
    SupabaseSyncService.debugReset();
  });

  void useZone(String zone) {
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = zone;
  }

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

  const answeredNight = DailyLoopState(
    loaded: true,
    checkinDone: true,
    checkinAnswers: ['I snapped at my brother and I have been sitting with it.'],
    checkinName: 'Al-Halim',
    checkinNameArabic: 'الحليم',
    reflectResult: response,
    streakCount: 4,
  );

  Future<List<SavedReflection>> cached() async {
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

  /// A completed night with a row on disk, ready to be appended to.
  Future<DailyLoopNotifier> completedNight([DailyLoopState? from]) async {
    final notifier = notifierWith(from ?? answeredNight);
    await notifier.completeDeeper();
    return notifier;
  }

  group('an append writes NO economy event', () {
    test('discoverName is never called, and no economy write is issued',
        () async {
      final notifier = await completedNight();

      // Everything the first submit did, snapshotted at the moment the night
      // finished. An append must move none of it.
      final rpcsBefore = fakeSync.rpcCalls.map((c) => c['fn']).toList();
      final insertTablesBefore =
          fakeSync.insertCalls.map((c) => c['table']).toList();
      final upsertTablesBefore =
          fakeSync.upsertCalls.map((c) => c['table']).toList();
      final streakBefore = notifier.state.streakCount;
      final streakOnDisk = (await getStreak()).currentStreak;
      final stepBefore = notifier.state.currentStep;
      final checkinDoneBefore = notifier.state.checkinDone;
      final engagedBefore = notifier.state.engagedCard;
      final revealBefore = notifier.state.revealQueuePosition;

      expect(await notifier.appendToTonight('One more thing, before I sleep.'),
          isTrue);

      // 1. No RPC at all — that covers `unseal_next_name`, `award_daily_noor`,
      //    `claim_daily_reward`, `consume_warmup_allowance`, the streak
      //    milestone claim and every other economy call in one assertion,
      //    including any added later.
      expect(fakeSync.rpcCalls.map((c) => c['fn']).toList(), rpcsBefore,
          reason: 'an append is a pure text write — no RPC may fire');

      // 2. No INSERT anywhere. In particular nothing into `user_reflections`:
      //    an append EDITS the night's row, it never creates a second one.
      expect(fakeSync.insertCalls.map((c) => c['table']).toList(),
          insertTablesBefore,
          reason: 'an append must not create a row — not a second reflection, '
              'and not a card, a check-in or a usage row');
      expect(fakeSync.batchInsertCalls, isEmpty);

      // 3. No card engaged, no queue position spent, no streak moved, and the
      //    lifecycle untouched.
      expect(fakeSync.upsertCalls.map((c) => c['table']).toList(),
          upsertTablesBefore);
      expect(notifier.state.streakCount, streakBefore);
      expect(notifier.state.currentStep, stepBefore);
      expect(notifier.state.checkinDone, checkinDoneBefore);
      expect(identical(notifier.state.engagedCard, engagedBefore), isTrue);
      expect(notifier.state.revealQueuePosition, revealBefore);

      // 4. And the persisted streak is exactly where the night left it.
      expect((await getStreak()).currentStreak, streakOnDisk,
          reason: 'an append must not mark the day active a second time');
    });

    test('the ONLY write an append makes is an upsert of the night\'s own row',
        () async {
      final notifier = await completedNight();
      final rawUpsertsBefore = fakeSync.rawUpsertCalls.length;

      await notifier.appendToTonight('One more thing.');

      final writes = fakeSync.rawUpsertCalls.skip(rawUpsertsBefore).toList();
      expect(writes, hasLength(1));
      expect(writes.single['table'], 'user_reflections');
      expect(writes.single['onConflict'], 'id',
          reason: 'an append edits the row it owns — an insert would collide '
              'with uniq_muhasabah_per_local_day and be refused');
      final data = writes.single['data'] as Map<String, dynamic>;
      expect(data['id'], notifier.state.tonightEntry!.id);
      expect((data['thread'] as List).single['text'], 'One more thing.');
    });

    test('discoverName is not called — the literal assertion', () async {
      final spy = _DiscoverSpy();
      addTearDown(spy.dispose);
      spy.debugSetState(answeredNight);
      await spy.completeDeeper();
      expect(spy.discoverCalls, 0);

      expect(await spy.appendToTonight('and one more thing'), isTrue);
      expect(await spy.appendToTonight('and another'), isTrue);
      expect(await spy.setTonightAzm('Tomorrow I will hold my tongue.'), isTrue);

      expect(spy.discoverCalls, 0,
          reason: 'appending, and resolving, must never reveal a Name. '
              'Widening the `!checkinDone` gate instead of adding this separate '
              'path is exactly how that would happen.');
    });

    test('the appended text never becomes an analytics property', () async {
      final notifier = await completedNight();

      final events = <(String, Map<String, dynamic>)>[];
      DailyLoopNotifier.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => DailyLoopNotifier.onAnalyticsEvent = null);

      await notifier.appendToTonight('The thing I could not say out loud.');

      // Wave H owns the analytics for this wave; today an append emits nothing
      // at all. Whatever it grows must never carry the words themselves.
      for (final event in events) {
        expect(jsonEncode(event.$2), isNot(contains('out loud')),
            reason: '${event.$1} carries the user\'s own words');
      }
    });
  });

  group('the day an append belongs to', () {
    test('an append lands on tonight\'s row and is readable back', () async {
      final notifier = await completedNight();

      expect(await notifier.appendToTonight('  Still turning it over.  '),
          isTrue);

      final entry = (await cached()).single;
      expect(entry.entryLocalDay, '2026-08-02');
      expect(entry.thread, hasLength(1));
      expect(entry.thread.single.text, 'Still turning it over.',
          reason: 'trimmed, and stored verbatim otherwise');
      expect(entry.thread.single.at, startsWith('2026-08-03'),
          reason: 'the instant is UTC; the DAY the entry belongs to is not');
      expect(notifier.state.tonightEntry!.thread.single.text,
          'Still turning it over.');
    });

    test('appends accumulate in order', () async {
      final notifier = await completedNight();
      await notifier.appendToTonight('first');
      await notifier.appendToTonight('second');
      await notifier.appendToTonight('third');

      expect((await cached()).single.thread.map((e) => e.text).toList(),
          ['first', 'second', 'third']);
    });

    test('a blank append writes nothing', () async {
      final notifier = await completedNight();
      final before = fakeSync.rawUpsertCalls.length;

      expect(await notifier.appendToTonight('   '), isFalse);
      expect(fakeSync.rawUpsertCalls, hasLength(before));
    });

    test('after the local day rolls over, the append goes to the NEW day\'s '
        'row — never back onto yesterday', () async {
      final notifier = await completedNight();
      await notifier.appendToTonight('written on the 2nd');

      // Midnight passes in Los Angeles.
      debugDailyLoopClock = () => tonight.add(const Duration(days: 1));
      useZone('America/Los_Angeles');

      // Tonight's night is completed too, so the new day has a row.
      final tomorrow = await completedNight(answeredNight.copyWith(
        checkinAnswers: const ['a different weight tonight'],
      ));
      expect(await tomorrow.appendToTonight('written on the 3rd'), isTrue);

      final rows = await cached();
      final byDay = {for (final r in rows) r.entryLocalDay: r};
      expect(byDay.keys, containsAll(['2026-08-02', '2026-08-03']));
      expect(byDay['2026-08-02']!.thread.map((e) => e.text).toList(),
          ['written on the 2nd'],
          reason: 'yesterday is closed — the rollover is what closes it');
      expect(byDay['2026-08-03']!.thread.map((e) => e.text).toList(),
          ['written on the 3rd']);
    });

    test('after rollover with no entry yet, the append is refused rather than '
        'filed against yesterday', () async {
      final notifier = await completedNight();

      debugDailyLoopClock = () => tonight.add(const Duration(days: 1));
      useZone('America/Los_Angeles');

      expect(await notifier.appendToTonight('a thought at 00:05'), isFalse,
          reason: 'the new day has no row yet; there is nothing to append to');
      expect((await cached()).single.thread, isEmpty,
          reason: "and yesterday's entry must not absorb it");
    });

    test('a night with no entry at all cannot be appended to', () async {
      // Nothing completed — an offline night, or a refused write.
      final notifier = notifierWith(answeredNight);
      expect(await notifier.appendToTonight('anything'), isFalse);
      expect(fakeSync.rawUpsertCalls, isEmpty);
    });

    test('a refused server write caches nothing and reports false', () async {
      final notifier = await completedNight();
      fakeSync.nextUpsertShouldFail = true;

      expect(await notifier.appendToTonight('this one does not land'), isFalse);
      expect((await cached()).single.thread, isEmpty,
          reason: 'a locally-cached append the server refused would vanish on '
              'the next sync — worse than never having appeared');
      expect(notifier.state.tonightEntry!.thread, isEmpty);
    });
  });

  group('the clamps agree with the server', () {
    // The server's `user_reflections_thread_shape` trigger + array CHECK, in
    // `20260802030000_user_reflections_journal_entries.sql`:
    //   • jsonb_array_length(thread) <= 20
    //   • length(element->>'text') <= 2048        (CODEPOINTS)
    //   • length(element->>'at')   <= 64          (CODEPOINTS)
    //   • keys ⊆ {at, text}
    //   • pg_column_size(thread) <= 49152         (BYTES)
    // The last one is the one that had no client-side mirror before Wave C.

    test('the element count stops at 20, and says so rather than silently '
        'dropping', () async {
      final notifier = await completedNight();
      for (var i = 0; i < 20; i++) {
        expect(await notifier.appendToTonight('append $i'), isTrue);
      }
      expect(await notifier.appendToTonight('the twenty-first'), isFalse);

      final entry = (await cached()).single;
      expect(entry.thread, hasLength(20));
      expect(entry.thread.last.text, 'append 19',
          reason: 'the refused append must not evict an accepted one');
    });

    test('a single append is char-clamped to 2048, matching the text CHECK',
        () async {
      final notifier = await completedNight();
      await notifier.appendToTonight('x' * 5000);

      final text = (await cached()).single.thread.single.text;
      expect(text.length, 2048);
    });

    test('only {at, text} ever reach the wire', () async {
      final notifier = await completedNight();
      await notifier.appendToTonight('one line');

      final data = fakeSync.rawUpsertCalls.last['data'] as Map<String, dynamic>;
      final element = (data['thread'] as List).single as Map;
      expect(element.keys.toSet(), {'at', 'text'},
          reason: 'the server rejects any other key outright');
      expect((element['at'] as String).length, lessThanOrEqualTo(64));
    });

    test('ARABIC: the whole thread is byte-clamped, which the per-element char '
        'caps do not do', () async {
      // The Wave B review's finding 7, made concrete. Arabic is two UTF-8 bytes
      // per codepoint, so twenty appends of 2048 Arabic characters each — every
      // one of them legal under the per-element CHECK — is ~80 KB and the
      // server's `pg_column_size(thread) > 49152` backstop rejects the ROW.
      // Before the byte clamp, the client had no way to know.
      final notifier = await completedNight();

      const arabicChar = 'ب'; // 2 bytes in UTF-8
      for (var i = 0; i < 20; i++) {
        await notifier.appendToTonight(arabicChar * 2048);
      }

      final data = fakeSync.rawUpsertCalls.last['data'] as Map<String, dynamic>;
      final bytes = utf8.encode(jsonEncode(data['thread'])).length;
      expect(bytes, lessThanOrEqualTo(49152),
          reason: 'the row the client composed must be one the server accepts');
      // And the margin the client actually holds itself to.
      expect(bytes, lessThanOrEqualTo(40960));
    });

    test('the byte clamp truncates the newest append rather than dropping it',
        () async {
      final notifier = await completedNight();
      const arabicChar = 'ب';

      // Fill most of the budget, then push one more in.
      for (var i = 0; i < 9; i++) {
        await notifier.appendToTonight(arabicChar * 2048);
      }
      expect(await notifier.appendToTonight('${arabicChar * 2048}TAIL'), isTrue,
          reason: 'the append lands — truncated, not silently discarded');

      final thread = (await cached()).single.thread;
      expect(thread, hasLength(10));
      expect(thread.last.text, isNotEmpty);
      expect(threadJsonBytes(thread), lessThanOrEqualTo(40960));
    });

    test('truncating at the byte budget never severs a surrogate pair', () {
      // REGRESSION (Wave C review). `substring` counts UTF-16 code units, so a
      // cut landing between an emoji's two halves leaves a lone surrogate — and
      // `utf8.encode` does NOT throw on that, it silently emits U+FFFD. The user
      // would have their last character saved as a replacement glyph with no
      // error raised anywhere.
      //
      // Every character here is astral (4 UTF-8 bytes, 2 UTF-16 code units), so
      // the cut lands mid-pair unless the clamp corrects for it.
      // ⚠️ READ THIS BEFORE TRUSTING THIS TEST. It is an INVARIANT guard, not a
      // proven regression test — it passes with the surrogate correction in
      // `fitThreadAppend` deliberately removed.
      //
      // Mutation-tested twice. With the guard mutated out, this sweep (and a
      // direct instrumentation harness over the same inputs) still produced an
      // even cut and a lossless round trip every time: the loop subtracts a
      // BYTE overshoot from a CODE-UNIT length, which over-corrects downward,
      // and in every configuration reachable through the real caps it settles
      // on a pair boundary. So the corruption the guard prevents appears to be
      // unreachable today, and the guard is defensive rather than load-bearing.
      //
      // It is kept because it costs nothing and the truncation arithmetic is
      // exactly the kind that gets "simplified" later. What this test actually
      // pins is the invariant — the stored text must survive a UTF-8 round trip
      // — so it will catch a future change that does make the cut reachable.
      // The parity shim walks the overshoot through both parities so that such
      // a change is caught on the first odd case rather than by luck.
      const emoji = '🌙';
      final nearFull = [
        for (var i = 0; i < 9; i++)
          ReflectionThreadEntry(at: '', text: 'ب' * 2048),
      ];

      for (var shim = 0; shim < 8; shim++) {
        final existing = [
          ...nearFull,
          ReflectionThreadEntry(at: '', text: 'a' * shim),
        ];
        final fitted = fitThreadAppend(
          existing,
          ReflectionThreadEntry(at: '', text: emoji * 2048),
        );

        expect(fitted, isNotNull,
            reason: 'shim $shim: there is room for a truncated append');
        final text = fitted!.text;

        // A lone surrogate survives `utf8.encode` and comes back as U+FFFD, so
        // an exact round trip is what actually catches the corruption.
        expect(utf8.decode(utf8.encode(text)), text,
            reason: 'shim $shim: a severed surrogate round-trips as U+FFFD');
        expect(text.contains('�'), isFalse, reason: 'shim $shim');
        expect(text.length.isEven, isTrue,
            reason: 'shim $shim: an odd count means half an emoji survived');
        expect(threadJsonBytes([...existing, fitted]), lessThanOrEqualTo(40960),
            reason: 'shim $shim');
      }
    });

    test('fitThreadAppend refuses when there is no room left at all', () {
      final full = [
        for (var i = 0; i < 19; i++)
          ReflectionThreadEntry(at: '', text: 'ب' * 2048),
      ];
      // 19 x 2048 Arabic chars is already ~78 KB — over budget on its own, so
      // no truncation of a twentieth can bring the total back under.
      expect(
        fitThreadAppend(
            full, const ReflectionThreadEntry(at: '', text: 'one more')),
        isNull,
      );
    });
  });
}

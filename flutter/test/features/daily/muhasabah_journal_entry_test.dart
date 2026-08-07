// The nightly muḥāsabah leaves an artifact (Wave B).
//
// Before this, a completed muḥāsabah persisted NOTHING the user could re-read:
// `user_checkin_history` carries no answer text (the discover path writes
// q1='discover' with q2-q4 empty) and the AI reflection was never stored at
// all — the user's own words lived only in the device-local per-day blob, which
// is keyed by the day and never read again once the day rolls over.
//
// Four properties are pinned here, and each one is a bug that has a name:
//   1. ONE row per local day. A replay is a no-op — not a duplicate, and not an
//      overwrite of what the user already wrote tonight.
//   2. `entry_local_day` is the LOCAL day, never `saved_at`. Near midnight a
//      timestamp disagrees with the day boundary the loop, the launch gate and
//      the reward ladder all key on (launch_gate_state.dart:14-22).
//   3. A failed write does not fail the completion. By then the streak, the
//      quests and the Noor award are committed: a lost row is recoverable, a
//      lost streak is not.
//   4. It goes through the reflect provider's own persistence path, so one code
//      path owns `user_reflections` — its row shape, its clamps and its cache.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/models/name_story_deck.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  late FakeSupabaseSyncService fakeSync;

  /// 2026-08-03 01:27 UTC. In Los Angeles that is still **6:27pm on Aug 2** —
  /// the instant the local-day key bug was reported from a device, reused here
  /// because it is exactly where a `saved_at`-derived day goes wrong.
  final afterUtcMidnight = DateTime.utc(2026, 8, 3, 1, 27);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugResetUserLocalDay();
    debugDailyLoopClock = () => afterUtcMidnight;
  });

  tearDown(() {
    debugDailyLoopClock = () => DateTime.now().toUtc();
    debugUserTimeZoneOverride = null;
    debugResetUserLocalDay();
    SupabaseSyncService.debugReset();
  });

  /// Reset clears the override, so the order matters — setting the zone first
  /// and resetting after silently puts you back on UTC, which is the value the
  /// bug produces and would make every assertion pass for the wrong reason.
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

  test('completing the night writes exactly one muhasabah row', () async {
    useZone('America/Los_Angeles');

    final notifier = notifierWith(answeredNight);
    await notifier.completeDeeper();

    final rows = reflectionInserts();
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row['source'], reflectionSourceMuhasabah);
    expect(row['user_id'], 'user-A');
    expect(row['user_text'],
        'I snapped at my brother and I have been sitting with it.');
    expect(row['name'], 'Al-Halim');
    expect(row['name_arabic'], 'الحليم');
    // The prefetched deeper response — the beats, the duʿā and the verses the
    // user was just shown — is what makes the entry re-readable as a story.
    expect((row['beat_data'] as Map)['storyTitle'], 'The Bedouin in the Masjid');
    expect(row['dua_translation'], 'O Allah, make me forbearing.');
    expect(row['reframe'], contains('room to return'));
    // Wave C's two columns exist and start empty.
    expect(row['thread'], isEmpty);
    expect(row['azm'], isNull);
  });

  test('the entry lands in the local cache, so the journal can read it',
      () async {
    useZone('America/Los_Angeles');

    await notifierWith(answeredNight).completeDeeper();

    final cached = await cachedReflections();
    expect(cached, hasLength(1));
    expect(cached.single.isMuhasabah, isTrue);
    expect(cached.single.entryLocalDay, '2026-08-02');
    expect(cached.single.storyTitle, 'The Bedouin in the Masjid');
  });

  test('entry_local_day is the LOCAL day, not the UTC day behind saved_at',
      () async {
    // 6:27pm Aug 2 in Los Angeles; the UTC date has already rolled to Aug 3.
    useZone('America/Los_Angeles');

    await notifierWith(answeredNight).completeDeeper();

    final row = reflectionInserts().single;
    expect(row['entry_local_day'], '2026-08-02',
        reason: 'the user is living in Aug 2 — that is the night they did');
    expect(row['saved_at'].toString(), startsWith('2026-08-03'),
        reason: 'the timestamp legitimately disagrees; that is WHY the day is '
            'a separate column');

    // The one that matters: it agrees with the day boundary every other part
    // of the loop keys on.
    expect(row['entry_local_day'],
        await userLocalDayString(clock: debugDailyLoopClock));
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getKeys().any((k) => k.contains('daily_loop_2026-08-02')),
      isTrue,
      reason: "the day's own state blob is under the same local day",
    );
  });

  test('east of UTC the local day is tomorrow, and the entry follows', () async {
    // Tokyo at this instant is already 10:27am on Aug 3.
    useZone('Asia/Tokyo');

    await notifierWith(answeredNight).completeDeeper();

    expect(reflectionInserts().single['entry_local_day'], '2026-08-03');
  });

  test('a second completeDeeper in the same cycle writes nothing more',
      () async {
    useZone('America/Los_Angeles');

    final notifier = notifierWith(answeredNight);
    await notifier.completeDeeper();
    await notifier.completeDeeper();

    expect(reflectionInserts(), hasLength(1),
        reason: 'completeDeeper early-returns once the step is completed');
  });

  test('a second completion the same local day is a no-op, not a duplicate '
      'and not an overwrite', () async {
    useZone('America/Los_Angeles');

    // A fresh notifier — a cold restart, a second entry path — so the in-notifier
    // early return cannot be what saves us.
    final first = DailyLoopNotifier(skipInitForTests: true);
    first.debugSetState(answeredNight);
    await first.completeDeeper();
    first.dispose();

    final originalRow =
        Map<String, dynamic>.from(reflectionInserts().single);

    final second = notifierWith(answeredNight.copyWith(
      checkinAnswers: const ['a different thing entirely'],
    ));
    await second.completeDeeper();

    expect(reflectionInserts(), hasLength(1),
        reason: 'one muḥāsabah per local day — the local cache catches the '
            'replay, and uniq_muhasabah_per_local_day catches it server-side '
            'even when the cache is cold');
    expect(reflectionInserts().single['user_text'], originalRow['user_text'],
        reason: 'a replay must never overwrite what the user wrote tonight — '
            'this is an INSERT, deliberately, and never an upsert');
    expect(fakeSync.upsertCalls.where((c) => c['table'] == 'user_reflections'),
        isEmpty);
    expect(await cachedReflections(), hasLength(1));
  });

  // ── The replay flag (2026-08-06) ──────────────────────────────────────────
  //
  // `_persistMuhasabahEntry` deliberately shows back "the entry that IS on the
  // day" rather than the one it just built — right, because the journal's row
  // is the artifact. But it DISCARDED the boolean `saveMuhasabahReflection`
  // returns, so it could not tell a row it had just written from one the day
  // already had. The completion screen then rendered another night's Name under
  // the label "The Name you met", and a reader who had just been shown
  // Al-Majeed was told they met Al-Wadud. Observed on a QA device.
  //
  // MUTATION: hard-code `tonightEntryIsReplay: false` → the second test fails.
  test('a night that wrote its own row is NOT flagged as a replay', () async {
    useZone('America/Los_Angeles');
    final notifier = notifierWith(answeredNight);
    await notifier.completeDeeper();

    expect(notifier.state.tonightEntry, isNotNull);
    expect(notifier.state.tonightEntryIsReplay, isFalse,
        reason: 'the ordinary night must be untouched by this');
  });

  test('a refused write flags the row it fell back to, so the screen stops '
      'calling another night\'s Name "the Name you met"', () async {
    useZone('America/Los_Angeles');

    final first = DailyLoopNotifier(skipInitForTests: true);
    first.debugSetState(answeredNight);
    await first.completeDeeper();
    first.dispose();

    // A second run of the same local day, revealing a DIFFERENT Name — exactly
    // the shape of the bug.
    final second = notifierWith(answeredNight.copyWith(
      checkinName: 'Al-Majeed',
      checkinNameArabic: 'الْمَجِيدُ',
      checkinAnswers: const ['something else entirely'],
    ));
    await second.completeDeeper();

    expect(second.state.tonightEntry, isNotNull,
        reason: 'the day\'s row is still shown — it is real, and it is the '
            'user\'s own words');
    expect(second.state.tonightEntry!.name, isNot('Al-Majeed'),
        reason: 'the fixture must reproduce the divergence, or this test is '
            'not about the reported bug');
    expect(second.state.tonightEntryIsReplay, isTrue);
  });

  test('a refused write with NO row to fall back on is not a replay — that is '
      'the ordinary "nothing was saved" case the screen already handles',
      () async {
    useZone('America/Los_Angeles');
    // Nothing revealed and nothing written: `_persistMuhasabahEntry` returns
    // before it ever reaches the write, so the flag must stay false rather than
    // make the screen apologise for an entry it is not showing.
    final notifier = notifierWith(answeredNight.copyWith(
      checkinName: '',
      checkinNameArabic: '',
      checkinAnswers: const [],
    ));
    await notifier.completeDeeper();

    expect(notifier.state.tonightEntry, isNull);
    expect(notifier.state.tonightEntryIsReplay, isFalse);
  });

  test('the next local day gets its own entry', () async {
    useZone('America/Los_Angeles');

    await notifierWith(answeredNight).completeDeeper();

    // 24 hours later, same local clock time.
    debugDailyLoopClock = () => afterUtcMidnight.add(const Duration(days: 1));
    useZone('America/Los_Angeles');

    await notifierWith(answeredNight).completeDeeper();

    final days = reflectionInserts()
        .map((r) => r['entry_local_day'])
        .toList();
    expect(days, ['2026-08-02', '2026-08-03']);
  });

  test('a refused write does not break the completion', () async {
    useZone('America/Los_Angeles');
    fakeSync.rpcHandlers['award_daily_noor'] = (_) async => 10;
    // The server says no — a CHECK, RLS, the unique index, a transient 5xx.
    fakeSync.nextInsertShouldFail = true;

    final notifier = notifierWith(answeredNight);
    await notifier.completeDeeper();

    expect(notifier.state.currentStep, DailyLoopStep.completed,
        reason: 'completion is the user-visible contract');
    expect(
      fakeSync.rpcCalls.where((c) => c['fn'] == 'award_daily_noor'),
      hasLength(1),
      reason: 'the Noor faucet is committed BEFORE the journal write, so a '
          'refused row cannot cost the user their reward',
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(fakeSync.scopedKey('sakina_launch_gate')), isNotNull,
        reason: 'the day-open markers are stamped too');

    expect(await cachedReflections(), isEmpty,
        reason: 'and nothing is cached locally that the server does not have — '
            'a phantom entry would vanish on the next sync');
  });

  test('an unresolvable timezone degrades to UTC and still completes',
      () async {
    // The write is best-effort end to end, not only at the insert: the local-day
    // resolution is a whole ladder of its own (cache → server → device → UTC).
    useZone('Not/AZone');
    fakeSync.rpcHandlers['award_daily_noor'] = (_) async => 10;

    final notifier = notifierWith(answeredNight);
    await notifier.completeDeeper();

    expect(notifier.state.currentStep, DailyLoopStep.completed);
    expect(reflectionInserts().single['entry_local_day'], '2026-08-03',
        reason: 'the ladder ends at UTC, which is also what the loop key does '
            '— they still agree');
  });

  test('the deck path still leaves an artifact', () async {
    // A pre-authored deck night has NO ReflectResponse at all — the beats are
    // the content. The user's words and the Name are still the point.
    useZone('America/Los_Angeles');

    await notifierWith(const DailyLoopState(
      loaded: true,
      checkinDone: true,
      checkinAnswers: ['I could not settle tonight.'],
      checkinName: 'As-Salam',
      checkinNameArabic: 'السلام',
    )).completeDeeper();

    final row = reflectionInserts().single;
    expect(row['user_text'], 'I could not settle tonight.');
    expect(row['name'], 'As-Salam');
    expect(row['source'], reflectionSourceMuhasabah);
    expect(row['beat_data'], isNull,
        reason: 'no AI beats on a deck night — the legacy fallback path');
  });

  test(
      'a deck night after an AI night does not inherit the previous '
      "night's reflection", () async {
    // REGRESSION (Wave B review, 2026-08-02). `reflectResult` survives a cycle
    // — only `resetToday()` and the off-topic re-ask null it — and the bypass
    // CTAs (`discoverNameWithBypass` / `discoverNameWithFirstBypass`) begin a
    // new cycle WITHOUT `resetToday()`. `dailyLoopProvider` is not autoDispose,
    // so one notifier survives backgrounding across midnight and a second cycle
    // is ordinary, not exotic.
    //
    // Before the fix, `startDeeper()`'s deck short-circuit left the stale
    // response on state and `completeDeeper()` persisted it: the PREVIOUS
    // night's reframe, story, beat_data and duʿa filed under tonight's Name,
    // tonight's words and tonight's date. Every field a reader would check for
    // plausibility is correct, which is exactly why it would never be reported.
    //
    // This drives the REAL path (`startDeeper`), not `debugSetState` — the
    // original deck test constructed a fresh state whose `reflectResult` was
    // already null, so it could not have caught this.
    useZone('America/Los_Angeles');

    final notifier = notifierWith(answeredNight.copyWith(
      checkinAnswers: ['Tonight is a different weight entirely.'],
      checkinName: 'As-Salam',
      checkinNameArabic: 'السلام',
      revealDeck: const NameStoryDeck(
        deckId: 'as-salam@1',
        nameId: 6,
        transliteration: 'As-Salam',
        chipKeys: [],
        positionInPair: 1,
        beats: [
          NameStoryBeat(kind: 'story', primary: 'The cave.'),
        ],
        sources: [],
        author: 'test',
        reviewedBy: 'test',
        reviewedAt: '2026-08-02',
        reviewVerdict: 'good',
      ),
    ));

    // `answeredNight` carries a full ReflectResponse — the prior night's.
    await notifier.startDeeper();
    expect(notifier.state.reflectResult, isNull,
        reason: 'the deck path promises no AI reflection; make that literal');

    await notifier.completeDeeper();

    final row = reflectionInserts().single;
    expect(row['user_text'], 'Tonight is a different weight entirely.');
    expect(row['name'], 'As-Salam');

    // 2026-08-07: this used to assert `beat_data` was NULL, because a deck
    // night wrote no beats of any kind — which turned out to be the separate
    // bug that made the archive re-read a deck night as two screens. A deck
    // night now carries the DECK's beats.
    //
    // The invariant this test was written for is untouched, and is what the
    // assertions below check: tonight's deck, never the previous night's
    // response. `beat_data isNull` was only ever a proxy for it.
    final beats = (row['beat_data'] as Map).cast<String, dynamic>();
    expect(beats['storyBeats'], ['The cave.'],
        reason: "tonight's deck, and only it");
    expect(beats['storyTitle'], anyOf(isNull, isEmpty),
        reason: 'the deck beat carries no label — the stale AI title must not '
            'wander in to fill the empty slot');
    expect(beats['takeaway'], anyOf(isNull, isEmpty));
    expect(row['story'], isNot(contains('The companions rose')));
    expect(row['reframe'], isNot(contains('Al-Halim withholds')));
    expect(row['dua_source'], isNot('Bukhari 220'));
  });

  // 2026-08-07 — reported from a device: the latest muḥāsabah opened as a
  // TWO-screen story (the cover and the Name) where the night before it opened
  // as a full one.
  //
  // The two nights took different paths. The AI night had a `ReflectResponse`
  // and `buildSavedReflection` wrote every field from it. The deck night had a
  // `NameStoryDeck` on `state.revealDeck` — pre-authored beats, verses, a duʿā,
  // a takeaway, all of it already on state at write time — and
  // `buildSavedReflection` reads NONE of it, because it only ever looked at
  // `response`. So the row went to the server with `reframe=''`, `story=''`,
  // `dua_arabic=''`, `verses=[]` and `beat_data=null`: the user's words and the
  // Name, and nothing else. The archive rendered exactly what it was given.
  //
  // The night was a complete, correct muḥāsabah. Only the artifact was empty —
  // which is the precise failure this whole wave exists to end.
  group('a deck night keeps the deck', () {
    /// A full pre-authored deck: one of every kind the flow renders.
    const richDeck = NameStoryDeck(
      deckId: 'ash-shafi@1',
      nameId: 12,
      transliteration: 'Ash-Shafi',
      chipKeys: [],
      positionInPair: 1,
      beats: [
        NameStoryBeat(kind: 'bridge', primary: 'The wound is not the verdict.'),
        NameStoryBeat(
            kind: 'recognition', primary: 'You have carried this a long time.'),
        NameStoryBeat(
          kind: 'name_intro',
          arabic: 'الشافي',
          transliteration: 'Ash-Shafi',
          primary: 'The Healer',
        ),
        NameStoryBeat(
          kind: 'story',
          label: 'The Cure of Ayyub',
          primary: 'Ayyub lost everything and did not lose his tongue.',
          source: "(Qur'an 21:83)",
        ),
        NameStoryBeat(
          kind: 'story',
          primary: 'He asked once, and asked plainly.',
          source: "(Qur'an 21:84)",
        ),
        NameStoryBeat(
          kind: 'verse',
          arabic: 'وَإِذَا مَرِضْتُ فَهُوَ يَشْفِينِ',
          primary: 'And when I am ill, it is He who cures me.',
          source: 'Ash-Shuara 26:80',
        ),
        NameStoryBeat(
          kind: 'dua',
          arabic: 'اللَّهُمَّ اشْفِنِي',
          transliteration: 'Allahumma-shfini',
          primary: 'O Allah, heal me.',
          source: 'Bukhari 5675',
        ),
        NameStoryBeat(
            kind: 'takeaway', primary: 'Returning is not the same as failing.'),
      ],
      sources: [],
      author: 'test',
      reviewedBy: 'test',
      reviewedAt: '2026-08-07',
      reviewVerdict: 'good',
    );

    DailyLoopNotifier deckNight() => notifierWith(answeredNight.copyWith(
          checkinAnswers: ['I keep sinning and going back'],
          checkinName: 'Ash-Shafi',
          checkinNameArabic: 'الشافي',
          revealDeck: richDeck,
        ));

    test('the row carries the deck it was read from', () async {
      useZone('America/Los_Angeles');
      final notifier = deckNight();
      await notifier.startDeeper();
      await notifier.completeDeeper();

      final row = reflectionInserts().single;
      expect(row['user_text'], 'I keep sinning and going back');
      expect(row['name'], 'Ash-Shafi');

      final beats = (row['beat_data'] as Map).cast<String, dynamic>();
      expect(beats['storyBeats'], [
        'Ayyub lost everything and did not lose his tongue.',
        'He asked once, and asked plainly.',
      ]);
      expect(beats['storyTitle'], 'The Cure of Ayyub');
      expect(beats['storySource'], "(Qur'an 21:84)",
          reason: 'the source shown on the LAST story screen, matching '
              'buildBeatScreensFromReflection');
      expect(beats['takeaway'], 'Returning is not the same as failing.');
      expect(beats['reframeKey'], 'The wound is not the verdict.');
      expect(beats['reframeBody'], 'You have carried this a long time.');
    });

    test('the duʿā and the verse survive too', () async {
      useZone('America/Los_Angeles');
      final notifier = deckNight();
      await notifier.startDeeper();
      await notifier.completeDeeper();

      final row = reflectionInserts().single;
      expect(row['dua_arabic'], 'اللَّهُمَّ اشْفِنِي');
      expect(row['dua_transliteration'], 'Allahumma-shfini');
      expect(row['dua_translation'], 'O Allah, heal me.');
      expect(row['dua_source'], 'Bukhari 5675');

      final verses =
          (row['verses'] as List).map((v) => (v as Map)).toList();
      expect(verses, hasLength(1));
      expect(verses.single['arabic'], 'وَإِذَا مَرِضْتُ فَهُوَ يَشْفِينِ');
      expect(verses.single['translation'],
          'And when I am ill, it is He who cures me.');
      expect(verses.single['reference'], 'Ash-Shuara 26:80');
    });

    test('the archive can re-read it as a full story, not a cover and a Name',
        () async {
      useZone('America/Los_Angeles');
      final notifier = deckNight();
      await notifier.startDeeper();
      await notifier.completeDeeper();

      final saved = (await cachedReflections()).single;
      final screens = buildBeatScreensFromReflection(saved);
      final kinds = screens.map((s) => s.kind).toList();

      expect(kinds.first, BeatKind.entryCover);
      expect(kinds, contains(BeatKind.name));
      expect(kinds, contains(BeatKind.keyLine));
      expect(kinds.where((k) => k == BeatKind.story), hasLength(2));
      expect(kinds, contains(BeatKind.takeaway));
      expect(kinds, contains(BeatKind.verse));
      expect(kinds, contains(BeatKind.dua));
      expect(screens.length, greaterThan(2),
          reason: 'the reported symptom was exactly two screens');
      expect(duaScreenIndex(screens), isNot(-1),
          reason: '"skip to duʿā" has somewhere to go again');
    });

    test('a deck night STILL does not inherit the previous AI night', () async {
      // The invariant the older regression test was written for. The fix adds
      // the deck's own beats; it must not reopen the door to another night's.
      useZone('America/Los_Angeles');
      final notifier = deckNight();
      await notifier.startDeeper();
      await notifier.completeDeeper();

      final row = reflectionInserts().single;
      expect(row['story'], isNot(contains('The companions rose')));
      expect(row['reframe'], isNot(contains('Al-Halim withholds')));
      expect(row['dua_source'], isNot('Bukhari 220'));
    });

    test('a deck with no renderable content still writes the night', () async {
      // The floor: an empty deck must degrade to what the legacy fallback
      // already wrote, not throw and not lose the entry.
      useZone('America/Los_Angeles');
      final notifier = notifierWith(answeredNight.copyWith(
        checkinAnswers: ['A quiet night.'],
        checkinName: 'As-Salam',
        checkinNameArabic: 'السلام',
        revealDeck: const NameStoryDeck(
          deckId: 'empty@1',
          nameId: 6,
          transliteration: 'As-Salam',
          chipKeys: [],
          positionInPair: 1,
          beats: [],
          sources: [],
          author: 'test',
          reviewedBy: 'test',
          reviewedAt: '2026-08-07',
          reviewVerdict: 'good',
        ),
      ));
      await notifier.startDeeper();
      await notifier.completeDeeper();

      final row = reflectionInserts().single;
      expect(row['user_text'], 'A quiet night.');
      expect(row['name'], 'As-Salam');
      expect(row['beat_data'], isNull);
    });
  });

  test('a bare lifecycle flip writes no empty row', () async {
    useZone('America/Los_Angeles');

    // Nothing revealed, nothing written: a legacy skip, or a harness driving
    // the notifier directly. An empty row is not an artifact — and it would
    // occupy the day's one muḥāsabah slot.
    await notifierWith(const DailyLoopState(loaded: true)).completeDeeper();

    expect(reflectionInserts(), isEmpty);
  });

  test('the answer text never becomes an analytics property', () async {
    // The rule is absolute for telemetry and permitted for the user's own
    // RLS-protected row (design D2). This pins the half that must not change.
    useZone('America/Los_Angeles');

    final events = <(String, Map<String, dynamic>)>[];
    DailyLoopNotifier.onAnalyticsEvent = (e, p) => events.add((e, p));
    addTearDown(() => DailyLoopNotifier.onAnalyticsEvent = null);

    await notifierWith(answeredNight).completeDeeper();

    const answer = 'I snapped at my brother and I have been sitting with it.';
    expect(reflectionInserts().single['user_text'], answer,
        reason: 'the server row is where it is allowed to be');
    for (final event in events) {
      expect(jsonEncode(event.$2), isNot(contains('snapped')),
          reason: '${event.$1} carries the user\'s own words');
    }
  });
}

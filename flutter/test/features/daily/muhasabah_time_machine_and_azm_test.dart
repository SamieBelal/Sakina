// The same-prompt time machine (C3) and ʿazm (C4).
//
// Both exist because Wave B started keeping the night. C3 is the archive paying
// rent — your own answer to the same question 30 / 90 / 365 nights ago, revealed
// only once tonight is done. C4 is the classical end of muḥāsabah, one line of
// forward resolve, handed back as the next night's opening line.
//
// Three properties matter enough to pin:
//   1. NEAREST anchor, exactly one. A user with both a month-ago and a year-ago
//      entry meets the month.
//   2. It renders nothing when there is no anchor, and it CANNOT be reached
//      before completing — enforced by the state never carrying it, not by a
//      widget deciding to hide it.
//   3. The ʿazm persists on the night's own row and comes back as the next
//      night's opener, bounded so a stale resolve is not handed back as if it
//      were last night's.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  late FakeSupabaseSyncService fakeSync;

  /// Noon UTC on 2026-08-02, in UTC, so every offset below is plain arithmetic.
  final tonight = DateTime.utc(2026, 8, 2, 12);
  const today = '2026-08-02';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'UTC';
    debugDailyLoopClock = () => tonight;
  });

  tearDown(() {
    debugDailyLoopClock = () => DateTime.now().toUtc();
    debugResetUserLocalDay();
    SupabaseSyncService.debugReset();
  });

  /// Writes a past muḥāsabah entry straight into the cache, the way a
  /// `sync_all_user_data()` rehydration would.
  Future<void> seedNight({
    required String day,
    required String words,
    String name = 'Al-Halim',
    String azm = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = fakeSync.scopedKey('saved_reflections');
    final existing = jsonDecode(prefs.getString(key) ?? '[]') as List;
    final entry = SavedReflection(
      id: 'entry-$day',
      date: '${day}T21:00:00.000Z',
      userText: words,
      name: name,
      nameArabic: 'الحليم',
      reframePreview: '',
      source: reflectionSourceMuhasabah,
      entryLocalDay: day,
      azm: azm,
    );
    await prefs.setString(key, jsonEncode([entry.toJson(), ...existing]));
  }

  DailyLoopNotifier notifierWith(DailyLoopState state) {
    final notifier = DailyLoopNotifier(skipInitForTests: true);
    addTearDown(notifier.dispose);
    notifier.debugSetState(state);
    return notifier;
  }

  const answeredNight = DailyLoopState(
    loaded: true,
    checkinDone: true,
    checkinAnswers: ['Tonight I am tired and short with everyone.'],
    checkinName: 'As-Sabur',
    checkinNameArabic: 'الصبور',
  );

  Future<DailyLoopNotifier> completeTonight() async {
    final notifier = notifierWith(answeredNight);
    await notifier.completeDeeper();
    return notifier;
  }

  group('the time machine picks the nearest anchor', () {
    test('a month ago wins over three months and a year', () async {
      await seedNight(day: '2026-07-03', words: 'A month ago, I was angry.');
      await seedNight(day: '2026-05-04', words: 'Three months ago.');
      await seedNight(day: '2025-08-02', words: 'A year ago.');

      final notifier = await completeTonight();

      expect(notifier.state.timeMachineEntry, isNotNull);
      expect(notifier.state.timeMachineEntry!.userText,
          'A month ago, I was angry.');
      expect(notifier.state.timeMachineEntry!.entryLocalDay, '2026-07-03',
          reason: '2026-08-02 minus 30 days');
    });

    test('three months is used when the month-ago night is missing', () async {
      await seedNight(day: '2026-05-04', words: 'Three months ago.');
      await seedNight(day: '2025-08-02', words: 'A year ago.');

      final notifier = await completeTonight();
      expect(notifier.state.timeMachineEntry!.entryLocalDay, '2026-05-04');
    });

    test('a year is the last resort', () async {
      await seedNight(day: '2025-08-02', words: 'A year ago.');

      final notifier = await completeTonight();
      expect(notifier.state.timeMachineEntry!.entryLocalDay, '2025-08-02');
    });

    test('nothing at an anchor day means nothing is revealed — a new user '
        'simply does not see it', () async {
      // Yesterday and last week exist; neither is an anchor.
      await seedNight(day: '2026-08-01', words: 'Yesterday.');
      await seedNight(day: '2026-07-26', words: 'Last week.');

      final notifier = await completeTonight();
      expect(notifier.state.timeMachineEntry, isNull);
    });

    test('a completely fresh user sees nothing and completes normally',
        () async {
      final notifier = await completeTonight();
      expect(notifier.state.timeMachineEntry, isNull);
      expect(notifier.state.currentStep, DailyLoopStep.completed);
      expect(notifier.state.tonightEntry, isNotNull);
    });

    test('an anchor with no words of its own is skipped', () async {
      await seedNight(day: '2026-07-03', words: '   ');
      await seedNight(day: '2026-05-04', words: 'Three months ago.');

      final notifier = await completeTonight();
      expect(notifier.state.timeMachineEntry!.entryLocalDay, '2026-05-04');
    });

    test('a Reflect entry on the anchor day is not an anchor — the time '
        'machine is same-PROMPT', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        fakeSync.scopedKey('saved_reflections'),
        jsonEncode([
          const SavedReflection(
            id: 'reflect-1',
            date: '2026-07-03T10:00:00.000Z',
            userText: 'A Reflect save, not a night.',
            name: 'Al-Wakeel',
            nameArabic: 'الوكيل',
            reframePreview: '',
            entryLocalDay: '2026-07-03',
          ).toJson(),
        ]),
      );

      final notifier = await completeTonight();
      expect(notifier.state.timeMachineEntry, isNull);
    });

    test('the anchor arithmetic survives a DST boundary', () async {
      // 2026-11-08 is the Sunday after the US clocks go back. Thirty days
      // earlier is 2026-10-09. A `DateTime.parse` (local midnight) minus 30 days
      // lands at 23:00 on the 8th in a zone that changed offset, and the anchor
      // silently shifts by one — which is why the parse is UTC.
      expect(
        formatLocalDay(
            parseLocalDayString('2026-11-08')!.subtract(const Duration(days: 30))),
        '2026-10-09',
      );
    });
  });

  group('the time machine cannot be peeked at before completing', () {
    test('mid-night state carries no anchor, however many exist', () async {
      await seedNight(day: '2026-07-03', words: 'A month ago, I was angry.');

      final notifier = notifierWith(answeredNight);
      expect(notifier.state.timeMachineEntry, isNull);

      // The reveal has happened, the beats are on screen — still nothing.
      await notifier.startDeeper();
      expect(notifier.state.timeMachineEntry, isNull,
          reason: 'the anchor is resolved by completeDeeper and nowhere else');

      await notifier.completeDeeper();
      expect(notifier.state.timeMachineEntry, isNotNull);
    });

    test('a cold restart mid-night does not restore the anchor, and a cold '
        'restart AFTER completing does', () async {
      await seedNight(day: '2026-07-03', words: 'A month ago, I was angry.');

      // Mid-night: hydration runs, the step is not `completed`.
      final midNight = DailyLoopNotifier(skipInitForTests: true);
      addTearDown(midNight.dispose);
      midNight.debugSetState(answeredNight.copyWith(
        currentStep: DailyLoopStep.deeper,
      ));
      await midNight.debugHydrateJournalContextForTest();
      expect(midNight.state.timeMachineEntry, isNull);

      // After completing: the same screen must come back the same way.
      await completeTonight();
      final restored = DailyLoopNotifier(skipInitForTests: true);
      addTearDown(restored.dispose);
      restored.debugSetState(answeredNight.copyWith(
        currentStep: DailyLoopStep.completed,
      ));
      await restored.debugHydrateJournalContextForTest();
      expect(restored.state.timeMachineEntry, isNotNull);
      expect(restored.state.tonightEntry, isNotNull);
    });
  });

  group('ʿazm', () {
    test('persists on the night\'s own row, as an UPDATE not a second row',
        () async {
      final notifier = await completeTonight();
      final insertsBefore = fakeSync.insertCalls.length;

      expect(await notifier.setTonightAzm('  Tomorrow I will hold my tongue.  '),
          isTrue);

      expect(fakeSync.insertCalls, hasLength(insertsBefore),
          reason: 'the resolve edits tonight; it never creates an entry');
      final write = fakeSync.rawUpsertCalls.last;
      expect(write['table'], 'user_reflections');
      expect((write['data'] as Map)['azm'], 'Tomorrow I will hold my tongue.');
      expect(notifier.state.tonightEntry!.azm,
          'Tomorrow I will hold my tongue.');
    });

    test('is clamped to 500 chars, matching user_reflections_azm_length_cap',
        () async {
      final notifier = await completeTonight();
      await notifier.setTonightAzm('z' * 900);

      final stored =
          (fakeSync.rawUpsertCalls.last['data'] as Map)['azm'] as String;
      expect(stored.length, 500);
    });

    test('is editable — the resolve is not a submission', () async {
      final notifier = await completeTonight();
      await notifier.setTonightAzm('First thought.');
      await notifier.setTonightAzm('Actually, this one.');

      expect(notifier.state.tonightEntry!.azm, 'Actually, this one.');
      expect(notifier.state.tonightEntry!.thread, isEmpty,
          reason: 'an ʿazm edit is not an append');
    });

    test('a night with no entry cannot carry a resolve', () async {
      final notifier = notifierWith(answeredNight);
      expect(await notifier.setTonightAzm('anything'), isFalse);
    });

    test('resurfaces as the NEXT night\'s opening line', () async {
      final notifier = await completeTonight();
      await notifier.setTonightAzm('Tomorrow I will call my mother.');

      // Tomorrow.
      debugDailyLoopClock = () => tonight.add(const Duration(days: 1));
      debugResetUserLocalDay();
      debugUserTimeZoneOverride = 'UTC';

      final tomorrow = DailyLoopNotifier(skipInitForTests: true);
      addTearDown(tomorrow.dispose);
      tomorrow.debugSetState(const DailyLoopState(loaded: true));
      await tomorrow.debugHydrateJournalContextForTest();

      expect(tomorrow.state.lastNightAzm, 'Tomorrow I will call my mother.');
      expect(tomorrow.state.tonightEntry, isNull,
          reason: 'tomorrow has not been written yet');
    });

    test('tonight\'s own resolve is never handed back as tonight\'s opener',
        () async {
      final notifier = await completeTonight();
      await notifier.setTonightAzm('Tomorrow I will call my mother.');
      await notifier.debugHydrateJournalContextForTest();

      expect(notifier.state.lastNightAzm, isNull,
          reason: 'the opener reads nights STRICTLY BEFORE today');
    });

    test('a stale resolve is not resurfaced — the window is seven nights',
        () async {
      await seedNight(
        day: '2026-07-20',
        words: 'Two weeks ago.',
        azm: 'A resolve I have long since forgotten.',
      );

      final notifier = notifierWith(const DailyLoopState(loaded: true));
      await notifier.debugHydrateJournalContextForTest();

      expect(notifier.state.lastNightAzm, isNull,
          reason: 'handing back a fortnight-old resolve is an accusation, not '
              'a reminder');
    });

    test('the most recent resolve inside the window wins', () async {
      await seedNight(day: '2026-07-29', words: 'Four nights ago.', azm: 'older');
      await seedNight(day: '2026-08-01', words: 'Last night.', azm: 'newer');
      await seedNight(day: '2026-07-31', words: 'Two nights ago.', azm: 'middle');

      final notifier = notifierWith(const DailyLoopState(loaded: true));
      await notifier.debugHydrateJournalContextForTest();

      expect(notifier.state.lastNightAzm, 'newer');
    });

    test('a night with no resolve is skipped rather than blanking the opener',
        () async {
      await seedNight(day: '2026-08-01', words: 'Last night, wordless.');
      await seedNight(day: '2026-07-31', words: 'Two nights ago.', azm: 'held');

      final notifier = notifierWith(const DailyLoopState(loaded: true));
      await notifier.debugHydrateJournalContextForTest();

      expect(notifier.state.lastNightAzm, 'held');
    });

    test('today\'s date lands on the entry, not the timestamp', () async {
      // Guards the same bug class Wave B's `entry_local_day` exists for: the
      // opener and the anchor both key on the LOCAL day, so a user east of UTC
      // must not read yesterday's resolve as today's.
      expect(parseLocalDayString(today), DateTime.utc(2026, 8, 2));
      expect(formatLocalDay(DateTime.utc(2026, 8, 2)), today);
      expect(parseLocalDayString('not-a-day'), isNull);
      expect(parseLocalDayString('2026-08'), isNull);
    });
  });
}

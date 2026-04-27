// §10 quest progress on tier-up — pins that `onCardTieredUp` appends
// exactly one entry to the local tier-ups log per call, and that
// `tierUpsThisWeek` / `tierUpsThisMonth` count those entries correctly.
//
// The log lives in SharedPreferences under the scoped key
// `tier_ups_log_v1:<userId>` (`quests_provider.dart:599, 1161`). Each entry
// is an ISO-8601 timestamp; week and month windows are computed via
// `_weekStart()` and `_monthStart()` inside the provider.
//
// Why this matters: the weekly threshold quest "Tier up N cards this week"
// reads from this log. If `onCardTieredUp` ever stopped appending (e.g.
// `_recordTierUpEvent` was renamed but the call site missed), the quest
// would silently never progress. This test catches that.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  const tierUpsLogKey = 'tier_ups_log_v1';
  const userId = 'user-1';
  const scopedKey = '$tierUpsLogKey:$userId';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: userId);
    SupabaseSyncService.debugSetInstance(fakeSync);
    // Daily-quest-completion path inside `onCardTieredUp` calls _tryComplete,
    // which may try to earn xp/tokens/scrolls. Stub them to harmless values.
    fakeSync.rpcHandlers['earn_xp'] = (_) async => 0;
    fakeSync.rpcHandlers['earn_tokens'] = (_) async => 0;
    fakeSync.rpcHandlers['earn_scrolls'] = (_) async => 0;
  });

  tearDown(SupabaseSyncService.debugReset);

  Future<List<String>> readLog() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(scopedKey);
    if (raw == null) return <String>[];
    return (jsonDecode(raw) as List).cast<String>();
  }

  test('onCardTieredUp appends exactly one timestamp to the scoped log',
      () async {
    final notifier = QuestsNotifier();
    addTearDown(notifier.dispose);

    expect(await readLog(), isEmpty,
        reason: 'log should not exist before first tier-up');

    await notifier.onCardTieredUp();

    final log = await readLog();
    expect(log.length, 1);
    // Each entry parses as a valid ISO-8601 timestamp.
    expect(DateTime.tryParse(log.first), isNotNull);
  });

  test('three calls append three log entries (no de-dup, no skip)', () async {
    final notifier = QuestsNotifier();
    addTearDown(notifier.dispose);

    await notifier.onCardTieredUp();
    await notifier.onCardTieredUp();
    await notifier.onCardTieredUp();

    final log = await readLog();
    expect(log.length, 3);
  });

  test('tierUpsThisWeek counts only entries inside the current week window',
      () async {
    final notifier = QuestsNotifier();
    addTearDown(notifier.dispose);

    // Pre-seed the log with two old entries (>14 days ago) and one fresh.
    final old1 = DateTime.now().subtract(const Duration(days: 30));
    final old2 = DateTime.now().subtract(const Duration(days: 14));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      scopedKey,
      jsonEncode([old1.toIso8601String(), old2.toIso8601String()]),
    );

    await notifier.onCardTieredUp(); // adds one fresh entry → "this week"

    final log = await readLog();
    expect(log.length, 3, reason: 'append, not replace');
    expect(await notifier.tierUpsThisWeek(), 1,
        reason:
            'only the fresh entry falls inside _weekStart()..now; the seeded '
            'entries are 14 and 30 days back');
  });

  test('tierUpsThisMonth counts entries within the current calendar month',
      () async {
    final notifier = QuestsNotifier();
    addTearDown(notifier.dispose);

    // Seed one entry from a clearly-prior month (60 days back) plus today's
    // fresh entry. The 60-day-back entry must NOT be counted.
    final priorMonth = DateTime.now().subtract(const Duration(days: 60));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      scopedKey,
      jsonEncode([priorMonth.toIso8601String()]),
    );

    await notifier.onCardTieredUp();

    expect(await notifier.tierUpsThisMonth(), 1);
  });

  test('log is capped at 200 entries (oldest dropped from front)', () async {
    final notifier = QuestsNotifier();
    addTearDown(notifier.dispose);

    // Seed 200 entries in chronological order (oldest first → newest last)
    // to match how production writes them. The cap at
    // `quests_provider.dart:1168-1170` removes from index 0, so the OLDEST
    // entry should be dropped when we exceed 200.
    final stale = List<String>.generate(
      200,
      (i) => DateTime.now()
          .subtract(Duration(days: 200 - i))
          .toIso8601String(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(scopedKey, jsonEncode(stale));

    await notifier.onCardTieredUp();

    final log = await readLog();
    expect(log.length, 200, reason: 'log must not exceed cap');
    // The dropped entry was stale[0] (today − 200 days). log[0] is now
    // stale[1] (today − 199 days).
    final droppedTimestamp = stale.first;
    expect(log.contains(droppedTimestamp), isFalse,
        reason: 'oldest stale entry must have been removed');
    expect(log.first, stale[1],
        reason: 'log must shift by one — second-oldest is now at front');
    expect(log.last, isNot(equals(stale.last)),
        reason: 'last position should be the freshly appended entry');
  });
}

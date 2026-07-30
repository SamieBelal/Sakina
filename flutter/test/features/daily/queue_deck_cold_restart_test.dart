import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/name_stories_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/fake_supabase_sync_service.dart';

/// Pins that a D1 deck reveal survives the app being killed mid-flow.
///
/// `_loadTodayState` restores `checkinDone`, so `discoverName` never re-runs
/// after a cold restart — which meant `revealDeck` (in-memory) came back null and
/// the user resumed on the AI reflection. That is the one reveal the W3 plan
/// promises has no OpenAI dependency (§4), on the most important comeback day in
/// the funnel, and the restart is entirely ordinary: a phone call, a swipe-away,
/// iOS reclaiming memory between the card landing and "Ameen".
///
/// **How "no AI call" is asserted** (technique inherited from
/// `queue_deck_reveal_test.dart`): `reflectWithOpenAI` has no injection seam, but
/// it writes to `reflect_classifier_log` in debug builds *before* it can return,
/// so an insert on that table is a faithful witness that the AI seam was
/// entered. Absence of the row is absence of the call.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  /// Al-Wakeel — queue position 2 of the `anxiety` pair, and one of the 14
  /// approved decks. Real shipped content on purpose: a fixture would paper over
  /// the wave's actual claim.
  const deckedNameId = 35;
  const deckedDeckId = 'al-wakeel@1';

  final stories = NameStoriesService(
    loadAsset: (_) async =>
        File(NameStoriesService.assetPath).readAsStringSync(),
  );

  late FakeSupabaseSyncService fakeSync;

  /// The persisted blob at the exact moment the reveal has landed and the deck
  /// has not been tapped through yet.
  ///
  /// **Hand-written, and that is a liability** — it is why the review caught what
  /// this file missed. When these tests were first written `discoverName` did not
  /// call `_persistTodayState` at all, so this shape was one production never
  /// produced and the restore branch under test was unreachable. The
  /// `round-trips through the real writer` test at the bottom is the guard
  /// against that recurring; keep it passing and these stay honest.
  Map<String, Object> midFlowBlob({
    required String revealSource,
    int? revealNameId = deckedNameId,
  }) {
    final key =
        FakeSupabaseSyncService(userId: 'user-A').scopedKey('daily_loop_2026-08-04');
    return {
      key: jsonEncode({
        'checkinDone': true,
        'deeperDone': false,
        'questDone': false,
        'currentStep': 0,
        'checkinAnswers': const <String>[],
        'checkinName': 'Al-Wakeel',
        'reflectStep': 0,
        'revealSource': revealSource,
        'revealQueuePosition': 2,
        'revealNameId': revealNameId,
      }),
    };
  }

  bool aiCallHappened() =>
      fakeSync.insertCalls.any((c) => c['table'] == 'reflect_classifier_log');

  void install(Map<String, Object> prefs) {
    SharedPreferences.setMockInitialValues(prefs);
    fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugDailyLoopClock = () => DateTime.utc(2026, 8, 4, 3, 0);
  }

  tearDown(() {
    SupabaseSyncService.debugReset();
    debugDailyLoopClock = () => DateTime.now().toUtc();
  });

  /// Constructs the notifier and lets `_initialize` (and the awaited
  /// `_loadTodayState` inside it) settle.
  Future<DailyLoopNotifier> restart() async {
    final notifier = DailyLoopNotifier(storiesService: stories);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return notifier;
  }

  test('a queue reveal resumes on the authored deck, with no AI call', () async {
    install(midFlowBlob(revealSource: revealSourceQueue));

    final notifier = await restart();

    expect(notifier.state.revealDeck, isNotNull,
        reason: 'the deck is re-resolved from the bundle on restore');
    expect(notifier.state.revealDeck!.deckId, deckedDeckId);
    expect(notifier.state.revealSource, revealSourceQueue);
    expect(notifier.state.revealQueuePosition, 2);
    expect(aiCallHappened(), isFalse,
        reason: 'a restored deck reveal must still spend no OpenAI call — that '
            'is the guarantee the persistence exists to keep');
  });

  test('a gacha reveal resumes exactly as it does today', () async {
    // Same Name — one that HAS a deck — but reached by the ordinary pull. The
    // deck must not leak into the legacy path on restore any more than it does
    // on the live reveal.
    install(midFlowBlob(revealSource: revealSourceGacha));

    final notifier = await restart();

    expect(notifier.state.revealDeck, isNull);
    expect(notifier.state.revealSource, revealSourceGacha);
    expect(aiCallHappened(), isTrue,
        reason: 'the legacy path still prefetches the reflection');
  });

  test('a blob written before this change degrades to the AI reflection',
      () async {
    // Forward-compatibility: a user mid-flow across the release upgrade has a
    // blob with NO reveal keys at all — not merely a null `revealNameId`, which
    // is what this test used to assert while still emitting `revealSource` and
    // `revealQueuePosition` that a pre-change blob could never contain.
    final key = FakeSupabaseSyncService(userId: 'user-A')
        .scopedKey('daily_loop_2026-08-04');
    install({
      key: jsonEncode({
        'checkinDone': true,
        'deeperDone': false,
        'questDone': false,
        'currentStep': 0,
        'checkinAnswers': const <String>[],
        'checkinName': 'Al-Wakeel',
        'reflectStep': 0,
      }),
    });

    final notifier = await restart();

    expect(notifier.state.revealDeck, isNull);
    expect(notifier.state.revealSource, revealSourceGacha,
        reason: 'the absent key defaults, it does not throw');
    expect(notifier.state.revealQueuePosition, isNull);
    expect(notifier.state.checkinDone, isTrue,
        reason: 'the rest of the restore is unaffected');
  });

  test('the reveal round-trips through the real writer', () async {
    // The test that would have caught the original defect, and the reason the
    // hand-written blobs above are trustworthy.
    //
    // Every other test in this file installs a blob by hand. That is why nobody
    // noticed `discoverName` did not call `_persistTodayState` at all: the restore
    // branch was correct code behind a condition production never satisfied. This
    // drives the WRITER — a real queue-driven reveal — then reads what landed in
    // prefs and hands it to a second notifier, so the writer and reader are
    // pinned as a pair.
    install(const {});
    PurchaseService.debugSetOverride(_FreeUser());
    addTearDown(PurchaseService.debugClearOverride);
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'America/Los_Angeles';
    addTearDown(() {
      debugResetUserLocalDay();
      debugUserTimeZoneOverride = null;
    });
    await hydrateTokenCache(balance: 100, totalSpent: 0);

    Map<String, dynamic> serverRow(int position, int nameId,
            {DateTime? unsealedAt}) =>
        {
          'position': position,
          'name_id': nameId,
          'unsealed_at': unsealedAt?.toIso8601String(),
        };

    final live = DailyLoopNotifier(
      storiesService: stories,
      nameQueueService: NameQueueService(
        currentUserId: () => fakeSync.userId,
        // Position 1 met long ago and outside the floor; position 2 sealed.
        selectRows: (_) async => [
          serverRow(1, 11, unsealedAt: DateTime.utc(2026, 8, 1, 15)),
          serverRow(2, deckedNameId),
        ],
        callRpc: (_, __) async => [
          serverRow(2, deckedNameId,
              unsealedAt: DateTime.utc(2026, 8, 4, 2, 30)),
        ],
      ),
    );
    addTearDown(live.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    await live.discoverName();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(live.state.revealSource, revealSourceQueue);
    expect(live.state.revealDeck?.deckId, deckedDeckId);

    // The blob must actually be on disk — this is the assertion whose absence
    // let the bug through.
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(fakeSync.scopedKey('daily_loop_2026-08-04'));
    expect(raw, isNotNull,
        reason: 'discoverName must persist the reveal, or the restore branch in '
            '_loadTodayState is unreachable and a restart runs a SECOND reveal');
    final blob = jsonDecode(raw!) as Map<String, dynamic>;
    expect(blob['checkinDone'], isTrue);
    expect(blob['deeperDone'], isFalse);
    expect(blob['revealSource'], revealSourceQueue);
    expect(blob['revealQueuePosition'], 2);
    expect(blob['revealNameId'], deckedNameId);

    // Now the reader half, against the writer's own output.
    final resumed = DailyLoopNotifier(storiesService: stories);
    addTearDown(resumed.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(resumed.state.checkinDone, isTrue);
    expect(resumed.state.revealSource, revealSourceQueue);
    expect(resumed.state.revealQueuePosition, 2);
    expect(resumed.state.revealDeck?.deckId, deckedDeckId,
        reason: 'the same authored deck, rebuilt from the persisted id');
  });
}

class _FreeUser extends PurchaseService {
  _FreeUser() : super.test();
  @override
  Future<bool> isPremium() async => false;
}

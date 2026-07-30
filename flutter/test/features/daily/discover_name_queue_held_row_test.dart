import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/name_stories_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/fake_supabase_sync_service.dart';

/// The client half of the D1 floor fix: a non-null `unsealNext()` result is not
/// proof that a position moved.
///
/// Inside its 20h floor `unseal_next_name` returns the most recently unsealed
/// row rather than null. The planner is supposed to keep us out of that branch,
/// but it mirrors the floor from the DEVICE clock against a possibly stale cache
/// while the RPC re-derives it server-side — so they disagree on ordinary drift
/// at the floor's edge, after a failed authoritative read, and when a user sets
/// their clock forward on purpose. Unguarded, that last case is rewarded: the D0
/// Name is re-revealed as today's queue reveal, with a Silver dignity floor and
/// a free tier-up on a card the user already owns.
///
/// The discriminator is **did the position move** — was it still sealed in the
/// pre-call view — not whether its Name is already owned. The second test is the
/// regression guard against reintroducing an owned-Name check: a queued Name's
/// card can legitimately be pre-owned from a Store purchase or a prior tier-up
/// pull (plan §11), and that unseal must still happen.
class _FreeUser extends PurchaseService {
  _FreeUser() : super.test();
  @override
  Future<bool> isPremium() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  final nowUtc = DateTime.utc(2026, 8, 4, 3, 0);

  /// Al-Wakeel — one of the 14 approved decks, so the deck resolves for real
  /// rather than through a fixture.
  const deckedNameId = 35;
  const deckedDeckId = 'al-wakeel@1';

  /// The asset bundle isn't available in a unit test, so the real decks are
  /// read off disk (same seam as `queue_deck_reveal_test.dart`).
  final stories = NameStoriesService(
    loadAsset: (_) async =>
        File(NameStoriesService.assetPath).readAsStringSync(),
  );

  late FakeSupabaseSyncService fakeSync;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    PurchaseService.debugSetOverride(_FreeUser());
    await hydrateTokenCache(balance: 100, totalSpent: 0);
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'America/Los_Angeles';
    debugDailyLoopClock = () => nowUtc;
  });

  tearDown(() {
    debugDailyLoopClock = () => DateTime.now().toUtc();
    debugResetUserLocalDay();
    debugLastPickExclude = null;
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  Map<String, dynamic> serverRow(int position, int nameId,
          {DateTime? unsealedAt}) =>
      {
        'position': position,
        'name_id': nameId,
        'unsealed_at': unsealedAt?.toIso8601String(),
      };

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  /// Lets the constructor's `_initialize()` land before the reveal runs, so a
  /// late `copyWith` (which clears `error` unconditionally) can't mask what
  /// these tests assert. Same reason as `discover_name_queue_fallback_test.dart`.
  Future<void> warmUp(DailyLoopNotifier notifier) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(notifier.state.loaded, isTrue);
  }

  test('a row whose position was already unsealed in the pre-call view is an '
      'ordinary gacha reveal, not a repeat of the D0 Name', () async {
    // D0 already happened: the user met Name 11 at the onboarding reveal.
    await engageCard(11);
    expect((await getCardCollection()).tierFor(11), 1);

    // The client's view says position 1 was unsealed 30h ago — outside the
    // floor — so the planner returns QueueUnseal. The server disagrees (clock
    // drift, a stale mirror, or a deliberately forwarded device clock) and is
    // still inside its floor, so it hands back the row it last unsealed. That
    // position was already unsealed here before we asked: nothing moved.
    var rpcCalls = 0;
    final notifier = DailyLoopNotifier(
      storiesService: stories,
      nameQueueService: NameQueueService(
        currentUserId: () => fakeSync.userId,
        selectRows: (_) async => [
          serverRow(1, 11,
              unsealedAt: nowUtc.subtract(const Duration(hours: 30))),
          serverRow(2, 22),
        ],
        callRpc: (_, __) async {
          rpcCalls++;
          return [
            serverRow(1, 11,
                unsealedAt: nowUtc.subtract(const Duration(hours: 5))),
          ];
        },
      ),
    );
    addTearDown(notifier.dispose);
    await warmUp(notifier);

    await notifier.discoverName();
    await settle();

    expect(rpcCalls, 1);
    expect(notifier.state.error, isNull, reason: 'the user still gets a reveal');
    expect(notifier.state.checkinDone, isTrue);

    // Honest about what it is: an ordinary pull, exactly what QueueHold gives.
    expect(notifier.state.revealSource, revealSourceGacha);
    expect(notifier.state.revealQueuePosition, isNull);
    expect(notifier.state.revealDeck, isNull);
    expect(notifier.state.engagedCard!.id, isNot(11),
        reason: 'the already-met D0 Name is not re-revealed as today\'s Name');

    // No Silver dignity floor, and no free tier-up on a card already owned.
    expect((await getCardCollection()).tierFor(11), 1);

    // Still refuses to hand over a Name promised for a later day.
    expect(debugLastPickExclude, contains(22));
  });

  test('a genuine advance onto an ALREADY-OWNED Name is still a queue reveal',
      () async {
    // The regression guard against discriminating on `discoveredIds`. A queued
    // Name's card can legitimately be pre-owned — a Store purchase, or a prior
    // tier-up pull — and plan §11 permits it: "the unseal still happens and
    // reads correctly". Position 2 was SEALED in the pre-call view, so the
    // server did advance, and owning the card changes nothing about that.
    await engageCard(deckedNameId); // pre-owned at Bronze
    expect((await getCardCollection()).tierFor(deckedNameId), 1);

    final notifier = DailyLoopNotifier(
      storiesService: stories,
      nameQueueService: NameQueueService(
        currentUserId: () => fakeSync.userId,
        selectRows: (_) async => [
          serverRow(1, 11,
              unsealedAt: nowUtc.subtract(const Duration(hours: 30))),
          serverRow(2, deckedNameId),
        ],
        callRpc: (_, __) async =>
            [serverRow(2, deckedNameId, unsealedAt: nowUtc)],
      ),
    );
    addTearDown(notifier.dispose);
    await warmUp(notifier);

    await notifier.discoverName();
    await settle();

    expect(notifier.state.error, isNull);
    expect(notifier.state.engagedCard!.id, deckedNameId);
    expect(notifier.state.revealSource, revealSourceQueue);
    expect(notifier.state.revealQueuePosition, 2);
    expect(notifier.state.revealDeck?.deckId, deckedDeckId,
        reason: 'the promised Name still arrives with its authored deck');
    // Engaged as a re-encounter tier-up, not as a first discovery.
    expect((await getCardCollection()).tierFor(deckedNameId), 2);
    expect(notifier.state.cardEngageResult, isNotNull);
  });

  test('a genuinely new row is a queue reveal', () async {
    await engageCard(11);

    final notifier = DailyLoopNotifier(
      storiesService: stories,
      nameQueueService: NameQueueService(
        currentUserId: () => fakeSync.userId,
        selectRows: (_) async => [
          serverRow(1, 11,
              unsealedAt: nowUtc.subtract(const Duration(hours: 30))),
          serverRow(2, 22),
        ],
        callRpc: (_, __) async => [serverRow(2, 22, unsealedAt: nowUtc)],
      ),
    );
    addTearDown(notifier.dispose);
    await warmUp(notifier);

    await notifier.discoverName();
    await settle();

    expect(notifier.state.engagedCard!.id, 22);
    expect(notifier.state.revealSource, revealSourceQueue);
    expect(notifier.state.revealQueuePosition, 2);
    expect((await getCardCollection()).tierFor(22), 2,
        reason: 'the Silver dignity floor still applies to a real unseal');
  });

  test('QueueResume is untouched: an unmet row unsealed earlier still resumes',
      () async {
    // The row was unsealed an hour ago and its Name was never met — the user
    // closed the app between the RPC and the card landing. The guard lives in
    // the QueueUnseal branch only, so this path must be unchanged.
    var rpcCalls = 0;
    final notifier = DailyLoopNotifier(
      storiesService: stories,
      nameQueueService: NameQueueService(
        currentUserId: () => fakeSync.userId,
        selectRows: (_) async => [
          serverRow(1, 11,
              unsealedAt: nowUtc.subtract(const Duration(hours: 1))),
          serverRow(2, 22),
        ],
        callRpc: (_, __) async {
          rpcCalls++;
          return null;
        },
      ),
    );
    addTearDown(notifier.dispose);
    await warmUp(notifier);

    await notifier.discoverName();
    await settle();

    expect(rpcCalls, 0, reason: 'a resume never calls the RPC');
    expect(notifier.state.engagedCard!.id, 11);
    expect(notifier.state.revealSource, revealSourceQueue);
    expect(notifier.state.revealQueuePosition, 1);
  });
}

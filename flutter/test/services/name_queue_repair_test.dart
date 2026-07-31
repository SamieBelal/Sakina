// A queue seed that fails during onboarding must not fail forever.
//
// `completeOnboarding` catches the seed failure on purpose — an escape there
// would skip `markOnboardingCompleted`/`markOnboarded` and strand the user
// mid-completion. But the catch ended at an analytics event, and completion
// then deletes the local onboarding state, so a single dropped connection on a
// day-0 cellular handoff left the user PERMANENTLY without a queue:
// `completeOnboarding` never runs again, nothing else seeds, and
// `planQueueReveal` returns QueueAbsent forever.
//
// The user-visible cost: the plan screen showed seven Names and said the second
// arrives tomorrow. It never does, and nothing tells them or us.

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/name_queue_repair.dart';
import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

class _FakeQueue implements NameQueueService {
  _FakeQueue({this.error, this.alreadySeeded = false});

  final Object? error;
  final bool alreadySeeded;
  final List<List<int>> seedCalls = [];

  @override
  Future<bool> seedIfEmpty(List<int> nameIds) async {
    seedCalls.add(nameIds);
    if (error != null) throw error!;
    return !alreadySeeded;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    onAnalyticsEvent = null;
  });

  tearDown(() {
    onAnalyticsEvent = null;
    SupabaseSyncService.debugReset();
  });

  test('nothing pending is a no-op', () async {
    final queue = _FakeQueue();
    expect(await retryPendingQueueSeed(service: queue), isFalse);
    expect(queue.seedCalls, isEmpty,
        reason: 'this runs on every app open — it must cost one prefs read '
            'when there is nothing to do');
  });

  test('a recorded seed is replayed and then cleared', () async {
    await recordPendingQueueSeed([11, 22, 33]);
    final queue = _FakeQueue();

    expect(await retryPendingQueueSeed(service: queue), isTrue);
    expect(queue.seedCalls.single, [11, 22, 33]);
    expect(await pendingQueueSeedIds(), isNull,
        reason: 'a landed seed must not be replayed on every future launch');
  });

  test('a still-failing retry keeps the record for next launch', () async {
    await recordPendingQueueSeed([11, 22]);
    final queue = _FakeQueue(error: StateError('still offline'));

    expect(await retryPendingQueueSeed(service: queue), isFalse);
    expect(
      await pendingQueueSeedIds(),
      [11, 22],
      reason: 'giving up costs the user their whole D1 promise; retrying costs '
          'one SELECT per launch. There is no attempt counter for that reason',
    );
  });

  test('rows that already exist count as success', () async {
    // `seedIfEmpty` returns false when the queue is already populated — an
    // earlier attempt landed and only its RESPONSE was lost. Treating that as
    // failure would retry forever against a queue that is already correct.
    await recordPendingQueueSeed([11, 22]);
    final queue = _FakeQueue(alreadySeeded: true);

    expect(await retryPendingQueueSeed(service: queue), isTrue);
    expect(await pendingQueueSeedIds(), isNull);
  });

  test('the repair event distinguishes a fix from a false alarm', () async {
    final events = <({String name, Map<String, dynamic> props})>[];
    onAnalyticsEvent = (name, props) => events.add((name: name, props: props));

    await recordPendingQueueSeed([11, 22]);
    await retryPendingQueueSeed(service: _FakeQueue(alreadySeeded: true));

    expect(events.single.name, 'name_queue_seed_repaired');
    expect(
      events.single.props['seeded'],
      isFalse,
      reason: 'if this is overwhelmingly false then the seed is landing and '
          'the FAILURE reporting is what is wrong — a different bug, and one '
          'the event has to be able to tell us about',
    );
  });

  test('the record is scoped to the account that made the promise', () async {
    await recordPendingQueueSeed([11, 22]);

    fakeSync.userId = 'user-2';
    expect(await pendingQueueSeedIds(), isNull,
        reason: 'seeding one account\'s Names into another\'s queue would '
            'hand them a plan screen they never saw');

    fakeSync.userId = 'user-1';
    expect(await pendingQueueSeedIds(), [11, 22]);
  });

  test('a corrupt record is dropped rather than seeded wrong', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '$pendingQueueSeedPrefBaseKey:user-1',
      ['11', 'not-an-id'],
    );

    final queue = _FakeQueue();
    expect(await retryPendingQueueSeed(service: queue), isFalse);
    expect(queue.seedCalls, isEmpty,
        reason: 'a partial id list would seed a queue of the WRONG Names, and '
            'the plan screen the user saw would then be wrong in a way '
            'nothing could ever detect');
  });

  test('signed out, there is nothing to record and nothing to read', () async {
    fakeSync.userId = null;
    await recordPendingQueueSeed([11, 22]);
    expect(await pendingQueueSeedIds(), isNull);
  });
}

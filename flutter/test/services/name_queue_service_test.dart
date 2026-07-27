import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/name_queue_service.dart';

/// One Ship W2-C2b — the `user_name_queue` client.
///
/// The behaviour under test is the review-5 contract: pre-check with the RLS
/// select, and never swallow a raise. `seed_name_queue` uses one errcode
/// (`check_violation`) for "already seeded", "wrong length" AND "duplicate
/// ids", so a service that caught its own errors would report success for a
/// wholesale failure and leave the user with a queue W3 can never unseal.
///
/// The RPC bodies themselves are covered by
/// `supabase/tests/one_ship_w1_data_layer_test.sql`.
void main() {
  /// Records every call so ordering and arguments can be asserted.
  late List<String> calls;
  late List<Map<String, dynamic>> rows;

  setUp(() {
    calls = [];
    rows = [];
  });

  NameQueueService build({
    Object? rpcError,
    Object? selectError,
    dynamic rpcResult,
    String? userId = 'user-1',
  }) {
    return NameQueueService(
      currentUserId: () => userId,
      selectRows: (uid) async {
        calls.add('select:$uid');
        if (selectError != null) throw selectError;
        return rows;
      },
      callRpc: (fn, params) async {
        calls.add('rpc:$fn:${params?['p_name_ids'] ?? ''}');
        if (rpcError != null) throw rpcError;
        return rpcResult;
      },
    );
  }

  group('seedIfEmpty', () {
    test('an empty queue is seeded through seed_name_queue with the 7 ids',
        () async {
      final service = build();

      final seeded = await service.seedIfEmpty([6, 35, 37, 64, 82, 17, 3]);

      expect(seeded, isTrue);
      expect(calls, [
        'select:user-1', // pre-check FIRST — never rpc-then-interpret
        'rpc:${NameQueueService.seedRpcName}:[6, 35, 37, 64, 82, 17, 3]',
      ]);
    });

    test('existing rows are a no-op success — the RPC is never called',
        () async {
      rows = [
        {'position': 1, 'name_id': 6, 'unsealed_at': '2026-07-26T10:00:00Z'},
      ];
      final service = build();

      expect(await service.seedIfEmpty([6, 35]), isFalse);
      expect(calls, ['select:user-1']);
    });

    test('a raise from the RPC is surfaced, never swallowed', () async {
      final service = build(rpcError: StateError('duplicate name ids'));

      await expectLater(
        service.seedIfEmpty([6, 6]),
        throwsA(isA<StateError>()),
      );
    });

    test('a raise from the pre-check select is surfaced too', () async {
      // A failed SELECT must not be read as "empty queue" — that would seed a
      // second time and raise inside the RPC for the wrong reason.
      final service = build(selectError: StateError('rls denied'));

      await expectLater(
        service.seedIfEmpty([6, 35]),
        throwsA(isA<StateError>()),
      );
      expect(calls.where((c) => c.startsWith('rpc:')), isEmpty);
    });

    test('an unauthenticated call throws instead of silently doing nothing',
        () async {
      final service = build(userId: null);

      await expectLater(
        service.seedIfEmpty([6, 35]),
        throwsA(isA<StateError>()),
      );
      expect(calls, isEmpty);
    });
  });

  group('queue', () {
    test('parses rows and orders them by position', () async {
      rows = [
        {'position': 3, 'name_id': 37, 'unsealed_at': null},
        {'position': 1, 'name_id': 6, 'unsealed_at': '2026-07-26T10:00:00Z'},
        {'position': 2, 'name_id': 35, 'unsealed_at': null},
      ];

      final queue = await build().queue();

      expect(queue.map((r) => r.position), [1, 2, 3]);
      expect(queue.map((r) => r.nameId), [6, 35, 37]);
      expect(queue.first.isSealed, isFalse);
      expect(queue.first.unsealedAt, DateTime.utc(2026, 7, 26, 10));
      expect(queue.skip(1).every((r) => r.isSealed), isTrue);
    });

    test('is empty (not a throw) when unauthenticated', () async {
      expect(await build(userId: null).queue(), isEmpty);
      expect(calls, isEmpty);
    });
  });

  group('unsealNext', () {
    test('calls unseal_next_name with no params and parses the row', () async {
      final service = build(rpcResult: [
        {'position': 2, 'name_id': 35, 'unsealed_at': '2026-07-27T06:30:00Z'},
      ]);

      final row = await service.unsealNext();

      expect(calls, ['rpc:${NameQueueService.unsealRpcName}:']);
      expect(row?.position, 2);
      expect(row?.nameId, 35);
      expect(row?.isSealed, isFalse);
    });

    test('an empty result means the queue is exhausted', () async {
      expect(await build(rpcResult: const []).unsealNext(), isNull);
      expect(await build(rpcResult: null).unsealNext(), isNull);
    });

    test('a raise is surfaced', () async {
      await expectLater(
        build(rpcError: StateError('not authenticated')).unsealNext(),
        throwsA(isA<StateError>()),
      );
    });
  });

  test('the RPC and table names match the W1 migration', () {
    expect(NameQueueService.tableName, 'user_name_queue');
    expect(NameQueueService.seedRpcName, 'seed_name_queue');
    expect(NameQueueService.unsealRpcName, 'unseal_next_name');
  });
}

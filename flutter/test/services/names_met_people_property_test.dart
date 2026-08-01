import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_data_batch_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

/// One Ship W6-E (D8) — the `names_met` people property.
///
/// Documented in the readout doc as "cards discovered", not a server-side
/// "met" definition — W3 declined to invent one and was right to. This is a
/// client-derived substitute: the count of rows `sync_all_user_data` returns
/// in `card_collection`. What matters here is that it is set exactly once per
/// hydrate, sourced ONLY from that row count (never a client guess), and that
/// a throwing hook cannot break the rest of hydration.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(() {
    UserProfileSyncHooks.onSetUserProperties = null;
    SupabaseSyncService.debugReset();
  });

  void respondWithCardCollection(List<Map<String, dynamic>>? rows) {
    fakeSync.rpcHandlers['sync_all_user_data'] = (_) async => {
          if (rows != null) 'card_collection': rows,
        };
  }

  test('sets names_met from the card_collection row count, once', () async {
    final calls = <Map<String, dynamic>>[];
    UserProfileSyncHooks.onSetUserProperties = calls.add;
    respondWithCardCollection([
      {
        'name_id': 5,
        'tier': 'silver',
        'discovered_at': '2026-04-01T00:00:00Z',
        'last_engaged_at': '2026-04-02T00:00:00Z',
      },
      {
        'name_id': 12,
        'tier': 'bronze',
        'discovered_at': '2026-04-03T00:00:00Z',
        'last_engaged_at': '2026-04-03T00:00:00Z',
      },
    ]);

    await hydrateUserDataFromBatchRpc();

    expect(calls, hasLength(1));
    expect(calls.single, {'names_met': 2});
  });

  test('an empty collection sets names_met: 0, not "no news"', () async {
    final calls = <Map<String, dynamic>>[];
    UserProfileSyncHooks.onSetUserProperties = calls.add;
    respondWithCardCollection(const []);

    await hydrateUserDataFromBatchRpc();

    expect(calls, hasLength(1));
    expect(calls.single, {'names_met': 0});
  });

  test('an absent card_collection section sets nothing — no guessed zero',
      () async {
    final calls = <Map<String, dynamic>>[];
    UserProfileSyncHooks.onSetUserProperties = calls.add;
    respondWithCardCollection(null);

    await hydrateUserDataFromBatchRpc();

    expect(calls, isEmpty,
        reason: 'a pre-W1 backend or a dropped section must not be read as '
            'zero Names met for a possibly-returning user');
  });

  test('a throwing hook does not break the rest of hydration', () async {
    UserProfileSyncHooks.onSetUserProperties = (_) => throw StateError('nope');
    respondWithCardCollection([
      {
        'name_id': 5,
        'tier': 'silver',
        'discovered_at': '2026-04-01T00:00:00Z',
        'last_engaged_at': '2026-04-02T00:00:00Z',
      },
    ]);

    // Must not throw out of hydrateUserDataFromBatchRpc.
    await hydrateUserDataFromBatchRpc();
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/name_queue_cache.dart';
import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

/// Pins the advisory scoped-prefs mirror of `user_name_queue` (W3 plan §7b).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  NameQueueRow row(int position, int nameId, [DateTime? unsealedAt]) =>
      NameQueueRow(position: position, nameId: nameId, unsealedAt: unsealedAt);

  test('round-trips rows, position-ordered, preserving unsealed_at', () async {
    await writeCachedNameQueue([
      row(3, 33),
      row(1, 11, DateTime.utc(2026, 8, 1, 15, 30)),
      row(2, 22),
    ]);

    final read = await readCachedNameQueue();
    expect(read.map((r) => r.position), [1, 2, 3]);
    expect(read.map((r) => r.nameId), [11, 22, 33]);
    expect(read[0].unsealedAt, DateTime.utc(2026, 8, 1, 15, 30));
    expect(read[0].isSealed, isFalse);
    expect(read[1].isSealed, isTrue);
    expect(read[2].isSealed, isTrue);
  });

  test('the encoded blob uses the same keys NameQueueRow.fromJson reads',
      () async {
    // Type-symmetry pin: the write side must not invent its own key names, or a
    // future reader silently decodes zeros. (Same failure class as the
    // cosmetics `_addOwnedToCache` symmetry fix.)
    await writeCachedNameQueue([row(1, 11, DateTime.utc(2026, 8, 1))]);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$nameQueuePrefBaseKey:user-1');
    final decoded = jsonDecode(raw!) as List<dynamic>;
    expect(decoded.single, {
      'position': 1,
      'name_id': 11,
      'unsealed_at': '2026-08-01T00:00:00.000Z',
    });
    expect(
      NameQueueRow.fromJson(Map<String, dynamic>.from(decoded.single as Map))
          .nameId,
      11,
    );
  });

  test('reads empty when nothing was cached', () async {
    expect(await readCachedNameQueue(), isEmpty);
    expect(await hasCachedNameQueue(), isFalse);
  });

  test('hasCachedNameQueue is the cohort probe', () async {
    expect(await hasCachedNameQueue(), isFalse);
    await writeCachedNameQueue([row(1, 11)]);
    expect(await hasCachedNameQueue(), isTrue);
    await writeCachedNameQueue(const []);
    expect(await hasCachedNameQueue(), isFalse);
  });

  test('a corrupt blob degrades to "no cached queue", never throws', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$nameQueuePrefBaseKey:user-1', '{not a list');
    expect(await readCachedNameQueue(), isEmpty);

    await prefs.setString('$nameQueuePrefBaseKey:user-1', '{"position": 1}');
    expect(await readCachedNameQueue(), isEmpty);
  });

  test('the key is user-scoped — another user never reads these rows', () async {
    await writeCachedNameQueue([row(1, 11)]);
    fakeSync.userId = 'user-2';
    expect(await readCachedNameQueue(), isEmpty);
    fakeSync.userId = 'user-1';
    expect(await readCachedNameQueue(), hasLength(1));
  });

  test('unauthenticated reads/writes are no-ops', () async {
    fakeSync.userId = null;
    await writeCachedNameQueue([row(1, 11)]);
    expect(await readCachedNameQueue(), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => k.startsWith(nameQueuePrefBaseKey)),
        isEmpty);
  });

  test('merge updates one position and leaves the rest cached', () async {
    await writeCachedNameQueue([row(1, 11, DateTime.utc(2026, 8, 1)), row(2, 22), row(3, 33)]);
    await mergeCachedNameQueueRow(row(2, 22, DateTime.utc(2026, 8, 4, 3)));

    final read = await readCachedNameQueue();
    expect(read.map((r) => r.position), [1, 2, 3]);
    expect(read[1].unsealedAt, DateTime.utc(2026, 8, 4, 3));
    expect(read[0].unsealedAt, DateTime.utc(2026, 8, 1));
    expect(read[2].isSealed, isTrue);
  });

  test('merge appends a position the mirror has never seen', () async {
    await mergeCachedNameQueueRow(row(2, 22, DateTime.utc(2026, 8, 4, 3)));
    final read = await readCachedNameQueue();
    expect(read, hasLength(1));
    expect(read.single.position, 2);
    // Cohort membership follows, so a freshly-seeded user isn't stuck legacy.
    expect(await hasCachedNameQueue(), isTrue);
  });

  test('clear drops the mirror', () async {
    await writeCachedNameQueue([row(1, 11)]);
    await clearCachedNameQueue();
    expect(await hasCachedNameQueue(), isFalse);
  });
}

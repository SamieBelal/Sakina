// D2 delete-all, across the relaunch — the half nobody tests.
//
// `delete_all_reflections_test.dart` pins the DELETE. This file pins what
// happens on the next launch, which is where the control historically lied:
// the journal emptied, the user closed the app, and the entries came back.
//
// The resurrection path is not in the delete code at all. It is in hydration:
//
//   _hydrateOrSeedListSection(rows: payload.listSection('reflections'), …)
//     rows.isEmpty  -> seed()      // push the LOCAL cache UP to the server
//     else          -> hydrate()   // overwrite the LOCAL cache with server rows
//
// After a successful delete-all the server has zero reflection rows, so every
// launch afterwards takes the `seed()` branch — forever. That branch is correct
// and load-bearing for a genuine first sync (a user who wrote entries offline,
// or before signing in, must not lose them). What makes it safe after a delete
// is a SECOND fact, in a different file: `deleteAllReflections` clears the local
// cache BEFORE it calls the server, so by the time `seed()` runs there is
// nothing local left to push.
//
// Two files, one invariant, no test spanning them. Either half can be changed
// alone without breaking anything visible, and the failure is silent, delayed by
// a relaunch, and destroys the user's stated intent. That is what this file is
// for.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_data_batch_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Mirrors the REAL `deleteRow`, which catches its own exception and returns
/// false rather than throwing.
class _FalseReturningDeleteSync extends FakeSupabaseSyncService {
  _FalseReturningDeleteSync({required super.userId});
  @override
  Future<bool> deleteRow(String table, String column, dynamic value) async =>
      false;
}

SavedReflection _reflection(String id) => SavedReflection(
      id: id,
      date: '2026-08-05T12:00:00Z',
      userText: 'sample $id',
      name: 'Al-Hadi',
      nameArabic: 'الهادي',
      reframePreview: 'preview',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const userId = 'user-relaunch';
  const cacheKey = 'saved_reflections:$userId';

  late FakeSupabaseSyncService sync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sync = FakeSupabaseSyncService(userId: userId);
    SupabaseSyncService.debugSetInstance(sync);
  });

  tearDown(SupabaseSyncService.debugReset);

  /// The next launch: the batch RPC answers with an empty reflections section,
  /// which is exactly what the server returns once every row has been deleted.
  Future<void> relaunch() async {
    sync.rpcHandlers['sync_all_user_data'] =
        (params) async => {'reflections': <Map<String, dynamic>>[]};
    await hydrateUserDataFromBatchRpc();
  }

  Future<List<dynamic>> cachedRows() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(cacheKey);
    if (raw == null) return const [];
    return jsonDecode(raw) as List<dynamic>;
  }

  group('delete all, then relaunch', () {
    test('the entries do not come back', () async {
      final notifier = ReflectNotifier(loadOnInit: false);
      addTearDown(notifier.dispose);
      notifier.debugSeedReflections([
        _reflection('a'),
        _reflection('b'),
        _reflection('c'),
      ]);

      expect(await notifier.deleteAllReflections(), isTrue);
      expect(await cachedRows(), isEmpty,
          reason: 'precondition: the delete cleared the local cache');

      await relaunch();

      expect(await cachedRows(), isEmpty);
      expect(
        sync.batchInsertCalls.where((c) => c['table'] == 'user_reflections'),
        isEmpty,
        reason: 'the empty-section branch seeds from the local cache, and the '
            'delete emptied it — so there is nothing to push back up',
      );
    });

    test('a second relaunch does not resurrect them either', () async {
      final notifier = ReflectNotifier(loadOnInit: false);
      addTearDown(notifier.dispose);
      notifier.debugSeedReflections([_reflection('a')]);
      await notifier.deleteAllReflections();

      await relaunch();
      await relaunch();

      expect(await cachedRows(), isEmpty);
      expect(
        sync.batchInsertCalls.where((c) => c['table'] == 'user_reflections'),
        isEmpty,
      );
    });

    test('a fresh notifier — the app restarting — reads an empty journal',
        () async {
      final notifier = ReflectNotifier(loadOnInit: false);
      addTearDown(notifier.dispose);
      notifier.debugSeedReflections([_reflection('a'), _reflection('b')]);
      await notifier.deleteAllReflections();
      await relaunch();

      // `loadOnInit: true` is the real cold-start path: the notifier reads the
      // cache the way it does on launch, with no seeded state.
      final relaunched = ReflectNotifier();
      addTearDown(relaunched.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(relaunched.state.savedReflections, isEmpty);
    });
  });

  group('the seed branch it depends on is still alive', () {
    // The tests above would ALSO pass if `seed()` were deleted outright, or if
    // the empty-section branch stopped running. That would be a data-loss bug
    // in the other direction — an offline-written journal never reaching the
    // server — so the same file has to hold the branch open.
    test('a journal that never synced IS pushed up on the next launch',
        () async {
      SharedPreferences.setMockInitialValues({
        cacheKey: jsonEncode([_reflection('offline').toJson()]),
      });
      sync = FakeSupabaseSyncService(userId: userId);
      SupabaseSyncService.debugSetInstance(sync);

      await relaunch();

      final seeds =
          sync.batchInsertCalls.where((c) => c['table'] == 'user_reflections');
      expect(seeds, hasLength(1),
          reason: 'an empty server section with a NON-empty local cache is a '
              'first sync, and must still seed');
      expect((seeds.single['rows'] as List), hasLength(1));
    });
  });

  group('a delete that failed leaves the journal intact across the relaunch',
      () {
    // The rollback puts the entries back locally. The server still has them
    // too, because the delete is what failed — but the batch RPC is stubbed
    // empty here to force the seed branch, which is the harsher case: it proves
    // the rollback is a real restore and not just an in-memory one.
    test('a server that returns false restores them, and they survive',
        () async {
      sync = _FalseReturningDeleteSync(userId: userId);
      SupabaseSyncService.debugSetInstance(sync);

      final notifier = ReflectNotifier(loadOnInit: false);
      addTearDown(notifier.dispose);
      notifier.debugSeedReflections([_reflection('a'), _reflection('b')]);

      expect(await notifier.deleteAllReflections(), isFalse);
      expect(notifier.state.savedReflections, hasLength(2));
      expect(notifier.state.error, isNotNull);

      await relaunch();

      expect(await cachedRows(), hasLength(2),
          reason: 'the rollback wrote them back to disk, so the relaunch finds '
              'them — a rollback that only restored state would lose both here');
      final seeds =
          sync.batchInsertCalls.where((c) => c['table'] == 'user_reflections');
      expect(seeds, hasLength(1),
          reason: 'and the surviving journal is pushed back up, converging the '
              'server the delete never managed to change');
    });
  });

  group('one entry deleted, not all', () {
    test('the other entries survive the relaunch and the deleted one stays gone',
        () async {
      final notifier = ReflectNotifier(loadOnInit: false);
      addTearDown(notifier.dispose);
      notifier.debugSeedReflections([
        _reflection('keep-1'),
        _reflection('drop'),
        _reflection('keep-2'),
      ]);

      // Returns void — the single-delete path reports failure through
      // `state.error`, not a bool. Checked below.
      await notifier.deleteReflection('drop');
      expect(notifier.state.error, isNull);

      await relaunch();

      final ids = (await cachedRows())
          .map((r) => (r as Map<String, dynamic>)['id'])
          .toList();
      expect(ids, containsAll(['keep-1', 'keep-2']));
      expect(ids, isNot(contains('drop')));

      // And the two survivors are seeded back up, not silently dropped.
      final seeds =
          sync.batchInsertCalls.where((c) => c['table'] == 'user_reflections');
      expect((seeds.single['rows'] as List), hasLength(2));
    });
  });
}

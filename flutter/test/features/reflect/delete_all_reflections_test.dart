// D2's delete-all control — the half of a closed founder decision that did not
// ship with the storage it was made conditional on.
//
// Design §11 D2 (2026-08-02) resolved: *"store the text server-side under RLS
// **with** export / delete-one / delete-all shipped in the same release"*, and
// plan §B4 restates it as non-negotiable — *"the decision was 'store it *with*
// the controls', not 'store it'."* Verified 2026-08-06: `grep -rn "Export" lib/`
// returned zero hits and there was no delete-all anywhere. One of the three
// controls existed, and it was the one that already existed before this work.
//
// The rollback cases below are the same failure mode
// `delete_reflection_network_failure_test.dart` exists for, and they matter
// MORE here: `deleteRow` swallows its own exception and returns false, so a
// silent server failure would leave the user believing their entire journal was
// destroyed while every row survives and resurrects on the next hydrate. On a
// destroy-everything action that is the worst available outcome.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

class _ThrowingDeleteSync extends FakeSupabaseSyncService {
  _ThrowingDeleteSync({required super.userId});
  @override
  Future<bool> deleteRow(String table, String column, dynamic value) async {
    throw Exception('network unreachable');
  }
}

/// Mirrors the REAL `deleteRow`, which catches and returns false.
class _FalseReturningDeleteSync extends FakeSupabaseSyncService {
  _FalseReturningDeleteSync({required super.userId});
  @override
  Future<bool> deleteRow(String table, String column, dynamic value) async =>
      false;
}

/// Records what it was asked to delete, so the test can prove the filter.
class _RecordingDeleteSync extends FakeSupabaseSyncService {
  _RecordingDeleteSync({required super.userId});
  final calls = <({String table, String column, dynamic value})>[];
  @override
  Future<bool> deleteRow(String table, String column, dynamic value) async {
    calls.add((table: table, column: column, value: value));
    return true;
  }
}

SavedReflection _reflection(String id) => SavedReflection(
      id: id,
      date: '2026-08-0${id.length}T12:00:00Z',
      userText: 'sample $id',
      name: 'Al-Hadi',
      nameArabic: 'الهادي',
      reframePreview: 'preview',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(SupabaseSyncService.debugReset);

  test('deletes every entry, in ONE filtered call rather than N', () async {
    final sync = _RecordingDeleteSync(userId: 'user-d2');
    SupabaseSyncService.debugSetInstance(sync);

    final notifier = ReflectNotifier(loadOnInit: false);
    addTearDown(notifier.dispose);
    notifier.debugSeedReflections([
      _reflection('a'),
      _reflection('bb'),
      _reflection('ccc'),
    ]);

    final ok = await notifier.deleteAllReflections();

    expect(ok, isTrue);
    expect(notifier.state.savedReflections, isEmpty);
    expect(notifier.state.error, isNull);
    // One statement filtered on user_id — not three deletes by id. RLS scopes
    // it to the caller, which is why deleting "everything" is safe to express
    // this way.
    expect(sync.calls, hasLength(1));
    expect(sync.calls.single.table, 'user_reflections');
    expect(sync.calls.single.column, 'user_id');
    expect(sync.calls.single.value, 'user-d2');
  });

  test('a throwing server restores EVERY entry and says so', () async {
    SupabaseSyncService.debugSetInstance(_ThrowingDeleteSync(userId: 'u1'));
    final notifier = ReflectNotifier(loadOnInit: false);
    addTearDown(notifier.dispose);
    notifier.debugSeedReflections([_reflection('a'), _reflection('bb')]);

    final ok = await notifier.deleteAllReflections();

    expect(ok, isFalse);
    expect(notifier.state.savedReflections, hasLength(2),
        reason: 'a failed destroy must leave the journal intact');
    expect(notifier.state.error, isNotNull);
  });

  test('a server that returns false (never throws) also rolls back', () async {
    // The case the first version of `deleteReflection` missed entirely: the
    // real `deleteRow` catches its own exception, so try/catch alone is blind.
    SupabaseSyncService.debugSetInstance(
        _FalseReturningDeleteSync(userId: 'u2'));
    final notifier = ReflectNotifier(loadOnInit: false);
    addTearDown(notifier.dispose);
    notifier.debugSeedReflections([_reflection('a'), _reflection('bb')]);

    final ok = await notifier.deleteAllReflections();

    expect(ok, isFalse);
    expect(notifier.state.savedReflections, hasLength(2));
    expect(notifier.state.error, isNotNull);
  });

  test('an empty journal is a no-op that touches no server', () async {
    final sync = _RecordingDeleteSync(userId: 'u3');
    SupabaseSyncService.debugSetInstance(sync);
    final notifier = ReflectNotifier(loadOnInit: false);
    addTearDown(notifier.dispose);

    expect(await notifier.deleteAllReflections(), isTrue);
    expect(sync.calls, isEmpty);
  });

  test('signed out, clearing the local cache IS the whole job', () async {
    // No account: the cache is the journal, and there is nothing on a server
    // to refuse. It must still succeed rather than report a failure.
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: null));
    final notifier = ReflectNotifier(loadOnInit: false);
    addTearDown(notifier.dispose);
    notifier.debugSeedReflections([_reflection('a')]);

    expect(await notifier.deleteAllReflections(), isTrue);
    expect(notifier.state.savedReflections, isEmpty);
    expect(notifier.state.error, isNull);
  });
}

// The delete paths' LOCAL failure — the one that was silent (2026-08-06).
//
// Both delete methods already handled every server failure explicitly, and
// `delete_reflection_network_failure_test.dart` and
// `delete_all_reflections_test.dart` pin those. Neither handled the first
// `await _persistReflections(...)`, which sat outside any try/catch: a
// `SharedPreferences` throw left the list CLEARED in memory, UNCHANGED on disk,
// and no error anywhere. The user watched their journal vanish, was told
// nothing, and found all of it back at the next launch.
//
// It matters more on delete-all, and that asymmetry is the point of this file:
// one lost row is a bug, but "your entire journal is gone" told to someone whose
// entire journal is intact is the worst outcome a destroy-everything control
// has. The fix refuses BEFORE the server call, so when the message says nothing
// was destroyed, nothing was.
//
// MUTATION: drop the `_tryPersistReflections` guard back to a bare
// `await _persistReflections(...)` → every test here fails with an uncaught
// StateError instead of a rolled-back list.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

/// A store whose WRITES fail — a plugin-channel error, a full or read-only
/// disk. Reads still work, which is what makes the divergence possible in the
/// first place: the old rows are perfectly readable at the next launch.
class _WriteFailingStore extends InMemorySharedPreferencesStore {
  _WriteFailingStore() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      throw StateError('simulated shared_preferences write failure');
}

/// Records the server deletes, so a test can prove none was attempted.
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
      date: '2026-08-01T21:00:00Z',
      userText: 'sample $id',
      name: 'Al-Hadi',
      nameArabic: 'الهادي',
      reframePreview: 'preview',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingDeleteSync sync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sync = _RecordingDeleteSync(userId: 'user-cache');
    SupabaseSyncService.debugSetInstance(sync);
  });

  tearDown(SupabaseSyncService.debugReset);

  /// Installs the failing store AFTER the notifier is seeded, so the seed
  /// itself is not what fails.
  void failWrites() {
    SharedPreferencesStorePlatform.instance = _WriteFailingStore();
    SharedPreferences.resetStatic();
  }

  group('deleteReflection', () {
    test('a failed cache write rolls the entry back and says so', () async {
      final notifier = ReflectNotifier(loadOnInit: false);
      addTearDown(notifier.dispose);
      notifier.debugSeedReflections([_reflection('a'), _reflection('b')]);
      failWrites();

      await notifier.deleteReflection('a');

      expect(
        notifier.state.savedReflections.map((r) => r.id),
        ['a', 'b'],
        reason: 'the entry must come back — it was never actually deleted',
      );
      expect(notifier.state.error, isNotNull,
          reason: 'the whole bug was that this stayed null');
    });

    test('nothing is deleted server-side when the cache refused', () async {
      final notifier = ReflectNotifier(loadOnInit: false);
      addTearDown(notifier.dispose);
      notifier.debugSeedReflections([_reflection('a')]);
      failWrites();

      await notifier.deleteReflection('a');

      expect(sync.calls, isEmpty,
          reason: 'refusing before the server call is what makes the error '
              'message true — the row is still on both sides');
    });
  });

  group('deleteAllReflections', () {
    test('returns false, restores every entry, and sets the error', () async {
      final notifier = ReflectNotifier(loadOnInit: false);
      addTearDown(notifier.dispose);
      notifier.debugSeedReflections(
          [_reflection('a'), _reflection('b'), _reflection('c')]);
      failWrites();

      final ok = await notifier.deleteAllReflections();

      expect(ok, isFalse);
      expect(notifier.state.savedReflections, hasLength(3));
      expect(notifier.state.error, isNotNull);
    });

    test('the server keeps every row — the message and the world agree',
        () async {
      final notifier = ReflectNotifier(loadOnInit: false);
      addTearDown(notifier.dispose);
      notifier.debugSeedReflections([_reflection('a'), _reflection('b')]);
      failWrites();

      await notifier.deleteAllReflections();

      expect(sync.calls, isEmpty);
    });

    test(
        'the rollback itself cannot throw — the cache is what is broken, and '
        'a second refusal must not escape as an unhandled async error',
        () async {
      final notifier = ReflectNotifier(loadOnInit: false);
      addTearDown(notifier.dispose);
      notifier.debugSeedReflections([_reflection('a')]);
      failWrites();

      // The assertion is that this completes at all.
      await expectLater(notifier.deleteAllReflections(), completion(isFalse));
    });

    test(
        'an empty journal is still a no-op — it returns true without ever '
        'touching the cache', () async {
      final notifier = ReflectNotifier(loadOnInit: false);
      addTearDown(notifier.dispose);
      failWrites();

      expect(await notifier.deleteAllReflections(), isTrue);
      expect(sync.calls, isEmpty);
    });
  });
}

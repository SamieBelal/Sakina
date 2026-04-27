// Regression test: removeSavedBuiltDua must roll back local state and SP
// when the server delete throws. Pre-fix the method had no try/catch, so a
// network failure left local in a "deleted" state while the server kept the
// row, causing ghost rehydration on next sync. Pattern mirrors
// deleteReflection in reflect_provider.dart.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixedNow = DateTime.parse('2026-04-26T12:00:00Z');

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'saved_built_duas:user-rollback': jsonEncode([
        {
          'id': 'dua-1',
          'savedAt': '2026-04-26T11:00:00Z',
          'need': 'patience',
          'arabic': 'دعاء',
          'transliteration': 'dua',
          'translation': 'supplication',
        },
      ]),
    });
  });

  tearDown(SupabaseSyncService.debugReset);

  test('removeSavedBuiltDua rolls back state + SP when server delete throws',
      () async {
    final fakeSync = FakeSupabaseSyncService(userId: 'user-rollback');
    SupabaseSyncService.debugSetInstance(fakeSync);

    final notifier = DuasNotifier(
      dependencies: DuasDependencies(
        findDuas: (_) async => throw UnimplementedError(),
        buildDua: (_) async => throw UnimplementedError(),
        now: () => fixedNow,
        createId: () => 'dua-rollback',
      ),
      resultRevealDelay: Duration.zero,
    );
    addTearDown(notifier.dispose);

    // Wait for loadSavedDuas() to hydrate from SP.
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.savedBuiltDuas, hasLength(1),
        reason: 'precondition: cached dua should hydrate');

    // Arm the failure on the next deleteRow call.
    fakeSync.nextDeleteShouldThrow = true;

    await notifier.removeSavedBuiltDua('dua-1');

    // Server failure → rollback. Item must be back in state.
    expect(notifier.state.savedBuiltDuas, hasLength(1),
        reason: 'rollback should restore the deleted dua');
    expect(notifier.state.savedBuiltDuas.first.id, 'dua-1');
    expect(notifier.state.error, isNotNull,
        reason: 'rollback should set state.error for UI surfacing');
    expect(notifier.state.error, contains("Couldn't delete"));

    // SP must also reflect the rollback.
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('saved_built_duas:user-rollback');
    expect(stored, isNotNull);
    expect(stored, contains('dua-1'),
        reason: 'rollback should re-persist the dua to SP');

    // Sanity: deleteRow was actually attempted once.
    expect(fakeSync.deleteCalls, hasLength(1));
    expect(fakeSync.deleteCalls.first['table'], 'user_built_duas');
  });

  test('removeSavedBuiltDua removes locally + remotely on server success',
      () async {
    final fakeSync = FakeSupabaseSyncService(userId: 'user-rollback');
    SupabaseSyncService.debugSetInstance(fakeSync);

    final notifier = DuasNotifier(
      dependencies: DuasDependencies(
        findDuas: (_) async => throw UnimplementedError(),
        buildDua: (_) async => throw UnimplementedError(),
        now: () => fixedNow,
        createId: () => 'dua-success',
      ),
      resultRevealDelay: Duration.zero,
    );
    addTearDown(notifier.dispose);

    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.savedBuiltDuas, hasLength(1));

    await notifier.removeSavedBuiltDua('dua-1');

    expect(notifier.state.savedBuiltDuas, isEmpty);
    expect(notifier.state.error, isNull);
    expect(fakeSync.deleteCalls, hasLength(1));
  });
}

// Regression test for §9 J-E4: network failure mid-delete.
//
// `ReflectNotifier.deleteReflection` previously did:
//
//     final updated = state.savedReflections.where((r) => r.id != id).toList();
//     state = state.copyWith(savedReflections: updated);
//     await _persistReflections(updated);
//     // ↓ no try/catch — exception bubbles uncaught into the UI layer
//     await supabaseSyncService.deleteRow('user_reflections', 'id', id);
//
// On airplane mode / RLS reject / 5xx, the server delete throws, but the
// local list and SharedPreferences are already mutated. The user sees the
// row vanish from the journal even though the server still has it. On the
// next sign-in or hydrate, the row reappears: silent failure, mystifying.
//
// Fix: snapshot the previous list, wrap the server call in try/catch, and on
// failure restore + re-persist + surface an error string the UI can show as
// a snackbar.

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

SavedReflection _reflection(String id) => SavedReflection(
      id: id,
      date: '2026-04-26T12:00:00Z',
      userText: 'sample $id',
      name: 'Al-Hadi',
      nameArabic: 'الهادي',
      reframePreview: 'preview',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(SupabaseSyncService.debugReset);

  test(
      'deleteReflection reverts local list and surfaces error when server delete fails',
      () async {
    SupabaseSyncService.debugSetInstance(
      _ThrowingDeleteSync(userId: 'user-jE4'),
    );

    final keep = _reflection('keep-1');
    final doomed = _reflection('doomed-1');
    final notifier = ReflectNotifier(loadOnInit: false);
    addTearDown(notifier.dispose);

    // Seed two reflections directly into state to skip the load path.
    notifier.debugSeedReflections([keep, doomed]);
    expect(notifier.state.savedReflections, hasLength(2));

    await notifier.deleteReflection('doomed-1');

    expect(
      notifier.state.savedReflections.map((r) => r.id),
      containsAll(['keep-1', 'doomed-1']),
      reason: 'failed server delete must restore the local row',
    );
    expect(notifier.state.error, isNotNull,
        reason: 'user must see an error when delete fails');
    expect(notifier.state.error, contains('delete'));
  });

  test('deleteReflection succeeds normally when server delete works',
      () async {
    final fake = FakeSupabaseSyncService(userId: 'user-jE4-ok');
    SupabaseSyncService.debugSetInstance(fake);

    final keep = _reflection('keep-1');
    final doomed = _reflection('doomed-1');
    final notifier = ReflectNotifier(loadOnInit: false);
    addTearDown(notifier.dispose);

    notifier.debugSeedReflections([keep, doomed]);

    await notifier.deleteReflection('doomed-1');

    expect(
      notifier.state.savedReflections.map((r) => r.id),
      ['keep-1'],
      reason: 'happy path removes only the targeted row',
    );
    expect(notifier.state.error, isNull);
    expect(fake.deleteCalls, hasLength(1));
    expect(fake.deleteCalls.single['value'], 'doomed-1');
  });
}

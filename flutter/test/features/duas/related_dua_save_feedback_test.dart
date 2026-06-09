import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/duas/screens/duas_screen.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Covers the two new pieces of the save→feedback fix without pumping the whole
/// Ameen screen (which drags in infinite ripple animations): the shared id
/// contract the heart keys off, and the confirmation snackbar copy.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixedNow = DateTime.parse('2026-04-10T12:00:00Z');

  BuiltDuaResponse buildResponse() => const BuiltDuaResponse(
        arabic: 'اللهم اهدني',
        transliteration: 'Allahumma ihdini',
        translation: 'O Allah, guide me',
        breakdown: [],
        namesUsed: [],
        relatedDuas: [],
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: 'user-feedback'),
    );
    await GatingService().debugSetHadTrial(true);
  });

  tearDown(SupabaseSyncService.debugReset);

  group('SavedRelatedDua.idFor contract', () {
    test('is stable for the same title+source and differs otherwise', () {
      expect(
        SavedRelatedDua.idFor('For guidance', 'Muslim'),
        SavedRelatedDua.idFor('For guidance', 'Muslim'),
      );
      expect(
        SavedRelatedDua.idFor('For guidance', 'Muslim'),
        isNot(SavedRelatedDua.idFor('For guidance', 'Tirmidhi')),
      );
    });

    test('toggleSaveRelatedDua stores the id the heart UI keys off', () async {
      final notifier = DuasNotifier(
        loadOnInit: false,
        dependencies: DuasDependencies(
          findDuas: (_) async => throw UnimplementedError(),
          buildDua: (_) async => buildResponse(),
          now: () => fixedNow,
          createId: () => 'dua-id',
        ),
        resultRevealDelay: Duration.zero,
      );
      addTearDown(notifier.dispose);

      const entry = FindDuasDuaEntry(
        title: 'For guidance',
        arabic: 'دعاء',
        transliteration: 'dua',
        translation: 'guidance',
        source: 'Muslim',
      );
      notifier.toggleSaveRelatedDua(entry);
      await Future<void>.delayed(Duration.zero);

      // The widget computes isSaved via `s.id == SavedRelatedDua.idFor(...)`,
      // so the stored id MUST equal idFor(title, source) or the heart never
      // reflects the save. This pins that contract.
      expect(
        notifier.state.savedRelatedDuas.single.id,
        SavedRelatedDua.idFor(entry.title, entry.source),
      );

      // Toggling again removes it.
      notifier.toggleSaveRelatedDua(entry);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.savedRelatedDuas, isEmpty);
    });
  });

  group('showRelatedDuaSnack', () {
    Widget host() => MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => showRelatedDuaSnack(ctx, saved: true),
                    child: const Text('save'),
                  ),
                  ElevatedButton(
                    onPressed: () => showRelatedDuaSnack(ctx, saved: false),
                    child: const Text('remove'),
                  ),
                ],
              ),
            ),
          ),
        );

    testWidgets('shows "Saved to Journal" on save', (tester) async {
      await tester.pumpWidget(host());
      await tester.tap(find.text('save'));
      await tester.pump(); // build the snackbar
      expect(find.text('Saved to Journal'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('shows "Removed from Journal" on un-save', (tester) async {
      await tester.pumpWidget(host());
      await tester.tap(find.text('remove'));
      await tester.pump();
      expect(find.text('Removed from Journal'), findsOneWidget);
    });

    testWidgets('replaces the previous snackbar (no stacking)', (tester) async {
      await tester.pumpWidget(host());
      await tester.tap(find.text('save'));
      await tester.pump();
      await tester.tap(find.text('remove'));
      await tester.pump();
      await tester.pump(); // let the hidden one clear
      expect(find.text('Saved to Journal'), findsNothing);
      expect(find.text('Removed from Journal'), findsOneWidget);
    });
  });
}

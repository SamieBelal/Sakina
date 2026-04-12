import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/constants/discovery_quiz.dart';
import 'package:sakina/features/discovery/providers/discovery_quiz_provider.dart';
import 'package:sakina/services/public_catalog_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService());
  });

  tearDown(SupabaseSyncService.debugReset);

  test('legacy anchor_names JSON migrates to normalized discovery quiz results',
      () async {
    SharedPreferences.setMockInitialValues({
      'anchor_names': jsonEncode([
        {
          'nameKey': 'ar-rahman',
          'name': 'Ar-Rahman',
          'arabic': 'الرَّحْمَنُ',
          'score': 8,
          'anchor': 'You lean on Allah’s mercy first.',
          'detail': 'Mercy is your way back to steadiness.',
        },
      ]),
    });

    final results = await loadSavedDiscoveryQuizResults();
    final prefs = await SharedPreferences.getInstance();

    expect(results, hasLength(1));
    expect(results.single.name, 'Ar-Rahman');
    expect(prefs.getString('anchor_names'), isNull);
    expect(prefs.getKeys(), contains('sakina_discovery_quiz_results_v1'));
  });

  test('legacy anchor_names string list migrates using anchor catalog lookup',
      () async {
    SharedPreferences.setMockInitialValues({
      'anchor_names': ['Ar-Rahman', 'Al-Wadud'],
    });

    final names = await loadSavedDiscoveryQuizAnchorNames();
    final results = await loadSavedDiscoveryQuizResults();

    expect(names, ['Ar-Rahman', 'Al-Wadud']);
    expect(results, hasLength(2));
    expect(results.first.nameKey, 'ar-rahman');
  });

  test('discovery quiz provider re-emits when catalog refresh succeeds',
      () async {
    final fakeSync = FakeSupabaseSyncService();
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugResetPublicCatalogs();
    await bootstrapPublicCatalogs();
    addTearDown(() {
      debugResetPublicCatalogs();
      SupabaseSyncService.debugReset();
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final emittedStates = <DiscoveryQuizState>[];
    final subscription = container.listen<DiscoveryQuizState>(
      discoveryQuizProvider,
      (_, next) => emittedStates.add(next),
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await Future<void>.delayed(Duration.zero);

    fakeSync.publicRows['discovery_quiz_questions'] =
        discoveryQuizQuestions.asMap().entries.map((entry) {
      final question = entry.value;
      return {
        'id': question.id,
        'prompt': entry.key == 0
            ? 'Updated quiz question from Supabase'
            : question.prompt,
        'sort_order': entry.key,
        'options': question.options
            .map((option) => {
                  'text': option.text,
                  'scores': option.scores,
                })
            .toList(),
      };
    }).toList();
    fakeSync.publicRows['name_anchors'] = nameAnchors.entries
        .map((entry) => {
              'name_key': entry.key,
              'name': entry.value.name,
              'arabic': entry.value.arabic,
              'anchor': entry.value.anchor,
              'detail': entry.value.detail,
            })
        .toList();

    await refreshPublicCatalogsFromSupabase(skipClientCheck: true);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(discoveryQuizProvider.notifier).questions.first.prompt,
      'Updated quiz question from Supabase',
    );
    expect(emittedStates.length, greaterThan(1));
  });
}

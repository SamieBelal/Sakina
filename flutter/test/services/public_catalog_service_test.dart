import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/constants/daily_questions.dart';
import 'package:sakina/core/constants/discovery_quiz.dart';
import 'package:sakina/core/constants/duas.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/public_catalog_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService();
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugResetPublicCatalogs();
  });

  tearDown(() {
    debugResetPublicCatalogs();
    SupabaseSyncService.debugReset();
  });

  test(
      'bootstrap seeds bundled snapshots into cache and exposes contract counts',
      () async {
    await bootstrapPublicCatalogs();

    expect(getPublicCatalogJson(PublicCatalogKeys.dailyQuestions), isNotNull);
    expect(getPublicCatalogJson(PublicCatalogKeys.browseDuas), isNotNull);
    expect(getPublicCatalogJson(PublicCatalogKeys.discoveryQuizQuestions),
        isNotNull);
    expect(getPublicCatalogJson(PublicCatalogKeys.nameAnchors), isNotNull);
    expect(getPublicCatalogJson(PublicCatalogKeys.collectibleNames), isNotNull);

    expect(dailyQuestionsCatalog.length, 30);
    expect(browseDuasCatalog.length, 76);
    expect(discoveryQuizQuestionsCatalog.length, 6);
    expect(nameAnchorsCatalog.length, 32);
    expect(currentCollectibleNames().length, 99);
  });

  test('refresh success overwrites cached catalog data', () async {
    await bootstrapPublicCatalogs();
    final initialRevision = debugPublicCatalogRevision();

    fakeSync.publicRows['daily_questions'] = dailyQuestions
        .map((question) => {
              'id': question.id,
              'question': question.id == 0
                  ? 'Updated from Supabase'
                  : question.question,
              'options': question.options,
            })
        .toList();

    await refreshPublicCatalogsFromSupabase(skipClientCheck: true);

    expect(dailyQuestionsCatalog, hasLength(30));
    expect(dailyQuestionsCatalog.first.question, 'Updated from Supabase');
    expect(debugPublicCatalogRevision(), greaterThan(initialRevision));
  });

  test('refresh keeps snapshot cache when remote data is empty', () async {
    await bootstrapPublicCatalogs();
    final original = getPublicCatalogJson(PublicCatalogKeys.browseDuas);

    await refreshPublicCatalogsFromSupabase(skipClientCheck: true);

    expect(getPublicCatalogJson(PublicCatalogKeys.browseDuas), original);
    expect(browseDuasCatalog.length, 76);
  });

  test('refresh rejects partial remote catalogs and keeps snapshot cache',
      () async {
    await bootstrapPublicCatalogs();
    final original = getPublicCatalogJson(PublicCatalogKeys.collectibleNames);
    final initialRevision = debugPublicCatalogRevision();

    fakeSync.publicRows['collectible_names'] = [
      {
        'id': 1,
        'arabic': 'اختبار',
        'transliteration': 'Broken Partial Data',
        'english': 'Broken',
        'meaning': 'Broken',
        'lesson': 'Broken',
        'hadith': '',
        'dua_arabic': '',
        'dua_transliteration': '',
        'dua_translation': '',
      },
    ];

    await refreshPublicCatalogsFromSupabase(skipClientCheck: true);

    expect(
      getPublicCatalogJson(PublicCatalogKeys.collectibleNames),
      original,
    );
    expect(currentCollectibleNames().length, 99);
    expect(debugPublicCatalogRevision(), initialRevision);
  });

  test('refresh rejects collectible catalogs with remapped ids', () async {
    await bootstrapPublicCatalogs();
    final original = getPublicCatalogJson(PublicCatalogKeys.collectibleNames);
    final initialRevision = debugPublicCatalogRevision();

    fakeSync.publicRows['collectible_names'] = currentCollectibleNames()
        .map((card) => {
              'id': card.id + 1,
              'arabic': card.arabic,
              'transliteration': card.transliteration,
              'english': card.english,
              'meaning': card.meaning,
              'lesson': card.lesson,
              'hadith': card.hadith,
              'dua_arabic': card.duaArabic,
              'dua_transliteration': card.duaTransliteration,
              'dua_translation': card.duaTranslation,
            })
        .toList();

    await refreshPublicCatalogsFromSupabase(skipClientCheck: true);

    expect(
      getPublicCatalogJson(PublicCatalogKeys.collectibleNames),
      original,
    );
    expect(currentCollectibleNames().first.id, 1);
    expect(debugPublicCatalogRevision(), initialRevision);
  });

  test('missing bundled snapshot returns null instead of blank cache',
      () async {
    final json = await supabaseSyncService.ensurePublicCatalogCache(
      cacheKey: 'missing-catalog',
      assetPath: 'assets/content/does_not_exist.json',
    );

    final prefs = await SharedPreferences.getInstance();
    expect(json, isNull);
    expect(prefs.containsKey('missing-catalog'), isFalse);
  });

  test('test helper can override collectible catalog JSON', () async {
    await setPublicCatalogJsonForTesting(
      PublicCatalogKeys.collectibleNames,
      jsonEncode([
        {
          'id': 1,
          'arabic': 'اختبار',
          'transliteration': 'Test Name',
          'english': 'Test',
          'meaning': 'Meaning',
          'lesson': 'Lesson',
          'hadith': 'Hadith',
          'dua_arabic': 'دعاء',
          'dua_transliteration': 'dua',
          'dua_translation': 'supplication',
        },
      ]),
    );

    expect(currentCollectibleNames().single.transliteration, 'Test Name');
  });
}

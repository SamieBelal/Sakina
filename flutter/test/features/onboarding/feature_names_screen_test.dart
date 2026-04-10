import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/collection/widgets/gold_ornate_card.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/public_catalog_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    debugResetPublicCatalogs();
  });

  tearDown(debugResetPublicCatalogs);

  testWidgets('pre-auth name preview card reads collectible names catalog',
      (tester) async {
    await setPublicCatalogJsonForTesting(
      PublicCatalogKeys.collectibleNames,
      jsonEncode([
        {
          'id': 1,
          'arabic': 'ٱخْتِبَار',
          'transliteration': 'Preview Test Name',
          'english': 'Preview',
          'meaning': 'Meaning',
          'lesson': 'Lesson',
          'hadith': 'Hadith',
          'dua_arabic': 'دعاء',
          'dua_transliteration': 'dua',
          'dua_translation': 'supplication',
        },
      ]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoldOrnateTile(
            card: getCollectiblePreviewCard(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Preview Test Name'), findsOneWidget);
  });
}

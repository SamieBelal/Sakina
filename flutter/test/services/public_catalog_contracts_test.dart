import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/public_catalog_contracts.dart';

void main() {
  test('checked-in public catalog assets satisfy the shared contracts',
      () async {
    for (final definition in publicCatalogContracts) {
      final file = File(definition.assetPath);
      expect(
        await file.exists(),
        isTrue,
        reason: 'Missing ${definition.assetPath}',
      );

      final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
      final rows =
          decoded.map((row) => Map<String, dynamic>.from(row as Map)).toList();

      expect(
        () => validatePublicCatalogRows(definition, rows),
        returnsNormally,
        reason: 'Contract drift detected for ${definition.table}',
      );
    }
  });
}

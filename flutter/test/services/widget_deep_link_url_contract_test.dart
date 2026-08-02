import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('daily widget URLs carry a valued native-delivery source marker', () {
    const affectedSources = <String>[
      'ios/SakinaWidget/SakinaWidget.swift',
      'ios/SakinaWidget/SakinaCompanionWidget.swift',
    ];

    for (final path in affectedSources) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('?homeWidget&source=home_widget'),
        reason: '$path must not use a lone valueless ?homeWidget query. That '
            'form opens the app without reliably delivering the daily route; '
            'a valued source parameter survives the native handoff.',
      );
    }
  });
}

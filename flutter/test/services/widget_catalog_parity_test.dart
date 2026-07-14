import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/allah_names.dart';

/// Pins the invariant that the committed widget catalog is index-aligned with
/// `allahNames`, so the widget's offline daily fallback
/// (`catalog[dayOfYear % count]`) always shows the SAME Name as the app's
/// `getTodaysName()` (`allahNames[dayOfYear % length]`). Spec §10.1.
///
/// If this fails, run: dart run scripts/gen_widget_catalog.dart
void main() {
  final file = File('ios/SakinaWidget/catalog.json');

  test('catalog exists and is index-aligned with allahNames', () {
    expect(file.existsSync(), isTrue,
        reason: 'run scripts/gen_widget_catalog.dart');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final names = (json['names'] as List).cast<Map<String, dynamic>>();

    expect(names.length, allahNames.length,
        reason: 'catalog count must equal allahNames for identical modulus');
    expect(json['count'], allahNames.length);

    for (var i = 0; i < allahNames.length; i++) {
      expect(names[i]['index'], i);
      expect(names[i]['transliteration'], allahNames[i].transliteration,
          reason: 'row $i must be the same Name as allahNames[$i]');
      expect(names[i]['arabic'], allahNames[i].arabic);
      expect((names[i]['anchor'] as String).trim(), isNotEmpty,
          reason: 'every Name needs an anchor line');
    }
  });

  test('daily-index math agrees for a full year of days', () {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final names = (json['names'] as List).cast<Map<String, dynamic>>();
    for (var day = 0; day < 366; day++) {
      final widgetName = names[day % names.length]['transliteration'];
      final appName = allahNames[day % allahNames.length].transliteration;
      expect(widgetName, appName, reason: 'divergence on day-of-year $day');
    }
  });
}

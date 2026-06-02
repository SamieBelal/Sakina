import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pins the analytics-constants leaf split: AnalyticsEvents lives in a
/// dependency-free file so the pure service layer can reference it without
/// transitively importing Riverpod (which analytics_events.dart pulls in for
/// its AnalyticsService extension). Source-level invariants so a regression
/// (re-coupling a service to the Riverpod-laden file) fails CI.
void main() {
  test('analytics_event_names.dart is an import-free leaf', () {
    final src =
        File('lib/services/analytics_event_names.dart').readAsStringSync();
    expect(
      RegExp(r'^import ', multiLine: true).hasMatch(src),
      isFalse,
      reason: 'the constants leaf must stay import-free so pure services can '
          'reference AnalyticsEvents without pulling in Riverpod',
    );
    expect(src.contains('abstract final class AnalyticsEvents'), isTrue);
  });

  test('analytics_events.dart re-exports the leaf (widget importers unaffected)',
      () {
    final src = File('lib/services/analytics_events.dart').readAsStringSync();
    expect(src.contains("export 'analytics_event_names.dart'"), isTrue,
        reason: 'the ~30 widget/provider files importing analytics_events.dart '
            'must keep getting AnalyticsEvents via re-export');
  });

  test('pure services import the leaf and stay Riverpod-free', () {
    for (final path in const [
      'lib/services/card_collection_service.dart',
      'lib/services/streak_service.dart',
      'lib/services/gating_service.dart',
    ]) {
      final src = File(path).readAsStringSync();
      expect(src.contains('analytics_event_names.dart'), isTrue,
          reason: '$path should import the leaf');
      expect(src.contains('services/analytics_events.dart'), isFalse,
          reason: '$path should NOT import the Riverpod-coupled '
              'analytics_events.dart');
      expect(src.contains('flutter_riverpod'), isFalse,
          reason: '$path must stay Riverpod-free');
    }
  });
}

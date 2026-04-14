import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/analytics_service.dart';

void main() {
  group('AnalyticsService with empty token', () {
    late AnalyticsService service;

    setUp(() async {
      service = AnalyticsService();
      await service.initialize('');
    });

    test('track does not throw', () {
      expect(() => service.track('test_event'), returnsNormally);
    });

    test('identify does not throw', () {
      expect(() => service.identify('user123'), returnsNormally);
    });

    test('reset does not throw', () {
      expect(() => service.reset(), returnsNormally);
    });

    test('setSuperProperties does not throw', () {
      expect(() => service.setSuperProperties({'key': 'value'}), returnsNormally);
    });

    test('setUserProperties does not throw', () {
      expect(() => service.setUserProperties({'key': 'value'}), returnsNormally);
    });

    test('flush does not throw', () {
      expect(() => service.flush(), returnsNormally);
    });

    test('timeEvent does not throw', () {
      expect(() => service.timeEvent('test_event'), returnsNormally);
    });
  });
}

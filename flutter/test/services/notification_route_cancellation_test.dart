import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/notification_service.dart';

void main() {
  test('cancellation_feedback push type routes to the deep-link screen', () {
    expect(
      NotificationService.routeForNotificationType('cancellation_feedback'),
      '/cancellation-feedback',
    );
  });

  test('unknown / null types still fall back to home', () {
    expect(NotificationService.routeForNotificationType(null), '/');
    expect(NotificationService.routeForNotificationType('something_else'), '/');
  });
}

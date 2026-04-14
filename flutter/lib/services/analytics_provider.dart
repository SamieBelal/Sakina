import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_service.dart';

final analyticsProvider = Provider<AnalyticsService>((ref) {
  throw UnimplementedError('analyticsProvider must be overridden in ProviderScope');
});

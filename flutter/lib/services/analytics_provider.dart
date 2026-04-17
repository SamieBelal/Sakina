import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_service.dart';

/// Default is a no-op [AnalyticsService] (Mixpanel is never initialized, so
/// every method short-circuits). `main.dart` overrides this with a real
/// instance; tests get a safe no-op for free without needing explicit
/// overrides. If you need to assert on analytics calls in a test, override
/// this provider with a spy.
final analyticsProvider = Provider<AnalyticsService>((ref) => AnalyticsService());

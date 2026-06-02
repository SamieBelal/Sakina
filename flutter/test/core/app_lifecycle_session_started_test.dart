import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_lifecycle_observer.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';

/// Pins the `session_started` warm-start gate (PR #33). The gate uses a
/// monotonic Stopwatch (not wall-clock) and a `warmStartThreshold` seam so the
/// `>= threshold` branch is exercisable without a real multi-second sleep.
class _RecordingAnalytics extends AnalyticsService {
  final List<String> events = [];
  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    events.add(event);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingAnalytics analytics;
  final binding = WidgetsBinding.instance;

  setUp(() => analytics = _RecordingAnalytics());

  tearDown(() {
    // Reset the static seam so a per-test override can't leak.
    AppLifecycleObserver.warmStartThreshold = const Duration(seconds: 3);
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsProvider.overrideWithValue(analytics),
            premiumStateProvider.overrideWith(
                (ref) async => (isPremium: false, billingIssueAt: null)),
          ],
          child: const AppLifecycleObserver(child: SizedBox()),
        ),
      );

  int sessionStarted() => analytics.events
      .where((e) => e == AnalyticsEvents.sessionStarted)
      .length;

  testWidgets('cold-start resume (no prior background) fires nothing',
      (tester) async {
    await pump(tester);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(sessionStarted(), 0);
  });

  testWidgets('transient inactive blip (Control Center) does not arm the gate',
      (tester) async {
    await pump(tester);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(sessionStarted(), 0);
  });

  testWidgets('a sub-threshold background (quick app-switch) fires nothing',
      (tester) async {
    // Default 3s threshold; the test's paused→resumed elapses microseconds.
    await pump(tester);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(sessionStarted(), 0,
        reason: 'a background shorter than the threshold is a quick switch');
  });

  testWidgets(
      'a genuine background (>= threshold) fires exactly one session_started, '
      'and a later transient resume does not re-fire', (tester) async {
    AppLifecycleObserver.warmStartThreshold = Duration.zero; // any real bg exceeds it
    await pump(tester);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(sessionStarted(), 1);

    // Resume again WITHOUT a real background in between — marker was reset.
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(sessionStarted(), 1, reason: 'stopwatch stopped+reset after firing');
  });
}

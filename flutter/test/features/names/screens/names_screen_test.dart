// W6 Wave D — pins `names_browse_viewed`. See
// `lib/features/names/screens/names_screen.dart` and the constant's
// docstring in `analytics_event_names.dart`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/names/screens/names_screen.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';

class _TrackingSpy extends AnalyticsService {
  final List<(String, Map<String, dynamic>?)> tracked = [];
  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event, properties));
  }
}

void main() {
  // The dedup latch is process-global by design (see the widget's
  // docstring) — reset it between tests so each test gets a clean session.
  setUp(NamesScreen.debugResetSession);

  testWidgets('mounting NamesScreen fires names_browse_viewed once',
      (tester) async {
    final spy = _TrackingSpy();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsProvider.overrideWithValue(spy)],
        child: const MaterialApp(home: NamesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final events = spy.tracked
        .where((e) => e.$1 == AnalyticsEvents.namesBrowseViewed)
        .toList();
    expect(events, hasLength(1));
  });

  testWidgets(
      'unmounting and remounting within the same app session '
      '(a tab switcher) does NOT re-fire the event — '
      'MUTATION: making the dedup latch an instance field instead of static '
      'would make this fail',
      (tester) async {
    final spy = _TrackingSpy();

    // First mount.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsProvider.overrideWithValue(spy)],
        child: const MaterialApp(home: NamesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Simulate a tab switch away and back: swap in a different screen, then
    // pump a brand-new NamesScreen instance (a fresh State object, exactly
    // what a non-IndexedStack tab switcher produces).
    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsProvider.overrideWithValue(spy)],
        child: const MaterialApp(home: Scaffold(body: SizedBox())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsProvider.overrideWithValue(spy)],
        child: const MaterialApp(home: NamesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final events = spy.tracked
        .where((e) => e.$1 == AnalyticsEvents.namesBrowseViewed)
        .toList();
    expect(events, hasLength(1),
        reason: 'the session-level latch must survive remount');
  });
}

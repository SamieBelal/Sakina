import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/dua_times/models/dua_window.dart';
import 'package:sakina/features/dua_times/models/dua_window_schedule.dart';
import 'package:sakina/features/dua_times/models/dua_window_type.dart';
import 'package:sakina/features/dua_times/providers/dua_window_provider.dart';
import 'package:sakina/features/dua_times/widgets/dua_times_card.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/dua_window_engine.dart';
import 'package:sakina/services/dua_window_repository.dart';
import 'package:sakina/services/location_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/widget_data_service.dart';

/// Spy analytics service capturing tracked events.
class _SpyAnalytics extends AnalyticsService {
  final events = <String>[];
  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    events.add(event);
  }
}

/// Records the last schedule JSON pushed to the widget.
class _FakeWidgetClient implements HomeWidgetClient {
  String? lastKey;
  String? lastValue;
  @override
  Future<void> setAppGroupId(String id) async {}
  @override
  Future<void> saveWidgetData(String key, String? value) async {
    lastKey = key;
    lastValue = value;
  }
  @override
  Future<void> updateWidget({required String name}) async {}
}

DateTime _fixedClock() => DateTime.utc(2027, 5, 15, 23, 0);

/// A schedule with an ACTIVE comfortable window (>1h remaining).
DuaWindowSchedule _activeSchedule() {
  final active = DuaWindow(
    type: DuaWindowType.lastThirdOfNight,
    tier: DuaWindowTier.hero,
    titleKey: 'dua_window.last_third.title',
    sourceRef: 'al-Bukhari 1145',
    startUtc: DateTime.utc(2027, 5, 15, 22, 0),
    endUtc: DateTime.utc(2027, 5, 16, 2, 0),
    isAllDay: false,
    locationDependent: true,
  );
  return DuaWindowSchedule(
    active: active,
    next: null,
    upcoming: const [],
    urgency: UrgencyState.comfortable,
    computedAt: DuaScheduleStamp(
      tz: 'Asia/Riyadh',
      lat: 21.4,
      lon: 39.8,
      computedThroughUtc: DateTime.utc(2027, 5, 22, 21, 0),
    ),
  );
}

/// A BETWEEN schedule (no active window; an upcoming ʿArafah tomorrow).
DuaWindowSchedule _betweenSchedule() {
  final next = DuaWindow(
    type: DuaWindowType.arafah,
    tier: DuaWindowTier.hero,
    titleKey: 'dua_window.arafah',
    sourceRef: 'Tirmidhi 3585',
    startUtc: DateTime.utc(2027, 5, 16, 21, 0),
    endUtc: DateTime.utc(2027, 5, 17, 21, 0),
    isAllDay: true,
    locationDependent: false,
  );
  return DuaWindowSchedule(
    active: null,
    next: next,
    upcoming: [next],
    urgency: UrgencyState.upcoming,
    computedAt: DuaScheduleStamp(
      tz: 'Asia/Riyadh',
      lat: 21.4,
      lon: 39.8,
      computedThroughUtc: DateTime.utc(2027, 5, 22, 21, 0),
    ),
  );
}

DuaWindowSchedule _emptySchedule() => DuaWindowSchedule(
      active: null,
      next: null,
      upcoming: const [],
      urgency: UrgencyState.upcoming,
      computedAt: DuaScheduleStamp(
        tz: 'local',
        computedThroughUtc: DateTime.utc(2027, 5, 22, 21, 0),
      ),
    );

/// Build a notifier that does NOT auto-build (no async engine), seeded with the
/// given schedule.
DuaWindowNotifier _seededNotifier(
  DuaWindowSchedule? schedule, {
  WidgetDataService? widgetData,
}) {
  final repo = DuaWindowRepository(
    prefs: SharedPreferences.getInstance,
    loadAsset: (_) async => '{"rows":[]}',
  );
  final location = LocationService(
    checkPermission: () async => LocationPermission.denied,
    requestPermission: () async => LocationPermission.denied,
    serviceEnabled: () async => false,
    prefs: SharedPreferences.getInstance,
  );
  final engine = DuaWindowEngine(repository: repo, locationService: location);
  final notifier = DuaWindowNotifier(
    engine: engine,
    locationService: location,
    repository: repo,
    clock: _fixedClock,
    resolveTimezone: () async => 'Asia/Riyadh',
    widgetDataService: widgetData,
    observeLifecycle: false,
    autoBuild: false,
    startTicker: false,
  );
  if (schedule != null) notifier.debugSetSchedule(schedule);
  return notifier;
}

Widget _harness({
  required DuaWindowNotifier notifier,
  required _SpyAnalytics analytics,
  required GoRouter router,
}) {
  return ProviderScope(
    overrides: [
      duaWindowProvider.overrideWith((ref) => notifier),
      analyticsProvider.overrideWithValue(analytics),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

GoRouter _router(List<String> navLog) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (c, s) => const Scaffold(body: DuaTimesCard()),
        ),
        GoRoute(
          path: '/duas',
          builder: (c, s) {
            navLog.add('/duas');
            return const Scaffold(body: Text('BUILD DUA SCREEN'));
          },
        ),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('active state renders the "Make your duʿā" verb + Ask CTA',
      (tester) async {
    final analytics = _SpyAnalytics();
    final navLog = <String>[];
    final notifier = _seededNotifier(_activeSchedule());

    await tester.pumpWidget(_harness(
      notifier: notifier,
      analytics: analytics,
      router: _router(navLog),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Make your duʿā'), findsOneWidget);
    expect(find.text('Ask now →'), findsOneWidget);
    // Impression fires once with the active-window property.
    expect(analytics.events, contains(AnalyticsEvents.duaTimesCardImpression));
  });

  testWidgets('between state renders "Build your duʿā" + Build CTA',
      (tester) async {
    final analytics = _SpyAnalytics();
    final navLog = <String>[];
    final notifier = _seededNotifier(_betweenSchedule());

    await tester.pumpWidget(_harness(
      notifier: notifier,
      analytics: analytics,
      router: _router(navLog),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Build your duʿā'), findsOneWidget);
    expect(find.text('Build now →'), findsOneWidget);
    // The upcoming window name appears in the cue.
    expect(find.textContaining('ʿArafah'), findsWidgets);
  });

  testWidgets('empty schedule renders nothing (render gate)', (tester) async {
    final analytics = _SpyAnalytics();
    final navLog = <String>[];
    final notifier = _seededNotifier(_emptySchedule());

    await tester.pumpWidget(_harness(
      notifier: notifier,
      analytics: analytics,
      router: _router(navLog),
    ));
    await tester.pump();

    expect(find.text('Make your duʿā'), findsNothing);
    expect(find.text('Build your duʿā'), findsNothing);
    // No impression event fires for a collapsed card.
    expect(
        analytics.events.contains(AnalyticsEvents.duaTimesCardImpression),
        isFalse);
  });

  testWidgets('tapping the CTA fires cta_tap analytics + navigates to /duas',
      (tester) async {
    final analytics = _SpyAnalytics();
    final navLog = <String>[];
    final notifier = _seededNotifier(_activeSchedule());

    await tester.pumpWidget(_harness(
      notifier: notifier,
      analytics: analytics,
      router: _router(navLog),
    ));
    await tester.pump();

    await tester.tap(find.text('Ask now →'));
    await tester.pumpAndSettle();

    expect(analytics.events, contains(AnalyticsEvents.duaTimesCardCtaTap));
    expect(navLog, contains('/duas'));
    expect(find.text('BUILD DUA SCREEN'), findsOneWidget);
  });

  testWidgets('rebuild pushes the schedule JSON to the widget data service',
      (tester) async {
    final client = _FakeWidgetClient();
    final widgetData = WidgetDataService(client: client);
    final repo = DuaWindowRepository(
      prefs: SharedPreferences.getInstance,
      loadAsset: (_) async => '{"rows":[]}',
      syncService: supabaseSyncService,
    );
    final location = LocationService(
      checkPermission: () async => LocationPermission.denied,
      requestPermission: () async => LocationPermission.denied,
      serviceEnabled: () async => false,
      prefs: SharedPreferences.getInstance,
    );
    final engine =
        DuaWindowEngine(repository: repo, locationService: location);
    final notifier = DuaWindowNotifier(
      engine: engine,
      locationService: location,
      repository: repo,
      clock: _fixedClock,
      resolveTimezone: () async => 'Asia/Riyadh',
      widgetDataService: widgetData,
      observeLifecycle: false,
      autoBuild: false,
      startTicker: false,
    );

    await notifier.rebuild();

    // A schedule JSON was pushed to the dua-times payload key.
    expect(client.lastKey, kDuaTimesPayloadKey);
    expect(client.lastValue, isNotNull);
    expect(client.lastValue, contains('computed_at'));

    notifier.dispose();
  });
}

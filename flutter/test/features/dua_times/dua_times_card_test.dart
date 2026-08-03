import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/core/widget_deep_link.dart';
import 'package:sakina/features/dua_times/models/dua_window.dart';
import 'package:sakina/features/dua_times/models/dua_window_schedule.dart';
import 'package:sakina/features/dua_times/models/dua_window_type.dart';
import 'package:sakina/features/dua_times/providers/dua_window_provider.dart';
import 'package:sakina/features/dua_times/widgets/dua_times_card.dart';
import 'package:sakina/features/dua_times/widgets/dua_times_copy.dart';
import 'package:sakina/features/dua_times/widgets/precise_paused_notice.dart';
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
    // Location OFF (no lat) → the between-state card still renders so the
    // "Turn on precise times" banner has a home (the narrow gate otherwise hides
    // the between state when location is granted).
    computedAt: DuaScheduleStamp(
      tz: 'Asia/Riyadh',
      computedThroughUtc: DateTime.utc(2027, 5, 22, 21, 0),
    ),
  );
}

/// A between schedule with location GRANTED (lat present) — the narrow gate
/// collapses this (no active window, nothing to nudge).
DuaWindowSchedule _grantedBetweenSchedule() {
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
      // Location granted (lat present) + no active window → gate collapses.
      computedAt: DuaScheduleStamp(
        tz: 'Asia/Riyadh',
        lat: 21.4,
        lon: 39.8,
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
        GoRoute(
          path: kFixLocationRoute,
          builder: (c, s) {
            navLog.add(kFixLocationRoute);
            return const Scaffold(body: Text('PRECISE TIMES SCREEN'));
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

  testWidgets(
      'narrow gate: between-state hidden when location is granted (only active '
      'windows show)', (tester) async {
    final analytics = _SpyAnalytics();
    final navLog = <String>[];
    final notifier = _seededNotifier(_grantedBetweenSchedule());

    await tester.pumpWidget(_harness(
      notifier: notifier,
      analytics: analytics,
      router: _router(navLog),
    ));
    await tester.pump();

    // No active window + location granted → the card collapses (no perpetual
    // "next window" between-state).
    expect(find.text('Build your duʿā'), findsNothing);
    expect(
        analytics.events.contains(AnalyticsEvents.duaTimesCardImpression),
        isFalse);
  });

  // ── The 2026-08 re-nag fix ────────────────────────────────────────────────
  // A user who already tapped "Turn on" must NEVER meet that pitch again, no
  // matter what the OS has done to their grant since. They get one quiet notice
  // per lapse instead, and then silence.

  testWidgets(
      'lapsed after opting in → the one-time notice, NEVER the pitch',
      (tester) async {
    final analytics = _SpyAnalytics();
    final navLog = <String>[];
    final notifier = _seededNotifier(null);
    // Location gone (no lat), but this user has answered before.
    notifier.debugSetSchedule(
      _betweenSchedule(),
      preciseState: PreciseTimesState.permissionLapsed,
    );

    await tester.pumpWidget(_harness(
      notifier: notifier,
      analytics: analytics,
      router: _router(navLog),
    ));
    await tester.pump();

    expect(find.byKey(kPrecisePausedNoticeKey), findsOneWidget);
    expect(find.text(DuaTimesCopy.enablePreciseTitle), findsNothing,
        reason: 'THE bug — the pitch must not return for someone who answered');
    // And it names the fix that actually ends the iOS "Allow Once" loop.
    expect(find.textContaining('While Using the App'), findsOneWidget);
  });

  testWidgets('notice spent → the card is silent for the same state',
      (tester) async {
    // The notice claims itself, so "already spent" is expressed the way the app
    // expresses it: the claim key already holds this state.
    SharedPreferences.setMockInitialValues({
      'dua_times_precise_notice_state': 'permission_lapsed',
    });
    final analytics = _SpyAnalytics();
    final navLog = <String>[];
    final notifier = _seededNotifier(null);
    notifier.debugSetSchedule(
      _betweenSchedule(),
      preciseState: PreciseTimesState.permissionLapsed,
    );

    await tester.pumpWidget(_harness(
      notifier: notifier,
      analytics: analytics,
      router: _router(navLog),
    ));
    await tester.pump();

    // The widget mounts but claims nothing (already spent), so it stays at zero
    // height — assert on the copy, which is what the user would see.
    expect(find.text(DuaTimesCopy.precisePausedPermission), findsNothing);
    expect(find.text(DuaTimesCopy.enablePreciseTitle), findsNothing);
    expect(find.text('Build your duʿā'), findsNothing,
        reason: 'no active window + nothing to say → collapse entirely');
  });

  // The device-QA finding (2026-08-03): with a 6s auto-fade and dismiss-on-any-
  // tap, a tester actively looking for the notice never saw it, then found
  // "Paused" in Settings and concluded the feature was broken. The notice now
  // waits for an explicit ✕ — so it must NOT disappear on its own.
  testWidgets('the notice persists — no auto-fade, no tap-anywhere dismiss',
      (tester) async {
    final analytics = _SpyAnalytics();
    final navLog = <String>[];
    final notifier = _seededNotifier(null);
    notifier.debugSetSchedule(
      _betweenSchedule(),
      preciseState: PreciseTimesState.permissionLapsed,
    );

    await tester.pumpWidget(_harness(
      notifier: notifier,
      analytics: analytics,
      router: _router(navLog),
    ));
    // Settle the entrance first: the notice lives in a SizeTransition, so a
    // half-open one is zero-height and swallows nothing.
    await tester.pumpAndSettle();
    expect(find.byKey(kPrecisePausedNoticeKey), findsOneWidget);

    // Well past the 6s the old auto-fade used, plus a tap somewhere else.
    await tester.pump(const Duration(seconds: 30));
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();

    expect(find.text(DuaTimesCopy.precisePausedPermission), findsOneWidget,
        reason: 'only the ✕ closes it — that is the whole point of the change');
  });

  testWidgets('the ✕ dismisses it and does not navigate', (tester) async {
    final analytics = _SpyAnalytics();
    final navLog = <String>[];
    final notifier = _seededNotifier(null);
    notifier.debugSetSchedule(
      _betweenSchedule(),
      preciseState: PreciseTimesState.permissionLapsed,
    );

    await tester.pumpWidget(_harness(
      notifier: notifier,
      analytics: analytics,
      router: _router(navLog),
    ));
    await tester.pumpAndSettle();
    expect(find.text(DuaTimesCopy.precisePausedPermission), findsOneWidget);

    await tester.tap(find.byKey(kPrecisePausedNoticeDismissKey));
    await tester.pumpAndSettle();

    expect(find.text(DuaTimesCopy.precisePausedPermission), findsNothing);
    expect(navLog, isEmpty, reason: 'dismissing is not a request to go anywhere');
    expect(analytics.events, contains(AnalyticsEvents.duaTimesPreciseNoticeShown));
    expect(
        analytics.events, contains(AnalyticsEvents.duaTimesPreciseNoticeAction));
  });

  // The HIG constraint made structural: the notice carries a ✕, so its tap must
  // NOT front the system location dialog. It navigates to the steps instead,
  // and PreciseTimesScreen is the one-button pre-alert view.
  testWidgets('tapping the notice goes to the steps, not the OS dialog',
      (tester) async {
    final analytics = _SpyAnalytics();
    final navLog = <String>[];
    final notifier = _seededNotifier(null);
    notifier.debugSetSchedule(
      _betweenSchedule(),
      preciseState: PreciseTimesState.permissionLapsed,
    );

    await tester.pumpWidget(_harness(
      notifier: notifier,
      analytics: analytics,
      router: _router(navLog),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text(DuaTimesCopy.precisePausedPermission));
    await tester.pumpAndSettle();

    expect(navLog, contains(kFixLocationRoute));
    expect(analytics.events, isNot(contains(AnalyticsEvents.duaTimesLocationPrompt)),
        reason: 'the prompt is fired by the screen, not by the notice');
  });

  // The bug the reviewer caught: claiming in rebuild() spent the notice while
  // the card sat under the opaque DailyLaunchOverlay — which is up on exactly
  // the cold starts where a lapse is detected. TickerMode is how the widget
  // knows it is off-screen, and it is inherited, so the claim happens when the
  // overlay goes away rather than never.
  testWidgets('offscreen (TickerMode off) → does not spend the notice',
      (tester) async {
    final analytics = _SpyAnalytics();
    // No router here — this harness mounts the card directly under a disabled
    // TickerMode, so there is nowhere to navigate.
    final notifier = _seededNotifier(null);
    notifier.debugSetSchedule(
      _betweenSchedule(),
      preciseState: PreciseTimesState.permissionLapsed,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        duaWindowProvider.overrideWith((ref) => notifier),
        analyticsProvider.overrideWithValue(analytics),
      ],
      child: MaterialApp(
        home: TickerMode(
          enabled: false,
          child: Scaffold(body: const DuaTimesCard()),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text(DuaTimesCopy.precisePausedPermission), findsNothing,
        reason: 'nothing is visible behind an opaque route');
    // …and crucially the claim is UNSPENT, so it still fires once on screen.
    expect(await notifier.claimLapseNotice(PreciseTimesState.permissionLapsed),
        isTrue,
        reason: 'an offscreen frame must never burn the one notice');
  });

  testWidgets('never asked → still gets the full pitch (the only on-ramp)',
      (tester) async {
    final analytics = _SpyAnalytics();
    final navLog = <String>[];
    final notifier = _seededNotifier(null);
    notifier.debugSetSchedule(
      _betweenSchedule(),
      preciseState: PreciseTimesState.neverAsked,
    );

    await tester.pumpWidget(_harness(
      notifier: notifier,
      analytics: analytics,
      router: _router(navLog),
    ));
    // The card body carries a flutter_animate entrance, so settle rather than
    // pump — a bare pump leaves its Timer pending and trips !timersPending.
    await tester.pumpAndSettle();

    expect(find.text(DuaTimesCopy.enablePreciseTitle), findsOneWidget);
    expect(find.byKey(kPrecisePausedNoticeKey), findsNothing);
  });

  testWidgets('unresolved renders nothing — it resolves in seconds',
      (tester) async {
    final analytics = _SpyAnalytics();
    final navLog = <String>[];
    final notifier = _seededNotifier(null);
    notifier.debugSetSchedule(
      _betweenSchedule(),
      preciseState: PreciseTimesState.unresolved,
    );

    await tester.pumpWidget(_harness(
      notifier: notifier,
      analytics: analytics,
      router: _router(navLog),
    ));
    await tester.pump();

    expect(find.byKey(kPrecisePausedNoticeKey), findsNothing);
    expect(find.text(DuaTimesCopy.enablePreciseTitle), findsNothing);
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

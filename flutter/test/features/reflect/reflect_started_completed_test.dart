// W6 Wave D — pins `reflect_started` / `reflect_completed`, the pair Reflect
// never had at the v1 diagnosis. See `ReflectNotifier.submit()` /
// `ReflectNotifier._reflect()` in `reflect_provider.dart` and the constants'
// docstrings in `analytics_event_names.dart`.
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/ai_service.dart' as ai;
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/daily_usage_service.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late List<({String event, Map<String, dynamic> props})> fired;
  final fixedNow = DateTime.parse('2026-04-10T12:00:00Z');

  ai.ReflectResponse successResponse({bool offTopic = false}) =>
      ai.ReflectResponse(
        name: 'As-Salam',
        nameArabic: 'السلام',
        reframe: 'Steadiness can return, even slowly.',
        story: 'A story of steadiness.',
        verses: const [],
        duaArabic: 'دعاء',
        duaTransliteration: 'dua',
        duaTranslation: 'supplication',
        duaSource: 'source',
        relatedNames: const [],
        offTopic: offTopic,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    await GatingService().debugSetHadTrial(true);
    fired = [];
    ReflectNotifier.onAnalyticsEvent = (event, props) {
      fired.add((event: event, props: props));
    };
  });

  tearDown(() {
    ReflectNotifier.onAnalyticsEvent = null;
    SupabaseSyncService.debugReset();
  });

  test('a successful on-topic submit fires reflect_started then '
      'reflect_completed{off_topic: false}, once each', () async {
    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) async => successResponse(),
        now: () => fixedNow,
        createId: () => 'reflection-1',
      ),
    );
    addTearDown(notifier.dispose);

    notifier.setUserText('I feel lost');
    await notifier.submit();

    // journal_entry_created also fires on a successful on-topic save — this
    // pins only the started/completed pair, in order, once each.
    final funnelEvents = fired
        .where((f) => f.event == AnalyticsEvents.reflectStarted ||
            f.event == AnalyticsEvents.reflectCompleted)
        .map((f) => f.event)
        .toList();
    expect(funnelEvents, [
      AnalyticsEvents.reflectStarted,
      AnalyticsEvents.reflectCompleted,
    ]);
    final completed = fired
        .firstWhere((f) => f.event == AnalyticsEvents.reflectCompleted);
    expect(completed.props[AnalyticsEvents.propOffTopic], isFalse);
  });

  test('an off-topic response still fires reflect_completed{off_topic: true}',
      () async {
    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) async => successResponse(offTopic: true),
        now: () => fixedNow,
        createId: () => 'reflection-offtopic',
      ),
    );
    addTearDown(notifier.dispose);

    notifier.setUserText('hi');
    await notifier.submit();

    final events = fired.map((f) => f.event).toList();
    expect(events, [
      AnalyticsEvents.reflectStarted,
      AnalyticsEvents.reflectCompleted,
    ]);
    expect(fired[1].props[AnalyticsEvents.propOffTopic], isTrue);
  });

  test(
      'a gated submit (daily cap already hit) fires NEITHER event '
      '— MUTATION: emitting reflect_started before the gate.allowed check '
      'would make this fail', () async {
    await incrementReflectUsage(); // consumes the 1/day cap

    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) async => successResponse(),
        now: () => fixedNow,
        createId: () => 'reflection-gated',
      ),
    );
    addTearDown(notifier.dispose);

    notifier.setUserText('I need peace');
    await notifier.submit();

    expect(notifier.state.gateResult, isNotNull);
    expect(notifier.state.gateResult!.allowed, isFalse);
    expect(fired, isEmpty);
  });

  test(
      'a failed AI call fires reflect_started only — '
      'MUTATION: emitting reflect_completed from the catch block in _reflect '
      'would make this fail', () async {
    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) async => throw Exception('boom'),
        now: () => fixedNow,
        createId: () => 'reflection-error',
      ),
    );
    addTearDown(notifier.dispose);

    notifier.setUserText('I feel lost');
    await notifier.submit();

    expect(notifier.state.error, isNotNull);
    final events = fired.map((f) => f.event).toList();
    expect(events, [AnalyticsEvents.reflectStarted]);
  });

  test(
      'submitWithBypass never fires reflect_started/_completed — the pair '
      'tracks only the free/gated `submit` path', () async {
    await GatingService().debugSetHadTrial(true);
    await incrementReflectUsage(); // force the daily cap so bypass is the path

    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) async => successResponse(),
        now: () => fixedNow,
        createId: () => 'reflection-bypass',
      ),
    );
    addTearDown(notifier.dispose);

    notifier.setUserText('I need peace');
    // No token balance / reservation is set up, so the reserve RPC will
    // reject and submitWithBypass returns silently — that's fine, this test
    // only pins that NO reflect funnel event fires from this entry point,
    // start or otherwise.
    await notifier.submitWithBypass();

    expect(fired, isEmpty);
  });
}

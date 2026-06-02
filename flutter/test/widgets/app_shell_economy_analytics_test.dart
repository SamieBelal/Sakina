// Pins AppShell's engagement/economy analytics (retention audit 2026-06-01):
//   - xp_awarded on EVERY XpGranted (the recurring engagement signal)
//   - level_up additionally when the grant crossed a threshold
//   - quest_completed when a quest completion lands
//
// We override analyticsProvider with a spy and assert the tracked events.
// (LevelUpOverlay rendering is covered separately by
// app_shell_level_up_overlay_test.dart — here we only care about analytics.)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:sakina/widgets/app_shell.dart';

import '../support/fake_supabase_sync_service.dart';

class _TrackingSpy extends AnalyticsService {
  final List<(String, Map<String, dynamic>?)> tracked = [];
  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event, properties));
  }
}

/// Controllable quests notifier — lets the test push a pending completion so
/// AppShell's `ref.listen` toast loop runs (and emits quest_completed).
class _ControllableQuests extends StateNotifier<QuestsState>
    implements QuestsNotifier {
  _ControllableQuests() : super(const QuestsState());

  void emitCompletion(Quest q) {
    state = state.copyWith(pendingCompletions: [...state.pendingCompletions, q]);
  }

  void emitBeginnerCompletion(BeginnerQuest q) {
    state = state.copyWith(pendingBeginnerCompletion: q);
  }

  @override
  List<Quest> consumePendingCompletions() {
    if (state.pendingCompletions.isEmpty) return const [];
    final pending = state.pendingCompletions;
    state = state.copyWith(pendingCompletions: const []);
    return pending;
  }

  @override
  void clearPendingBeginnerCompletion() {
    if (state.pendingBeginnerCompletion == null) return;
    state = state.copyWith(clearPendingBeginnerCompletion: true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeSupabaseSyncService fakeSync;
  late _TrackingSpy spy;
  late _ControllableQuests quests;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: null);
    SupabaseSyncService.debugSetInstance(fakeSync);
    spy = _TrackingSpy();
    quests = _ControllableQuests();
  });

  tearDown(() async {
    SupabaseSyncService.debugReset();
    await EconomyEvents.resetForTest();
  });

  Future<void> pumpShell(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (_, __, child) => AppShell(child: child),
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())],
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        analyticsProvider.overrideWithValue(spy),
        questsProvider.overrideWith((_) => quests),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
  }

  Iterable<(String, Map<String, dynamic>?)> tracked(String name) =>
      spy.tracked.where((e) => e.$1 == name);

  testWidgets('XpGranted without a level fires xp_awarded only', (tester) async {
    await pumpShell(tester);

    EconomyEvents.publish(const XpGranted(
      amount: 25,
      newTotal: 125,
      newState: XpState(
        totalXp: 125,
        level: 2,
        title: 'Listener',
        titleArabic: 'مُسْتَمِع',
        xpForNextLevel: 150,
        xpIntoCurrentLevel: 25,
      ),
      leveledUp: false,
      source: EconomyEventSource.streak,
    ));
    await tester.pump();

    final xp = tracked(AnalyticsEvents.xpAwarded).toList();
    expect(xp.length, 1);
    expect(xp.first.$2?['amount'], 25);
    expect(xp.first.$2?['source'], 'streak');
    expect(xp.first.$2?['new_total'], 125);
    expect(tracked(AnalyticsEvents.levelUp), isEmpty);
  });

  testWidgets('XpGranted that levels up fires xp_awarded AND level_up',
      (tester) async {
    await pumpShell(tester);

    // rewards:null exercises the level_up branch + the defensive from-level
    // fallback (to - 1) WITHOUT pushing the LevelUpOverlay (whose looping
    // flutter_animate timers never settle — overlay rendering is covered by
    // app_shell_level_up_overlay_test.dart). track() fires synchronously in
    // the stream listener, so no overlay is needed to assert analytics.
    EconomyEvents.publish(const XpGranted(
      amount: 100,
      newTotal: 200,
      newState: XpState(
        totalXp: 200,
        level: 3,
        title: 'Listener',
        titleArabic: 'مُسْتَمِع',
        xpForNextLevel: 250,
        xpIntoCurrentLevel: 0,
      ),
      leveledUp: true,
      source: EconomyEventSource.quest,
    ));
    await tester.pump();

    expect(tracked(AnalyticsEvents.xpAwarded).length, 1);
    final lvl = tracked(AnalyticsEvents.levelUp).toList();
    expect(lvl.length, 1);
    expect(lvl.first.$2?['from_level'], 2);
    expect(lvl.first.$2?['to_level'], 3);
  });

  testWidgets('level_up from_level uses rewards.levelsGained for multi-level',
      (tester) async {
    // A grant that jumps 2 levels: from_level = to - levelsGained. We assert
    // the computation directly from the spy without rendering the overlay —
    // pump only enough for the synchronous listener, never building the route.
    await pumpShell(tester);

    EconomyEvents.publish(const XpGranted(
      amount: 500,
      newTotal: 700,
      newState: XpState(
        totalXp: 700,
        level: 5,
        title: 'Devotee',
        titleArabic: 'مُتَعَبِّد',
        xpForNextLevel: 800,
        xpIntoCurrentLevel: 0,
      ),
      leveledUp: true,
      rewards: LevelUpRewards(
        levelsGained: 2,
        tokensAwarded: 20,
        scrollsAwarded: 2,
        titleUnlocked: false,
      ),
      source: EconomyEventSource.quest,
    ));

    await tester.pump(); // broadcast listener delivers (async) → track fires

    final lvl = tracked(AnalyticsEvents.levelUp).toList();
    expect(lvl.length, 1);
    expect(lvl.first.$2?['from_level'], 3);
    expect(lvl.first.$2?['to_level'], 5);

    // Drain the overlay this one DOES push (rewards != null), for teardown.
    // Warm-up pumps must run first (push → build → render) so the overlay's
    // Future.delayed phase timers are armed before we advance the clock —
    // mirrors app_shell_level_up_overlay_test.dart's drain sequence.
    await tester.pump(); // post-frame → Navigator.push
    await tester.pump(); // route entry built
    await tester.pump(); // overlay rendered
    await tester.pump(); // settle initial animations
    await tester.pump(const Duration(milliseconds: 800)); // phase 0→1
    await tester.pump(const Duration(milliseconds: 500)); // phase 1→2
    await tester.pump(const Duration(milliseconds: 500)); // finite slice
  });

  testWidgets('a pending quest completion fires quest_completed', (tester) async {
    await pumpShell(tester);

    quests.emitCompletion(const Quest(
      id: 'daily_checkin',
      cadence: QuestCadence.daily,
      title: 'Daily check-in',
      description: 'Complete a muḥāsabah',
      icon: Icons.check,
      xpReward: 20,
      tokenReward: 5,
      scrollReward: 0,
      poolIndex: 0,
      target: 1,
    ));
    await tester.pump(); // ref.listen fires → schedules post-frame
    await tester.pump(); // post-frame loop runs → track + toast

    final qc = tracked(AnalyticsEvents.questCompleted).toList();
    expect(qc.length, 1);
    expect(qc.first.$2?['quest_id'], 'daily_checkin');
    expect(qc.first.$2?['quest_type'], 'standard');
    expect(qc.first.$2?['xp_reward'], 20);
    expect(qc.first.$2?['token_reward'], 5);

    // Drain the toast's auto-dismiss timers (3500ms + 400ms) for teardown.
    await tester.pump(const Duration(milliseconds: 3500));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
      'a pending beginner (First Steps) completion fires quest_completed '
      'with quest_type beginner', (tester) async {
    await pumpShell(tester);

    quests.emitBeginnerCompletion(const BeginnerQuest(
      id: BeginnerQuestId.firstMuhasabah,
      title: 'Your First Check-In',
      description: 'Complete a Muhasabah and meet a Name of Allah.',
      icon: Icons.favorite_rounded,
      xpReward: 75,
      tokenReward: 50,
      scrollReward: 5,
      route: '/muhasabah',
    ));
    await tester.pump(); // ref.listen fires → schedules post-frame
    await tester.pump(); // post-frame runs → track + toast

    final qc = tracked(AnalyticsEvents.questCompleted).toList();
    expect(qc.length, 1);
    expect(qc.first.$2?['quest_type'], AnalyticsEvents.questTypeBeginner);
    expect(qc.first.$2?['quest_id'], isNotNull);
    expect(qc.first.$2?['quest_id'], BeginnerQuestId.firstMuhasabah.key);
    expect(qc.first.$2?['xp_reward'], 75);
    expect(qc.first.$2?['token_reward'], 50);

    // Drain the toast's auto-dismiss timers (3500ms + 400ms) for teardown.
    await tester.pump(const Duration(milliseconds: 3500));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));
  });
}

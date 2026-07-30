// W4 Wave 3 follow-up — the off-topic re-ask.
//
// Before this, an answer the classifier rejected was terminal for the day: the
// off-topic view offered only "Return home", and because the rejected response
// stayed cached, a user who left and came back met it again with no way past.
// The user kept their card and their reward and lost their reflection.
//
// The fix lets them rephrase against the SAME reveal. What this suite pins:
//
//   1. A re-ask produces exactly ONE reveal in total — the headline property.
//      A second `discoverName` here would spend another queue position, teach a
//      different Name, and charge for it.
//   2. The reward is claimed once, on the first submit only.
//   3. The card does not change.
//   4. The rejected reflection AND its cache are dropped, so re-entering does
//      not land back on it.
//   5. `attempt` rides `daily_question_answered` as a dimension, and
//      `daily_question_off_topic` makes the classifier's fire rate countable.
//   6. The answer text still never leaves the device — on either attempt.
//   7. A force-quit mid-rephrase comes back to the question, not to a reveal.
//
// The classifier is driven for real rather than stubbed: `classifyOffTopic` is
// pure and runs inside `reflectWithOpenAI` before the API-key check, so a
// genuinely off-topic sentence produces a genuinely off-topic response with no
// network and no seam.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/features/daily/content/daily_question_copy.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/screens/muhasabah_screen.dart';
import 'package:sakina/features/daily/widgets/daily_question_prompt.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/daily_question_analytics.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:visibility_detector/visibility_detector.dart';

import '../../support/fake_supabase_sync_service.dart';

class _FreeUser extends PurchaseService {
  _FreeUser() : super.test();
  @override
  Future<bool> isPremium() async => false;
}

/// Rejected by `classifyOffTopic`'s `recipe` pattern — a real sentence the real
/// classifier really refuses, so this suite breaks if the classifier's contract
/// changes rather than passing against a stub that no longer resembles it.
const String _offTopicAnswer = 'how do i bake bread';
const String _onTopicAnswer = 'everything feels heavy today';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  late FakeSupabaseSyncService fakeSync;
  late List<({String event, Map<String, dynamic> props})> events;

  setUp(() async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    PurchaseService.debugSetOverride(_FreeUser());
    await hydrateTokenCache(balance: 100, totalSpent: 0);
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'UTC';
    debugDailyLoopClock = () => DateTime.utc(2026, 8, 4, 3);
    fakeSync.rpcHandlers['claim_daily_reward'] = (_) async => {
          'current_day': 3,
          'last_claim_date': '2026-08-04',
          'token_balance': 115,
        };
    events = [];
    DailyLoopNotifier.onAnalyticsEvent =
        (e, p) => events.add((event: e, props: p));
  });

  tearDown(() {
    debugDailyLoopClock = () => DateTime.now().toUtc();
    debugResetUserLocalDay();
    DailyLoopNotifier.onAnalyticsEvent = null;
    DailyQuestionAnalytics.onAnalyticsEvent = null;
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  /// Every reveal emits exactly one `check_in_completed`, so counting them
  /// counts reveals — including any a future refactor might add without
  /// touching `discoverName` itself.
  int reveals() =>
      events.where((e) => e.event == AnalyticsEvents.checkInCompleted).length;

  int claims() =>
      fakeSync.rpcCalls.where((c) => c['fn'] == 'claim_daily_reward').length;

  List<Map<String, dynamic>> propsFor(String event) =>
      events.where((e) => e.event == event).map((e) => e.props).toList();

  /// Drives a full off-topic first attempt: answer → reveal → the rejected
  /// reflection lands in state.
  ///
  /// [ownsDispose] is false when a `ProviderScope` will take the notifier over:
  /// a StateNotifierProvider disposes what its override hands back, and a
  /// second `dispose()` trips StateNotifier's mounted assert.
  Future<DailyLoopNotifier> answeredOffTopic({bool ownsDispose = true}) async {
    final notifier = DailyLoopNotifier();
    if (ownsDispose) addTearDown(notifier.dispose);
    await settle();

    await notifier.submitDailyAnswer(_offTopicAnswer);
    await settle();
    await notifier.startDeeper();
    await settle();

    expect(notifier.state.reflectResult?.offTopic, isTrue,
        reason: 'the real classifier really rejected it — if this fails the '
            'classifier changed and the rest of this suite is testing nothing');
    return notifier;
  }

  /// The same thing from inside a widget test.
  ///
  /// [answeredOffTopic] awaits real `Future.delayed`s, and under
  /// `testWidgets`' fake clock those never complete unless someone pumps —
  /// which is a deadlock, not a slow test. `runAsync` runs the provider work in
  /// the real async zone, where the reflection request and the prefetch behave
  /// exactly as they do in the pure tests above.
  Future<DailyLoopNotifier> answeredOffTopicIn(WidgetTester t) async =>
      (await t.runAsync(() => answeredOffTopic(ownsDispose: false)))!;

  // -------------------------------------------------------------------------
  // 1-3. The re-ask costs nothing.
  // -------------------------------------------------------------------------

  test('a re-ask produces exactly one reveal in total', () async {
    final notifier = await answeredOffTopic();
    expect(reveals(), 1);
    final card = notifier.state.engagedCard;

    await notifier.reopenQuestionAfterOffTopic();
    await notifier.submitDailyAnswer(_onTopicAnswer);
    await settle();

    expect(reveals(), 1,
        reason: 'THE property this whole change turns on. A second reveal '
            'would spend another queue position, teach a Name the user was '
            'never promised, and charge them for the privilege of having been '
            'misclassified.');
    expect(identical(notifier.state.engagedCard, card), isTrue,
        reason: 'the same card, not merely an equal one');
  });

  test('a re-ask does not claim the reward again', () async {
    final notifier = await answeredOffTopic();
    await notifier.dailyRewardClaimFuture;
    expect(claims(), 1);

    await notifier.reopenQuestionAfterOffTopic();
    await notifier.submitDailyAnswer(_onTopicAnswer);
    await notifier.dailyRewardClaimFuture;
    await settle();

    expect(claims(), 1,
        reason: 'the ladder was already claimed on attempt 1 — the RPC is '
            'idempotent, but not calling it is the guarantee');
  });

  test('the rephrased answer drives the reflection, against the same Name',
      () async {
    final notifier = await answeredOffTopic();
    final name = notifier.state.checkinName;

    await notifier.reopenQuestionAfterOffTopic();
    await notifier.submitDailyAnswer(_onTopicAnswer);
    await settle();

    final request = notifier.debugDeeperRequest()!;
    expect(request.contextText, _onTopicAnswer,
        reason: 'the new words, not the rejected ones');
    expect(request.forceName, name,
        reason: 'a rephrase changes what is SAID about the Name, never which '
            'Name it is — the queue chose it and W3 promised it');
    expect(notifier.state.reflectResult?.offTopic, isFalse);
    expect(notifier.state.currentStep, DailyLoopStep.deeper);
  });

  // -------------------------------------------------------------------------
  // 4. The stale cache — half the original dead end.
  // -------------------------------------------------------------------------

  test('the rejected reflection and its cache are both dropped', () async {
    final notifier = await answeredOffTopic();

    await notifier.reopenQuestionAfterOffTopic();

    expect(notifier.state.reflectResult, isNull,
        reason: 'not merely hidden — cleared, or `startDeeper` would serve it '
            'straight back from the cache on the next Go Deeper tap');
    expect(notifier.state.awaitingReAnswer, isTrue);
    expect(notifier.state.currentStep, DailyLoopStep.checkin);
    expect(notifier.state.checkinDone, isTrue,
        reason: 'the reveal still happened — this is the one state where the '
            'question shows on a revealed day');
  });

  test('reopening is a no-op when the reflection was not off-topic', () async {
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);
    await settle();
    await notifier.submitDailyAnswer(_onTopicAnswer);
    await settle();
    await notifier.startDeeper();
    await settle();
    expect(notifier.state.reflectResult?.offTopic, isFalse);

    await notifier.reopenQuestionAfterOffTopic();

    expect(notifier.state.awaitingReAnswer, isFalse,
        reason: 'reachable only from the off-topic view; anywhere else it '
            'would be the phantom-second-gacha bug class with extra steps');
    expect(notifier.state.reflectResult, isNotNull);
  });

  // -------------------------------------------------------------------------
  // 5-6. Analytics, and the privacy rule that outranks it.
  // -------------------------------------------------------------------------

  test('attempt rides the answered event as a dimension', () async {
    final notifier = await answeredOffTopic();
    await notifier.reopenQuestionAfterOffTopic();
    await notifier.submitDailyAnswer(_onTopicAnswer);
    await settle();

    final answered = propsFor(AnalyticsEvents.dailyQuestionAnswered);
    expect(answered.length, 2);
    expect(answered[0][AnalyticsEvents.propAttempt], 1);
    expect(answered[1][AnalyticsEvents.propAttempt], 2);
    expect(
      events.any((e) => e.event.contains('re_ask')),
      isFalse,
      reason: 'a separate re-ask EVENT would fork the funnel at step two and '
          'silently under-count every segment built on the original',
    );
  });

  test('the off-topic signal fires with its attempt, once per attempt',
      () async {
    final notifier = await answeredOffTopic();

    final offTopic = propsFor(AnalyticsEvents.dailyQuestionOffTopic);
    expect(offTopic.length, 1);
    expect(offTopic.single[AnalyticsEvents.propAttempt], 1);

    // Re-entering the same rejected reflection must not re-count it — the rate
    // is per answer, not per look.
    await notifier.startDeeper();
    await settle();
    expect(propsFor(AnalyticsEvents.dailyQuestionOffTopic).length, 1);
  });

  test('a rephrase that is ALSO rejected counts again', () async {
    final notifier = await answeredOffTopic();
    await notifier.reopenQuestionAfterOffTopic();
    await notifier.submitDailyAnswer('what is the weather in london');
    await settle();

    final offTopic = propsFor(AnalyticsEvents.dailyQuestionOffTopic);
    expect(offTopic.length, 2,
        reason: 'someone rejected twice is the case most worth seeing');
    expect(offTopic[1][AnalyticsEvents.propAttempt], 2);
  });

  test('neither attempt puts the answer text on the wire', () async {
    final notifier = await answeredOffTopic();
    await notifier.reopenQuestionAfterOffTopic();
    await notifier.submitDailyAnswer(_onTopicAnswer);
    await settle();

    for (final e in events) {
      for (final entry in e.props.entries) {
        final value = entry.value;
        if (value is! String) continue;
        expect(value.contains(_offTopicAnswer), isFalse,
            reason: '${e.event}.${entry.key} carried the rejected answer');
        expect(value.contains(_onTopicAnswer), isFalse,
            reason: '${e.event}.${entry.key} carried the answer');
      }
    }
  });

  // -------------------------------------------------------------------------
  // 7. Force-quit mid-rephrase.
  // -------------------------------------------------------------------------

  test('a force-quit mid-rephrase comes back to the question, not a reveal',
      () async {
    final first = await answeredOffTopic();
    await first.reopenQuestionAfterOffTopic();
    final revealedId = first.state.engagedCard!.id;
    events.clear();

    // The process dies while the user is staring at the pre-filled field.
    final restored = DailyLoopNotifier();
    addTearDown(restored.dispose);
    await settle();

    expect(restored.state.awaitingReAnswer, isTrue,
        reason: 'persisted on purpose — without it the restored state is a '
            'revealed day with the question hidden, and the user has no way '
            'back to the reflection they were promised');
    expect(restored.state.checkinDone, isTrue);
    expect(restored.state.engagedCard!.id, revealedId);

    await restored.submitDailyAnswer(_onTopicAnswer);
    await settle();

    expect(reveals(), 0,
        reason: 'the answer after the restart still reveals nothing');
    expect(restored.state.engagedCard!.id, revealedId);
  });

  // -------------------------------------------------------------------------
  // The surface.
  // -------------------------------------------------------------------------

  Future<void> pumpScreen(WidgetTester t, DailyLoopNotifier notifier) async {
    final router = GoRouter(
      initialLocation: '/muhasabah',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/muhasabah',
          builder: (_, __) => const MuhasabahScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await t.pumpWidget(
      ProviderScope(
        overrides: [dailyLoopProvider.overrideWith((_) => notifier)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 2));
  }

  testWidgets('the off-topic view offers the rephrase, in the founder copy',
      (t) async {
    final notifier = await answeredOffTopicIn(t);
    await pumpScreen(t, notifier);

    expect(find.text(DailyQuestionCopy.offTopicHeader), findsOneWidget);
    expect(find.text(DailyQuestionCopy.offTopicBody), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Return home'), findsOneWidget);
    // Nothing that tells the user they were wrong.
    expect(find.textContaining('understand'), findsNothing);
    expect(find.textContaining("couldn't"), findsNothing);
  });

  testWidgets('tapping Try again returns the question with their words in it',
      (t) async {
    final notifier = await answeredOffTopicIn(t);
    await pumpScreen(t, notifier);

    await t.tap(find.text('Try again'));
    await t.pump();
    await t.pump(const Duration(seconds: 2));

    expect(find.byType(DailyQuestionPrompt), findsOneWidget);
    final field = t.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, _offTopicAnswer,
        reason: 'an empty box reads as "that was deleted", and re-typing a '
            'sentence about what you are carrying because a classifier '
            'disliked it is a small cruelty');
    expect(field.controller!.selection.baseOffset, _offTopicAnswer.length,
        reason: 'caret at the end — the keyboard opens ready to append');
  });

  testWidgets('a re-ask does not emit a second daily_question_shown',
      (t) async {
    final surfaceEvents = <String>[];
    DailyQuestionAnalytics.onAnalyticsEvent = (e, _) => surfaceEvents.add(e);

    final notifier = await answeredOffTopicIn(t);
    await pumpScreen(t, notifier);
    await t.tap(find.text('Try again'));
    await t.pump();
    await t.pump(const Duration(seconds: 2));

    expect(find.byType(DailyQuestionPrompt), findsOneWidget);
    expect(
      surfaceEvents.where((e) => e == AnalyticsEvents.dailyQuestionShown),
      isEmpty,
      reason: 'the user asked for the question back; the app did not put it to '
          "them. Emitting would also trip Wave 7's once-per-local-day day_open "
          'assert on a completely ordinary path.',
    );
  });
}

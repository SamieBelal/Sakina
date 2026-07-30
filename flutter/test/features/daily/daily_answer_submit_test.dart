// W4 Wave 3 — the answer drives the reflection.
//
// The submit path, end to end: the day's question hands its answer to
// `DailyLoopNotifier.submitDailyAnswer`, which writes it into `checkinAnswers`,
// derives `problem_category` from the same chip taxonomy onboarding uses,
// claims the daily reward, and then runs the ordinary `discoverName()`.
//
// The contract this suite pins, in the order plan §11 states it:
//
//   1. The answer reaches `_deeperContextText` — the reflection is written
//      about the user's own words, not the card's blurb.
//   2. `forceName` still pins the QUEUE's Name during D1–D7. The answer shapes
//      the reflection; it does not choose the Name (spec M3). Letting it choose
//      during the queue window would contradict the seven-Name promise the last
//      two waves were built to keep.
//   3. THE REVEAL DOES NOT AWAIT THE AI. This is the single reason the April
//      2026 commit removed questions in the first place, and the one property
//      whose regression would be invisible in a screenshot.
//   4. The off-topic branch renders — reusing Reflect's handling, not a new one.
//   5. The reward is claimed exactly once, at submit, and is idempotent on
//      replay — so a user who abandons after answering keeps their 7-day ladder.
//   6. A cold restart preserves the answer and does not run a second reveal.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/screens/muhasabah_screen.dart';
import 'package:sakina/features/daily/widgets/daily_question_prompt.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/daily_usage_service.dart' as daily_usage;
import 'package:sakina/services/name_queue_service.dart';
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

/// A notifier whose state can be set directly, for the widget-level branch
/// tests. `skipInitForTests` keeps Supabase, gating and the AI seam out.
class _StubLoop extends DailyLoopNotifier {
  _StubLoop(DailyLoopState initial) : super(skipInitForTests: true) {
    state = initial;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  final nowUtc = DateTime.utc(2026, 8, 4, 3, 0);

  late FakeSupabaseSyncService fakeSync;

  setUp(() async {
    // The reveal lands the screen on the check-in result, whose `TourAnchor`
    // wraps a VisibilityDetector that re-arms a 500ms timer on every paint —
    // unpumpable past while the entrance animations are still running. Same
    // line every other anchored-widget suite uses.
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    PurchaseService.debugSetOverride(_FreeUser());
    await hydrateTokenCache(balance: 100, totalSpent: 0);
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'UTC';
    debugDailyLoopClock = () => nowUtc;
    // The reward RPC, so the claim has something server-authoritative to
    // return and `rpcCalls` counts real claims rather than no-ops.
    fakeSync.rpcHandlers['claim_daily_reward'] = (_) async => {
          'current_day': 3,
          'last_claim_date': '2026-08-04',
          'token_balance': 115,
        };
  });

  tearDown(() {
    debugDailyLoopClock = () => DateTime.now().toUtc();
    debugResetUserLocalDay();
    daily_usage.debugDailyUsageClock = null;
    DailyLoopNotifier.onAnalyticsEvent = null;
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  /// Let the fire-and-forget deeper-reflection prefetch settle.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  int claimCalls() =>
      fakeSync.rpcCalls.where((c) => c['fn'] == 'claim_daily_reward').length;

  // A queue whose position 2 carries name_id 22 — the D1–D7 window, where the
  // Name is the queue's to choose.
  DailyLoopNotifier queueNotifier() => DailyLoopNotifier(
        nameQueueService: NameQueueService(
          currentUserId: () => fakeSync.userId,
          selectRows: (_) async => [
            {
              'position': 1,
              'name_id': 11,
              'unsealed_at': DateTime.utc(2026, 8, 1, 15).toIso8601String(),
            },
            {'position': 2, 'name_id': 22, 'unsealed_at': null},
          ],
          callRpc: (_, __) async => [
            {
              'position': 2,
              'name_id': 22,
              'unsealed_at': nowUtc.toIso8601String(),
            },
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // 1. The answer reaches the reflection.
  // ---------------------------------------------------------------------------

  test('the answer becomes the reflection\'s context text', () async {
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);
    await settle();

    await notifier.submitDailyAnswer('I keep waking up at 3am worrying');
    await settle();

    expect(notifier.state.checkinAnswers,
        ['I keep waking up at 3am worrying'],
        reason: 'one question, one answer — replacing, not accumulating like '
            'the dormant 4-question flow');

    final request = notifier.debugDeeperRequest()!;
    expect(request.contextText, 'I keep waking up at 3am worrying',
        reason: 'the reflection is written about what the user said, NOT the '
            'card blurb `_deeperContextText` falls back to');
  });

  test('the answer is trimmed, and an empty one is not an answer at all',
      () async {
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);
    await settle();

    await notifier.submitDailyAnswer('   ');
    await settle();

    expect(notifier.state.checkinAnswers, isEmpty);
    expect(notifier.state.checkinDone, isFalse,
        reason: 'whitespace must not spend the day\'s reveal');
    expect(claimCalls(), 0, reason: 'nor claim the reward');

    await notifier.submitDailyAnswer('  everything feels heavy  ');
    await settle();

    expect(notifier.state.checkinAnswers, ['everything feels heavy']);
  });

  // ---------------------------------------------------------------------------
  // 2. `problem_category` — typed text segments identically to a chip tap.
  // ---------------------------------------------------------------------------

  // Separate tests, not one with two notifiers: a second notifier in the same
  // test would restore the FIRST one's day blob and refuse the submit — which
  // is the cold-restart guard working, and would silently pass this assertion
  // for the wrong reason.
  test('typed text is segmented by the chip taxonomy it names', () async {
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);
    await settle();

    await notifier.submitDailyAnswer('everything feels so heavy lately');
    await settle();

    expect(notifier.state.checkinProblemCategory, 'heavy');
    expect(notifier.state.checkinInputMode, inputModeTyped);
  });

  test('a chip tap produces the same problem_category as typing its words',
      () async {
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);
    await settle();

    await notifier.submitDailyAnswer('Everything feels heavy', chipKey: 'heavy');
    await settle();

    expect(notifier.state.checkinProblemCategory, 'heavy',
        reason: 'the same category the typed sentence above produces — a '
            'typed answer must segment identically to the chip it names, or '
            '`problem_category` forks away from onboarding');
    expect(notifier.state.checkinInputMode, inputModeChip);
  });

  test('a tapped chip is authoritative over its own label', () async {
    // The sign chip's label is deliberately keyword-free ("I can't put it into
    // words"), so re-deriving from the label would record `unmatched` for a
    // user who made a specific claim.
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);
    await settle();

    await notifier.submitDailyAnswer(
      "I can't put it into words",
      chipKey: 'sign',
    );
    await settle();

    expect(notifier.state.checkinProblemCategory, 'unspoken');
  });

  test('free text the taxonomy does not cover records `unmatched`', () async {
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);
    await settle();

    await notifier.submitDailyAnswer('alhamdulillah, today was good');
    await settle();

    expect(notifier.state.checkinProblemCategory, 'unmatched',
        reason: 'the reveal still happens; the category records that the '
            'taxonomy did not cover what they typed');
    expect(notifier.state.checkinDone, isTrue);
  });

  // ---------------------------------------------------------------------------
  // 3. The queue keeps picking the Name (spec M3).
  // ---------------------------------------------------------------------------

  test('forceName still pins the queue\'s Name while the answer shapes the '
      'reflection', () async {
    final notifier = queueNotifier();
    addTearDown(notifier.dispose);
    await settle();

    await notifier.submitDailyAnswer("I'm worried about money");
    await settle();

    expect(notifier.state.engagedCard!.id, 22,
        reason: 'the queue chose the Name, not the answer — a rizq answer must '
            'not redirect a D1–D7 reveal');
    expect(notifier.state.revealSource, revealSourceQueue);

    final request = notifier.debugDeeperRequest()!;
    expect(request.forceName, notifier.state.checkinName);
    expect(request.contextText, "I'm worried about money");
  });

  // ---------------------------------------------------------------------------
  // 4. The reveal does not block on the AI.
  // ---------------------------------------------------------------------------

  test('the reveal lands before any reflection does', () async {
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);
    await settle();

    // Every state the submit produces, in order.
    final reflectAtReveal = <bool>[];
    notifier.addListener((s) {
      if (s.checkinDone) reflectAtReveal.add(s.reflectResult != null);
    }, fireImmediately: false);

    await notifier.submitDailyAnswer('my mind will not stop racing');

    expect(notifier.state.checkinDone, isTrue,
        reason: 'the card is revealed the moment `submitDailyAnswer` returns');
    expect(notifier.state.engagedCard, isNotNull);
    expect(notifier.state.reflectResult, isNull,
        reason: 'THE LOAD-BEARING ASSERTION: the reflection is still being '
            'written. `_prefetchDeeperReflection` is fire-and-forget and only '
            '`startDeeper` ever moves its result into state, so a reveal that '
            'had waited for the AI could not have got here with a null '
            'reflectResult.');
    expect(reflectAtReveal, isNotEmpty);
    expect(reflectAtReveal.every((hadReflection) => !hadReflection), isTrue,
        reason: 'no state in which the card is revealed carries a reflection');

    // And the prefetch really did start — this is not passing because nothing
    // was requested.
    expect(notifier.debugDeeperRequest(), isNotNull);
    await settle();
    await notifier.startDeeper();
    expect(notifier.state.reflectResult, isNotNull,
        reason: 'the reflection arrives behind the reveal, as designed');
  });

  // ---------------------------------------------------------------------------
  // 5. The reward, re-timed to submit (spec §6 / DECISION 1).
  // ---------------------------------------------------------------------------

  test('the reward is claimed at submit, exactly once', () async {
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);
    await settle();

    expect(claimCalls(), 0);

    await notifier.submitDailyAnswer('feeling far from Allah');
    await notifier.dailyRewardClaimFuture;
    await settle();

    expect(claimCalls(), 1);
    expect(notifier.state.rewardClaimResult, isNotNull);
    expect(notifier.state.tokenBalance, 115,
        reason: 'the server-authoritative balance rides back on the claim');
  });

  test('a user who abandons after answering keeps the ladder', () async {
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);
    await settle();

    await notifier.submitDailyAnswer('I keep sinning and going back');
    await notifier.dailyRewardClaimFuture;
    await settle();

    // No `startDeeper`, no "Ameen", no `completeDeeper` — the user closed the
    // app after their card. The claim already happened, which is the entire
    // point of claiming at submit: `claim_daily_reward` resets a 7-day ladder
    // to day 0 on ONE missed claim, so a day-6 user must not lose it for
    // failing to tap through every beat.
    expect(notifier.state.currentStep, isNot(DailyLoopStep.completed));
    expect(claimCalls(), 1);
  });

  test('a replayed submit claims nothing further', () async {
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);
    await settle();

    await notifier.submitDailyAnswer('everything feels heavy');
    await notifier.dailyRewardClaimFuture;
    await settle();

    await notifier.submitDailyAnswer('everything feels heavy');
    await notifier.dailyRewardClaimFuture;
    await settle();

    expect(claimCalls(), 1,
        reason: 'the day is already answered — a second submit is a no-op, '
            'and the RPC is idempotent behind it anyway');
    expect(notifier.state.checkinAnswers, ['everything feels heavy']);
  });

  test('a claim failure does not fail the reveal', () async {
    fakeSync.rpcHandlers['claim_daily_reward'] =
        (_) async => throw StateError('rewards are down');

    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);
    await settle();

    await notifier.submitDailyAnswer('everything feels heavy');
    await notifier.dailyRewardClaimFuture;
    await settle();

    expect(notifier.state.checkinDone, isTrue);
    expect(notifier.state.error, isNull,
        reason: '`state.error` is what the bypass wrapper reads to decide '
            'commit-versus-refund — a reward hiccup must never reach it');
  });

  test('a claim landing after a FAILED reveal does not erase the failure',
      () async {
    // The claim is deliberately racing `discoverName`, so it can settle after
    // the catch block — and `copyWith` assigns `error` rather than merging it.
    // An unguarded write here would blank the error view AND tell
    // `discoverNameWithBypass` to commit a bypass for a reveal that never
    // happened.
    fakeSync.rpcHandlers['claim_daily_reward'] = (_) async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return {'current_day': 3, 'last_claim_date': '2026-08-04'};
    };

    final notifier = DailyLoopNotifier(
      nameQueueService: NameQueueService(
        currentUserId: () => fakeSync.userId,
        selectRows: (_) async => [
          {'position': 1, 'name_id': 11, 'unsealed_at': null},
        ],
        callRpc: (_, __) async => throw StateError('unseal exploded'),
      ),
    );
    addTearDown(notifier.dispose);
    await settle();

    await notifier.submitDailyAnswer('everything feels heavy');
    expect(notifier.state.error, isNotNull, reason: 'the reveal failed');

    await notifier.dailyRewardClaimFuture;
    await settle();

    expect(notifier.state.error, isNotNull,
        reason: 'and it still has, after the reward landed');
    expect(notifier.state.rewardClaimResult, isNotNull,
        reason: 'the claim itself still succeeded — the two are independent');
  });

  // ---------------------------------------------------------------------------
  // 6. Cold restart.
  // ---------------------------------------------------------------------------

  test('a cold restart keeps the answer and runs no second reveal', () async {
    final first = DailyLoopNotifier();
    addTearDown(first.dispose);
    await settle();

    await first.submitDailyAnswer('no one sees what I am carrying');
    await settle();
    final revealedId = first.state.engagedCard!.id;
    expect(first.state.checkinProblemCategory, 'unseen');

    // The process dies here — between the card and "Ameen".
    final restored = DailyLoopNotifier();
    addTearDown(restored.dispose);
    await settle();

    expect(restored.state.checkinAnswers, ['no one sees what I am carrying'],
        reason: 'the answer round-trips through the day blob for free');
    expect(restored.state.checkinProblemCategory, 'unseen',
        reason: 'and so does its segmentation, so Wave 7 does not report null '
            'for every interrupted session');
    expect(restored.state.checkinDone, isTrue);
    expect(restored.state.engagedCard!.id, revealedId,
        reason: 'the SAME Name resumes — a second reveal here would hand the '
            'user a different Name and re-spend the queue position');
    expect(restored.debugDeeperRequest()!.contextText,
        'no one sees what I am carrying',
        reason: 'the resumed reflection is still about their own words');
  });

  // ---------------------------------------------------------------------------
  // 7. Off-topic renders Reflect's branch, not a new one.
  // ---------------------------------------------------------------------------

  /// The container owns the notifier's lifetime (a StateNotifierProvider
  /// disposes what its override hands back), so this must not add a teardown of
  /// its own — a second `dispose()` trips StateNotifier's mounted assert.
  Future<_StubLoop> pumpScreen(WidgetTester t, DailyLoopState initial) async {
    final notifier = _StubLoop(initial);
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
    return notifier;
  }

  const offTopicResponse = ReflectResponse(
    name: 'Ar-Rahman',
    nameArabic: 'الرحمن',
    reframe: '',
    story: '',
    duaArabic: '',
    duaTransliteration: '',
    duaTranslation: '',
    duaSource: '',
    relatedNames: [],
    offTopic: true,
  );

  testWidgets('an off-topic answer renders the off-topic view', (t) async {
    await pumpScreen(
      t,
      const DailyLoopState(
        loaded: true,
        currentStep: DailyLoopStep.deeper,
        checkinDone: true,
        checkinName: 'Al-Wakeel',
        reflectResult: offTopicResponse,
      ),
    );

    // Reflect's exact copy, reached through Reflect's exact status — the
    // off-topic response is the DEMO response, so rendering it as an ordinary
    // reflection would teach a Name the user never revealed.
    expect(
      find.text("Share how you're feeling, and I'll find a Name for it."),
      findsOneWidget,
    );
    // The escape hatch survives (plan §2 rule 7).
    expect(find.text('Return home'), findsOneWidget);
    // And no retry button: on this path "try again" would mean re-entering a
    // question that sits in front of a reveal which has already happened, so
    // it is dropped rather than offered as a no-op. Same treatment the
    // unrenderable deck gets.
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('an on-topic answer does not', (t) async {
    await pumpScreen(
      t,
      const DailyLoopState(
        loaded: true,
        currentStep: DailyLoopStep.deeper,
        checkinDone: true,
        checkinName: 'Al-Wakeel',
        reflectResult: ReflectResponse(
          name: 'Al-Wakeel',
          nameArabic: 'الوكيل',
          reframe: 'You are not carrying this alone.',
          story: 'A short story.',
          duaArabic: 'دعاء',
          duaTransliteration: 'dua',
          duaTranslation: 'A dua.',
          duaSource: 'Qur\'an',
          relatedNames: [],
          offTopic: false,
        ),
      ),
    );

    expect(
      find.text("Share how you're feeling, and I'll find a Name for it."),
      findsNothing,
    );
  });

  testWidgets('the question surface still submits into the provider',
      (t) async {
    // The seam Wave 2 left as a `debugPrint`: the surface's `onSubmit` has to
    // actually reach `submitDailyAnswer`, or `/muhasabah` stays the dead end
    // this wave exists to close.
    final notifier = await pumpScreen(
      t,
      const DailyLoopState(loaded: true, currentStep: DailyLoopStep.checkin),
    );

    expect(find.byType(DailyQuestionPrompt), findsOneWidget);

    await t.enterText(find.byType(TextField), 'my mind will not stop racing');
    await t.pump();
    await t.tap(find.text('Continue'));
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    // The reveal lands the screen on the check-in result, whose TourAnchor
    // arms a 500ms VisibilityDetector timer. Drain it rather than leave a
    // pending timer behind the disposed tree.
    await t.pump(const Duration(seconds: 1));

    expect(notifier.state.checkinAnswers, ['my mind will not stop racing'],
        reason: 'the answer reached the provider, not a debugPrint');
    expect(notifier.state.checkinProblemCategory, 'anxiety');
  });
}

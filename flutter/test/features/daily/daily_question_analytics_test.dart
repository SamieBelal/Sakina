// W4 Wave 7 — the daily question's within-wave funnel.
//
// W4 ships alongside the paywall wave, and the One Ship's keep read is a
// pre/post comparison with no control arm — so at T0+6wk we will know whether
// the ship worked and NOT which half did it. This funnel is the only way to
// find out whether the question itself carried its weight, which is why it is
// pinned this closely.
//
// What this suite holds:
//
//   1. `check_in_completed` is EXTENDED, never forked — `path` stays
//      `'discover'` and the question arrives as two new properties.
//   2. Every new event fires exactly once, with the right props.
//   3. `daily_question_skipped` and `daily_question_abandoned` are DISTINCT.
//      The difference between "people want this later" and "people don't want
//      this" is the entire readout for the defer design.
//   4. **The verbatim answer appears in no event payload, on any path.**
//   5. The buckets are right at their boundaries — an off-by-one in a bucket is
//      invisible in a dashboard and permanent in the data.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/widgets/daily_question_chip.dart';
import 'package:sakina/features/daily/widgets/daily_question_defer_link.dart';
import 'package:sakina/features/daily/widgets/daily_question_prompt.dart';
import 'package:sakina/features/daily/widgets/daily_question_submit_button.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/daily_question_analytics.dart';
import 'package:sakina/services/daily_usage_service.dart' as daily_usage;
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/fake_supabase_sync_service.dart';

class _FreeUser extends PurchaseService {
  _FreeUser() : super.test();
  @override
  Future<bool> isPremium() async => false;
}

/// One captured emit, flattened so a test can assert on the whole payload at
/// once — which is what makes the privacy check below total rather than
/// per-property.
typedef _Emit = ({String event, Map<String, dynamic> props});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  // =========================================================================
  // Buckets — the only two things about an answer that leave the device.
  // =========================================================================

  group('charCountBucket', () {
    test('is correct on both sides of every boundary', () {
      // Boundaries are inclusive-upper, exactly as the names read.
      expect(charCountBucket(1), '1_20');
      expect(charCountBucket(20), '1_20');
      expect(charCountBucket(21), '21_60');
      expect(charCountBucket(60), '21_60');
      expect(charCountBucket(61), '61_140');
      expect(charCountBucket(140), '61_140');
      expect(charCountBucket(141), '141_300');
      expect(charCountBucket(300), '141_300');
      expect(charCountBucket(301), '301_plus');
      expect(charCountBucket(5000), '301_plus');
    });

    test('degrades rather than throwing on lengths that cannot happen', () {
      // Empty is refused by both the surface and the provider, so this is
      // unreachable — a metric helper is still the wrong place to throw.
      expect(charCountBucket(0), '0');
      expect(charCountBucket(-1), '0');
    });
  });

  group('dwellMsBucket', () {
    test('is correct on both sides of every boundary', () {
      // Boundaries are exclusive-upper: `0_2s` is [0, 2000).
      expect(dwellMsBucket(0), '0_2s');
      expect(dwellMsBucket(1999), '0_2s');
      expect(dwellMsBucket(2000), '2_5s');
      expect(dwellMsBucket(4999), '2_5s');
      expect(dwellMsBucket(5000), '5_15s');
      expect(dwellMsBucket(14999), '5_15s');
      expect(dwellMsBucket(15000), '15_60s');
      expect(dwellMsBucket(59999), '15_60s');
      expect(dwellMsBucket(60000), '60s_plus');
    });

    test('a clock that went backwards floors at the first bucket', () {
      expect(dwellMsBucket(-1), '0_2s');
    });
  });

  // =========================================================================
  // entry_source — the widget path must stay separable from day-open.
  // =========================================================================

  group('questionEntrySourceFor', () {
    test('reads the three wire values', () {
      expect(questionEntrySourceFor({'entry': 'widget'}), questionEntryWidget);
      expect(
          questionEntrySourceFor({'entry': 'home_cta'}), questionEntryHomeCta);
      expect(
          questionEntrySourceFor({'entry': 'day_open'}), questionEntryDayOpen);
    });

    test('untagged is day_open — the app brought the user here', () {
      // Every in-app push tags itself (pinned by
      // daily_question_entry_source_test.dart), so absence is the day-open
      // path, which routes with a bare `go('/muhasabah')`.
      expect(questionEntrySourceFor(const {}), questionEntryDayOpen);
      expect(questionEntrySourceFor({'other': 'x'}), questionEntryDayOpen);
    });

    test('an unrecognised value degrades instead of reaching Mixpanel', () {
      // The prop is a closed set of three; a fourth value would quietly break
      // every segment built on it.
      expect(questionEntrySourceFor({'entry': 'nonsense'}),
          questionEntryDayOpen);
    });
  });

  // =========================================================================
  // The auto-entry guard.
  // =========================================================================

  group('the once-per-local-day auto-entry guard', () {
    test('passes on the first show of the day', () {
      expect(
        () => DailyQuestionAnalytics.debugAssertFirstAutoEntryToday(
            null, '2026-08-04'),
        returnsNormally,
      );
      expect(
        () => DailyQuestionAnalytics.debugAssertFirstAutoEntryToday(
            '2026-08-03', '2026-08-04'),
        returnsNormally,
      );
    });

    test('trips when auto-entry throws the question twice in one local day',
        () {
      expect(
        () => DailyQuestionAnalytics.debugAssertFirstAutoEntryToday(
            '2026-08-04', '2026-08-04'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('is scoped to day_open, and that is deliberate', () async {
      // The literal invariant — "`daily_question_shown` never fires twice in
      // one local day" — is false in normal use: a metered re-roll calls
      // `resetToday()` and legitimately re-shows the question from the home
      // CTA, and a user who backs out and taps their widget again gets a
      // second, correct, `widget` show. An assert that fires during ordinary
      // use is an assert that gets deleted. What it actually protects is spec
      // M2's auto-entry rule, and day-open is the only entry the app initiates
      // on the user's behalf.
      SharedPreferences.setMockInitialValues({});
      final fake = FakeSupabaseSyncService(userId: 'user-guard');
      SupabaseSyncService.debugSetInstance(fake);
      addTearDown(SupabaseSyncService.debugReset);
      debugResetUserLocalDay();
      debugUserTimeZoneOverride = 'UTC';
      addTearDown(debugResetUserLocalDay);
      DailyQuestionAnalytics.debugShownClock = () => DateTime.utc(2026, 8, 4, 9);
      addTearDown(() => DailyQuestionAnalytics.debugShownClock = null);

      await DailyQuestionAnalytics.debugCheckAutoEntryOncePerLocalDay(
          questionEntryDayOpen);
      // Two more of a DIFFERENT source on the same day: not the bug, not
      // checked, and they must not poison the marker either.
      await DailyQuestionAnalytics.debugCheckAutoEntryOncePerLocalDay(
          questionEntryHomeCta);
      await DailyQuestionAnalytics.debugCheckAutoEntryOncePerLocalDay(
          questionEntryWidget);

      await expectLater(
        DailyQuestionAnalytics.debugCheckAutoEntryOncePerLocalDay(
            questionEntryDayOpen),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  // =========================================================================
  // The surface's three events.
  // =========================================================================

  group('the question surface', () {
    late List<_Emit> emitted;

    setUp(() {
      emitted = [];
      DailyQuestionAnalytics.onAnalyticsEvent =
          (event, props) => emitted.add((event: event, props: props));
    });

    tearDown(() => DailyQuestionAnalytics.onAnalyticsEvent = null);

    List<_Emit> of(String event) =>
        emitted.where((e) => e.event == event).toList();

    Widget host({String entrySource = questionEntryHomeCta}) => MaterialApp(
          home: DailyQuestionPrompt(
            entrySource: entrySource,
            commitBeat: Duration.zero,
            onSubmit: (_, {String? chipKey}) {},
            onDefer: () {},
          ),
        );

    testWidgets('mounting is the show, once, with its entry_source',
        (t) async {
      await t.pumpWidget(host(entrySource: questionEntryWidget));
      await t.pumpAndSettle();

      expect(of(AnalyticsEvents.dailyQuestionShown), hasLength(1));
      expect(of(AnalyticsEvents.dailyQuestionShown).single.props, {
        AnalyticsEvents.propEntrySource: questionEntryWidget,
      });
    });

    testWidgets('"Not right now" is a SKIP, never an abandon', (t) async {
      await t.pumpWidget(host());
      await t.pumpAndSettle();

      await t.tap(find.byType(DailyQuestionDeferLink));
      await t.pumpAndSettle();

      expect(of(AnalyticsEvents.dailyQuestionSkipped), hasLength(1));
      expect(
        of(AnalyticsEvents.dailyQuestionSkipped)
            .single
            .props[AnalyticsEvents.propDwellMsBucket],
        isA<String>(),
      );
      // The whole readout depends on these two never being conflated.
      expect(of(AnalyticsEvents.dailyQuestionAbandoned), isEmpty);

      // And it stays a skip after the route unwinds.
      await t.pumpWidget(const MaterialApp(home: SizedBox()));
      await t.pumpAndSettle();
      expect(of(AnalyticsEvents.dailyQuestionAbandoned), isEmpty);
      expect(of(AnalyticsEvents.dailyQuestionSkipped), hasLength(1));
    });

    testWidgets('leaving without deciding is an ABANDON, never a skip',
        (t) async {
      await t.pumpWidget(host());
      await t.pumpAndSettle();

      await t.pumpWidget(const MaterialApp(home: SizedBox()));
      await t.pumpAndSettle();

      expect(of(AnalyticsEvents.dailyQuestionAbandoned), hasLength(1));
      expect(of(AnalyticsEvents.dailyQuestionSkipped), isEmpty);
    });

    testWidgets('backgrounding without deciding abandons, and only once',
        (t) async {
      // Not covered by dispose: the route stays mounted, and if the OS reaps
      // the app from the background dispose never runs at all. Leaving it to
      // dispose would undercount the most likely way someone bails.
      await t.pumpWidget(host());
      await t.pumpAndSettle();

      // The real iOS sequence, which the framework asserts on: the intermediate
      // states must not report anything — `hidden` is the first that counts as
      // gone, and firing on `inactive` would abandon on every notification
      // banner and control-centre pull.
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await t.pump();
      expect(of(AnalyticsEvents.dailyQuestionAbandoned), isEmpty);

      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      expect(of(AnalyticsEvents.dailyQuestionAbandoned), hasLength(1));

      // Resumed, then navigated away: still one abandon for one show.
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      await t.pumpWidget(const MaterialApp(home: SizedBox()));
      await t.pumpAndSettle();
      expect(of(AnalyticsEvents.dailyQuestionAbandoned), hasLength(1));
    });

    testWidgets('a typed answer does not abandon when the reveal replaces it',
        (t) async {
      await t.pumpWidget(host());
      await t.pumpAndSettle();

      await t.enterText(find.byType(TextField), 'everything feels heavy');
      await t.pump();
      await t.tap(find.byType(DailyQuestionSubmitButton));
      await t.pumpAndSettle();

      // The reveal replaces the question a frame later.
      await t.pumpWidget(const MaterialApp(home: SizedBox()));
      await t.pumpAndSettle();

      expect(of(AnalyticsEvents.dailyQuestionAbandoned), isEmpty);
      expect(of(AnalyticsEvents.dailyQuestionSkipped), isEmpty);
    });

    testWidgets('a chip answer does not abandon either', (t) async {
      await t.pumpWidget(host());
      await t.pumpAndSettle();

      await t.tap(find.byType(DailyQuestionChip).first);
      await t.pumpAndSettle();
      await t.pumpWidget(const MaterialApp(home: SizedBox()));
      await t.pumpAndSettle();

      expect(of(AnalyticsEvents.dailyQuestionAbandoned), isEmpty);
    });

    testWidgets('NOTHING the user typed is in any surface payload', (t) async {
      const secret = 'my marriage is falling apart and I cannot say it aloud';
      await t.pumpWidget(host());
      await t.pumpAndSettle();

      await t.enterText(find.byType(TextField), secret);
      await t.pump();
      await t.tap(find.byType(DailyQuestionDeferLink));
      await t.pumpAndSettle();
      await t.pumpWidget(const MaterialApp(home: SizedBox()));
      await t.pumpAndSettle();

      expect(emitted, isNotEmpty);
      for (final e in emitted) {
        expect(e.props.toString(), isNot(contains('marriage')));
        expect(e.props.toString(), isNot(contains(secret)));
      }
    });
  });

  // =========================================================================
  // The provider's two events, and the one it extends.
  // =========================================================================

  group('the provider', () {
    final nowUtc = DateTime.utc(2026, 8, 4, 3, 0);
    late FakeSupabaseSyncService fakeSync;
    late List<_Emit> emitted;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fakeSync = FakeSupabaseSyncService(userId: 'user-1');
      SupabaseSyncService.debugSetInstance(fakeSync);
      PurchaseService.debugSetOverride(_FreeUser());
      await hydrateTokenCache(balance: 100, totalSpent: 0);
      debugResetUserLocalDay();
      debugUserTimeZoneOverride = 'UTC';
      debugDailyLoopClock = () => nowUtc;
      fakeSync.rpcHandlers['claim_daily_reward'] = (_) async => {
            'current_day': 3,
            'last_claim_date': '2026-08-04',
            'token_balance': 115,
          };
      emitted = [];
      DailyLoopNotifier.onAnalyticsEvent =
          (event, props) => emitted.add((event: event, props: props));
    });

    tearDown(() {
      debugDailyLoopClock = () => DateTime.now().toUtc();
      debugResetUserLocalDay();
      daily_usage.debugDailyUsageClock = null;
      DailyLoopNotifier.onAnalyticsEvent = null;
      SupabaseSyncService.debugReset();
      PurchaseService.debugClearOverride();
    });

    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 20));

    List<_Emit> of(String event) =>
        emitted.where((e) => e.event == event).toList();

    test('daily_question_answered carries the category, mode and a BUCKET',
        () async {
      final notifier = DailyLoopNotifier();
      addTearDown(notifier.dispose);
      await settle();

      await notifier.submitDailyAnswer('everything feels so heavy lately');
      await settle();

      expect(of(AnalyticsEvents.dailyQuestionAnswered), hasLength(1));
      expect(of(AnalyticsEvents.dailyQuestionAnswered).single.props, {
        AnalyticsEvents.propProblemCategory: 'heavy',
        AnalyticsEvents.propInputMode: inputModeTyped,
        // 31 characters.
        AnalyticsEvents.propCharCountBucket: '21_60',
      });
    });

    test('a chip answer reports input_mode chip', () async {
      final notifier = DailyLoopNotifier();
      addTearDown(notifier.dispose);
      await settle();

      await notifier.submitDailyAnswer("I can't put it into words",
          chipKey: 'sign');
      await settle();

      final props = of(AnalyticsEvents.dailyQuestionAnswered).single.props;
      expect(props[AnalyticsEvents.propInputMode], inputModeChip);
      expect(props[AnalyticsEvents.propProblemCategory], 'unspoken');
    });

    test('an empty answer emits nothing at all', () async {
      final notifier = DailyLoopNotifier();
      addTearDown(notifier.dispose);
      await settle();

      await notifier.submitDailyAnswer('   ');
      await settle();

      expect(emitted, isEmpty);
    });

    test('check_in_completed is EXTENDED, not forked', () async {
      final notifier = DailyLoopNotifier();
      addTearDown(notifier.dispose);
      await settle();

      await notifier.submitDailyAnswer('everything feels so heavy lately');
      await settle();

      final checkIn = of(AnalyticsEvents.checkInCompleted);
      expect(checkIn, hasLength(1));
      // `path` is the D1/D7 retention spine. Changing it to `'feeling'` — as
      // the original Phase-2 prescription proposed — breaks every historical
      // comparison built on this event.
      expect(checkIn.single.props['path'], 'discover');
      expect(checkIn.single.props[AnalyticsEvents.propProblemCategory],
          'heavy');
      expect(checkIn.single.props[AnalyticsEvents.propInputMode],
          inputModeTyped);
      // Still the event it always was.
      expect(checkIn.single.props.containsKey('name'), isTrue);
      expect(checkIn.single.props.containsKey('tier_changed'), isTrue);
    });

    test('daily_reward_claimed fires once at submit, and not on a replay',
        () async {
      final notifier = DailyLoopNotifier();
      addTearDown(notifier.dispose);
      await settle();

      await notifier.submitDailyAnswer('everything feels so heavy lately');
      await settle();

      expect(of(AnalyticsEvents.dailyRewardClaimed), hasLength(1));
      expect(of(AnalyticsEvents.dailyRewardClaimed).single.props, {
        AnalyticsEvents.propTrigger: AnalyticsEvents.triggerAnswerSubmit,
      });

      // A second submit is refused by the re-entry guard; even if the claim
      // did run again it is idempotent, and an idempotent replay grants
      // nothing and must not be counted.
      await notifier.submitDailyAnswer('and again');
      await settle();
      expect(of(AnalyticsEvents.dailyRewardClaimed), hasLength(1));
    });

    test('an already-claimed ladder day grants nothing and counts nothing',
        () async {
      fakeSync.rpcHandlers['claim_daily_reward'] = (_) async => {
            'already_claimed': true,
            'current_day': 3,
            'last_claim_date': '2026-08-04',
            'token_balance': 115,
          };
      final notifier = DailyLoopNotifier();
      addTearDown(notifier.dispose);
      await settle();

      await notifier.submitDailyAnswer('everything feels so heavy lately');
      await settle();

      expect(of(AnalyticsEvents.dailyRewardClaimed), isEmpty,
          reason: 'the event counts grants, not calls — counting replays '
              'would inflate the claim rate exactly where we are trying to '
              'see whether the re-timing preserved it');
      // The rest of the funnel is unaffected.
      expect(of(AnalyticsEvents.dailyQuestionAnswered), hasLength(1));
    });

    test('THE ANSWER TEXT REACHES NO EVENT PAYLOAD, on any provider path',
        () async {
      // The single most important assertion in this file. The user's own words
      // about what is on their heart are the most sensitive thing this app
      // holds: they go to the reflection engine because that is the product,
      // and they go nowhere else.
      const secret = 'I have been drinking again and nobody knows';
      final notifier = DailyLoopNotifier();
      addTearDown(notifier.dispose);
      await settle();

      await notifier.submitDailyAnswer(secret);
      await settle();
      await notifier.completeDeeper();
      await settle();

      expect(emitted, isNotEmpty);
      for (final e in emitted) {
        final payload = e.props.toString();
        expect(payload, isNot(contains(secret)),
            reason: '${e.event} carried the verbatim answer');
        // Not just the whole string — no fragment of it either, which is what
        // a truncation or a "first N characters" prop would leave behind.
        for (final word in ['drinking', 'nobody', 'knows']) {
          expect(payload, isNot(contains(word)),
              reason: '${e.event} carried "$word" from the answer');
        }
      }
      // And it really did travel to the place it is supposed to.
      expect(notifier.state.checkinAnswers, [secret]);
    });
  });
}

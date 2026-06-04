import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/referrals/widgets/referral_nudge_card.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/referral_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Fake service — overrides only the methods the card touches. Records share
/// calls and whether the Supabase referral read was attempted (for the perf
/// short-circuit assertion). Mirrors my_referrals_screen_test's fake.
class _FakeReferralService extends ReferralService {
  _FakeReferralService() : super(_StubSupabase());

  MyReferralsState? nextState;
  bool getStateCalled = false;
  final List<String> shareCalls = [];

  @override
  Future<MyReferralsState> getMyReferralsState(String userId) async {
    getStateCalled = true;
    return nextState!;
  }

  @override
  Future<void> ensureReferralCode(String userId) async {}

  @override
  Future<String?> getMyReferralCode(String userId) async => 'ABCD2345';

  @override
  Future<void> shareMyCode(
    BuildContext context,
    String code, {
    Future<void> Function(String)? override,
  }) async {
    shareCalls.add(code);
    if (override != null) await override(code);
  }
}

class _StubSupabase extends Fake implements SupabaseClient {}

/// Overrides the single RC reader the gate depends on. `startedAt == null`
/// models "no active RC premium"; a past date models a subscriber past grace.
class _FakePurchaseService extends PurchaseService {
  _FakePurchaseService(this.startedAt) : super.test();
  final DateTime? startedAt;

  @override
  Future<DateTime?> getActivePremiumStartedAt() async => startedAt;
}

class _SpyAnalytics extends AnalyticsService {
  final List<({String event, Map<String, dynamic>? properties})> events = [];
  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    events.add((event: event, properties: properties));
  }
}

MyReferralsState _state({
  int confirmedCount = 1,
  List<MyReferralGrant> grants = const [],
}) {
  return MyReferralsState(
    code: 'ABCD2345',
    confirmedCount: confirmedCount,
    grants: grants,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late _SpyAnalytics analytics;
  late _FakeReferralService fakeRef;

  // Fixed "now" 5 days after premium began → comfortably past the 2-day grace.
  final now = DateTime.utc(2026, 6, 10, 12);
  final pastGrace = now.subtract(const Duration(days: 5));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    analytics = _SpyAnalytics();
    fakeRef = _FakeReferralService();
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  Widget harness() {
    return ProviderScope(
      overrides: [
        analyticsProvider.overrideWithValue(analytics),
        referralServiceProvider.overrideWithValue(fakeRef),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ReferralNudgeCard(clock: () => now),
        ),
      ),
    );
  }

  int shownCount() => analytics.events
      .where((e) => e.event == AnalyticsEvents.homeReferralNudgeShown)
      .length;

  testWidgets('renders zero-height + skips the Supabase query when not premium',
      (tester) async {
    PurchaseService.debugSetOverride(_FakePurchaseService(null));
    fakeRef.nextState = _state();

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.textContaining('Send to friends'), findsNothing);
    expect(tester.getSize(find.byType(ReferralNudgeCard)), Size.zero);
    expect(shownCount(), 0);
    // Perf short-circuit: a non-premium user never hits Supabase.
    expect(fakeRef.getStateCalled, isFalse);
  });

  testWidgets('shows the card + fires shown once on the happy path',
      (tester) async {
    PurchaseService.debugSetOverride(_FakePurchaseService(pastGrace));
    fakeRef.nextState = _state(confirmedCount: 1);

    await tester.pumpWidget(harness());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Send to friends · 1/3 joined'), findsOneWidget);
    expect(find.text('Send a dua to 3 friends'), findsOneWidget);
    expect(shownCount(), 1);
    expect(
      analytics.events
          .firstWhere((e) => e.event == AnalyticsEvents.homeReferralNudgeShown)
          .properties?['progress'],
      1,
    );
    // lastShown prefs persisted.
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(fakeSync.scopedKey(ReferralNudgeCard.lastShownBaseKey)),
      isNotNull,
    );
  });

  testWidgets('hidden when a grant has already been earned', (tester) async {
    PurchaseService.debugSetOverride(_FakePurchaseService(pastGrace));
    fakeRef.nextState = _state(
      confirmedCount: 3,
      grants: [
        MyReferralGrant(
          grantedAt: now.subtract(const Duration(days: 1)),
          expiresAt: now.add(const Duration(days: 29)),
          cardTier: 'gold',
        ),
      ],
    );

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.textContaining('Send to friends'), findsNothing);
    expect(shownCount(), 0);
  });

  testWidgets('hidden when progress is already 3/3', (tester) async {
    PurchaseService.debugSetOverride(_FakePurchaseService(pastGrace));
    fakeRef.nextState = _state(confirmedCount: 3); // grants empty, progress=3

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.textContaining('Send to friends'), findsNothing);
  });

  testWidgets('tapping the CTA shares the code + fires share_tapped',
      (tester) async {
    PurchaseService.debugSetOverride(_FakePurchaseService(pastGrace));
    fakeRef.nextState = _state(confirmedCount: 1);

    await tester.pumpWidget(harness());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Send to friends · 1/3 joined'));
    await tester.pumpAndSettle();

    expect(fakeRef.shareCalls, ['ABCD2345']);
    expect(
      analytics.events.where(
          (e) => e.event == AnalyticsEvents.homeReferralNudgeShareTapped),
      hasLength(1),
    );
  });

  testWidgets('tapping dismiss collapses the card + persists + fires dismissed',
      (tester) async {
    PurchaseService.debugSetOverride(_FakePurchaseService(pastGrace));
    fakeRef.nextState = _state(confirmedCount: 1);

    await tester.pumpWidget(harness());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Send to friends'), findsNothing);
    expect(
      analytics.events
          .where((e) => e.event == AnalyticsEvents.homeReferralNudgeDismissed),
      hasLength(1),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getInt(fakeSync.scopedKey(ReferralNudgeCard.lastProgressBaseKey)),
      1,
    );
  });
}

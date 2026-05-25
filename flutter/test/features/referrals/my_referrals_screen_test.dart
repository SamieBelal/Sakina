import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/features/referrals/screens/my_referrals_screen.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/referral_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Spy fake — overrides only the methods MyReferralsScreen exercises. Per-
/// test we set [nextState] (returned by getMyReferralsState) and the screen
/// renders against it. shareMyCode is recorded for the share assertion.
/// Follows the _FakeReferralService pattern from
/// test/widgets/referral_code_field_test.dart.
class _FakeReferralService extends ReferralService {
  _FakeReferralService() : super(_StubSupabase());

  MyReferralsState? nextState;
  Object? nextThrow;
  final List<String> shareCalls = [];

  @override
  Future<MyReferralsState> getMyReferralsState(String userId) async {
    if (nextThrow != null) throw nextThrow!;
    return nextState!;
  }

  @override
  Future<void> ensureReferralCode(String userId) async {
    // no-op; the screen calls this before getMyReferralsState.
  }

  @override
  Future<void> shareMyCode(
    BuildContext context,
    String code, {
    Future<void> Function(String)? override,
  }) async {
    shareCalls.add(code);
    if (override != null) {
      await override(code);
    }
  }
}

/// Minimal SupabaseClient stand-in. Never invoked because the fake overrides
/// every method the screen touches.
class _StubSupabase extends Fake implements SupabaseClient {}

class _TrackingSpy extends AnalyticsService {
  final List<(String, Map<String, dynamic>?)> tracked = [];
  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event, properties));
  }
}

MyReferralGrant _grant({required int daysAgo}) {
  final granted = DateTime.now().subtract(Duration(days: daysAgo));
  return MyReferralGrant(
    grantedAt: granted,
    expiresAt: granted.add(const Duration(days: 30)),
    cardTier: 'gold',
  );
}

/// Pumps the screen, then immediately seeds state via the visible-for-
/// testing seam. The first build renders the loader (Supabase isn't
/// initialized in tests, so the post-frame _load() bails); we then call
/// debugSeedState to mirror what the production path does post-load.
Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeReferralService fake,
  required _TrackingSpy analytics,
  required MyReferralsState state,
}) async {
  // Generous viewport so the grants list + empty-state footer don't push the
  // share button below the visible bounds (default 800x600 chops the layout).
  await tester.binding.setSurfaceSize(const Size(420, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // SubpageHeader calls context.canPop() which requires a GoRouter ancestor.
  // Wrap with a 2-route router so the screen renders without throwing.
  final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(
        path: '/start',
        builder: (_, __) => Scaffold(
          body: Center(
            child: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ctx.push('/sub'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/sub',
        builder: (_, __) => const MyReferralsScreen(),
      ),
    ],
  );

  await tester.pumpWidget(ProviderScope(
    overrides: [
      referralServiceProvider.overrideWithValue(fake),
      analyticsProvider.overrideWithValue(analytics),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  // First frame — initState scheduled the post-frame callback.
  await tester.pump();
  // Drain the post-frame _load() which bails because Supabase isn't init'd.
  await tester.pump();
  // Seed state directly to simulate a successful load.
  final state0 = tester.state(find.byType(MyReferralsScreen));
  // ignore: invalid_use_of_visible_for_testing_member
  (state0 as dynamic).debugSeedState(state);
  await tester.pump();
}

void main() {
  group('MyReferralsScreen', () {
    testWidgets('empty state — 0 confirmed, no grants', (tester) async {
      final fake = _FakeReferralService();
      final spy = _TrackingSpy();
      await _pumpScreen(
        tester,
        fake: fake,
        analytics: spy,
        state: const MyReferralsState(
          code: 'ABCD2EFG',
          confirmedCount: 0,
          grants: [],
        ),
      );

      expect(find.text('0 of 3 friends joined'), findsOneWidget);
      expect(
        find.textContaining("No one's joined yet"),
        findsOneWidget,
      );
      expect(find.text('Share your code'), findsOneWidget);
      expect(find.text('ABCD2EFG'), findsOneWidget);
      // myReferralsShown event fired with properties.
      final shown = spy.tracked
          .where((e) => e.$1 == AnalyticsEvents.myReferralsShown)
          .toList();
      expect(shown.length, 1);
      expect(shown.first.$2, containsPair('confirmed_count', 0));
      expect(shown.first.$2, containsPair('grants_count', 0));
    });

    testWidgets('2/3 progress — 2 filled dots, 1 hollow', (tester) async {
      final fake = _FakeReferralService();
      final spy = _TrackingSpy();
      await _pumpScreen(
        tester,
        fake: fake,
        analytics: spy,
        state: const MyReferralsState(
          code: 'ABCD2EFG',
          confirmedCount: 2,
          grants: [],
        ),
      );

      expect(find.text('2 of 3 friends joined'), findsOneWidget);
      // Empty-state footer should NOT appear (confirmedCount > 0).
      expect(find.textContaining("No one's joined yet"), findsNothing);
      // Rewards earned section should not appear when grants is empty.
      expect(find.text('Rewards earned'), findsNothing);
    });

    testWidgets(
        'reward earned + reset progress — confirmed=3 grants=[gold @ today]',
        (tester) async {
      final fake = _FakeReferralService();
      final spy = _TrackingSpy();
      await _pumpScreen(
        tester,
        fake: fake,
        analytics: spy,
        state: MyReferralsState(
          code: 'ABCD2EFG',
          confirmedCount: 3,
          grants: [_grant(daysAgo: 0)],
        ),
      );

      expect(find.text('0 of 3 friends joined'), findsOneWidget);
      expect(find.text('Rewards earned'), findsOneWidget);
      expect(find.text('30 days + Gold card'), findsOneWidget);
      expect(find.text('Earned today'), findsOneWidget);
      // The post-grant caption flips to the "last reward active until..." copy.
      expect(
        find.textContaining('Your last reward is active until'),
        findsOneWidget,
      );
    });

    testWidgets('multi-grant — confirmed=7, grants=[today, -30d]',
        (tester) async {
      final fake = _FakeReferralService();
      final spy = _TrackingSpy();
      await _pumpScreen(
        tester,
        fake: fake,
        analytics: spy,
        state: MyReferralsState(
          code: 'ABCD2EFG',
          confirmedCount: 7,
          grants: [_grant(daysAgo: 0), _grant(daysAgo: 30)],
        ),
      );

      // 7 confirmed - 2 grants * 3 = 1 toward next.
      expect(find.text('1 of 3 friends joined'), findsOneWidget);
      // Both grant rows render — find by the "30 days + Gold card" label.
      expect(find.text('30 days + Gold card'), findsNWidgets(2));
      // Newest first — "Earned today" for grant 0, "Earned" + month for grant 1.
      expect(find.text('Earned today'), findsOneWidget);
    });

    testWidgets('tap-to-copy fires analytics + snackbar + clipboard',
        (tester) async {
      final fake = _FakeReferralService();
      final spy = _TrackingSpy();
      // Mock the platform clipboard channel so Clipboard.setData doesn't
      // throw in the test environment, and we can assert the written value.
      final clipboardWrites = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          final args = call.arguments as Map<dynamic, dynamic>;
          clipboardWrites.add(args['text'] as String);
        }
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await _pumpScreen(
        tester,
        fake: fake,
        analytics: spy,
        state: const MyReferralsState(
          code: 'ABCD2EFG',
          confirmedCount: 0,
          grants: [],
        ),
      );

      // Tap the code text — it sits inside an InkWell on the code card.
      await tester.tap(find.text('ABCD2EFG'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(clipboardWrites, ['ABCD2EFG']);
      expect(find.text('Code copied'), findsOneWidget);
      expect(
        spy.tracked.where((e) => e.$1 == AnalyticsEvents.myReferralsCodeCopied),
        isNotEmpty,
      );
    });

    testWidgets('share button calls referralService.shareMyCode + analytics',
        (tester) async {
      final fake = _FakeReferralService();
      final spy = _TrackingSpy();
      await _pumpScreen(
        tester,
        fake: fake,
        analytics: spy,
        state: const MyReferralsState(
          code: 'ABCD2EFG',
          confirmedCount: 0,
          grants: [],
        ),
      );

      await tester.tap(find.text('Share your code'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fake.shareCalls, ['ABCD2EFG']);
      expect(
        spy.tracked
            .where((e) => e.$1 == AnalyticsEvents.myReferralsShareTapped),
        isNotEmpty,
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/gifts/widgets/ramadan_gift_card.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/gift_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/widgets/adjusted_arabic_display.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Spy analytics. The project's analyticsProvider default is a no-op
/// `AnalyticsService` (Mixpanel never initialized); we subclass it here
/// rather than introducing a new fake type so the gift card's calls
/// behave exactly as production but become observable in tests.
class _SpyAnalytics extends AnalyticsService {
  final List<({String event, Map<String, dynamic>? properties})> events = [];

  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    events.add((event: event, properties: properties));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late _SpyAnalytics analytics;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    analytics = _SpyAnalytics();
    GiftService.debugGiftClock = () => DateTime.utc(2027, 2, 20);
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    GiftService.debugGiftClock = () => DateTime.now().toUtc();
  });

  Widget buildHarness(Widget child) {
    return ProviderScope(
      overrides: [
        analyticsProvider.overrideWithValue(analytics),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets(
      'renders zero-height during loading (no 220px flash), then transitions '
      'to pre-claim card', (tester) async {
    fakeSync.publicRows['islamic_occasions'] = [
      {
        'id': 'ramadan_2027',
        'starts_at': '2027-02-17T00:00:00.000Z',
        'ends_at': '2027-03-19T23:59:59.000Z',
      },
    ];

    await tester.pumpWidget(buildHarness(const RamadanGiftCard()));

    // First frame (loading state): widget collapses to SizedBox.shrink so
    // the home dashboard doesn't reflow on every cold launch outside an
    // occasion window. The RamadanGiftCard itself paints zero pixels and
    // shows none of its content.
    expect(find.text('Accept your gift'), findsNothing);
    expect(find.byType(AdjustedArabicDisplay), findsNothing);
    expect(tester.getSize(find.byType(RamadanGiftCard)), Size.zero);

    // Let resolve() complete. Pump once for the microtask + post-frame
    // callback chain that `_resolve()` schedules, then settle the pre-claim
    // card's flutter_animate fadeIn (400ms).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Pre-claim card visible.
    expect(find.text('Accept your gift'), findsOneWidget);
    expect(find.text('A gift from Sakina for Ramadan'), findsOneWidget);
    expect(find.byType(AdjustedArabicDisplay), findsOneWidget);

    // ramadan_gift_shown analytics fired with occasion_id.
    expect(
      analytics.events.where((e) => e.event == AnalyticsEvents.ramadanGiftShown),
      hasLength(1),
    );
    expect(
      analytics.events
          .firstWhere((e) => e.event == AnalyticsEvents.ramadanGiftShown)
          .properties?['occasion_id'],
      'ramadan_2027',
    );
  });

  testWidgets(
      'renders "مولد مبارك" (not "عيد مبارك") for Mawlid occasions',
      (tester) async {
    // Mawlid an-Nabi 1448 AH ≈ 2026-09-04 (approximate; the seed migration
    // owns the canonical window). We pick a clock inside the seeded window.
    fakeSync.publicRows['islamic_occasions'] = [
      {
        'id': 'mawlid_2026',
        'starts_at': '2026-09-01T00:00:00.000Z',
        'ends_at': '2026-09-07T23:59:59.000Z',
      },
    ];
    GiftService.debugGiftClock = () => DateTime.utc(2026, 9, 4);

    await tester.pumpWidget(buildHarness(const RamadanGiftCard()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Accept your gift'), findsOneWidget);
    expect(find.text('A gift from Sakina for Mawlid'), findsOneWidget);

    // Mawlid Mubarak — NOT Eid Mubarak. Some Islamic schools regard
    // celebrating Mawlid as bid'ah and do not consider it an Eid.
    expect(find.text('مولد مبارك'), findsOneWidget);
    expect(find.text('عيد مبارك'), findsNothing);
  });

  testWidgets('renders nothing when clock is outside every occasion window',
      (tester) async {
    fakeSync.publicRows['islamic_occasions'] = [
      {
        'id': 'ramadan_2027',
        'starts_at': '2027-02-17T00:00:00.000Z',
        'ends_at': '2027-03-19T23:59:59.000Z',
      },
    ];
    GiftService.debugGiftClock = () => DateTime.utc(2027, 4, 15);

    await tester.pumpWidget(buildHarness(const RamadanGiftCard()));
    await tester.pumpAndSettle();

    expect(find.text('Accept your gift'), findsNothing);
    // The widget is collapsed to SizedBox.shrink — no gift-specific text.
    expect(
      analytics.events.where((e) => e.event == AnalyticsEvents.ramadanGiftShown),
      isEmpty,
    );
  });

  testWidgets('tapping Accept transitions to post-claim status row', (tester) async {
    fakeSync.publicRows['islamic_occasions'] = [
      {
        'id': 'ramadan_2027',
        'starts_at': '2027-02-17T00:00:00.000Z',
        'ends_at': '2027-03-19T23:59:59.000Z',
      },
    ];
    fakeSync.rpcHandlers['claim_sakina_gift'] = (_) async => {
          'granted': true,
          'granted_at': '2027-02-20T10:00:00.000Z',
          'expires_at': '2027-02-27T10:00:00.000Z',
          'reused': false,
        };

    await tester.pumpWidget(buildHarness(const RamadanGiftCard()));
    await tester.pumpAndSettle();

    expect(find.text('Accept your gift'), findsOneWidget);
    await tester.tap(find.text('Accept your gift'));
    await tester.pumpAndSettle();

    expect(find.text('Accept your gift'), findsNothing);
    expect(
      find.textContaining('Your Sakina gift is active until'),
      findsOneWidget,
    );

    // ramadan_gift_claimed analytics fired with reused=false.
    final claimed = analytics.events
        .firstWhere((e) => e.event == AnalyticsEvents.ramadanGiftClaimed);
    expect(claimed.properties?['occasion_id'], 'ramadan_2027');
    expect(claimed.properties?['reused'], isFalse);

    // SharedPreferences cache populated.
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(fakeSync.scopedKey(giftPremiumUntilPrefsBaseKey)),
      '2027-02-27T10:00:00.000Z',
    );
  });

  testWidgets(
      'cached expiry in the future short-circuits to post-claim status row',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      fakeSync.scopedKey(giftPremiumUntilPrefsBaseKey):
          '2027-02-27T10:00:00.000Z',
    });
    fakeSync.publicRows['islamic_occasions'] = [
      {
        'id': 'ramadan_2027',
        'starts_at': '2027-02-17T00:00:00.000Z',
        'ends_at': '2027-03-19T23:59:59.000Z',
      },
    ];

    await tester.pumpWidget(buildHarness(const RamadanGiftCard()));
    // Pump for resolve() microtasks, then settle the post-claim status
    // row's flutter_animate fadeIn (300ms).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Post-claim wins over pre-claim — the user has already accepted.
    expect(find.text('Accept your gift'), findsNothing);
    expect(
      find.textContaining('Your Sakina gift is active until'),
      findsOneWidget,
    );
    // ramadan_gift_shown should NOT fire when we land on post-claim — the
    // card never showed the "Accept" surface this session.
    expect(
      analytics.events.where((e) => e.event == AnalyticsEvents.ramadanGiftShown),
      isEmpty,
    );
  });
}

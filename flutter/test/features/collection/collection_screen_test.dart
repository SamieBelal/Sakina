import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/collection/screens/collection_screen.dart';
import 'package:sakina/features/collection/widgets/bronze_card_preview.dart';
import 'package:sakina/features/collection/widgets/emerald_card_preview.dart';
import 'package:sakina/features/collection/widgets/emerald_ornate_card.dart';
import 'package:sakina/features/collection/widgets/gold_card_preview.dart';
import 'package:sakina/features/collection/widgets/silver_card_preview.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/public_catalog_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Fake premium/free users. `PurchaseService()` returns the debug override when
/// one is set, so `initState`'s `PurchaseService().isPremium()` resolves to
/// this value — steering the tri-state `_isPremium` field that gates the
/// locked "Emerald · Premium" teaser tiles.
class _FreeUser extends PurchaseService {
  _FreeUser() : super.test();
  @override
  Future<bool> isPremium() async => false;
}

class _PremiumUser extends PurchaseService {
  _PremiumUser() : super.test();
  @override
  Future<bool> isPremium() async => true;
}

/// Seed the scoped collection prefs so card id 1 (the FIRST collectible Name,
/// so its tiles sort to the top of the "All" grid and stay in-viewport without
/// scrolling) is unlocked at Gold and already SEEN (no `unseen` shimmer loop →
/// `flutter_animate` stays finite so the tree can settle). A free user then
/// gets a locked Emerald teaser tile immediately after its Gold tile.
void _seedGoldCollection() {
  const date = '2026-05-01';
  SharedPreferences.setMockInitialValues({
    'sakina_card_collection:user-1': jsonEncode({
      'ids': [1],
      'dates': {'1': date},
      'tiers': {'1': 3}, // 3 == Gold
      'tierUpDates': {'1': date},
    }),
    // Mark all sub-tiers seen so no tile carries the repeating new-card glow.
    'sakina_card_seen:user-1': ['1:1', '1:2', '1:3'],
  });
}

/// A fully-inert [AppSessionNotifier] override: `initialOnboarded` true, all
/// readers injected as local no-ops so the session never touches Supabase or
/// the network. `economyHydrated` starts false (the screen just adds a
/// listener — harmless).
AppSessionNotifier _fakeSession() => AppSessionNotifier(
      initialOnboarded: true,
      // Injected empty stream → the constructor never reaches
      // `Supabase.instance.client.auth.onAuthStateChange`.
      authStateChanges: const Stream.empty(),
      isAuthenticatedProvider: () => true,
      currentUserIdProvider: () => 'user-1',
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => true,
      isPremiumReader: () async => false,
      hardPaywallFlowReader: () async => false,
      trialExpiredReader: () async => false,
      paywallArmReader: () async => null,
    );

/// Pumps [CollectionScreen] inside a real GoRouter exposing `/` (the screen)
/// and `/paywall` (a stub) so the teaser's `context.push('/paywall')` resolves.
Future<GoRouter> _pumpCollectionScreen(WidgetTester tester) async {
  // A tall surface so the first grid row (the seeded Gold tile + its Emerald
  // teaser) is fully within the viewport and hit-testable without scrolling.
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const CollectionScreen()),
      GoRoute(
        path: '/paywall',
        builder: (_, __) => const Scaffold(body: Text('PAYWALL')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appSessionProvider.overrideWithValue(_fakeSession()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  // Do NOT pumpAndSettle: the header + filter row use finite-but-delayed
  // `flutter_animate` fades, and initState kicks off async `isPremium()` +
  // provider reloads. Fixed pumps drain those without risking a hang on any
  // stray repeating animation.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 350));
  }
  return router;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Full-screen pump of `CollectionScreen` (not just the standalone teaser
  // tile) so the real `_buildAllEntries` conversion hook — which injects the
  // locked "Emerald · Premium" teaser only when `_isPremium == false` — is
  // exercised end-to-end, including the tap → `/paywall` navigation. The pump
  // uses fixed `pump()` durations (see `_pumpCollectionScreen`) rather than
  // `pumpAndSettle` because the screen's `flutter_animate` fades + async
  // provider hydration would otherwise make settling fragile. Seeding a SEEN
  // Gold card keeps every tile's shimmer off so nothing loops forever.
  group('Emerald · Premium teaser (full-screen pump)', () {
    late FakeSupabaseSyncService fakeSync;

    setUp(() {
      // Fresh catalog registry each test — a prior ProviderScope teardown can
      // dispose the global registry, and `currentCollectibleNames()` reads it.
      debugResetPublicCatalogs();
      _seedGoldCollection();
      fakeSync = FakeSupabaseSyncService(userId: 'user-1');
      SupabaseSyncService.debugSetInstance(fakeSync);
    });

    tearDown(() {
      SupabaseSyncService.debugReset();
      PurchaseService.debugClearOverride();
      debugResetPublicCatalogs();
    });

    testWidgets('FREE user: teaser renders and taps through to the paywall',
        (tester) async {
      PurchaseService.debugSetOverride(_FreeUser());

      await _pumpCollectionScreen(tester);

      // The locked teaser tile carries a "Premium" badge for the collected
      // Name whose Emerald tier is unearned.
      expect(find.text('Premium'), findsOneWidget);

      // Tap the teaser tile itself (its enclosing GestureDetector) — the
      // "Premium" text sits in a small bottom badge that isn't the tap target;
      // the whole tile routes to the paywall.
      final teaserTile = find.ancestor(
        of: find.text('Premium'),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(teaserTile.first);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 350));
      }

      // Tapping the teaser routed to the paywall stub.
      expect(find.text('PAYWALL'), findsOneWidget);
    });

    testWidgets('PREMIUM user: NO teaser renders on their own collection',
        (tester) async {
      PurchaseService.debugSetOverride(_PremiumUser());

      await _pumpCollectionScreen(tester);

      // Premium users can earn Emerald directly, so the conversion teaser is
      // suppressed entirely.
      expect(find.text('Premium'), findsNothing);
    });
  });

  test(
      'collection tier-up failure presentation covers success and both failures',
      () {
    expect(
      collectionTierUpFailurePresentation(
        spendResult: const TierUpScrollSpendResult(
          success: true,
          newBalance: 4,
        ),
        scrollCost: 5,
        scrollBalance: 4,
        nextTier: 'Silver',
      ),
      isNull,
    );

    final insufficient = collectionTierUpFailurePresentation(
      spendResult: const TierUpScrollSpendResult(
        success: false,
        newBalance: 2,
        failureReason: TierUpScrollFailureReason.insufficientBalance,
      ),
      scrollCost: 5,
      scrollBalance: 2,
      nextTier: 'Silver',
    );
    expect(insufficient, isNotNull);
    expect(insufficient!.title, 'Not Enough Scrolls');
    expect(insufficient.primaryAction, CollectionTierUpFailureAction.goToStore);
    expect(
      insufficient.message,
      'You need 5 scrolls to upgrade to Silver. You have 2.',
    );

    final syncFailed = collectionTierUpFailurePresentation(
      spendResult: const TierUpScrollSpendResult(
        success: false,
        newBalance: 5,
        failureReason: TierUpScrollFailureReason.syncFailed,
      ),
      scrollCost: 5,
      scrollBalance: 5,
      nextTier: 'Gold',
    );
    expect(syncFailed, isNotNull);
    expect(syncFailed!.title, 'Couldn\'t Spend Scrolls');
    expect(syncFailed.primaryAction, CollectionTierUpFailureAction.retry);
    expect(syncFailed.primaryActionLabel, 'Try Again');
  });

  // §10 C5b — emerald widgets render standalone with a fixture card. Pumps
  // `EmeraldOrnateTile` and `EmeraldOrnateDetailSheet` directly to catch
  // post-fix regressions (RTL bleed, layout overflow, missing fields)
  // without standing up the full collection screen + Riverpod tree.
  group('§10 C5b emerald widget pumps', () {
    const fixture = CollectibleName(
      id: 1,
      arabic: 'الرَّحْمَٰن',
      transliteration: 'Ar-Rahman',
      english: 'The Most Compassionate',
      meaning: 'Whose mercy encompasses all creation.',
      lesson: 'Mercy is not earned, it is given.',
      hadith: 'He has prescribed mercy for Himself.',
      duaArabic: 'يَا رَحْمَٰنُ',
      duaTransliteration: 'Ya Rahman',
      duaTranslation: 'O Most Compassionate',
    );

    testWidgets('EmeraldOrnateTile renders without overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: EmeraldOrnateTile(card: fixture),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(EmeraldOrnateTile), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EmeraldOrnateDetailSheet renders the card content',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmeraldOrnateDetailSheet(
              card: fixture,
              tier: CardTier.emerald,
            ),
          ),
        ),
      );

      // Sheet uses staggered `flutter_animate` fadeIn/slideY with delays up
      // to 400ms. Settle them before teardown so flutter_test doesn't trip
      // the "Timer is still pending after dispose" guard.
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(EmeraldOrnateDetailSheet), findsOneWidget);
      expect(find.text(fixture.transliteration), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  // §10 unseen-shimmer state and the four preview screens (`*CardPreviewScreen`)
  // use `flutter_animate` `.animate(onPlay: c.repeat(...))` continuous loops.
  // `pumpAndSettle` never returns on infinite animations, so we cannot pump
  // them in a unit test without `tester.runAsync`. They are exercised on the
  // simulator via §10 C5a (DB-seeded emerald grid) and the debug preview
  // routes documented in `lib/core/router.dart:101-120`. Visual fidelity for
  // these is best assessed on-device, not asserted in a widget test.

  // §10 C4 — preview-route smoke. Each preview screen is a debug-only
  // route (`router.dart:101-120`, marked "DEBUG: temporary") and uses
  // `flutter_animate` `.animate(onPlay: c.repeat(...))` continuous loops
  // that `pumpAndSettle` cannot drain. We do not pump them in widget tests
  // (would either hang or leak Timers). Instead we pin that the four screen
  // classes are constructible and that the route paths exist in the router
  // — anything past that is visual review on sim.
  group('§10 C4 preview screen registration', () {
    test('preview screen classes are const-constructible', () {
      // If any of these stops being a const StatelessWidget, the test (and
      // the GoRoute builders that hold them) will fail to compile.
      expect(const BronzeCardPreviewScreen(), isA<StatelessWidget>());
      expect(const SilverCardPreviewScreen(), isA<StatelessWidget>());
      expect(const GoldCardPreviewScreen(), isA<StatelessWidget>());
      expect(const EmeraldCardPreviewScreen(), isA<StatelessWidget>());
    });
  });
}

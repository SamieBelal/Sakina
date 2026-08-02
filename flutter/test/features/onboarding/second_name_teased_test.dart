import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:sakina/features/daily/widgets/card_reveal_overlay.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/features/onboarding/screens/onboarding_reveal_screen.dart';
import 'package:sakina/features/onboarding/widgets/sealed_name_tease.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/name_stories_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_flow.dart';

import '../../support/fake_supabase_sync_service.dart';
import 'screens/_test_utils.dart';

/// A [SharedPreferencesStorePlatform] that always fails a read — simulates a
/// plugin-channel error (disk I/O failure, isolate death mid-call) rather than
/// a merely-empty store.
class _ThrowingSharedPreferencesStore extends InMemorySharedPreferencesStore {
  _ThrowingSharedPreferencesStore() : super.empty();

  @override
  Future<Map<String, Object>> getAll() async =>
      throw StateError('simulated shared_preferences failure');
}

/// `second_name_teased` (W6 Wave B / W3 §9) — the promise the seven-day queue
/// is made of. Fires from the onboarding reveal screen's own static hook,
/// latched (mirrors `kindledFired`'s reasoning) so a re-mount cannot re-fire
/// it: one tease per user, ever.
///
/// Mirrors `onboarding_reveal_screen_test.dart`'s harness exactly (the real
/// shipped decks, no fixtures — the per-kind field mapping is what the deck
/// content actually is).
void main() {
  const anxietyPair = [6, 35]; // As-Salam (Name₁) + Al-Wakeel (Name₂)

  late List<({String name, Map<String, Object?> props})> events;

  NameStoriesService stories() => NameStoriesService(
        loadAsset: (_) async =>
            File(NameStoriesService.assetPath).readAsStringSync(),
      );

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    events = [];
    OnboardingRevealScreen.onAnalyticsEvent =
        (name, props) => events.add((name: name, props: props));
    // Every reveal run now consults a persisted, user-scoped flag before
    // firing `second_name_teased` — a real prefs store (scoped to 'u1' unless
    // a test overrides it) so the existing tests exercise that path too, not
    // just the ones added for it.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u1'));
  });

  tearDown(() {
    OnboardingRevealScreen.onAnalyticsEvent = null;
    SupabaseSyncService.debugReset();
  });

  Future<void> pumpReveal(
    WidgetTester tester, {
    List<int> pair = anxietyPair,
    String? contract,
    OnboardingRevealLatch? latch,
  }) async {
    useOnboardingViewport(tester);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: OnboardingRevealScreen(
          pairNameIds: pair,
          stories: stories(),
          contract: contract,
          latch: latch,
          loaderBeat: Duration.zero,
          showFirstRunHint: false,
          onDone: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> walkToLastBeat(WidgetTester tester) async {
    final size = tester.getSize(find.byType(BeatRevealFlow));
    while (find.text('Ameen').evaluate().isEmpty) {
      await tester.tapAt(Offset(size.width * 0.8, size.height * 0.5));
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapAmeenThroughToTease(WidgetTester tester) async {
    await walkToLastBeat(tester);
    await tester.tap(find.text('Ameen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));
    tester
        .widget<CardRevealOverlay>(find.byType(CardRevealOverlay))
        .onContinue!();
    await tester.pumpAndSettle();
  }

  testWidgets('fires once, carrying Name₂ (not Name₁), deck_id and contract',
      (tester) async {
    await pumpReveal(tester, contract: HookContract.problem);
    await tapAmeenThroughToTease(tester);

    expect(find.byType(SealedNameTease), findsOneWidget);

    final teased = events
        .where((e) => e.name == AnalyticsEvents.secondNameTeased)
        .toList();
    expect(teased, hasLength(1));
    expect(teased.single.props[AnalyticsEvents.propNameId], 35);
    expect(teased.single.props[AnalyticsEvents.propDeckId], isNotEmpty);
    expect(teased.single.props[AnalyticsEvents.propNameId], isNot(6),
        reason: 'must carry Name₂, not the _emit helper\'s default Name₁');
    expect(
        teased.single.props[AnalyticsEvents.propContract], HookContract.problem);
    expect(teased.single.props[AnalyticsEvents.propSurface],
        AnalyticsEvents.surfaceOnboardingReveal);
  });

  testWidgets('null contract omits the key rather than emitting null',
      (tester) async {
    await pumpReveal(tester); // no contract passed
    await tapAmeenThroughToTease(tester);

    final teased = events
        .where((e) => e.name == AnalyticsEvents.secondNameTeased)
        .single;
    expect(teased.props.containsKey(AnalyticsEvents.propContract), isFalse);
  });

  testWidgets(
      // MUTATION: remove the `_latch.secondNameTeasedFired` guard in
      // `_scheduleSecondNameTeased` (or call the emit directly from `build()`
      // instead of scheduling it once) — this must fail: `build()` re-runs on
      // every rebuild while the tease is on screen, unlike `_onAmeen` (which
      // guards itself via `_latch.completed` and can't be re-entered at all).
      'a parent rebuild while the tease is on screen does not re-fire',
      (tester) async {
    await pumpReveal(tester);
    await tapAmeenThroughToTease(tester);
    expect(find.byType(SealedNameTease), findsOneWidget);
    expect(
      events.where((e) => e.name == AnalyticsEvents.secondNameTeased),
      hasLength(1),
    );

    // Same shape as the deckless-tease "hands back exactly once, not per
    // frame" regression this file already guards against for `_finish`: a
    // fresh (non-const) widget at the SAME tree position reconciles onto the
    // existing State (`didUpdateWidget`, not a re-mount) and re-runs `build`.
    await pumpReveal(tester);
    await tester.pump();
    await pumpReveal(tester);
    await tester.pump();

    expect(
      events.where((e) => e.name == AnalyticsEvents.secondNameTeased),
      hasLength(1),
      reason: 'one tease per user, ever',
    );
  });

  testWidgets('a deckless Name₂ (comfort pair also fails) never teases',
      (tester) async {
    // Empty catalog: no Name₁ at all, so the in-canvas error shows and Ameen
    // is unreachable — the tease can never fire.
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: OnboardingRevealScreen(
          pairNameIds: const [6, 35],
          stories: NameStoriesService(loadAsset: (_) async => '[]'),
          loaderBeat: Duration.zero,
          showFirstRunHint: false,
          onDone: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining("couldn't prepare"), findsOneWidget);
    expect(
      events.where((e) => e.name == AnalyticsEvents.secondNameTeased),
      isEmpty,
    );
    // Let flutter_animate's staggered timers elapse before teardown.
    await tester.pump(const Duration(seconds: 1));
  });

  group('process-kill persistence (P1: the latch is durably persisted)', () {
    // Onboarding page position is durably persisted (SharedPreferences), so a
    // process kill anywhere on the reveal page — including AFTER the tease
    // already fired — restores a brand-new State, a fresh in-memory latch, and
    // replays the whole deck. Without a persisted flag, `_scheduleSecondNameTeased`
    // fires again on that fresh, unset latch. `docs`: "one tease per user,
    // ever" must survive a kill, not just a rebuild.

    testWidgets(
        // MUTATION: revert the persisted-flag check in
        // `_scheduleSecondNameTeased`'s post-frame callback back to relying
        // solely on `_latch.secondNameTeasedFired` (i.e. make the latch
        // process-lifetime only again) — this must fail: a fresh mount always
        // gets a fresh, unset in-memory latch, so nothing stops the replay.
        'a fresh mount after a simulated kill does not re-fire',
        (tester) async {
      // Simulates the tease having already fired in a prior process for this
      // same user: the durable flag is present before the screen ever mounts.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'onboarding_reveal_second_name_teased:u1': true,
      });

      // A brand-new State + a brand-new (unset) latch — exactly what a killed
      // and relaunched app produces, since Wave E's latch does not itself
      // survive process death.
      await pumpReveal(tester);
      await tapAmeenThroughToTease(tester);
      expect(find.byType(SealedNameTease), findsOneWidget);
      // The post-frame callback awaits a prefs read; flush it.
      await tester.pump();
      await tester.pump();

      expect(
        events.where((e) => e.name == AnalyticsEvents.secondNameTeased),
        isEmpty,
        reason: 'already teased in a prior process — never again',
      );
    });

    testWidgets('a same-session rebuild still does not re-fire (no kill)',
        (tester) async {
      // No pre-seeded flag: this is the ordinary first-ever tease, confirming
      // the persistence work did not disturb the existing rebuild guard.
      await pumpReveal(tester);
      await tapAmeenThroughToTease(tester);
      await tester.pump();
      await tester.pump();
      expect(
        events.where((e) => e.name == AnalyticsEvents.secondNameTeased),
        hasLength(1),
      );

      await pumpReveal(tester);
      await tester.pump();
      await pumpReveal(tester);
      await tester.pump();

      expect(
        events.where((e) => e.name == AnalyticsEvents.secondNameTeased),
        hasLength(1),
      );
    });

    testWidgets('a genuinely different user on the same device still teases',
        (tester) async {
      // u1's flag is set (as if u1 already saw their tease on this shared QA
      // device), but the mount below is for u2 — the scoped key must not
      // collide.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'onboarding_reveal_second_name_teased:u1': true,
      });
      SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u2'));

      await pumpReveal(tester);
      await tapAmeenThroughToTease(tester);
      await tester.pump();
      await tester.pump();

      expect(
        events.where((e) => e.name == AnalyticsEvents.secondNameTeased),
        hasLength(1),
        reason: "u2 has never been teased — u1's flag must not block it",
      );
    });

    testWidgets('a prefs read that throws does not break the reveal',
        (tester) async {
      SharedPreferencesStorePlatform.instance =
          _ThrowingSharedPreferencesStore();

      await pumpReveal(tester);
      await tapAmeenThroughToTease(tester);
      expect(find.byType(SealedNameTease), findsOneWidget);
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}

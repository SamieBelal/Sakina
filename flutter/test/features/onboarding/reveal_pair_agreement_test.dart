import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/content/aspirations.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/onboarding_reveal_screen.dart';
import 'package:sakina/features/onboarding/screens/queue_plan_screen.dart';
import 'package:sakina/features/onboarding/widgets/queue_name_row.dart';
import 'package:sakina/features/onboarding/widgets/sealed_name_tease.dart';
import 'package:sakina/features/daily/widgets/card_reveal_overlay.dart';
import 'package:sakina/services/auth_service.dart';
import 'package:sakina/services/card_collection_service.dart' show CardTier;
import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/name_stories_service.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';
import 'screens/_test_utils.dart';

/// One Ship W2 review P2-2 — the four consumers of the pair agree, even when
/// the hook resolved a pair that only LOOKS valid.
///
/// A length-2 pair whose Name₂ no approved deck teaches (a `sakina://reel`
/// link's `name_ids`, an id retired from the decks) sends the reveal to the
/// comfort pair without ever touching `pairNameIds`. Before `setRevealedPair`,
/// the reveal and the plan screen showed the comfort pair while the starter
/// card and the seeded queue were still resolved from the hook's — so a user's
/// day-0 collection contradicted the queue they had just been promised.
///
/// The four: what the reveal SHOWED, the card `seedStarterCard` writes, the head
/// of the queue `seed_name_queue` gets, and the rows the plan screen names.
class _RecordingAuthService extends AuthService {
  int? seededNameId;
  CardTier? seededTier;
  int? persistedStarterNameId;

  @override
  bool get isSignedIn => true;

  @override
  Future<void> saveOnboardingData({
    String? displayName,
    String? intention,
    String? familiarity,
    List<String> attribution = const [],
    String? ageRange,
    String? prayerFrequency,
    int? starterNameId,
    List<String> duaTopics = const [],
    String? duaTopicsOther,
    int? dailyCommitmentMinutes,
    String? reminderTime,
    bool commitmentAccepted = false,
    Map<String, dynamic>? acquisitionPromise,
    String? firstProblemText,
    String? onboardingFlow,
  }) async {
    persistedStarterNameId = starterNameId;
  }

  @override
  Future<void> seedStarterCard(int nameId, {CardTier tier = CardTier.bronze}) async {
    seededNameId = nameId;
    seededTier = tier;
  }

  @override
  Future<void> markOnboardingCompleted() async {}
}

class _RecordingNameQueueService extends NameQueueService {
  List<int>? seededIds;

  @override
  Future<bool> seedIfEmpty(List<int> nameIds) async {
    seededIds = nameIds;
    return true;
  }
}

class _FakeNotificationService extends NotificationService {
  @override
  Future<void> logout() async {}
  @override
  Future<void> identifyUser(String userId) async {}
  @override
  Future<void> syncTimezone() async {}
  @override
  Future<void> requestPermissionIfPreviouslyEnabled() async {}
}

void main() {
  /// Name₁ has an approved deck; nothing teaches 999. Two ids long, so every
  /// `pair.length == 2` check upstream of the reveal is satisfied.
  const junkPair = [6, 999];

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  NameStoriesService stories() => NameStoriesService(
        loadAsset: (_) async =>
            File(NameStoriesService.assetPath).readAsStringSync(),
      );

  ProblemChipResolver resolver() => ProblemChipResolver(stories: stories());

  AppSessionNotifier buildSession() => AppSessionNotifier(
        initialOnboarded: false,
        authStateChanges: const Stream.empty(),
        isAuthenticatedProvider: () => true,
        currentUserIdProvider: () => 'user-1',
        hydrateEconomyCache: () async {},
        hasCompletedOnboarding: () async => true,
        isPremiumReader: () async => false,
        hardPaywallFlowReader: () async => false,
        notificationService: _FakeNotificationService(),
      );

  /// Drives the real reveal screen to completion and returns what it showed.
  Future<OnboardingRevealResult> runReveal(
    WidgetTester tester,
    List<int> pairNameIds,
  ) async {
    useOnboardingViewport(tester);
    final done = <OnboardingRevealResult>[];
    await tester.pumpWidget(MaterialApp(
      home: OnboardingRevealScreen(
        pairNameIds: pairNameIds,
        stories: stories(),
        loaderBeat: Duration.zero,
        showFirstRunHint: false,
        onDone: done.add,
      ),
    ));
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(BeatRevealFlow));
    while (find.text('Ameen').evaluate().isEmpty) {
      await tester.tapAt(Offset(size.width * 0.8, size.height * 0.5));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Ameen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));
    tester
        .widget<CardRevealOverlay>(find.byType(CardRevealOverlay))
        .onContinue!();
    await tester.pumpAndSettle();
    await tester.tap(find.text(SealedNameTease.continueLabel));
    await tester.pumpAndSettle();

    // The screen must have been torn down before the test ends, or the tease's
    // animations outlive it.
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
    return done.single;
  }

  testWidgets('a junk length-2 pair: reveal, card, queue and plan all agree',
      (tester) async {
    final comfort = await resolver().pairNameIdsForChip(comfortChipKey);
    expect(comfort, hasLength(2), reason: 'the ship gate guarantees a pair');

    // 1 — what the reveal SHOWED. Name₂ has no deck, so both halves fall back.
    final revealed = await runReveal(tester, junkPair);
    expect([revealed.name1Id, revealed.name2Id], comfort);

    final auth = _RecordingAuthService();
    final queue = _RecordingNameQueueService();
    final container = ProviderContainer(overrides: [
      authServiceProvider.overrideWithValue(auth),
    ]);
    addTearDown(container.dispose);

    final notifier = OnboardingNotifier(
      authService: auth,
      nameQueueService: queue,
      chipResolver: resolver(),
    )
      ..setOnboardingFlow(onboardingFlowReel)
      ..applyHookSelection(const ChipSelection(
        contract: HookContract.problem,
        problemCategory: 'anxiety',
        hookType: HookType.chip,
        chipKey: 'anxiety',
        pairNameIds: junkPair,
      ))
      ..setAspiration('peace')
      // …the Wave E call site, which is what makes the other three agree.
      ..setRevealedPair([revealed.name1Id, revealed.name2Id!]);

    await notifier.completeOnboarding(buildSession());

    // 2 — the card the user owns on day 0.
    expect(auth.seededNameId, comfort.first);
    expect(auth.seededTier, CardTier.silver);
    expect(auth.persistedStarterNameId, comfort.first);

    // 3 — the head of the seeded queue.
    expect(queue.seededIds!.take(2), comfort);
    expect(queue.seededIds, [...comfort, ...aspirationQueueNameIds('peace')]);

    // 4 — the rows the plan screen names.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: QueuePlanScreen(
            onNext: () {},
            revealedPairNameIds: [revealed.name1Id, revealed.name2Id!],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final id in comfort) {
      expect(
        find.text(QueuePlanScreen.collectibleNameById(id)!.transliteration),
        findsOneWidget,
        reason: 'the plan screen names the pair the queue will hold',
      );
    }
    expect(find.text(QueueNameRow.metLabel), findsOneWidget);
    expect(
      find.text(QueuePlanScreen.collectibleNameById(junkPair.first)!
          .transliteration),
      findsNothing,
      reason: 'the hook pair was never shown to this user',
    );
  });

  test('setRevealedPair is what resolvePairNameIds now prefers', () async {
    final notifier = OnboardingNotifier(
      authService: _RecordingAuthService(),
      nameQueueService: _RecordingNameQueueService(),
      chipResolver: resolver(),
    )
      ..setOnboardingFlow(onboardingFlowReel)
      ..applyHookSelection(const ChipSelection(
        contract: HookContract.problem,
        problemCategory: 'anxiety',
        hookType: HookType.chip,
        chipKey: 'anxiety',
        pairNameIds: junkPair,
      ));

    // Before the reveal reports back, the hook's pair is all there is.
    expect(await notifier.resolvePairNameIds(), junkPair);

    notifier.setRevealedPair(const [2, 36]);
    expect(await notifier.resolvePairNameIds(), [2, 36]);
    expect(await notifier.buildQueueNameIds(), [2, 36]);
  });

  test('a half pair is ignored — it would seed a queue the RPC rejects',
      () async {
    final notifier = OnboardingNotifier(chipResolver: resolver())
      ..setOnboardingFlow(onboardingFlowReel)
      ..applyHookSelection(const ChipSelection(
        contract: HookContract.problem,
        problemCategory: 'anxiety',
        hookType: HookType.chip,
        chipKey: 'anxiety',
        pairNameIds: [6, 35],
      ))
      ..setRevealedPair(const [2]);

    expect(notifier.state.revealedPairNameIds, isEmpty);
    expect(await notifier.resolvePairNameIds(), [6, 35]);
  });

  test('the revealed pair round-trips through prefs with the rest of v8', () {
    // An app kill between the reveal and completion must resume against the
    // Names the user actually met.
    const state = OnboardingState(
      pairNameIds: [6, 999],
      revealedPairNameIds: [2, 36],
    );

    final restored = OnboardingState.fromJson(state.toJson());

    expect(restored.revealedPairNameIds, [2, 36]);
    expect(restored.pairNameIds, [6, 999]);
  });
}

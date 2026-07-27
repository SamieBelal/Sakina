import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/content/aspirations.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/auth_service.dart';
import 'package:sakina/services/card_collection_service.dart' show CardTier;
import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/name_stories_service.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

// One Ship W2-C2 — the completion chain's ORDER, which is the whole fix.
//
// Two review findings live here:
//   * 8a — the prefs wipe must land AFTER the server writes. Wiping first
//     meant a crash mid-completion restarted onboarding from a blank slate,
//     resolving a fresh Name₁ against a queue the server had already frozen.
//   * 5 — the queue seed must run once auth exists and before the completion
//     flag, and a seed failure must not abort the rest of the chain (the
//     screen-level caller swallows throws, so an escape here would skip
//     `markOnboardingCompleted` and `markOnboarded`).

/// Records the step order AND, at every server write, whether the local
/// onboarding blob was still in prefs at that moment.
class _RecordingAuthService extends AuthService {
  _RecordingAuthService(this.log, {this.stateStillStored});

  final List<String> log;
  final void Function(String step, bool stored)? stateStillStored;
  int? seededNameId;
  CardTier? seededTier;

  Future<void> _note(String step) async {
    log.add(step);
    final prefs = await SharedPreferences.getInstance();
    stateStillStored?.call(step, prefs.getString('onboarding_state') != null);
  }

  @override
  bool get isSignedIn => true;

  int? persistedStarterNameId;

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
    await _note('persist');
  }

  @override
  Future<void> seedStarterCard(
    int nameId, {
    CardTier tier = CardTier.bronze,
  }) async {
    seededNameId = nameId;
    seededTier = tier;
    await _note('seedCard');
  }

  @override
  Future<void> markOnboardingCompleted() => _note('markCompleted');
}

class _RecordingNameQueueService extends NameQueueService {
  _RecordingNameQueueService(this.log, {this.error, this.stateStillStored});

  final List<String> log;
  final Object? error;
  final void Function(String step, bool stored)? stateStillStored;
  List<int>? seededIds;

  @override
  Future<bool> seedIfEmpty(List<int> nameIds) async {
    log.add('seedQueue');
    seededIds = nameIds;
    final prefs = await SharedPreferences.getInstance();
    stateStillStored?.call(
        'seedQueue', prefs.getString('onboarding_state') != null);
    if (error != null) throw error!;
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

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

  ProblemChipResolver resolver() => ProblemChipResolver(
        stories: NameStoriesService(
          loadAsset: (_) async =>
              File(NameStoriesService.assetPath).readAsStringSync(),
        ),
      );

  /// A notifier mid-reel-flow: the anxiety pair committed, an aspiration
  /// answered, and prefs already holding the persisted blob.
  Future<
      ({
        OnboardingNotifier notifier,
        _RecordingAuthService auth,
        _RecordingNameQueueService queue,
        List<String> log,
      })> buildReelNotifier({Object? queueError}) async {
    final log = <String>[];
    final auth = _RecordingAuthService(log);
    final queue = _RecordingNameQueueService(log, error: queueError);
    final notifier = OnboardingNotifier(
      authService: auth,
      nameQueueService: queue,
      chipResolver: resolver(),
    );
    notifier.setOnboardingFlow(onboardingFlowReel);
    notifier.applyHookSelection(await resolver().forChip('anxiety'));
    notifier.setAspiration('closeness');
    return (notifier: notifier, auth: auth, queue: queue, log: log);
  }

  Future<String?> storedOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('onboarding_state');
  }

  test('the queue is seeded with the pair then the aspiration\'s five',
      () async {
    final ctx = await buildReelNotifier();

    await ctx.notifier.completeOnboarding(buildSession());

    expect(ctx.queue.seededIds, [
      6, 35, // the anxiety pair — Name₁ met, Name₂ sealed
      ...aspirationsByKey['closeness']!.queueNameIds,
    ]);
    expect(ctx.queue.seededIds, hasLength(7));
    expect(ctx.queue.seededIds!.toSet(), hasLength(7));
  });

  test('the seed runs after the profile persist and before the completion flag',
      () async {
    final ctx = await buildReelNotifier();

    await ctx.notifier.completeOnboarding(buildSession());

    expect(ctx.log.indexOf('seedQueue'), greaterThan(ctx.log.indexOf('persist')),
        reason: 'seeding needs the authed profile row to exist');
    expect(ctx.log.indexOf('seedQueue'),
        lessThan(ctx.log.indexOf('markCompleted')),
        reason: 'the promise must exist before the user counts as onboarded');
  });

  test('the prefs wipe happens after the server writes, not before', () async {
    // A crash anywhere before the last server write must leave the local blob
    // intact, so the retry re-runs against the SAME Name₁ instead of resolving
    // a fresh one against a queue the server has already frozen.
    final storedAt = <String, bool>{};
    void note(String step, bool stored) => storedAt[step] = stored;

    final log = <String>[];
    final notifier = OnboardingNotifier(
      authService: _RecordingAuthService(log, stateStillStored: note),
      nameQueueService:
          _RecordingNameQueueService(log, stateStillStored: note),
      chipResolver: resolver(),
    );
    notifier.setOnboardingFlow(onboardingFlowReel);
    notifier.applyHookSelection(await resolver().forChip('anxiety'));
    notifier.setAspiration('closeness');
    expect(await storedOnboardingState(), isNotNull,
        reason: 'the blob the wipe is supposed to clear');

    await notifier.completeOnboarding(buildSession());

    expect(storedAt, {
      'persist': true,
      'seedCard': true,
      'seedQueue': true,
      'markCompleted': true,
    });
    // …and by the end it IS cleared.
    expect(await storedOnboardingState(), isNull);
  });

  test('the reel flow seeds its starter card at Silver, legacy stays Bronze',
      () async {
    final reel = await buildReelNotifier();
    await reel.notifier.completeOnboarding(buildSession());
    expect(reel.auth.seededNameId, 6, reason: 'Name₁ of the pair');
    expect(reel.auth.seededTier, CardTier.silver);

    final log = <String>[];
    final legacyAuth = _RecordingAuthService(log);
    final legacy = OnboardingNotifier(
      authService: legacyAuth,
      nameQueueService: _RecordingNameQueueService(log),
      chipResolver: resolver(),
    );
    legacy.setOnboardingFlow(onboardingFlowLegacy);
    legacy.setStarterName(3);

    await legacy.completeOnboarding(buildSession());

    expect(legacyAuth.seededNameId, 3);
    expect(legacyAuth.seededTier, CardTier.bronze);
    expect(log, isNot(contains('seedQueue')),
        reason: 'the queue is the reel flow\'s promise; legacy has none');
  });

  test('a seed failure is loud but never aborts the rest of completion',
      () async {
    final ctx = await buildReelNotifier(queueError: StateError('rls denied'));
    final session = buildSession();

    await ctx.notifier.completeOnboarding(session);

    expect(ctx.log, contains('markCompleted'));
    expect(session.hasOnboarded, isTrue);
    expect(await storedOnboardingState(), isNull);
  });

  test('a seed failure emits name_queue_seed_failed with the error class',
      () async {
    // The debugPrint above is invisible in production; this event is the only
    // way to see that a shipped user's promise has nothing behind it.
    final events = <({String name, Map<String, Object?> props})>[];
    OnboardingNotifier.onAnalyticsEvent =
        (name, props) => events.add((name: name, props: props));
    addTearDown(() => OnboardingNotifier.onAnalyticsEvent = null);

    final ctx = await buildReelNotifier(queueError: StateError('rls denied'));

    await ctx.notifier.completeOnboarding(buildSession());

    final failed = events
        .where((e) => e.name == AnalyticsEvents.nameQueueSeedFailed)
        .toList();
    expect(failed, hasLength(1));
    expect(failed.single.props['id_count'], 7);
    expect(failed.single.props['error_class'], 'StateError',
        reason: 'the class, never the raw driver message');
  });

  test('a successful seed emits nothing', () async {
    final events = <String>[];
    OnboardingNotifier.onAnalyticsEvent = (name, _) => events.add(name);
    addTearDown(() => OnboardingNotifier.onAnalyticsEvent = null);

    final ctx = await buildReelNotifier();
    await ctx.notifier.completeOnboarding(buildSession());

    expect(events, isEmpty);
  });

  group('the pair is resolved ONCE for every consumer', () {
    test('an empty-pair reel user gets the comfort pair as BOTH starter and '
        'queue head', () async {
      // The split-resolution bug: the queue opened on Ar-Rahman while the
      // starter card (and `starter_name_id`) stayed null.
      final log = <String>[];
      final auth = _RecordingAuthService(log);
      final queue = _RecordingNameQueueService(log);
      final notifier = OnboardingNotifier(
        authService: auth,
        nameQueueService: queue,
        chipResolver: resolver(),
      );
      notifier.setOnboardingFlow(onboardingFlowReel);
      notifier.setAspiration('peace');

      await notifier.completeOnboarding(buildSession());

      expect(queue.seededIds!.first, 2, reason: 'Ar-Rahman heads the queue');
      expect(auth.seededNameId, 2, reason: '…and is the card the user owns');
      expect(auth.seededTier, CardTier.silver);
    });

    test('the resolved starter reaches the server persist, not just the card',
        () async {
      // Computing the fallback after `saveOnboardingData` left
      // `starter_name_id` null server-side — and the freeze trigger locks it.
      final log = <String>[];
      final auth = _RecordingAuthService(log);
      final notifier = OnboardingNotifier(
        authService: auth,
        nameQueueService: _RecordingNameQueueService(log),
        chipResolver: resolver(),
      );
      notifier.setOnboardingFlow(onboardingFlowReel);
      notifier.applyHookSelection(await resolver().forChip('anxiety'));

      await notifier.completeOnboarding(buildSession());

      expect(auth.persistedStarterNameId, 6);
      expect(notifier.state.starterNameId, 6);
    });

    test('an explicit starter always wins over the pair', () async {
      final log = <String>[];
      final auth = _RecordingAuthService(log);
      final notifier = OnboardingNotifier(
        authService: auth,
        nameQueueService: _RecordingNameQueueService(log),
        chipResolver: resolver(),
      );
      notifier.setOnboardingFlow(onboardingFlowReel);
      notifier.applyHookSelection(await resolver().forChip('anxiety'));
      notifier.setStarterName(3);

      await notifier.completeOnboarding(buildSession());

      expect(auth.seededNameId, 3);
      expect(auth.persistedStarterNameId, 3);
    });
  });

  group('buildQueueNameIds', () {
    test('an unanswered aspiration seeds the pair alone — never an invented '
        'ordering', () async {
      final notifier = OnboardingNotifier(
        authService: _RecordingAuthService([]),
        nameQueueService: _RecordingNameQueueService([]),
        chipResolver: resolver(),
      );
      notifier.setOnboardingFlow(onboardingFlowReel);
      notifier.applyHookSelection(await resolver().forChip('guilt'));

      expect(await notifier.buildQueueNameIds(), [11, 31]);
    });

    test('an unresolved pair falls back to the comfort pair', () async {
      final notifier = OnboardingNotifier(
        authService: _RecordingAuthService([]),
        nameQueueService: _RecordingNameQueueService([]),
        chipResolver: resolver(),
      );
      notifier.setOnboardingFlow(onboardingFlowReel);
      notifier.setAspiration('peace');

      expect(await notifier.buildQueueNameIds(), [
        2, 36, // Ar-Rahman + Al-Lateef
        ...aspirationsByKey['peace']!.queueNameIds,
      ]);
    });
  });

  test('the flow wire values are the ones the server column accepts', () {
    expect(onboardingFlowReel, 'reel_v1');
    expect(onboardingFlowReel, AppSessionNotifier.onboardingFlowReelV1);
    expect(onboardingFlowLegacy, 'legacy');
  });

  test('the persisted state blob round-trips the reel fields it must survive',
      () async {
    final ctx = await buildReelNotifier();
    final raw = await storedOnboardingState();

    final json = jsonDecode(raw!) as Map<String, dynamic>;
    expect(json['pairNameIds'], [6, 35]);
    expect(json['aspiration'], 'closeness');
    expect(json['onboardingFlow'], onboardingFlowReel);
    expect(ctx.notifier.state.contract, HookContract.problem);
  });
}

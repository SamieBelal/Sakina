import 'dart:async';
import 'dart:convert';
import 'dart:ui' show VoidCallback;

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_session.dart';
import '../content/aspirations.dart';
import '../content/help_chips.dart';
import '../content/intake_questions.dart';
import '../content/problem_chips.dart';
import '../../../services/analytics_event_names.dart';
import '../../../services/auth_service.dart';
import '../../../services/card_collection_service.dart' show CardTier;
import '../../../services/launch_gate_service.dart';
import '../../../services/name_queue_service.dart';
import '../../../services/purchase_service.dart';
import '../../../services/referral_service.dart';
import '../../../services/user_data_batch_sync_service.dart';
import '../../quests/providers/quests_provider.dart';

/// `OnboardingState.onboardingFlow` for the reel flow — also the tour
/// suppression key (Wave F) and the `user_profiles.onboarding_flow` value.
///
/// Aliases [OnboardingFlow], which is where [OnboardingNotifier.setOnboardingFlow]
/// validates from. `AppSessionNotifier` (which the router reads, and which
/// cannot import this direction) keeps its own copy; the two are pinned equal by
/// `test/features/onboarding/complete_onboarding_queue_seed_test.dart` — a drift
/// would suppress the tour for nobody while silently marking every profile
/// `reel_v1`.
const String onboardingFlowReel = OnboardingFlow.reelV1;

/// …and for both fallback flows behind the kill switch.
const String onboardingFlowLegacy = OnboardingFlow.legacy;

const _prefsKey = 'onboarding_state';

/// Last index in [OnboardingScreen]'s trimmed PageView. The legacy 27-screen
/// flow lives behind the `onboarding_trim_enabled` app_config flag (Option α
/// dual-flow strategy from 2026-05-25 eng review).
///   * Trimmed flow: 20 children (0..19), paywall at 19 (when rating gate on).
///   * Legacy flow: 27 children (0..26), paywall at 26 (preserved for rollback).
///
/// Trimmed flow indices:
///   0 First check-in, 1 Name, 2 Age, 3 Intention, 4 Prayer,
///   5 Familiarity, 6 Dua topics, 7 Daily commitment, 8 Attribution,
///   9 Reminder time, 10 Notifications, 11 Commitment pact, 12 Social proof,
///   13 Save progress, 14 Email, 15 Password, 16 Generating,
///   17 Personalized plan, 18 Rating gate, 19 Paywall.
const int onboardingLastPageIndex = 19;

/// Legacy 27-screen flow last index. Used when `onboarding_trim_enabled=false`.
const int onboardingLegacyLastPageIndex = 26;

/// Trimmed-flow sign-up email page index.
const int onboardingEmailPageIndex = 14;

/// Trimmed-flow sign-up password page index.
const int onboardingPasswordPageIndex = 15;

/// Where social-auth (Apple/Google) users land after OAuth succeeds in the
/// trimmed flow. Replaces the old `onboardingEncouragementPageIndex` — the
/// Encouragement interstitial was removed; users go straight to Generating.
const int onboardingPostSignupPageIndex = 16;

/// Legacy flow constants (kept for backwards-compat while dual-flow is live).
const int onboardingLegacyEmailPageIndex = 19;
const int onboardingLegacyPasswordPageIndex = 20;
const int onboardingLegacyEncouragementPageIndex = 21;

// ---------------------------------------------------------------------------
// REEL flow (One Ship W2-E1) — the third page order. Default-on behind
// [reelFirstOnboardingFlag]; the two sets above serve the kill switch.
//
//   0 Hook, 1 Reveal, 2 Carrying duration, 3 When heaviest, 4 Told anyone,
//   5 Names known, 6 What would help, 7 Daily time, 8 Note,
//   9 Queue plan, 10 Rating gate, 11 Notifications, 12 Widget offer,
//   13 Source, 14 Name, 15 Save progress, 16 Email, 17 Password,
//   18 Paywall (final gate).
//
// Wave H (2026-07-28) deepened the intake from 3 questions to 7 and moved every
// ASK behind the payoff: the plan screen now lands before the notification,
// widget and source screens rather than after them. "Where did you find us?"
// in particular used to sit at the emotional peak, immediately after Ameen —
// the one screen that gives the user nothing, at the moment they are most open.
//
// The reminder-time page is GONE from the reel order: "When is it heaviest?"
// derives the reminder in the same state mutation, so the answer IS the
// schedule. The kill-switch flows keep their reminder screen untouched.
//
// Value first, account last: the signup trio sits AFTER the reveal and the
// plan, so the user has met a Name and seen their queue before they are asked
// for an address (W2-E2, deferred signup).
// ---------------------------------------------------------------------------

/// app_config kill switch. Fallback **true** — the reel flow is the shipping
/// experience; OFF reproduces today's prod behaviour exactly (trimmed, or
/// legacy when `onboarding_trim_enabled` is also off).
const String reelFirstOnboardingFlag = 'reel_first_onboarding_enabled';

/// Reel-flow last index — the final gate (paywall) at 18.
///
/// 12 → 13 when Wave G inserted the widget offer; 13 → 18 when Wave H added the
/// four new intake questions and re-admitted the rating gate. Every index and
/// segment below moves with it.
const int onboardingReelLastPageIndex = 18;

/// Reel-flow hook screen. No progress bar, no back affordance.
const int onboardingReelHookPageIndex = 0;

/// Reel-flow reveal (deck → Silver card → sealed Name₂). No progress bar.
const int onboardingReelRevealPageIndex = 1;

/// First page from which backing up into the reveal is FORBIDDEN.
///
/// The reveal awards a card and burns its once-per-run latch on "Ameen"; a
/// re-entry would land the user on a deck whose Ameen no longer does anything,
/// and re-answering the hook would resolve a different pair than the card they
/// already own. `OnboardingRevealLatch` is the belt; this is the braces the
/// latch's own doc comment requires.
const int onboardingReelNoBackBeforeIndex = 2;

/// Reel-flow name-input page index. `NameInputScreen` compares its own
/// `pageIndex` against the current page to decide whether to autofocus, so the
/// value has to be the page's REAL index — the literal it replaces was the one
/// thing in the reel list with no name behind it.
const int onboardingReelNamePageIndex = 14;

/// Reel-flow sign-up email page index.
const int onboardingReelEmailPageIndex = 16;

/// Reel-flow sign-up password page index.
const int onboardingReelPasswordPageIndex = 17;

/// Where social-auth (Apple/Google) users land after OAuth succeeds in the reel
/// order: the page after the signup trio, which IS the final gate. Unlike the
/// trimmed flow there is no interstitial left to show them — the plan screen
/// already ran, pre-signup.
const int onboardingReelPostSignupPageIndex = 18;

/// Segments in the reel flow's progress bar.
///
/// Fifteen, not nineteen: the bar is hidden on the hook (spec ③ — a step
/// counter on screen one signals a long form), on the reveal (full-screen
/// sacred canvas), on the rating gate (a gate, not a step), and on the paywall.
/// The fifteen bar-visible pages fill segments 0-14, so the bar COMPLETES on the
/// password screen rather than vanishing part-full.
///
/// Wave G's widget offer and Wave H's four new questions DO carry segments:
/// they are steps and asks, not payoffs.
///
/// **The queue plan joined them on 2026-07-29** (founder), which is what took
/// this from fourteen to fifteen. It had been excluded on the reasoning that a
/// payoff is not a step — but the bar vanishing for one page mid-flow, taking
/// the back circle's chrome with it, read as a broken screen rather than as a
/// deliberate pause. See [onboardingReelPlanSegment].
const int onboardingReelTotalSegments = 15;

/// The queue plan screen's segment (One Ship W2-D2).
///
/// Named rather than inlined because it sits in the middle of the run: every
/// segment after it is this + n, so a future page inserted before the plan has
/// one number to change here and a compile error everywhere it matters.
const int onboardingReelPlanSegment = 7;

/// Which of the three onboarding page orders is active.
///
/// [reel] is the shipping flow; [trimmed] and [legacy] are the two kill-switch
/// fallbacks and behave exactly as they do today.
enum OnboardingFlowKind { reel, trimmed, legacy }

/// Last valid page index for [kind].
int lastPageIndexForFlow(OnboardingFlowKind kind) => switch (kind) {
      OnboardingFlowKind.reel => onboardingReelLastPageIndex,
      OnboardingFlowKind.trimmed => onboardingLastPageIndex,
      OnboardingFlowKind.legacy => onboardingLegacyLastPageIndex,
    };

/// The `user_profiles.onboarding_flow` value [kind] records. Both fallback
/// flows are `legacy` — the column names the EXPERIENCE, and neither fallback
/// is the reel one.
String onboardingFlowValueFor(OnboardingFlowKind kind) =>
    kind == OnboardingFlowKind.reel ? onboardingFlowReel : onboardingFlowLegacy;

class OnboardingState {
  const OnboardingState({
    this.currentPage = 0,
    this.intention,
    this.notificationPermissionGranted = false,
    this.demoFeelingInput,
    this.demoCheckinCompleted = false,
    this.isLoadingDemoResult = false,
    this.familiarity,
    this.attribution = const {},
    this.generateProgress = 0.0,
    this.isSignedUp = false,
    this.authError,
    this.signUpName,
    this.signUpEmail,
    // New in v3:
    this.ageRange,
    this.prayerFrequency,
    this.starterNameId,
    this.duaTopics = const {},
    this.duaTopicsOther,
    this.dailyCommitmentMinutes,
    this.reminderTime,
    this.commitmentAccepted = false,
    this.referralApplyFailedReason,
    // New in v8 (One Ship W2 — the reel flow):
    this.contract,
    this.problemCategory,
    this.chipKey,
    this.problemTextRaw,
    this.pairNameIds = const [],
    this.revealedPairNameIds = const [],
    this.aspiration,
    this.carryingDuration,
    // New in Wave H — the intake set (H2-H7):
    this.heaviestTime,
    this.toldAnyone,
    this.namesKnown,
    this.helpWith = const [],
    this.dailyTime,
    this.intakeNote,
    this.reelSource,
    this.reelId,
    this.reelPairOverride = const [],
    this.hookType,
    this.onboardingFlow,
  });

  final int currentPage;
  final String? intention;
  final bool notificationPermissionGranted;
  final String? demoFeelingInput;
  final bool demoCheckinCompleted;
  final bool isLoadingDemoResult;
  final String? familiarity;
  final Set<String> attribution;
  final double generateProgress;
  final bool isSignedUp;
  final String? authError;
  final String? signUpName;
  final String? signUpEmail;
  final String? ageRange;
  final String? prayerFrequency;
  final int? starterNameId;
  final Set<String> duaTopics;
  final String? duaTopicsOther;
  final int? dailyCommitmentMinutes;
  final String? reminderTime; // "HH:mm" 24h
  final bool commitmentAccepted;

  /// One-shot signal set by sign-up callers (Apple/Google in
  /// SaveProgressScreen, email in SignUpPasswordScreen) when `apply_referral`
  /// returns `ok:false` with reason `invalid` or `self_referral`. The
  /// EncouragementScreen drains it on mount and shows a recovery snackbar
  /// pointing the user at Settings → Redeem. Intentionally NOT persisted to
  /// prefs — it's a transient UI signal. The cold-launch defensive retry in
  /// `app_session.dart` does NOT write this flag, so a stale invalid code
  /// can never surface as a snackbar days after onboarding.
  final String? referralApplyFailedReason;

  // ---- v8: the reel flow's hook + arrival record -------------------------
  // All of these are written pre-auth and must survive an app kill mid-flow,
  // so every one of them round-trips through prefs (deferred signup, W2-E2).

  /// [HookContract.problem] or [HookContract.sign] — what the hook promised.
  final String? contract;

  /// Stable snake_case category behind the chosen chip, or `unmatched`.
  final String? problemCategory;

  /// The taxonomy chip key (`anxiety`, `far-from-allah`, …). Null when free
  /// text matched nothing — the comfort pair still reveals, but no chip is
  /// claimed on the user's behalf.
  final String? chipKey;

  /// Verbatim free text → `user_profiles.first_problem_text`.
  final String? problemTextRaw;

  /// `[name₁, name₂]` resolved from the approved decks at hook time. Persisted
  /// so an app kill after the reveal resumes with the SAME Names.
  final List<int> pairNameIds;

  /// `[name₁, name₂]` as the reveal ACTUALLY showed them — the single source of
  /// truth for the pair once the reveal has run.
  ///
  /// Not always [pairNameIds]: the reveal falls back to the comfort pair when
  /// either half has no approved deck, including for a length-2 pair that only
  /// LOOKS resolved (a deep link's `name_ids`, an id retired from the decks).
  /// Recording what was shown is what keeps the four consumers — the card the
  /// user watched land, `starter_name_id`, the seeded queue's head, and the
  /// plan screen's named rows — from disagreeing about which Name they met.
  /// Empty until the reveal reports back, and outside the reel flow.
  final List<int> revealedPairNameIds;

  /// Wave D's aspiration answer (drives queue rows 3-7 in W2-C2).
  final String? aspiration;

  /// "How long have you been carrying this?" — pacing + AI context. Rides to
  /// the server inside [acquisitionPromise] as `carrying_duration`.
  final String? carryingDuration;

  // ---- Wave H: the intake set --------------------------------------------
  // Every one of these has a VISIBLE CONSEQUENCE — a question whose answer
  // never surfaces is extractive (spec §2). The consequence functions live
  // beside the options in `content/intake_questions.dart` and
  // `content/help_chips.dart`; the screens here only record the answer.
  //
  // None of them ride to the server yet: `acquisitionPromise` is pinned by
  // exact-map equality in `onboarding_state_v8_test.dart` and its check
  // constraint has no room reserved for them. W3 needs `heaviestTime`,
  // `namesKnown`, `dailyTime` and `intakeNote` as AI context on a device that
  // may not be the one that onboarded, so giving them a server home is
  // outstanding work, not a decision that they stay local.

  /// H2 "When is it heaviest?" — DERIVES [reminderTime] (see
  /// [OnboardingNotifier.setHeaviestTime]) and sets the plan screen's
  /// when-we'll-be-there line. The reel flow has no reminder-time screen; this
  /// question replaced it.
  final String? heaviestTime;

  /// H3 "Have you been able to tell anyone?" — sets the plan line and the first
  /// notification's register. Approved on the condition that we act on it, so
  /// an answer of `no_one`/`a_little` MUST keep changing something visible.
  final String? toldAnyone;

  /// H4 "How many of Allah's Names could you name right now?" — the projection
  /// baseline ("You know about five. In 30 days you'll know thirty-five.").
  final String? namesKnown;

  /// H5 "What would help most right now?" — **ordered**, capped at
  /// [helpChipsMaxSelections].
  ///
  /// Order is load-bearing, which is why this is a list and not a set: the
  /// blend in [helpChipsQueueNameIds] weights by selection order, so
  /// `['words', 'sense']` and `['sense', 'words']` seed different queues.
  final List<String> helpWith;

  /// H6 "How much time feels right most days?" — plan pacing line and deck
  /// length. Not a commitment device; nothing reads it as one.
  final String? dailyTime;

  /// H7 "Anything you want to add?" — free text, skippable, capped at
  /// [intakeNoteMaxGraphemes]. AI context for Reflect and Build-a-Duʿā.
  final String? intakeNote;

  /// Post-reveal "Where did you find us?" answer.
  final String? reelSource;

  /// Reel id captured from a `sakina://reel/<id>` deep link.
  final String? reelId;

  /// The `?name_ids=a,b` pair a reel link promised, or empty for the common
  /// case. Validated at capture time (`reel_deep_link_service.dart`), so it is
  /// either a real two-Name pair or nothing.
  ///
  /// Lives in STATE rather than on the onboarding screen's State object because
  /// the deep link is drained once, at launch, and the hook may be answered
  /// several app kills later — a field would have quietly lost the override and
  /// revealed the Names the hook resolved instead of the ones the reel named.
  final List<int> reelPairOverride;

  /// [HookType.chip], [HookType.freeText] or [HookType.reel].
  final String? hookType;

  /// `reel_v1` | `legacy` — which onboarding EXPERIENCE ran. Set at flow entry
  /// (W2-E1) and mirrored into `user_profiles.onboarding_flow`; also the tour
  /// suppression key.
  final String? onboardingFlow;

  /// The `acquisition_promise` jsonb payload, or null when the hook has not
  /// been answered yet.
  ///
  /// `contract` is mandatory — the column carries a check constraint requiring
  /// it. `contract` and `hookType` are always written together by
  /// [OnboardingNotifier.applyHookSelection]; if either is somehow missing we
  /// emit nothing rather than guess an arrival story.
  ///
  /// `carrying_duration` rides along when the user answered that question. The
  /// check constraint only requires `contract`, so extra keys are free, and
  /// this is the column that gives the answer a server-side home: it is
  /// otherwise local-only, and W3 needs it as AI context on a device that may
  /// not be the one that onboarded.
  Map<String, dynamic>? get acquisitionPromise {
    final c = contract;
    final h = hookType;
    if (c == null || h == null) return null;
    return {
      if (reelId != null) 'reel_id': reelId,
      'hook_type': h,
      'contract': c,
      if (problemCategory != null) 'problem_category': problemCategory,
      if (carryingDuration != null) 'carrying_duration': carryingDuration,
    };
  }

  OnboardingState copyWith({
    int? currentPage,
    String? intention,
    bool? notificationPermissionGranted,
    String? demoFeelingInput,
    bool? demoCheckinCompleted,
    bool? isLoadingDemoResult,
    String? familiarity,
    Set<String>? attribution,
    double? generateProgress,
    bool? isSignedUp,
    String? authError,
    bool clearAuthError = false,
    String? signUpName,
    bool clearSignUpName = false,
    String? signUpEmail,
    bool clearSignUpEmail = false,
    String? ageRange,
    String? prayerFrequency,
    int? starterNameId,
    Set<String>? duaTopics,
    String? duaTopicsOther,
    bool clearDuaTopicsOther = false,
    int? dailyCommitmentMinutes,
    String? reminderTime,
    bool? commitmentAccepted,
    String? referralApplyFailedReason,
    bool clearReferralApplyFailedReason = false,
    String? contract,
    String? problemCategory,
    String? chipKey,
    bool clearChipKey = false,
    String? problemTextRaw,
    bool clearProblemTextRaw = false,
    List<int>? pairNameIds,
    List<int>? revealedPairNameIds,
    String? aspiration,
    String? carryingDuration,
    String? heaviestTime,
    String? toldAnyone,
    String? namesKnown,
    List<String>? helpWith,
    String? dailyTime,
    String? intakeNote,
    bool clearIntakeNote = false,
    String? reelSource,
    String? reelId,
    List<int>? reelPairOverride,
    String? hookType,
    String? onboardingFlow,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      intention: intention ?? this.intention,
      notificationPermissionGranted:
          notificationPermissionGranted ?? this.notificationPermissionGranted,
      demoFeelingInput: demoFeelingInput ?? this.demoFeelingInput,
      demoCheckinCompleted: demoCheckinCompleted ?? this.demoCheckinCompleted,
      isLoadingDemoResult: isLoadingDemoResult ?? this.isLoadingDemoResult,
      familiarity: familiarity ?? this.familiarity,
      attribution: attribution ?? this.attribution,
      generateProgress: generateProgress ?? this.generateProgress,
      isSignedUp: isSignedUp ?? this.isSignedUp,
      authError: clearAuthError ? null : (authError ?? this.authError),
      signUpName: clearSignUpName ? null : (signUpName ?? this.signUpName),
      signUpEmail: clearSignUpEmail ? null : (signUpEmail ?? this.signUpEmail),
      ageRange: ageRange ?? this.ageRange,
      prayerFrequency: prayerFrequency ?? this.prayerFrequency,
      starterNameId: starterNameId ?? this.starterNameId,
      duaTopics: duaTopics ?? this.duaTopics,
      duaTopicsOther:
          clearDuaTopicsOther ? null : (duaTopicsOther ?? this.duaTopicsOther),
      dailyCommitmentMinutes:
          dailyCommitmentMinutes ?? this.dailyCommitmentMinutes,
      reminderTime: reminderTime ?? this.reminderTime,
      commitmentAccepted: commitmentAccepted ?? this.commitmentAccepted,
      referralApplyFailedReason: clearReferralApplyFailedReason
          ? null
          : (referralApplyFailedReason ?? this.referralApplyFailedReason),
      contract: contract ?? this.contract,
      problemCategory: problemCategory ?? this.problemCategory,
      // Explicit clears: re-answering the hook with unmatched free text must
      // be able to erase a chip key / typed sentence from an earlier answer.
      chipKey: clearChipKey ? null : (chipKey ?? this.chipKey),
      problemTextRaw:
          clearProblemTextRaw ? null : (problemTextRaw ?? this.problemTextRaw),
      pairNameIds: pairNameIds ?? this.pairNameIds,
      revealedPairNameIds: revealedPairNameIds ?? this.revealedPairNameIds,
      aspiration: aspiration ?? this.aspiration,
      carryingDuration: carryingDuration ?? this.carryingDuration,
      heaviestTime: heaviestTime ?? this.heaviestTime,
      toldAnyone: toldAnyone ?? this.toldAnyone,
      namesKnown: namesKnown ?? this.namesKnown,
      helpWith: helpWith ?? this.helpWith,
      dailyTime: dailyTime ?? this.dailyTime,
      // Explicit clear: H7 is the one intake answer a user can take back —
      // emptying the field must be able to erase a note they already wrote.
      intakeNote:
          clearIntakeNote ? null : (intakeNote ?? this.intakeNote),
      reelSource: reelSource ?? this.reelSource,
      reelId: reelId ?? this.reelId,
      reelPairOverride: reelPairOverride ?? this.reelPairOverride,
      hookType: hookType ?? this.hookType,
      onboardingFlow: onboardingFlow ?? this.onboardingFlow,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': 8,
        'currentPage': currentPage,
        'intention': intention,
        'notificationPermissionGranted': notificationPermissionGranted,
        'demoCheckinCompleted': demoCheckinCompleted,
        'familiarity': familiarity,
        'attribution': attribution.toList(),
        'signUpName': signUpName,
        'signUpEmail': signUpEmail,
        'ageRange': ageRange,
        'prayerFrequency': prayerFrequency,
        'starterNameId': starterNameId,
        'duaTopics': duaTopics.toList(),
        'duaTopicsOther': duaTopicsOther,
        'dailyCommitmentMinutes': dailyCommitmentMinutes,
        'reminderTime': reminderTime,
        'commitmentAccepted': commitmentAccepted,
        'contract': contract,
        'problemCategory': problemCategory,
        'chipKey': chipKey,
        'problemTextRaw': problemTextRaw,
        'pairNameIds': pairNameIds,
        'revealedPairNameIds': revealedPairNameIds,
        'aspiration': aspiration,
        'carryingDuration': carryingDuration,
        // Additive within v8, like `reelPairOverride`: an older v8 blob simply
        // has no key here, and `fromJson` reads that as "not answered yet".
        // These are all written pre-auth and must survive an app kill mid-flow.
        'heaviestTime': heaviestTime,
        'toldAnyone': toldAnyone,
        'namesKnown': namesKnown,
        'helpWith': helpWith,
        'dailyTime': dailyTime,
        'intakeNote': intakeNote,
        'reelSource': reelSource,
        'reelId': reelId,
        // Additive within v8: an older v8 blob simply has no key here, and
        // `fromJson` reads that as "no override" — which is what it was.
        'reelPairOverride': reelPairOverride,
        'hookType': hookType,
        'onboardingFlow': onboardingFlow,
      };

  static OnboardingState fromJson(Map<String, dynamic> json) {
    // Bumped to 8 with the One Ship reel flow (W2): the page order changed
    // again and the hook fields are new. A v7 blob describes a flow whose page
    // indices no longer mean the same thing, so it is discarded and the user
    // starts fresh — intended, and the same call the trim refactor made when
    // it bumped 6 → 7.
    final version = json['version'] as int? ?? 0;
    if (version < 8) return const OnboardingState();

    var currentPage = json['currentPage'] as int? ?? 0;
    // Preserve rollback-path pages until OnboardingScreen resolves the
    // server-driven flow flag. Trimmed mode re-clamps after resolution.
    currentPage = currentPage.clamp(0, onboardingLegacyLastPageIndex);

    Set<String> readSet(dynamic raw) =>
        (raw as List<dynamic>?)?.map((e) => e as String).toSet() ?? const {};

    return OnboardingState(
      currentPage: currentPage,
      intention: json['intention'] as String?,
      notificationPermissionGranted:
          json['notificationPermissionGranted'] as bool? ?? false,
      demoCheckinCompleted: json['demoCheckinCompleted'] as bool? ?? false,
      familiarity: json['familiarity'] as String?,
      attribution: readSet(json['attribution']),
      signUpName: json['signUpName'] as String?,
      signUpEmail: json['signUpEmail'] as String?,
      ageRange: json['ageRange'] as String?,
      prayerFrequency: json['prayerFrequency'] as String?,
      starterNameId: (json['starterNameId'] as num?)?.toInt(),
      duaTopics: readSet(json['duaTopics']),
      duaTopicsOther: json['duaTopicsOther'] as String?,
      dailyCommitmentMinutes: json['dailyCommitmentMinutes'] as int?,
      reminderTime: json['reminderTime'] as String?,
      commitmentAccepted: json['commitmentAccepted'] as bool? ?? false,
      contract: json['contract'] as String?,
      problemCategory: json['problemCategory'] as String?,
      chipKey: json['chipKey'] as String?,
      problemTextRaw: json['problemTextRaw'] as String?,
      pairNameIds: (json['pairNameIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList(growable: false) ??
          const [],
      revealedPairNameIds: (json['revealedPairNameIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList(growable: false) ??
          const [],
      aspiration: json['aspiration'] as String?,
      carryingDuration: json['carryingDuration'] as String?,
      heaviestTime: json['heaviestTime'] as String?,
      toldAnyone: json['toldAnyone'] as String?,
      namesKnown: json['namesKnown'] as String?,
      // Order survives the round trip — the blend weights by it.
      helpWith: (json['helpWith'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(growable: false) ??
          const [],
      dailyTime: json['dailyTime'] as String?,
      intakeNote: json['intakeNote'] as String?,
      reelSource: json['reelSource'] as String?,
      reelId: json['reelId'] as String?,
      reelPairOverride: (json['reelPairOverride'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList(growable: false) ??
          const [],
      hookType: json['hookType'] as String?,
      onboardingFlow: json['onboardingFlow'] as String?,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier({
    OnboardingState? restored,
    AuthService? authService,
    NameQueueService? nameQueueService,
    ProblemChipResolver? chipResolver,
  })  : _authServiceOverride = authService,
        _nameQueueOverride = nameQueueService,
        _chipResolverOverride = chipResolver,
        super(restored ?? const OnboardingState());

  /// Static analytics hook (mirrors `DailyLoopNotifier.onAnalyticsEvent`).
  /// Wired in `main.dart` — the notifier itself stays Riverpod-dispatch-free so
  /// `completeOnboarding` can be driven in a unit test.
  static void Function(String name, Map<String, Object?> props)?
      onAnalyticsEvent;

  final AuthService? _authServiceOverride;
  AuthService? _authServiceCached;
  AuthService get _authService =>
      _authServiceOverride ?? (_authServiceCached ??= AuthService());

  final NameQueueService? _nameQueueOverride;
  NameQueueService? _nameQueueCached;
  NameQueueService get _nameQueue =>
      _nameQueueOverride ?? (_nameQueueCached ??= NameQueueService());

  final ProblemChipResolver? _chipResolverOverride;
  ProblemChipResolver? _chipResolverCached;
  ProblemChipResolver get _chipResolver =>
      _chipResolverOverride ?? (_chipResolverCached ??= ProblemChipResolver());

  Timer? _generateTimer;

  @override
  void dispose() {
    _generateTimer?.cancel();
    super.dispose();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  static Future<OnboardingState?> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return null;
    try {
      return OnboardingState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
    _saveToPrefs();
  }

  void setIntention(String intention) {
    state = state.copyWith(intention: intention);
    _saveToPrefs();
  }

  void setNotificationPermission(bool granted) {
    state = state.copyWith(notificationPermissionGranted: granted);
    _saveToPrefs();
  }

  void setDemoFeelingInput(String input) {
    state = state.copyWith(demoFeelingInput: input);
    _saveToPrefs();
  }

  Future<void> completeDemoCheckin() async {
    state = state.copyWith(isLoadingDemoResult: true);
    await Future<void>.delayed(const Duration(seconds: 2));
    state = state.copyWith(
      isLoadingDemoResult: false,
      demoCheckinCompleted: true,
    );
    _saveToPrefs();
  }

  void setFamiliarity(String familiarity) {
    state = state.copyWith(familiarity: familiarity);
    _saveToPrefs();
  }

  void toggleAttribution(String source) {
    final updated = Set<String>.from(state.attribution);
    if (updated.contains(source)) {
      updated.remove(source);
    } else {
      updated.add(source);
    }
    state = state.copyWith(attribution: updated);
    _saveToPrefs();
  }

  void setAgeRange(String value) {
    state = state.copyWith(ageRange: value);
    _saveToPrefs();
  }

  void setPrayerFrequency(String value) {
    state = state.copyWith(prayerFrequency: value);
    _saveToPrefs();
  }

  void setStarterName(int catalogId) {
    state = state.copyWith(starterNameId: catalogId);
    _saveToPrefs();
  }

  /// Commit the hook screen's answer (W2-B2 → B3).
  ///
  /// One write for the whole promise so `contract`, `hookType` and the pair can
  /// never be persisted half-applied — [OnboardingState.acquisitionPromise]
  /// depends on that invariant.
  ///
  /// `hook_type` records ARRIVAL ORIGIN, so an existing [HookType.reel] survives
  /// this call: a reel visitor answers the hook screen like everyone else, and
  /// overwriting them as `chip` would make [HookType.reel] unreachable in the
  /// data and erase the only marker that the reel sent them.
  void applyHookSelection(ChipSelection selection) {
    final origin =
        state.hookType == HookType.reel ? HookType.reel : selection.hookType;
    state = state.copyWith(
      contract: selection.contract,
      problemCategory: selection.problemCategory,
      hookType: origin,
      pairNameIds: selection.pairNameIds,
      chipKey: selection.chipKey,
      clearChipKey: selection.chipKey == null,
      problemTextRaw: selection.problemTextRaw,
      clearProblemTextRaw: selection.problemTextRaw == null,
    );
    _saveToPrefs();
  }

  /// Record the pair the reveal actually showed (W2-E, called from its
  /// `onDone`). See [OnboardingState.revealedPairNameIds] for why the shown
  /// pair — not the hook's — is what the rest of completion resolves against.
  ///
  /// Anything but a two-id pair is ignored: a half pair would name one row on
  /// the plan screen and seed a queue the RPC rejects, and the hook's own pair
  /// (with its comfort fallback) is the better answer in that case.
  void setRevealedPair(List<int> nameIds) {
    if (nameIds.length != 2) return;
    state = state.copyWith(
      revealedPairNameIds: List<int>.unmodifiable(nameIds),
    );
    _saveToPrefs();
  }

  void setCarryingDuration(String value) {
    state = state.copyWith(carryingDuration: value);
    _saveToPrefs();
  }

  void setAspiration(String value) {
    state = state.copyWith(aspiration: value);
    _saveToPrefs();
  }

  // ---- Wave H: the intake set --------------------------------------------

  /// H2. Records the answer **and derives [OnboardingState.reminderTime] from
  /// it** — the whole reason this question is allowed to replace the
  /// reminder-time screen rather than sit beside it.
  ///
  /// Always re-derives: a user who backs up and changes their answer would
  /// otherwise keep a reminder at the hour they just told us is the wrong one.
  /// An off-taxonomy key writes the answer but no time (rather than a guessed
  /// 08:00), so a reminder is only ever scheduled from something the user
  /// actually said.
  void setHeaviestTime(String value) {
    state = state.copyWith(
      heaviestTime: value,
      reminderTime: heaviestReminderTime(value),
    );
    _saveToPrefs();
  }

  /// H3.
  void setToldAnyone(String value) {
    state = state.copyWith(toldAnyone: value);
    _saveToPrefs();
  }

  /// H4.
  void setNamesKnown(String value) {
    state = state.copyWith(namesKnown: value);
    _saveToPrefs();
  }

  /// H5. Adds [key] to the end of the ordered selection, or removes it.
  ///
  /// **A fourth selection is refused, not swapped in.** Silently dropping the
  /// oldest choice would take away something the user deliberately chose — the
  /// cap has to read as "you already have three", never as musical chairs. The
  /// screen dims the unselected chips at the cap so the refusal is visible
  /// before the tap rather than after it.
  ///
  /// Append-to-end is what makes the selection ORDERED: the blend weights by it,
  /// so re-selecting a chip the user removed puts it last, which is the honest
  /// reading of what they just did.
  void toggleHelpWith(String key) {
    final current = state.helpWith;
    final List<String> next;
    if (current.contains(key)) {
      next = [
        for (final k in current)
          if (k != key) k,
      ];
    } else {
      if (current.length >= helpChipsMaxSelections) return;
      next = [...current, key];
    }
    state = state.copyWith(helpWith: List<String>.unmodifiable(next));
    _saveToPrefs();
  }

  /// H6.
  void setDailyTime(String value) {
    state = state.copyWith(dailyTime: value);
    _saveToPrefs();
  }

  /// H7. Empty (or whitespace-only) clears the note — skipping the screen and
  /// deleting what you wrote are the same intent, and both must be able to
  /// erase an earlier answer.
  ///
  /// Capped in GRAPHEMES so emoji and Arabic ligatures are never split
  /// mid-code-unit, the same way `setDuaTopicsOther` does it.
  void setIntakeNote(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      state = state.copyWith(clearIntakeNote: true);
    } else {
      final chars = trimmed.characters;
      state = state.copyWith(
        intakeNote: chars.length > intakeNoteMaxGraphemes
            ? chars.take(intakeNoteMaxGraphemes).toString()
            : trimmed,
      );
    }
    _saveToPrefs();
  }

  void setReelSource(String value) {
    state = state.copyWith(reelSource: value);
    _saveToPrefs();
  }

  /// Stamped from a `sakina://reel/<id>` deep link before the hook renders.
  ///
  /// [nameIds] is the link's `?name_ids=` pair, already validated by
  /// `reel_deep_link_service.dart`; it persists with the rest of the arrival so
  /// an app kill between the link and the hook answer cannot silently drop the
  /// Names the reel promised. Empty is the common case and overrides nothing.
  void setReelArrival({required String reelId, List<int> nameIds = const []}) {
    state = state.copyWith(
      reelId: reelId,
      hookType: HookType.reel,
      reelPairOverride: List<int>.unmodifiable(nameIds),
    );
    _saveToPrefs();
  }

  /// `reel_v1` | `legacy`, decided at flow entry (W2-E1).
  ///
  /// Throws rather than asserts on an unknown value: the column is the tour
  /// suppression key and the flow dimension every W2 readout segments on, so a
  /// typo that only fails in debug would ship as silently mis-segmented data.
  void setOnboardingFlow(String flow) {
    if (!OnboardingFlow.values.contains(flow)) {
      throw ArgumentError.value(
        flow,
        'flow',
        'not an onboarding flow (${OnboardingFlow.values.join(' | ')})',
      );
    }
    state = state.copyWith(onboardingFlow: flow);
    _saveToPrefs();
  }

  Set<String> _toggled(Set<String> src, String v) =>
      src.contains(v) ? (Set.of(src)..remove(v)) : (Set.of(src)..add(v));

  void toggleDuaTopic(String topic) {
    state = state.copyWith(duaTopics: _toggled(state.duaTopics, topic));
    _saveToPrefs();
  }

  void setDuaTopicsOther(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      state = state.copyWith(clearDuaTopicsOther: true);
    } else {
      // Spec §5: 280-grapheme cap on free text (use user-perceived characters
      // so emoji and Arabic ligatures aren't split mid-code-unit).
      final chars = trimmed.characters;
      state = state.copyWith(
        duaTopicsOther:
            chars.length > 280 ? chars.take(280).toString() : trimmed,
      );
    }
    _saveToPrefs();
  }

  void setDailyCommitmentMinutes(int minutes) {
    state = state.copyWith(dailyCommitmentMinutes: minutes);
    _saveToPrefs();
  }

  void setReminderTime(String hhmm) {
    state = state.copyWith(reminderTime: hhmm);
    _saveToPrefs();
  }

  void setCommitmentAccepted(bool accepted) {
    state = state.copyWith(commitmentAccepted: accepted);
    _saveToPrefs();
  }

  void runGeneratingTheater(VoidCallback onComplete) {
    state = state.copyWith(generateProgress: 0.0);
    // 3.5s total — gives the 4th step (threshold 0.70) room to render its active
    // state for ~30% of the timeline before auto-advance.
    const totalDuration = Duration(milliseconds: 3500);
    const tickInterval = Duration(milliseconds: 50);
    final totalTicks =
        totalDuration.inMilliseconds ~/ tickInterval.inMilliseconds;
    var currentTick = 0;

    _generateTimer?.cancel();
    _generateTimer = Timer.periodic(tickInterval, (timer) {
      currentTick++;
      final progress = currentTick / totalTicks;
      state = state.copyWith(generateProgress: progress.clamp(0.0, 1.0));

      if (currentTick >= totalTicks) {
        timer.cancel();
        _generateTimer = null;
        onComplete();
      }
    });
  }

  /// Reset all onboarding state back to defaults (page 0, no selections).
  /// Call this on sign-out or account deletion so a returning user starts fresh.
  void reset() {
    _generateTimer?.cancel();
    _generateTimer = null;
    state = const OnboardingState();
    _saveToPrefs();
  }

  void setSignedUp(bool value) {
    state = state.copyWith(isSignedUp: value);
  }

  void setAuthError(String? error) {
    if (error == null) {
      state = state.copyWith(clearAuthError: true);
    } else {
      state = state.copyWith(authError: error);
    }
  }

  void clearAuthError() {
    state = state.copyWith(clearAuthError: true);
  }

  /// Set when the post-signup `apply_referral` call returns `ok:false` with
  /// reason `invalid` or `self_referral`. Read once by EncouragementScreen
  /// and cleared via [clearReferralApplyFailedReason] so re-mounts don't
  /// double-fire the snackbar.
  void setReferralApplyFailedReason(String reason) {
    state = state.copyWith(referralApplyFailedReason: reason);
  }

  void clearReferralApplyFailedReason() {
    state = state.copyWith(clearReferralApplyFailedReason: true);
  }

  void setSignUpName(String name) {
    state = state.copyWith(signUpName: name);
    _saveToPrefs();
  }

  void setSignUpEmail(String email) {
    state = state.copyWith(signUpEmail: email);
    _saveToPrefs();
  }

  Future<void> persistOnboardingToSupabase() async {
    // Asked through the service (which owns the Supabase handle) rather than
    // reading `Supabase.instance` here, so the completion chain can be driven
    // in a unit test without a live client.
    if (!_authService.isSignedIn) return;
    await _persistQuizAnswers();
  }

  /// Test-only.
  @visibleForTesting
  Future<void> debugPersistOnboardingForTest() => _persistQuizAnswers();

  Future<void> _persistQuizAnswers() async {
    try {
      await _authService.saveOnboardingData(
        displayName: state.signUpName,
        intention: state.intention,
        familiarity: state.familiarity,
        attribution: state.attribution.toList(),
        ageRange: state.ageRange,
        prayerFrequency: state.prayerFrequency,
        starterNameId: state.starterNameId,
        duaTopics: state.duaTopics.toList(),
        duaTopicsOther: state.duaTopicsOther,
        dailyCommitmentMinutes: state.dailyCommitmentMinutes,
        reminderTime: state.reminderTime,
        commitmentAccepted: state.commitmentAccepted,
        // W1 columns — they ride EVERY persist, including the final one, so
        // they are already written when `onboarding_completed` freezes them.
        acquisitionPromise: state.acquisitionPromise,
        firstProblemText: state.problemTextRaw,
        onboardingFlow: state.onboardingFlow,
      );
    } catch (e, stack) {
      // Best-effort — don't block onboarding completion on DB failure, but
      // make the failure audible so the analytics/UX cost is visible.
      debugPrint('[Onboarding] persist quiz answers failed: $e\n$stack');
    }
  }

  /// The hook pair this user's completion writes agree on.
  ///
  /// Resolved ONCE per completion and handed to both consumers (the starter
  /// card / `starter_name_id`, and the seeded queue). Resolving it twice let an
  /// empty-pair user's queue open on the comfort pair while their starter card
  /// stayed null — the queue's Name₁ and the card they own must be the same
  /// Name. Outside the reel flow the state's pair is returned untouched: the
  /// comfort fallback is the reel flow's contract, not a global default.
  ///
  /// The pair the reveal SHOWED wins outright when it recorded one. The hook's
  /// pair can be two ids long and still not be what the user met — an id no
  /// approved deck teaches (a deep link's `name_ids`, a retired deck) sends the
  /// reveal to the comfort pair without ever touching `pairNameIds`, and the
  /// length check below would then hand completion a pair the user never saw.
  @visibleForTesting
  Future<List<int>> resolvePairNameIds() async {
    final revealed = state.revealedPairNameIds;
    if (revealed.length == 2) return revealed;
    final pair = state.pairNameIds;
    if (pair.length == 2 || state.onboardingFlow != onboardingFlowReel) {
      return pair;
    }
    return _chipResolver.pairNameIdsForChip(comfortChipKey);
  }

  /// The 7 ids `seed_name_queue` is called with: the hook's pair at positions
  /// 1-2, then the five that the "what would help most" selections blend into
  /// at 3-7 (Wave H — this replaced the single aspiration answer).
  ///
  /// Empty for anything but the reel flow — the queue IS the reel flow's
  /// acquisition promise, and a kill-switch user who never saw a hook screen
  /// must not be handed one. Falls back to a two-row queue when nothing was
  /// selected — the RPC accepts 2-7 ids, and inventing an ordering would ship
  /// unreviewed content. Empty means "don't seed", never "seed junk".
  ///
  /// MUST stay in lockstep with `QueuePlanScreen.plannedQueueNameIds`, incl.
  /// the pair exclusion: the plan screen names these rows to the user, and a
  /// queue that seeds something else makes the promise a lie. Pinned by
  /// `reveal_pair_agreement_test.dart`.
  List<int> queueNameIdsFor(List<int> pair) {
    if (state.onboardingFlow != onboardingFlowReel) return const [];
    if (pair.length != 2) return const [];
    return [
      ...pair,
      ...helpChipsQueueNameIds(state.helpWith, exclude: pair.toSet()),
    ];
  }

  /// [queueNameIdsFor] over a freshly [resolvePairNameIds]-resolved pair.
  /// `completeOnboarding` does NOT call this — it resolves the pair itself so
  /// the starter card sees the same one.
  @visibleForTesting
  Future<List<int>> buildQueueNameIds() async =>
      queueNameIdsFor(await resolvePairNameIds());

  Future<void> completeOnboarding(AppSessionNotifier appSession) async {
    // Reset the daily launch gate so the new user always sees the day-0
    // DailyLaunchOverlay when they land on the home screen.
    await resetDailyLaunchGate();

    // One resolution for the whole chain: the starter card, the persisted
    // `starter_name_id` and the queue's first row are the same Name or the
    // user's collection contradicts their queue on day 0.
    final pair = await resolvePairNameIds();
    final starterId =
        state.starterNameId ?? (pair.isNotEmpty ? pair.first : null);
    // Committed to state BEFORE the persist so the fallback reaches
    // `starter_name_id` server-side too — computing it after meant the column
    // stayed null for every user who reached completion without an explicit
    // starter, and the freeze trigger locks that null in.
    if (starterId != null && state.starterNameId != starterId) {
      state = state.copyWith(starterNameId: starterId);
    }

    await persistOnboardingToSupabase();

    // Seed the user's first collection card with the Name they met. The reel
    // flow's reveal SHOWS a Silver card (W2-C1, deterministic), so it persists
    // Silver; every other flow keeps the legacy Bronze. Idempotent on
    // (user_id, name_id) — a re-run clamps rather than increments.
    if (starterId != null) {
      try {
        await _authService.seedStarterCard(
          starterId,
          tier: state.onboardingFlow == onboardingFlowReel
              ? CardTier.silver
              : CardTier.bronze,
        );
      } catch (e, stack) {
        debugPrint('[Onboarding] seed starter card failed: $e\n$stack');
      }
      // Refresh local card_collection cache so the collection screen shows
      // the seeded card immediately. Separate try/catch so a hydration
      // failure isn't misattributed to the seed call above.
      try {
        await hydrateUserDataFromBatchRpc();
      } catch (e, stack) {
        debugPrint(
            '[Onboarding] post-seed user data hydration failed: $e\n$stack');
      }
    }

    // Seed the 7-Name queue — needs auth, so it runs after the persist, and
    // before the completion flag so the promise exists by the time the user is
    // "onboarded". `seedIfEmpty` pre-checks with an RLS select and never
    // swallows a raise (the RPC's errcode can't distinguish "already seeded"
    // from a wholesale failure), so a genuine failure lands here loudly rather
    // than leaving a silently dead W3 unseal. It must not abort the rest of
    // completion, though: the caller in onboarding_screen swallows throws, and
    // an escape here would skip markOnboardingCompleted + markOnboarded.
    final queueIds = queueNameIdsFor(pair);
    if (queueIds.length >= 2) {
      try {
        await _nameQueue.seedIfEmpty(queueIds);
      } catch (e, stack) {
        debugPrint('[Onboarding] name-queue seed FAILED — the daily unseal '
            'will have nothing to open: $e\n$stack');
        // A debugPrint is invisible in production, and this failure means a
        // shipped user has an acquisition promise with nothing behind it. The
        // error CLASS only — a raw PostgrestException message would blow up the
        // property cardinality.
        onAnalyticsEvent?.call(AnalyticsEvents.nameQueueSeedFailed, {
          'id_count': queueIds.length,
          'error_class': e.runtimeType.toString(),
        });
      }
    }

    // Flip the server-side onboarding flag now that the user has actually
    // finished onboarding. Doing this earlier (e.g. right after sign-up)
    // causes `requestPermissionIfPreviouslyEnabled` to prompt for push
    // permission before the user reaches the notification screen.
    try {
      await _authService.markOnboardingCompleted();
    } catch (_) {}

    // Which post-onboarding gate this user gets is decided by the flow they
    // actually ran, NOT by the current flag state (plan §F1): a kill-switch
    // revert must restore the tour for the users who ran the legacy flow
    // without stranding the reel users who already skipped it.
    //
    // Placed HERE — immediately after the completion flag, ahead of the
    // first-steps sync / referral confirm / premium-cache tail — because that
    // tail is seconds of network on a cold day-0 connection. Run last, an app
    // kill inside that window left the gate flags unwritten while the server
    // already considered the user onboarded: a reel user's next launch had no
    // tour-seen flag and got the legacy opportunistic tour they were never
    // meant to see. Nothing in the gate write depends on the tail.
    await _applyPostOnboardingGate(appSession);

    // Re-sync first steps now that user_profiles row exists
    await syncFirstStepsFromSupabase();

    // Refer-to-Unlock confirm hook: if this user was referred, flip their
    // referrals row pending → confirmed. The SQL RPC handles the 30d grant
    // for the referrer atomically when the 3-confirmed threshold is crossed.
    // Wrapped in try/catch — must NEVER block onboarding completion. The
    // post-RPC refreshReferralPremiumCache surfaces any new window the
    // referee earned to PurchaseService.isPremium().
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null && uid.isNotEmpty) {
        await ReferralService(Supabase.instance.client)
            .confirmReferralIfPending(uid);
        // Also refresh for the referee branch — in case their own 7d window
        // was granted earlier via apply_referral but the cache hasn't been
        // populated yet on this device.
        await PurchaseService().refreshReferralPremiumCache();
        // And the Sakina Gift cache — if the user pre-claimed on another
        // device, restore that entitlement immediately on this one.
        await PurchaseService().refreshGiftPremiumCache();
      }
    } catch (e, stack) {
      debugPrint(
          '[Onboarding] referral confirm failed (non-fatal): $e\n$stack');
    }

    // Mark onboarded in the single source of truth
    await appSession.markOnboarded();

    // Only NOW drop the local onboarding state — after the LAST step that could
    // need to be retried against it. Wiping it earlier (as this did until
    // W2-C2) meant a crash anywhere above restarted onboarding from a blank
    // slate: a fresh Name₁ resolved against a queue the server had already
    // frozen, and a `first_problem_text` the freeze trigger would reject.
    // Losing the wipe to a crash is the cheap failure — the next run
    // re-persists the same answers idempotently, and `markOnboarded` has
    // already routed the user out of onboarding.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// Latches the post-onboarding gate for the flow this user actually ran.
  /// Called from [completeOnboarding] right after the completion flag; see the
  /// comment there for why it does not run at the end.
  Future<void> _applyPostOnboardingGate(AppSessionNotifier appSession) async {
    if (state.onboardingFlow == onboardingFlowReel) {
      // The reel flow REPLACES the forced tour — it already delivered the
      // value the tour exists to demonstrate (a Name met, a card awarded, the
      // queue shown), and its final page IS an onboarding-placement paywall.
      // Latching both gate flags here is what keeps the router from parking
      // these users in stage `tour`, where no paywall surface is reachable.
      await appSession.skipOnboardingGateForReelFlow();
    } else if (appSession.hardPaywallFlowEnabled) {
      // Put the new user INTO the hard-paywall gate by writing the local
      // paywall-cleared latch = false NOW, so the router enforces tour → wall
      // immediately and deterministically — without depending on the async
      // batch-sync hydrate winning the race against the first redirect / the
      // one-shot tour-start in progress_screen (the cold-launch race two
      // reviewers flagged). Flag-gated: a user who onboards while the kill
      // switch is OFF must stay grandfathered if it later flips ON, so we only
      // set the latch when the gate is actually active.
      await appSession.enterOnboardingGate();
    }
  }
}

final cachedOnboardingStateProvider = Provider<OnboardingState?>((ref) => null);

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(
    restored: ref.read(cachedOnboardingStateProvider),
    authService: ref.read(authServiceProvider),
  ),
);

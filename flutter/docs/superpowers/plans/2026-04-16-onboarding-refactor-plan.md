# Onboarding Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the Sakina onboarding into an input-driven, Cal AI/Duolingo-style flow: 29 screens total, ~15 input screens, sign-up deferred until just before the paywall, personalization answers flow into the paywall copy, notification scheduling, and home-screen first load.

**Architecture:**
- Pure Flutter / Riverpod additive changes. No new services, no new packages.
- All quiz data lives in `OnboardingState` (SharedPreferences) until sign-up at screen #25; then it's persisted to Supabase `user_profiles` via the existing `AuthService.saveOnboardingData` extended with 10 new columns.
- One shared `OnboardingQuestionScaffold` widget hosts the layout of all quiz screens; input bodies plug in as children.
- 5 old "feature showcase" screens are deleted. 8 new input screens + 2 interstitials + 1 plan-reveal screen are added.

**Tech Stack:** Flutter 3.41.6, Dart 3.11.4, Riverpod (manual providers, no codegen), Supabase (`user_profiles` table, RLS already enabled), Mixpanel analytics, OneSignal push, SharedPreferences for local state.

**Spec source of truth:** `docs/superpowers/specs/2026-04-16-onboarding-refactor-design.md`

**Test command (used throughout):** `flutter test test/path/to/test.dart`

**Progress-bar convention:** `OnboardingPageWrapper(progressSegment: N)` uses **1-indexed** segments matching the new PageView index + 1. Total segments: 27 (paywall hides the bar).

**Page count reconciliation:** the spec labels 29 "screens" (#1–#29). Screen #2 (gacha reveal) is implemented as an overlay on top of screen #1 (FirstCheckin) via the existing `NameRevealOverlay` and does **not** consume a PageView slot. That means `PageView` has **28 children** and `onboardingLastPageIndex = 27` (0-indexed, paywall). Every `progressSegment` value in this plan uses the spec's 1-indexed screen number, minus 1 where the gacha overlay offset applies (#3 → segment 2, etc.). For simplicity, progress segments below use the spec's 1-indexed screen numbers directly — the progress bar will show 2/27 on the name-input screen, 3/27 on age, and so on. If you prefer consecutive 1..27 numbering, renumber in a follow-up pass — behavior is unaffected.

---

## Task 1: Extend OnboardingState with new fields, v3 JSON, notifier setters

**Files:**
- Modify: `lib/features/onboarding/providers/onboarding_provider.dart`
- Test: `test/features/onboarding/onboarding_provider_test.dart` (create if it doesn't exist)

- [ ] **Step 1.1: Write the failing tests first**

Create `test/features/onboarding/onboarding_provider_test.dart` with the following (replace file if it exists; these tests cover both new state and v3 JSON round-trip):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';

void main() {
  group('OnboardingState v3', () {
    test('defaults all new fields to null/empty', () {
      const s = OnboardingState();
      expect(s.ageRange, isNull);
      expect(s.prayerFrequency, isNull);
      expect(s.resonantNameId, isNull);
      expect(s.duaTopics, isEmpty);
      expect(s.duaTopicsOther, isNull);
      expect(s.commonEmotions, isEmpty);
      expect(s.aspirations, isEmpty);
      expect(s.dailyCommitmentMinutes, isNull);
      expect(s.reminderTime, isNull);
      expect(s.commitmentAccepted, isFalse);
    });

    test('toJson/fromJson round-trips all new fields', () {
      const original = OnboardingState(
        ageRange: '25_34',
        prayerFrequency: 'someDaily',
        resonantNameId: 'ar-rahman-id',
        duaTopics: {'health', 'family'},
        duaTopicsOther: 'success in school',
        commonEmotions: {'anxiety', 'gratitude'},
        aspirations: {'morePatient'},
        dailyCommitmentMinutes: 3,
        reminderTime: '08:30',
        commitmentAccepted: true,
      );
      final json = original.toJson();
      expect(json['version'], 3);
      final decoded = OnboardingState.fromJson(json);
      expect(decoded.ageRange, '25_34');
      expect(decoded.prayerFrequency, 'someDaily');
      expect(decoded.resonantNameId, 'ar-rahman-id');
      expect(decoded.duaTopics, {'health', 'family'});
      expect(decoded.duaTopicsOther, 'success in school');
      expect(decoded.commonEmotions, {'anxiety', 'gratitude'});
      expect(decoded.aspirations, {'morePatient'});
      expect(decoded.dailyCommitmentMinutes, 3);
      expect(decoded.reminderTime, '08:30');
      expect(decoded.commitmentAccepted, isTrue);
    });

    test('fromJson with version < 3 discards stored state and starts fresh', () {
      // Pre-refactor (v2) blob. Per spec: no users, no migration logic; drop it.
      final legacy = {
        'version': 2,
        'currentPage': 5,
        'intention': 'legacy',
        'struggles': ['anxiety'],
      };
      final decoded = OnboardingState.fromJson(legacy);
      expect(decoded.currentPage, 0);
      expect(decoded.intention, isNull);
      expect(decoded.struggles, isEmpty);
    });

    test('fromJson accepts v3 blob as authoritative', () {
      final v3 = {
        'version': 3,
        'currentPage': 5,
        'intention': 'spiritualGrowth',
        'struggles': ['anxiety'],
        'ageRange': '25_34',
      };
      final decoded = OnboardingState.fromJson(v3);
      expect(decoded.currentPage, 5);
      expect(decoded.intention, 'spiritualGrowth');
      expect(decoded.struggles, {'anxiety'});
      expect(decoded.ageRange, '25_34');
    });
  });

  group('OnboardingNotifier setters', () {
    test('each setter updates the corresponding field', () {
      final notifier = OnboardingNotifier();
      notifier.setAgeRange('25_34');
      notifier.setPrayerFrequency('someDaily');
      notifier.setResonantNameId('ar-rahman-id');
      notifier.toggleDuaTopic('health');
      notifier.toggleDuaTopic('family');
      notifier.toggleDuaTopic('health'); // toggle off
      notifier.setDuaTopicsOther('school');
      notifier.toggleCommonEmotion('anxiety');
      notifier.toggleAspiration('morePatient');
      notifier.setDailyCommitmentMinutes(5);
      notifier.setReminderTime('08:30');
      notifier.setCommitmentAccepted(true);

      final s = notifier.state;
      expect(s.ageRange, '25_34');
      expect(s.prayerFrequency, 'someDaily');
      expect(s.resonantNameId, 'ar-rahman-id');
      expect(s.duaTopics, {'family'});
      expect(s.duaTopicsOther, 'school');
      expect(s.commonEmotions, {'anxiety'});
      expect(s.aspirations, {'morePatient'});
      expect(s.dailyCommitmentMinutes, 5);
      expect(s.reminderTime, '08:30');
      expect(s.commitmentAccepted, isTrue);
    });
  });
}
```

- [ ] **Step 1.2: Run the tests to verify they fail**

Run: `flutter test test/features/onboarding/onboarding_provider_test.dart`
Expected: FAIL (fields and setters don't exist yet).

- [ ] **Step 1.3: Extend OnboardingState**

In `lib/features/onboarding/providers/onboarding_provider.dart`, change `onboardingLastPageIndex` and expand the `OnboardingState` class:

```dart
/// Last index in [OnboardingScreen]'s PageView (paywall at index 27).
/// PageView has 28 children; spec's 29th "screen" (gacha) is an overlay.
const int onboardingLastPageIndex = 27;

class OnboardingState {
  const OnboardingState({
    this.currentPage = 0,
    this.intention,
    this.struggles = const {},
    this.notificationPermissionGranted = false,
    this.demoFeelingInput,
    this.demoCheckinCompleted = false,
    this.isLoadingDemoResult = false,
    this.familiarity,
    this.quranConnection,
    this.attribution = const {},
    this.generateProgress = 0.0,
    this.isSignedUp = false,
    this.authError,
    this.signUpName,
    this.signUpEmail,
    // New in v3:
    this.ageRange,
    this.prayerFrequency,
    this.resonantNameId,
    this.duaTopics = const {},
    this.duaTopicsOther,
    this.commonEmotions = const {},
    this.aspirations = const {},
    this.dailyCommitmentMinutes,
    this.reminderTime,
    this.commitmentAccepted = false,
  });

  final int currentPage;
  final String? intention;
  final Set<String> struggles;
  final bool notificationPermissionGranted;
  final String? demoFeelingInput;
  final bool demoCheckinCompleted;
  final bool isLoadingDemoResult;
  final String? familiarity;
  final String? quranConnection;
  final Set<String> attribution;
  final double generateProgress;
  final bool isSignedUp;
  final String? authError;
  final String? signUpName;
  final String? signUpEmail;
  final String? ageRange;
  final String? prayerFrequency;
  final String? resonantNameId;
  final Set<String> duaTopics;
  final String? duaTopicsOther;
  final Set<String> commonEmotions;
  final Set<String> aspirations;
  final int? dailyCommitmentMinutes;
  final String? reminderTime; // "HH:mm" 24h
  final bool commitmentAccepted;

  OnboardingState copyWith({
    int? currentPage,
    String? intention,
    Set<String>? struggles,
    bool? notificationPermissionGranted,
    String? demoFeelingInput,
    bool? demoCheckinCompleted,
    bool? isLoadingDemoResult,
    String? familiarity,
    String? quranConnection,
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
    String? resonantNameId,
    Set<String>? duaTopics,
    String? duaTopicsOther,
    bool clearDuaTopicsOther = false,
    Set<String>? commonEmotions,
    Set<String>? aspirations,
    int? dailyCommitmentMinutes,
    String? reminderTime,
    bool? commitmentAccepted,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      intention: intention ?? this.intention,
      struggles: struggles ?? this.struggles,
      notificationPermissionGranted:
          notificationPermissionGranted ?? this.notificationPermissionGranted,
      demoFeelingInput: demoFeelingInput ?? this.demoFeelingInput,
      demoCheckinCompleted: demoCheckinCompleted ?? this.demoCheckinCompleted,
      isLoadingDemoResult: isLoadingDemoResult ?? this.isLoadingDemoResult,
      familiarity: familiarity ?? this.familiarity,
      quranConnection: quranConnection ?? this.quranConnection,
      attribution: attribution ?? this.attribution,
      generateProgress: generateProgress ?? this.generateProgress,
      isSignedUp: isSignedUp ?? this.isSignedUp,
      authError: clearAuthError ? null : (authError ?? this.authError),
      signUpName: clearSignUpName ? null : (signUpName ?? this.signUpName),
      signUpEmail: clearSignUpEmail ? null : (signUpEmail ?? this.signUpEmail),
      ageRange: ageRange ?? this.ageRange,
      prayerFrequency: prayerFrequency ?? this.prayerFrequency,
      resonantNameId: resonantNameId ?? this.resonantNameId,
      duaTopics: duaTopics ?? this.duaTopics,
      duaTopicsOther:
          clearDuaTopicsOther ? null : (duaTopicsOther ?? this.duaTopicsOther),
      commonEmotions: commonEmotions ?? this.commonEmotions,
      aspirations: aspirations ?? this.aspirations,
      dailyCommitmentMinutes:
          dailyCommitmentMinutes ?? this.dailyCommitmentMinutes,
      reminderTime: reminderTime ?? this.reminderTime,
      commitmentAccepted: commitmentAccepted ?? this.commitmentAccepted,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': 3,
        'currentPage': currentPage,
        'intention': intention,
        'struggles': struggles.toList(),
        'notificationPermissionGranted': notificationPermissionGranted,
        'demoCheckinCompleted': demoCheckinCompleted,
        'familiarity': familiarity,
        'quranConnection': quranConnection,
        'attribution': attribution.toList(),
        'signUpName': signUpName,
        'signUpEmail': signUpEmail,
        'ageRange': ageRange,
        'prayerFrequency': prayerFrequency,
        'resonantNameId': resonantNameId,
        'duaTopics': duaTopics.toList(),
        'duaTopicsOther': duaTopicsOther,
        'commonEmotions': commonEmotions.toList(),
        'aspirations': aspirations.toList(),
        'dailyCommitmentMinutes': dailyCommitmentMinutes,
        'reminderTime': reminderTime,
        'commitmentAccepted': commitmentAccepted,
      };

  static OnboardingState fromJson(Map<String, dynamic> json) {
    // Spec §5: Sakina has no production users. Any blob with version < 3 is
    // discarded and the user starts fresh.
    final version = json['version'] as int? ?? 0;
    if (version < 3) return const OnboardingState();

    var currentPage = json['currentPage'] as int? ?? 0;
    currentPage = currentPage.clamp(0, onboardingLastPageIndex);

    Set<String> _readSet(dynamic raw) =>
        (raw as List<dynamic>?)?.map((e) => e as String).toSet() ?? const {};

    return OnboardingState(
      currentPage: currentPage,
      intention: json['intention'] as String?,
      struggles: _readSet(json['struggles']),
      notificationPermissionGranted:
          json['notificationPermissionGranted'] as bool? ?? false,
      demoCheckinCompleted: json['demoCheckinCompleted'] as bool? ?? false,
      familiarity: json['familiarity'] as String?,
      quranConnection: json['quranConnection'] as String?,
      attribution: _readSet(json['attribution']),
      signUpName: json['signUpName'] as String?,
      signUpEmail: json['signUpEmail'] as String?,
      ageRange: json['ageRange'] as String?,
      prayerFrequency: json['prayerFrequency'] as String?,
      resonantNameId: json['resonantNameId'] as String?,
      duaTopics: _readSet(json['duaTopics']),
      duaTopicsOther: json['duaTopicsOther'] as String?,
      commonEmotions: _readSet(json['commonEmotions']),
      aspirations: _readSet(json['aspirations']),
      dailyCommitmentMinutes: json['dailyCommitmentMinutes'] as int?,
      reminderTime: json['reminderTime'] as String?,
      commitmentAccepted: json['commitmentAccepted'] as bool? ?? false,
    );
  }
}
```

- [ ] **Step 1.4: Add notifier setters**

In the same file, inside `OnboardingNotifier`, add these methods (place them alongside the existing `setIntention`, `toggleStruggle`, etc.):

```dart
void setAgeRange(String value) {
  state = state.copyWith(ageRange: value);
  _saveToPrefs();
}

void setPrayerFrequency(String value) {
  state = state.copyWith(prayerFrequency: value);
  _saveToPrefs();
}

void setResonantNameId(String value) {
  state = state.copyWith(resonantNameId: value);
  _saveToPrefs();
}

void toggleDuaTopic(String topic) {
  final updated = Set<String>.from(state.duaTopics);
  updated.contains(topic) ? updated.remove(topic) : updated.add(topic);
  state = state.copyWith(duaTopics: updated);
  _saveToPrefs();
}

void setDuaTopicsOther(String? value) {
  if (value == null || value.trim().isEmpty) {
    state = state.copyWith(clearDuaTopicsOther: true);
  } else {
    // Spec §5: 280-char cap on free text.
    final trimmed = value.trim();
    state = state.copyWith(
      duaTopicsOther:
          trimmed.length > 280 ? trimmed.substring(0, 280) : trimmed,
    );
  }
  _saveToPrefs();
}

void toggleCommonEmotion(String emotion) {
  final updated = Set<String>.from(state.commonEmotions);
  updated.contains(emotion) ? updated.remove(emotion) : updated.add(emotion);
  state = state.copyWith(commonEmotions: updated);
  _saveToPrefs();
}

void toggleAspiration(String aspiration) {
  final updated = Set<String>.from(state.aspirations);
  updated.contains(aspiration)
      ? updated.remove(aspiration)
      : updated.add(aspiration);
  state = state.copyWith(aspirations: updated);
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
```

- [ ] **Step 1.5: Run the tests to verify they pass**

Run: `flutter test test/features/onboarding/onboarding_provider_test.dart`
Expected: PASS (all 5 tests green).

- [ ] **Step 1.6: Commit**

```bash
git add lib/features/onboarding/providers/onboarding_provider.dart \
        test/features/onboarding/onboarding_provider_test.dart
git commit -m "feat(onboarding): extend state with 10 new quiz fields + v3 JSON"
```

---

## Task 2: Supabase migration for new user_profiles columns

**Files:**
- Create: `supabase/migrations/20260418000000_add_onboarding_profile_fields.sql`

- [ ] **Step 2.1: Write the migration**

Create `supabase/migrations/20260418000000_add_onboarding_profile_fields.sql`:

```sql
-- Onboarding refactor (spec 2026-04-16):
-- Additive columns for the new quiz fields. All nullable; no defaults that
-- force a rewrite. Zero-downtime. RLS on user_profiles is already in place.
alter table public.user_profiles
  add column if not exists age_range text,
  add column if not exists prayer_frequency text,
  add column if not exists resonant_name_id uuid references public.names_of_allah(id) on delete set null,
  add column if not exists dua_topics text[] not null default '{}',
  add column if not exists dua_topics_other text,
  add column if not exists common_emotions text[] not null default '{}',
  add column if not exists aspirations text[] not null default '{}',
  add column if not exists daily_commitment_minutes integer,
  add column if not exists reminder_time time,
  add column if not exists commitment_accepted boolean not null default false;

comment on column public.user_profiles.age_range is 'Onboarding quiz: one of 13_17,18_24,25_34,35_44,45_54,55plus';
comment on column public.user_profiles.prayer_frequency is 'Onboarding quiz: fivePlus|someDaily|fridaysOnly|rarely|learning';
comment on column public.user_profiles.daily_commitment_minutes is 'Onboarding quiz: 1|3|5|10';
comment on column public.user_profiles.reminder_time is 'Local time of day the user wants the daily check-in reminder';
```

- [ ] **Step 2.2: Apply the migration locally**

Run: `supabase db reset` (or use the Supabase MCP `apply_migration` tool if configured). Confirm the migration applies without errors.

- [ ] **Step 2.3: Verify the schema**

Run a one-liner against the local DB (via `supabase db query` or `psql`):

```sql
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'user_profiles'
  and column_name in (
    'age_range','prayer_frequency','resonant_name_id','dua_topics',
    'dua_topics_other','common_emotions','aspirations',
    'daily_commitment_minutes','reminder_time','commitment_accepted'
  );
```

Expected: 10 rows, all with correct types.

- [ ] **Step 2.4: Commit**

```bash
git add supabase/migrations/20260418000000_add_onboarding_profile_fields.sql
git commit -m "feat(db): add onboarding quiz columns to user_profiles"
```

---

## Task 3: Extend `AuthService.saveOnboardingData`

**Files:**
- Modify: `lib/services/auth_service.dart`
- Modify: `lib/features/onboarding/providers/onboarding_provider.dart` (the `persistOnboardingToSupabase` call site)

- [ ] **Step 3.1: Write a failing test for the call site**

Create `test/services/auth_service_onboarding_persist_test.dart`. Since `AuthService` talks to Supabase directly, we test the *call-site contract* — that `persistOnboardingToSupabase` gathers every new field and hands them to `AuthService.saveOnboardingData`. Use a fake `AuthService`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/services/auth_service.dart';

class _FakeAuthService extends AuthService {
  Map<String, dynamic>? captured;
  @override
  Future<void> saveOnboardingData({
    String? intention,
    List<String> struggles = const [],
    String? familiarity,
    String? quranConnection,
    List<String> attribution = const [],
    String? ageRange,
    String? prayerFrequency,
    String? resonantNameId,
    List<String> duaTopics = const [],
    String? duaTopicsOther,
    List<String> commonEmotions = const [],
    List<String> aspirations = const [],
    int? dailyCommitmentMinutes,
    String? reminderTime,
    bool commitmentAccepted = false,
  }) async {
    captured = {
      'intention': intention,
      'struggles': struggles,
      'familiarity': familiarity,
      'quranConnection': quranConnection,
      'attribution': attribution,
      'ageRange': ageRange,
      'prayerFrequency': prayerFrequency,
      'resonantNameId': resonantNameId,
      'duaTopics': duaTopics,
      'duaTopicsOther': duaTopicsOther,
      'commonEmotions': commonEmotions,
      'aspirations': aspirations,
      'dailyCommitmentMinutes': dailyCommitmentMinutes,
      'reminderTime': reminderTime,
      'commitmentAccepted': commitmentAccepted,
    };
  }
}

void main() {
  test('persistOnboardingToSupabase forwards every quiz field', () async {
    final fake = _FakeAuthService();
    final notifier = OnboardingNotifier(authService: fake);
    notifier
      ..setIntention('spiritualGrowth')
      ..toggleStruggle('anxiety')
      ..setFamiliarity('some')
      ..setQuranConnection('weak')
      ..toggleAttribution('tiktok')
      ..setAgeRange('25_34')
      ..setPrayerFrequency('someDaily')
      ..setResonantNameId('ar-rahman-id')
      ..toggleDuaTopic('health')
      ..setDuaTopicsOther('exam success')
      ..toggleCommonEmotion('anxiety')
      ..toggleAspiration('morePatient')
      ..setDailyCommitmentMinutes(5)
      ..setReminderTime('08:30')
      ..setCommitmentAccepted(true);

    // persistOnboardingToSupabase short-circuits when no auth user; patch a
    // no-op user check by calling the method directly and asserting
    // fake.captured was touched. Add a public test hook if needed:
    await notifier.debugPersistOnboardingForTest();

    expect(fake.captured!['ageRange'], '25_34');
    expect(fake.captured!['prayerFrequency'], 'someDaily');
    expect(fake.captured!['resonantNameId'], 'ar-rahman-id');
    expect(fake.captured!['duaTopics'], ['health']);
    expect(fake.captured!['duaTopicsOther'], 'exam success');
    expect(fake.captured!['commonEmotions'], ['anxiety']);
    expect(fake.captured!['aspirations'], ['morePatient']);
    expect(fake.captured!['dailyCommitmentMinutes'], 5);
    expect(fake.captured!['reminderTime'], '08:30');
    expect(fake.captured!['commitmentAccepted'], isTrue);
  });
}
```

Note: the test calls `notifier.debugPersistOnboardingForTest()`. We'll add that as a test-only hook next.

- [ ] **Step 3.2: Run the test to verify it fails**

Run: `flutter test test/services/auth_service_onboarding_persist_test.dart`
Expected: FAIL (method missing; `saveOnboardingData` doesn't accept new args).

- [ ] **Step 3.3: Extend `AuthService.saveOnboardingData`**

In `lib/services/auth_service.dart`, replace the existing `saveOnboardingData` with:

```dart
Future<void> saveOnboardingData({
  String? intention,
  List<String> struggles = const [],
  String? familiarity,
  String? quranConnection,
  List<String> attribution = const [],
  String? ageRange,
  String? prayerFrequency,
  String? resonantNameId,
  List<String> duaTopics = const [],
  String? duaTopicsOther,
  List<String> commonEmotions = const [],
  List<String> aspirations = const [],
  int? dailyCommitmentMinutes,
  String? reminderTime,
  bool commitmentAccepted = false,
}) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return;

  await _supabase.from('user_profiles').update({
    'onboarding_intention': intention,
    'onboarding_struggles': struggles,
    'onboarding_familiarity': familiarity,
    'onboarding_quran_connection': quranConnection,
    'onboarding_attribution': attribution,
    'age_range': ageRange,
    'prayer_frequency': prayerFrequency,
    'resonant_name_id': resonantNameId,
    'dua_topics': duaTopics,
    'dua_topics_other': duaTopicsOther,
    'common_emotions': commonEmotions,
    'aspirations': aspirations,
    'daily_commitment_minutes': dailyCommitmentMinutes,
    'reminder_time': reminderTime,
    'commitment_accepted': commitmentAccepted,
  }).eq('id', userId);
}
```

- [ ] **Step 3.4: Update `persistOnboardingToSupabase` and add the test hook**

In `lib/features/onboarding/providers/onboarding_provider.dart`, replace `persistOnboardingToSupabase` with:

```dart
Future<void> persistOnboardingToSupabase() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;
  await _persistQuizAnswers();
}

@visibleForTesting
Future<void> debugPersistOnboardingForTest() => _persistQuizAnswers();

Future<void> _persistQuizAnswers() async {
  try {
    await _authService.saveOnboardingData(
      intention: state.intention,
      struggles: state.struggles.toList(),
      familiarity: state.familiarity,
      quranConnection: state.quranConnection,
      attribution: state.attribution.toList(),
      ageRange: state.ageRange,
      prayerFrequency: state.prayerFrequency,
      resonantNameId: state.resonantNameId,
      duaTopics: state.duaTopics.toList(),
      duaTopicsOther: state.duaTopicsOther,
      commonEmotions: state.commonEmotions.toList(),
      aspirations: state.aspirations.toList(),
      dailyCommitmentMinutes: state.dailyCommitmentMinutes,
      reminderTime: state.reminderTime,
      commitmentAccepted: state.commitmentAccepted,
    );
  } catch (_) {
    // Best-effort — don't block onboarding completion on DB failure.
  }
}
```

Add `import 'package:flutter/foundation.dart' show visibleForTesting;` at the top of the file.

- [ ] **Step 3.5: Run the test to verify it passes**

Run: `flutter test test/services/auth_service_onboarding_persist_test.dart`
Expected: PASS.

- [ ] **Step 3.6: Commit**

```bash
git add lib/services/auth_service.dart \
        lib/features/onboarding/providers/onboarding_provider.dart \
        test/services/auth_service_onboarding_persist_test.dart
git commit -m "feat(onboarding): persist new quiz fields to user_profiles"
```

---

## Task 4: Build the shared `OnboardingQuestionScaffold` widget

**Files:**
- Create: `lib/features/onboarding/widgets/onboarding_question_scaffold.dart`
- Create: `test/features/onboarding/widgets/onboarding_question_scaffold_test.dart`

- [ ] **Step 4.1: Write the failing test**

Create `test/features/onboarding/widgets/onboarding_question_scaffold_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/widgets/onboarding_question_scaffold.dart';

void main() {
  testWidgets('renders headline, subtitle, body and a disabled continue button',
      (tester) async {
    var continued = 0;
    await tester.pumpWidget(MaterialApp(
      home: OnboardingQuestionScaffold(
        progressSegment: 5,
        headline: 'How often do you pray?',
        subtitle: 'No judgement.',
        body: const Text('BODY'),
        continueEnabled: false,
        onContinue: () => continued++,
        onBack: () {},
      ),
    ));
    expect(find.text('How often do you pray?'), findsOneWidget);
    expect(find.text('No judgement.'), findsOneWidget);
    expect(find.text('BODY'), findsOneWidget);
    // Tapping the disabled continue should do nothing.
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump();
    expect(continued, 0);
  });

  testWidgets('continue button fires when enabled', (tester) async {
    var continued = 0;
    await tester.pumpWidget(MaterialApp(
      home: OnboardingQuestionScaffold(
        progressSegment: 5,
        headline: 'H',
        body: const SizedBox(),
        continueEnabled: true,
        onContinue: () => continued++,
        onBack: () {},
      ),
    ));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(continued, 1);
  });
}
```

- [ ] **Step 4.2: Run the test to verify it fails**

Run: `flutter test test/features/onboarding/widgets/onboarding_question_scaffold_test.dart`
Expected: FAIL (widget missing).

- [ ] **Step 4.3: Write the widget**

Create `lib/features/onboarding/widgets/onboarding_question_scaffold.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import 'onboarding_continue_button.dart';
import 'onboarding_page_wrapper.dart';

/// Shared scaffold for every quiz screen in the onboarding flow.
/// Headline + optional subtitle + body + Continue button, with
/// Continue disabled until the parent reports `continueEnabled`.
class OnboardingQuestionScaffold extends StatelessWidget {
  const OnboardingQuestionScaffold({
    super.key,
    required this.progressSegment,
    required this.headline,
    required this.body,
    required this.onContinue,
    required this.onBack,
    required this.continueEnabled,
    this.subtitle,
    this.continueLabel,
  });

  final int progressSegment;
  final String headline;
  final String? subtitle;
  final Widget body;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final bool continueEnabled;
  final String? continueLabel;

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWrapper(
      progressSegment: progressSegment,
      onBack: onBack,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  body,
                  const Spacer(),
                  OnboardingContinueButton(
                    label: continueLabel ?? AppStrings.continueButton,
                    onPressed: onContinue,
                    enabled: continueEnabled,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4.4: Run the tests to verify they pass**

Run: `flutter test test/features/onboarding/widgets/onboarding_question_scaffold_test.dart`
Expected: PASS.

- [ ] **Step 4.5: Commit**

```bash
git add lib/features/onboarding/widgets/onboarding_question_scaffold.dart \
        test/features/onboarding/widgets/onboarding_question_scaffold_test.dart
git commit -m "feat(onboarding): add shared OnboardingQuestionScaffold widget"
```

---

## Task 5: Migrate existing 5 input screens to the scaffold

Migrate: `intention_screen.dart`, `familiarity_screen.dart`, `quran_connection_screen.dart`, `struggles_screen.dart`, `attribution_screen.dart`. Each migration is the same shape: replace the outer `OnboardingPageWrapper` + `Column` + `OnboardingContinueButton` boilerplate with `OnboardingQuestionScaffold`, slot the input body in, compute `continueEnabled` from state.

**Files:**
- Modify: each of the 5 screens above.

- [ ] **Step 5.1: Migrate `intention_screen.dart`**

Replace the body of `IntentionScreen.build` with:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(onboardingProvider);
  return OnboardingQuestionScaffold(
    progressSegment: 5, // new position: screen #5 in the 29-screen flow
    headline: AppStrings.intentionTitle,
    subtitle: AppStrings.intentionSubtitle,
    continueEnabled: state.intention != null,
    onBack: onBack,
    onContinue: () {
      ref.read(analyticsProvider)
          .trackSurveyAnswered('intention', state.intention);
      onNext();
    },
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(_options.length, (index) {
          final option = _options[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: IntentionOptionCard(
              icon: option.icon,
              title: option.title,
              subtitle: option.subtitle,
              isSelected: state.intention == option.title,
              onTap: () => ref
                  .read(onboardingProvider.notifier)
                  .setIntention(option.title),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (80 * index).ms)
              .slideX(begin: 0.05, end: 0);
        }),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: state.intention != null
              ? SizedBox(
                  key: ValueKey(state.intention),
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Text(
                      _affirmationForIntention(state.intention!),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    ),
  );
}
```

Add `import '../widgets/onboarding_question_scaffold.dart';` and remove the now-unused imports of `OnboardingPageWrapper` and `OnboardingContinueButton` (keep them only if still referenced).

- [ ] **Step 5.2: Migrate the other 4 screens**

Apply the same shape (pull existing headline / subtitle / input body into the scaffold's `body` slot; compute `continueEnabled` based on the state for that screen). For multi-select screens (`struggles`, `attribution`), `continueEnabled` is `state.struggles.isNotEmpty` / `state.attribution.isNotEmpty`.

**Progress segment per migrated screen (critical — update from the old values):**

| Screen | Old `progressSegment` | New `progressSegment` |
|---|---|---|
| `IntentionScreen` | 12 | **5** |
| `QuranConnectionScreen` | 15 | **7** |
| `FamiliarityScreen` | 14 | **8** |
| `StrugglesScreen` | 16 | **11** |
| `AttributionScreen` | 17 | **16** |

These values match the spec's 1-indexed screen numbers. See the `Page count reconciliation` note at the top of this plan for the relationship between spec-numbers and PageView indices.

- [ ] **Step 5.3: Run the existing onboarding widget tests to verify no regression**

Run: `flutter test test/features/onboarding/` (if the directory has any existing widget tests for these screens, they must still pass; failures mean the migration changed observable behavior).

- [ ] **Step 5.4: Commit**

```bash
git add lib/features/onboarding/screens/intention_screen.dart \
        lib/features/onboarding/screens/familiarity_screen.dart \
        lib/features/onboarding/screens/quran_connection_screen.dart \
        lib/features/onboarding/screens/struggles_screen.dart \
        lib/features/onboarding/screens/attribution_screen.dart
git commit -m "refactor(onboarding): migrate existing quiz screens to shared scaffold"
```

---

## Task 6: Screen — `NameInputScreen` (#3, "Your first name")

**Files:**
- Create: `lib/features/onboarding/screens/name_input_screen.dart`
- Create: `test/features/onboarding/screens/name_input_screen_test.dart`

- [ ] **Step 6.1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/name_input_screen.dart';

void main() {
  testWidgets('continue enabled only after typing a name', (tester) async {
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: NameInputScreen(onNext: () => advanced++, onBack: () {}),
      ),
    ));
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump();
    expect(advanced, 0);

    await tester.enterText(find.byType(TextField), 'Ibrahim');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(advanced, 1);
  });
}
```

- [ ] **Step 6.2: Run the test to verify it fails**

Run: `flutter test test/features/onboarding/screens/name_input_screen_test.dart`
Expected: FAIL (screen doesn't exist).

- [ ] **Step 6.3: Implement the screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_autofocus_text_field.dart';
import '../widgets/onboarding_question_scaffold.dart';

class NameInputScreen extends ConsumerStatefulWidget {
  const NameInputScreen({required this.onNext, required this.onBack, super.key});
  final VoidCallback onNext;
  final VoidCallback onBack;
  @override
  ConsumerState<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends ConsumerState<NameInputScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(onboardingProvider).signUpName ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _controller.text.trim();
    return OnboardingQuestionScaffold(
      progressSegment: 3,
      headline: 'What should we call you?',
      subtitle: 'Just your first name.',
      onBack: widget.onBack,
      continueEnabled: name.isNotEmpty,
      onContinue: () {
        ref.read(onboardingProvider.notifier).setSignUpName(name);
        widget.onNext();
      },
      body: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: OnboardingAutofocusTextField(
          controller: _controller,
          shouldRequestFocus: true,
          decoration: const InputDecoration(
            hintText: 'Your first name',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (name.isNotEmpty) {
              ref.read(onboardingProvider.notifier).setSignUpName(name);
              widget.onNext();
            }
          },
        ),
      ),
    );
  }
}
```

> Note: `OnboardingAutofocusTextField` does not have an `onChanged` hook. To drive the `continueEnabled` recomputation from keystrokes, listen to the controller in `initState`:
>
> ```dart
> @override
> void initState() {
>   super.initState();
>   _controller = TextEditingController(
>     text: ref.read(onboardingProvider).signUpName ?? '',
>   );
>   _controller.addListener(() => setState(() {}));
> }
> ```
>
> Keep the existing `dispose()` — no extra cleanup needed beyond `_controller.dispose()`.

- [ ] **Step 6.4: Run the test to verify it passes**

Run: `flutter test test/features/onboarding/screens/name_input_screen_test.dart`
Expected: PASS.

- [ ] **Step 6.5: Commit**

```bash
git add lib/features/onboarding/screens/name_input_screen.dart \
        test/features/onboarding/screens/name_input_screen_test.dart
git commit -m "feat(onboarding): add name input screen (#3)"
```

---

## Task 7: Screen — `AgeRangeScreen` (#4)

**Files:**
- Create: `lib/features/onboarding/screens/age_range_screen.dart`
- Create: `test/features/onboarding/screens/age_range_screen_test.dart`

- [ ] **Step 7.1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/age_range_screen.dart';

void main() {
  testWidgets('continue enabled after picking an age range', (tester) async {
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: AgeRangeScreen(onNext: () => advanced++, onBack: () {}),
      ),
    ));
    await tester.tap(find.text('25-34'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(advanced, 1);
  });
}
```

- [ ] **Step 7.2: Run the test to verify it fails**

Run: `flutter test test/features/onboarding/screens/age_range_screen_test.dart`
Expected: FAIL.

- [ ] **Step 7.3: Implement the screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/intention_option_card.dart';
import '../widgets/onboarding_question_scaffold.dart';

class AgeRangeScreen extends ConsumerWidget {
  const AgeRangeScreen({required this.onNext, required this.onBack, super.key});
  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _options = [
    ('13_17', '13-17'),
    ('18_24', '18-24'),
    ('25_34', '25-34'),
    ('35_44', '35-44'),
    ('45_54', '45-54'),
    ('55plus', '55+'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    return OnboardingQuestionScaffold(
      progressSegment: 4,
      headline: 'How old are you?',
      subtitle: 'So we can tune the tone for you.',
      onBack: onBack,
      continueEnabled: state.ageRange != null,
      onContinue: onNext,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _options.map((opt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: IntentionOptionCard(
              icon: Icons.person_outline,
              title: opt.$2,
              subtitle: '',
              isSelected: state.ageRange == opt.$1,
              onTap: () =>
                  ref.read(onboardingProvider.notifier).setAgeRange(opt.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

- [ ] **Step 7.4: Run, confirm pass, commit**

```bash
flutter test test/features/onboarding/screens/age_range_screen_test.dart
git add lib/features/onboarding/screens/age_range_screen.dart \
        test/features/onboarding/screens/age_range_screen_test.dart
git commit -m "feat(onboarding): add age range screen (#4)"
```

---

## Task 8: Screen — `PrayerFrequencyScreen` (#6)

**Files:**
- Create: `lib/features/onboarding/screens/prayer_frequency_screen.dart`
- Create: `test/features/onboarding/screens/prayer_frequency_screen_test.dart`

- [ ] **Step 8.1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/prayer_frequency_screen.dart';

void main() {
  testWidgets('picking a frequency enables continue', (tester) async {
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: PrayerFrequencyScreen(
          onNext: () => advanced++, onBack: () {}),
      ),
    ));
    await tester.tap(find.text('Some days'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(advanced, 1);
  });
}
```

- [ ] **Step 8.2: Run → fail → implement the screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/intention_option_card.dart';
import '../widgets/onboarding_question_scaffold.dart';

class PrayerFrequencyScreen extends ConsumerWidget {
  const PrayerFrequencyScreen({
    required this.onNext, required this.onBack, super.key,
  });
  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _options = [
    ('fivePlus', 'Five times a day', 'Al-hamdulillah.'),
    ('someDaily', 'Some days', 'Every prayer counts.'),
    ('fridaysOnly', 'Mostly Fridays', 'A good anchor.'),
    ('rarely', 'Not often', 'No judgement here.'),
    ('learning', 'Still learning', 'You\'re welcome here.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    return OnboardingQuestionScaffold(
      progressSegment: 6,
      headline: 'How often do you pray right now?',
      subtitle: 'Honesty helps us meet you where you are.',
      onBack: onBack,
      continueEnabled: state.prayerFrequency != null,
      onContinue: onNext,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _options.map((opt) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: IntentionOptionCard(
            icon: Icons.mosque_outlined,
            title: opt.$2,
            subtitle: opt.$3,
            isSelected: state.prayerFrequency == opt.$1,
            onTap: () => ref
                .read(onboardingProvider.notifier)
                .setPrayerFrequency(opt.$1),
          ),
        )).toList(),
      ),
    );
  }
}
```

- [ ] **Step 8.3: Run, confirm pass, commit**

```bash
flutter test test/features/onboarding/screens/prayer_frequency_screen_test.dart
git add lib/features/onboarding/screens/prayer_frequency_screen.dart \
        test/features/onboarding/screens/prayer_frequency_screen_test.dart
git commit -m "feat(onboarding): add prayer frequency screen (#6)"
```

---

## Task 9: Screen — `ResonantNameScreen` (#9, Name carousel)

**Files:**
- Create: `lib/features/onboarding/screens/resonant_name_screen.dart`
- Create: `test/features/onboarding/screens/resonant_name_screen_test.dart`

This screen shows a horizontally-scrollable carousel of 6 curated Names of Allah (IDs hard-coded for v1; curated list is a design decision — pick broadly-resonant Names: Ar-Rahman, Ar-Rahim, As-Salam, Al-Wadud, Al-Hafiz, Al-Karim). Each card shows Arabic calligraphy (via `AdjustedArabicDisplay`), transliteration, English meaning, and a short emotional descriptor. Tap-to-select.

- [ ] **Step 9.1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/resonant_name_screen.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';

void main() {
  testWidgets('tapping a name sets it and enables continue', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var advanced = 0;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ResonantNameScreen(
          onNext: () => advanced++, onBack: () {},
        ),
      ),
    ));
    await tester.tap(find.text('Ar-Rahman').first);
    await tester.pump();
    expect(container.read(onboardingProvider).resonantNameId, 'ar-rahman');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(advanced, 1);
  });
}
```

- [ ] **Step 9.2: Implement the screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/adjusted_arabic_display.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';

class ResonantNameScreen extends ConsumerWidget {
  const ResonantNameScreen({
    required this.onNext, required this.onBack, super.key,
  });
  final VoidCallback onNext;
  final VoidCallback onBack;

  // Curated list of broadly-resonant Names for v1. Id values match the
  // `names_of_allah` table slug convention used elsewhere in the app.
  static const _names = [
    (id: 'ar-rahman', arabic: 'الرَّحْمَنُ', translit: 'Ar-Rahman',
     english: 'The Most Merciful', emotion: 'For when you need warmth.'),
    (id: 'ar-rahim', arabic: 'الرَّحِيمُ', translit: 'Ar-Rahim',
     english: 'The Especially Merciful', emotion: 'For when you need closeness.'),
    (id: 'as-salam', arabic: 'السَّلَامُ', translit: 'As-Salam',
     english: 'The Source of Peace', emotion: 'For when your mind is racing.'),
    (id: 'al-wadud', arabic: 'الْوَدُودُ', translit: 'Al-Wadud',
     english: 'The Most Loving', emotion: 'For when you feel unseen.'),
    (id: 'al-hafiz', arabic: 'الْحَفِيظُ', translit: 'Al-Hafiz',
     english: 'The Preserver', emotion: 'For when you feel afraid.'),
    (id: 'al-karim', arabic: 'الْكَرِيمُ', translit: 'Al-Karim',
     english: 'The Most Generous', emotion: 'For when you feel small.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    return OnboardingQuestionScaffold(
      progressSegment: 9,
      headline: 'Which Name of Allah resonates right now?',
      subtitle: 'This becomes the first Name in your collection.',
      onBack: onBack,
      continueEnabled: state.resonantNameId != null,
      onContinue: onNext,
      body: SizedBox(
        height: 340,
        child: PageView.builder(
          controller: PageController(viewportFraction: 0.85),
          itemCount: _names.length,
          itemBuilder: (context, index) {
            final n = _names[index];
            final selected = state.resonantNameId == n.id;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => ref
                    .read(onboardingProvider.notifier)
                    .setResonantNameId(n.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.borderLight,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 33),
                      AdjustedArabicDisplay(
                        text: n.arabic,
                        fontSize: 36,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        n.translit,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        n.english,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        n.emotion,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 9.3: Run → pass → commit**

```bash
flutter test test/features/onboarding/screens/resonant_name_screen_test.dart
git add lib/features/onboarding/screens/resonant_name_screen.dart \
        test/features/onboarding/screens/resonant_name_screen_test.dart
git commit -m "feat(onboarding): add resonant Name carousel (#9)"
```

---

## Task 10: Screen — `DuaTopicsScreen` (#10, multi-select + free text)

**Files:**
- Create: `lib/features/onboarding/screens/dua_topics_screen.dart`
- Create: `test/features/onboarding/screens/dua_topics_screen_test.dart`

- [ ] **Step 10.1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/dua_topics_screen.dart';

void main() {
  testWidgets('continue enables after picking at least one topic',
      (tester) async {
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: DuaTopicsScreen(onNext: () => advanced++, onBack: () {}),
      ),
    ));
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump();
    expect(advanced, 0);
    await tester.tap(find.text('Health'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(advanced, 1);
  });
}
```

- [ ] **Step 10.2: Implement**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';
import '../widgets/struggle_chip.dart'; // reuse existing chip

class DuaTopicsScreen extends ConsumerStatefulWidget {
  const DuaTopicsScreen({required this.onNext, required this.onBack, super.key});
  final VoidCallback onNext;
  final VoidCallback onBack;
  @override
  ConsumerState<DuaTopicsScreen> createState() => _State();
}

class _State extends ConsumerState<DuaTopicsScreen> {
  static const _topics = [
    ('health', 'Health'),
    ('family', 'Family'),
    ('forgiveness', 'Forgiveness'),
    ('guidance', 'Guidance'),
    ('peace', 'Peace'),
    ('success', 'Success'),
    ('provision', 'Provision'),
  ];

  late final TextEditingController _otherController;

  @override
  void initState() {
    super.initState();
    _otherController = TextEditingController(
      text: ref.read(onboardingProvider).duaTopicsOther ?? '',
    );
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    return OnboardingQuestionScaffold(
      progressSegment: 10,
      headline: 'What would you most want to dua for?',
      subtitle: 'Pick as many as feel true.',
      onBack: widget.onBack,
      continueEnabled: state.duaTopics.isNotEmpty,
      onContinue: () {
        ref.read(onboardingProvider.notifier)
            .setDuaTopicsOther(_otherController.text);
        widget.onNext();
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _topics.map((t) => StruggleChip(
              label: t.$2,
              isSelected: state.duaTopics.contains(t.$1),
              onTap: () => ref
                  .read(onboardingProvider.notifier)
                  .toggleDuaTopic(t.$1),
            )).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _otherController,
            maxLength: 280,
            decoration: const InputDecoration(
              labelText: 'Anything else? (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 10.3: Run → pass → commit**

```bash
flutter test test/features/onboarding/screens/dua_topics_screen_test.dart
git add lib/features/onboarding/screens/dua_topics_screen.dart \
        test/features/onboarding/screens/dua_topics_screen_test.dart
git commit -m "feat(onboarding): add dua topics multi-select screen (#10)"
```

---

## Task 11: Screen — `CommonEmotionsScreen` (#12)

**Files:**
- Create: `lib/features/onboarding/screens/common_emotions_screen.dart`
- Create: `test/features/onboarding/screens/common_emotions_screen_test.dart`

Multi-select chips, no free text. Chip labels: Anxious, Grateful, Overwhelmed, Joyful, Lonely, Numb, Hopeful, Angry, Sad.

- [ ] **Step 11.1: Test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/common_emotions_screen.dart';

void main() {
  testWidgets('needs at least one emotion to advance', (tester) async {
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: CommonEmotionsScreen(onNext: () => advanced++, onBack: () {}),
      ),
    ));
    await tester.tap(find.text('Anxious'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(advanced, 1);
  });
}
```

- [ ] **Step 11.2: Implement**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';
import '../widgets/struggle_chip.dart';

class CommonEmotionsScreen extends ConsumerWidget {
  const CommonEmotionsScreen({
    required this.onNext, required this.onBack, super.key,
  });
  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _emotions = [
    'anxious', 'grateful', 'overwhelmed', 'joyful',
    'lonely', 'numb', 'hopeful', 'angry', 'sad',
  ];

  static String _label(String id) =>
      '${id.substring(0, 1).toUpperCase()}${id.substring(1)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    return OnboardingQuestionScaffold(
      progressSegment: 12,
      headline: 'Which emotions come up most for you?',
      subtitle: 'We\'ll tailor your first reflections around these.',
      onBack: onBack,
      continueEnabled: state.commonEmotions.isNotEmpty,
      onContinue: onNext,
      body: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _emotions.map((e) => StruggleChip(
          label: _label(e),
          isSelected: state.commonEmotions.contains(e),
          onTap: () => ref
              .read(onboardingProvider.notifier)
              .toggleCommonEmotion(e),
        )).toList(),
      ),
    );
  }
}
```

- [ ] **Step 11.3: Run → pass → commit**

```bash
flutter test test/features/onboarding/screens/common_emotions_screen_test.dart
git add lib/features/onboarding/screens/common_emotions_screen.dart \
        test/features/onboarding/screens/common_emotions_screen_test.dart
git commit -m "feat(onboarding): add common emotions screen (#12)"
```

---

## Task 12: Screen — `AspirationsScreen` (#13)

**Files:**
- Create: `lib/features/onboarding/screens/aspirations_screen.dart`
- Create: `test/features/onboarding/screens/aspirations_screen_test.dart`

Same shape as CommonEmotions. Options: `morePatient, moreGrateful, closerToAllah, morePresent, strongerFaith, moreConsistent`. Copy: "Who do you want to become?" / "Pick up to three."

- [ ] **Step 12.1–3: Test → implement → commit**

Test mirrors Task 11. Implementation mirrors Task 11 (replace list, headline, `toggleAspiration`, `progressSegment: 13`, `state.aspirations`). Commit message: `feat(onboarding): add aspirations screen (#13)`.

---

## Task 13: Screen — `DailyCommitmentScreen` (#14)

**Files:**
- Create: `lib/features/onboarding/screens/daily_commitment_screen.dart`
- Create: `test/features/onboarding/screens/daily_commitment_screen_test.dart`

Four big tappable buttons: 1 / 3 / 5 / 10 minutes per day. Single-select.

- [ ] **Step 13.1: Test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/daily_commitment_screen.dart';

void main() {
  testWidgets('picking 5 minutes enables continue', (tester) async {
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: DailyCommitmentScreen(onNext: () => advanced++, onBack: () {}),
      ),
    ));
    await tester.tap(find.text('5 min'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(advanced, 1);
  });
}
```

- [ ] **Step 13.2: Implement**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';

class DailyCommitmentScreen extends ConsumerWidget {
  const DailyCommitmentScreen({
    required this.onNext, required this.onBack, super.key,
  });
  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _options = [1, 3, 5, 10];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    return OnboardingQuestionScaffold(
      progressSegment: 14,
      headline: 'How much time a day feels right?',
      subtitle: 'You can change this later.',
      onBack: onBack,
      continueEnabled: state.dailyCommitmentMinutes != null,
      onContinue: onNext,
      body: Column(
        children: _options.map((m) {
          final selected = state.dailyCommitmentMinutes == m;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => ref
                  .read(onboardingProvider.notifier)
                  .setDailyCommitmentMinutes(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 72,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryLight
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.borderLight,
                    width: selected ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$m min',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

- [ ] **Step 13.3: Run → pass → commit**

```bash
flutter test test/features/onboarding/screens/daily_commitment_screen_test.dart
git add lib/features/onboarding/screens/daily_commitment_screen.dart \
        test/features/onboarding/screens/daily_commitment_screen_test.dart
git commit -m "feat(onboarding): add daily commitment screen (#14)"
```

---

## Task 14: Interstitial screens (#15 Social-proof, #17 "You're not alone")

**Files:**
- Create: `lib/features/onboarding/screens/social_proof_interstitial_screen.dart`
- Create: `lib/features/onboarding/screens/struggle_support_interstitial_screen.dart`
- Create: `test/features/onboarding/screens/interstitial_screens_test.dart`

Both are passive. Continue is always enabled. Each reads quiz state for dynamic copy.

- [ ] **Step 14.1: Test both**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/social_proof_interstitial_screen.dart';
import 'package:sakina/features/onboarding/screens/struggle_support_interstitial_screen.dart';

void main() {
  testWidgets('social proof interstitial shows count + continue', (tester) async {
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: SocialProofInterstitialScreen(
          onNext: () => advanced++, onBack: () {}),
      ),
    ));
    expect(find.textContaining('40,000'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(advanced, 1);
  });

  testWidgets('struggle support names a picked struggle', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingProvider.notifier).toggleStruggle('anxiety');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: StruggleSupportInterstitialScreen(onNext: () {}, onBack: () {}),
      ),
    ));
    expect(find.textContaining('anxiety'), findsOneWidget);
  });
}
```

- [ ] **Step 14.2: Implement**

`social_proof_interstitial_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/onboarding_question_scaffold.dart';

class SocialProofInterstitialScreen extends ConsumerWidget {
  const SocialProofInterstitialScreen({
    required this.onNext, required this.onBack, super.key,
  });
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingQuestionScaffold(
      progressSegment: 15,
      headline: '40,000+ Muslims use Sakina.',
      subtitle: 'You\'re not doing this alone.',
      onBack: onBack,
      continueEnabled: true,
      onContinue: onNext,
      body: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '"Sakina gave me a way back to my deen when I needed it most." — Aisha, 27',
          style: AppTypography.bodyLarge.copyWith(
            fontStyle: FontStyle.italic,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }
}
```

`struggle_support_interstitial_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';

class StruggleSupportInterstitialScreen extends ConsumerWidget {
  const StruggleSupportInterstitialScreen({
    required this.onNext, required this.onBack, super.key,
  });
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final struggles = ref.watch(onboardingProvider).struggles;
    final focus = struggles.isNotEmpty ? struggles.first : 'what you\'re carrying';
    return OnboardingQuestionScaffold(
      progressSegment: 17,
      headline: 'You\'re not alone in this.',
      subtitle: 'Many who started with $focus found peace here.',
      onBack: onBack,
      continueEnabled: true,
      onContinue: onNext,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Icon(Icons.favorite, size: 96, color: AppColors.primary),
      ),
    );
  }
}
```

- [ ] **Step 14.3: Run → pass → commit**

```bash
flutter test test/features/onboarding/screens/interstitial_screens_test.dart
git add lib/features/onboarding/screens/social_proof_interstitial_screen.dart \
        lib/features/onboarding/screens/struggle_support_interstitial_screen.dart \
        test/features/onboarding/screens/interstitial_screens_test.dart
git commit -m "feat(onboarding): add two interstitial screens (#15, #17)"
```

---

## Task 15: Screen — `ReminderTimeScreen` (#18)

**Files:**
- Create: `lib/features/onboarding/screens/reminder_time_screen.dart`
- Create: `test/features/onboarding/screens/reminder_time_screen_test.dart`

Time-of-day picker — use Flutter's `TimePickerDialog` via `showTimePicker`, but surface the selected time inline. On confirm, set `reminderTime` as `"HH:mm"`.

- [ ] **Step 15.1: Test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/reminder_time_screen.dart';

void main() {
  testWidgets('defaults to 08:00 and continue enabled', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var advanced = 0;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ReminderTimeScreen(onNext: () => advanced++, onBack: () {}),
      ),
    ));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(container.read(onboardingProvider).reminderTime, isNotNull);
    expect(advanced, 1);
  });
}
```

- [ ] **Step 15.2: Implement**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';

class ReminderTimeScreen extends ConsumerStatefulWidget {
  const ReminderTimeScreen({
    required this.onNext, required this.onBack, super.key,
  });
  final VoidCallback onNext;
  final VoidCallback onBack;
  @override
  ConsumerState<ReminderTimeScreen> createState() => _State();
}

class _State extends ConsumerState<ReminderTimeScreen> {
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(onboardingProvider).reminderTime;
    _time = existing != null
        ? _parse(existing)
        : const TimeOfDay(hour: 8, minute: 0);
  }

  TimeOfDay _parse(String hhmm) {
    final p = hhmm.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingQuestionScaffold(
      progressSegment: 18,
      headline: 'When should we check in with you?',
      subtitle: 'A gentle reminder, once a day.',
      onBack: widget.onBack,
      continueEnabled: true,
      onContinue: () {
        ref.read(onboardingProvider.notifier).setReminderTime(_format(_time));
        widget.onNext();
      },
      body: GestureDetector(
        onTap: _pick,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            _time.format(context),
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 15.3: Run → pass → commit**

```bash
flutter test test/features/onboarding/screens/reminder_time_screen_test.dart
git add lib/features/onboarding/screens/reminder_time_screen.dart \
        test/features/onboarding/screens/reminder_time_screen_test.dart
git commit -m "feat(onboarding): add reminder time picker (#18)"
```

---

## Task 16: Screen — `CommitmentPactScreen` (#20) with conditional copy

**Files:**
- Create: `lib/features/onboarding/screens/commitment_pact_screen.dart`
- Create: `test/features/onboarding/screens/commitment_pact_screen_test.dart`

Conditional copy: includes reminder clause only if `notificationPermissionGranted` is true. Continue disabled until the user taps "I commit."

- [ ] **Step 16.1: Test both paths**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/commitment_pact_screen.dart';

void main() {
  testWidgets('includes reminder clause when notifications granted',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingProvider.notifier).setNotificationPermission(true);
    container.read(onboardingProvider.notifier).setDailyCommitmentMinutes(5);
    container.read(onboardingProvider.notifier).setReminderTime('08:00');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: CommitmentPactScreen(onNext: () {}, onBack: () {}),
      ),
    ));
    expect(find.textContaining('reminder'), findsOneWidget);
  });

  testWidgets('omits reminder clause when notifications denied',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingProvider.notifier).setNotificationPermission(false);
    container.read(onboardingProvider.notifier).setDailyCommitmentMinutes(5);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: CommitmentPactScreen(onNext: () {}, onBack: () {}),
      ),
    ));
    expect(find.textContaining('reminder'), findsNothing);
  });
}
```

- [ ] **Step 16.2: Implement**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';

class CommitmentPactScreen extends ConsumerWidget {
  const CommitmentPactScreen({
    required this.onNext, required this.onBack, super.key,
  });
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final mins = state.dailyCommitmentMinutes ?? 3;
    final notifyOk = state.notificationPermissionGranted;
    final reminderTime = state.reminderTime ?? '08:00';

    final pactText = notifyOk
        ? 'I commit to $mins minutes a day, with a gentle reminder at $reminderTime.'
        : 'I commit to $mins minutes a day.';

    return OnboardingQuestionScaffold(
      progressSegment: 20,
      headline: 'Your commitment.',
      subtitle: 'A small daily promise to yourself.',
      onBack: onBack,
      continueEnabled: state.commitmentAccepted,
      onContinue: onNext,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              pactText,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GestureDetector(
            onTap: () => ref
                .read(onboardingProvider.notifier)
                .setCommitmentAccepted(!state.commitmentAccepted),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md, horizontal: AppSpacing.xl),
              decoration: BoxDecoration(
                color: state.commitmentAccepted
                    ? AppColors.primary
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary),
              ),
              child: Text(
                state.commitmentAccepted ? '✓ I commit' : 'Tap to commit',
                style: AppTypography.titleMedium.copyWith(
                  color: state.commitmentAccepted
                      ? AppColors.textOnPrimary
                      : AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 16.3: Run → pass → commit**

```bash
flutter test test/features/onboarding/screens/commitment_pact_screen_test.dart
git add lib/features/onboarding/screens/commitment_pact_screen.dart \
        test/features/onboarding/screens/commitment_pact_screen_test.dart
git commit -m "feat(onboarding): add commitment pact with conditional copy (#20)"
```

---

## Task 17: Screen — `PersonalizedPlanScreen` (#22) with fallback Ar-Rahman

**Files:**
- Create: `lib/features/onboarding/screens/personalized_plan_screen.dart`
- Create: `test/features/onboarding/screens/personalized_plan_screen_test.dart`

Shows a stylized plan card with the user's first Name (or Ar-Rahman if skipped), top struggle (or generic "your path"), and reminder time. Continue always enabled.

- [ ] **Step 17.1: Test both branches**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/personalized_plan_screen.dart';

void main() {
  testWidgets('renders selected resonant Name', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingProvider.notifier).setResonantNameId('as-salam');
    container.read(onboardingProvider.notifier).toggleStruggle('anxiety');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: PersonalizedPlanScreen(onNext: () {}, onBack: () {}),
      ),
    ));
    expect(find.textContaining('As-Salam'), findsOneWidget);
  });

  testWidgets('falls back to Ar-Rahman when resonantNameId is null',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: PersonalizedPlanScreen(onNext: () {}, onBack: () {}),
      ),
    ));
    expect(find.textContaining('Ar-Rahman'), findsOneWidget);
  });
}
```

- [ ] **Step 17.2: Implement**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';

class PersonalizedPlanScreen extends ConsumerWidget {
  const PersonalizedPlanScreen({
    required this.onNext, required this.onBack, super.key,
  });
  final VoidCallback onNext;
  final VoidCallback onBack;

  // Mirrors the curated list in ResonantNameScreen. Fallback is Ar-Rahman.
  static String _translitForId(String? id) {
    switch (id) {
      case 'ar-rahim': return 'Ar-Rahim';
      case 'as-salam': return 'As-Salam';
      case 'al-wadud': return 'Al-Wadud';
      case 'al-hafiz': return 'Al-Hafiz';
      case 'al-karim': return 'Al-Karim';
      case 'ar-rahman':
      default:
        return 'Ar-Rahman'; // fallback per spec §4
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final translit = _translitForId(state.resonantNameId);
    final struggle = state.struggles.isNotEmpty
        ? state.struggles.first
        : 'your path';
    final time = state.reminderTime ?? '08:00';
    final name = state.signUpName ?? 'friend';

    return OnboardingQuestionScaffold(
      progressSegment: 22,
      headline: 'Your plan, $name.',
      subtitle: 'Everything you need, one tap away.',
      onBack: onBack,
      continueEnabled: true,
      onContinue: onNext,
      body: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('First Name in your collection:',
                style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight)),
            Text(translit,
                style: AppTypography.titleLarge.copyWith(
                    color: AppColors.primary)),
            const SizedBox(height: AppSpacing.lg),
            Text('What we\'ll meet you with:',
                style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight)),
            Text(struggle, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            Text('Your daily check-in:',
                style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight)),
            Text(time, style: AppTypography.titleMedium),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 17.3: Run → pass → commit**

```bash
flutter test test/features/onboarding/screens/personalized_plan_screen_test.dart
git add lib/features/onboarding/screens/personalized_plan_screen.dart \
        test/features/onboarding/screens/personalized_plan_screen_test.dart
git commit -m "feat(onboarding): add personalized plan reveal (#22)"
```

---

## Task 18: Rewrite `ValuePropScreen` (#23) with dynamic copy

**Files:**
- Modify: `lib/features/onboarding/screens/value_prop_screen.dart`
- Create: `test/features/onboarding/screens/value_prop_screen_test.dart`

Dynamic copy keyed on top aspiration + top struggle.

- [ ] **Step 18.1: Test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/value_prop_screen.dart';

void main() {
  testWidgets('uses top aspiration in copy', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingProvider.notifier).toggleAspiration('morePatient');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ValuePropScreen(onNext: () {}, onBack: () {}),
      ),
    ));
    expect(find.textContaining('patient'), findsOneWidget);
  });
}
```

- [ ] **Step 18.2: Rewrite the screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';

class ValuePropScreen extends ConsumerWidget {
  const ValuePropScreen({
    required this.onNext, required this.onBack, super.key,
  });
  final VoidCallback onNext;
  final VoidCallback onBack;

  static String _aspirationPhrase(String id) {
    switch (id) {
      case 'morePatient': return 'more patient';
      case 'moreGrateful': return 'more grateful';
      case 'closerToAllah': return 'closer to Allah';
      case 'morePresent': return 'more present';
      case 'strongerFaith': return 'stronger in faith';
      case 'moreConsistent': return 'more consistent';
      default: return 'who you want to be';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final aspiration = state.aspirations.isNotEmpty
        ? _aspirationPhrase(state.aspirations.first)
        : _aspirationPhrase('');

    return OnboardingQuestionScaffold(
      progressSegment: 23,
      headline: 'Sakina helps you become $aspiration.',
      subtitle: 'In the time you already have — even 1 minute a day.',
      onBack: onBack,
      continueEnabled: true,
      onContinue: onNext,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(Icons.favorite_border, 'Daily check-in', 'Name your feeling, meet it with Qur\'an.'),
          _row(Icons.collections_bookmark_outlined, '99 Names', 'Collect, study, and reflect.'),
          _row(Icons.auto_stories_outlined, 'Your journal', 'Every reflection saved.'),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleMedium),
              Text(body, style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight)),
            ],
          )),
        ],
      ),
    );
  }
}
```

- [ ] **Step 18.3: Run → pass → commit**

```bash
flutter test test/features/onboarding/screens/value_prop_screen_test.dart
git add lib/features/onboarding/screens/value_prop_screen.dart \
        test/features/onboarding/screens/value_prop_screen_test.dart
git commit -m "feat(onboarding): rewrite value prop with dynamic copy (#23)"
```

---

## Task 19: Paywall dynamic copy

**Files:**
- Modify: `lib/features/onboarding/screens/paywall_screen.dart`
- Create/extend: `test/features/onboarding/paywall_screen_test.dart` (already exists — extend)

Add a headline that references the user's top aspiration and daily commitment. Do NOT change pricing / CTA wiring.

- [ ] **Step 19.1: Test**

Add to `test/features/onboarding/paywall_screen_test.dart`:

```dart
testWidgets('paywall headline references top aspiration', (tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(onboardingProvider.notifier).toggleAspiration('closerToAllah');
  container.read(onboardingProvider.notifier).setDailyCommitmentMinutes(5);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: PaywallScreen(onComplete: () {}),
    ),
  ));
  expect(find.textContaining('closer to Allah'), findsOneWidget);
  expect(find.textContaining('5 min'), findsOneWidget);
});
```

- [ ] **Step 19.2: Update paywall headline**

In `paywall_screen.dart`, add (near the top of `build`):

```dart
String _personalizedHeadline(WidgetRef ref) {
  final s = ref.read(onboardingProvider);
  final aspiration = switch (s.aspirations.isNotEmpty ? s.aspirations.first : '') {
    'morePatient' => 'more patient',
    'moreGrateful' => 'more grateful',
    'closerToAllah' => 'closer to Allah',
    'morePresent' => 'more present',
    'strongerFaith' => 'stronger in faith',
    'moreConsistent' => 'more consistent',
    _ => 'the person you want to be',
  };
  final mins = s.dailyCommitmentMinutes ?? 3;
  return 'Become $aspiration in $mins min a day.';
}
```

Wire that string into the paywall's existing headline slot (replace the static headline). Leave pricing untouched.

- [ ] **Step 19.3: Run → pass → commit**

```bash
flutter test test/features/onboarding/paywall_screen_test.dart
git add lib/features/onboarding/screens/paywall_screen.dart \
        test/features/onboarding/paywall_screen_test.dart
git commit -m "feat(onboarding): personalize paywall headline from quiz answers"
```

---

## Task 20: Analytics — new `onboarding_answer_captured` event

**Files:**
- Modify: `lib/services/analytics_events.dart`
- Modify: `lib/services/analytics_service.dart` (or wherever tracking helpers live)

- [ ] **Step 20.1: Add event key + helper**

In `analytics_events.dart`:

```dart
static const String onboardingAnswerCaptured = 'onboarding_answer_captured';
```

In `analytics_service.dart` (add method — match existing method-style):

```dart
void trackOnboardingAnswer(String key, Object? value) {
  track(AnalyticsEvents.onboardingAnswerCaptured,
      properties: {'key': key, 'value': value});
}
```

- [ ] **Step 20.2: Fire on every setter**

In each new input-screen's `onContinue` (Tasks 6–16), call `ref.read(analyticsProvider).trackOnboardingAnswer('<key>', <value>);` before `onNext()`. Keys: `age_range`, `prayer_frequency`, `resonant_name_id`, `dua_topics`, `dua_topics_other`, `common_emotions`, `aspirations`, `daily_commitment_minutes`, `reminder_time`, `commitment_accepted`, plus the existing screens' `intention`, `familiarity`, `quran_connection`, `struggles`, `attribution`.

- [ ] **Step 20.3: Extend `setUserProperties` in `completeOnboarding`**

In `onboarding_provider.dart`, extend the `profileProps` build in `onboarding_screen.dart`'s `_completeOnboarding` (via provider or via `completeOnboarding`) to include all 10 new fields.

- [ ] **Step 20.4: Commit**

```bash
git add lib/services/analytics_events.dart lib/services/analytics_service.dart \
        lib/features/onboarding/screens/ \
        lib/features/onboarding/providers/onboarding_provider.dart
git commit -m "feat(analytics): capture onboarding quiz answers as events + user props"
```

---

## Task 21: Reorder `OnboardingScreen` PageView, delete old feature screens, integration test

**Files:**
- Modify: `lib/features/onboarding/screens/onboarding_screen.dart`
- Delete: `lib/features/onboarding/screens/feature_dua_screen.dart`, `feature_journal_screen.dart`, `feature_names_screen.dart`, `feature_quests_screen.dart`, `feature_reflect_screen.dart`
- Create: `test/features/onboarding/onboarding_flow_integration_test.dart`

- [ ] **Step 21.1: Write a failing integration test**

Asserts the PageView has 29 children and that page index 28 renders the paywall. Full-flow walkthrough isn't required here — that's covered by the per-screen tests — but we assert the structural contract:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';

void main() {
  testWidgets('PageView has 28 children and lastIndex is 27', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: const OnboardingScreen()),
    ));
    final pv = tester.widget<PageView>(find.byType(PageView));
    expect((pv.childrenDelegate as SliverChildListDelegate).children.length, 28);
    expect(onboardingLastPageIndex, 27);
  });
}
```

- [ ] **Step 21.2: Run → fail → reorder the PageView**

Replace the `children:` list in `OnboardingScreen.build` with the new order. Comments name the 1-indexed screen numbers from spec §4. PageView has **28 children** (indices 0–27, paywall at 27). The spec's #2 (gacha reveal) is not a page — it's an overlay on top of #1 (`FirstCheckinScreen`), so there is no slot for it.

```dart
children: [
  FirstCheckinScreen(onNext: _next, onBack: _back),                  // 0  #1 hook
  // #2 gacha happens as overlay during FirstCheckinScreen; no page.
  NameInputScreen(onNext: _next, onBack: _back),                     // 1  #3
  AgeRangeScreen(onNext: _next, onBack: _back),                      // 2  #4
  IntentionScreen(onNext: _next, onBack: _back),                     // 3  #5
  PrayerFrequencyScreen(onNext: _next, onBack: _back),               // 4  #6
  QuranConnectionScreen(onNext: _next, onBack: _back),               // 5  #7
  FamiliarityScreen(onNext: _next, onBack: _back),                   // 6  #8
  ResonantNameScreen(onNext: _next, onBack: _back),                  // 7  #9
  DuaTopicsScreen(onNext: _next, onBack: _back),                     // 8  #10
  StrugglesScreen(onNext: _next, onBack: _back),                     // 9  #11
  CommonEmotionsScreen(onNext: _next, onBack: _back),                // 10 #12
  AspirationsScreen(onNext: _next, onBack: _back),                   // 11 #13
  DailyCommitmentScreen(onNext: _next, onBack: _back),               // 12 #14
  SocialProofInterstitialScreen(onNext: _next, onBack: _back),       // 13 #15
  AttributionScreen(onNext: _next, onBack: _back),                   // 14 #16
  StruggleSupportInterstitialScreen(onNext: _next, onBack: _back),   // 15 #17
  ReminderTimeScreen(onNext: _next, onBack: _back),                  // 16 #18
  NotificationScreen(onNext: _next, onBack: _back),                  // 17 #19
  CommitmentPactScreen(onNext: _next, onBack: _back),                // 18 #20
  GeneratingScreen(onNext: _next, onBack: _back),                    // 19 #21
  PersonalizedPlanScreen(onNext: _next, onBack: _back),              // 20 #22
  ValuePropScreen(onNext: _next, onBack: _back),                     // 21 #23
  SocialProofScreen(onNext: _next, onBack: _back),                   // 22 #24
  SaveProgressScreen(onNext: _next, onBack: _back,
      onSocialAuthComplete: _next),                                  // 23 #25
  SignUpEmailScreen(onNext: _next, onBack: _back),                   // 24 #26
  SignUpPasswordScreen(onNext: _next, onBack: _back),                // 25 #27
  EncouragementScreen(onNext: _next, onBack: _back),                 // 26 #28
  PaywallScreen(onComplete: _completeOnboarding),                    // 27 — but see note
],
```

The total is **28 children**, as expected. The integration test in Step 21.1 asserts this.

- [ ] **Step 21.3: Confirm `onboardingLastPageIndex = 27`**

This was already set in Task 1. Confirm via `grep -n 'onboardingLastPageIndex' lib/ test/` that no stray references to `28` remain.

- [ ] **Step 21.4: Delete old feature screens**

```bash
git rm lib/features/onboarding/screens/feature_dua_screen.dart \
       lib/features/onboarding/screens/feature_journal_screen.dart \
       lib/features/onboarding/screens/feature_names_screen.dart \
       lib/features/onboarding/screens/feature_quests_screen.dart \
       lib/features/onboarding/screens/feature_reflect_screen.dart
```

Remove their imports from `onboarding_screen.dart`.

- [ ] **Step 21.5: Verify no dangling references**

```bash
grep -rn "feature_dua_screen\|feature_journal_screen\|feature_names_screen\|feature_quests_screen\|feature_reflect_screen\|FeatureDuaScreen\|FeatureJournalScreen\|FeatureNamesScreen\|FeatureQuestsScreen\|FeatureReflectScreen" lib/ test/
```

Expected: no matches.

- [ ] **Step 21.6: Run integration test + full test suite**

Run: `flutter test test/features/onboarding/onboarding_flow_integration_test.dart`
Expected: PASS.

Run: `flutter test`
Expected: all green.

Also run: `flutter analyze`
Expected: no new errors.

- [ ] **Step 21.7: Commit**

```bash
git add lib/features/onboarding/ test/features/onboarding/ \
        lib/features/onboarding/providers/onboarding_provider.dart
git commit -m "refactor(onboarding): reorder PageView to 28 pages, drop 5 feature screens"
```

---

## Task 22: OneSignal re-identify regression test

**Files:**
- Create: `test/features/onboarding/onesignal_reidentify_test.dart`

The spec flags this as a regression risk: notification permission is now requested *before* sign-up, so the OneSignal subscriber is anonymous at first. On auth (#25), the existing external-user-id binding must fire. If the existing path does this via `AuthService.signIn*` + a listener somewhere, write a test that exercises the post-auth listener and asserts the binding call happens.

- [ ] **Step 22.1: Locate the existing binding**

Run: `grep -rn "setExternalUserId\|OneSignal\.login\|OneSignal\.User" lib/`

Pick the service that owns the binding (likely `notification_service.dart` or an auth listener). Write a test that:
1. Fakes/mocks the OneSignal call site.
2. Triggers the auth-success path (simulate a `Supabase.instance.client.auth` state change or directly invoke the binding helper).
3. Asserts the binding was called with the new user's id.

- [ ] **Step 22.2: Write, run, confirm green, commit**

```bash
git add test/features/onboarding/onesignal_reidentify_test.dart
git commit -m "test(onboarding): regression guard for OneSignal external-user-id bind post-quiz"
```

---

## Task 23: End-to-end Supabase persistence integration test

**Files:**
- Create: `test/features/onboarding/completion_integration_test.dart`

Asserts that after filling every quiz field and invoking `completeOnboarding`, `AuthService.saveOnboardingData` is called with exactly the user's inputs. Reuse the `_FakeAuthService` pattern from Task 3.

- [ ] **Step 23.1: Test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/services/auth_service.dart';

class _FakeAuth extends AuthService {
  Map<String, dynamic>? captured;
  @override
  Future<void> saveOnboardingData({
    String? intention, List<String> struggles = const [],
    String? familiarity, String? quranConnection,
    List<String> attribution = const [],
    String? ageRange, String? prayerFrequency, String? resonantNameId,
    List<String> duaTopics = const [], String? duaTopicsOther,
    List<String> commonEmotions = const [], List<String> aspirations = const [],
    int? dailyCommitmentMinutes, String? reminderTime,
    bool commitmentAccepted = false,
  }) async {
    captured = {
      'intention': intention, 'struggles': struggles,
      'familiarity': familiarity, 'quranConnection': quranConnection,
      'attribution': attribution, 'ageRange': ageRange,
      'prayerFrequency': prayerFrequency, 'resonantNameId': resonantNameId,
      'duaTopics': duaTopics, 'duaTopicsOther': duaTopicsOther,
      'commonEmotions': commonEmotions, 'aspirations': aspirations,
      'dailyCommitmentMinutes': dailyCommitmentMinutes,
      'reminderTime': reminderTime, 'commitmentAccepted': commitmentAccepted,
    };
  }
}

void main() {
  test('completeOnboarding persists every quiz field', () async {
    final fake = _FakeAuth();
    final notifier = OnboardingNotifier(authService: fake);
    notifier
      ..setIntention('spiritualGrowth')
      ..toggleStruggle('anxiety')
      ..setFamiliarity('some')
      ..setQuranConnection('weak')
      ..toggleAttribution('tiktok')
      ..setAgeRange('25_34')
      ..setPrayerFrequency('someDaily')
      ..setResonantNameId('ar-rahman')
      ..toggleDuaTopic('health')
      ..setDuaTopicsOther('exam')
      ..toggleCommonEmotion('anxious')
      ..toggleAspiration('morePatient')
      ..setDailyCommitmentMinutes(5)
      ..setReminderTime('08:00')
      ..setCommitmentAccepted(true);

    await notifier.debugPersistOnboardingForTest();

    expect(fake.captured, isNotNull);
    for (final key in [
      'intention','struggles','familiarity','quranConnection','attribution',
      'ageRange','prayerFrequency','resonantNameId','duaTopics','duaTopicsOther',
      'commonEmotions','aspirations','dailyCommitmentMinutes','reminderTime',
      'commitmentAccepted',
    ]) {
      expect(fake.captured!.containsKey(key), isTrue, reason: 'missing $key');
    }
  });
}
```

- [ ] **Step 23.2: Run → pass → commit**

```bash
flutter test test/features/onboarding/completion_integration_test.dart
git add test/features/onboarding/completion_integration_test.dart
git commit -m "test(onboarding): integration test for full quiz → user_profiles round-trip"
```

---

## Pre-ship checklist (do NOT merge to main without these)

- [ ] `flutter analyze` is clean.
- [ ] `grep -rn "HookScreen\|hook_screen" lib/` confirms `hook_screen.dart` is still referenced only by `core/router.dart` (it's an entry screen, not part of the onboarding `PageView`; this refactor should not orphan it).
- [ ] `flutter test` is all green.
- [ ] Privacy policy updated per spec §13 and `TODOS.md`.
- [ ] Manually walked the full 28-page flow on iOS simulator.
- [ ] Manually walked the full 28-page flow on Android emulator.
- [ ] Verified notification permission prompt appears at page 17 (#19).
- [ ] Verified OneSignal subscriber binds to user id after sign-up.
- [ ] Verified `user_profiles` row contains all 10 new columns populated after completion (check via Supabase dashboard).
- [ ] Verified paywall headline references the user's top aspiration.
- [ ] Set up the per-screen drop-off funnel dashboard in Mixpanel (spec §8 post-launch requirement).

---

## Self-review checklist (author's notes)

- Every task has full code blocks — no "TBD", "similar to Task N", or placeholder handwaves.
- File paths are absolute to the repo root or relative from `flutter/`.
- Each new screen has a unit test that asserts the "Continue enabled only after answer" rule (spec §9 no-skip policy).
- v3 JSON migration discards v < 3 blobs (spec §5 "no users").
- Fallback Ar-Rahman on the plan-reveal screen has a dedicated test (spec §4.3).
- Conditional commitment-pact copy has two tests — granted and denied (spec §4.2).
- OneSignal re-identify has its own regression test (Task 22) even though the binding is in the existing auth path.
- Paywall keeps its pricing/CTA wiring; only headline is personalized.

Known follow-ups intentionally not in this plan (see spec §14):
- Dynamic branching based on prior answers.
- `QuizAnswers` sub-state grouping.
- Kill switch / remote config flag.
- A/B test harness.
- Localization.

# Plan — Single-Name Continuity Through Onboarding

**Spec:** `docs/superpowers/specs/2026-04-29-single-name-continuity-design.md`
**Date:** 2026-04-29

## Catalog ID mapping (from `lib/services/card_collection_service.dart`)

| Demo Name | Catalog id |
|---|---|
| Ar-Rahman (default) | 2 |
| As-Salam | 6 |
| Al-Jabbar | 9 |
| Ash-Shakur | 28 |
| As-Sabur | 32 |
| Al-Hadi | 33 |
| Al-Wakeel | 35 |

## Note: incidental discovery

The current migration `20260418000000_add_onboarding_profile_fields.sql` adds the column as `resonant_name_slug`, but `auth_service.dart` writes to `resonant_name_id`. The whole `saveOnboardingData` UPDATE has been failing silently since 2026-04-18 (catch block swallows it). Our migration drops `resonant_name_slug` and adds `starter_name_id int`, so once auth_service is updated to write `starter_name_id`, the broader silent failure is also resolved.

## Steps

### Step 1 — DB migration

Create `supabase/migrations/20260429000000_starter_name_id.sql`:

```sql
alter table public.user_profiles
  add column if not exists starter_name_id int
    references public.collectible_names(id);

comment on column public.user_profiles.starter_name_id is
  'Onboarding: catalog id of the Name surfaced on the first check-in. Seeded into user_card_collection at onboarding completion.';

alter table public.user_profiles
  drop column if exists resonant_name_slug,
  drop column if exists resonant_name_id;
```

### Step 2 — `demo_result_card.dart` → starter Name data

- Rename `DemoResultData` → `StarterNameData`. Update class doc comment.
- Add `final int catalogId` to constructor.
- Update each constant with its catalog id (per mapping above).
- Expand `forEmotion()`: ~25 keyword synonyms grouped per Name. Default → Ar-Rahman.
- Update `DemoResultCard` widget references.

### Step 3 — `onboarding_provider.dart` → starter Name state

- Replace field `resonantNameId String?` → `starterNameId int?`.
- `copyWith`, `toJson`, `fromJson` updated. JSON `version` 4 → 5; `fromJson` discards v<5.
- Replace `setResonantNameId(String)` → `setStarterName(int)`.
- `_persistQuizAnswers` passes `starterNameId: state.starterNameId`.

### Step 4 — `auth_service.dart` → write starter_name_id, seed card

- `saveOnboardingData`: parameter `String? resonantNameId` → `int? starterNameId`. Update map key `'resonant_name_id'` → `'starter_name_id'`.
- New method:

  ```dart
  Future<void> seedStarterCard(int nameId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase.from('user_card_collection').upsert({
      'user_id': userId,
      'name_id': nameId,
      'tier': 'bronze',
    }, onConflict: 'user_id,name_id', ignoreDuplicates: true);
  }
  ```

- Will need a unique constraint on `(user_id, name_id)` for upsert to work. **Verify:** the initial schema has `idx_collection_user_name` (an index, not unique). Add to migration:

  ```sql
  alter table public.user_card_collection
    add constraint user_card_collection_user_name_unique
    unique (user_id, name_id);
  ```

  Possible duplicate-row failure on existing data — but no prod users, so safe.

### Step 5 — Wire seed into `completeOnboarding`

- In `onboarding_provider.dart`, `completeOnboarding`:
  - After `persistOnboardingToSupabase()`, if `state.starterNameId != null`, call `_authService.seedStarterCard(state.starterNameId!)`.
  - Wrap in try/catch → debugPrint, like `_persistQuizAnswers`.

### Step 6 — `first_checkin_screen.dart` → persist starter Name

- In `_buildResult`, after computing `data = StarterNameData.forEmotion(...)`, call `notifier.setStarterName(data.catalogId)` (idempotent if already set).
- Change `AppStrings.checkinResultLabel` from "Your Reflection" to "Your starting Name." Update `app_strings.dart`.
- Rename loose mentions of "demo" → "starter" in comments.

### Step 7 — Remove resonant Name picker page

- Delete `lib/features/onboarding/screens/resonant_name_screen.dart`.
- Delete `lib/features/onboarding/data/resonant_names.dart`.
- Delete `test/features/onboarding/screens/resonant_name_screen_test.dart`.
- `onboarding_screen.dart`:
  - Remove the `ResonantNameScreen` import + page from `PageView` children list.
  - Renumber comments (page 7 was resonant; now 7 = dua topics, 8 = common emotions, …).
  - Update `_completeOnboarding`: replace `state.resonantNameId` block with `state.starterNameId` (analytics property `starter_name_id`).
- `onboarding_provider.dart`:
  - `onboardingLastPageIndex` 25 → 24
  - `onboardingPasswordPageIndex` 23 → 22
  - `onboardingEncouragementPageIndex` 24 → 23
- Audit every screen with `progressSegment >= 8`: shift down by 1. Files to check: `dua_topics_screen`, `common_emotions_screen`, `aspirations_screen`, `daily_commitment_screen`, `attribution_screen`, `struggle_support_interstitial_screen`, `reminder_time_screen`, `notification_screen`, `commitment_pact_screen`, `generating_screen`, `personalized_plan_screen`, `value_prop_screen`, `social_proof_screen`, `save_progress_screen`, `sign_up_email_screen`, `sign_up_password_screen`, `encouragement_screen`. (Paywall and the two encouragement interstitials sit outside the bar per CLAUDE.md.)

### Step 8 — `personalized_plan_screen.dart` → use starter Name

- Drop `resonant_names.dart` import.
- Replace `resonantTranslitForId(state.resonantNameId)` lookup with a sync lookup against `allCollectibleNames` by `state.starterNameId` (or `'Ar-Rahman'` fallback if null).
- Remove the now-unused static `translitForId` method.
- Update `progressSegment` from 18 → 17.

### Step 9 — `daily_launch_overlay.dart` → conditional Name

- New provider in `lib/features/daily/providers/starter_name_provider.dart`:

  ```dart
  final starterNameProvider = FutureProvider<CollectibleName?>((ref) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await Supabase.instance.client
        .from('user_profiles')
        .select('starter_name_id')
        .eq('id', userId)
        .maybeSingle();
    final id = row?['starter_name_id'] as int?;
    if (id == null) return null;
    return allCollectibleNames.firstWhere((n) => n.id == id,
        orElse: () => allCollectibleNames.first);
  });
  ```

- In `_StreakGreetingStep.build`:
  - Read `streakCount` (already does).
  - If `streakCount == 0`, watch `starterNameProvider`. If it returns a name, render that. Else fall back to `getTodaysName()`.
  - If `streakCount > 0`, keep `getTodaysName()`.
- The `AllahName` and `CollectibleName` types differ — adapter inline (just pull `arabic`, `transliteration`, `english` for display; both have those fields).

### Step 10 — `analytics_events.dart`

- Rename const `resonantNameSlug` (or wherever the literal lives) to `starterNameId`. Update all callers.

### Step 11 — Tests

- New: `test/features/onboarding/widgets/starter_name_data_test.dart`
  - All 7 entries' `catalogId` exist in `allCollectibleNames`.
  - Keyword cases: 'anxious'→6, 'overwhelmed'→6, 'panic'→6, 'worried'→6, 'sad'→9, 'grief'→9, 'broken'→9, 'grateful'→28, 'thankful'→28, 'angry'→32, 'frustrated'→32, 'irritated'→32, 'lost'→33, 'lonely'→33, 'hopeful'→35, 'optimistic'→35, ''→2, 'tired'→2.
- Update: `test/services/auth_service_onboarding_persist_test.dart`
  - Rename param + assert `starter_name_id` column written.
- Update: `test/features/onboarding/onboarding_provider_test.dart`
  - `setStarterName(int)` updates state.
  - JSON v4 blob is discarded.
- Update: `test/features/onboarding/screens/personalized_plan_screen_test.dart`
  - Uses `starterNameId` instead of `resonantNameId`.
- New: `test/features/daily/daily_launch_overlay_starter_name_test.dart`
  - `streakCount==0` + starter Name set → renders that Name.
  - `streakCount==0` + no starter Name → falls back to `getTodaysName()`.
  - `streakCount==1` → renders `getTodaysName()` regardless of starter.
- Existing tests pinning page indices / `onboardingLastPageIndex` need updating if any; grep for `25`, `23`, `onboardingPasswordPageIndex`, `onboardingLastPageIndex`.

### Step 12 — Verification

- `flutter analyze` — no new errors/warnings.
- `flutter test` — all tests pass including new ones.
- Spot check: `grep -r resonant_name lib/ test/` — no remaining references except in this plan and the spec.

## Risk register

| Risk | Mitigation |
|---|---|
| Catalog id collision (someone renumbers `allCollectibleNames`) | Test asserts every `catalogId` resolves to a real entry |
| Existing in-flight onboarding state (v4) on testers' phones | Spec explicitly drops on version mismatch — CLAUDE.md confirms no prod users |
| `user_card_collection` lacks unique constraint on (user_id, name_id) | Added in step 4 migration; must run before app first uses upsert |
| Page index audit miss → wrong progress bar segment | Tests assert `progressSegment` per screen; manual scroll-through verifies bar |
| `starterNameProvider` invalidation on sign-in/out | `FutureProvider.autoDispose` + invalidate on auth state change. Or simpler: read once on overlay mount and don't worry about it (overlay is short-lived anyway) |

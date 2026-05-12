# Single-Name Continuity Through Onboarding

**Date:** 2026-04-29
**Status:** Approved, ready for implementation
**Bug:** Three different Names of Allah surfaced during signup (page 0 demo card, page 7 picker, post-signin home greeting) with no narrative continuity. See `docs/qa/entry-identity-findings.md` (referenced) and conversation log 2026-04-29.

## Goal

One Name carries the user from first check-in → personalized plan → home greeting → first collection card. Eliminate the three-Name confusion.

## Root cause

Three independent code paths each pick a Name independently:

| Touchpoint | Source | File |
|---|---|---|
| First check-in (page 0) | `DemoResultData.forEmotion()` keyword switch over 7 hardcoded names | `lib/features/onboarding/widgets/demo_result_card.dart` |
| Resonant Name picker (page 7) | User pick from `kResonantNames` (6 names) | `lib/features/onboarding/data/resonant_names.dart` |
| Home post-signin | `getTodaysName()` = `allahNames[dayOfYear % 15]` | `lib/core/constants/allah_names.dart` |

`resonantNameId` is written to `user_profiles` but never read post-signin. CLAUDE.md promises "selection becomes first card in collection" — promise unfulfilled (no `user_card_collection` seed).

## Design

### Architecture change

```
BEFORE                                    AFTER
──────                                    ─────
Page 0 (first check-in)                   Page 0 (first check-in)
  → demo card (keyword switch)              → expanded keyword switch → starter Name
  → "Your Reflection"                       → persisted as starterNameId (catalog int)
                                            → "Your starting Name" framing
Page 7 (resonant Name picker)             [DELETED]
DailyLaunchOverlay                        DailyLaunchOverlay
  → always getTodaysName()                  → if streakCount==0: starterName
                                              else: getTodaysName()
user_card_collection                      user_card_collection
  → seeded only by daily gacha              → also seeded by starterNameId at signup
                                              (bronze tier, idempotent)
```

### Data model

- New column: `user_profiles.starter_name_id int references collectible_names(id)`.
- Drop column: `user_profiles.resonant_name_id text` (unused post-signup, no prod users).
- One additional row written to `user_card_collection (user_id, name_id=starter_name_id, tier='bronze')` at onboarding completion. Upsert on `(user_id, name_id) do nothing`.

### Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Page 0 + Page 7 | Collapse — Page 0 result becomes the starter Name | Single coherent moment, no duplicate "pick a Name" steps |
| Page 0 input | Free text + chips, expanded keyword map (~25 synonyms) | Preserves "type how you feel" magic; reduces accidental defaults |
| DailyLaunchOverlay rule | `streakCount == 0` → starter Name; else `getTodaysName()` | Simple, stateless; resonant Name introduces catalog without competing forever |
| Persistence | Dart-side insert in `completeOnboarding`, idempotent upsert | Visible in flow, no DB trigger needed for one-row insert |
| Onboarding state version bump | v4 → v5 (drops in-flight v4 state) | CLAUDE.md confirms no production users |

## Files

### Modified

- `lib/features/onboarding/widgets/demo_result_card.dart` — rename `DemoResultData` → `StarterNameData`. Add `catalogId int` field. Expand `forEmotion()` keyword map.
- `lib/features/onboarding/screens/first_checkin_screen.dart` — call `setStarterName(catalogId)` on completion. Update label copy.
- `lib/features/onboarding/providers/onboarding_provider.dart` — replace `resonantNameId` with `starterNameId int?`, JSON v4→v5, add `setStarterName`, remove `setResonantNameId`. `_persistQuizAnswers` writes `starter_name_id`.
- `lib/services/auth_service.dart` — `saveOnboardingData` parameter `starterNameId int?` writes `starter_name_id`. New `seedStarterCard(int nameId)` method.
- `lib/features/onboarding/screens/onboarding_screen.dart` — remove `ResonantNameScreen` from PageView. Constants: `onboardingLastPageIndex` 25→24, `onboardingPasswordPageIndex` 23→22, `onboardingEncouragementPageIndex` 24→23. Audit `progressSegment` on every screen >7 (each shifts down by 1).
- `lib/features/onboarding/screens/personalized_plan_screen.dart` — read `starterNameId` and resolve via `PublicCatalogService` instead of `resonantNameId` slug lookup.
- `lib/features/daily/screens/daily_launch_overlay.dart` — conditional Name selection based on `streakCount`.
- `lib/services/analytics_events.dart` — rename `resonant_name_slug` → `starter_name_id`.

### Deleted

- `lib/features/onboarding/screens/resonant_name_screen.dart`
- `lib/features/onboarding/data/resonant_names.dart`
- `test/features/onboarding/screens/resonant_name_screen_test.dart`

### New

- `supabase/migrations/20260429000000_starter_name_id.sql` — add `starter_name_id`, drop `resonant_name_id`.
- `lib/features/daily/providers/starter_name_provider.dart` — `FutureProvider<CollectibleName?>` for the user's starter Name.

## Edge cases

- **Catalog miss.** If `forEmotion()` returns a `catalogId` not in `collectible_names`, seed silently fails (caught + logged). Guarded by a unit test that asserts every `StarterNameData.catalogId` exists in the catalog.
- **Apple/Google social auth.** `_skipToEncouragement` still routes through `completeOnboarding`, which seeds the card.
- **Re-signup with same email.** Seed uses `upsert ... do nothing` — never overwrites a progressed collection.
- **Streak == 0 race.** `markDailyLaunchShown()` already gates per-day. Streak check decides Name on whatever day the overlay does fire.

## Testing

- `test/features/onboarding/widgets/starter_name_data_test.dart`
  - Every `StarterNameData.catalogId` resolves to a real `CollectibleName`.
  - 25 keyword inputs each map to expected catalogId.
- `test/features/onboarding/screens/first_checkin_screen_test.dart`
  - Selecting "Grateful" persists `starterNameId` matching Ash-Shakur's catalog id.
- `test/services/auth_service_onboarding_persist_test.dart` — extend
  - `saveOnboardingData(starterNameId: …)` writes `starter_name_id` column.
- `test/features/onboarding/completion_integration_test.dart` — extend
  - `completeOnboarding` inserts one bronze row in `user_card_collection` for the starter Name.
- `test/features/daily/daily_launch_overlay_starter_name_test.dart` — new
  - `streakCount == 0` + starter Name = X → overlay shows X.
  - `streakCount == 1` → overlay shows `getTodaysName()`.
- `test/features/onboarding/onboarding_screen_pageview_test.dart` — extend
  - PageView has 25 children; password at 22; paywall at 24.

## Out of scope

- Replacing `DemoResultData`/`StarterNameData`'s literal verses with DB lookups.
- Migrating `getTodaysName()` from the local 15-name list to the 99-name catalog.
- Backend trigger for collection seeding.

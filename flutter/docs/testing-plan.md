# Sakina Flutter Testing Plan

Coverage-oriented plan for the Flutter app. Defines **what to test** and at **which layer** (unit, provider, widget, E2E). Pair with `manual-test-plan.md` for on-device runbooks and DB/MCP assertions — don't duplicate execution steps here.

## Release blockers

High-signal checks that gate every release:

1. **Premium + paywall** (when billing is enabled)
   - RevenueCat init succeeds with keys, fails safely without.
   - Auth signs user into RevenueCat with stable Supabase user id.
   - Onboarding paywall renders annual + weekly pricing from offerings.
   - Purchase success → entitlement granted → routed to Home.
   - Purchase cancel → stays on paywall.
   - Restore success → routed to Home. Restore with no entitlement → user-facing error.
   - Offerings load failure → recoverable error UI (not blank).
   - Webhook updates `is_premium` correctly on purchase / cancel / expiration.

2. **Legal**
   - Privacy + Terms links open.
   - Consent copy matches what's actually stored.

3. **Notification permission timing**
   - iOS system prompt fires **only** on the notification screen.
   - Account creation alone does not trigger it.
   - Skipping notifications preserves onboarding progress.

## Test pyramid

1. **Unit** — pure business rules: streak logic, XP curves, reward math, AI response parsing, RPC payload mapping, catalog validation.
2. **Provider / service** — Riverpod state transitions, SharedPreferences caching, Supabase sync, failure recovery.
3. **Widget** — rendering, enabled/disabled states, empty states, destructive confirmations, upgrade prompts.
4. **E2E smoke** — a handful of app-level flows to verify routing, persistence, and cross-feature integration.

## Section-by-section checklist

### 1. Launch and session

- Fresh install opens Welcome.
- Onboarded + signed-in opens Home.
- Signed-out but onboarded → Welcome.
- Relaunch preserves route.
- Sign-out clears scoped caches (no leak across accounts).
- Account deletion removes user-scoped data and returns to entry flow.

### 2. Welcome, auth, account creation

- Hook screen routes correctly.
- Email sign-up: name/email/password validation + happy path.
- Google + Apple sign-in happy paths.
- Existing onboarded user skips onboarding on sign-in.

Edge: invalid email, weak password, duplicate email, social auth cancellation.

### 3. Onboarding flow

Pages are enumerated in `docs/manual-test-plan.md` §3 (0–24). For every page test:
- Initial render.
- Back + continue behavior.
- Validation rules.
- State survives app kill/resume.
- `progressSegment` matches page index.
- Analytics event emitted once (no duplicates on back-then-forward).

Flow-level:
- Full happy path Welcome → Home.
- Resume from mid-onboarding after force close.
- Backtracking edits prior answers.
- Social auth stays in-flow (calls `_next`, not `_goToPaywall`).
- Paywall (last index) sits outside the progress bar.
- After paywall dismiss/complete, verify `user_profiles` row has ALL fields populated: `display_name`, `onboarding_intention`, `age_range`, `prayer_frequency`, `onboarding_quran_connection`, `onboarding_familiarity`, `resonant_name_id`, `dua_topics`, `common_emotions`, `aspirations`, `daily_commitment_minutes`, `reminder_time`, `commitment_accepted`, `onboarding_attribution`. Regression guard against the 2026-04 silent-write-failure bug where a bad column name caused the whole UPDATE to fail.

### 4. Daily core loop

- Daily launch overlay shows only when expected.
- Home loads streak, XP, tokens, quests.
- Muhasabah questions advance.
- Final answer triggers AI response → saves to history.
- Gacha reveal shows correct card with working Continue.
- Reward claims update balances.
- Achievement checks fire after completion.

Edge: double-tap answer/continue, background during loading, midnight boundary (local vs UTC), same-day repeat does not duplicate rewards, streak freeze consumed only when needed.

### 5. Discovery quiz

- Quiz starts only when no anchors exist.
- Each answer advances.
- Results deterministic for known inputs.
- Results persist locally + remotely.
- Settings shows saved anchors.
- Re-entering doesn't corrupt prior results.

### 6. Reflect

- Input / loading / follow-up / result / off-topic states.
- Follow-up answers feed back into the final prompt.
- Saved reflections render in Journal.
- Delete updates local + remote.
- Token gate after free limit.
- Context uses saved anchors and recent journal/check-in data.

Edge: AI failure does not consume free usage, off-topic does not consume free usage, very long input, duplicate tap while loading, share/export graceful failure.

### 7. Duas

- Browse list + favorite toggle.
- AI dua builder happy path persists output.
- Related duas save/unsave.
- Names-invoked tracking updates.
- Token gate after free limit.

Edge: AI failure leaves state intact, off-topic doesn't consume usage, saved/built duas survive relaunch, cross-user cache isolation.

### 8. Journal

- Empty state.
- Mixed saved content.
- Reflection and dua detail pages render correctly.
- Delete removes only the tapped item.

Edge: long content truncates in list but shows full on detail, share failures surface safely.

### 9. Collection and card economy

- First discovered name unlocks.
- Existing name progresses through tiers.
- Tier-up scroll spend updates once.
- Grid + detail render correct tier visuals.
- Premium celebration overlay only after verified premium success.

Edge: duplicate engage calls produce one mutation, tier upgrade failure presented, share/export from ornate card works.

### 10. Quests, XP, titles, streaks

- First Steps quests progress on correct actions.
- Rewards granted once.
- XP level changes update title + UI.
- Streak milestones trigger at correct thresholds.
- Manual and auto title both persist.

Edge: multiple quest completions in one frame each grant once, broken streak → `current_streak` resets to 1 on next check-in, `longest_streak` preserved.

### 11. Settings and notifications

- Notification toggle reads server state.
- Toggle writes local + Supabase.
- Push opt-in/out updates delivery state.
- Timezone sync runs after auth.
- Reset daily loop + clear collection confirmations work.
- Delete account requires explicit confirmation and clears local state.

Edge: Supabase unavailable during toggle, notification tap routes to correct screen, foreground notification does not crash current screen.

### 12. Share and export

- Reflect, built-dua, and journal detail share previews export a card image.
- Cards render correct verse count, text, branding.

Edge: native share cancel, long content still fits core card content.

### 13. Public catalog and RLS

- Bundled snapshots bootstrap correctly.
- Remote public catalog refresh validates shape before overwrite.
- Batch RPC hydrates all user caches.
- User-owned data respects RLS — one user cannot read another's reflections, history, rewards, or discovery results.

### 14. Edge functions and SQL

- Scheduled notification eligibility for daily, streak, re-engagement, weekly.
- Deduplication windows work.
- Partial OneSignal send failure tolerated.
- `delete_own_account` removes dependent data.
- `sync_all_user_data()` returns complete, stable payloads.
- `revenuecat-webhook` rejects unauthorized requests.
- Webhook resolves stable user id via alias / `original_app_user_id` fallback.
- Initial purchase, cancellation, billing issue, expiration events persist correct subscription state.
- `grant_premium_monthly()` grants only to active premium users, only once per month, rejects non-premium callers.

## Automated gate before shipping

On every PR:

```bash
flutter analyze
flutter test
```

Focused E2E smoke coverage:
- Welcome → onboarding → Home.
- Home → daily loop → reveal.
- Reflect submit → save → Journal.
- Onboarding paywall → purchase or restore → Home.
- Discovery quiz → anchors saved.
- Settings → notification toggles → sign out.

## Manual regression before release

See `manual-test-plan.md` for full on-device steps, DB assertions, and MCP calls. Minimum pass on iOS simulator + one physical device:

- New user onboarding.
- Returning user login.
- Daily loop.
- Reflect.
- Dua builder.
- Discovery quiz.
- Journal review + delete.
- Settings notification toggles.
- Account deletion.

When premium is enabled, also: purchase, restore, relaunch with entitlement, monthly premium grant, webhook-driven subscription refresh.

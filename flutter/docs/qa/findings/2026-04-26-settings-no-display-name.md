# Phase-1-F1: Settings profile shows email twice, no display_name

**Severity:** Low
**Surface:** `lib/features/settings/screens/settings_screen.dart` profile card
**Found:** 2026-04-26 settings/push QA run

## Observation

The profile card at the top of Settings shows the user's email address twice (one as the "name" position at y=193, again at y=267), and never renders `user_profiles.display_name`.

## Repro

1. Sign in as a user with `display_name` set (e.g. `verify20260422b@sakinaqa.test` whose `display_name = "VerifyUser"`).
2. Open Settings.
3. Top profile card shows `verify20260422b@sakinaqa.test` in both label slots. "VerifyUser" never appears.

## Why it matters

CLAUDE.md and `manual-test-plan.md` §14 both say the profile card should show display_name + email. The user filled in their name on onboarding page 1; that data is being collected but not surfaced. Personalization screens later in the app (e.g. "Your plan, <name>") use it correctly, so the column is populated, just unread on this screen.

## Likely fix

Read `display_name` from `user_profiles` (or the auth state holder it's mirrored into) and render in the top label slot. Fall back to email if null.

## Status: FIXED 2026-04-26 (sim-verified, unit-tested)

`lib/features/settings/screens/settings_screen.dart` — `_loadData` now
fetches `user_profiles.display_name`. Resolution logic extracted to a
top-level pure function `resolveProfileDisplayName({profileDisplayName,
fullName, email})` with priority chain profile → fullName → email → 'Guest'.

Tests added in `test/features/settings/resolve_profile_display_name_test.dart`:
- prefers profileDisplayName when present
- falls back to fullName when profileDisplayName is null
- falls back to fullName when profileDisplayName is empty/whitespace
- falls back to email when profile + fullName are missing
- returns Guest when everything is null
- returns Guest when everything is empty/whitespace
- trims whitespace from profileDisplayName

Sim verified end-to-end on QABot: profile card renders "QABot" (display_name)
with `qa20260426@sakinaqa.test` as subtitle. Pre-fix this rendered email
in both slots.

# Signup session-race recovery — fixed

**Date:** 2026-06-03
**Area:** Onboarding · email signup (`sign_up_password_screen.dart`)
**Severity:** Medium (new-signup-only; no impact on existing/signed-in users)
**Status:** Fixed + tested. Simulator end-to-end pass pending a local build.

## The bug

On the onboarding password screen, `_submit()` called `signUpWithEmail()` then
read `Supabase.instance.client.auth.currentUser?.id`. On a slow network the
signup resolves but `currentUser` reads back null for a beat (propagation lag).
The old code fired `signup_failed{session_race}`, showed the snackbar
**"Account created — tap Continue to finish signing in"**, and returned.

That snackbar was a dead end: tapping Continue re-ran `_submit()` →
`signUpWithEmail()` again → Supabase threw `AuthException("User already
registered")` → the user was trapped in onboarding with no recovery short of
backing out and changing email. The prior batch added the telemetry + snackbar
but never added the actual recovery.

## Why it's safe for current users

Only the new-signup path changes. Already-signed-in users never reach this
screen. The one new behavior — an existing email + correct password now signs
that account in and continues instead of dead-ending — is strictly better and
touches no existing-user data. Autoconfirm is ON for this project (all 90 users
confirmed within 5s of creation), so a password sign-in reliably establishes
the session.

## The fix

Root cause: the screen read the **global `currentUser`**, which lags
`auth.signUp` on a slow network. The fix reads the user id straight off the
signUp `AuthResponse` (`session?.user.id`) — authoritative, no propagation lag.
That alone closes the race; no retry loop needed.

`performSignUpWithRecovery` (top-level, in `auth_service.dart`, fully
injectable/unit-testable) orchestrates:

1. signUp returns an id (live session) → `created`.
2. signUp returns null (no session — rare under autoconfirm) → `signInWithPassword`
   for the just-created account → `recoveredViaSignIn`, else `failed`.
3. signUp throws "User already registered" → `emailAlreadyRegistered`. We
   **deliberately do NOT sign in**: the email belongs to an existing account,
   and continuing would overwrite that user's profile. The screen shows an
   honest "That email already has an account. Try logging in instead." This was
   a conscious decision (reviewed) to honor the "don't affect current users"
   constraint over auto-recovering a returning user.
4. any other `AuthException` → `failed` (message shown; mapped to a bounded
   analytics reason).

`AuthService.signUpWithRecovery` wires the real Supabase calls. The screen
switches on the result: created + recovered proceed (adds
`signup_completed{recovery:'signin'}` when recovery kicked in). `signup_failed.error`
is mapped through `AnalyticsEvents.signupFailedReasonForCode` to a bounded set
(`email_taken` / `invalid_credentials` / `weak_password` / `rate_limited` /
`auth_error` / `session_race` / `unknown`) so the funnel stays low-cardinality.
The referral block and its `{invalid, self_referral}` structural pin are
unchanged (variable renamed `result` → `applyResult`; pin updated in lockstep).

## Tests

- `test/services/sign_up_recovery_test.dart` — 9 deterministic cases incl. the
  exact null-session race (the reproduction the simulator can't force).
- `test/features/onboarding/sign_up_password_session_recovery_test.dart` — 2
  widget tests proving the dead-end copy is gone, the real auth error reaches
  the user, and onboarding does not advance without a session.
- Full suite: 1271 passing; `flutter analyze` clean on changed files.

## Simulator verification script (run after a local build)

1. Complete onboarding, create account A (email + password P).
2. Restart onboarding, reach the password screen, sign up with A again.
   - **Before:** raw "User already registered" → stuck dead-end.
   - **After:** "That email already has an account. Try logging in instead."
     (honest, no overwrite of A's profile). Re-tapping just re-shows it.

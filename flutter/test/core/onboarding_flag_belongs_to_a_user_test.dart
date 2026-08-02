// P0 — a never-onboarded user could walk straight into the app.
//
// `onboarding_completed` is an UNSCOPED prefs flag read at cold launch
// (`main.dart:198`) as `AppSessionNotifier(initialOnboarded: ...)`. Nothing
// records WHICH user it belongs to.
//
// The sequence, on a device this project explicitly shares across test
// accounts:
//
//   1. User A completes onboarding → `onboarding_completed = true`.
//   2. Their refresh token expires or is revoked. supabase_flutter emits a bare
//      `signedOut` with no explicit `signOut()` call — so the caller-side
//      cleanup in `clearSession()` / `AuthService.signOut()` never runs, and the
//      persisted flag survives. (The in-memory `_hasOnboarded = false` in the
//      `signedOut` branch is correct but dies with the process.)
//   3. Cold launch → `initialOnboarded: true`.
//   4. User B — a different, never-onboarded account — signs in. The guard
//      `if (isAuthenticated && !_hasOnboarded)` is false, so
//      `_checkOnboardingStatus()` never runs. `ensureOnboardingChecked()` has
//      the same `if (_hasOnboarded) return;` short-circuit.
//   5. The router sees `hasOnboarded == true` and lets them into the app,
//      never onboarded — no Name, no queue, no starter card.
//
// `_checkOnboardingStatus` only ever sets the flag TRUE, so a stale true is
// never corrected by anything.
//
// WHY NOT JUST CLEAR THE FLAG ON SIGN-OUT: because an expired token is the
// common case, and the user who signs back in is usually the SAME person.
// Clearing would force them to redo onboarding for a routine token refresh —
// trading a rare cross-user bug for a frequent same-user one. The flag has to
// know whose it is.
//
// MUTATION: make `shouldRecheckOnboarding` return false unconditionally → the
// cross-user cases below fail.

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';

void main() {
  group('shouldRecheckOnboarding — whose flag is it', () {
    test('a DIFFERENT user must be re-checked against the server', () {
      expect(
        shouldRecheckOnboarding(
          currentUid: 'user-b',
          flagUid: 'user-a',
          hasOnboarded: true,
        ),
        isTrue,
        reason: 'trusting user A\'s completion for user B is what lets a '
            'never-onboarded account into the app',
      );
    });

    test('the SAME user is trusted — an expired token is not a new user', () {
      expect(
        shouldRecheckOnboarding(
          currentUid: 'user-a',
          flagUid: 'user-a',
          hasOnboarded: true,
        ),
        isFalse,
        reason: 'a routine token refresh must never cost someone their '
            'onboarding — that would be a far more frequent bug than the one '
            'this guards',
      );
    });

    test('an UNOWNED flag is re-checked', () {
      // Every install that predates this field has a flag with no owner. The
      // check is cheap and server-authoritative; trusting an unowned flag is
      // exactly the bug.
      expect(
        shouldRecheckOnboarding(
          currentUid: 'user-a',
          flagUid: null,
          hasOnboarded: true,
        ),
        isTrue,
      );
    });

    test('a not-yet-onboarded session needs no re-check', () {
      // `_checkOnboardingStatus` already runs on this path; re-checking would
      // be redundant, not wrong.
      for (final flagUid in [null, 'user-a', 'user-b']) {
        expect(
          shouldRecheckOnboarding(
            currentUid: 'user-b',
            flagUid: flagUid,
            hasOnboarded: false,
          ),
          isFalse,
        );
      }
    });

    test('an unauthenticated session never re-checks', () {
      expect(
        shouldRecheckOnboarding(
          currentUid: null,
          flagUid: 'user-a',
          hasOnboarded: true,
        ),
        isFalse,
        reason: 'there is nobody to check against; the signedOut branch owns '
            'this case',
      );
    });
  });
}

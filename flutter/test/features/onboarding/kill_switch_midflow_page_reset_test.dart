// The kill switch is the rollback path for the whole reel flow. If the ship
// goes badly, someone flips `reel_first_onboarding_enabled` off — and that is
// precisely the moment you cannot afford a second failure.
//
// THE BUG: `currentPage` was restored unconditionally and reinterpreted against
// whichever flow resolved on THIS launch. The only correction was a numeric
// out-of-bounds clamp, which does nothing when the index is merely in-bounds
// for the WRONG flow — the common case, since the flows have similar lengths
// but completely different page orders.
//
// Concretely: a user paused on reel page 12 (WidgetOfferScreen — post-reveal,
// mid-intake, pre-signup) resumes after a flip into the trimmed flow still at
// index 12, which there is SocialProofScreen, the screen immediately before
// sign-up. They skip twelve required questions — name, age, intention, prayer
// frequency, familiarity, dua topics, daily commitment, attribution, reminder
// time, notifications, the commitment pact — and land in signup with all of it
// empty, while their reel answers are stranded and ignored.
//
// Nothing invalid is persisted and nothing crashes, which is exactly why it
// would have gone unnoticed: it is a silent UX break during an emergency
// rollback.
//
// THE FIX IS CHEAP BECAUSE THE ANSWER WAS ALREADY ON DISK. `onboardingFlow` is
// persisted in the same prefs blob as `currentPage` (`toJson`), so a resumed
// session can always tell which flow recorded its page. When they disagree,
// the page is meaningless and the only safe reading is 0.
//
// Restarting is not free — the user re-answers. It is chosen over the
// alternatives deliberately: reinterpreting the index skips required questions
// silently, and mapping indices between two hand-ordered flows is a table
// nobody will maintain. During a rollback, coherent-and-annoying beats
// broken-and-quiet.
//
// MUTATION: make `resolveResumePage` return `savedPage` unconditionally → every
// cross-flow case below fails.

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';

void main() {
  group('resolveResumePage — a page only means something in its own flow', () {
    test('a reel page resumed into the trimmed flow restarts', () {
      expect(
        resolveResumePage(
          savedPage: 12,
          savedFlow: onboardingFlowReel,
          resolved: OnboardingFlowKind.trimmed,
        ),
        0,
        reason: 'index 12 is WidgetOfferScreen in reel and SocialProofScreen in '
            'trimmed — one page before signup, with twelve required questions '
            'never asked',
      );
    });

    test('a trimmed page resumed into the reel flow restarts', () {
      expect(
        resolveResumePage(
          savedPage: 8,
          savedFlow: onboardingFlowLegacy,
          resolved: OnboardingFlowKind.reel,
        ),
        0,
      );
    });

    test('the SAME flow resumes exactly where it left off', () {
      // The guard must not become a blanket reset — the ordinary resume is the
      // common case by orders of magnitude, and restarting it would be a far
      // worse bug than the one being fixed.
      expect(
        resolveResumePage(
          savedPage: 12,
          savedFlow: onboardingFlowReel,
          resolved: OnboardingFlowKind.reel,
        ),
        12,
      );
      expect(
        resolveResumePage(
          savedPage: 8,
          savedFlow: onboardingFlowLegacy,
          resolved: OnboardingFlowKind.trimmed,
        ),
        8,
        reason: 'trimmed and legacy share the legacy flow value — a trim-flag '
            'change is not a flow change',
      );
    });

    test('page 0 is unaffected by anything', () {
      for (final flow in [onboardingFlowReel, onboardingFlowLegacy, null]) {
        for (final kind in OnboardingFlowKind.values) {
          expect(
            resolveResumePage(savedPage: 0, savedFlow: flow, resolved: kind),
            0,
          );
        }
      }
    });

    test('an UNKNOWN saved flow resumes rather than restarting', () {
      // A pre-W2 install has no recorded flow. Restarting those users would
      // punish everyone who installed before the field existed, to guard
      // against a flip that may never happen. An unknown flow is not evidence
      // of a mismatch.
      expect(
        resolveResumePage(
          savedPage: 7,
          savedFlow: null,
          resolved: OnboardingFlowKind.reel,
        ),
        7,
      );
      expect(
        resolveResumePage(
          savedPage: 7,
          savedFlow: '',
          resolved: OnboardingFlowKind.trimmed,
        ),
        7,
      );
    });

    test('a garbage saved flow is treated as unknown, not as a mismatch', () {
      expect(
        resolveResumePage(
          savedPage: 5,
          savedFlow: 'something_nobody_ships',
          resolved: OnboardingFlowKind.reel,
        ),
        5,
      );
    });
  });
}

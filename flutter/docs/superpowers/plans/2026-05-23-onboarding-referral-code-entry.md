# In-Onboarding Referral Code Entry — Hybrid Pattern Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**PR bundling.** This work lands as ADDITIONAL commits on the existing PR #16 branch (`feat/2026-05-14-refer-unlock`), NOT as a separate follow-on PR. #16 already ships the deep-link path (`sakina://r/<code>` → `pending_referral` SharedPrefs → `apply_referral` RPC on signup); this plan extends that branch with an OPTIONAL in-onboarding text field and a permanent Settings entry that write to the SAME `pending_referral` key, so the existing `applyPendingReferralIfAny` plumbing handles both inputs with zero divergence. Reviewers see one cohesive referral story instead of two PRs in flight.

**Goal:** Capture referral attribution for users who heard about Sakina from a friend by WORD-OF-MOUTH (not by tapping a deep link). The friend says "I'll send you my code, type it in when you sign up" — we honor that with a one-tap-to-reveal "Add a friend's gift" entry on the Save Your Progress screen (onboarding page 18), plus a permanent Settings → "Redeem a referral code" entry for users who didn't have a code at signup but receive one later.

**Pre-launch context (load-bearing, same as #16).** Sakina is pre-launch with zero users. Paid acquisition budget is $0. Word-of-mouth from Muslim friends/family is the entire growth motion. The deep-link path in #16 only fires if the friend (a) has Sakina installed to share-sheet from, AND (b) the receiver's iOS/Android honors the custom scheme on first tap. In a pre-launch world with low install density on both sides, neither is reliable. The code-entry field captures the conversational case: "I told my sister about it, she's installing the app right now, she'll type in my code." This is the dominant share path in zero-density networks (see Hallow, Glorify, Calm growth research summary in Background below).

**Architecture.** No new server tables, no new SECURITY DEFINER write RPCs. We add ONE read-only RPC, `validate_referral_code(p_code text) returns boolean`, so the UI can give live feedback ("✓ Valid code from a friend" / "We didn't find that code") without telegraphing whether a given user exists. On submit (either onboarding field OR Settings entry) we write the code into the same `pending_referral` SharedPreferences key #16 owns. `applyPendingReferralIfAny()` on auth handles the rest — for the Settings path (where the user is already authenticated), we call `apply_referral` directly through the existing `ReferralService`.

**Why no new write RPC.** `apply_referral` already exists in #16 and is the canonical entry point. Writing a parallel "submit_referral_code" RPC would duplicate the self-referral / chain-referral / duplicate-referee guards. By funneling all three inputs (deep link, onboarding field, Settings field) through `applyPendingReferralIfAny`, we get one validation path, one analytics shape, one set of pgtap tests — and one rollback surface if anything misbehaves.

**Spiritual-native framing (the moat).** The field is NOT labelled "Referral code." It's "Did a friend send you a gift?" — the same reframe that made #16's "Send a dua to 3 friends" land. Generic referral SaaS copy ("Enter referral code", "Got a promo code?") is commodity and clashes with Sakina's brand. The gift framing matches the Islamic etiquette inversion in #16's plan: the act of giving is its own reward, the act of receiving is acknowledged with `جزاك الله خيرًا`. Microcopy in §UX below.

**Apple compliance.** Two-sided non-IAP premium-time grants (7d referee / 30d referrer) are explicitly permitted under Apple Guideline 3.1.1 — the entitlement is content delivery, not a discount on a future purchase. Hallow, Headspace, Calm, and Cal AI all run analogous patterns through App Review without friction. The Settings-side "Redeem" entry is the structurally identical Hallow pattern (Settings → Subscription → Redeem code) — green-lit prior art.

**Tech Stack:** Flutter 3.41.6 (no new packages), Supabase Postgres (one new read-only RPC), existing `referral_service.dart` + `analytics_service.dart`.

---

## Background — why this matters

The 2026-05-23 research pass (web search across 21+ subscription / wellness / fintech apps) found three things load-bearing for this plan:

1. **Hybrid pattern is the norm, not the exception.** Cash App, Coinbase, Revolut, Wise, Hallow, Headspace, Calm, Cal AI, Dropbox, Notion all ship BOTH (a) deep-link / share-sheet capture AND (b) a manual code-entry field. The split between users who arrive via tap vs. users who arrive via "type this in" is roughly 60/40 to 40/60 depending on app demographic; betting on one path alone leaves ~half the attributable growth on the table.

2. **Pre-install zero-density is where code entry dominates.** When neither side has the app yet, the conversation is "download Sakina and type GUMR9R34 when you sign up." Deep links can't fire across an uninstalled OS. Cal AI explicitly cites this as the reason their onboarding code field beat their deep link 3:1 in their first 90 days. Sakina is in the same pre-launch position TODAY.

3. **Friction-as-a-feature is wrong here.** Notion's "Got a promo code?" disclosure-triangle entry is the right UX shape: collapsed by default (zero friction for users without a code), tap-to-reveal a single-line input (one extra tap for users with a code). Validation is live but non-blocking — typing a bad code never gates the Continue button.

**Cannibalization is not a v1 concern** (same reasoning as #16). Pre-launch with zero users means no paying cohort exists to cannibalize from. Forward-instrument events; analyze when data arrives.

---

## File Structure

**Modify:**
- `lib/features/onboarding/screens/save_progress_screen.dart` — add the "Did a friend send you a gift?" collapsed-by-default disclosure field above the Apple/Google buttons. On debounced settle, persists code to `pending_referral` SharedPrefs key (the SAME key #16 deep-link path writes). Continue button is NEVER gated by this field. Pre-filled values from a deep-link capture are locked behind a "Change code" affordance (see A3 fix in Task 3).
- `lib/features/settings/screens/settings_screen.dart` — add a "Redeem a referral code" row near "Manage subscription" / "Restore purchases". Opens a small bottom-sheet with the same input + validation surface.
- `lib/services/referral_service.dart` — add `Future<bool> validateCode(String code)` (calls the new RPC) and `Future<({bool ok, bool granted7d, String? reason})> redeemCodeNow(String userId, String code)` for the Settings post-auth path.
- `lib/services/analytics_events.dart` — add referral-code-entry events (see Analytics below).
- `supabase/migrations/20260523000001_apply_referral_reason_split.sql` — patch `apply_referral` to differentiate `idempotent_same_code` vs `already_referred_other_code` on the duplicate-conflict path (closes A1 from eng review; was a silent-clobber). Full SQL block in Task 1 below.
- `supabase/tests/referrals_test.sql` — extend #16's pgtap suite with the two new reason-string cases.
- `CLAUDE.md` — extend the existing "Settings entry points" / referral discussion to note the two new input surfaces. One sentence.

**Create:**
- `supabase/migrations/20260523000000_referral_validate_rpc.sql` — `validate_referral_code(p_code text) returns boolean` (SECURITY DEFINER, `STABLE`, `search_path = public`, returns true iff a `user_profiles` row exists with that code AND that user is not the caller; regex `{8,16}` per A2 fix). RLS unaffected — function uses internal row read, never returns the referrer's identity.
- `supabase/tests/referral_validate_rpc_test.sql` — pgtap: returns false for unknown code, false for self-code, true for valid foreign code, normalizes case (input is uppercased before lookup), rejects malformed input (length, charset).
- `lib/features/settings/widgets/redeem_code_sheet.dart` — the bottom-sheet UI used by the Settings entry.
- `lib/widgets/referral_code_field.dart` — shared input widget (the disclosure-triangle field) used by BOTH `save_progress_screen` and `redeem_code_sheet`. Single source of truth for validation, debouncing (300ms), input formatters (uppercase, alphanumeric, 4-16 chars), and the live "✓ Valid" / "We didn't find that code" feedback chip.
- `test/widgets/referral_code_field_test.dart` — widget tests for the input behavior (debouncing, validation states, uppercase coercion, Continue-button non-blocking).
- `test/features/onboarding/save_progress_referral_field_test.dart` — pumps the screen, types a code, taps Apple, asserts `pending_referral` was written to SharedPrefs BEFORE `signInWithApple` fires.
- `test/features/settings/redeem_code_sheet_test.dart` — pumps the sheet authenticated, types a code, taps Redeem, asserts `apply_referral` RPC fires with the code and the success state renders.
- `test/services/referral_service_validate_code_test.dart` — unit-tests for `validateCode` (RPC wiring, debounce, error swallowing).

**Do NOT modify:**
- The deep-link path in `lib/main.dart` (`extractValidReferralCode`). Unchanged — keep the two ingress paths independent.
- `apply_referral` SQL function. The Settings path calls it via `ReferralService.redeemCodeNow` with the same params shape (`p_code`, `p_referee`) — no schema change.
- RevenueCat dashboard. Same as #16: referral grants are Supabase-only.

---

## Task 0: BLOCKING prerequisites — work on the #16 branch directly

**This work lands on `feat/2026-05-14-refer-unlock` (PR #16's branch), NOT on master and NOT on a new branch.** The plan extends #16's surfaces rather than depending on #16 having merged. Reviewers see the deep-link path + onboarding field + Settings redeem as one cohesive change.

- [ ] Check out the existing worktree: `cd /Users/appleuser/CS\ Work/Repos/sakina/refer-unlock/flutter` (or `git checkout feat/2026-05-14-refer-unlock`). Confirm you're on the right branch with `git branch --show-current`. If you have uncommitted changes from prior physical-device QA (button height 48→54, `sharePositionOrigin` fix), commit those first as their own commit so the bundling diff stays surgical.
- [ ] Verify the surfaces this plan hooks into are present in the current branch state (these were just verified during eng review, but re-check before coding in case anything moved):
  - `lib/services/referral_service.dart` exports `referralPendingReferralPrefsKey = 'pending_referral'` and `ReferralService.applyPendingReferralIfAny(String userId)`.
  - `lib/main.dart` has `pendingReferralPrefsKey`, `referralCodeRegex = ^[A-HJ-NP-Z2-9]+$`, and `extractValidReferralCode`.
  - `supabase/migrations/20260514000000_referrals.sql` defines `apply_referral(p_code text, p_referee uuid) returns jsonb` with reasons `invalid_code` / `self_referral` / `chain_referral` (and the duplicate-conflict path that A1 below patches).
- [ ] Update PR #16's description/title to reflect the expanded scope. Suggested title bump: `feat(referrals): refer-to-unlock + in-onboarding code entry + Settings redeem (hybrid pattern)`. Add a "What's bundled" section in the PR body listing the three ingress paths.
- [ ] Plan commit boundaries so the diff reads cleanly: one commit per Task (Task 1 SQL, Task 2 widget, Task 3 onboarding integration, Task 4 Settings sheet, Task 5 analytics, Task 6 copy, Task 8 docs). This keeps the PR navigable when a reviewer steps through the file-by-file view.

---

## Task 1: SQL — `validate_referral_code` RPC + pgtap tests

The UI needs a way to give live "is this a real code?" feedback without leaking which user owns it. One read-only RPC.

- [ ] Write `supabase/migrations/20260523000000_referral_validate_rpc.sql`:

```sql
-- Read-only validator for the in-onboarding / Settings referral code entry.
-- Returns true iff (a) p_code matches the 8-16 char A-HJ-NP-Z2-9 charset
-- after uppercasing, (b) a user_profiles row exists with referral_code =
-- upper(p_code), AND (c) that user is NOT the caller (auth.uid() self-check
-- — required so the UI can show "you can't redeem your own code" without
-- the client having to know the referrer's id).
--
-- 8-char minimum is intentional: ensure_referral_code emits 8-char codes,
-- so a 4-char input has no legitimate origin. Tightening to {8,16} also
-- closes the 32^4 ≈ 1M enumeration surface that {4,16} would expose to
-- the anon role.
--
-- Does NOT return the referrer's id, name, or any other field — only a
-- boolean. The actual self-referral / chain-referral / duplicate guards
-- still live in apply_referral (the write path); this is purely a UX
-- affordance.
create or replace function public.validate_referral_code(p_code text)
returns boolean
language plpgsql
security definer
set search_path = public
stable
as $$
declare
  v_code text;
  v_caller uuid := auth.uid();
  v_exists boolean;
begin
  if p_code is null then return false; end if;
  v_code := upper(trim(p_code));
  if v_code !~ '^[A-HJ-NP-Z2-9]{8,16}$' then return false; end if;

  select exists(
    select 1 from public.user_profiles
    where referral_code = v_code
      and (v_caller is null or id <> v_caller)
  ) into v_exists;

  return coalesce(v_exists, false);
end;
$$;

revoke all on function public.validate_referral_code(text) from public;
grant execute on function public.validate_referral_code(text) to anon, authenticated;
```

Why `anon, authenticated`: the onboarding field fires BEFORE the user has signed up — `auth.uid()` is null in that window. The function tolerates that (the `v_caller is null or id <> v_caller` clause). Once they sign up via Settings, `auth.uid()` is populated and the self-check kicks in.

Why `STABLE` + `SECURITY DEFINER` + pinned `search_path`: matches the project-wide convention from `20260510000000_pin_function_search_path.sql`. STABLE is correct because we read but never write.

Why 8-char minimum (closes A2 from eng review): `ensure_referral_code` in #16 always emits 8-char codes — there is no legitimate input shorter than that. 32^4 ≈ 1M is enumerable from `anon` in hours; 32^8 ≈ 1.1T is intractable. Mirror the 8-char floor on the CLIENT in `ReferralCodeField`'s `tooShort` threshold (Task 2).

- [ ] Patch `supabase/migrations/20260514000000_referrals.sql`'s `apply_referral` to differentiate idempotent same-code re-application from already-referred-by-a-different-code (closes A1 from eng review). Replace the duplicate-conflict tail (the `-- Idempotent re-application` block) with:

```sql
  -- Duplicate (referee_id) conflict: differentiate so the UI can tell the
  -- user whether their gesture was a no-op (same code re-applied) or a
  -- silent lockout (they typed a DIFFERENT code than the one already on
  -- their account). The unique(referee_id) constraint means the second
  -- code is dropped; previously the UI had no way to surface that.
  declare v_existing_referrer uuid;
  begin
    select referrer_id into v_existing_referrer
      from public.referrals where referee_id = p_referee;
    if v_existing_referrer = v_referrer then
      return jsonb_build_object('ok', true, 'granted_referee_7d', false,
                                'reason', 'idempotent_same_code');
    else
      return jsonb_build_object('ok', true, 'granted_referee_7d', false,
                                'reason', 'already_referred_other_code');
    end if;
  end;
```

Add pgtap cases to the existing `supabase/tests/referrals_test.sql` (NOT to the new `referral_validate_rpc_test.sql`):
- same-code re-application returns `reason: 'idempotent_same_code'`
- different-code application against same referee returns `reason: 'already_referred_other_code'`

- [ ] Write `supabase/tests/referral_validate_rpc_test.sql` (pgtap). Cases:
  - returns false for null / empty / `"   "` input
  - returns false for malformed input (too short — 4, 5, 6, 7 chars; too long; includes `I` / `O` / `0` / `1`; includes lowercase that doesn't normalize)
  - returns true for a valid 8-char uppercase foreign code
  - returns true for a valid 8-char lowercase foreign code (normalization works)
  - returns false when caller is the owner of the code (self-redeem rejection)
  - returns false when no row matches
  - returns true for an anon caller (auth.uid() is null) with a valid foreign code — pins the pre-signup onboarding-field code path

- [ ] Run `supabase test db` locally. All cases green before moving on.

- [ ] Apply migration to staging via `supabase db push` (or `mcp__supabase__apply_migration`). Smoke from `psql`: `select public.validate_referral_code('GUMR9R34')` returns true for a known seed code.

---

## Task 2: Shared `ReferralCodeField` widget

One widget used by both surfaces. Single source of truth for input rules.

- [ ] Create `lib/widgets/referral_code_field.dart`. API surface:

```dart
class ReferralCodeField extends ConsumerStatefulWidget {
  const ReferralCodeField({
    super.key,
    required this.onCodeChanged, // fires only when validation state changes
    this.initialValue,
    this.autofocus = false,
  });
  final void Function(String code, ReferralCodeValidationState state) onCodeChanged;
  final String? initialValue;
  final bool autofocus;
}

enum ReferralCodeValidationState {
  empty,           // nothing typed
  tooShort,        // < 4 chars, no validation fired yet
  validating,      // RPC in flight
  valid,           // RPC returned true
  invalid,         // RPC returned false
  networkError,    // RPC threw — show neutral "check connection" hint, NOT a hard fail
}
```

- [ ] Input formatters: inline `TextInputFormatter.withFunction((old, new) => new.copyWith(text: new.text.toUpperCase()))` for uppercase coercion (closes C3 from eng review — no shared `UpperCaseTextFormatter` exists in #16, claim was wrong; inlining keeps the diff small), then `FilteringTextInputFormatter.allow(RegExp('[A-HJ-NP-Z2-9]'))`, then `LengthLimitingTextInputFormatter(16)`. The client `tooShort` threshold is 8 chars to mirror the server regex (Task 1).

- [ ] Debounce: 300ms after the user stops typing, call `ref.read(referralServiceProvider).validateCode(code)`. Cancel in-flight on next keystroke. Use a `Timer?` field, not `package:async` — keep deps minimal.

- [ ] Trailing chip renders per state:
  - empty / tooShort / validating: no chip (or a subtle pulsing dot for validating)
  - valid: green `Icon(Icons.check_circle_rounded)` + "Valid gift code"
  - invalid: muted gray `Icon(Icons.help_outline_rounded)` + "We didn't find that code" — NOT red, NOT an error icon. The user might still want to keep it in case they typo'd, and we don't want this field to feel punishing.
  - networkError: neutral wifi-off icon + "Couldn't check right now — we'll verify when you sign up." This is the kill-resilient path: even if validation fails, the code still goes into `pending_referral` and is verified server-side on signup.

- [ ] `onCodeChanged` fires with the raw code text on the SAME 300ms trailing debounce edge as validation (closes C1 from eng review — per-keystroke prefs writes are inconsistent with the rest of the plan and waste disk I/O). One unified debounce pipeline drives: (a) RPC validation, (b) `pending_referral` prefs write, (c) `referral_field_code_entered` analytics. State transitions also gated on the debounce. The parent never gates a Continue button on `state == valid`; the field is advisory, not blocking.

- [ ] Write `test/widgets/referral_code_field_test.dart`:
  - typing "abc" → state goes empty → tooShort, no RPC call
  - typing "GUMR" + waiting 300ms → fires validateCode("GUMR")
  - typing "GUMR" then "GUMR9" within 300ms → only one RPC call, for "GUMR9"
  - validateCode returns true → state becomes valid, chip renders "Valid gift code"
  - validateCode throws → state becomes networkError, chip renders neutral hint
  - typing lowercase → field displays uppercase (formatter test)

---

## Task 3: Wire the field into `save_progress_screen.dart`

This is the high-traffic surface — 100% of new users land here.

- [ ] Insert the `ReferralCodeField` ABOVE the Apple Sign In button, inside a collapsed-by-default `ExpansionTile`-style disclosure. Default state: closed, header reads "Did a friend send you a gift?" in body-medium with a small chevron. Tapping reveals the field with autofocus.

- [ ] On every keystroke in the field (via `onCodeChanged`), write the current code to `SharedPreferences` under the `pending_referral` key (the SAME key #16 deep-link path writes to). This is critical for two reasons:
  - The user may type a code, then sign in with Apple — the Apple flow auto-jumps past 2 screens (`_skipToEncouragement`) — we need the code to be in prefs BEFORE the auth flow returns.
  - Kill-resilient: if the user types a code, closes the app, reopens it tomorrow, and signs up — the code is still in prefs. Matches the contract that `applyPendingReferralIfAny` already retries on cold launch via `AppSessionNotifier._reconcilePendingReferralOnAuth`.

- [ ] If the user CLEARS the field after typing a code, REMOVE the key from prefs. Don't leave a stale value to be auto-applied.

- [ ] Race-with-deep-link tiebreak: if `pending_referral` is ALREADY populated when the screen mounts (deep link captured first), pre-fill the field with that value AND open the disclosure expanded by default. Lock the field behind a "Change code" affordance — a small text link below the read-only display that, on tap, clears the value and opens a fresh input (closes A3 from eng review). Rationale: the deep-link code is a HIGHER-trust signal than a typed one (a friend explicitly tapped Share). Without the lock, one accidental keystroke against the pre-filled value silently destroys the friend's code with no undo. Once the user taps "Change code", normal field semantics apply (debounced prefs write, blank = key removed).

- [ ] DO NOT gate Continue / Apple / Google / Email buttons on validation state. The field is OPTIONAL — the only contract is "if there's a non-empty value in the field at submit, it gets persisted to prefs." Validation feedback is purely informational.

- [ ] Analytics: fire `referral_field_revealed` when the disclosure is opened, `referral_field_code_entered` when a code is persisted to prefs (debounced — fire on the same 300ms trailing edge as validation, not on every keystroke), `referral_field_code_cleared` when prefs key is removed.

- [ ] Write `test/features/onboarding/save_progress_referral_field_test.dart`:
  - mount screen with empty prefs → disclosure is closed by default
  - mount screen with pre-set `pending_referral` → disclosure is open, field renders read-only with the pre-fill, "Change code" affordance is visible (A3 regression pin — typing without tapping Change must NOT mutate prefs)
  - tap "Change code" → field becomes editable, prior value cleared, prefs key removed
  - type code → after 300ms, prefs key is written (and ONLY one prefs write happened, not one-per-keystroke — C1 regression pin)
  - clear field → prefs key is removed (debounced)
  - tap Apple sign-in → mock `signInWithApple` captures, assert prefs key was written BEFORE the auth call (use a sequencing assertion via `ProviderContainer.listen` or call-order tracking on a fake)
  - **[T1 REGRESSION]** empty field + tap Apple sign-in → mock `signInWithApple` returns success → assert `_skipToEncouragement` fires (pins that the field, when empty, does NOT interfere with the social-auth onboarding shortcut from #16)
- [ ] Write `test/services/app_session_referral_cold_launch_test.dart` (new — closes T2 from eng review):
  - seed SharedPrefs with a `pending_referral` value shaped like a field write (no deep-link metadata)
  - simulate authenticated session resume via `AppSessionNotifier._reconcilePendingReferralOnAuth`
  - assert `applyPendingReferralIfAny` is invoked and the key is drained
  - this pins that the field-write path and deep-link path share the same drain — adding a fourth path would have to either reuse this drain or add a parallel test here

---

## Task 4: Wire the same field into Settings → Redeem

Authenticated path. Goes through `apply_referral` directly because there's no "deferred signup" to drain into.

- [ ] Add `lib/features/settings/widgets/redeem_code_sheet.dart` — a `showModalBottomSheet` content widget containing the `ReferralCodeField` + a single "Redeem" CTA.

- [ ] On Redeem tap: set `bool _isRedeeming = true` (closes C2 from eng review — without this flag, a double-tap fires the RPC twice and amplifies the same-vs-other-code ambiguity from A1). Button visibly disabled while `_isRedeeming`. Reset to false in a `finally` so the user can retry after a network error. Then call `ReferralService.redeemCodeNow(userId, code)`. The new method:

```dart
Future<({bool ok, bool granted7d, String? reason})> redeemCodeNow(
    String userId, String code) async {
  if (userId.isEmpty || code.isEmpty) return (ok: false, granted7d: false, reason: 'invalid');
  try {
    final raw = await _supabase.rpc<dynamic>(
      'apply_referral',
      params: <String, dynamic>{'p_code': code, 'p_referee': userId},
    );
    final result = raw is Map ? Map<String, dynamic>.from(raw) : null;
    final ok = result?['ok'] == true;
    final granted = result?['granted_referee_7d'] == true;
    final reason = result?['reason'] as String?;
    if (ok) {
      _analytics?.track(AnalyticsEvents.refereeSignedUpWithReferral,
          properties: {'source': 'settings_redeem'});
      if (granted) _analytics?.track(AnalyticsEvents.refereeGranted7dWindow,
          properties: {'source': 'settings_redeem'});
      await PurchaseService().refreshReferralPremiumCache();
    }
    return (ok: ok, granted7d: granted, reason: reason);
  } catch (e) {
    debugPrint('[ReferralService] redeemCodeNow failed: $e');
    return (ok: false, granted7d: false, reason: 'network_error');
  }
}
```

- [ ] Result rendering (inside the sheet) — reason strings below must match the actual `apply_referral` return values verified against #16's `supabase/migrations/20260514000000_referrals.sql:140-198` plus the new branches added in Task 1:
  - `ok && granted7d`: replace sheet body with success state — green check, "جزاك الله خيرًا — your friend just gave you 7 days of Sakina." Auto-dismiss after 2.5s.
  - `ok && !granted7d && reason == 'idempotent_same_code'`: friendly acknowledgement, "You've already used this code." Auto-dismiss after 2.5s.
  - `ok && !granted7d && reason == 'already_referred_other_code'`: clear lockout copy, "You've already redeemed a code on this account — only one per account." Do NOT auto-dismiss; user needs to read this.
  - `!ok && reason == 'invalid_code'`: "We couldn't find that code. Double-check it and try again." Keep field populated.
  - `!ok && reason == 'self_referral'`: "You can't redeem your own code."
  - `!ok && reason == 'chain_referral'`: "This account isn't eligible." (Vague on purpose — #16's plan covers why.)
  - `network_error` (caught client-side, not a server reason): "We couldn't apply that code. Check your connection and try again." Keep field populated.

- [ ] Add the entry point in `lib/features/settings/screens/settings_screen.dart`. Place row between "Restore purchases" and account management. Icon: `Icons.card_giftcard_rounded`. Label: "Redeem a referral code". Subtitle (smaller, secondary text): "Apply a friend's gift to your account."

- [ ] Hide the Settings entry from users who are ALREADY premium via referral (`PurchaseService.isPremium()` is true AND the source is referral). Optional polish — if uncertain, leave it always visible; the RPC will gracefully reject the `already_referred` case.

- [ ] Write `test/features/settings/redeem_code_sheet_test.dart`:
  - happy path: type valid code → tap Redeem → mock RPC returns `{ok: true, granted_referee_7d: true}` → success state renders
  - **[T5 REGRESSION]** already-redeemed-other-code: mock RPC returns `{ok: true, granted_referee_7d: false, reason: 'already_referred_other_code'}` → clear lockout copy renders (this branch is the WHOLE POINT of the A1 SQL change; without this test the silent-clobber regression could reappear)
  - idempotent same-code: mock returns `{ok: true, granted_referee_7d: false, reason: 'idempotent_same_code'}` → "you've already used this code" copy renders
  - self-referral: mock returns `{ok: false, reason: 'self_referral'}` → specific copy renders
  - chain-referral: mock returns `{ok: false, reason: 'chain_referral'}` → vague copy renders
  - invalid code: mock returns `{ok: false, reason: 'invalid_code'}` → field stays populated
  - network error: mock throws → "Couldn't apply" copy renders, field stays populated
  - **[C2 REGRESSION]** double-tap Redeem: tap twice within 100ms → mock RPC is called EXACTLY once (pins the `_isRedeeming` in-flight disable)
  - sheet auto-dismiss: on success, advance fake timer 2.5s → assert sheet popped

- [ ] Write `test/services/referral_service_validate_code_test.dart`:
  - validateCode("") returns false without calling RPC
  - validateCode("abc") returns false without calling RPC (too short — client-side guard before RPC)
  - validateCode("GUMR9R34") calls `validate_referral_code` RPC with that param, returns boolean from response
  - RPC throws → returns false (swallow, never let validation surface a crash to the field)

---

## Task 5: Analytics — forward-instrument code-entry funnel

Same forward-instrumentation philosophy as #16 Task 5. Pre-launch = no cohort, but the funnel needs to be analyzable the moment users arrive.

- [ ] Add to `lib/services/analytics_events.dart`:

```dart
/// Fired when the onboarding "Did a friend send you a gift?" disclosure is
/// opened. Funnel start for the code-entry path.
static const referralFieldRevealed = 'referral_field_revealed';

/// Fired when a code (4+ chars) is persisted to pending_referral prefs via
/// the onboarding field. Debounced 300ms — one event per "settled" code,
/// not one per keystroke.
static const referralFieldCodeEntered = 'referral_field_code_entered';

/// Fired when a user clears a previously-entered code.
static const referralFieldCodeCleared = 'referral_field_code_cleared';

/// Fired when the Settings redeem entry is tapped (sheet opens).
static const referralSettingsRedeemOpened = 'referral_settings_redeem_opened';

/// Fired when Redeem is tapped in the Settings sheet (whether successful
/// or not — paired with refereeSignedUpWithReferral for success).
static const referralSettingsRedeemSubmitted = 'referral_settings_redeem_submitted';
```

- [ ] Extend the existing `refereeSignedUpWithReferral` and `refereeGranted7dWindow` calls to include a `source` property: `'deep_link'` (existing PR #16 path), `'onboarding_field'` (Task 3), `'settings_redeem'` (Task 4). This is how we'll measure the 60/40 vs 40/60 split between paths.

- [ ] Verify in Mixpanel staging that all five new events plus the augmented `source` property arrive correctly. One end-to-end smoke per path.

---

## Task 6: UX copy + microcopy review

The copy is the moat — get it right.

- [ ] Pin the strings in `lib/core/app_strings.dart` (or wherever the existing onboarding strings live — check the project; for refer-unlock the strings were inlined for v1, follow the same convention here unless a strings file already exists for this surface):

  - Disclosure header (collapsed): **"Did a friend send you a gift?"**
  - Field placeholder: **"Enter their code"**
  - Validation success chip: **"Valid gift code"**
  - Validation soft-fail chip: **"We didn't find that code"** (NOT "Invalid code")
  - Network error chip: **"Couldn't check right now — we'll verify when you sign up."**
  - Settings row label: **"Redeem a referral code"**
  - Settings row subtitle: **"Apply a friend's gift to your account."**
  - Settings sheet header: **"Redeem your friend's gift"**
  - Settings success body: **"جزاك الله خيرًا — your friend just gave you 7 days of Sakina."** (Arabic phrase is intentional — it's the standard Islamic "may Allah reward you with good" said in receipt of a gift. Renders right-to-left in its own `Text` widget per CLAUDE.md's Arabic-rendering rules.)

- [ ] DO NOT use any of these phrasings (banned per the spiritual-native moat):
  - "Got a promo code?"
  - "Enter referral code"
  - "Redeem free month"
  - "Invite code"
  - "Promo"

- [ ] All UX copy must be reviewable diff-wise. The widget test in Task 2 must include negative `findsNothing` pins on at least three of the banned phrases, mirroring the pattern from `test/features/paywall/refer_unlock_screen_test.dart`'s "spiritual-native copy" test.

---

## Task 7: Manual QA pass (P0 before merge)

Same physical-device-required reasoning as #16. Some of this can be sim-tested; the prefs / cold-launch interactions need a real device.

**Simulator (iPhone 17, fresh install) — quick happy path:**

- [ ] Onboarding from page 0 to page 18. Open disclosure. Type a valid seed code. Wait 300ms — chip flips to green "Valid gift code".
- [ ] Tap Apple sign-in. Skip-to-encouragement path fires. Open Mixpanel staging, confirm `referral_field_code_entered` fired and `refereeSignedUpWithReferral` arrived with `source: 'onboarding_field'`.
- [ ] In another simulator, fresh install. Skip the disclosure entirely. Confirm signup completes with no errors and no `pending_referral` value lingers.
- [ ] Authenticated user in Settings. Tap "Redeem a referral code". Sheet opens. Type valid foreign code. Tap Redeem. Success state renders. Premium becomes active (verify with a gated screen like Reflect).

**Physical device (iPhone, real iOS Share Sheet + cold-launch behavior):**

- [ ] Type a code into the onboarding field. Force-quit the app before signing up. Relaunch. Resume onboarding from where it left off. Confirm the field is pre-populated with the saved code (because the prefs persisted).
- [ ] Cross-account test: User A's code, User B redeems via onboarding field. User C redeems same User A code via Settings. Both should grant 7d to B and C, and User A's confirmed_count should advance accordingly.
- [ ] Self-referral test: User A's code, User A tries to redeem via Settings. Sheet shows "You can't redeem your own code."
- [ ] Network-off test: Toggle airplane mode. Type code in onboarding field. Chip shows network-error neutral hint. Continue with Apple. Re-enable network. Confirm code is still applied on next cold launch via the defensive cold-launch reconciler.

---

## Task 8: Documentation + decision log

- [ ] Update `CLAUDE.md`: in the existing referral / settings discussion (if PR #16 added one — check first), append a short paragraph: "Three code-ingress paths: (1) `sakina://r/<code>` deep link captured in `lib/main.dart`; (2) optional disclosure field on save_progress_screen (onboarding page 18); (3) Settings → Redeem a referral code. All three persist into the same `pending_referral` SharedPrefs key and drain via `applyPendingReferralIfAny` — or, for the post-auth Settings path, via `redeemCodeNow` directly. Adding a fourth path? Reuse one of these drains; do not add a parallel one."
- [ ] Add a short note to `docs/decisions/` (per the directory observed in `git status`) capturing the "why hybrid" decision and the one-RPC architecture choice. ~30 lines max.

---

## Rollback / Kill Switch

No env flag needed — the field is collapsed by default. If something is wrong:

- **Surgical rollback:** Hide the disclosure widget behind a quick boolean constant in `lib/core/env.dart` (`referralCodeEntryEnabled`, default true; flip to false in `env.json` and rebuild). The widget tree becomes a no-op and the prefs key is never written from this path. Deep-link path #16 continues to function.
- **Server-side cutoff:** `revoke execute on function public.validate_referral_code(text) from anon, authenticated;` — UI loses its live validation feedback but still falls back to the network-error chip + post-signup verification, so codes still apply. Use this if the validate RPC is being abused (e.g. enumeration scanning).

---

## Out of Scope (Phase 2+)

- Branded share assets / referral landing page (depends on `sakina.app` domain ownership — same blocker as #16 Phase 2 universal links).
- A/B test: disclosure default-closed vs default-open. Wait for v1 data.
- Referral tier visualization in Settings ("3 friends joined → 30d unlocked"). PR #16 owns the post-signup loop; Settings can read those numbers but the visualization is a follow-on plan.
- Email / SMS code delivery (i.e., "we'll text your friend the code"). Adds a Twilio dependency and a CAN-SPAM / TCPA review. Out of scope.
- Multi-redeem per user (one referee can only consume one code in #16's schema; this stays).

---

## Open Questions for Reviewer

1. **Default state of the disclosure.** Closed (current plan, lower friction) vs Open (current plan would only auto-open if a deep-link code was already captured — but maybe open is right always, to maximize discoverability). Default proposed: closed; open if pre-populated. Reviewer pushback welcome.
2. **Settings entry visibility for already-redeemed users.** Hide it (cleaner) vs show with disabled state (more discoverable but reveals state). Default proposed: always show, rely on RPC rejection (now safe to do because A1's `already_referred_other_code` reason surfaces the rejection cleanly). Reviewer pushback welcome.
3. ~~`validate_referral_code` 4-char enumeration surface~~ — RESOLVED by A2: regex tightened to `{8,16}` in both server RPC and client `tooShort` threshold. Anon-callable surface accepted.

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR (PLAN) | 6 issues found, 6 resolved in-plan |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**UNRESOLVED:** 0 — all 6 findings folded into the plan on 2026-05-23.

**Resolved findings:**
- **A1 [P0]:** `apply_referral` now returns `idempotent_same_code` vs `already_referred_other_code` (Task 1 SQL patch + Task 4 sheet dispatch + T5 regression test). Was: invented `'already_referred'` reason that could never fire.
- **C3 [P0]:** Inlined `TextInputFormatter.withFunction` for uppercase coercion (Task 2). Was: claimed reuse of non-existent shared formatter.
- **A3 [P1]:** Pre-filled deep-link code locked behind "Change code" affordance (Task 3). Was: silent clobber on first keystroke.
- **A2 [P1]:** Validator regex tightened from `{4,16}` to `{8,16}` on both server and client (Task 1 + Task 2). Was: 32^4 enumeration surface from anon role.
- **C1 [P1]:** Prefs write debounced to same 300ms trailing edge as RPC + analytics (Task 2 `onCodeChanged` contract). Was: per-keystroke disk I/O.
- **C2 [P1]:** Settings Redeem button gated by `_isRedeeming` flag with `finally`-reset (Task 4) + double-tap test (Task 4 tests). Was: no in-flight protection.

**Net test additions:** T1 (empty-field social-auth regression), T2 (cold-launch reconciler), T5 (already_referred_other_code regression), C2 double-tap pin, sheet auto-dismiss pin, anon `validate_referral_code` pgtap case.

**VERDICT:** CLEAR — plan is ready to implement. Land #16 first (Task 0 blocking dep), then this. Recommend `/plan-ceo-review` before kickoff if you want a second-pair-of-eyes on scope vs. landing #16-only.

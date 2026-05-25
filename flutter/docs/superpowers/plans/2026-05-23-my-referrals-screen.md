# My Referrals Screen — Settings Entry + Progress UI

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Give the referrer a permanent, post-onboarding surface to (a) see their own referral code, (b) re-share it, (c) see how many friends have joined and how far they are from the next reward, and (d) see rewards already earned. Today the only progress UI in the app is the "Send to friends (X / 3 joined)" button label inside `ReferUnlockScreen`, which is reachable exactly once during onboarding. After that, the referrer goes blind — they don't know if anyone joined, can't re-share, and can't see grants land.

**Why this matters:** PR-18 ships the referral mechanic. Without a progress surface, the loop is broken on the referrer's side — they share once during onboarding and then have zero feedback. That kills retention of the growth mechanic itself. Settings is the canonical "always-reachable" surface in Sakina; a row there + a small standalone screen is the smallest fix that closes the loop.

**Pre-launch context:** Same as the PR-18 plan — zero users, refer-unlock is the primary growth mechanic, no cohort to measure against. Forward-instrument analytics for the new surface so we can see whether the Settings entry actually drives re-shares.

---

## Scope

**In v1:**
- Settings → "Refer a friend" row (sibling of the existing "Redeem a referral code" row)
- New route `/my-referrals` pushing `MyReferralsScreen`
- Screen shows: referral code (copy-tap), Share button, "X friends joined" count, progress toward next reward (X / 3 dots), list of grants earned (date + tier)
- One new `ReferralService` method: `Future<MyReferralsState> getMyReferralsState(String userId)` — single round-trip via two parallel queries (`referrals` confirmed count + `referral_grants` list)
- Reuse share logic from `refer_unlock_screen.dart` (factor to small helper or copy — see Decision below)
- 4 widget tests pinning the rendering at the key states (0/3, 2/3, 3/3 after grant, multiple grants)

**Also in v1 (confirmed 2026-05-23 after OneSignal free-tier check):**
- Push notification on referral confirmation. OneSignal free tier allows unlimited mobile push subscribers (10k cap is Web Push / Live Activities only — irrelevant). Real constraints on free: (1) REST API rate limit 150 req/sec/app — non-issue for our isolated 1-per-confirmation trigger; (2) "10× total subscribers in any rolling 15-min window" message cap — app can be disabled if exceeded, but we'd need every subscriber to refer 10 friends who all confirm in the same 15 min to hit it, not physically possible. OneSignal SDK is already integrated and `OneSignal.login(userId)` is called at sign-in (`notification_service.dart:71`), so external-id targeting is already live. The only new work is a Postgres trigger that fires `pg_net` POST to OneSignal REST API on `referrals.status` flip to `'confirmed'`. **API note:** use modern `include_aliases: {external_id: [...]}`, not the deprecated `include_external_user_ids`.

**Out of scope (separate plan):**
- In-app banner / toast on the home screen when a confirm lands while the user is foregrounded
- "Friends invited" list with each friend's display name (privacy review needed)
- Referrer-side leaderboard / streaks

---

## Decision: factor share or copy?

The share text + `Share.share` call with the iPad popover origin trick lives in `refer_unlock_screen.dart:100-134`. Two callers now. Factor it once into `ReferralService.shareMyCode(BuildContext context, String code, {Future<void> Function(String)? override})` so both screens share the same wire and the popover-origin gotcha lives in one place. The `shareOverride` test seam (already in ReferUnlockScreen) becomes a method param.

---

## File Structure

**Create:**
- `lib/features/referrals/screens/my_referrals_screen.dart` — the new screen
- `test/features/referrals/my_referrals_screen_test.dart` — widget tests

**Modify:**
- `lib/services/referral_service.dart` — add `getMyReferralsState(userId)` + `shareMyCode(...)` helper. Export a small `MyReferralsState` record/class.
- `lib/features/settings/screens/settings_screen.dart` — add a "Refer a friend" row in the same card group as "Redeem a referral code"
- `lib/core/router.dart` — register `GoRoute(path: '/my-referrals', ...)`
- `lib/services/analytics_events.dart` — add 3 events: `myReferralsShown`, `myReferralsShareTapped`, `myReferralsCodeCopied`
- `lib/features/paywall/screens/refer_unlock_screen.dart` — swap the inline share logic to call the new `referralService.shareMyCode(...)` helper (DRY pass)

**Untouched:**
- Server schema (`referrals` + `referral_grants` tables already have the right RLS — owner-scoped select on grants, plus the existing apply_referral RPC writes correctly)
- `PurchaseService` — no premium-gate changes; reading `referral_grants` doesn't change isPremium semantics
- ReferUnlockScreen layout — we're just adding a complementary post-onboarding surface

---

## Service API

```dart
class MyReferralsState {
  const MyReferralsState({
    required this.code,
    required this.confirmedCount,
    required this.grants,
  });
  final String code;        // 8-char A-HJ-NP-Z2-9
  final int confirmedCount; // total confirmed referees ever
  final List<MyReferralGrant> grants; // newest first

  /// Confirmed referees since the most-recent grant (or all confirmed if no
  /// grant yet). Drives the "X / 3" progress dots on the screen.
  int get progressTowardNext {
    if (grants.isEmpty) return confirmedCount.clamp(0, 3);
    // Server-side trigger awards at +3 NEW since last grant. Mirror that
    // by counting confirmations after the last grant's granted_at.
    // We don't have per-referral confirmed_at on the client here; the
    // simpler approximation is (confirmedCount - grants.length * 3),
    // clamped to [0, 3]. Exact and stable across the grant flow.
    return (confirmedCount - grants.length * 3).clamp(0, 3);
  }
}

class MyReferralGrant {
  const MyReferralGrant({
    required this.grantedAt,
    required this.expiresAt,
    required this.cardTier,
  });
  final DateTime grantedAt;
  final DateTime expiresAt;
  final String cardTier; // 'gold', etc.
}

extension on ReferralService {
  Future<MyReferralsState> getMyReferralsState(String userId);
  Future<void> shareMyCode(BuildContext context, String code,
      {Future<void> Function(String)? override});
}
```

Implementation notes:
- `getMyReferralsState` fires two reads in parallel via `Future.wait`: one `referrals` select (count) + one `referral_grants` select (rows). Plus a `getMyReferralCode(userId)` call (already cached via the `user_profiles.referral_code` column).
- RLS is already correct — referrer can only read their own referrals (existing policy) and their own grants (`referral_grants_select_owner` policy in `20260514000000_referrals.sql`).
- Empty / error case: bubble a small error state to the UI; never crash, always render the screen with a retry button.

---

## Screen layout sketch

Standard `Scaffold` + `SafeArea` + `SubpageHeader(title: 'Refer a friend', subtitle: 'Send a dua to 3 friends to unlock 30 days + a Gold card.')`. Body sections (top to bottom):

1. **Code card** (`AppColors.surfaceLight`, 16px radius, 24px padding)
   - "Your code" label (bodySmall, secondary)
   - Code displayed huge (`displayMedium`, monospace, letter-spaced) — tap to copy with haptic
   - Subtle "Tap to copy" hint (`bodySmall`, tertiary)

2. **Share button** (primary green, full width, `Icons.ios_share`)
   - Routes through `referralService.shareMyCode(context, code)`
   - Fires `myReferralsShareTapped` analytics

3. **Progress section**
   - "X of 3 friends joined" headline
   - 3 dots inline: filled green if `i < progressTowardNext`, hollow border otherwise
   - Caption: "Sending love means a dua for them too — the Angel says Ameen for you in return." (subtle hadith echo, no citation in body — keep light)
   - If `progressTowardNext == 0 && grants.isNotEmpty`: caption flips to "Your last reward is active until {date}. Send to 3 more to earn another."

4. **Grants earned** (only renders if `grants.isNotEmpty`)
   - Section label "Rewards earned"
   - List of grant rows: gold star icon, "30 days + Gold card", "Earned {date}" (relative — "today" / "3 days ago" / "Mar 12")
   - No interaction; pure display

5. **Empty-state footer** (renders if `confirmedCount == 0 && grants.isEmpty`)
   - Soft subtitle: "No one's joined yet. Share your code with a friend who'd love this."

PopScope is unnecessary — the back button is the SubpageHeader's; system back works.

---

## Tests

`test/features/referrals/my_referrals_screen_test.dart` — widget tests with a `_FakeReferralService` that overrides `getMyReferralsState` per test. Following the existing pattern in `test/widgets/referral_code_field_test.dart` (Fake + injected via ProviderScope).

- [ ] **renders empty state** when `confirmedCount=0, grants=[]` — verifies the "No one's joined yet" footer copy + share button enabled + 0 filled dots
- [ ] **renders 2/3 progress** when `confirmedCount=2, grants=[]` — 2 filled dots, 1 hollow, "2 of 3 friends joined" headline
- [ ] **renders earned reward + reset progress** when `confirmedCount=3, grants=[gold @ today]` — 0 filled dots (next cycle), "Your last reward is active until..." caption, grant row visible
- [ ] **renders multi-grant** when `confirmedCount=7, grants=[gold @ today, gold @ -30d]` — 1 filled dot toward next, both grant rows in list (newest first), no crashes on date formatting
- [ ] **tap-to-copy fires analytics + snackbar** — pump screen, tap code, verify Clipboard.getData matches + snackbar text + `myReferralsCodeCopied` event fired
- [ ] **share button calls referralService.shareMyCode with override** — pumps with `shareOverride` capturing the share text, verifies the wire matches the canonical "I made a dua for you..." copy

Plus one service test:
- [ ] `referral_service_my_referrals_state_test.dart` — pure unit test of `MyReferralsState.progressTowardNext` math across (0 grants, 0–4 confirmed), (1 grant, 3–7 confirmed), (2 grants, 6–10 confirmed). Pins the formula so a future "fancier" rewrite can't drift.

No SQL test needed — read-only queries on existing tables, RLS already pinned by `supabase/tests/backend_rls_test.sql`.

---

## Analytics events to add

In `lib/services/analytics_events.dart`:

```dart
static const String myReferralsShown = 'my_referrals_shown';
static const String myReferralsShareTapped = 'my_referrals_share_tapped';
static const String myReferralsCodeCopied = 'my_referrals_code_copied';
```

Properties on `myReferralsShown`: `confirmed_count`, `grants_count`. Lets Mixpanel slice "how many people open the screen with 0 vs 2 referrals" — surfaces whether the screen acts as a re-engagement loop.

---

## Tasks (execution order)

- [ ] **T1 — Service additions.** Add `MyReferralsState` + `MyReferralGrant` classes (Freezed if the file uses it elsewhere, else plain immutable). Add `getMyReferralsState(userId)` using `Future.wait` over two parallel selects + the cached code. Add `shareMyCode(context, code, {override})` factored from `ReferUnlockScreen._onShare`. Add 3 analytics constants.
- [ ] **T2 — Service unit test.** Pin `progressTowardNext` math (table-driven).
- [ ] **T3 — Screen.** Create `lib/features/referrals/screens/my_referrals_screen.dart` per the layout sketch above. Use `SubpageHeader`, `SakinaLoader` for loading, error retry button on failure.
- [ ] **T4 — Widget tests.** All 6 cases above.
- [ ] **T5 — Router.** Add `GoRoute(path: '/my-referrals', builder: (_, __) => const MyReferralsScreen())` to `lib/core/router.dart`.
- [ ] **T6 — Settings row.** Add "Refer a friend" row (icon: `Icons.group_add_rounded` or `Icons.send_rounded`) in the same card group as "Redeem a referral code". Tap pushes `/my-referrals` via `context.push`.
- [ ] **T7 — DRY pass on ReferUnlockScreen.** Swap the inline share logic for `referralService.shareMyCode(...)`. Delete the now-dead local share code. Make sure the existing `shareOverride` widget param still routes through (pass it as the method's override arg).
- [ ] **T8 — Run analyze + test.** `flutter analyze` clean; `flutter test test/features/referrals/ test/services/referral_service_my_referrals_state_test.dart` green.
- [ ] **T9 — QA via iOS Simulator MCP.** Walk through: existing referrer signs in → Settings → Refer a friend → see code + share + progress. Then exercise: tap code (copies), tap Share (system sheet opens), back button works. Screenshot each state.
- [ ] **T10 — Push: verify edge-function secrets.** Verify `ONESIGNAL_API_KEY` and `ONESIGNAL_APP_ID` are set as Supabase Edge Function secrets (they should already be — they power `send-scheduled-notifications`). No new secrets required. Also verify `pg_net` extension is enabled (`select * from pg_extension where extname = 'pg_net';`).
- [ ] **T11 — Push: migration + edge function (two deliverables).**
  - Migration `supabase/migrations/20260523010000_push_on_referral_confirm.sql`: thin plpgsql trigger on `referrals` AFTER UPDATE OF status WHEN (OLD distinct from 'confirmed' and NEW = 'confirmed') that POSTs to the edge function via `net.http_post`. SECURITY DEFINER, exception-swallowed, no auth header (matches existing cron pattern).
  - Edge function `supabase/functions/notify-referral-confirmed/index.ts`: reads `ONESIGNAL_APP_ID`/`ONESIGNAL_API_KEY` from `Deno.env`, looks up referee `display_name`, POSTs to `https://api.onesignal.com/notifications` with `Authorization: Key <REST_KEY>` (modern format) and the `include_aliases: {external_id: [referrer]}` / `target_channel: 'push'` v2 shape. Best-effort: returns 200 on OneSignal failure so the trigger never sees a non-2xx.
- [ ] **T11b — Push: deploy the edge function.** `supabase functions deploy notify-referral-confirmed --no-verify-jwt` (mirrors `send-scheduled-notifications`'s deploy posture; the trigger calls it from inside the project, no JWT available).
- [ ] **T12 — Push: SQL test.** `supabase/tests/push_on_referral_confirm_test.sql` pinning trigger semantics by stubbing `net.http_post` into a capture table.
- [ ] **T13 — Push: manual QA.** Fresh signup with referral code on simulator/device → confirm landed in referrer's notification center via real device (sim can't receive APNs).
- [ ] **T14 — Update CLAUDE.md "Onboarding Flow" or relevant section** if a fresh dev would otherwise wonder where the referrer-side surface lives. Probably one sentence under a new "Referrals" subsection pointing at `/my-referrals` + the push trigger.

---

## Push notification on confirm (v1 — added 2026-05-23, hardened 2026-05-23 post-/review)

Free tier confirmed adequate (see "Also in v1" above). Implementation:

**Server side (edge-function indirection — NOT Vault, NOT direct OneSignal call from plpgsql):**

The OneSignal REST key must never live in the DB. Instead, mirror the pattern already used by `send-scheduled-notifications`: a thin plpgsql trigger that POSTs to a new edge function via `net.http_post`, and the edge function holds the OneSignal credentials in its `Deno.env`.

- Verify `pg_net` extension is enabled on this project (`select * from pg_extension where extname = 'pg_net';`).
- `ONESIGNAL_API_KEY` and `ONESIGNAL_APP_ID` are already deployed as Supabase Edge Function secrets — they power `send-scheduled-notifications`. **One NEW edge-function secret required:** `NOTIFY_REFERRAL_SECRET` (32-char random string, e.g. `openssl rand -hex 16`). Set via `supabase secrets set NOTIFY_REFERRAL_SECRET=...`.
- **Two NEW Postgres GUCs required** (set per-environment, NOT in the migration):
  - `alter database postgres set app.notify_referral_url = 'https://<project-ref>.supabase.co/functions/v1/notify-referral-confirmed';`
  - `alter database postgres set app.notify_referral_secret = '<same-secret-as-edge-side>';`
  - Reconnect sessions after `alter database` for the new values to apply.
- **New edge function** `supabase/functions/notify-referral-confirmed/index.ts`:
  - Reads `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `ONESIGNAL_APP_ID`, `ONESIGNAL_API_KEY`, `NOTIFY_REFERRAL_SECRET` from `Deno.env`. Fails-closed 500 on missing env.
  - **Shared-secret gate (S1 fix):** rejects any request without header `X-Notify-Secret: <NOTIFY_REFERRAL_SECRET>` with 401. Without this, --no-verify-jwt + URL leak = anyone can spam pushes.
  - **Display-name sanitization (S2 + S9 fix):** NFKC normalize → strip control/zero-width/bidi-override chars → reject if contains `://` / `http` / `www.` / `@` → cap at 30 chars → fallback `'A friend'`. Prevents a malicious user from setting their display_name to a phishing string ("Free 1yr → bit.ly/xyz") that gets pushed to legitimate referrers.
  - Method gate: POST only (405 on anything else). UUID shape validation on `referrer_id` + `referee_id`.
  - Looks up `display_name` from `user_profiles` for the referee via service-role supabase client; sanitizes per above.
  - POSTs to `https://api.onesignal.com/notifications` with header `Authorization: Key ${REST_KEY}` (modern format — `Basic` is deprecated) and body shape `{app_id, include_aliases: {external_id: [referrer_id]}, target_channel: 'push', contents: {en: "{name} just joined Sakina with your code 🌙"}, headings: {en: 'A friend joined'}, data: {type: 'referral_confirmed', referee_id}}`.
  - Best-effort delivery: any OneSignal non-2xx or `recipients: 0` is logged but the function still returns 200, because the caller is a DB trigger and a 5xx response cannot be usefully retried.
  - **No CORS headers (S8 fix):** function is trigger-only, not browser-callable. Removing CORS prevents future drift ("the web build can fetch this — CORS allows it").
  - Deployed `--no-verify-jwt` (shared secret IS the auth gate).
- **New migration** `supabase/migrations/20260523010000_push_on_referral_confirm.sql`:
  - `notify_referrer_on_confirm()` SECURITY DEFINER with `set search_path = public, extensions, pg_temp`.
  - **Env-bound URL (S3 fix):** reads `current_setting('app.notify_referral_url', true)` instead of hardcoded prod subdomain. No-ops if unset (cannot accidentally fire prod pushes from staging).
  - **Shared-secret header (S1 fix):** reads `current_setting('app.notify_referral_secret', true)` and passes as `X-Notify-Secret` header. No-ops if unset.
  - Body wrapped in `BEGIN ... EXCEPTION WHEN OTHERS THEN RAISE WARNING ... RETURN NEW; END;` — push failure must never roll back the confirmation transaction.
  - **Tightened WHEN clause (S4 fix):** `WHEN (OLD.status = 'pending' AND NEW.status = 'confirmed')` — only the legitimate `pending → confirmed` transition fires. Blocks `rejected → confirmed` resurrection from firing a push.
  - `REVOKE EXECUTE ... FROM public, anon, authenticated` on the trigger function — trigger machinery is the only caller (matches the lockdown pattern in `20260514000000_referrals.sql`).

**SQL test:**
- `supabase/tests/push_on_referral_confirm_test.sql` — pgtap with stubbed `net.http_post`. 15 assertions covering: function structure (exists, SECURITY DEFINER, REVOKEd), INSERT-pending no-op, INSERT-confirmed-direct no-op (S7), pending→confirmed happy path, env-bound URL from GUC (S3), referrer + referee body fields, X-Notify-Secret header from GUC (S1), confirmed→confirmed no re-fire, rejected→confirmed no fire (S4), non-status column update no fire (S7), fail-soft on unset GUC, header key spelling canary.

**Manual QA via OneSignal MCP / dashboard:**
- After triggering a real confirmation flow on the simulator, check OneSignal's Delivery dashboard for the resulting message — verify external_user_id matches the referrer.

Estimated: ~2h including the SQL test, env-var setup, and the post-/review hardening pass.

---

## Out of scope — Phase 2

- **Cancellable in-app banner** when a confirm lands during a foregrounded session (use Supabase Realtime channel on `referrals` filtered by `referrer_id`).
- **Friends list with names.** Privacy review required — show display names only if the referee has opted into being visible.
- **Reward-earned push** (separate from join push) when the referrer crosses the 3-referral threshold and `referral_grants` gets a new row. Same trigger pattern, different table.

---

## Risk + rollback

- **Risk:** new screen pulls from `referral_grants` which is a small table today (0 rows). Performance non-issue. Single round-trip parallel reads should be < 200ms p95.
- **Risk:** the share helper factor touches `refer_unlock_screen.dart` which we just shipped. Mitigation: T7 is its own commit; revertable if widget tests on ReferUnlockScreen break.
- **Rollback:** removing the Settings row + the GoRoute is sufficient to hide the surface; the service additions are read-only and inert if no caller exists.

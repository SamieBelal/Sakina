# AI Bypass via Token Spend (Halo-style consumable path)

**Date:** 2026-05-23
**Status:** Plan — pending user approval, then implementation
**Owner:** Ibrahim
**Amends:** `docs/superpowers/specs/2026-05-09-free-premium-tier-redesign-design.md` (line 83 invariant)
**Related:** `docs/decisions/monetization-model.md` (subscription-only premium), `lib/services/gating_service.dart` (current 1/day cap)

## Problem

Today's free user post-warmup hits a hard 1/day cap on Reflect / Built Dua / Discover Name. The only exit is a subscription. This loses revenue from two segments:

1. Users who refuse subscriptions but happily spend $1.99-$6.99 once on consumables (Halo AI's exact pattern — proven to lift ARPU on non-converting free users).
2. Users who see the Store screen subtitle "Use tokens for extra reflections and duas" (`store_screen.dart:378`) and buy tokens expecting that capability. Today they find tokens only buy cards. This is a soft-fraud surface.

The Store already sells token IAP (100/250/500 packs at $1.99/$3.99/$6.99) with proper grant + dedup plumbing (`ConsumableGrantsService`). The `TokenGateSheet` widget at `lib/widgets/token_gate_sheet.dart` was built for this flow and is currently orphaned dead code with zero callers.

## Goal

Add a **bounded token bypass** path that lets non-subscribers buy 1-2 extra AI uses/day per feature, while preserving the spec's anti-grind invariant: earned tokens alone must never sustain a daily bypass habit. Sustained bypass use must require IAP.

## Non-goals

- No change to subscription products (annual + weekly unchanged).
- No change to warmup budget (10/10/5 lifetime unchanged).
- No change to premium fair-use ceiling (30/day unchanged).
- No re-introduction of the deleted `tokenCostReflect` / `tokenCostBuiltDua` / `tokenCostDiscoverName` constants — those were the OLD coupling. The new bypass is a separate path with stricter bounds.
- No ad-watch, friend-invite, or other bypass mechanisms. Those invariants from the original spec stand.

## Design

### Bypass parameters

| Parameter | Value | Rationale |
|---|---|---|
| Cost per bypass | **25 tokens** | $0.50 IAP-equivalent at the cheapest pack; psychological "small extra" feel |
| Max bypasses / feature / day | **2** | Caps free user at 3 AI uses/day per feature (1 free + 2 bypasses), vs premium's 30 |
| Features covered | **reflect, built-dua, discover-name** | All three gated AI features |
| Reset | local midnight | Matches existing `daily_usage_service.dart` date-keying |
| Premium / lapsed trialer interaction | bypass path inactive when `isPremium()` (premium already uses fair-use limit); active for lapsed-trialer (`had_trial=true`) post-warmup |

### Grind-proofing math

Active free user earns ~100 tokens/week (80 from daily login + ~7 from streak + ~15 from quests, per spec line 14 and `daily_rewards_service.dart:39-81`).

Sustaining 2 bypasses/day across all 3 features:
`2 × 3 × 7 × 25 = 1,050 tokens/week required`

vs. earned: ~100/week. **Sustaining requires IAP at >10x the earn rate.** Casual grind-funded bypass (~1 bypass/feature/week) is acceptable — that's the soft funnel, not the escape hatch.

### User-facing flow

1. Free user post-warmup taps Reflect a 2nd time today.
2. Today: `DailyCapSheet` shows "Unlock unlimited" + "Maybe later." (current behavior, unchanged for users with bypass count exhausted or `tokens < 25`).
3. After this plan: same sheet shows a third button between Unlock and Maybe later:
   `"Use 25 tokens for one more (balance: 87)"` — disabled with explanatory text if `balance < 25` OR `bypassesUsedToday >= 2`.
4. Tap → **reserve-then-commit flow** (see below) → on success, sheet dismisses, original action retries automatically. On failure (race condition: someone bought a sub on another device mid-flow), surface error toast and keep sheet open.
5. After 2 bypasses today, the button shows "You've used today's bypasses. Tomorrow's reflection is on us, or unlock unlimited now." (Maybe later still available.)

### Reserve-then-commit pattern (RPC-succeeds-AI-fails resilience)

The naive design ("single RPC debits both balance and bypass counter, then call AI") loses the user's money on any AI failure between RPC commit and AI return. Real failure modes: OpenAI proxy 5xx, client network drop mid-call, app killed mid-flow. The OpenAI proxy is configured with retries but not 100%.

Three-step flow:

```
  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────────────┐
  │ reserve_bypass  │→ │ AI call          │→ │ commit_bypass(res_id)  │
  │ (atomic)        │  │ (may fail)       │  │ OR cancel_bypass(...)  │
  └─────────────────┘  └──────────────────┘  └────────────────────────┘
        │                                          │
        │ holds 25 tokens, increments bypass cnt   │ on commit: finalize
        │ creates ai_bypass_reservations row       │ on cancel: restore
        │ returns reservation_id (UUID)            │   tokens + bypass cnt
        └──────────────────────────────────────────┘
```

Three RPCs replace the single `spend_tokens_for_ai_bypass`:

- `reserve_ai_bypass(p_feature TEXT) → {ok, reservation_id, balance, bypasses_used}` — atomically debits 25 tokens, increments `{feature}_bypasses_used`, inserts row into `ai_bypass_reservations` with `status='pending'`. Same cap checks as the original single-RPC design.
- `commit_ai_bypass(p_reservation_id UUID) → {ok}` — flips reservation `status='committed'`. Idempotent. Returns ok=false if already cancelled or unknown.
- `cancel_ai_bypass(p_reservation_id UUID) → {ok, refunded_tokens, refunded_bypass_count}` — flips status to `'cancelled'`, re-credits 25 tokens to `user_profiles.tokens`, decrements `{feature}_bypasses_used`. Idempotent: a second cancel returns `ok=false`.

New table: `ai_bypass_reservations(id UUID PRIMARY KEY, user_id UUID, feature TEXT, tokens_held INT, status TEXT CHECK (status IN ('pending','committed','cancelled')), created_at TIMESTAMPTZ, finalized_at TIMESTAMPTZ)`. Indexed on `(user_id, status, created_at)` for the cleanup cron.

Orphan cleanup: a Supabase pg_cron job runs every 5 minutes, finds reservations with `status='pending' AND created_at < now() - interval '15 minutes'`, and calls `cancel_ai_bypass` on each. Covers the "app killed mid-flow, never committed or cancelled" case. The 15-minute window is generous — a normal AI call takes 5-15 seconds.

Client contract:
- `GatingService.spendBypass(feature)` returns `BypassReservation{reservationId, newBalance, bypassesUsedToday}` on success.
- Provider stores `reservationId` in local state, calls AI, then either:
  - On AI success: `GatingService.commitBypass(reservationId)` (fire-and-forget; failure here is fine, the cron will not touch committed reservations).
  - On AI failure (any exception, network drop, off-topic detection from `ai_service.dart`): `GatingService.cancelBypass(reservationId)` → on success, restore tokens to user view, show retry-or-cancel UX.
  - On app kill / process death: orphan cron cancels after 15 min.

### Daily counter semantics

Two related-but-distinct counters live in `user_daily_usage` after this change:

```
reflect_uses_today        = free_used + bypasses_consumed_today  (cap: 1 + 2 = 3)
reflect_bypasses_used     = bypasses_consumed_today only          (cap: 2)
free_remaining_today      = 1 - min(reflect_uses_today, 1)
bypasses_remaining_today  = 2 - reflect_bypasses_used
```

Same shape for `built_dua` and `discover_name`. Document this at the top of `daily_usage_service.dart` so future contributors don't conflate them.

## Scope expansions accepted in CEO review (2026-05-23)

Original plan was 3 PRs. CEO review's Selective Expansion mode added 4 expansions, reorganizing into a 5-PR rollout. Skipped expansions go to "NOT in scope" below.

### Accepted expansions

- **EXP-1: Dynamic bypass pricing.** Move `bypassTokenCost` (25) and `maxBypassesPerDayPerFeature` (2) from Dart constants to server-driven config. Use a new `app_config` table (key/value) or extend `user_profiles` with per-user overrides for A/B test cohorts. Default values match the locked plan (25 / 2). Client reads via the existing `sync_all_user_data` RPC's hydration path. **Folds into PR 1 (server) + PR 2 (client read path).**

- **EXP-2: First-bypass-free on Day-1 cap-hit.** Add `first_bypass_consumed BOOLEAN DEFAULT FALSE` column on `user_profiles`. New RPC `claim_first_bypass(p_feature TEXT)` that atomically increments bypass counter WITHOUT debiting tokens, but only succeeds if `first_bypass_consumed = false AND signup_at IS NOT NULL AND signup_at >= now() - interval '24 hours'`. After success, flips the flag. Client: `DailyCapSheet` renders a "First one's on us" variant when `firstBypassAvailable == true`. **New PR 4 (Day-1 freebie).**

  **One-shot-per-user, not per-feature (R2 eng review).** The flag is global: a user gets ONE Day-1 freebie across reflect / built-dua / discover-name combined. If they hit cap on Reflect first and use it, hitting cap on Built Dua later that day shows paid CTA, not freebie. Intentional. The Day-1 freebie's job is product discovery (demonstrate IAP path exists), not unlimited Day-1 access.

  **Null signup_at defense (R2 eng review).** `signup_at IS NOT NULL` guard prevents a corrupted-profile user from accidentally qualifying for the freebie forever. Defensive against data drift.

- **EXP-3: IAP-to-sub upsell at 6+ bypasses.** New column `user_profiles.lifetime_bypasses_purchased INT DEFAULT 0`, incremented by the existing `commit_ai_bypass` RPC (post-commit only — cancelled bypasses don't count). New sticky banner widget that renders on home screen when `lifetime_bypasses_purchased >= 6 AND !isPremium AND days_since_signup >= 7` (the 7-day floor avoids harassing brand-new heavy IAP users). Tap routes to existing paywall with new trigger string `iap_to_sub_upsell`. **New PR 5 (IAP→sub upsell).**

  **Home-screen overlay priority (R2 eng review).** Adding this banner brings the home surface to 4 competing UI layers. Documented priority table:

  ```
  PRIORITY | SURFACE                | RENDERS WHEN                       | SUPPRESSES BELOW
  1 (top)  | daily_launch_overlay   | reward unclaimed today             | YES (full modal)
  2        | level_up_overlay       | level just gained                  | YES (full modal)
  3        | billing_issue_banner   | sub payment failing                | YES (other banners)
  4        | iap_to_sub_banner      | lifetime_bypasses_purchased >= 6   | shows only if 1-3 absent
  5        | home content           | default                            | —
  ```

  Implementation: home screen reads the highest-priority active condition and renders only that surface. Two banners (3, 4) never show simultaneously. Dismissal state for the iap_to_sub banner uses `user_profiles.iap_upsell_banner_dismissed_at TIMESTAMPTZ` (CEO review's 14-day suppression already noted).

  **IAP-to-sub banner visual spec (design review):**
  - **Pattern reference:** mirror `lib/widgets/billing_issue_banner.dart` structure. Same layout shape so users learn it as a single banner pattern, not two competing surfaces.
  - **Background:** `AppColors.secondary.withValues(alpha: 0.10)` (8-12% gold tint). NOT red/orange — this is a soft upsell, not an alert.
  - **Border:** 1px `AppColors.secondary.withValues(alpha: 0.25)` bottom border only (no full outline).
  - **Height:** 52dp (matches billing_issue_banner). Sits below the safe-area inset, above home content.
  - **Copy:** "You've spent $X on bypasses. Weekly sub at $9.99 unlocks unlimited." (compute $X from `lifetime_bypasses_purchased × $0.50`, rounded down). Note: pull price string from RevenueCat via existing `purchase_service.dart` so locale-priced.
  - **Icon (leading):** `Icons.workspace_premium` in `AppColors.secondary`, 20dp.
  - **Primary tap target:** entire banner is tappable, routes to paywall with `trigger=iap_to_sub_upsell`.
  - **Dismiss affordance:** small `Icons.close` 16dp trailing, separate tap target, sets `iap_upsell_banner_dismissed_at = now()`.
  - **Animation:** slide-down fade-in 300ms on first render of the day. NOT every screen change — only once per home-visit-session.

- **EXP-4: Win-back push with token grant.** OneSignal segment: `had_trial=true AND last_seen <= now() - interval '7 days' AND last_seen >= now() - interval '60 days'` (lower bound stops infinite re-grants). New server-side scheduled function (Supabase Edge Function — pg_cron can't call OneSignal). Frequency cap: 1 win-back grant per user per 30 days. Push deep-links to home → DailyCapSheet ready-state. **New PR 6 (Win-back).**

  **Scheduling mechanism (R2 eng review):** use Supabase's native **Scheduled Edge Functions** (cron syntax in `supabase/functions/winback/config.toml`), NOT pg_cron + pg_net.http_post. Reasoning: pg_net has known footguns (408 timeouts silently dropped, requires manual `pg_net.pending_requests` monitoring). Native scheduled functions are the Layer-1 choice here. Cadence: every 6 hours. Documented as the project's first scheduled Edge Function (existing Edge Functions are webhook-driven).

  **Atomic grant + frequency cap (R2 eng review):** the Edge Function MUST wrap the grant + `last_winback_grant_at` update in a single transaction (via a new RPC `grant_winback_tokens(p_user_id UUID, p_amount INT)`). The next cron's eligibility query includes `AND (last_winback_grant_at IS NULL OR last_winback_grant_at < now() - interval '30 days')` to enforce the cap. Without atomic update, a crash between grant-success and timestamp-write triggers a re-grant on the next run.

  **Schema additions for EXP-4:**
  - `user_profiles.last_winback_grant_at TIMESTAMPTZ` — frequency cap timestamp. Set atomically with the token grant inside `grant_winback_tokens` RPC.

### Skipped expansions (NOT in scope)

- **EXP-5: Gift tokens to a friend.** Deferred. Substantial standalone feature surface; user base too small for viral loops to matter pre-10K MAU.

### Revised PR sequencing

```
  PR 1 (server core)    ─┬─→ PR 2 (client wiring)  ─┬─→ PR 4 (Day-1 freebie)
                         │                          │
                         │                          └─→ PR 5 (IAP→sub upsell)
                         │
                         └─→ PR 3 (copy + telemetry — independent, parallelizable)

  PR 6 (win-back) lands independently after PR 1 (needs the bypass tracker columns and
  earn_tokens RPC already exists). Can run in parallel with PR 4/5.
```

## Implementation — sequenced PRs

### PR 1 — server-side enforcement (foundation)

**Why first:** the client-side counter can be defeated by airplane-mode toggling; building client first then retrofitting server is worse than the opposite. Server is the source of truth from day 1.

**Files:**

- New migration: `supabase/migrations/20260523000000_ai_bypass_reservations_and_rpcs.sql`
  - `ALTER TABLE user_daily_usage ADD COLUMN reflect_bypasses_used INT DEFAULT 0;`
  - `ALTER TABLE user_daily_usage ADD COLUMN built_dua_bypasses_used INT DEFAULT 0;`
  - `ALTER TABLE user_daily_usage ADD COLUMN discover_name_bypasses_used INT DEFAULT 0;`
  - `ALTER TABLE user_profiles ADD COLUMN first_bypass_consumed BOOLEAN DEFAULT FALSE;` *(EXP-2)*
  - `ALTER TABLE user_profiles ADD COLUMN lifetime_bypasses_purchased INT DEFAULT 0;` *(EXP-3)*
  - `CREATE TABLE app_config (key TEXT PRIMARY KEY, value JSONB NOT NULL, updated_at TIMESTAMPTZ DEFAULT now());` *(EXP-1)*
  - Seed `app_config` with `('bypass_token_cost', '25')` and `('max_bypasses_per_day', '2')`. RLS: authenticated users have SELECT only; mutations require service-role (admin).
  - `CREATE TABLE ai_bypass_reservations (...)` — see Data model in Reserve-then-commit section.
  - `CREATE INDEX ai_bypass_reservations_pending_idx ON ai_bypass_reservations (status, created_at) WHERE status = 'pending';` — covers the cleanup cron's hot query.
  - RLS on `ai_bypass_reservations`: `user_id = auth.uid()` for SELECT only. INSERT/UPDATE blocked at the RLS layer — only the SECURITY DEFINER RPCs may write.
  - `CREATE FUNCTION reserve_ai_bypass(p_feature TEXT) RETURNS JSON` — atomic:
    1. `SELECT ... FOR UPDATE` on `user_profiles` row
    2. Reject `{"ok": false, "reason": "no_tokens"}` if `tokens < 25`
    3. Reject `{"ok": false, "reason": "bypass_cap"}` if `{feature}_bypasses_used >= 2`
    4. Reject `{"ok": false, "reason": "invalid_feature"}` if `p_feature` not in (`reflect`, `built_dua`, `discover_name`)
    5. `UPDATE user_profiles SET tokens = tokens - 25, total_tokens_spent = total_tokens_spent + 25`
    6. `UPDATE user_daily_usage SET {feature}_bypasses_used = bypasses_used + 1`
    7. `INSERT INTO ai_bypass_reservations (id, user_id, feature, tokens_held, status, created_at)` with `status='pending'`
    8. Return `{"ok": true, "reservation_id": uuid, "balance": N, "bypasses_used": M}`
  - `CREATE FUNCTION commit_ai_bypass(p_reservation_id UUID) RETURNS JSON` — idempotent flip `pending → committed`. Returns `{"ok": false, "reason": "not_pending"}` if reservation is already committed/cancelled/unknown.
  - `CREATE FUNCTION cancel_ai_bypass(p_reservation_id UUID) RETURNS JSON` — atomic restore:
    1. `SELECT ... FOR UPDATE` on the reservation
    2. If `status != 'pending'`, return `{"ok": false, "reason": "not_pending"}`
    3. Flip `status='cancelled'`, set `finalized_at`
    4. `UPDATE user_profiles SET tokens = tokens + 25, total_tokens_spent = total_tokens_spent - 25`
    5. `UPDATE user_daily_usage SET {feature}_bypasses_used = bypasses_used - 1`
    6. Return `{"ok": true, "refunded_tokens": 25, "balance": N}`
  - All three RPCs: pin `search_path` per `20260510000000_pin_function_search_path.sql`. Revoke `anon` execute, grant `authenticated`. SECURITY DEFINER so they can write the RLS-protected table.

- New migration: `supabase/migrations/20260523000001_ai_bypass_cleanup_cron.sql`
  - `pg_cron` job every 5 minutes:
    ```sql
    SELECT cancel_ai_bypass(id) FROM ai_bypass_reservations
    WHERE status = 'pending' AND created_at < now() - interval '15 minutes';
    ```
  - Logs each cancellation count to a `cron_run_log` table (or existing observability surface — match project convention).

- New tests: `supabase/tests/ai_bypass_rpc_test.sql`
  - `reserve_ai_bypass`: happy path debits balance, increments bypasses, returns reservation_id
  - `reserve_ai_bypass`: `no_tokens` rejection at balance=24
  - `reserve_ai_bypass`: `bypass_cap` rejection at bypasses_used=2
  - `reserve_ai_bypass`: `invalid_feature` rejection for unknown feature string
  - `reserve_ai_bypass`: concurrent calls serialize correctly via FOR UPDATE
  - `reserve_ai_bypass`: writes row to ai_bypass_reservations with status='pending'
  - `commit_ai_bypass`: pending → committed; second commit returns not_pending; nonexistent id returns not_pending
  - `cancel_ai_bypass`: pending → cancelled, refunds 25 tokens, decrements bypass counter
  - `cancel_ai_bypass`: idempotent — second cancel returns not_pending
  - `cancel_ai_bypass`: cannot cancel a committed reservation (returns not_pending)
  - Orphan cleanup: a pending reservation older than 15 min is cancelled by the cron's logic (test the SQL directly, no need to wait for cron schedule)
  - Date rollover: `{feature}_bypasses_used` is keyed on `date = CURRENT_DATE` matching existing daily_usage convention
  - RLS: anon role cannot execute any of the 3 RPCs; authenticated role can only see their own reservations via SELECT

**Why no client work yet:** PR 1 is shippable independently. Server contract locked before UI calls it.

### PR 2 — wire bypass into client gating + sheet

**Files:**

- `lib/services/gating_service.dart`:
  - Add constants: `static const int bypassTokenCost = 25;` and `static const int maxBypassesPerDayPerFeature = 2;`
  - Add `Future<int> bypassesUsedToday(GatedFeature feature)` reading `daily_usage_service`.
  - Add `Future<BypassReservation?> reserveBypass(GatedFeature feature)` that calls `reserve_ai_bypass` RPC, returns `BypassReservation{reservationId: String, newBalance: int, bypassesUsedToday: int}` on success or `null` on RPC rejection. Optimistically updates local SharedPrefs caches (tokens, bypass counter) on success.
  - Add `Future<void> commitBypass(String reservationId)` — fire-and-forget call to `commit_ai_bypass`. Errors logged, not surfaced — the orphan cron is the safety net.
  - Add `Future<bool> cancelBypass(String reservationId)` — calls `cancel_ai_bypass`. On success, refreshes local token + bypass caches from the RPC response. Returns success bool so the UI can show the right toast.
  - **Defense-in-depth:** `reserveBypass` short-circuits with null (and never hits the RPC) when `PurchaseService().isPremium() == true`. Pinned by test TEST-C below. Premium users should never reach this path — but pin it at the service layer, not just at the UI.
  - Extend `hydrateFromProfile(profile)`: also read `reflect_bypasses_used`, `built_dua_bypasses_used`, `discover_name_bypasses_used` from the profile payload and mirror to SharedPrefs. Without this, multi-device users see stale bypass-button state until the next manual refresh. The `sync_all_user_data` RPC's profile section is the canonical hydration surface — add the columns there too (one-line schema reference in the RPC, not a separate sync).
  - No change to `canUse` / `markUsed` — the bypass increments the daily counter via the same `_incrementDaily` path the normal use does, so the 2nd-attempt-today gate still kicks in for the next call. See "Daily counter semantics" diagram for the relationship.

- `lib/services/daily_usage_service.dart`:
  - Add the daily counter semantics diagram (see Design section above) as the file's top-of-file comment.
  - Add `getReflectBypassesUsedToday()`, `getBuiltDuaBypassesUsedToday()`, `getDiscoverNameBypassesUsedToday()` (read-only client cache; server is source of truth).
  - Add `incrementReflectBypassUsage()` etc. (called by `GatingService.reserveBypass` only on RPC success).
  - Add `decrementReflectBypassUsage()` etc. (called by `GatingService.cancelBypass` on rollback).

- `lib/features/paywall/widgets/daily_cap_sheet.dart`:
  - Add 3rd CTA between "Unlock unlimited" and "Maybe later":
    - Label: `"Use 25 tokens for one more (you have $balance)"`
    - Disabled when `tokenBalance < 25` OR `bypassesUsedToday >= 2` OR `isPremium == true`
    - Disabled-state copy explains why (no tokens vs. cap reached vs. premium fair-use path)
  - When `isPremium == true`, hide the bypass button entirely (don't show disabled — premium users should never see this surface anyway because of `GateReason.premiumFairUse`'s separate sheet, but defense-in-depth).
  - On tap: dispatch via the `onBypassRequested(GatedFeature feature, BuildContext sheetContext)` callback wired by the caller. The widget itself stays presentational; the provider owns the reserve→AI→commit/cancel flow.

- **DELETE `lib/widgets/token_gate_sheet.dart`** — orphaned dead widget from the pre-2026-05-09 design. The new bypass uses `DailyCapSheet`'s 3rd CTA, not a separate sheet. Same hygiene principle as the 2026-05-09 spec's deletion of `tokenCostReflect` constants (spec line 154).

- Call-site updates in three providers — each follows this exact state machine:

  ```
  ┌──────────┐  user taps    ┌────────────────────┐
  │ capped   │ ────CTA────→ │ reserving (loading) │
  │ (gate    │              └──────────┬───────────┘
  │  shown)  │              reserveBypass()
  └──────────┘                         │
                            ┌──────────┴──────────┐
                            ↓                     ↓
                    null (rejected)        BypassReservation
                            │                     │
                            ↓                     ↓
                    toast "out of tokens"   ┌─────────────┐
                    sheet stays open        │ AI in       │
                                            │ flight      │
                                            └──────┬──────┘
                                                   │
                                       ┌───────────┴────────┐
                                       ↓                    ↓
                                  AI success           AI failure
                                       │                    │
                                       ↓                    ↓
                              commitBypass(id)      cancelBypass(id)
                              (fire & forget)              │
                                       │           ┌───────┴──────┐
                                       │           ↓              ↓
                                       ↓       cancel ok      cancel failed
                                  show result   restore       (cron will rescue)
                                                tokens,        show retry CTA
                                                show retry
  ```

  Each provider stores `String? _activeBypassReservationId` in its local state during this flow.

  - `lib/features/reflect/providers/reflect_provider.dart` — extend `gateResult` handling: add `submitWithBypass(GatedFeature.reflect)` method, store reservationId, call existing `_doSubmit()`, on error path call `cancelBypass`. Clear `_activeBypassReservationId` on terminal states (committed or cancelled).
  - `lib/features/duas/providers/duas_provider.dart` — same state machine, parametrized for built_dua.
  - `lib/features/daily/providers/daily_loop_provider.dart` (discover-name path) — same state machine, parametrized for discover_name. Note: discover-name has no text input, so the "retry" CTA after a cancellation simply re-fires the muhasabah action.
  - Add inline comment in each provider: `// If a 4th gated feature is added, extract a BypassFlowMixin — three sites is the YAGNI threshold.`

- `lib/features/paywall/widgets/lapsed_trial_sheet.dart` — **unchanged.** The lapsed-trialer Day-1 sheet is the strongest sub-upsell moment and does NOT offer the bypass CTA. Add a one-line comment at the top of the file documenting this invariant.

### DailyCapSheet state matrix (design review)

Sheet renders one of 4 variants based on user state. State F (premium) never reaches this sheet — premium uses the dedicated fair-use sheet.

```
STATE  | TRIGGER                              | COPY + CTAs
-------+--------------------------------------+------------------------------------------
A      | tokens >= 25, bypasses_today < 2     | "You've reflected today" /
       |                                      | "Tomorrow's reflection is on us. Or use tokens
       |                                      |  for one more now." /
       |                                      | [Unlock unlimited] (primary, filled emerald, 56dp)
       |                                      | [Use 25 tokens (balance: N)] (secondary, outlined, 48dp, gold toll icon)
       |                                      | [Maybe later] (tertiary, text only)
-------+--------------------------------------+------------------------------------------
B      | tokens < 25, bypasses_today < 2      | Same headline + body /
       |                                      | [Unlock unlimited] (primary) /
       |                                      | [Get tokens (balance: N)] (secondary — routes to Store) /
       |                                      | [Maybe later] (tertiary)
-------+--------------------------------------+------------------------------------------
C      | bypasses_today == 2 (cap reached)    | Same headline + body /
       |                                      | [Unlock unlimited] (primary) /
       |                                      | [Maybe later] (tertiary) — bypass CTA hidden
-------+--------------------------------------+------------------------------------------
D      | signup_at >= now()-24h AND           | Headline: if name != defaultDisplayName ('Friend'):
       | first_bypass_consumed == false        |   "One more on us, {name}" (gold accent on name)
       |                                      | else:
       |                                      |   "One more on us" (no awkward 'Friend' greeting) /
       |                                      | "We saved you an extra reflection for today.
       |                                      |  Tomorrow you'll get one a day." /
       |                                      | [Reflect one more time, free] (PRIMARY, gold filled, 56dp)
       |                                      | [Maybe later] (tertiary)
       |                                      | NOTE: Unlock unlimited CTA hidden — Day-1 freebie
       |                                      | is the moment to demonstrate the bypass mechanic,
       |                                      | not push subscription. Sub upsell resumes State A
       |                                      | after the freebie is consumed.
-------+--------------------------------------+------------------------------------------
E      | Lapsed trialer Day-1                 | NOT this sheet — uses LapsedTrialSheet.
       |                                      | Days 2+: uses States A/B/C above (had_trial=true
       |                                      | path through GatingService).
-------+--------------------------------------+------------------------------------------
F      | Premium fair-use ceiling             | NEVER reaches DailyCapSheet — uses dedicated
       |                                      | premium-fair-use sheet (silent, no upsell).
```

**Loading state during bypass:** sheet stays open; primary CTA replaces text with `SakinaLoader.breathingStar()` variant inline, other CTAs disabled. Auto-dismiss on success.

**Error states:**
- RPC race (user upgraded on another device mid-flow): toast "Just upgraded to premium? Tap to refresh." with refresh-RC button. Sheet auto-closes after refresh.
- RPC succeeds, AI fails (reserve-then-commit): sheet stays open showing recovery view — "Reflection couldn't load. Your bypass is saved." with [Retry] (calls AI again with same reservation) and [Cancel & refund] (calls cancel_ai_bypass).
- Network failure on reserve: toast "Couldn't connect. Try again."

**Visual hierarchy across all states:** ONE filled CTA per sheet (the primary). All others are outlined or text-only. This preserves Krug's "what should I click?" self-evident test.

### Responsive + accessibility (design review)

**Viewport floors:**
- **iPhone SE (375×667):** sheet height with 3 CTAs (State A) measures ~340dp content + safe-area. Fits comfortably above the safe-area bottom inset. With dynamic-type at Large+, switch the secondary CTA's subtext "(balance: N)" to a 2nd line below the primary label.
- **iPhone 15 Pro Max (430×932):** sheet content stays centered; bottom safe-area padding 34dp respected.
- **iPad (>700dp width):** sheet renders centered in a max-width 480dp container, NOT full-width (matches existing `PaywallSheetScaffold` behavior).

**Touch targets (a11y):**
- Primary CTA: 56dp height × full width minus 24dp horizontal padding. Meets 44dp Apple HIG minimum.
- Secondary CTA: 48dp height. Meets minimum.
- Tertiary text CTA: 44dp tap target even though visible text height is 16dp. Use a transparent expanded tap region.
- Banner dismiss X: 44dp tap area around the 16dp icon. Critical — small X icons on mobile are an a11y anti-pattern.

**Screen reader (TalkBack / VoiceOver):**
- Sheet announces on present: "Daily reflection cap reached. Three options." (Semantics label).
- Primary CTA `Semantics(label: "Unlock unlimited reflections, subscribe")` — verb + outcome.
- Bypass CTA: `Semantics(label: "Use twenty-five tokens for one more reflection today. You have N tokens.")` — spell out the cost.
- Bypass-disabled state: `Semantics(label: "Bypass unavailable: cap reached for today")` — explain why.
- Banner: `Semantics(label: "Subscription upgrade suggestion. Tap to see plans, or tap close to dismiss.")` with separate dismiss button.

**Contrast (WCAG AA):**
- Primary CTA: white text on `AppColors.primary` (#1B6B4A) = 7.2:1 ✓
- Secondary CTA outline: `AppColors.primary` text on `AppColors.surfaceLight` (#FFFFFF) = 7.2:1 ✓
- Tertiary text: `AppColors.textSecondaryLight` (#6B7280) on background = 4.6:1 ✓ (AA at 4.5:1 minimum)
- Banner text: ensure gold-tinted background still gives ≥4.5:1 on body — use `AppColors.textPrimaryLight` (#1A1A2E), NOT the gold accent color.

**Dynamic type:**
- All copy uses `AppTypography` which respects `MediaQuery.textScaleFactor`. Sheet must `SingleChildScrollView` if content overflows at scale 1.4+ (large-text accessibility setting). Pin this with a widget test.

**Reduced motion:**
- Banner slide-in animation must respect `MediaQuery.disableAnimations` (set by iOS Reduce Motion). Fall back to instant render.

**Tests:**

- `test/services/gating_service_bypass_test.dart` (new):
  - `reserveBypass` happy path returns BypassReservation with reservation_id and decremented balance
  - `reserveBypass` when `tokens < 25` returns null with state-set reason=`no_tokens`
  - `reserveBypass` when bypasses_used >= 2 returns null with state-set reason=`bypass_cap`
  - **TEST-C (defense-in-depth):** `reserveBypass` short-circuits to null and never hits the RPC when `isPremium() == true`. Pins the invariant that premium users cannot accidentally spend tokens on bypass.
  - `commitBypass` happy path + idempotent (second commit is no-op).
  - `cancelBypass` happy path restores tokens + decrements bypass counter from local cache.
  - `cancelBypass` failure (RPC says not_pending) keeps local cache as-is; UI shows error.
  - **REGRESSION-PIN:** earned-token-only user (no IAP) sustaining 2 bypasses/day for 7 days runs out of tokens by Day 5 — pins the grind-proofing math against future earn-rate inflation.
  - Bypass count resets at local midnight (fake clock test).
  - **TEST-B:** `hydrateFromProfile` writes bypass counters from profile payload to SharedPrefs (covers multi-device drift).

- `test/features/paywall/daily_cap_sheet_bypass_button_test.dart` (new):
  - Renders bypass button enabled when balance≥25 and bypasses<2 and !isPremium
  - Renders bypass button disabled with "no tokens" copy when balance<25
  - Renders bypass button disabled with "cap reached" copy when bypasses≥2
  - Tapping bypass button invokes `onBypassRequested(feature, context)`
  - Bypass button entirely hidden when `isPremium()` (premium hits fair-use, not this sheet)

- `test/features/reflect/reflect_bypass_flow_test.dart` (new):
  - Free + capped user taps reflect → sees DailyCapSheet → taps bypass → balance debits → reflect AI call fires → commitBypass called → markUsed records the daily counter.
  - **TEST-E (failure path):** AI call throws → cancelBypass called → tokens restored → bypass counter decremented → user sees retry CTA. Pinned for OpenAI proxy 5xx behavior.
  - Cancellation RPC fails (offline) → user sees "reservation will expire in 15 min" toast; tokens stay debited until cron rescues.

- `test/features/duas/duas_bypass_flow_test.dart` (new — **TEST-A parity**):
  - Mirror of reflect_bypass_flow_test for built_dua feature. Same happy + failure paths.

- `test/features/daily/discover_name_bypass_flow_test.dart` (new — **TEST-A parity**):
  - Mirror for discover_name feature. Same happy + failure paths.

- `test/services/analytics_events_callsite_test.dart` (new — **TEST-D**):
  - `ai_bypass_offered` fires when `DailyCapSheet` builds with `feature=reflect|built_dua|discover_name`
  - `ai_bypass_purchased` fires after successful `commitBypass`, with properties matching the spec
  - `ai_bypass_rejected` fires on `null` return from `reserveBypass`, with reason from RPC

- `test/widgets/token_gate_sheet_deletion_test.dart` — N/A; PR 2 includes `git rm lib/widgets/token_gate_sheet.dart` and `git rm test/widgets/token_gate_sheet_test.dart` if one exists.

### PR 3 — store-copy honesty + telemetry

**Files:**

- `lib/features/store/screens/store_screen.dart`:
  - Update tokens-tab subtitle (line 378): `"Use tokens for extra reflections and duas."` → `"25 tokens = 1 extra reflection, dua, or name discovery. Max 2 extra per feature per day."`
  - Add a small info tooltip next to the section header explaining the bypass mechanic + how subscription beats it.

- `lib/services/analytics_events.dart`:
  - Add: `aiBypassOffered = 'ai_bypass_offered'`
  - Add: `aiBypassPurchased = 'ai_bypass_purchased'` (props: feature, token_balance_after, bypasses_used_today)
  - Add: `aiBypassRejected = 'ai_bypass_rejected'` (props: feature, reason — `no_tokens` | `bypass_cap`)

- Mixpanel funnel changes (no code, dashboard update):
  - Add Mixpanel funnel: `daily_cap_hit` → `ai_bypass_offered` → `ai_bypass_purchased` to measure bypass-CTA conversion.
  - Extend `paywall_shown` `trigger` prop list with `daily_cap_with_bypass_option` to distinguish from `daily_cap` (no-bypass variant for users with exhausted bypasses).

**Tests:**

- `test/services/analytics_events_test.dart` (extend): pin the three new event names as typed constants.

## Migration

Schema changes are additive. New columns default to 0. No backfill needed. No existing user state is invalidated. The `ConsumableGrantsService` IAP path is unchanged (still credits tokens to the same balance the bypass spends from).

## Decision — bypass cost is flat 25 tokens

**Locked: 25 tokens per bypass, flat across all 3 features.** Rejected alternative was scaled (reflect 25 / dua 25 / discover 50, weighting by warmup ratio). Rejected because:

- The 2/day cap already prevents discover-name from being over-grindable on its own.
- A uniform cost is one number in the Store copy, one number for the user to remember, one constant in code.
- Per-feature pricing creates a future maintenance burden if a 4th gated feature lands.

If post-launch Mixpanel shows discover-name bypass converting at 3x the rate of the other two (i.e. it's underpriced), revisit then.

## Acceptance criteria

- [ ] Free + capped user can spend 25 tokens to unlock one more Reflect / Dua / Discover today, up to 2 bypasses per feature per day.
- [ ] When tokens < 25, the bypass CTA is visibly disabled with explanatory copy. No silent failure.
- [ ] When bypasses_used >= 2, the CTA is disabled with cap-reached copy.
- [ ] Server RPC enforces both limits atomically; client cache rolls back on RPC failure.
- [ ] Premium users (including active trial) NEVER see the bypass CTA — they hit the silent 30/day fair-use sheet.
- [ ] Lapsed trialers (had_trial=true, not premium) DO see the bypass CTA.
- [ ] Earned-token grind sustaining 2 bypasses/day exhausts user tokens by Day 5 (pinned by regression test).
- [ ] Mixpanel events fire on each path (offered / purchased / rejected).
- [ ] Store screen subtitle now accurately describes the bypass cost + cap.
- [ ] `flutter analyze` clean.
- [ ] All new tests pass.
- [ ] Spec `2026-05-09-free-premium-tier-redesign-design.md` line 83 amendment is committed.

## Risks

- **Risk:** Bypass cannibalizes subscription conversion — users who would have subscribed instead buy a $1.99 token pack. **Mitigation:** the 2/day per-feature cap forces power users (>3 AI uses/day) into subscription. Monitor `paywall_converted` vs `ai_bypass_purchased` ratio in Mixpanel post-launch.
- **Risk:** Users feel cheated by the "max 2 per day" ceiling after paying. **Mitigation:** Store screen subtitle and sheet copy state the cap explicitly before purchase. No hidden limits.
- **Risk:** Concurrent purchases race the spend RPC. **Mitigation:** `SELECT ... FOR UPDATE` lock in the RPC plus the existing module-level `_spendTokensLock` (`token_service.dart:16`).
- **Risk:** A future contributor restores the old token-AI coupling unaware of the bounded design. **Mitigation:** the 2026-05-09 spec now points to this plan at line 83; gating_service constants document the bypass limits inline.

## Test plan summary

| Layer | New tests | Modified tests |
|---|---|---|
| SQL (Supabase) — bypass core | 13 (3 RPCs + cron + RLS + concurrency) | 0 |
| SQL (Supabase) — EXP additions | ~16 (claim_first_bypass × 6, grant_winback_tokens × 4, commit_ai_bypass extension × 3, app_config × 4) | 0 |
| Service (Dart) — bypass core | 10 | 0 |
| Service (Dart) — EXP additions | 6 (app_config fallback regression-pin, Day-1 variant gating, banner priority logic) | 0 |
| Widget | 5 (daily_cap_sheet bypass states) + 4 (Day-1 variant + iap_to_sub banner) | 0 |
| Integration | 6 (reflect + dua + discover bypass) + 3 (Day-1 freebie, IAP→sub flow, winback push) | 0 |
| Analytics | 3 (event constants + call-site test) + 4 (winback + IAP-to-sub + Day-1 variant events) | analytics_events_test extended |

**Critical regression-pins (added by R2 eng review):**
- `signup_at IS NULL` defense in `claim_first_bypass`
- Atomic grant + `last_winback_grant_at` update in `grant_winback_tokens` (prevents re-grant on crash)
- Client fallback to hardcoded `bypassTokenCost=25` / `maxBypasses=2` when `app_config` row missing

## R2 Eng Review — Architectural notes

- **`commit_ai_bypass` responsibility creep:** the RPC now does (1) flip reservation status and (2) increment `lifetime_bypasses_purchased`. Atomicity-driven, accepted. Implementer must add an inline comment in the RPC body documenting both responsibilities.
- **`claim_first_bypass` and `reserve_ai_bypass` duplication:** both lock `user_profiles`, check eligibility, mutate two tables. Different eligibility criteria. DO NOT extract a shared SQL helper — that abstraction is premature at N=2. Cross-reference comments in each RPC are sufficient.
- **`user_profiles` write amplification:** after this PR, the table has ~10 mutable counter/state columns. Acceptable at current scale. Add TODO note: "extract `user_economy_stats` table when daily writes per user exceed ~50 or Supabase shows row-lock contention."
- **Scheduled Edge Function — first of its kind in this codebase.** Existing Edge Functions (`revenuecat-webhook`) are webhook-driven. Using Supabase native Scheduled Functions (not pg_cron + pg_net). Document the pattern in `supabase/functions/README.md` if one exists, otherwise add a brief design note in the winback function's source comments.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 1 | CLEAR (SELECTIVE_EXPANSION) | 5 proposals, 4 accepted, 1 deferred. 3 critical gaps in expansion surfaces. |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 2 | CLEAR (PLAN, R2) | R1: 13 issues / R2: 6 arch + 3 code-qual + 3 test-pin findings. All applied inline. |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | CLEAR | Initial 5/10 → 9/10. 4-state copy matrix added, banner spec, full responsive + a11y. 2 decisions resolved (name fallback, banner re-trigger). |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**UNRESOLVED:** 0
**VERDICT:** CEO + ENG (R2) + DESIGN CLEARED — most-vetted feature plan in the project. State matrix, copy, responsive specs, a11y, and visual hierarchy fully spec'd. Ready to implement PR 1.

## Rollout

Single release. No feature flag — the change is purely additive to free users (subscription users unaffected). If post-launch metrics show cannibalization, the bypass cost or cap can be tuned by flipping the constants in `gating_service.dart`. If a true emergency revert is needed, set `bypassTokenCost = 999999` in a hotfix to render the CTA permanently disabled while keeping the rest of the system intact.

## What this does NOT change

- Subscription products, pricing, trial length
- Warmup budgets (10/10/5)
- Premium fair-use ceiling (30/day)
- Daily login reward amounts
- Card / scroll / collection mechanics
- Onboarding paywall
- Any AI prompt content

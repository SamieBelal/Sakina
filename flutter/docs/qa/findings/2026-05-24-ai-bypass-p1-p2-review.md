# AI-Bypass Feature — P1/P2 Findings (live-verified)

**Scope:** commits `14c800f..2eeb5cb` (PRs #20–24, the AI-bypass feature)
**Reviewed:** 2026-05-24
**Reviewer:** Claude Opus 4.7 (single-reviewer pass + security specialist subagent + live MCP repros)

## Verification methodology

- **SQL-side P1s + P2-3 + P2-5 + P2-6:** reproduced live on the production Supabase project via `mcp__supabase__execute_sql`. Test users created with deterministic `p1-repro-*@example.com` / `p1-attacker-*@example.com` patterns, then deleted (including `ai_bypass_reservations` cascade) after each repro. Zero production users affected.
- **Client-side P2-1, P2-2, P2-4:** confirmed by reading the merged source on master (commit `2c9a183`). File:line cited for every claim.
- **UI P1-4:** confirmed live on the iOS simulator (iPhone 17, build 2026-05-24). Screenshot + accessibility tree captured.

## What was already shipped (do NOT re-flag)

The P0 hotfix bundle (PR #26, merged to master as `2c9a183`) closed: P0-1 freemium guards on bypass counters, P0-2 `reserve_ai_bypass` idempotency, P0-3 `daily_usage_service._today()` UTC switch, P0-4 dispose cancels in-flight bypass, P0-5 `iap_to_sub_banner_shown` emit, P1-A `unique_violation` race, P1-B dispose-mid-reserve future cancel.

---

## P1 — Must fix before next public release

### P1-1 — `cancel_ai_bypass` lacks owner auth check **[LIVE-VERIFIED]**

- **File:** `supabase/migrations/20260523213854_ai_bypass_reservations_and_rpcs.sql:337-410`
- **Confidence:** 10/10 (live-reproduced)
- **Category:** auth / privilege escalation

**Live reproduction (2026-05-24, prod Supabase):**

Created two test users:
- Victim: `965bdc51-4eb4-471b-9e27-8538eb05faed`
- Attacker: `bd88c00c-b111-4af3-8ede-51126b2f8713`

| Step | Actor | Call | Result |
|------|-------|------|--------|
| 1 | Victim (JWT) | `reserve_ai_bypass('reflect', 'p1-1-repro-key-...')` | `{ok:true, reservation_id:bc0c507c-..., balance:175, bypasses_used:1}` |
| 2 | Pre-attack state check | — | victim balance=175, counter=1, reservation status=pending |
| 3 | **Attacker (JWT, different `auth.uid()`)** | `cancel_ai_bypass('bc0c507c-...')` | `{ok:true, refunded_tokens:25, balance:200}` ← server mutated victim's row |
| 4 | Post-attack state check | — | **victim balance=200 (refunded!), total_spent=0 (rolled back), counter=0 (decremented), reservation status=cancelled** |

The function returned `ok:true` to the attacker. The 25-token refund went to `v_owner` (the victim, not the attacker), but the attacker successfully mutated the victim's freemium-gating state across an auth boundary.

The function comment at lines 352–356 explicitly acknowledges: "We do NOT check `auth.uid()` against owner, so the cron can rescue any orphan. Defense is at the 'must be pending' check." That comment is wrong about the defense being sufficient.

**Two real exploit paths:**

1. **Self-cancel after AI delivery** (does not require obtaining another user's UUID):
   1. User reserves → 25 tokens debited, AI call fires, AI response renders into local state.
   2. User cancels their own pending reservation via direct REST call instead of letting `BypassFlowMixin.commitActiveBypassIfAny` commit.
   3. Server returns ok, refunds 25 tokens, decrements counter.
   4. User keeps the AI value. Net cost: $0. Repeatable until counter hits cap, but counter never increments past 0 because cancel decrements it.

2. **Cross-user grief** (requires obtaining victim's reservation UUID — possible if leaked via crash logs, Sentry redaction gaps, app share-sheet screenshots, or any future RLS misconfig): attacker calls cancel on victim's mid-flight reservation, denying the victim their paid bypass.

**Fix:** after the `v_owner` SELECT, before the cancel UPDATE, add:

```sql
if v_owner <> auth.uid()
   and current_user not in ('service_role', 'postgres', 'supabase_admin') then
  return jsonb_build_object('ok', false, 'reason', 'not_pending');
end if;
```

The 15-min orphan cron continues working (runs as `service_role`). `BypassFlowMixin.cancelActiveBypassIfAny` continues working (caller IS the owner). Add a regression test pinning both the cron path and the cross-user denial.

---

### P1-2 — `reserve_ai_bypass` replay path doesn't check status **[LIVE-VERIFIED]**

- **File:** `supabase/migrations/20260524111803_reserve_ai_bypass_race_fix.sql:108-122` (fast-path) and `204-213` (exception handler)
- **Confidence:** 10/10 (live-reproduced)
- **Category:** idempotency / replay attack → free bypasses

**Live reproduction (2026-05-24, prod Supabase):**

Continuing from the P1-1 repro state (victim's reservation is now `cancelled`, key `p1-1-repro-key-aaaaaaaaaaaaaaaa`, balance refunded to 200):

| Step | Call | Result |
|------|------|--------|
| 1 | Victim (JWT) re-calls `reserve_ai_bypass('reflect', 'p1-1-repro-key-aaaaaaaaaaaaaaaa')` (same key) | `{ok:true, reservation_id:bc0c507c-..., balance:200, bypasses_used:0, replayed:true}` |
| 2 | Post-call state check | **balance=200 (no debit), total_spent=0, counter=0 (no increment), reservation status=cancelled** |

The fast-path lookup at line 108 selects `id INTO v_existing_id` without checking the row's `status`. Returns ok:true for ANY existing row (`pending`, `committed`, OR `cancelled`).

The client (`lib/services/gating_service.dart:375-409`) treats every `ok:true` response as a fresh successful reservation: hydrates the token cache, increments the local bypass counter, and proceeds to fire the AI call. The flag `result['replayed']` is never inspected (see P2-1).

**Exploit loop:**
1. Reserve with key K → 25 tokens debited, AI fires, response delivered.
2. Cancel → 25 tokens refunded, counter back to 0.
3. Reserve again with key K → server returns ok:true (replay), no debit. Client fires AI again.
4. Repeat steps 2–3. Net per loop: 0 cost, 1 free bypass.

**Fix:** in both the fast-path replay and the `unique_violation` exception handler, also read `status` and route:
- `status = 'pending'` → return ok:true with replayed:true (correct double-tap behavior).
- `status = 'committed'` → return ok:false reason `already_committed`.
- `status = 'cancelled'` → return ok:false reason `replay_after_cancel`.

Pin with a regression test that reserves → cancels → replays the same key, asserting the third call fails.

---

### P1-3 — Missing freemium guards on `last_winback_grant_at` + `iap_upsell_banner_dismissed_at` **[LIVE-VERIFIED]**

> **Scope note:** the eng-review audit also surfaced `gift_premium_until` as unguarded with the same risk shape (live-reproduced setting to '2999-01-01'). Its guard rule is **deferred** because the column is defined by the Ramadan-gifts migration which lives in a separate open PR. Pulling that migration into this hotfix would mix unrelated feature code with a security PR. Tracked as a separate P1 follow-up that should land in a small PR after the Ramadan-gifts feature PR is merged. **Residual exploit on prod until then.**

- **File:** `supabase/migrations/20260524050655_extend_freemium_guards_for_bypass_fields.sql` (gap)
- **Affected columns on `user_profiles`:** `last_winback_grant_at`, `iap_upsell_banner_dismissed_at`
- **Confidence:** 10/10 (both live-reproduced)
- **Category:** freemium guard gap (same class as P0-1, missed two columns)

**Additional live reproduction for `gift_premium_until` (2026-05-24, prod Supabase):**

| Step | Actor | Call | Result |
|------|-------|------|--------|
| 1 | **Victim (JWT, `authenticated`)** | `update user_profiles set gift_premium_until = '2999-01-01 00:00:00+00' where id = auth.uid()` | **succeeds — no exception** |
| 2 | Post-state | — | `gift_premium_until = '2999-01-01 00:00:00+00'` (977 years of premium) |

**Exploit C — permanent free premium via Ramadan-gift column:** `gift_premium_until` grants premium entitlement to the user (Ramadan-gifts feature). Pushing it to 2999-01-01 yields effectively-permanent premium with no payment. Same trivial RLS-write exploit as Exploits A/B. The risk amplifier here is that this column is consulted directly by entitlement-check code paths, so the bypass is immediate (no cron tick required).

**Live reproduction (2026-05-24, prod Supabase):**

| Step | Actor | Call | Result |
|------|-------|------|--------|
| 1 | postgres | `update user_profiles set last_winback_grant_at = now(), iap_upsell_banner_dismissed_at = now() - interval '1 day' where id = '965bdc51-...'` | seed succeeds |
| 2 | **Victim (JWT, `set local role authenticated`)** | `update user_profiles set last_winback_grant_at = null where id = '965bdc51-...'` | **succeeds — no exception** |
| 3 | **Victim (JWT)** | `update user_profiles set iap_upsell_banner_dismissed_at = '2999-01-01' where id = '965bdc51-...'` | **succeeds — no exception** |
| 4 | Post-state | — | `last_winback_grant_at = NULL`, `iap_upsell_banner_dismissed_at = '2999-01-01 00:00:00+00'` |

Both writes ran as `authenticated` and committed. P0-1 extended the guard for `first_bypass_consumed` and `lifetime_bypasses_purchased` but missed these two columns added by the same `20260523213854` migration.

**Exploit A — re-trigger win-back grant:** Null `last_winback_grant_at` → next scheduled win-back cron tick selects this user (the WHERE clause treats NULL as eligible), `grant_winback_tokens`'s in-RPC 30-day check also passes on NULL. User receives another 25-token grant. Repeatable each tick. With a 25-token bypass cost, each cycle yields one free bypass.

**Exploit B — permanently suppress IAP→sub upsell:** Push `iap_upsell_banner_dismissed_at` to year 2999 → the banner suppression query treats this as "recently dismissed" indefinitely. EXP-3 funnel hides for that user forever.

**Fix:** extend `guard_user_profiles_freemium_fields` to reject user-initiated changes:

```sql
if new.last_winback_grant_at is distinct from old.last_winback_grant_at then
  raise exception 'cannot modify freemium gating field: last_winback_grant_at'
    using errcode = 'check_violation';
end if;
if new.iap_upsell_banner_dismissed_at is distinct from old.iap_upsell_banner_dismissed_at then
  raise exception 'cannot modify freemium gating field: iap_upsell_banner_dismissed_at'
    using errcode = 'check_violation';
end if;
if new.gift_premium_until is distinct from old.gift_premium_until then
  raise exception 'cannot modify freemium gating field: gift_premium_until; must go through SECURITY DEFINER RPC'
    using errcode = 'check_violation';
end if;
```

Honest paths are unaffected: `grant_winback_tokens` is `SECURITY DEFINER` owned by `postgres` (in the guard bypass list), `dismiss_iap_upsell_banner` likewise, and the Ramadan-gift grant RPC should also be `SECURITY DEFINER` owned by `postgres` — verify before merging. Pin with a regression test mirroring `freemium_guards_bypass_fields_test.sql`.

**Eng-review audit scope (2026-05-24):** all `user_profiles` columns examined. Guard-relevant columns and current state:

| Column | Guarded? | Notes |
|--------|----------|-------|
| `warmup_*_remaining` (3 cols) | ✅ | P0 lock — decrement-only |
| `had_trial` | ✅ | P0 lock — one-way latch |
| `referral_code` | ✅ | Referrals migration — immutable after assignment |
| `referral_premium_until` | ✅ | Referrals migration — RPC-only |
| `first_bypass_consumed` | ✅ | P0-1 — one-way latch |
| `lifetime_bypasses_purchased` | ✅ | P0-1 — monotonic |
| `last_winback_grant_at` | ❌ → fix here | This PR |
| `iap_upsell_banner_dismissed_at` | ❌ → fix here | This PR |
| `gift_premium_until` | ❌ → **fix here (NEW)** | This PR — surfaced by audit |

All other columns (`display_name`, `onboarding_*`, `selected_title`, `age_range`, `dua_topics`, etc.) are user-editable by design (profile/preferences) — no guard needed.

---

### P1-4 — Rating-gate forces interaction with no skip option **[LIVE-VERIFIED]**

- **File:** `lib/features/onboarding/screens/rating_gate_screen.dart:120-185`
- **Confidence:** 10/10 (live screenshot + accessibility tree)
- **Category:** App Store compliance / dark pattern

**Live UI evidence:** `docs/qa/findings/2026-05-24-p1-4-rating-gate.png` plus accessibility tree showing exactly one interactive element on the entire screen:

```json
{"AXLabel":"Send a sign","type":"Button","enabled":true,
 "AXFrame":"{{32, 759}, {338, 57}}"}
```

No back chevron, no skip button, no tap-target outside the gate. User is locked forward-only into invoking the OS rating prompt before they can advance.

**Source evidence:** the rating-gate screen build() method renders exactly ONE button:

```dart
// rating_gate_screen.dart:160-178
SizedBox(
  width: double.infinity,
  child: FilledButton(
    onPressed: _rated ? _onContinue : _onPrimary,
    ...
    child: Text(
      _rated ? 'I rated' : 'Send a sign',
      ...
    ),
  ),
),
```

There is no Skip button, no "Maybe later" button, no tap-target outside the gate that advances. The user MUST tap "Send a sign" → `InAppReview.instance.requestReview()` fires → the button flips to "I rated" → only then can they advance.

**Apple guideline 4.5.4:** "Apps must not encourage customers to use Apple's ratings and review prompts to leave specific ratings, or in exchange for compensation."

The screen frames the rating as a religious / altruistic act ("Leave a sign on the road for the next Muslim searching for the same") before the user has experienced any post-onboarding value. Apple doesn't tell the app whether the user actually rated, so the user can lie and tap "I rated" without rating. The forced-interaction failure mode (no skip path) is the risk vector.

**Fix:** add a "Maybe later" tertiary button alongside "Send a sign" that fires `AnalyticsEvents.ratingGateSkipped` and calls `widget.onNext()` directly. Keep `Env.ratingGateEnabled` kill switch. ~10 lines of code.

---

## P2 — Defensive depth

### P2-1 — Client doesn't inspect `replayed:true` flag **[CODE-VERIFIED, SEVERITY DOWNGRADED]**

- **File:** `lib/services/gating_service.dart:360-409`
- **Confidence:** 7/10 (code-evidenced; impact is theoretical in current code)
- **Category:** client/server desync (defense-in-depth)

The client passes a fresh `const Uuid().v4()` per call (line 365), so legitimate double-tap doesn't hit the replay path with the same key. The bug surfaces only in conjunction with P1-2 (replay-after-cancel) or any future code path that reuses an idempotency key (retry queue, network-retry middleware, undo/redo).

Lines 383-397 unconditionally call `tokens.hydrateTokenCache(balance: balance)` and `_incrementBypassCache(feature)` regardless of whether `result['replayed']` is true.

**Fix:** inspect `result['replayed']` after the ok-check. If true, skip `_incrementBypassCache` (the server didn't increment). Also closes the second half of the P1-2 exploit as defense in depth: even if the server fix lands, a buggy server response can't trick the client into running another AI call.

---

### P2-2 — IAP→sub upsell banner displays fabricated dollar figure **[CODE-VERIFIED]**

- **File:** `lib/widgets/iap_to_sub_upsell_banner.dart:202-206`
- **Confidence:** 9/10 (dev's own comment confirms the figure is illustrative)
- **Category:** Apple 3.1.1 / FTC endorsement rules

**Source evidence:**

```dart
// iap_to_sub_upsell_banner.dart:202-206
// $X spent: compute from lifetime count × $0.50 (the lowest token-pack
// unit price — bypass = 25 tokens ≈ $0.50 at the smallest pack). Rounded
// down per plan. This is illustrative, not a financial figure.
final dollarsSpent = (state.lifetimeBypassesPurchased * 0.5).floor();
final headline = "You've spent \$$dollarsSpent on bypasses";
```

The dev's own comment ("This is illustrative, not a financial figure") confirms the user-visible "You've spent $X on bypasses" is not derived from real transactions. Token pack pricing varies (cheap pack: ~$0.50/bypass equivalent; large pack: lower). The figure under- or over-states depending on which pack the user bought. Combined with the "Weekly sub at $X unlocks unlimited…" framing immediately below, this becomes a comparative price claim.

**Risk:** Apple 3.1.1 prohibits misleading financial framing. The repo already has a `FAKE_DO_NOT_SHIP_` tripwire script (`scripts/check_no_fake_strings.sh`) for the same class of problem.

**Fix:** compute real dollars from `user_token_purchases.amount_paid_usd` (or RevenueCat `nonSubscriptionTransactions[].amount`) aggregated server-side and surface via `sync_all_user_data`. Or drop the dollar figure and use a count: "You've used 6 bypasses." The illustrative $0.50/bypass figure is per-bypass economic exposure to the dev — not a user-facing fact.

---

### P2-3 — `app_config` has no CHECK constraints **[LIVE-VERIFIED]**

- **File:** `supabase/migrations/20260523213854_ai_bypass_reservations_and_rpcs.sql` (creates `app_config` with PK only)
- **Confidence:** 9/10 (live-verified via `pg_constraint` query)
- **Category:** operational / blast radius

**Live verification:**

```sql
select conname, contype from pg_constraint where conrelid = 'public.app_config'::regclass;
-- Result: [{"conname":"app_config_pkey","contype":"p"}]
```

Only the primary key. Current values: `bypass_token_cost=25`, `max_bypasses_per_day=2`. A service-role accidental UPDATE setting `bypass_token_cost = 0` would let every authenticated user spend zero tokens for bypasses (the `v_balance < v_cost` check at `reserve_ai_bypass:135` becomes `v_balance < 0` → false). No defense against an ops mistake or compromised service-role credential.

**Fix:**
```sql
alter table app_config add constraint app_config_bypass_cost_positive
  check (key <> 'bypass_token_cost' or (value::text)::int between 1 and 1000);
alter table app_config add constraint app_config_max_bypasses_sane
  check (key <> 'max_bypasses_per_day' or (value::text)::int between 0 and 10);
```

Or defensive clamp in `reserve_ai_bypass`: `v_cost := greatest(coalesce(v_cost, 25), 1)`.

---

### P2-4 — `dismiss_iap_upsell_banner` analytics fires before server confirms **[CODE-VERIFIED]**

- **File:** `lib/widgets/iap_to_sub_upsell_banner.dart:320-329`
- **Confidence:** 10/10 (single-line ordering bug, plain in source)
- **Category:** analytics integrity / funnel skew

**Source evidence:**

```dart
// iap_to_sub_upsell_banner.dart:320-329
Future<void> _onDismissTap() async {
  final analytics = ref.read(analyticsProvider);
  analytics.track(AnalyticsEvents.iapToSubBannerDismissed);   // ← fires BEFORE await
  final ok = await GatingService().dismissIapToSubBanner();
  if (ok && mounted) {
    ref.invalidate(iapToSubBannerStateProvider);
  }
}
```

On RPC failure (network, auth, server), the analytics event recorded a dismissal that didn't persist. The user retries → fires a second `iapToSubBannerDismissed` event for the same intent. Funnel double-counts; the 14-day re-prompt cadence model is biased.

**Fix:** move `analytics.track` after the `ok == true` check. Optionally fire a paired `iap_to_sub_banner_dismiss_failed` event on the false branch so the funnel can model retries.

---

### P2-5 — LLM reflection output persisted without server-side validation **[CODE+LIVE-VERIFIED]**

- **Files:** `lib/features/reflect/providers/reflect_provider.dart:668-712` (`_saveReflection`) + `user_reflections` schema (no CHECKs)
- **Confidence:** 8/10
- **Category:** LLM output trust boundary / prompt injection

**Source evidence:** `_saveReflection` builds a `SavedReflection` from `response.reframe`, `response.story`, `response.verses[]`, etc. with no length cap (only the preview is truncated at 150 chars). Then `insertRow('user_reflections', reflection.toSupabaseRow(userId))` writes the full payload directly.

**Live verification:**

```sql
select conname, contype from pg_constraint where conrelid = 'public.user_reflections'::regclass;
-- Result: only user_reflections_pkey (PRIMARY KEY) and user_reflections_user_id_fkey (FOREIGN KEY).
-- No CHECK constraints. No length caps. No JSON shape validation on verses[]/relatedNames[].
```

CLAUDE.md gotcha explicitly warns: "NEVER generate or fabricate Quran verses, hadith, or scholarly content." The prompt instructs the model to select from a pre-verified DB, but a prompt-injection attack via `user_text` could coax fabricated content. Sync would push the fabricated row to every device the user owns; the shareable image card would render it.

**Fix:** Postgres CHECK constraints — text fields ≤ 4KB each, `verses[]` length ≤ 8, `relatedNames[]` length ≤ 8. Trigger on `user_reflections` validating each `verses[]` element has shape `{surah: text, ayah: int, arabic: text, translation: text}`. Belt-and-braces: clamp lengths client-side in `SavedReflection.toSupabaseRow`.

---

### ~~P2-6 — `grant_winback_tokens` missing service_role grant~~ **[INVALIDATED]**

The security agent flagged this on the assumption that `proacl` would lack an explicit service_role entry. Live check via `pg_proc`:

```sql
select proname, proacl from pg_proc where proname='grant_winback_tokens' and pronamespace='public'::regnamespace;
-- proacl = "{postgres=X/postgres,service_role=X/postgres}"
```

`service_role` HAS explicit EXECUTE. Finding withdrawn.

---

## Reproduction matrix (revised)

| Finding | Live-verified? | Evidence |
|---------|---------------|----------|
| P1-1 cancel_ai_bypass auth | **YES** | 2-user repro on prod, attacker mutated victim's balance 175→200, counter 1→0, status pending→cancelled |
| P1-2 replay-after-cancel | **YES** | Same user re-reserved cancelled key, server returned `ok:true, replayed:true, balance=200 (unchanged)` |
| P1-3 missing guards | **YES** | Authenticated UPDATE on `last_winback_grant_at` (NULL), `iap_upsell_banner_dismissed_at` (2999-01-01), AND `gift_premium_until` (2999-01-01) all succeeded |
| P1-4 rating-gate no skip | **YES** (UI + code) | Screenshot at `2026-05-24-p1-4-rating-gate.png` + accessibility tree shows single "Send a sign" button, no skip |
| P2-1 client replay desync | **NO** (code) | `gating_service.dart:383-397` doesn't inspect `result['replayed']` |
| P2-2 banner $ fabrication | **NO** (code) | `iap_to_sub_upsell_banner.dart:202-206` — dev's own comment confirms "illustrative, not a financial figure" |
| P2-3 app_config CHECK | **YES** | `pg_constraint` shows only `app_config_pkey` |
| P2-4 dismiss analytics order | **NO** (code) | `iap_to_sub_upsell_banner.dart:322` fires before line 323 await |
| P2-5 LLM output validation | **YES** | `pg_constraint` shows only PK+FK on `user_reflections`; no length caps |
| ~~P2-6 grant_winback role~~ | INVALIDATED | `pg_proc.proacl` shows explicit `service_role=X/postgres` |

## Recommended fix order

1. **Bundle P1-1 + P1-2 + P1-3 + P2-3 into one SQL hotfix PR.** All four are server-side guard/auth gaps in the AI-bypass migration chain. Same shape as PR #26 hotfix bundle. Single test file (`supabase/tests/ai_bypass_p1_security_test.sql`). Pin all four exploits + the cron path. ~45 min CC time.
2. **P1-4 (rating-gate skip button)** — small UI PR. ~15 min CC time.
3. **P2-1, P2-2, P2-4, P2-5** — polish PR, bundle after P1 lands.

## Out of scope

- Drop the 1-arg `reserve_ai_bypass` shim — blocked by 60+ days of IPA drain telemetry (tracked in `flutter/TODOS.md`).
- Daily-loop `_todayKey` local-time bug — pre-existing from commit `8d135808`, tracked in `flutter/TODO.md`.
- Paywall 3-second `IgnorePointer` on close X — initially flagged P1 (Apple 3.1.2 / 4.0 dark-pattern risk), removed 2026-05-24 after live verification + product call: industry-standard pattern (Cal AI, Hallow, Glorify all ship similar 1-5s delays), no actual data points of Sakina or peer apps being rejected for this, 3s is too short to feel coercive, the exit-offer sheet provides a clear non-forced dismiss path. Not a release-blocker.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR (PLAN) | 1 issue (DRY helper), 0 critical gaps, 17 test paths planned, audit surfaced new column `gift_premium_until` |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**UNRESOLVED:** 0
**VERDICT:** ENG CLEARED — ready to implement the P1 security hotfix bundle (4 fixes + helper + audit-found `gift_premium_until` guard) plus the P1-4 UI PR in parallel worktrees.

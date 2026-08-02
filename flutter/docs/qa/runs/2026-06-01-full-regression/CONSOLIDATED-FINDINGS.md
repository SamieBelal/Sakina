# Consolidated Findings — Full Regression (2026-06-01)

Single register of every issue found in the post-`14c800f` regression (60 commits, 11 feature clusters),
with **reproduction steps** for each. Living document — backend/security findings are confirmed; lane
(UI) findings are appended as each parallel simulator agent (A/C/D/E, then B) completes.

**Sources:** Gate 0 (`gate-0.md`), security sweep (`security-sweep.md`), lane run logs (`lane-*.md`),
individual finding files (`docs/qa/findings/2026-06-01-*.md`).

## Summary table

| ID | Severity | Component | Title | Status | Detail file |
|----|----------|-----------|-------|--------|-------------|
| F-01 | 🔴 P1 / High | ✅ **RESOLVED** | `get_eligible_notification_users` anon enumeration — REVOKEd from PUBLIC, granted service_role, verified, regression test added | `findings/2026-06-01-notif-eligibility-anon-enumeration.md` |
| F-02 | 🟡 Low | Backend / Perf | `cancellation_feedback` RLS skips `(select auth.uid())` initplan opt | Open | `findings/2026-06-01-cancellation-feedback-rls-initplan.md` |
| F-03 | ⚙️ Process (High) | Test hygiene | Lane D used operator's account as referrer → prod contamination | **Cleanup pending operator OK** | `findings/2026-06-01-lane-d-wrong-referrer-account.md` |
| F-04 | ⚪ Resolved/Tooling | Analytics | Mixpanel: only `Get-Events` (Lexicon) is gated — `Run-Query` works; analytics VERIFIED flowing | Resolved | this file |
| F-05 | 🔵 P3 | UI / Tour | "Skip tour" tap target ~18pt tall, 2pt h-padding (< 44pt min) | Open | `findings/2026-06-01-guided-tour-skip-tap-target-narrow.md` |
| F-06 | 🟠 Medium | UI / Tour | Tour step 13 celebratory banner not shown when landing on a SAVED-catalog-dua journal detail (route mismatch) | Open | `findings/2026-06-01-tour-step13-saved-dua-no-banner.md` |
| F-07 | 🔵 Polish | ✅ **RESOLVED** | Name-input layout fixed — input now hugs the prompt (leading `Spacer` → fixed gap; flexible space moved below the field). Widget test + sim-verified (branch `qa-f07-nameinput-bypass-hygiene`) | Lane A log |
| F-08 | 🟠 Medium | Analytics | `paywall_flow_*` events defined but never wired (0 call sites, 0 events) | Open | `findings/2026-06-01-paywall-flow-events-not-wired.md` |
| F-09 | 🔵 Low | Migrations | `20260525000001_drop_unused_onboarding_columns` not applied to prod (dead columns remain) | Confirmed | Lane B log |
| F-10 | 🟠 Medium | UI / Tour | `tour_anchor_timeout` fires ~31% of tour starts (anchor resolution reliability) | Open | `findings/2026-06-01-tour-anchor-timeout-rate-high.md` |
| F-11 | 🔴 P0 (analytics) | Retention instrumentation | Core retention engine largely un-instrumented (subscription lifecycle, daily loop, notifications, store, collection = 0 analytics) | Open | `retention-audit/RETENTION-COVERAGE-SUMMARY.md` |

Counts so far: **1 P1 · 1 Low · 1 Medium · 2 P3/Polish · 2 resolved**. Lanes done: **A 50P/0F/1B · C 12P/0F/1B · D 23P/1F/13B · E 11P/1partial/0F**. **0 release-blocking product bugs.**

---

## F-01 🔴 P1 — `get_eligible_notification_users` anon enumeration / PII exposure

- **Component:** Supabase RPC `public.get_eligible_notification_users(...)`
- **Impact:** An unauthenticated caller with only the public anon key can enumerate push-enabled users and
  harvest `user_id`, `display_name`, `timezone`, `current_streak`, `last_active`.
- **Root cause:** `SECURITY DEFINER` function with **anon EXECUTE granted** and **no `auth.uid()` guard** in
  the body. Re-introduced after `20260509000000_revoke_anon_rpc_execute` (likely via a later `CREATE OR
  REPLACE` and/or `20260531200000_reconcile_anon_rpc_grants`).

### How to reproduce
**A. Confirm the grant (read-only, safe) — Supabase MCP / psql:**
```sql
select has_function_privilege(
  'anon',
  'public.get_eligible_notification_users(text,text,integer,boolean,integer,integer,boolean)',
  'EXECUTE');   -- returns TRUE  ← the bug
```
**B. Confirm no identity guard:**
```sql
select pg_get_functiondef(
  'public.get_eligible_notification_users(text,text,integer,boolean,integer,integer,boolean)'::regprocedure);
-- body has NO `auth.uid()` check; returns user_id, display_name, timezone, streak, last_active
```
**C. Live exploitation (do NOT run against prod with real data — illustrative only).** From any client
holding just the public `SUPABASE_ANON_KEY`:
```bash
curl -s "$SUPABASE_URL/rest/v1/rpc/get_eligible_notification_users" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"p_pref_column":"notify_daily","p_sent_column":"last_daily_sent_at","p_target_hour":9}'
# Iterate p_target_hour 0..23 → enumerates the push-enabled user base.
```
- **Expected:** anon cannot call it; only the `send-scheduled-notifications` edge fn (service_role) may.
- **Actual:** anon call returns rows of user PII.

### Fix (safe — only caller is service_role, which bypasses grants)
```sql
revoke execute on function public.get_eligible_notification_users(
  text, text, integer, boolean, integer, integer, boolean
) from anon, authenticated;
-- defense-in-depth: add `if auth.role() <> 'service_role' then raise exception ...` at top of body.
```
**Verify:** re-run repro step A → expect `false`; confirm `send-scheduled-notifications` still dispatches; re-run `get_advisors security`.

---

## F-02 🟡 Low — `cancellation_feedback` RLS skips initplan optimization

- **Component:** RLS policies on `public.cancellation_feedback` (migration `20260531000000_create_cancellation_feedback.sql`)
- **Impact:** Per-row re-evaluation of `auth.uid()` → suboptimal at scale. No correctness/security impact.
- **Root cause:** Policies use bare `auth.uid() = user_id`; the rest of the schema moved to
  `(select auth.uid())` in `20260510172453_rls_initplan_optimization`. New table regressed the convention.

### How to reproduce
```sql
-- Advisor flags it:
select * from (select 1) t;  -- via Supabase MCP: get_advisors('performance') → lint auth_rls_initplan on cancellation_feedback (x3)
-- Source confirmation:
--   supabase/migrations/20260531000000_create_cancellation_feedback.sql
--   lines 58 / 65 / 72-73 use `auth.uid() = user_id` (not `(select auth.uid())`)
```
- **Expected:** `(select auth.uid()) = user_id` (cached once per query).
- **Actual:** `auth.uid() = user_id` (re-evaluated per row).

### Fix
New migration replacing each occurrence with `(select auth.uid())` in all three policies. Behavior identical.

---

## Analytics layer — CENTRAL verification (orchestrator, via Mixpanel `Run-Query`, project 4013350)

Done centrally because Lane D finished before we knew `Run-Query` works. **Every real new event is firing** (30-day totals):

| Event | Count | Event | Count |
|-------|-------|-------|-------|
| tour_started / tour_completed | 67 / 13 | tour_step_viewed / advanced | 317 / 257 |
| tour_skipped | 15 | tour_anchor_timeout | 22 ⚠️ |
| refer_unlock_shown / share_tapped / start_trial / back | 7 / 7 / 6 / 4 | my_referrals_shown / share_tapped | 10 / 1 |
| referral_settings_redeem_opened | 7 | referral_field_revealed | 2 |
| referee_signed_up_with_referral | 1 | ramadan_gift_shown / claimed | 3 / 1 |
| ai_bypass_offered / purchased / rejected | 4 / 1 / 1 | first_bypass_offered / claimed | 1 / 2 |
| iap_to_sub_banner_shown / tapped / dismissed | 3 / 6 / 3 | cancellation_feedback_shown / submitted / dismissed | 10 / 2 / 4 |

**Verdict: analytics layer PASS.** Notes:
- **Not events (property values) — correctly 0 as event names:** `onboarding_field`, `paywall_flow_loader`, `rating_gate` (page/source values); `bypass_cap`, `no_tokens` (= `reason` property on `ai_bypass_rejected`). Verify these via breakdowns of their parent event, not as events. (Plan's event list conflated them.)
- **Real events at 0 (coverage gaps, not bugs):** `my_referrals_code_copied` (wired at `my_referrals_screen.dart:110`, copy action not exercised) · `onboarding_abandoned_at_page` (testers complete onboarding — **Lane B** will fire it) · `ramadan_gift_window_expired` (no expired-window attempt — expected).
- ⚠️ **`tour_anchor_timeout` = 22** over 30d — a *designed* graceful fallback (fires when an anchor can't be located in time), not a crash, but the volume is worth a glance: the tour occasionally can't find its target. **Lane A** to characterize whether it's flaky anchors vs. expected.

## Lane (UI) findings — appended as agents complete

> Lanes A (onboarding+paywall+tour), C (AI-bypass), D (referrals+gift), E (core loop) are running in
> parallel on dedicated simulators; Lane B (legacy onboarding) runs after. Each agent files individual
> `docs/qa/findings/2026-06-01-<slug>.md` files and records PASS/FAIL/BLOCKED in its `lane-*.md` log.
> Confirmed UI bugs will be merged into the summary table above with reproduction steps.

### Lane B — legacy onboarding / kill-switches OFF (COMPLETE: 8 PASS / 0 FAIL / 1 BLOCKED) — flags reverted to true
**Passed clean:** kill switches work (`onboarding_trim_enabled=false` → legacy **26-page** flow with 6 legacy-only screens: QuranConnection, CommonEmotions, Aspirations, StruggleSupportInterstitial, ValueProp, Encouragement; `guided_tour_enabled=false` → **no tour** on first Home + cold relaunch) · rating gate correctly **absent** (RATING_GATE_ENABLED=false → YourJourney p24 → Paywall p25; `rating_gate_skipped` fires) · no overflow · no RTL bleed · `user_profiles` written correctly (all 12 legacy fields) · social-auth buttons present at p18 (OAuth execution blocked on sim).
**Blocked / key insight:** `onboarding_abandoned_at_page` requires a **24h+ background gap** (delayed re-engagement signal, NOT immediate drop-off) — impossible to exercise in a QA session without time mocking; logic is unit-tested (`abandonment_telemetry_test.dart`). → **Recommend a `debugAbandonmentThreshold` seam.** Immediate per-step drop-off is instead **derived from the step funnel** (works, given `step_index`).

#### F-09 🔵 Low — migration drift (CONFIRMED): `20260525000001_drop_unused_onboarding_columns` not applied to prod
- Verified: `schema_migrations` has no `20260525000001`; the 3 columns it should drop (`onboarding_quran_connection`, `common_emotions`, `aspirations`) still exist in prod `user_profiles`. Benign dead weight, but it's repo↔prod migration-state drift (relevant to the clean-reset concern, cluster #10). Apply the migration or reconcile.

### Lane A — onboarding(trim) + paywall + tour (COMPLETE: 50 PASS / 0 FAIL / 1 BLOCKED) — 1 Medium + 1 polish
**Passed clean:** trimmed 20-page onboarding all screens render/navigate, **no keyboard overflow, zero RTL bleed** · `user_profiles` fully populated by `saveOnboardingData` (display_name, intention, familiarity, attribution, age_range, prayer_frequency, dua_topics, daily_commitment_minutes, reminder_time, commitment_accepted, starter_name_id, referral_code) · paywall flow (loader auto-advance, personalized plan, rating gate present, annual+weekly pricing, progress bar hidden) with skip route documented · **guided tour 12/13 steps** verified (personalized banner, gold-ring anchors, blocking-route + Build-a-Dua suppression, no-refire, seen-flag persisted) · analytics observed (tour_started/step_viewed/step_advanced/completed, onboarding_completed, paywall_viewed, rating_gate_shown).
**Blocked (tooling, not product):** iOS 26 native notification permission dialog (system `UIAlertController`) isn't tappable via MCP `ui_tap`; worked around with `idb approve notification` (side-effect: app restart). → coverage-gap note.

#### F-06 🟠 Medium — Tour step 13 final banner missing on saved-catalog-dua detail
- When the user reaches the tour's final step on a **saved catalog dua** (heart-saved from Related Duas) journal detail, the celebratory centered banner doesn't render — tour completes internally (seen flag set) but no banner. Likely route mismatch: tour expects `DuaDetailPage` (personal built dua), not the saved-catalog-dua view. Detail: `findings/2026-06-01-tour-step13-saved-dua-no-banner.md`. Worth fixing (last impression of the tour) but not a blocker.

#### F-07 🔵 Polish — Trimmed name-input screen sparse upper area — ✅ RESOLVED (2026-06-02)
- Page-2 name input showed a large blank area up top. Root cause: a leading `Spacer()` before the text field shoved the input toward the bottom, leaving the gap between the subtitle and the field. Fix (`name_input_screen.dart`): the input now sits directly beneath the prompt (fixed `AppSpacing.xl` gap) and the flexible `Spacer()` moved below the field, so the Continue button still anchors to the bottom. Pinned by `test/features/onboarding/screens/name_input_screen_test.dart` (asserts the flexible space is below the input, not above) and sim-verified on iPhone 16. Shipped on branch `qa-f07-nameinput-bypass-hygiene`.

### Lane C — AI bypass economy (COMPLETE: 12 PASS / 0 FAIL / 1 BLOCKED) — 1 P3 bug
**Passed clean:** Day-1 freebie STATE D (`first_bypass_consumed` flip, events fired) · token bypass accept (25-token debit 155→130, `ai_bypass_reservations` row w/ UUID idempotency key, reservation→committed, `lifetime_bypasses_purchased`++) · reject (no charge) · no-tokens STATE B (disabled CTA + "need 25" copy) · bypass cap STATE C (3rd blocked, no charge) · **all freemium guards** reject authenticated direct writes (reflect_bypasses_used, first_bypass_consumed, lifetime_bypasses_purchased, gift_premium_until) while service_role succeeds · **idempotency** (`replayed:true`, same reservation_id, single debit) · **premium short-circuit** (premium user → AI fires immediately, `reserveBypass` NEVER called — the key CLAUDE.md invariant) · `user_reflections` length caps (5000-char + 15-verse rejected, valid 1-verse ok).
**Blocked:** TC-7 IAP→sub upsell banner — correctly NOT shown (threshold = 6 paid bypasses, account < 7d); full flow needs 6+ committed paid bypasses via real StoreKit → **Lane P scope**.

#### F-05 🔵 P3 — "Skip tour" tap target too small
- Coachmark "Skip tour" control is ~18pt tall with 2pt horizontal padding (< the 44pt min touch target). Hard to hit via automation; an accessibility/usability nit on device. Recommend ≥44pt. Detail: `findings/2026-06-01-guided-tour-skip-tap-target-narrow.md`. Not a release blocker.

### Lane E — core loop + Settings + notifications (COMPLETE: 11 PASS / 1 PARTIAL / 0 FAIL / 0 BLOCKED) — no bugs
**Passed clean:** Settings "Replay tour" re-fires immediately without restart (regression da01c47 ✓, `tour_replay_tapped=2` via Mixpanel) · no cold-launch "Open Settings" nag (5b07d16 ✓) · Home "Begin Muḥāsabah" discover path (`q1='discover'`, q2/q3 empty, q4 null, name `Al-Muakhkhir`, share-worthy card, no RTL bleed) · economy consistency (`user_tokens.balance`, streak, `tier_up_scrolls` all match UI, only `sync_all_user_data` writes) · **iPhone SE overflow scan CLEAN** across Home/Collection/Reflect/Duas/Journal/Store/Settings/gacha/result/delete-dialog (56 screenshots).
**Partial / residual gap:** `DailyLaunchOverlay` 4-question `answerCheckin()` path not walked e2e — the account already had a same-day discover check-in, so the overlay short-circuited. Path is unit-tested; needs a fresh account on a clean day for full e2e (candidate for a targeted re-test or Lane A's fresh account).

### Lane D — referrals + Sakina gift (COMPLETE: 23 PASS / 1 FAIL / 13 BLOCKED)
**Passed clean:** Sakina-gift backend (happy/idempotent/outside-window/unknown-occasion/auth-mismatch/RLS-isolation/`greatest()` coalesce all ✓), gift UI render (Arabic "رمضان مبارك", no RTL bleed) + claim + `sakina_gifts` row + `gift_premium_until` mirror, My Referrals screen + share sheet, Settings redeem sheet, validation guards (invalid code soft-fail, self-referral excluded, no spurious rows), referral backend mechanics (`apply_referral` 7d mutual, 3-confirm→30d+Gold, `push_on_referral_confirm`→OneSignal delivered, threshold counting), no mawlid rows, freemium guard covers `gift_premium_until`.
**Blocked:** Refer-to-Unlock screen cases D-B1–B4 (needs fresh-onboarding paywall dismissal; sim had an established session → push to Lane P or wipe sim); all Mixpanel verification (see F-04).

#### F-03 ⚙️ Process (High) — Lane D contaminated the operator's production account
- **What:** Instead of creating its own `sakinaqa.d.referrer` account through the app, Lane D read the referral code `68U5QNQX` from the signed-in sim user (the operator's account `sakina.tour.qa@gmail.com`, uid `f7eb9cb3…`) and **SQL-injected 3 fake referee accounts** (`aaaaaaaa-d001-…001/002/003`) directly into `auth.users`, then ran the referral flow against the operator.
- **Production side-effects on `sakina.tour.qa@gmail.com`:** `referral_premium_until=2026-07-01` (30d), a Gold card in `user_card_collection`, 3 confirmed `referrals` + 1 `referral_grants` row, plus `gift_premium_until` + a `sakina_gifts` row from the gift test. Also seeded `qa_test_active_d`/`qa_test_past_d` into `islamic_occasions`. **3 real pushes** sent to the operator's devices.
- **Not a product bug** — the underlying referral/gift mechanics were all CORRECT (that's why it worked). It's an agent test-hygiene violation + a reminder that lane agents hold privileged (service_role) Supabase access via MCP.
- **Repro / cleanup SQL:** in `findings/2026-06-01-lane-d-wrong-referrer-account.md`. **Awaiting operator OK before running.**
- **Prevention:** AGENT-PROTOCOL now must enforce "create + verify your own account before reading any user-scoped data"; consider giving lane agents a least-privilege DB role rather than service_role.

#### F-04 ⚪ RESOLVED — Mixpanel analytics ARE verifiable (Lane D mis-diagnosed)
- Lane D hit permission-denied on the **`Get-Events`** tool (Lexicon/metadata endpoint — that one IS gated for this service account). But the **`Run-Query`** analytics tool works fine. Project = **Sakina (4013350)**, workspace 4509390.
- **Live verification (orchestrator, via Run-Query):** every real new event is flowing — `tour_started` 67 / `tour_completed` 13, `refer_unlock_shown` 7, `ai_bypass_offered` 4, `ramadan_gift_shown` 3, `cancellation_feedback_shown` 10, `iap_to_sub_banner_shown` 3, `first_bypass_offered` 1, `referee_signed_up_with_referral` 1 (last 7–30d).
- **Plan correction:** `onboarding_field`, `paywall_flow_loader`, `rating_gate` are NOT events — they're property VALUES (`referralSourceOnboardingField='onboarding_field'`; page-name map entries 22→`paywall_flow_loader`, 25→`rating_gate`). Querying them as event names correctly returns 0. The plan's analytics list conflated these property-values with events; treat them as properties on their parent events.
- **One real event at 0:** `onboarding_abandoned_at_page` (a genuine event, wired at `onboarding_screen.dart:187`) — 0 over 30d because testers complete onboarding rather than abandon. **Lane B** is tasked to trigger it; verify there.
- Lanes use `Run-Query` (project 4013350) for analytics going forward.

---

## Still-unrun gates (not findings, but block full sign-off)
- **pgtap suite** (`scripts/run_sql_tests.sh`) — needs `DATABASE_URL` (branch/local stack).
- **`supabase db reset`** clean-reset validation (cluster #10 migration guards) — needs branch/local stack.
- **Lane P** (physical device) — StoreKit purchase/cancel/restore, real cancellation-survey trigger, push receipt.

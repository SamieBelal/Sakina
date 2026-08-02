# Full Regression — Parallel Simulator Test Plan (2026-06-01)

Master orchestration plan for regression-testing **everything merged since `14c800f`** (60 commits,
241 files, ~36k insertions, 2026-05-14 → 2026-06-01). Drives **5 iOS simulators in parallel via the
`ios-simulator` MCP (UDID-pinned)** + **1 physical device** for StoreKit/push-receipt flows.

> **This is the orchestration layer.** It does not re-document per-feature steps that already exist —
> it points at them and fills the gaps. Pairs with `docs/manual-test-plan.md` (execution + MCP assertions)
> and `docs/testing-plan.md` (coverage by layer). Log results under `docs/qa/runs/2026-06-01-full-regression/`
> and file bugs under `docs/qa/findings/`.

---

## 0. What changed (test surface)

| # | Cluster | Key commits / PRs | New backend | New analytics | Push? | Existing plan |
|---|---------|-------------------|-------------|---------------|-------|----------------|
| 1 | **AI bypass** (token spend, day-1 freebie STATE D, IAP→sub upsell banner) | #20–#27 | `ai_bypass_reservations`, `reserve_ai_bypass` RPC, `sync_all_user_data` bypass counters, freemium guards | `ai_bypass_offered/purchased/rejected`, `bypass_cap`, `no_tokens`, `already_consumed`, `invalid_feature`, `first_bypass_offered/claimed/rejected`, `iap_to_sub_banner_shown/tapped/dismissed/dismiss_failed` | — | — (gap) |
| 2 | **Guided tour / coachmarks** | #31 (abe4be8, 832e12d, 2461c94, 8531278, e443280…) | `app_config.guided_tour_enabled` | `tour_started/skipped/start_skipped/step_viewed/step_advanced/completed/replay_tapped/anchor_timeout` | — | `docs/qa/plans/2026-05-31-guided-tour-sim-test-plan.md` |
| 3 | **Onboarding trim 27→20 + dual-flow** | d2ab75a, a71afcc, f0d9bd8, 3c3e36f | `app_config.onboarding_trim_enabled`, dropped onboarding columns | `onboarding_abandoned_at_page`, `onboarding_field` | — | — (gap) |
| 4 | **Paywall rebuild** | #15 (df5f9d5), 80475c6 | — | `paywall_flow_loader/plan`, `rating_gate`, `rating_gate_skipped` | — | `docs/superpowers/plans/2026-05-14-paywall-rebuild.md` |
| 5 | **Refer-to-unlock + My Referrals** | #16 (a3e1f01) | `referrals`, `referral_validate`/`apply_referral` RPCs, `push_on_referral_confirm`, `notify-referral-confirmed` edge fn, `user_profiles.referral_premium_until` | `refer_unlock_*`, `referee_signed_up_with_referral`, `referral_field_*`, `referral_settings_redeem_*`, `my_referrals_*`, `settings_redeem` | ✅ confirm push | `docs/qa/2026-05-23-refer-unlock-device-test-plan.md`, `docs/superpowers/plans/2026-05-23-my-referrals-screen.md` |
| 6 | **Ramadan / Eid gift** | #17 (7767ad6), 7055da0 | `ramadan_gifts`, `claim_sakina_gift` RPC, `islamic_occasions`, `user_profiles.gift_premium_until` | `ramadan_gift_shown/claimed/window_expired` | — | `docs/qa/plans/2026-05-25-ramadan-gift-manual-qa.md` |
| 7 | **Cancellation feedback survey** | #32 (7daf3d6, 62581cc, d540099, a1400da, 89c795a) | `cancellation_feedback`, `user_subscription_cancellation_transition`, `revenuecat-webhook` push | `cancellation_feedback_shown/dismissed/submitted` | ✅ webhook push (sandbox-gated) | `docs/decisions/…` spec |
| 8 | **Notification nag-loop fix** | 5b07d16 | — | `notifications` | — | — |
| 9 | **Freemium guard hardening** | 7055da0, 350a137, 524…bundles | guard triggers on `gift_premium_until`, `referral_premium_until`, bypass fields | — | — | — |
| 10 | **Migration safety (clean DB reset)** | b6b2dd3, 4462c32, 419af95, 059e72b, 6402952, 31162ef | guarded policy/cron blocks, anon RPC grant reconcile | — | — | cross-cutting |
| 11 | **Core-loop / economy regressions** (sync schema fixes, consumable clawback, starter name, UTC daily loop) | 20260427…, 20260429…, ac2dece | `consumable_clawback`, `starter_name_id`, UTC `sync_all_user_data` | — | — | `docs/qa/runs/2026-04-22-core-loop.md` |

**Kill switches & flags (set per lane — this is the crux of dual-flow coverage):**

| Flag | Where | Default | Controls |
|------|-------|---------|----------|
| `onboarding_trim_enabled` | `app_config` table (anon-readable) | `true` | 20-screen trimmed vs 27-screen legacy onboarding |
| `guided_tour_enabled` | `app_config` table | `true` | First-visit coachmark tour on/off |
| `RATING_GATE_ENABLED` | `env.json` (compile-time) | `true` | Rating gate page in paywall flow (27 vs 26 onboarding pages) |
| `PAYWALL_ANIMATIONS_ENABLED` | `env.json` | `true` | Paywall motion |
| `PAYWALL_HONEST_BILLING_ENABLED` | `env.json` | `true` | Honest-billing copy structural change |
| `RAMADAN_GIFT_ENABLED` | `env.json` | `true` (absent in current `env.json` → verify) | Gift card render |

---

## 1. MCP tooling matrix — which server verifies which layer

| Layer | MCP server | Used for |
|-------|-----------|----------|
| **UI drive + screenshots** | `ios-simulator` (`launch_app`, `ui_tap`, `ui_type`, `ui_swipe`, `ui_describe_all`, `screenshot` — **all accept `udid`**) | Every lane. Pin each lane to its UDID. |
| **Backend state** | `supabase` (`execute_sql`, `get_logs`, `get_advisors`, `list_migrations`) | Verify table rows, RPC effects, RLS, freemium guards, migration state |
| **Analytics** | `mixpanel` (`Run-Query`, `Get-Events`, `Get-Property-Values`) — call `Get-Business-Context` FIRST | Confirm each event fired with correct props; verify `onboarding_funnel.json` funnel |
| **Push** | `onesignal` (`view_messages`, `view_message_history`, `view_outcomes`) | Confirm referral-confirm + cancellation pushes were *sent* |
| **Billing** | `revenuecat` (`get-customer`, `list-subscriptions`, `list-purchases`) + `asc-mcp sandbox_*` | Entitlement state after sandbox purchase/cancel; clear sandbox purchase history between runs |

> **`sips -Z 1600` every simulator screenshot immediately after capture** (per CLAUDE.md) — native @3x trips the image cap.

---

## 2. Hard constraints (read before assigning lanes)

1. **StoreKit purchases need a physical device.** Simulators can render the paywall and the IAP→sub /
   cancellation UIs, but cannot complete a RevenueCat purchase. So **anything that requires a *real
   entitlement transition*** — onboarding paywall purchase, IAP→sub upsell *purchase*, subscription
   *cancellation* (and therefore the cancellation-feedback survey's real trigger), restore, and
   `revenuecat-webhook` `is_premium` flips — runs on the **physical device lane (P)**. On simulators,
   grant premium via the **non-RC paths** (`referral_premium_until` / `gift_premium_until` SECURITY-DEFINER
   RPCs) to exercise premium-gated UI.
2. **AI-bypass token spend is NOT StoreKit** — it's the `reserve_ai_bypass` economy RPC. Fully testable on simulator.
3. **Push *receipt* needs a real device** (APNs). Simulators verify push *logic* (scheduling rows,
   edge-fn invocation) and we confirm *send* via OneSignal MCP; actual banner receipt → device lane P.
4. **Cancellation-feedback push is sandbox-gated pre-launch** (89c795a) — only fires for sandbox
   subscriptions. Verify the gate, not production delivery.
5. **Mixpanel ingestion latency** — allow 1–3 min before `Run-Query`; use `timeEvent`-aware funnels.
6. **Each lane uses its own test account** (distinct email) so DB writes never collide across parallel sims.
7. **MCP drives one tap at a time per UDID** — lanes are parallel at the *flow* level, but a single
   Claude session issues serialized tool calls. Run lanes as **background agents / separate sessions**,
   or interleave (boot+build+seed all in parallel, then walk lanes round-robin).

---

## 3. Pre-flight (do once, mostly parallel)

```bash
# 3.1 Static gates (must be green before any device work)
flutter analyze            # expect ~18 baseline infos, 0 errors
flutter test               # full unit/provider/widget suite (covers dual-flow, tour, bypass, banners)
./scripts/check_no_fake_strings.sh   # fabricated-content tripwire

# 3.2 Backend gates
./scripts/run_sql_tests.sh           # pgtap (12 changed test files in supabase/tests)
#   + Supabase MCP: get_advisors (security+performance), list_migrations (all 43 new applied)

# 3.3 Clean-reset safety (cluster #10) — on a throwaway Supabase branch or local stack:
supabase db reset          # must succeed end-to-end (guards in b6b2dd3/4462c32/419af95)
```

**Build matrix** — two binaries differ only by `env.json` flags (app_config flags are flipped live via SQL):

| Build | env.json overrides | Lanes |
|-------|--------------------|-------|
| `build-default` | all flags `true` (shipping config) | A, C, D, E, P |
| `build-legacy`  | `RATING_GATE_ENABLED=false` (+ flip `onboarding_trim_enabled`/`guided_tour_enabled` to `false` via SQL) | B |

```bash
# Boot + install per lane (run boots in parallel)
xcrun simctl boot <UDID> ; xcrun simctl install <UDID> build/ios/iphonesimulator/Runner.app
# Bundle id: grep PRODUCT_BUNDLE_IDENTIFIER ios/Runner.xcodeproj/project.pbxproj | head -1
```

**Suggested UDID assignment** (from `xcrun simctl list devices available`; pick any free one):

| Lane | Device (suggested) | UDID | Build |
|------|--------------------|------|-------|
| A | iPhone 17 Pro | `2B74939C-5EDF-445D-8B90-942BAC529C25` | default |
| B | iPhone 16 Pro | `2AC274EC-AF75-4E57-9687-76723B56B66B` | legacy |
| C | iPhone 17 | `E1152EC8-6A80-4966-92D9-7D7425A81CD2` | default |
| D | iPhone 16 | `F0259F3A-84BB-470D-8B13-168C566C9CDF` | default |
| E | **iPhone SE Test** (small screen — catches overflow) | `2190EC25-ED15-4F53-A88D-D4BEA4017366` | default |
| P | your physical iPhone | — | default (RC sandbox tester signed in) |

---

## 4. Parallel lanes

Each lane below lists **Config → Accounts → UI → DB → Analytics → Push → Regression watch**.
Lanes are independent; A–E run concurrently, P runs alongside on your phone.

### Lane A — New-user happy path: onboarding (trim ON) → paywall → first-launch tour
*Config:* default build, `onboarding_trim_enabled=true`, `guided_tour_enabled=true`. Fresh install + new email.
- **UI:** Walk all 20 trimmed onboarding screens (canonical order in `onboarding_provider.dart` `onboardingLastPageIndex`; cross-check `docs/qa/ui-map.md`). Verify each text-entry screen scrolls (no keyboard overflow). Paywall pages 22–26: loader → plan → journey → rating gate → paywall, progress bar hidden. Then drop to Home → **first-visit guided tour** fires: coach banner top-left, outline ring + cutout tracks anchor through scroll, tooltip width on center step 13. Walk Home → Collection → Journal → Duas first-visit teachings in sequence.
- **DB:** `user_profiles` row created with `saveOnboardingData` columns populated (exact column names — one mismatch fails the whole UPDATE). Tour completion persisted (no re-fire on relaunch).
- **Analytics:** funnel per `docs/analytics/onboarding_funnel.json`; `onboarding_field` per step; `paywall_flow_loader/plan`; `rating_gate`; `tour_started → tour_step_viewed×N → tour_step_advanced → tour_completed`.
- **Regression watch:** tour cutout follows scroll (41f127c), tap-vs-scroll gating (502e58a), safe-area clamp, ticker dispose, replay re-fire (da01c47), keyboard-fade (38a2607).

### Lane B — Dual-flow / kill-switch OFF: legacy onboarding (27 screens) + no tour
*Config:* legacy build (`RATING_GATE_ENABLED=false`), then `UPDATE app_config SET value='false' WHERE key IN ('onboarding_trim_enabled','guided_tour_enabled')`. Fresh install + new email.
- **UI:** Confirm 26-page flow (rating gate absent), legacy screens present, **no guided tour** on Home. Social-auth routing: from page 18 (Save Progress) social auth jumps to page 21 (Encouragement) skipping email/password (pinned by `onboarding_auth_routing_test.dart`).
- **DB:** dropped onboarding columns (20260525000001) absent; legacy path still writes profile correctly.
- **Analytics:** `onboarding_abandoned_at_page` fires when you background-kill mid-flow; `rating_gate_skipped` when gate disabled.
- **Regression watch:** flipping kill switches mid-session must not crash; abandonment telemetry pages match legacy indices.

### Lane C — AI bypass economy (free user, established account)
*Config:* default build. Seed a **free** account; drive `user_profiles` token balance + daily state via SQL.
- **Day-1 freebie (STATE D):** brand-new free user gets first AI feature free → `first_bypass_offered`/`first_bypass_claimed`. Verify `sync_all_user_data` first-bypass fields set.
- **Token bypass:** exhaust daily 1-use cap on an AI feature (Reflect / Build-a-Dua); bypass offer for 25 tokens → accept → `ai_bypass_purchased`, reject → `ai_bypass_rejected`. With <25 tokens → `no_tokens` path. Second bypass same day OK; **third blocked → `bypass_cap`** (max 2/day).
- **DB:** `ai_bypass_reservations` row per reservation; idempotency (20260524050930) — retry same reservation doesn't double-spend; race fix (20260524111803). `reserve_ai_bypass` decrements tokens via `sync_all_user_data` (never direct write).
- **Freemium guard (critical):** grant premium via `gift_premium_until` SQL → confirm premium user **short-circuits before `GatingService.reserveBypass`** (per CLAUDE.md / `gating_service.dart`); direct `UPDATE` of bypass counters / `referral_premium_until` / `gift_premium_until` from anon is **rejected by guard triggers** (20260524050655, 20260525200000).
- **IAP→sub upsell banner (#24):** for a user in IAP state, banner shows → `iap_to_sub_banner_shown`; tap → `iap_to_sub_banner_tapped` (purchase itself → Lane P); dismiss → `iap_to_sub_banner_dismissed`; simulate dismiss write failure → `iap_to_sub_banner_dismiss_failed`.
- **Regression watch:** P0/P1 hotfix bundle (#25/#26) — cancel-auth, replay status, app_config CHECK constraints, `user_reflections` length+shape caps (20260524164841 — over-long reflection rejected), `invalid_feature`/`already_consumed` guards.

### Lane D — Referrals + Ramadan gift + non-RC premium grants
*Config:* default build, `RAMADAN_GIFT_ENABLED=true`. Two accounts: **referrer** + **referee**.
- **Refer-to-unlock:** from paywall → `refer_unlock_shown`; share → `refer_unlock_share_tapped` (no-universal-links fallback → `refer_unlock_share_no_universal_links`); start-trial → `refer_unlock_start_trial_tapped`; back → `refer_unlock_back_to_paywall`. Referee enters code at onboarding field (`referral_field_revealed/code_entered/code_cleared`) and at Settings redeem (`referral_settings_redeem_opened/submitted`, `settings_redeem`). `referral_validate` rejects self-referral (20260514183034) and invalid codes; `apply_referral` reason-split (20260523000001).
- **My Referrals screen:** `my_referrals_shown/code_copied/share_tapped`.
- **Confirm push:** when referee converts → `push_on_referral_confirm` trigger → `notify-referral-confirmed` edge fn → confirm **send** via OneSignal MCP `view_message_history` (receipt → Lane P). Vault secrets present (20260525000000).
- **Ramadan gift:** seed an active `islamic_occasions` window (or use `GiftService.debugGiftClock`); card renders → `ramadan_gift_shown`; claim → `claim_sakina_gift` (idempotent `ON CONFLICT DO NOTHING`, race-fixed 20260525110000) → `ramadan_gift_claimed`; mirror to `user_profiles.gift_premium_until` via `greatest()`. Out-of-window client clock must **not** grant (server authority). Expired window → `ramadan_gift_window_expired`. Mawlid removed (20260525100000) — confirm absent.
- **DB:** `referrals` + `ramadan_gifts` rows; both premium sources OR into `PurchaseService.isPremium()`; premium-gated UI unlocks.

### Lane E — Core-loop regression + Settings + notifications (small screen)
*Config:* default build on iPhone SE (overflow catcher). Established account with history.
- **UI:** Daily muhasabah (both paths — `DailyLaunchOverlay` 4-question `answerCheckin` AND Home `Begin Muḥāsabah` → `/muhasabah` `discoverName` gacha, `q1='discover'`). Reflect, Journal (delete confirm, error toast), Collection, Store, Quests/Streaks/Titles. **Settings → Replay tour** (`tour_replay_tapped` → tour re-fires without app restart). Verify gacha + Arabic name display has no RTL bleed (`AdjustedArabicDisplay`).
- **Notifications:** grant → schedule daily reminder at chosen `reminder_time`; cold-launch must **not** re-nag "Open Settings" (5b07d16); skipping notifications preserves onboarding progress; reminder honored in payload.
- **DB:** economy via `sync_all_user_data` only (UTC daily-loop migration — streak rolls at UTC boundary); `consumable_clawback` + `starter_name_id` behave.
- **Push:** scheduled-notification row created; `send-scheduled-notifications` edge fn picks it up (logic only on sim; receipt on P).

### Lane P — Physical device: StoreKit + push receipt (runs on your phone)
*Config:* default build, signed in as **RevenueCat sandbox tester** (`docs/qa/revenuecat-sandbox.md`). Clear sandbox purchase history first (`asc-mcp sandbox_clear_purchase_history`).
- **Paywall purchase:** annual + weekly render from offerings; purchase → entitlement → routed Home; cancel → stays on paywall; restore (with + without entitlement). Offerings load failure → recoverable UI.
- **Webhook:** `revenuecat-webhook` flips `user_profiles.is_premium` on purchase/cancel/expiration (verify via Supabase MCP).
- **Cancellation feedback survey (#32):** cancel the sandbox sub → `user_subscription_cancellation_transition` detects the transition → survey sheet shows (`cancellation_feedback_shown`); submit (`cancellation_feedback_submitted`) and dismiss-as-implicit-skip (2a210f5 → `cancellation_feedback_dismissed`); rows land in `cancellation_feedback`; webhook push fires **only** because sandbox-gated (89c795a). Recency guard (4f66c2b) — no re-prompt within window.
- **IAP→sub upsell purchase:** complete the actual upsell purchase from the Lane-C banner.
- **Push receipt:** referral-confirm, cancellation, and daily-reminder notifications actually arrive.

---

## 5. Cross-cutting passes (not per-lane)

- **Migrations / clean reset (cluster #10):** `supabase db reset` succeeds; `list_migrations` shows all 43; anon RPC grants reconciled (20260531200000, 6402952) — anon can read `app_config` (20260529030441) but cannot execute privileged RPCs (20260509000000).
- **Security advisors:** `get_advisors` security + performance clean; RLS on new tables (`cancellation_feedback`, `referrals`, `ramadan_gifts`, `ai_bypass_reservations`) blocks cross-user reads — verify with two accounts.
- **Analytics funnel:** rebuild/validate `onboarding_funnel.json` funnel in Mixpanel; confirm step→step drop-off populated from Lanes A & B.
- **Freemium guard sweep (#9):** attempt anon/authed direct writes to every protected column — all rejected.

---

## 6. Execution sequencing

1. **Gate 0:** §3.1–§3.3 static + backend + clean-reset. Stop if red.
2. **Parallel boot/build/seed:** all sims boot, both builds install, test accounts seeded (SQL) — concurrent.
3. **Run lanes A–E concurrently** (background agents or round-robin), **P on phone in parallel**.
4. **Mixpanel verification** batched after lanes settle (ingestion lag).
5. **Cross-cutting passes** (§5) once lane DB state exists.
6. **Triage:** every bug → `docs/qa/findings/2026-06-01-<slug>.md`; per-lane log → `docs/qa/runs/2026-06-01-full-regression/lane-<X>.md` (before/after screenshots `sips -Z 1600`).

---

## 7. Exit criteria (release blockers)

- [ ] `flutter analyze` 0 errors, `flutter test` green, pgtap green, `check_no_fake_strings.sh` clean.
- [ ] `supabase db reset` succeeds; `get_advisors` clean; all 43 migrations applied.
- [ ] Both onboarding flows (trim ON/OFF) complete and write `user_profiles` correctly.
- [ ] Guided tour fires once, tracks anchors, replays from Settings, never re-fires after completion.
- [ ] AI-bypass: token spend + day-1 freebie + cap + no-tokens all correct; **premium never reaches `reserveBypass`**; freemium guards reject direct writes; reservation idempotent.
- [ ] Referrals: validate/apply/self-check correct; confirm push sent; My Referrals renders.
- [ ] Ramadan gift: claim idempotent, server-authoritative window, mirrors to `gift_premium_until`.
- [ ] Cancellation survey shows on real sandbox cancel; rows written; push sandbox-gated; recency guard holds.
- [ ] Paywall purchase/cancel/restore + webhook `is_premium` correct on device.
- [ ] No notification nag-loop on cold launch.
- [ ] Every new analytics event observed in Mixpanel with expected properties.
- [ ] No Arabic/English RTL bleed on any new surface.

---

## 8. Open questions / decisions for the operator

- Confirm `RAMADAN_GIFT_ENABLED` belongs in `env.json` (present in `env.example.json`, absent in current `env.json`).
- Which physical iPhone + sandbox Apple ID for Lane P.
- Whether to run lanes as parallel background Claude sessions (true concurrency) vs one session round-robin (simpler, slower).

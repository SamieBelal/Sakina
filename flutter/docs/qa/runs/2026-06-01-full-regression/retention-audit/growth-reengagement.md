# Analytics Coverage Audit — Growth & Re-engagement Retention Surfaces

**Date:** 2026-06-01
**Scope:** Referrals · Sakina Gift (Ramadan/Eid) · Rating gate · AI bypass + Day-1 freebie · Collection/cards/gacha · Store · Guided tour
**Method:** Code audit (`lib/services/analytics_events.dart` catalog + `grep` call-site wiring) + Mixpanel firing verification (`Run-Query`, project 4013350, insights, math total, last 30d). Mixpanel has **no business context configured** for this project.

Legend — Wired? = at least one live call site outside `analytics_events.dart`. Firing(30d) = total events in Mixpanel over trailing 30 days. `—` = no events returned (zero).

---

## Coverage matrix

| Surface | Event | Defined? | Wired? | Firing(30d) | Sufficient? | Gap |
|---|---|---|---|---|---|---|
| **Referrals — refer-to-unlock** | `refer_unlock_shown` | Y | Y | 20 | Y | — |
| | `refer_unlock_share_tapped` | Y | Y | 7 | Y | — |
| | `refer_unlock_share_no_universal_links` | Y | Y | (not queried; share-time) | Y | v1 share-without-deep-link marker; fine |
| | `refer_unlock_start_trial_tapped` | Y | Y | 6 | Y | referrer's own conversion |
| | `refer_unlock_back_to_paywall` | Y | Y | 4 | Y | — |
| **Referrals — referee/grant** | `referee_signed_up_with_referral` | Y | Y | 5 | Partial | fires on apply success; no INSTALL step before it |
| | `referee_granted_7d_window` | Y | Y | 3 | Y | mutual reward |
| | `referrer_granted_30d_window` | Y | Y | **—** | Partial | **0 firing** — nobody has crossed the 3-confirmed threshold yet (loop never closes in data) |
| **Referrals — code entry** | `referral_field_revealed` | Y | Y | 2 | Y | — |
| | `referral_field_code_entered` | Y | Y | (not queried) | Y | — |
| | `referral_field_code_cleared` | Y | Y | (not queried) | Y | — |
| | `referral_settings_redeem_opened` | Y | Y | (not queried) | Y | — |
| | `referral_settings_redeem_submitted` | Y | Y | 6 | Y | — |
| **Referrals — My Referrals screen** | `my_referrals_shown` | Y | Y | 10 | Y | carries confirmed_count/grants_count |
| | `my_referrals_share_tapped` | Y | Y | 1 | Y | — |
| | `my_referrals_code_copied` | Y | Y | **—** | Y | 0 firing (low traffic, not a wiring bug) |
| **Sakina Gift** | `ramadan_gift_shown` | Y | Y | 3 | Y | — |
| | `ramadan_gift_claimed` | Y | Y | 1 | Y | — |
| | `ramadan_gift_window_expired` | Y | Y | **—** | Partial | 0 firing — client-render-time event, only fires if a user re-opens after expiry; no server-side window-end signal |
| **Rating gate** | `rating_gate_shown` | Y | Y | 21 | Y | — |
| | `rating_gate_prompt_triggered` | Y | Y | 9 | Y | native SKStoreReview prompt actually requested |
| | `rating_gate_continue_tapped` | Y | Y | 12 | Y | — |
| | `rating_gate_skipped` | Y | Y | 8 | Y | — |
| **AI bypass** | `daily_cap_hit` | **N** | N | **—** | **No** | **Documented funnel entry never defined or wired** — funnel has no top |
| | `ai_bypass_offered` | N (raw str) | Y | 10 | Y | wired via raw string through `GatingService.onAnalyticsEvent`, not a const |
| | `ai_bypass_purchased` | Y (const, unused) | Y (raw str) | 1 | Y | const exists but call site uses raw `'ai_bypass_purchased'` |
| | `ai_bypass_rejected` | N (raw str) | Y | 1 | Y | raw string; reason prop wired |
| **Day-1 freebie** | `first_bypass_offered` | N (raw str) | Y | 2 | Y | raw string |
| | `first_bypass_claimed` | N (raw str) | Y | 2 | Y | raw string |
| | `first_bypass_rejected` | N (raw str) | Y | (not queried) | Y | raw string |
| **IAP→sub upsell** | `iap_to_sub_banner_shown` | Y | Y | 3 | Y | — |
| | `iap_to_sub_banner_tapped` | Y | Y | 6 | Y | — |
| | `iap_to_sub_banner_dismissed` | Y | Y | (not queried) | Y | — |
| | `iap_to_sub_banner_dismiss_failed` | Y | Y | (not queried) | Y | paired failure event |
| **Guided tour** | `tour_started` | Y | Y | 70 | Y | — |
| | `tour_step_viewed` | Y | Y | 317 | Y | — |
| | `tour_step_advanced` | Y | Y | (not queried) | Y | — |
| | `tour_completed` | Y | Y | 14 | Y | — |
| | `tour_skipped` | Y | Y | 15 | Y | — |
| | `tour_replay_tapped` | Y | Y | 5 | Y | — |
| | `tour_anchor_timeout` | Y | Y | 22 | Y | **22/70 tour starts hit an anchor timeout — health signal, see below** |
| | `tour_start_skipped` | Y | Y | (not queried) | Y | — |
| **Collection / cards / gacha** | (any card/gacha event) | **N** | N | **—** | **No** | **Zero instrumentation across entire surface** |
| **Store (token/scroll packs)** | (any store/purchase event) | **N** | N | **—** | **No** | **Zero instrumentation — real-money consumable IAP completely dark** |

---

## Surface-by-surface sufficiency assessment

### 1. Referrals — viral loop is measurable but the INSTALL step is invisible
The loop is instrumented at: `refer_unlock_shown → refer_unlock_share_tapped → [BLACK BOX] → referee_signed_up_with_referral → referee_granted_7d_window → referrer_granted_30d_window`. The `source` property (`deep_link` / `onboarding_field` / `settings_redeem`) splits the three referee ingress paths cleanly.

**Two gaps:**
- **No share→install attribution.** There is no event between `refer_unlock_share_tapped` (referrer's device) and `referee_signed_up_with_referral` (referee's device). We cannot compute share→install conversion or K-factor — only share→signup-among-installed. The catalog itself flags this is pre-universal-links (`refer_unlock_share_no_universal_links` fires on every share). Until deferred deep-link / install attribution exists, the top of the viral funnel is uncountable.
- **`referrer_granted_30d_window` = 0 firing.** The reward that closes the loop (referrer crosses 3 confirmed referees) has never fired in 30d. Code is wired (`referral_service.dart:209`); this is a real-world "nobody hit the threshold" outcome, not a wiring bug — but it means the loop's payoff is currently unproven in data and the 3-referral threshold may be too high.

### 2. Sakina Gift — claim is measured, but gift→retention linkage is not
`shown → claimed` fires (3 / 1). The retention question ("did the 7-day premium window retain the user past expiry?") is **not answerable**: `ramadan_gift_window_expired` is a client-render-time event (only fires if the user happens to re-open the app after expiry) and returned 0. There is no event marking the *start* of the premium window vs. activity inside it, so gift→retained cannot be built as a funnel/retention report from these events alone (would need server-side window-grant + a post-expiry return event).

### 3. Rating gate — fully sufficient
`shown(21) → prompt_triggered(9) → continue(12) / skipped(8)`. The split between `shown` and `prompt_triggered` (the actual native SKStoreReview request) lets us measure prompt-impact and review-prompt-rate. No gaps.

### 4. AI bypass + Day-1 freebie — funnel fires but is missing its entry event
`ai_bypass_offered(10) → ai_bypass_purchased(1) / ai_bypass_rejected(1)` and `first_bypass_offered(2) → first_bypass_claimed(2)` all fire. **But `daily_cap_hit` — documented in the catalog as the funnel's first step — is neither defined as a constant nor wired anywhere, and fires 0.** Without it we cannot measure how many cap-hits convert to an offer (offer-rate), only offer→purchase. Also a hygiene issue: the bypass events fire via **raw strings** through the `GatingService.onAnalyticsEvent` / `DailyCapSheet.onAnalyticsEvent` static hooks rather than the `AnalyticsEvents` constants (the `aiBypassPurchased` const exists but the call site hardcodes the string) — drift risk, and the constants read as dead in a naive grep.

### 5. Collection / cards / gacha + Store — completely dark (biggest gap)
There is **zero analytics instrumentation** across `lib/features/collection/`, `lib/features/store/`, and the gacha reveal flow (`muhasabah_screen.dart` / `daily_loop_provider.dart`). No catalog events, no `track()` calls (`grep` of `lib/features/collection` + `lib/features/store` for `track`/`Analytics` → 0 hits). Consequences:
- **Gacha/card engagement is unmeasurable.** Cards are the core gamification/collection retention loop (Bronze→Silver→Gold→Emerald, daily gacha). We cannot see card reveals, tier-ups, collection-screen opens, or completion progress — so we cannot tie collection engagement to retention at all.
- **Store conversion is unmeasurable AND it sells real money.** `store_screen.dart` runs RevenueCat consumable purchases (token/scroll packs, `purchaseConsumable` + `grantForMostRecentPurchase`) with no store_viewed, no pack_selected, no purchase_succeeded/failed/cancelled events. A monetized surface is fully invisible in product analytics (RevenueCat has the billing record, but funnel/abandonment/entry-attribution is gone).

### 6. Guided tour — sufficient, but a health flag
End-to-end measurable: 70 started, 317 steps viewed, 14 completed, 15 skipped, 5 replayed. **`tour_anchor_timeout` fired 22 times against 70 starts (~31%)** — roughly a third of tours hit a step whose UI anchor never resolved. That's a tour-reliability problem worth a separate bug, but instrumentation itself is complete. Note ~41 of 70 starts have no completed/skipped terminal event — consistent with anchor timeouts and mid-tour drop, but a `tour_abandoned` terminal would make the funnel airtight.

---

## Prioritized list of MISSING events (with the retention decision each informs)

**P0 — instrument the dark monetized/gamification surfaces**
1. **`store_viewed` / `store_pack_selected` / `store_purchase_succeeded` / `store_purchase_failed` / `store_purchase_cancelled`** (with pack id, price, token amount, entry source) — *Decision: which store entry points and packs convert, where purchase abandonment happens, and whether token-pack buyers retain better than subscribers.* Currently a real-money surface is 100% dark.
2. **`gacha_opened` / `card_revealed` / `card_tier_up`** (with name id, tier, source = daily vs store) — *Decision: does the daily gacha/card loop drive D1/D7 return? Are tier-ups a retention hook worth amplifying?* Core collection retention loop is unmeasured.
3. **`collection_viewed`** (with cards_owned, completion_pct) — *Decision: do users who browse their collection retain better; is "collection completeness" a re-engagement lever?*

**P1 — close existing funnels that are missing their entry/linkage**
4. **`daily_cap_hit`** (define as a constant + wire at the gating cap-rejection point, with feature) — *Decision: cap-hit→offer rate and overall monetization pressure from the daily AI cap.* The funnel is documented around this event but it does not exist.
5. **Referral install attribution** — a `referral_install_attributed` (or deferred-deep-link) event tying a share to an install on the referee device — *Decision: true share→install conversion and K-factor; whether to invest in universal links.* Today the top of the viral funnel is uncountable.
6. **Gift window lifecycle** — `gift_window_started` (on claim/grant) + a reliable post-expiry `gift_window_retained` / return signal — *Decision: does the 7-day Sakina Gift premium window convert to retained/paying users?* Gift→retention is currently unbuildable.

**P2 — hygiene + completeness**
7. **Migrate AI-bypass/Day-1 raw-string `track()` calls to the `AnalyticsEvents` constants** (`ai_bypass_*`, `first_bypass_*`) — prevents event-name drift and makes the wired call sites discoverable by grep (they currently read as dead constants).
8. **`tour_abandoned`** terminal event (or reuse timeout as terminal) so tour completion funnel reconciles (70 started vs only ~29 reaching completed/skipped). Separately: file the **~31% `tour_anchor_timeout` rate** as a reliability bug, not an analytics one.

---

## Mixpanel firing summary (30d totals, this audit)
refer_unlock_shown 20 · refer_unlock_share_tapped 7 · refer_unlock_start_trial_tapped 6 · refer_unlock_back_to_paywall 4 · referee_signed_up_with_referral 5 · referee_granted_7d_window 3 · **referrer_granted_30d_window 0** · referral_field_revealed 2 · referral_settings_redeem_submitted 6 · my_referrals_shown 10 · my_referrals_share_tapped 1 · **my_referrals_code_copied 0** · ramadan_gift_shown 3 · ramadan_gift_claimed 1 · **ramadan_gift_window_expired 0** · rating_gate_shown 21 · rating_gate_prompt_triggered 9 · rating_gate_continue_tapped 12 · rating_gate_skipped 8 · ai_bypass_offered 10 · ai_bypass_purchased 1 · ai_bypass_rejected 1 · first_bypass_offered 2 · first_bypass_claimed 2 · **daily_cap_hit 0** · iap_to_sub_banner_shown 3 · iap_to_sub_banner_tapped 6 · tour_started 70 · tour_step_viewed 317 · tour_completed 14 · tour_skipped 15 · tour_replay_tapped 5 · tour_anchor_timeout 22 · **card/gacha/store events 0 (do not exist)**.

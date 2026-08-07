# Paywall Draft — Decision ⑥ (One Ship hybrid gate)

**Status: APPROVED (founder, 2026-07-25; W5 copy reconciliation 2026-08-03) — structure + copy locked; visual polish happens at W5 build per DESIGN.md (mock is layout/copy fidelity only).**
Architecture per §V5.3/§V6.3 (Rootd hybrid): front-loaded at onboarding's emotional peak, hard-looking, dismissible-to-limited-free, with trial and pricing read from live RevenueCat products. Mock: [`../mocks/2026-07-25-paywall-mock.html`](../mocks/2026-07-25-paywall-mock.html).

> ## ⚠️ RECONCILED WITH THE STORE — 2026-08-03. Read before quoting any number below.
>
> This deck's examples were written ahead of the store. The implementation now renders
> the localized price and introductory duration from RevenueCat, so no example below is
> a runtime fallback or a promise of a fixed storefront value.
>
> | | This deck says | Store (verified at ASC/RC) | Decision |
> |---|---|---|---|
> | Trial | store-derived | **RevenueCat introductory offer** | **Renderer follows the live eligible offer.** |
> | Annual | store-derived | **RevenueCat localized price** | **No static price fallback.** |
>
> **Trial → the store.** Every duration renders from `TrialOffer`
> (`lib/features/paywall/trial_offer.dart`) through a `{trial}` placeholder. The timeline
> appears only for a whole-day offer of at least two days; month/unknown-day and one-day
> offers retain truthful CTA/terms without invented dates.
>
> **Price → the store.** Both annual and weekly prices, the annual per-week equivalent, and
> the savings label are computed from the two live packages. If either required package or
> price is unavailable, the paywall renders no sellable price, terms, or purchase CTA.

## Decision: 3 pages, stable `page_id`s: `value_depth` → `trial_timeline` → `plan_select`
*(Pins the "e.g." ids in §V6.8.C6 — `value_depth`/`trial_timeline` replace the placeholder `value_names`/`value_journey`.)* Rationale: page 1 = personalized depth (JTBD echo, the +37% multi-page pattern); page 2 = trial-transparency timeline (the proven trial-anxiety reducer — and our reverence posture applied to billing: plain terms, stated once); page 3 = plan select. The free-forever honesty lives as one footer line on page 3 + the post-dismissal "always free" card (§V6.3.1d) — a full "free tier" page would sell the free thing.

## Page 1 — `value_depth` (echoes {Name₁} + contract)
Visual: the user's just-revealed card. Visible ✕ from page one (no 3s delay — §V6.3.1d).

| | Problem contract | Sign contract |
|---|---|---|
| Headline | **You've met {Name₁}.** | **You've met {Name₁} — the first Name of your journey.** |
| Subline | Premium goes deeper into what you named: | Premium goes deeper, every day: |
| Bullet 1 | **Reflections that meet you where you are.** | **Reflections that meet you where you are.** |
| Bullet 2 | **Space for the duʿā you're carrying.** | **Space for the duʿā you're carrying.** |
| Bullet 3 | **A Name of Allah to return to when you need one.** | **A Name of Allah to return to when you need one.** |

*(Review fixes 2026-07-25: journal itself is NOT gated — premium generates the content, the journal keeps it (B1); the free-forever subline moved off page 1 — honesty lives on page 3 + the dismissal card only, per the Decision paragraph (S2). `{chip phrase}` = canonical chip phrasing only, never raw free text.)*
| CTA | Continue | Continue |

## Page 2 — `trial_timeline`
Headline: **Try everything free for {trial}.**
- **Today** — your trial starts today with full Premium access.
- **Day {trialDaysMinusOne}** — Apple reminds you before your trial ends.
- **Day {trialDays}** — your selected plan begins after the trial. Cancel anytime before renewal.
Footnote: *No charge today.* · CTA: Continue.
*(Review fix B2: the reminder rides Apple's SYSTEM trial-end notice — the plan's "one allowed clock" — no app-scheduled second clock, no new W5 task, and true regardless of the user's notification-permission state. The day beats render only for eligible whole-day trials of at least two days; one-day, month, and unknown-day offers omit the timeline rather than invent dates. S1: "in one tap" removed — iOS cancellation is multi-step.)*

## Page 3 — `plan_select`
Headline: **Choose how you continue.**
**Premium checklist (founder direction 2026-07-25 — reuses the SHIPPED benefit strings from `app_strings.dart` `paywallPremiumBenefit1-5`, verbatim):** Unlimited reflections, duʿās & Name discoveries · 5× daily rewards, every single day · Exclusive Emerald cards for every Name of Allah · A monthly gift of tokens & scrolls · 3 streak freezes so you never lose progress. *(Placement rationale: page 1 sells the personalized depth at the peak; the full checklist completes the value case at the decision moment. All five pass the firewall — tier language attaches to cards, no arc-count, tools/artifacts only.)*
- **Annual (pre-selected):** live localized annual price and computed per-week equivalent · computed savings label
- **Weekly (de-emphasized):** **live price only**
CTA: **Start my {trial} free** or **Subscribe** when no eligible free trial exists
Plain terms under CTA (template per selection, live RC prices substituted — S3): *"Free for {trial}, then {price}. Cancel anytime in Settings."* · *"{price}. Cancel anytime in Settings."* when there is no trial
**Build rules (review S4-S6, N4):** ✕ hit area ≥44pt on every page · terms line uses `textSecondaryLight` minimum (never tertiary — billing terms must be legible) · every page scrollable on <812pt frames with the card art clamped smaller, CTA pinned (the existing keyboard-overflow LayoutBuilder convention) · weekly plan rendered as a de-emphasized text row, not a peer card · bullet icons are drawn assets marked decorative, never emoji · dismissal card exits via its own tap ("Continue") → home, never auto-advance.
Footer (honesty line): *The 99 Names, your daily Name and its story, and your streak stay free — always.*

## Surfaces — where this design applies (founder Q 2026-07-25)
One paywall widget parameterized by `placement`; one copy firewall with live storefront economics everywhere:
- **`onboarding`** — the full 3-page ceremony above. Re-present on a later session start (≤1/session): lands on `plan_select` directly, not the full replay.
- **`soft_inapp`** (allowance exhausted, `trigger_feature` prop) — **condensed single screen**: trigger-specific value line ("Your reflections for this week are used — Premium is unlimited.") + the plan cards + plain terms. Never the 3-page ceremony mid-task.
- **LapsedTrialSheet** — separate shipped surface (store-trial winback, re-paced to 7d); same firewall, own layout.
- **Future:** welcome/backup offers + `eid_recap` (post-decision / seasonal) — bound by the same firewall when built.

## Dismissal (all pages)
✕ → home directly (no ReferUnlock chain), one-time reverent card: "The 99 Names, your daily Name and its story, and your streak are yours — always free." Re-present ≤1/session start, ≤2 offer surfaces/week. No welcome/backup offers in v1 (post-decision, §V6.8.B8).

## Firewall self-check
No arc-count ("X of 99") anywhere · no guilt/loss framing · no countdown UI · no "sign"/"meant for you" · premium = tools and depth, stated as such · scarcity: none (no offers in v1) · trial terms plain, stated in the CTA and billing terms as required disclosure · weekly row price-only · free-forever honesty present but not the sales pitch (§V6.8.A4).

## Events (per §V6.4.3/§V6.8.C6)
`paywall_viewed{placement:'onboarding'}` · `paywall_page_viewed{page_id}` · `paywall_cta_tapped` → purchase-sheet chain · `paywall_closed{placement}` · `free_tier_entered`.

**Sign-off:** `reviewed_by: founder · reviewed_at: 2026-07-25 · verdict: good (structure + copy; aesthetics at build)`

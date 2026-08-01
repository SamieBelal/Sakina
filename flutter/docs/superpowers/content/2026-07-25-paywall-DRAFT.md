# Paywall Draft — Decision ⑥ (One Ship hybrid gate)

**Status: APPROVED (founder, 2026-07-25) — structure + copy locked; visual polish happens at W5 build per DESIGN.md (mock is layout/copy fidelity only). Copy FREEZES at T0.**
Architecture per §V5.3/§V6.3 (Rootd hybrid): front-loaded at onboarding's emotional peak, hard-looking, dismissible-to-limited-free, real RC **7-day trial**, **$59.99/yr** anchor. Mock: [`../mocks/2026-07-25-paywall-mock.html`](../mocks/2026-07-25-paywall-mock.html).

> ## ⚠️ RECONCILED WITH THE STORE — 2026-08-01. Read before quoting any number below.
>
> This deck's numbers were written ahead of the store and **two of them never matched
> it**. Both are now settled — in *opposite* directions. Nothing below is edited; read
> it through this note.
>
> | | This deck says | Store (verified at ASC/RC) | Decision |
> |---|---|---|---|
> | Trial | 7 days | **3 days** (`FREE_TRIAL / THREE_DAYS`, live since 2026-04-29) | **Deck wins — flip the store to 7.** |
> | Annual | $59.99/yr · $1.15/wk | **$49.99/yr · $0.96/wk** | **Store wins — $59.99 was deliberately NOT chosen (founder, 2026-08-01). The deck's anchor is dead copy.** |
>
> **Trial → the store moves.** The flip is queued in [`TODO.md`](../../../TODO.md) and must
> happen **only after 1.3.0 reaches `READY_FOR_SALE`** — never at submission. Until then the
> store serves 1.2.0, whose paywall hardcodes "3 days", so an early flip hands every new
> subscriber four unadvertised free days. From 1.3.0 forward **no duration in this deck is
> implemented as a literal**: every one renders from `TrialOffer` (`lib/features/paywall/
> trial_offer.dart`) through a `{trial}` placeholder, so the copy follows the store by
> itself with no release. Treat every "7 days" below as *the value the store will be set
> to*, not as a string to type into Dart. **Writing a duration into Dart is what produced
> the "Day 6 … Day 7" bug this deck already caused once.**
>
> **Price → the deck moves.** Shipping price is **$49.99/yr**, and the implementation
> already follows it (`paywallAnnualPerWeek = '$0.96'`; `$59.99` and `$1.15` appear nowhere
> in `lib/`). Strike the $59.99 anchor and the "$1.15 a week" line from lines 34, 37 and 42
> wherever you work from them — they describe a price that was considered and declined, not
> one that is pending. ⚠️ Unlike the trial, `$0.96` **is** a hardcoded literal derived from
> $49.99: if the annual price ever does move, that constant goes silently wrong.

## Decision: 3 pages, stable `page_id`s: `value_depth` → `trial_timeline` → `plan_select`
*(Pins the "e.g." ids in §V6.8.C6 — `value_depth`/`trial_timeline` replace the placeholder `value_names`/`value_journey`.)* Rationale: page 1 = personalized depth (JTBD echo, the +37% multi-page pattern); page 2 = trial-transparency timeline (the proven trial-anxiety reducer — and our reverence posture applied to billing: plain terms, stated once); page 3 = plan select. The free-forever honesty lives as one footer line on page 3 + the post-dismissal "always free" card (§V6.3.1d) — a full "free tier" page would sell the free thing.

## Page 1 — `value_depth` (echoes {Name₁} + contract)
Visual: the user's just-revealed card. Visible ✕ from page one (no 3s delay — §V6.3.1d).

| | Problem contract | Sign contract |
|---|---|---|
| Headline | **You've met {Name₁}.** | **You've met {Name₁} — the first Name of your journey.** |
| Subline | Premium goes deeper into what you named: | Premium goes deeper, every day: |
| Bullet 1 | A personal reflection on {chip phrase}, every day | A personal reflection to sit with, every day |
| Bullet 2 | Your own duʿā, built for what you carry | Your own duʿā — even when you can't find the words |
| Bullet 3 | Every reflection and duʿā, kept in your journal | Every reflection and duʿā, kept in your journal |

*(Review fixes 2026-07-25: journal itself is NOT gated — premium generates the content, the journal keeps it (B1); the free-forever subline moved off page 1 — honesty lives on page 3 + the dismissal card only, per the Decision paragraph (S2). `{chip phrase}` = canonical chip phrasing only, never raw free text.)*
| CTA | Continue | Continue |

## Page 2 — `trial_timeline`
Headline: **Try everything free for 7 days.**
- **Today** — everything unlocks: daily reflections and your own duʿās, saved to your journal.
- **Day 6** — Apple reminds you before your trial ends.
- **Day 7** — your plan begins. Cancel anytime before — no charge.
Footnote: *No charge today.* · CTA: Continue.
*(Review fix B2: the reminder rides Apple's SYSTEM trial-end notice — the plan's "one allowed clock" — no app-scheduled second clock, no new W5 task, and true regardless of the user's notification-permission state. S1: "in one tap" removed — iOS cancellation is multi-step.)*

## Page 3 — `plan_select`
Headline: **Choose how you continue.**
**"Everything in Premium" checklist (founder direction 2026-07-25 — reuses the SHIPPED benefit strings from `app_strings.dart` `paywallPremiumBenefit1-5`, verbatim):** Unlimited reflections, duʿās & Name discoveries · 5× daily rewards, every single day · Exclusive Emerald cards for every Name · A monthly gift of tokens & scrolls · 3 streak freezes so you never lose progress. *(Placement rationale: page 1 sells the personalized depth at the peak; the full checklist completes the value case at the decision moment. All five pass the firewall — tier language attaches to cards, no arc-count, tools/artifacts only.)*
- **Annual (pre-selected):** $59.99/year · *$1.15 a week* · badge: "7 days free first"
- **Weekly (de-emphasized):** live RC price · "7 days free first" *(weekly SKU trial is also 7-day per §V6.8.B4)*
CTA: **Start my 7 days free**
Plain terms under CTA (template per selection, live RC prices substituted — S3): annual *"Free for 7 days, then $59.99/year. Cancel anytime in Settings."* · weekly *"Free for 7 days, then {RC weekly price}/week. Cancel anytime in Settings."*
**Build rules (review S4-S6, N4):** ✕ hit area ≥44pt on every page · terms line uses `textSecondaryLight` minimum (never tertiary — billing terms must be legible) · every page scrollable on <812pt frames with the card art clamped smaller, CTA pinned (the existing keyboard-overflow LayoutBuilder convention) · weekly plan rendered as a de-emphasized text row, not a peer card · bullet icons are drawn assets marked decorative, never emoji · dismissal card exits via its own tap ("Continue") → home, never auto-advance.
Footer (honesty line): *The 99 Names, your daily Name and its story, and your streak stay free — always.*

## Surfaces — where this design applies (founder Q 2026-07-25)
One paywall widget parameterized by `placement`; one copy firewall + economics ($59.99 anchor, 7-day trial) everywhere:
- **`onboarding`** — the full 3-page ceremony above. Re-present on a later session start (≤1/session): lands on `plan_select` directly, not the full replay.
- **`soft_inapp`** (allowance exhausted, `trigger_feature` prop) — **condensed single screen**: trigger-specific value line ("Your reflections for this week are used — Premium is unlimited.") + the plan cards + plain terms. Never the 3-page ceremony mid-task.
- **LapsedTrialSheet** — separate shipped surface (store-trial winback, re-paced to 7d); same firewall, own layout.
- **Future:** welcome/backup offers + `eid_recap` (post-decision / seasonal) — bound by the same firewall when built.

## Dismissal (all pages)
✕ → home directly (no ReferUnlock chain), one-time reverent card: "The 99 Names, your daily Name and its story, and your streak are yours — always free." Re-present ≤1/session start, ≤2 offer surfaces/week. No welcome/backup offers in v1 (post-decision, §V6.8.B8).

## Firewall self-check
No arc-count ("X of 99") anywhere · no guilt/loss framing · no countdown UI · no "sign"/"meant for you" · premium = tools and depth, stated as such · scarcity: none (no offers in v1) · trial terms plain, stated once · free-forever honesty present but not the sales pitch · {chip phrase} = canonical chip phrasing only, never raw free text (§V6.8.A4).

## Events (per §V6.4.3/§V6.8.C6)
`paywall_viewed{placement:'onboarding'}` · `paywall_page_viewed{page_id}` · `paywall_cta_tapped` → purchase-sheet chain · `paywall_closed{placement}` · `free_tier_entered`.

**Sign-off:** `reviewed_by: founder · reviewed_at: 2026-07-25 · verdict: good (structure + copy; aesthetics at build)`

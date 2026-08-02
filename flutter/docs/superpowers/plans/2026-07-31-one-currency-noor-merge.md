# One Currency — merge tokens and scrolls into Noor

> **⛔ DEFERRED — founder decision 2026-07-31. Do NOT pick this up during W5.**
> The whole of it moves to the **softener wave** (post-keep-decision). W5 does **zero**
> currency work — not the cohort branch, not the Store SKUs, not the benefit string.
> Deferral is safe because nothing becomes false (tokens still buy streak restores,
> scrolls still buy tier-ups) and nobody loses value they paid for (the bypass removal is
> cohort-scoped, so every existing token holder keeps it until this same wave).
> Tracked in [`TODO.md`](../../../TODO.md) → *One currency: merge tokens + tier-up scrolls
> into Noor*. **§4 below still describes a W5-riding cohort branch — that is superseded by
> this banner; there is no W5 component any more.**

**Status: DEFERRED (see banner). Two founder decisions remain open for whenever it runs (§3).**
**Date:** 2026-07-31
**Branch/worktree:** `feat/reel-first-w2-onboarding` at `/Users/appleuser/CS Work/Repos/sakina-reel-first`
**Parents:** `2026-07-23-conversion-refactor-changes-and-implementation.md` §W5 + **D10** (the decision that created this) · `2026-07-25-lantern-cosmetics-01-backend-economy.md` (the Noor economy this merges into)
**Trigger:** W5 deletes the AI bypass, which was the only routine token sink. D10 recorded the hole; this plan fills it.

Sakina runs **three** soft currencies — tokens, tier-up scrolls, Noor — against **three**
separate sinks. That fragmentation is why none of them is liquid. This plan collapses them
into one: **Noor**. New-cohort accounts mint Noor from T0 and never hold a token; existing
accounts convert during the softener wave that is already scheduled for them.

**Non-goals:** the W5 paywall and free-tier limits (that ship first, unchanged) · XP and
levels (a progression signal, not a currency — stays) · streak freezes (an entitlement, not
a balance) · any change to what premium grants until §6.

---

## 1. Verified baseline (production, read 2026-07-31)

**The token economy is already inert. This is the single most important fact in this plan.**

| Measure | Value |
|---|---|
| Users holding tokens | 1,362 (100% of rows — every account is seeded) |
| Tokens outstanding | **348,024** · avg 256 · max 1,618 · 82 users over 500 |
| Tokens **ever spent**, all-time | **2,775** |
| Users who have **ever spent one token** | **31** (2.3% of holders) |
| Tier-up scrolls outstanding | 17,810 |
| Noor holders / outstanding | **1 user / 30 Noor** (economy merged 2026-07-28) |
| Consumable clawbacks / cosmetic IAP grants | 0 / 0 |

**0.8% of every token ever minted has been spent.** Removing the bypass does not break a
working economy — it removes the last pretext for one that never worked. Read the other way
round: for **98% of holders these balances have never bought anything**, which is what makes
the conversion rate in §3 an economic choice rather than a debt we owe.

The receiving side is effectively empty (1 holder, 30 Noor), so there is no incumbent Noor
economy to disrupt — only one to avoid devaluing before it starts.

### Schema

- `public.user_tokens` — `{user_id, balance (default 100), total_spent, tier_up_scrolls}`.
  **Scrolls live in the token table**, which is why they cannot be scoped out of this work.
- `public.user_profiles.noor_balance` — `integer not null default 0 check (>= 0)`, guarded by
  the `cosmetics_guard` trigger.
- **`public.user_profiles.free_tier_cohort`** — `text check (in ('reel_v1','legacy'))`,
  **server-assigned in `handle_new_user`** from `app_config.new_signup_cohort`, never
  client-writable. NULL = predates cohort activation. *This already exists* (migration
  `20260727100200`) and is the branch this whole plan rides. No new plumbing.

### Live server surface

**15 functions touch `user_tokens`**, all SECURITY DEFINER:

- *mint* — `handle_new_user`, `earn_tokens`, `claim_daily_reward`, `grant_premium_monthly`, `grant_winback_tokens`, `award_xp`
- *spend* — `spend_tokens`, `repair_streak_paid`, `reserve_ai_bypass`, `cancel_ai_bypass`, `_replay_reservation_response`
- *scrolls* — `earn_scrolls`, `spend_scrolls`
- *other* — `clawback_consumable_grant`, `sync_all_user_data`

**3 touch `noor_balance`:** `award_noor`, `unlock_cosmetic`, `cosmetics_guard`. `sync_all_user_data` touches both.

**Three of the fifteen disappear with the bypass** — `reserve_ai_bypass`,
`cancel_ai_bypass`, `_replay_reservation_response`. **The real conversion target is 12
functions**, two of which (`spend_tokens`, `sync_all_user_data`) merely *lose a bypass
branch* and still have to be converted.

> **Corrected 2026-07-31 (second pass).** This paragraph first read "Five of the fifteen are
> bypass functions W5 deletes anyway … the real conversion target is ~10 functions." That
> subtracted `spend_tokens` and `sync_all_user_data` from the workload, but only their bypass
> *branches* go — the functions survive and are two of the most load-bearing ones in the
> merge (`sync_all_user_data` is the dual-emit in §5.2.3). Sizing the work at ~10 understates
> it by the two that matter most. Verified against `pg_proc` in production 2026-07-31: 15
> functions reference `user_tokens`, all SECURITY DEFINER, exactly as listed above.

### Client surface

~12 files carry genuine economy-token references: `token_service.dart`,
`token_provider.dart`, `store_screen.dart`, `streak_rescue_sheet.dart`,
`daily_rewards_service.dart`, `achievements_service.dart`, `achievement_checker.dart`,
`consumable_grants_service.dart`, `user_data_batch_sync_service.dart`, the balance chip in
`subpage_header.dart`, `dev_tools_service.dart`, plus `cosmetics_service.dart` receiving.
(A plain grep for "token" hits ~58 files; most are auth tokens and are not in scope.)

### Store

Six consumable SKUs: `sakina_tokens_100/250/500`, `sakina_scrolls_3/10/25`.

> **Unverified, and it gates §5.4.** Whether any real customer has ever *bought* a token or
> scroll pack. There is no grants ledger, `consumable_clawback_events` is empty, and RC's
> overview does not split consumables (28-day revenue $451, MRR $154, 19 active subs). Given
> 100 free at signup × 1,362 accounts ≈ 136k minted before daily rewards are counted,
> purchased tokens are almost certainly negligible — but **check Mixpanel `pack_purchased`
> with the test distinct_ids excluded before retiring a SKU.** A single paying customer
> changes the notice we owe them.

---

## 2. The price-ladder collision (found while scoping — this is the hard part)

The three currencies are **not on compatible scales**:

| Sink | Currency | Price |
|---|---|---|
| Streak restore (≥7-day streak) | tokens | **100 / 250 / 500** by pre-lapse streak |
| Bronze → Silver tier-up | scrolls | **5** |
| Silver → Gold tier-up | scrolls | **10** |
| Lantern skins / backdrops | Noor | **120 – 300** |

**Tokens and Noor already line up** — both run in the hundreds. A 1:1 token merge is
arithmetically coherent, and streak restore keeps its exact price ladder.

**Scrolls do not.** A tier-up costs 5 units where a skin costs 120. Merge scrolls 1:1 and
**every card tier-up in the game becomes effectively free.** So scrolls cannot be converted
without simultaneously **repricing tier-ups onto the Noor ladder** — and the conversion rate
for scroll *balances* must then preserve purchasing power against the new price, not the old
number.

Worked example at the obvious repricing (Bronze→Silver **100 Noor**, Silver→Gold **200
Noor**), which keeps the 1:2 ratio and puts a tier-up beside a cheap cosmetic:

- 5 scrolls bought one Bronze→Silver, so **1 scroll ≈ 20 Noor**.
- 17,810 scrolls × 20 = **356,200 Noor**, plus 348,024 from tokens at 1:1 = **~704,000 Noor**
  across 1,362 users — an average of **~517 Noor each**, or roughly **two to four free
  cosmetics per user**, handed to the entire base on a shop that opened three days ago.

That is the real cost of this plan, and it is an economics problem, not an engineering one.

---

## 3. The two open decisions

**① Do scrolls fold in?**

- **In (recommended).** They share a table with tokens, so leaving them out means keeping
  `user_tokens` alive as a one-column vestige and shipping two migrations instead of one.
  More importantly, one currency is the entire point: it makes every earned unit a genuine
  choice between a card tier-up and a lantern skin, which is what makes it worth earning.
  Requires the tier-up repricing in §2.
- **Out.** Cheaper now, but leaves two currencies and a table named `user_tokens` holding
  only scrolls. Defers the problem rather than solving it.

**② The conversion rate.** The honest framing is not "what is fair" but **"what did these
balances actually let you do?"** For 98% of holders: nothing — they never found a sink they
wanted. Any positive rate is a strict improvement on that, which means we are free to choose
on economic grounds provided we say so plainly. Three candidates:

| | Tokens | Effect |
|---|---|---|
| **1:1** | 348k → 348k Noor | Generous, arithmetically clean, streak-restore prices unchanged. Gives ~2 free cosmetics/user and blunts the Noor IAP before it has sold anything. |
| **Rate + cap** *(recommended)* | 1:1 up to a ceiling (e.g. 250) | Median user lands with a real, usable credit just under one mid-tier cosmetic; the 82 whales don't empty the shop. Needs one clear sentence of explanation. |
| **10:1** | 348k → 34.8k | Protects the shop; reads as a devaluation to anyone watching, and breaks the streak-restore ladder (100 tokens → 10 Noor) unless that is repriced too. |

**Recommendation: 1:1 with a per-account cap.** It keeps streak restore's price ladder
untouched (the one sink that actually works), gives the wardrobe a live economy on day one
instead of an empty shelf, and bounds the giveaway. Whatever is chosen ships with **one plain
in-app sentence, stated once, no spin** — see §5.5.

---

## 4. Timing — why this does NOT ride W5

An economy migration during the conversion measurement window is exactly the second variable
that makes the T0+6wk keep read unreadable. It also does not need to be there: **W5 removes
the bypass for the new cohort only**, so legacy users keep their existing sink either way.

So the work splits along the cohort line that already exists:

- **New cohort (`free_tier_cohort = 'reel_v1'`), from T0** — mints **Noor**, never tokens.
  Nothing to migrate, no conversion rate, no notice, no legacy balance. They receive the
  clean economy as their only economy.
- **Everyone else** — converts during the **softener wave**, after the keep decision
  (~T0+6wk, completing before Ramadan prep), inside the 30-day notice that wave already
  sends. One message about "your tier and your currency are changing", not two.

Phases 1–2 and 4 below are what W5 must carry (small — the cohort branch on the mint paths).
Phases 3, 5 and 6 are the softener wave. **§7 answers this split explicitly.**

---

## 5. Phases

### 5.1 — Decide (blocking)

Close ①, ②, and the tier-up repricing. Nothing starts until these are fixed in writing,
because every later step encodes them. Record in the D10 entry, not in this file only.

### 5.2 — Server, additive only (rides W5)

1. `award_noor` / a new `spend_noor` gain the full set of reason strings currently used by
   `earn_tokens` / `spend_tokens`, **preserved verbatim** so economy analytics stays
   comparable across the boundary.
2. The ~10 surviving token functions gain a **cohort branch**: `reel_v1` writes
   `noor_balance`, everything else keeps writing `user_tokens`. `handle_new_user` mints Noor
   for `reel_v1` and 100 tokens otherwise.
3. `sync_all_user_data` emits the merged shape **while still emitting the existing token and
   scroll keys**. This is what lets already-shipped clients keep working, and it is the step
   that must not be skipped — the collision history in `20260727100300` is the precedent.
4. Extend the freemium-guard trigger to cover `noor_balance` the way it covers the token and
   bypass columns. A client-writable currency is a client-mintable currency.
   **Precision, verified 2026-07-31 — the gap is INSERT, not UPDATE.** `noor_balance` is
   *already* protected on UPDATE by `trg_cosmetics_guard` → `cosmetics_guard()`. What it is
   not covered by is `guard_user_profiles_insert_server_columns` (BEFORE INSERT), which
   guards `free_tier_cohort`, all three `weekly_pool_*` columns and `softener_notice_ends_at`
   but not `noor_balance`. Close the INSERT hole; do not re-implement the UPDATE guard.

**Tests:** pgtap for every converted function — cohort branch both ways, `>= 0` floor,
idempotency, and a guard test asserting a direct client UPDATE of `noor_balance` is rejected.

### 5.3 — The backfill (softener wave)

One idempotent migration, stamped:

```
noor_balance += (balance * token_rate) + (tier_up_scrolls * scroll_rate)
```

- Keyed by a **`currency_merged_at` stamp** on `user_profiles` so a re-run cannot
  double-credit. This is the single highest-risk statement in the plan; it must be safe to
  run twice.
- **`user_tokens` is kept intact and read-only** as the audit trail. Do **not** drop the
  table in the same change that moves the money — if a rate turns out wrong, the original
  balances must still exist.
- Batched, with a dry-run mode that reports totals before writing.

### 5.4 — Client (softener wave, except the cohort read)

- `token_service.dart` → `noor_service.dart`; one balance chip in `subpage_header.dart`.
- Streak restore priced in Noor, **ladder unchanged at 100/250/500** under a 1:1 token rate.
- Tier-up priced in Noor at the §2 repricing; `tier_up_scroll_service.dart` retired.
- Store: token and scroll SKUs retired or re-pointed at Noor packs — **gated on the Mixpanel
  `pack_purchased` check in §1.**
- `paywallPremiumBenefit4` — *"A monthly gift of tokens & scrolls"* — is **false the moment
  this lands, on the paywall W5 rebuilds.** It must be rewritten in whichever wave lands
  first; W5 owns the string either way.
- `tokens_spent_100` / `tokens_spent_500` achievements re-pointed at Noor, with already-earned
  unlocks preserved (they are rows in `user_achievements`, not derived — safe).

### 5.5 — The notice (softener wave)

One sentence in the existing 30-day softener message. Plain, once, no celebration framing —
this is a change to something people hold, and the tool register applies. It must state the
rate, that balances were converted rather than removed, and what Noor buys. It must **not**
be phrased as a gift.

### 5.6 — Cleanup (one release after the wave)

Drop the legacy sync keys, then `user_tokens`, once no shipped client reads them. Add to the
hygiene ledger in the parent plan with a review date, per the standing rule.

---

## 6. Risks

| Risk | Mitigation |
|---|---|
| Backfill runs twice, doubling balances | `currency_merged_at` stamp; dry-run first; batched |
| A rate is wrong and is discovered late | `user_tokens` retained read-only — the original numbers survive |
| Old clients break on the sync shape | Dual-emit in 5.2.3 for a full release before removal |
| Noor becomes client-writable | Guard trigger extension in 5.2.4, with a pgtap test |
| The giveaway kills the cosmetics shop | The cap in §3② ; model the totals before choosing |
| A real customer bought a pack | Mixpanel check gates 5.4; owed a direct notice, not a broadcast |

---

## 7. What "migrate at the softener wave" means, concretely

The softener wave is **already scheduled work** — §V6.10 of the plan of record commits to
migrating every existing free user onto the new free tier via one 30-day-notice wave,
executed after the T0+6wk keep decision and completed before Ramadan prep. It exists whether
or not this plan happens.

This plan **adds one more thing to that same wave** rather than creating a second one:

| | Softener wave *as already planned* | *With this plan* |
|---|---|---|
| Who | every existing free user | unchanged |
| When | after the T0+6wk keep decision | unchanged |
| Notice | 30 days | unchanged — same notice |
| Message | "your free limits are changing" | "…and your tokens are now Noor" |
| Backend | apply new tier limits | + run the §5.3 backfill |

**Mapping to the phases:** §5.1 is a decision, not a wave. §5.2 and the cohort read in §5.4
ride **W5** — they are small, additive, and invisible to existing users, because a legacy
account keeps taking the legacy branch. §5.3, the rest of §5.4, and §5.5 are the **softener
wave**. §5.6 is one release later.

The point of the split is that an existing user experiences **one** disruption, not two —
one notice, one changed day, one thing to be annoyed about — and the launch window stays
clean enough to read.

# Conversion Refactor — Net Change List & Implementation Plan

**Date:** 2026-07-23
**Source of truth:** [`2026-07-03-reel-first-conversion-refactor.md`](./2026-07-03-reel-first-conversion-refactor.md) (v6, as amended by §V6.7/§V6.8/§V6.9/§V6.10). That doc is append-only history; **this doc is the distilled net state** — every change we are actually making, then the concrete build plan. Section references (§V6.x) point back to the full rationale.

> **Rollout decision (founder, 2026-07-23, §V6.9):** the new onboarding + gate ships to **100% of new signups at release — no A/B, no control arm, no holdout.** The legacy flow stays in code only as a kill switch. Section C below reflects this; the A/B design in §V5.3/§V6.8.C is superseded.

---

## Part 1 — Every change, what & why

### A. Onboarding (treatment arm)

- **Replace the current onboarding with a reel-verbatim flow: problem-first hook screen → full reveal deck → derived questions → plan → gate.** The reels promise "tell us your problem → 2 Names that answer it," and the current flow delivers that promise once on page 0 then buries it under 19 pages. (§V5.1, §V6.1)
- **The hook screen asks for the problem (not the feeling) via ~5-6 problem-register chips + free text.** "How is your heart today?" breaks ad-scent — the reel's own language is problem language, and the existing chips are emotions, so the chip taxonomy is rebuilt. (§V5.1.1, §V6.1)
- **Add one "sign" router chip: "I can't put it into words — everything just feels heavy."** Reel 2 arrivals carry an unnamed burden and can't answer a problem intake; this chip routes them to `contract='sign'` with recognition copy instead of diagnosis copy. (§V6.1)
- **The hook screen is the ONLY routing intake; a post-reveal "Where did you find us?" tap captures `reel_hook` for measurement only.** Two competing routers (chip vs selector) would conflict, so the selector is demoted to analytics and never influences Name selection. (§V6.8.A2)
- **Build a problem → Name-PAIR map (Name₁ + Name₂ per chip), plus a curated comfort/nearness pair for the sign contract.** Reel 1 promises TWO complementary Names per problem and the existing map is single-Name — without pairs the Day-0 reveal can't keep the literal promise. (§V6.8.A1)
- **Day-0 reveal = the full pre-authored story deck: Name → story → verse → dua → shareable card; both Names shown Day 0, Name #2's deck sealed until Day 1.** The reel is verbose (Name + story + verse + dua) so a teaser under-delivers; sealing only the second *deck* keeps the D1 comeback hook while literally showing both promised Names. (§V5.1.2, §V6.2.2)
- **Sign-contract decks open with a recognition beat ("You didn't find this by accident") + a verified 2:286-theme comfort verse; recognition copy fires exactly ONCE (the deck-opening beat — the hook-chip microcopy is a subtitle, not a second recognition moment).** That is Reel 2's actual payoff — being seen and comforted — and repeating the recognition cheapens it into a gimmick. Confirm the verse is tagged in the catalog; seed via migration if absent — never AI-generated. (§V6.1 Branch A, §V6.8.A8)
- **All story decks are pre-authored and religiously verified (`name_stories` set, ~15 decks max); no runtime AI at the reveal.** Prophet/companion stories are hadith-adjacent, and runtime generation at the moment of highest trust is a fabrication risk the NEVER-fabricate rule forbids. (§V6.2.1, §V6.8.A3)
- **Bridge beats ("for the weight you named…") are authored per pair×chip, plus one authored Day-0 beat per pair on how the two Names TOGETHER answer the problem; free text maps to the nearest chip and is stored raw, never interpolated into scripted copy.** One template across all chips recreates the wall-of-ChatGPT feel, and the two-Names-together beat is the reel's actual shape. Raw text is kept for later verbatim echo only. (§V6.8.A1, §V6.8.A4)
- **Every post-reveal question derives from the stated problem and has a named code consumer; "Who else is affected?" is cut.** The old flow's failure was 8 write-only survey pages, so §G4 is binding: no consumer within 24h → no screen. "How long have you been carrying this?" now sets plan-pacing copy and rides into AI context. (§V5.1.3, §V6.2.4, §V6.8.A6)
- **The aspiration question survives ("What are you seeking?" / sign register: "What do you most want to know Him as — peace, mercy, strength, nearness?") and shapes queue rows 3-7, AI teaching-context bias, and notification content rotation.** Rows 1-2 are the promised pair, so this is the question that makes the rest of the 7-Name plan personal instead of generic. (§G2, §V6.1 Branch B, §V6.8.A1)
- **The plan screen becomes a real artifact: a server-stored `user_name_queue` of the first 7 Names (rows 1-2 = the promised pair).** Promise → artifact → verification is the trust loop; the static "crafted for you" tiles promised things nothing delivered. (§G3, §V6.8.A1)
- **The One Ship includes the D1-D7 daily-loop seam: the daily reveal consults the queue, and the D1 reveal IS Name #2's unseal deck.** Without this seam the plan screen and D1 push promise things Day 1 doesn't deliver — the user catches us breaking the promise immediately. (§V6.8.A5)
- **[AMENDED 2026-07-29 — D3]** **The journey track shows 8 stamps (7 Names + account), pre-stamped 2/8; day 7 = "Seeker of the Names" title.** Endowed progress (2 pre-stamps ≈ 34% vs 19% completion) with truthful stamps; this absorbs the old trial-journey track. (§V6.8.A8, §V6.5.4)
- **Deferred signup ships as local-first state + `persistOnboardingToSupabase` at signup — anonymous auth is cut.** Signup completion is already 99%, so anon-auth was the ship's biggest engineering risk spent on a non-leak; a stable install id is still aliased at signup so pre-signup events and RC join up. (§V6.8.E)
- **The forced 9-step tour is killed for the new flow, replaced by 2-3 dismissible contextual coachmarks — never blocking, never multi-step; suppression is keyed on the flow (not a global flag flip) so a kill-switch revert restores the tour with the legacy flow.** The tour is the funnel's biggest leak (52% completion). (§V6.2.8, §V6.8.A7 adapted by §V6.9, v1 Phase 1)
- **[SUPERSEDED 2026-07-28 — D2]** **The rating gate moves out of the pre-paywall slot to post-D1-unseal.** It currently occupies the emotional peak the paywall needs; D1-unseal is a genuine delight moment that's safer for review quality anyway. (§V6.8.A8)
- **First reveal is guaranteed Silver+ ("beginner's barakah"), with a dignity floor across the first 7 reveals — ships IN the One Ship.** Today the first pull always lands Bronze, i.e. the weakest reveal at the most important moment, and a mid-window gacha change later would violate the freeze. (§V6.8.A9)
- **The queue selects the Name, the gacha selects only the tier, and the awarded card is always the revealed Name's card; already-met Names become tier-upgrade pulls.** The three progress systems (queue, gacha, cards) previously had no reconciliation and would visibly contradict each other. (§V6.8.D4)
- **Per-user local-time day boundaries close whatever gap the shipped streak-tz work left (quests/rewards/muhasabah).** "Unseals tomorrow" and the weekly pool reset are incoherent at UTC midnight (3 AM Jakarta, 4 PM California). (§V6.8.A10)
- **Deep links (`sakina://reel/<id>`, `sakina://feel/<emotion>`) are best-effort warm-link handlers only; the hook chip is the mandatory reel-source capture; when a deep link carries `name_ids`, they override the chip's pair.** Organic reels have no attributed click, so deferred deep linking can't be load-bearing — but an attributed arrival that names its Names must get exactly those Names. (§V6.2.7, §V6.8.A1)

### B. Paywall & free tier

- **Ship a front-loaded, hard-looking, dismissible-to-limited-free paywall at the end of onboarding, with a real RevenueCat trial (Rootd hybrid).** Both current soft arms sit at the freemium median (~2.1%); the Rootd template (front-loaded + trial + secret freemium) is the proven ~5×-revenue shape with near-zero backlash. (§V5.3)
- **The trial is 7 days on every SKU, including the weekly (currently 3-day).** 3-day trials are the industry's worst-converting bucket, and taking the weekly 3-day burns the user's once-per-subscription-group intro eligibility — forfeiting the annual 7-day forever. (§V6.3.2, §V6.8.B4)
- **The annual anchor moves $49.99 → $59.99 with the new paywall.** The faith category clusters at $59.99-69.99 and under-pricing is the bigger measured risk; the gate change is the zero-marginal-cost moment to move. (§V6.3.6)
- **The paywall is multi-page, echoes the user's own problem/Name, and sells depth only — never the arc ("X of 99 met" is banned from purchase surfaces).** JTBD/feeling-echo paywalls outperform layout tests, but the journey count sells a thing that's free forever, which reads as deception after dismissal. (§V5.3, §V6.8.B2)
- **[PARTIAL — D6]** **Dismissal goes straight to home with a one-time reverent "always free" card — the ReferUnlock chain and 3s-hidden close button do NOT carry over; re-presentation is capped at ≤1 gate per session start and ≤2 offer surfaces per week.** Honoring dismissal is what makes the hard-looking gate non-coercive; the caps keep "re-present on reopen" from decaying into nagging. (§V6.3.1d, §V5.3)
- **A binding gate copy firewall: payment never buys the divine, no guilt/loss framing, scarcity stated plainly once, no countdown UI anywhere (the sole allowed clock is the system RC trial-end reminder, e.g. the Day-6 notice); enforced by a tripwire grep.** A monetization surface in a worship app is exactly where copy drift does real harm, and the pre-v6 firewall predates the hybrid gate. (§V6.3.1, §V6.7 H5 row)
- **The base reverence firewall (§H5) stays in force alongside the v6 extensions: no paid randomness ever (money never buys a random pull), no public worship leaderboards, social = praying for each other only, gamify showing up never the worship itself; plus the pinned card-tier language rule — tier vocabulary attaches to the card, never the Name ("a Bronze Name of Allah" is banned copy).** The One Ship puts a gacha-tier card award adjacent to a purchase surface for the first time, which is exactly where these lines get crossed by accident. (§H5, §V6.5.6)
- **Free forever, guaranteed: the 99 Names, verses, duas, the daily problem→Name match with full deck and share card, both promised Names, streak/lantern/widgets.** The reel's literal promise and scripture can never sit behind the gate — that's both the faith line and the growth loop. (§V6.3.3, §V6.2.3)
- **The free tier tightens for EVERYONE — new cohort at launch, all existing free users after the keep decision (no grandfathering; founder decision 2026-07-24, §V6.10): warmup 10/10/5 → ~3 per feature; the 1/day reset becomes a ~3/week pool across Reflect + Build-a-Dua; the token bypass (incl. the free Day-1 bypass) is removed.** Only 3% of users ever hit today's caps so premium is invisible; the pool makes engaged free users genuinely meet the paywall (target ≥30% of D1 users) while keeping a real taste, because payers are people who experienced depth. One tier end-state = the whole bypass subsystem and legacy cap constants get deleted instead of maintained forever. Warmup framing copy is tool-register: "your first three reflections are included — yours to keep" (never "a gift" on a monetization-adjacent surface). (§V6.3.8, §V6.8.B5, §V6.8.D2, §V6.10)
- **`discoverName` is exempt: the daily reveal keeps a 1/day free cap permanently.** It IS the daily reveal path — sweeping it into the pool would paywall the reel promise and kill the streak engine. (§V6.8.B3)
- **The weekly pool counter is server-mirrored via `sync_all_user_data`.** Usage counters are SharedPreferences today, so once the bypass (the only server-enforced leg) is gone, a reinstall would reset the pool. (§V6.8.B6)
- **No grandfathering (§V6.10 supersedes §V6.3.4/§V6.8.B7): ALL existing free users migrate to the new tier via one softener wave — 30-day notice, then new limits — executed only AFTER the T0+6wk keep decision and completed before Ramadan prep; referral/gift premium windows are untouched.** Existing users still feel nothing during the launch window (stacking their tightening onto the launch would make guardrail signals unreadable), and the review-keyword scan runs through the migration since the ~10-30 legacy AI power users are the accepted backlash risk. Rationale: one permanent free tier instead of two maintained forever; the research recommendation to grandfather actives was heard and overridden for simplicity. (§V6.10)
- **Welcome/backup offers ship after the T0+6wk keep read, specced now: a ~$39.99 first-year SKU, shown once per user lifetime at 24h, plain text.** They'd pollute the pre/post read (one-change-at-a-time), they're ARPU optimizers not architecture, and an iOS promotional offer can't reach a never-subscribed dismisser anyway. (§V6.8.B8 adapted by §V6.9)
- **The reverse trial is retired with a clean close-out: dated readout addendum (2.44% vs 1.68%), all in-flight trials honored, `reverse_trial_onboarding.dart` + `trial_expiry_service.dart` retired, `paywall_exp_arm` frozen.** Both soft arms proved the ceiling is the gate model, and a faith audience punishes clawbacks. (§V5.3, §V6.3.5)
- **`LapsedTrialSheet` is KEPT and re-paced: its "3-day" copy updates to 7-day and it wires to RC trial-lapse.** It's the store-trial winback (the strongest sub-upsell window), not reverse-trial residue — the new trial needs it at day 7-8. (§V6.8.B1)

### C. Rollout & measurement (amended by §V6.9 — ship-and-watch, no A/B)

- **The new onboarding + gate ships to 100% of new signups from release day; existing users are untouched (§B grandfathering still governs them).** Founder decision 2026-07-23: at ~21 signups/day the A/B could only detect ≥2.3× lifts anyway, and the intent is the new experience for every future install — the causal read is traded for speed, and that trade is declared, not hidden. (§V6.9)
- **The legacy onboarding + soft-gate flow stays in code behind ONE kill-switch flag (`reel_first_onboarding_enabled`) until the keep decision; flipping it back must restore the complete old experience, tour included.** With no control arm, the kill switch IS the revert path, so it must actually work end-to-end. An `onboarding_flow: 'reel_v1' | 'legacy'` super property records which flow each user really got — a kill-switch flip mid-stream makes this non-inferable from `app_version`. (§V6.9)
- **The read is pre/post against the historical baseline: trailing-90-day new-signup cohorts (signup→paid 2.44%, D1 21.9%).** T0+2wk = health read (Day-0 trial-start rate, checkout starts, paywall-encounter ≥30%); T0+4wk = first trial→paid; **keep decision at T0+6wk on D30 cohorts** (by then the first two post-T0 weeks of signups have full D30 + trial resolution + most of the refund tail). Honesty clause: no causal attribution — seasonality and reel-mix shifts are declared confounds. (§V6.9, adapting §V6.8.C2)
- **Primary metric = D30 signup→paid of post-T0 cohorts vs the trailing baseline; targets decomposed as trial-start ≥15% × trial→paid ≥30% ⇒ ≥5% signup→paid.** RC `subscription_started{is_trial:true}` never counts as revenue, and Day-0 "purchases" are now $0 trial starts — the units changed with the trial, so the baseline comparison is on paid conversion, not Day-0 events. (§V6.8.C2-3 metrics, §V6.9 denominator)
- **Guardrail stopping rules survive intact but become absolute/historical: refunds >2× trailing-30d baseline for 7 days, star trend −0.3 over 14d, D1 of post-T0 cohorts −8pts vs the trailing-60d baseline (rolling 14-day cohort AND >2×SE), any scripture-gating review cluster. Any trigger → kill-switch flip + dated log entry, no debate.** With no control these fire against history instead of an arm, which is noisier — hence the same de-noising rules and a bias toward reviewing early. (§V6.4.4, §V6.8.C4, §V6.9)
- **One-change-at-a-time replaces the formal freeze: notification Phase A goes live ≥14 days before T0 (so the immediate pre-ship baseline includes it), then NOTHING user-facing ships between T0 and the T0+6wk keep read.** Pre/post reads die if the "post" period contains three overlapping changes; the discipline survives even though the arm-asymmetry rationale is gone. (§V6.8.C1 adapted)
- **New super properties: `onboarding_flow`, `reel_hook`, `contract`, `problem_category` (chips only, never free text), `free_tier_cohort`; new people property `names_met`.** One funnel segmented by super properties is the house convention, and without reel-source capture "did we deliver the promise per audience" is unanswerable. (§V6.4.1-2, §V6.8.C7, §V6.8.C10)
- **Audience dimensions (`contract`/`problem_category`/`reel_hook`) are directional-only at this volume and never condition the keep/revert decision; the one sanctioned early cut is the sign-vs-problem split on deck completion + D1, flagged low-n.** The full audience matrix needs months of pooled data, not the first six weeks. (§V6.8.C5 adapted)
- **Event work reuses shipped spines — no `story_deck_*`, no `purchase_started`, no `paywall_dismissed`:** deck events = `reflect_beat_advanced{surface:'onboarding_reveal'}` + `reveal_deck_completed/abandoned`; checkout leak = the existing purchase-sheet chain + RC↔Mixpanel cohort reconciliation by distinct_id (denominator = post-T0 `signup_completed` with `onboarding_flow:'reel_v1'`); gate = `paywall_page_viewed{page_id}` / `paywall_closed` / `paywall_exit_offer_*`; second-Name lifecycle with `{source}`; taste events `ai_taste_consumed{allowance}` + `ai_allowance_exhausted`; stable `step_id` strings on onboarding; deck tap-skips reuse `reflect_flow_skipped{surface:'onboarding_reveal'}` with `reveal_deck_abandoned` reserved for non-tap exits. Duplicate event names would fork funnels forever, and `beat_kind` gives story-vs-verse drop-off for free. Verify-or-add the never-superseded v1 holes (`reflect_started/completed`, `names_browse_viewed`, `dua_read`) in the same pass. (§V6.4.3, §V6.8.C6-7, v1 Phase 4)
- **The declared price confound stays declared: the post-T0 period runs $59.99 + a 7-day trial vs a $49.99/no-trial baseline period — the pre/post read is of the package, and revenue-per-signup absorbs price by design.** Stated up front so nobody "corrects" the comparison mid-flight. (§V6.8.C9 adapted)

### D. Notifications, retention, reverence

- **Notification copy is rewritten in reel voice, in two phases: Phase A (now, server-only) extends the RPC to return the user's most-recent Name and frames copy as yesterday's Name; Phase B (post-ship) reads `user_name_queue` for today's Name.** The server currently has no per-user Name at send time, so "a Name for what you're carrying" today would be a false being-seen claim — exactly what the sign-copy boundary bans. (§V6.5.1, §V6.8.D1)
- **Push strings are transliteration-only (no Arabic script), with `template_id` + `copy_version` on every send; the milestone/winback template changes amend the streak-retention-v2 locked vocabulary in the same PR, never silently.** Single-string surfaces can't isolate text direction (the RTL-bleed rule), and open-rate by template is unmeasurable without version stamps. (§V6.8.D3, §V6.8.C8, §V6.8.D4)
- **Two binding copy rules extend the reverence firewall: "sign" language never appears in system-initiated copy or near a price; and no copy may attribute waiting or a stance to Allah or a Name (app artifacts wait, He does not).** The system claiming divine intent on its own schedule turns recognition into manipulation, and "Al-Wadud is waiting for you" speaks for Allah. (§V6.1.1, §V6.8.D2)
- **"Met" is defined as completing a Name's reveal deck (never card ownership), tracked server-side, surfaced as "you have met N of the 99 Names."** The 99-Name arc is Reel 2's retention spine, and without a definition the three progress systems drift apart. (§V6.5.2, §V6.8.D4)
- **The backlog is re-ranked depth-first: (1) Reflect re-entry, (2) 99-Name arc, (3) journal insights, (4) gift-a-dua (with day-one Mixpanel instrumentation + §G4 test), (5) intention/harvest appointment, (6) TTS.** Payers are 2.6-3.4× depth users, Reflect re-entry literally re-delivers Reel 1's contract, and manufactured frequency doesn't convert. (§V6.5.5, §V6.8.D5)
- **Cut outright: the reward-strip re-curve, streak-countdown Live Activity, two-chest adhkar scaffolding, churn-flag intervention, garden companion, Rive migration.** Each was justified by the retired reverse-trial choreography or is superseded by shipped work (lantern, Lottie pipeline). (§V6.5.4, §V6.7)
- **Ramadan = "30 Names for 30 Nights" with a generosity posture: 14-day trial via a seasonal RC offering (new users), offer-code campaign (existing users), `placement:'eid_recap'` paywall + Shawwal winback, cap-loosening framed as bounded from day one, reversion on Eid+3 never Eid day.** Hallow's Lent ≈25% of annual revenue proves the season, and in-window tightening in a worship month is the one unforgivable move. (§V6.5.3, §V6.8.D6)
- ~~**The feeling-first core-loop rewire (Begin Muḥāsabah → problem/feeling input → `reflectWithOpenAI`) is the FIRST item after the keep decision, not part of the One Ship.** The D1-D7 queue seam covers the promise window; the full rewire is too large to ride the launch under one-change-at-a-time. (§V6.8.A5)~~ **[OVERTURNED 2026-07-30 — D9. It rides the One Ship as W4.]**

---

## Part 2 — Concrete implementation plan

### Phase 0 — Unblock (this week, parallel tracks)

**0.1 Founder decisions — STATUS 2026-07-25: ①②③④⑤ DECIDED; only ⑥ open (non-blocking until pre-T0):**
1. ✅ Chip taxonomy — **APPROVED as the researched draft below** (6 problem chips + sign chip; hook-screen UX locked via the mock at `../mocks/2026-07-25-hook-screen-mock.html`).
2. ✅ Name-PAIR map — **APPROVED as drafted** (pairs in the table below; comfort pair Ar-Rahman + Al-Latif).
3. ✅ Deck pipeline — **author = Claude, reviewer = founder** (revises §V6.8.A3's "founder authors"): Claude drafts each deck with every story/verse/dua claim traced to a reputable cited source (hadith citations verified against sunnah.com / Quran.com at draft time — never from memory; anything not fully verifiable is flagged, not shipped); the founder reviews each deck + its sources and records sign-off per deck. Ship-gate unchanged: a chip renders only when BOTH its decks carry recorded sign-off. Verses/duas still come ONLY from the verified catalog (AI-selection rule) — authoring covers story beats + bridge copy, never scripture.
4. ✅ Day boundaries — audited 2026-07-25: streaks have per-user tz (`user_notification_preferences.timezone` + local-date column); muhasabah/rewards/usage are uniform UTC; **quests have a local-vs-UTC inconsistency bug** (rotation local, persistence UTC — fix in W1); weekly pool + local-midnight unseal are new builds on the streak-tz pattern.
5. ✅ Free-tier integers — **PINNED: warmup 3 Reflect + 3 Build-a-Dua lifetime; weekly pool 3 combined, Monday per-user local reset; `discoverName` 1/day free forever** (app_config dials).
6. ✅ Paywall — **APPROVED 2026-07-25** (`../content/2026-07-25-paywall-DRAFT.md` + mock): 3 pages (`value_depth`/`trial_timeline`/`plan_select`), contract-keyed page 1, Apple-Day-6 timeline, shipped benefits checklist on plan page, surfaces map (onboarding ceremony / condensed soft_inapp / LapsedTrialSheet separate). Adversarially reviewed (2 blockers fixed: journal-honesty, Day-5 second-clock). Aesthetics at W5 build per DESIGN.md; copy freezes at T0. **⇒ ALL SIX PHASE 0 DECISIONS CLOSED.**

> **Researched draft for ①+② (2026-07-25, awaiting founder sign-off).** Two-agent web research: evidence side (Muslim Youth Helpline 2019, N=1,077 young Western Muslims recruited via social media — the reel demographic; ISPU/Pew/Yaqeen/Khalil Center) + demand side (IslamQA/SeekersGuidance category volumes, dua-search taxonomies, viral reel framings, competitor intakes — Sabr, Hallow, Hisn al-Muslim). Convergent top struggles: anxiety (63% / #1 dua demand) · sadness-hopelessness (52%) · family conflict (47%) · far-from-Allah/iman-low (30% named UNPROMPTED; IslamQA's biggest category is Psychological & Social; no Hallow analogue — the differentiator) · sin-guilt-repentance cycles (#1 ask-a-scholar emotional topic; 31% of young men porn-guilt) · loneliness/marriage (+ 40% of men tell nobody) · rizq/money.
>
> | # | Chip | Name₁ + Name₂ | Research basis |
> |---|---|---|---|
> | 1 | "My mind won't stop racing" (anxiety) | As-Salam + Al-Wakeel | #1 on both sides (63%; top dua demand) |
> | 2 | "Everything feels heavy" (sad/hopeless/grief) | Al-Jabbar + Ash-Shafi | 52%; widened from "heartbreak" — despair-of-mercy is the Muslim-shaped layer, decks lead with mercy |
> | 3 | "I keep sinning and going back" (guilt/return) | Al-Ghaffar + At-Tawwab | #1 emotional ask-a-scholar category; shame blocks human help channels — anonymous app is the right vessel |
> | 4 | **"I feel far from Allah" (iman low / can't stay consistent) — NEW, replaces "lost/no direction"** | Al-Wadud + Al-Hadi | 30% unprompted; uniquely Muslim; zero competitor analogue; "lost/direction" ranked bottom on both sides |
> | 5 | "I'm worried about money / providing" (rizq) | Ar-Razzaq + Al-Fattah | Top-level dua-taxonomy category; MYH money/employment |
> | 6 | "No one sees what I'm carrying" (lonely/alone) | Al-Baseer + As-Samad | Covers marriage-longing + convert isolation + silent suffering (40%-tell-nobody stat) |
> | — | Sign chip (unchanged) | Ar-Rahman + Al-Latif | The "tested/hardship" viral framing IS the Reel-2 arrival; sign chip serves it |
>
> = **14 unique decks** (Al-Latif and Al-Hadi shared), within the 15 cap. **Bench (post-ship iteration, in order):** family strain (47% — strongest cut, awkward Name-pairing, weak as a first-session chip), grief-specific, sleep. **Design notes from research (binding):** no chip named waswas and no mechanic that invites same-day repeated re-checks (Khalil Center: mood→verse loops can feed compulsive reassurance-seeking — the 1/day reveal cap is protective, keep it); any future doubt chip is phrased experientially ("faith feels shaky") never intellectually; free-text keyword map must catch family/marriage/exams/sleep/grief terms → nearest chip.
3. Story author (founder) + named religious reviewer committed.
4. Day-boundary verification: what does the shipped streak-tz work already cover? (engineering audit, 1 day)
5. Pin the free-tier integers (warmup ~3/feature, pool ~3/week → exact numbers, into `app_config`).
6. Paywall page count + copy draft (must freeze before T0).

**0.2 Content production (starts week 0, the long pole):**
- Author `name_stories` decks: 2 per problem chip (the pair) + ~3 comfort Names ≈ 15 decks. Each story carries a cited source; reviewer sign-off stored per deck. Bridge beats authored per pair×chip, PLUS one pair-synergy beat per pair (how the two Names together answer the problem). Ship-gate: a chip renders only when BOTH its decks are verified; uncovered chips fall back to the comfort pair.
- Verify the 2:286-theme verse is tagged for the recognition beat in the verse catalog (`reflection_verse_catalog.dart:35` — entry confirmed present in the 2026-07-23 code audit; confirm beat tagging; if tagging is absent, seed via migration — never AI-generated).

**0.3 Notification Phase A (server-only, no app release — starts the freeze clock):**
- Migration: extend `get_eligible_notification_users` to return most-recent Name (two-step query — no FK embed, per the deploy gotchas memory).
- Rewrite templates in `supabase/functions/send-scheduled-notifications/index.ts`: daily (yesterday's-Name framing), re-engagement ("You paused at {transliteration}. Its story is still open…"), Jumu'ah (+ no-checkin fallback — never interpolate null), streak saver, milestone, winback. Transliteration only; no "sign" language; no waiting-Allah claims.
- Add `template_id` + `copy_version` to payload + server-emitted `notification_sent`; client echo lands with the One Ship release.
- Milestone/winback templates change locked streak-retention-v2 vocabulary — amend that spec in the same PR.

  **Phase A build record (2026-07-25 — code drafted, adversarially reviewed, fixes applied; NOT yet deployed):**
  - **Deviation 1 (sound, keep):** companion RPC `get_recent_checkin_names` instead of extending `get_eligible_notification_users` — the prod body of that function differs from the repo copy (an MCP-applied migration with no local .sql added the `push_enabled_last_verified_at` defense filter); `CREATE OR REPLACE` from the stale copy would have silently dropped it.
  - **Deviation 2 (review F3): the ENTIRE streak family stays on locked streak-retention-v2 vocabulary in Phase A** — the plan's saver/milestone/winback Name variants assume queue semantics ({Name} = the NEXT Name); with yesterday's-Name data they'd promise a Name the next reflection won't deliver. Streak-family personalization moves to Phase B. Consequence: NO locked-vocab spec amendment needed in Phase A (`2026-07-20-streak-retention-hardening-design.md` lines 52/75 stay true).
  - **Blocker fixed (review F1):** `name_returned='Allah'` (card id 1, live gacha path, no anchors row) could interpolate into reengagement/weekly/saver copy ("You paused at Allah…") — all named variants now anchor-gate, which doubles as the canonical-Name whitelist against junk legacy rows (F2). Regression test added.
  - **Copy decision (review F5):** daily generic = "Today's Name is waiting — whenever you're ready." (the drafted "A Name is waiting for what you're carrying today" was the exact being-seen phrase §D reserves for Phase B). Daily named variant recency-gated at 7 days (F10).
  - Tests 41/41, `deno check` clean; pgtap added (`supabase/tests/notification_recent_name_test.sql`) pinning the slug overrides + grants (F7).
  - **DEPLOYED 2026-07-25:** founder signed off the templates (final trim: "whenever you're ready" stripped from daily/reengagement bodies — v1 strings are the `reel_v1` set in `index.ts`). Migration `notification_recent_name` applied to prod + RPC smoke-tested live (NULL-row contract ✓, real users return Name+anchor ✓). Function deployed as **v20** (`verify_jwt:false` preserved; auth/cron untouched). Cron history: ~30-min cadence, all 200s. **THE ≥14-DAY FREEZE CLOCK STARTED 2026-07-25 → earliest T0 = 2026-08-08.** **✅ VERIFIED same day: nine v20 cron cycles, all 200, normal latency (RPC separately smoke-tested on prod rows). Templates are FROZEN (`reel_v1`) until the keep read.** Open-rate-by-template vs the ~1% baseline becomes readable after a few days of sends (Mixpanel `notification_sent` by `template_id`; the `notification_opened` client echo lands with the One Ship release — OneSignal click stats are the interim view).
- **Deadline: fully live and frozen ≥14 days before T0.** Template iteration happens only in this pre-window.

**0.4 Flag cleanup (EXECUTED 2026-07-25):**
- ✅ `tour_ab_enabled` deleted: prod key removed; `_resolveVariant` → always slim; `flag_tour_ab` super property retired from `registerBootstrapAnalytics`; boot prime removed; 4 test files updated (30/30 pass). `tourBucket`/`assignTourVariant` KEPT — the salted bucket backs `assignPaywallArm` until close-out.
- ⚠️ `hard_paywall_after_tour_enabled` NOT deleted — the pre-execution check found the audit's "inert" call was wrong (it drives the forced-gated tour flow via 5 direct getter reads; see table). Reclassified to post-keep.
- ✅ CLAUDE.md drift fixed: `Env.ratingGateEnabled` reference replaced with the accurate trimmed-flow description.
- Remaining: the code-side removals ride the next release (user-invisible, exempt from one-change-at-a-time; never during the watch window).

### Phase 1 — The One Ship (single release; new flow default-on for new signups, legacy flow retained behind the `reel_first_onboarding_enabled` kill switch)

**W1. Data layer (migrations first):**
- `user_name_queue` table (user_id, position, name_id, unsealed_at) + RPC writes; RLS for authed users (anon-session support cut per §V6.8.E).
- `user_profiles`: `acquisition_promise` jsonb (canonical payload `{reel_id?, hook_type, contract, problem_category?}`), `first_problem_text`, weekly-pool mirror column (hydrated via `sync_all_user_data`), `met_at` tracking for Names (or derive from `user_checkin_history`).
- Softener-wave migration (mark all existing free users, stamp the 30-day notice window end) **written + reviewed now, executed after the T0+6wk keep decision**; no `free_tier_grandfathered_at` column (§V6.10 — nobody is grandfathered).
- Local-tz gap-close: whatever quests/rewards/muhasabah need beyond shipped streak-tz (per decision 0.1.4).

**W2. Onboarding flow (Flutter):**
- Rebuild hook screen: problem chips (new taxonomy) + sign chip + free text; sets `contract` + `problem_category`; keyword-map free text to nearest chip.

  **Hook-screen UX spec (2026-07-25 — founder direction: large targets, unhurried, minimal decisions).**
  *Current-state analysis (`first_checkin_screen.dart`):* the shipped screen inverts the needed hierarchy — a 2-line free-text field is primary (position + size) with the chips as small secondary pills below it (~36px tall in a ragged `Wrap`, under the 44pt HIG minimum, lines 159-201); a decorative SVG eats ~19% of screen height (line 126); chips vanish whenever the text field focuses (line 151); and selection is a two-step commit (pick chip, then press "Reflect"). None of that survives.
  *New spec:*
  1. **Single-column list of full-width selection cards** — one chip per row, ≥64pt tall, 16px radius, ~12px gaps, generous horizontal padding. One vertical scan line, no grid; sentence-length problem labels fit on one card. 6 problem cards + the sign card = 7 total (the taxonomy cap IS the choice-overload guard — never render bench chips here).
  2. **Tap = commit.** Selecting a card advances (selected state + haptic + ~450ms beat, then the reveal loader). No separate Continue button on this screen — one decision, one tap.
  3. **Header:** "What's weighing on you right now?" + quiet subline "Take your time." **No progress bar on this screen** (precedent: the paywall pages already hide it) — a step counter on screen one signals a long form and manufactures hurry.
  4. **Illustration cut** (or reduced to a small ornament above the header) — the vertical space belongs to the choices.
  5. **[AMENDED 2026-07-29 — D4]** **Free text demoted:** a quiet "Or say it in your own words…" text-button below the list that expands the field on demand; never required, never hides the cards (§V6.1). Typed input keyword-maps per §V6.8.A4.
  6. **[SUPERSEDED 2026-07-29 — D1]** **Sign card: identical surface and spacing to the problem cards; distinction via typography ONLY** (lighter weight, secondary ink; last position in the list). Founder decision 2026-07-25 after the mock review, revising §V6.1's "visually distinct chip": a tinted surface reads as a pre-selected state (the selected state is an emerald tint) and inconsistent spacing reads as a layout bug. The sentence-length label + last position + quieter type are distinction enough.
  7. **All 7 visible without scrolling** on ≥812pt screens (compact header + no illustration makes this fit); on smaller screens allow gentle scroll with a fade hint — never shrink the cards to fit.
  8. **No urgency mechanics ever:** no timers, no auto-advance, no skip-pressure copy (§H5). Stagger-fade the cards in (~60ms/card, pattern already in the shipped screen). Accessibility: 44pt minimum everywhere, Dynamic-Type-safe labels, VoiceOver reads the full sentence.
- Reveal: pair lookup → full story deck rendered on the shipped beat spine (`BeatRevealFlow` surface `'onboarding_reveal'`); recognition beat + comfort verse for sign contract; Name #2 identity shown, deck sealed.
- Card award at reveal: guaranteed Silver+ first pull; queue-picks-Name/gacha-picks-tier wiring; tier-upgrade on already-met.
- Derived questions (problem register, consumers wired): "how long carrying" → plan pacing + AI context field; aspiration question (sign-register variant) → queue rows 3-7 + AI teaching-context + notification rotation; reminder-time question retained.
- **[AMENDED 2026-07-29 — D3]** Plan screen renders the real 7-Name queue; 8-stamp journey track pre-stamped 2/8.
- Deferred signup: local pre-auth state + `persistOnboardingToSupabase` at signup; stable install id aliased at signup (RC/Mixpanel join for pre-signup events).
- **[PARTIAL — D5]** Post-reveal "Where did you find us?" single tap → `reel_source_captured` + `reel_hook`.
- Rating gate relocated to post-D1-unseal; tour suppressed for the new flow (keyed on `onboarding_flow`, NOT a global flag flip — kill-switch revert must restore it), replaced by 2-3 dismissible contextual coachmarks (Duas tab, streak — never blocking).
- Deep-link handlers (best-effort): `sakina://reel/<id>` + `sakina://feel/<emotion>` cloning the `sakina://r/` pattern; `name_ids` in the payload override the chip pair.

**W3. Daily-loop seam (D1-D7):**
- Daily reveal consults `user_name_queue`; D1 reveal = Name #2's unseal deck on the same surface; stated feeling overrides the Name with the unseal deck offered immediately after.
- Unseal timing on per-user local midnight. Second-Name lifecycle events wired (`source:'widget'` unseal attribution may trail the ship per §V6.8.E; guardrail queries may not).

**W4. Daily-loop restructure — the loop asks (Flutter). [ADDED 2026-07-30 — D9; everything below shifted by one]:**
- Day-open order reversed: streak/lantern become ambient state on open, the question comes first, and the reward **ceremony** lands after completion. **The streak increment does NOT move** — it lives in `discoverName()`, and moving it would cost a user their streak day for abandoning after the reveal (corrected 2026-07-30; see spec M1). The rule is **grant at engagement, celebrate at completion**. `DailyLaunchOverlay` stops handing off nothing, drops its "Today's Name" card (it advertised a date rotation the reveal then contradicts seconds later) and routes into `/muhasabah`.
- The question renders in `DailyLoopStep.checkin` (today an empty slot falling through to a spinner), on the sacred canvas, with a marked exit. Not in the overlay, and **not** by reviving `answerCheckin()` — that deletion still proceeds.
- The answer writes into `DailyLoopState.checkinAnswers` before `_prefetchDeeperReflection()`, so the reflection is written about the stated problem against the queue's Name via the existing `forceName` seam. **While the queue is live (D1-D7) the answer shapes the reflection only; the queue keeps picking the Name.** After exhaustion it may pick via `ProblemChipResolver`.
- Valence-neutral question with a real good-day branch (§7 of the spec is the open decision). Chip taxonomy reused from onboarding so `problem_category` stays comparable — **not** the 30-question bank, which is a different vocabulary.
- Home: CTA above the fold and out of the divider stack, renamed to the job (muḥāsabah kept as a taught gloss, Hallow's Examen treatment), promo/stat clutter above it cut, and a real design for the completed state.
- **Prerequisite, lands first and alone:** move `markUsed` out of the CTA tap (`progress_screen.dart:988-1001`) into `discoverName()`, or a user who opens the question and backs out burns their 1/day reveal. Touches both bypass wrappers and the `state.error` refund invariant.
- **Input is free text primary** (Reflect-shaped) → `reflectWithOpenAI(text, forceName:)`; chips demoted to quick-fill. Question: *"What's on your heart today?"* with a placeholder spanning worry → thanks. **Reward is claimed at answer-submit** (the 7-day ladder resets on a missed claim, so tying it to "Ameen" would punish a half-finished session); the animated ceremony lands after. **Ships to all users**, kill-switched; Name *selection* stays cohort-scoped.
- Spec: [`../specs/2026-07-30-daily-loop-asks-design.md`](../specs/2026-07-30-daily-loop-asks-design.md) · Plan: [`2026-07-30-one-ship-04-daily-loop-restructure.md`](./2026-07-30-one-ship-04-daily-loop-restructure.md). Evidence: `docs/research/2026-07-29-daily-loop-internal-audit.md` + `docs/research/2026-07-29-day-open-loops-external-research.md`.

**W5. Gate + free tier (Flutter + RC + gating):**
- New multi-page paywall (pages per decision 0.1.6, `page_id` strings): value pages echo problem/Name, depth-register copy only; $59.99 annual anchor; the 7-day-trial offering becomes the RC default at T0 (weekly SKU trial → 7-day; exit-offer strings updated); legacy offering retained in RC for kill-switch revert.
- Dismiss → home + one-time "always free" card; no ReferUnlock chain; visible close; re-present ≤1/session start, ≤2 offer surfaces/week; no countdown UI (RC's system trial-end notice is the one allowed clock).
- `gating_service.dart` + `daily_usage_service.dart`: new-cohort config — warmup ~3/feature, weekly pool (reflect+builtDua only, server-mirrored), bypass removed incl. `claimFirstBypass`, `DailyCapSheet` premium-only variant, IAP→sub banner trigger retired for the new cohort (legacy users keep bypass behavior only until their softener window ends — then the whole subsystem is deleted, §V6.10), `discoverName` exempt (1/day permanent, all users). Dials in `app_config`.
- **⚠️ CORRECTION 2026-07-30 — the free-tier baseline is NOT 1/day, and W5 must decide this deliberately.** Every document, including this line, said `discoverName` is 1/day. It never was: the day-open CTA (`progress_screen.dart:1046-1050`) pushed `/muhasabah` with **no gate at all**, so a post-warmup free user has always had an **effective 2 reveals/day** — one unmetered day-open plus one metered re-roll — and the 5-use warmup was spent on re-rolls only. `dailyFreeDiscoverNames = 1` is correct for what it governs; it simply never governed the day-open path.
- **W4 preserved that deliberately** (Wave 1, `8241923`): the day's first reveal is free and unmetered via a `_capDay()`-keyed marker, only re-rolls are metered. Moving `markUsed` into `discoverName()` unqualified would have charged the day-open reveal for the first time ever and halved the free tier for every existing user, unannounced, in the same wave that restructured the reward claim specifically to avoid an unannounced takeaway.
- **So a genuine 1/day is a real tightening and it is W5's call to make openly** — not something to inherit from a line that was wrong. If W5 does tighten it: **the day-open path must remain ungated**. It is where the app asks what is on the user's heart, and that surface must never be able to answer a disclosure with a cap sheet. That is a safety property, not an economic one, and it currently holds *structurally* because the day-open reveal consults no gate whatsoever.
- **⚠️ Correction 2026-07-31 — the W5 build line above (`discoverName` exempt, "1/day permanent, *all users*") is superseded by D10②.** D10 makes the genuine 1/day + 3-re-roll warmup **`reel_v1`-only**; legacy accounts keep today's effective 2/day until the softener wave, per §V6.10's one-disruption rule. Read "all users" there as pre-dating that decision — anyone implementing from that bullet would ship the tightening to the existing base unannounced, which is the exact outcome §V6.10 and the W4 note above exist to prevent.
- `LapsedTrialSheet`: "3-day" copy → 7-day; wire to RC trial-lapse for the new flow's store trial.
- Reverse-trial close-out: readout addendum written; in-flight `trial_premium_until` honored; flag flip only after both; retire `reverse_trial_onboarding.dart` + `trial_expiry_service.dart` after last in-flight trial + winback grace; delete the `reverse_trial_experiment_enabled` config key + `assignPaywallArm` + the `paywall_experiment_assigned` dedup key; freeze `paywall_exp_arm`.

**W6. Instrumentation (rides the same release):**
- Constants in `analytics_event_names.dart`; emit via `onAnalyticsEvent` hook. Super properties at boot/capture: `onboarding_flow`, `reel_hook`, `contract`, `problem_category`, `free_tier_cohort`; people property `names_met`.
- Events: `reel_source_captured`, deck events on the beat spine (`beat_kind` gains `recognition`/`comfort_verse`), `reveal_deck_completed/abandoned`, `second_name_teased/unseal_available/unsealed{source}`, `paywall_page_viewed{page_id}`, `paywall_viewed{placement:'onboarding'}`, `paywall_closed`, `ai_taste_consumed{feature, allowance, remaining}`, `ai_allowance_exhausted`, `free_tier_entered`, stable `step_id` on onboarding steps, install→signup (ASC), RC↔Mixpanel cohort-reconciliation query (post-T0 `signup_completed` × `onboarding_flow`) documented in the readout doc.
- Debug-assert: `ai_bypass_offered` never fires for a new-cohort user.
- Verify-or-add the never-superseded v1 Phase-4 holes: `reflect_started/completed`, `names_browse_viewed`, `dua_read` (Reflect was zero-instrumented at diagnosis; confirm what shipped work already covers before minting).

**W7. Pre-ship QA gates:**
- Tripwire grep extended: firewall patterns ("sign"/"meant for you" near price, "waiting for you"+Name adjacency, countdown UI, guilt phrases, "X of 99" on purchase surfaces, tier-word+Name adjacency e.g. "Bronze Name") + `check_no_fake_strings.sh`.
- Refresh `docs/qa/ui-map.md` for the new onboarding (it still documents the legacy 27-page indices and the One Ship makes it more stale).
- Acceptance test (must pass on device): a reel-install user who pays nothing and dismisses everything still receives BOTH promised Names with full decks within 48h.
- Deck ship-gate verified: every rendered chip has two verified decks.
- Both-contract walkthrough (problem chip vs sign chip) on simulator; RTL/Arabic isolation check on all new surfaces; physical-device StoreKit run for the 7-day trial.

### Phase 2 — Launch & watch (§V6.9: 100% ship-and-watch, no arms)

1. Confirm notification templates live ≥14d and stable; snapshot the baseline (trailing-90d new-signup cohorts: signup→paid, D1/D7, paywall-encounter, review velocity, refund rate) into the readout doc BEFORE release. Declare T0.
2. Release: new flow default-on for 100% of new signups; kill switch verified working on device (flip → complete legacy experience incl. tour) before submission. Existing users unaffected.
3. Daily guardrail watch vs the snapshotted baseline (reviews, refunds, D1 of post-T0 cohorts — rolling 14d + 2×SE); weekly review-keyword scan. **Any stopping rule → flip the kill switch, log a dated entry, diagnose before re-launch.**
4. Reads: T0+2wk health (Day-0 trial-start rate, checkout starts, paywall-encounter ≥30%) · T0+4wk first trial→paid · **T0+6wk keep decision** on D30 cohorts vs baseline (≥5% signup→paid target; honesty clause: pre/post, not causal).
5. Between T0 and the keep read: NOTHING else user-facing ships (one-change-at-a-time). Emergency changes get a dated readout-doc entry; their date becomes a segmentation boundary.

### Phase 3 — After the keep decision (T0+6wk)

- **On keep:** delete the legacy flow (see hygiene ledger below) → execute the all-users softener wave (30-day notice → new tier for every legacy free user; schedule so it completes before Ramadan prep; review-keyword scan runs through it) → ship welcome/backup offers (~$39.99 first-year SKU, once-ever, 24h) via ship-and-watch → Phase B notifications (queue-based "a Name for what you're carrying") → ~~feeling-first core-loop rewire (v1 Phase 2) as the first big rock~~ **(moved into the ship as W4, D9)** → 3d-vs-7d trial only as conditional ship-and-watch if leakage concentrates late.
- **Backlog, depth-first (signal-gated):** Reflect re-entry → 99-Name arc → journal insights → gift-a-dua (instrumented, §G4 test) → intention/harvest appointment → TTS.
- **Ramadan (design ~Nov-Dec 2026):** seasonal RC offering (14-day trial), offer-code campaign, eid_recap paywall + Shawwal winback, Eid+3 ramp-down; Jumu'ah beat earlier (mostly shipped).

### Standing rule — flag & dead-code hygiene (§V6.9 companion decision)

- **At most ONE live product kill-switch/experiment flag at a time.** At ~21 signups/day there is never statistical room for two anyway; the volume constraint is the bloat constraint.
- **Every flag ships with a pre-registered deletion task and a review date.** A flag with no deletion date is a permanent config knob and must be named/justified as one (e.g. the V6.3.8 pool dials in `app_config` are knobs, not flags).
- **Loser code is deleted within one release of its decision.** Post-keep iteration is version-gated by `app_version` (ship-and-watch), never by new flags — the flag matrix does not grow.
- **Current deletion ledger:**
  - Now (Phase 0.4): `tour_ab_enabled` + `hard_paywall_after_tour_enabled` keys and their read sites (dead per the 2026-07-24 audit).
  - After the last in-flight reverse trial + winback grace: `reverse_trial_onboarding.dart`, `trial_expiry_service.dart`, the `reverse_trial_experiment_enabled` key + `assignPaywallArm`; `paywall_exp_arm` frozen (Mixpanel history only, no code).
  - After the T0+6wk keep decision: the entire legacy onboarding flow (dead pages included), the guided-tour code, the legacy config keys (`onboarding_trim_enabled`, `guided_tour_enabled`, `post_tour_paywall_mode`), the `reel_first_onboarding_enabled` kill switch itself, the legacy RC offering, the dormant `answerCheckin()` path (already flagged for deletion in CLAUDE.md — this is its trigger).
  - After the softener wave completes (~keep decision + 60d): the entire token-bypass subsystem (`claimFirstBypass`, `reserveBypass`, the `DailyCapSheet` token slot, the IAP→sub banner trigger, `ai_bypass_*` events) + the legacy cap constants + the `free_tier_cohort` branch — one free tier remains (§V6.10).
  - On revert instead: the same ledger applies to the new-flow code after diagnosis — no zombie half-flows.

**Flag inventory & retirement timeline (audited against prod `app_config` + code, 2026-07-24):**

| Key | Prod value | Gates | Fate |
|---|---|---|---|
| `tour_ab_enabled` | *(deleted 2026-07-25)* | slim-vs-full tour A/B (concluded) | **DONE** — key deleted from prod, A/B branch removed, `flag_tour_ab` super property retired |
| `hard_paywall_after_tour_enabled` | `true` (**LIVE** — 2026-07-25 correction) | NOT inert: read directly in 5 places (`app_shell.dart:205`, `progress_screen.dart:163`, `onboarding_provider.dart:547`, tour overlay host, onboarding screen) where it drives the FORCED-GATED tour flow; `post_tour_paywall_mode` overrides it only for the paywall-mode derivation | Reclassified: survives as a legacy-flow key for the kill switch; deleted **post-keep** |
| `reverse_trial_experiment_enabled` | `true` | reverse-trial arm assignment | Deleted at the **reverse-trial close-out** (pre-T0), with `assignPaywallArm` + the `paywall_experiment_assigned` dedup key |
| `onboarding_trim_enabled` | `true` | 20-page vs 27-page legacy onboarding | Survives as part of the kill-switch legacy flow; deleted **post-keep** |
| `guided_tour_enabled` | `true` | tour rendering (legacy flow) | Survives for the kill switch; deleted **post-keep** |
| `post_tour_paywall_mode` | `soft` | legacy soft-gate mode | Survives for the kill switch; deleted **post-keep** |
| `bypass_token_cost` / `max_bypasses_per_day` | `25` / `2` | server-side bypass RPC dials | Deleted **post-softener-wave** with the bypass subsystem (§V6.10) |
| `reel_first_onboarding_enabled` | *(new)* | THE kill switch for this ship | Added at T0; deleted **post-keep +1 release** |
| free-tier dials (~2 keys: warmup-per-feature, weekly-pool size) | *(new)* | §V6.3.8 integers | **Permanent config knobs** (declared as such — no deletion date needed) |
| `RAMADAN_GIFT_ENABLED` (compile-time Env) | `true` | Ramadan/Eid gift card surface | Permanent seasonal knob |

**Count trajectory:** 8 keys today → 6 after the immediate cleanup → ~8 during the watch window (kill switch + dials added, reverse-trial key gone) → 4 post-keep → **2 permanent knobs** post-softener-wave (+1 env knob). Doc-drift note: CLAUDE.md still cites `Env.ratingGateEnabled`, which no longer exists — the rating gate is hardcoded in the page list today (and relocates post-D1-unseal in the One Ship); fix the CLAUDE.md line when touching onboarding docs.

---

## Divergence log — code vs this plan (2026-07-29)

Audited by walking every W1/W2 line item against what is committed on
`feat/reel-first-w2-onboarding`. Recorded here rather than rewritten inline so the
original intent and the reason it changed both stay legible. Each entry names the
decision date and where the truth now lives in code.

**D1 — Sign card has NO visual distinction.** Founder call 2026-07-29, reversing the
2026-07-25 "distinction via typography ONLY (lighter weight, secondary ink)". Reason:
the lighter grey type — plus a hairline break added on 2026-07-29 and removed the same
day — lifted the row out of the list into an implied "other" bucket sitting directly
above the free-text link, so two *opposite* affordances read as duplicates ("I can't put
it into words" = *I don't want to type*; the link = *I do*). The row is now the seventh
feeling, styled identically, still last. Pinned by
`test/features/onboarding/screens/hook_list_uniformity_test.dart`, which defends
uniformity precisely because the failure mode is gradual re-differentiation.

**D2 — Rating gate STAYS in onboarding.** Founder call 2026-07-28. Placed *after* the
plan screen so it lands on the payoff rather than before it. Post-D1-unseal is a W3
surface that does not exist yet, so relocation had nowhere to go. Note recorded during
Wave F: despite its name `rating_gate_screen.dart` is not a two-step "are you enjoying
Sakina?" gate — it calls `InAppReview.requestReview()` directly, and iOS rate-limits to
3 prompts/365 days, so placement genuinely burns attempts.

**D3 — The journey track is a filling bar, not eight stamps.** Founder call 2026-07-29.
The 8-total / 2-earned *semantics* are unchanged; only the rendering is. Eight dots read
as a count of things rather than as progress, which produced the founder's actual
question — "why does it say 2 of 8 when the screen above says you know 10?". Same
change gave the plan screen the progress bar it had been excluded from
(`onboardingReelTotalSegments` 14 → **15**, new `onboardingReelPlanSegment`).

**D4 — Free text is a modal, not an inline expanding field.** Founder call 2026-07-29.
The inline field expanded *below* seven options, so on a device it opened under the fold,
the screen auto-scrolled to find it, and the keyboard then covered the rows just read —
while leaving all six options live during a sentence about the hardest thing in someone's
week. Now `showFreeTextDialog`: blurred canvas (dark-emerald scrim, never black),
autofocus, circular emerald check. `HookFreeTextBlock` collapsed to a single link, and
its label changed to "Or describe it yourself…" so it stops echoing the row above it —
that row keeps its wording because the sign contract's shipped reveal answers it directly
("You couldn't put it into words…", `assets/content/name_stories.json`).

**D5 — `reel_hook` is NOT shipped; the event name differs.** The screen exists and sits
at the flow's lowest-emotion point, but emits `reel_source_selected{source}` rather than
the specified `reel_source_captured`, and **no `reel_hook` super property is registered
anywhere**. Consequence: the answer tags one event instead of segmenting the funnel —
which matters, because this doc calls reel-source capture "the plan's biggest measurement
hole". Deferred to W6; setup steps (including that organic Instagram gives the app
nothing to capture, and ASC Campaign Links as the free first-party substitute) are in
`TODO.md`.

**D6 — Part of the §B dismissal item shipped early, in the W2 timeframe.** The
ReferUnlock chain is **deleted** (2026-07-29) rather than waiting for W5: its card
advertised a 7-day trial against a THREE_DAYS App Store offer, its "Start free trial" CTA
called `Navigator.maybePop()` and started no trial, and it asked a user who had declined
twice and never used the app to recommend it to three friends. Still outstanding from the
same bullet: the **3s-hidden close button** (`_closeButtonRevealDelay` is still live) and
the one-time reverent **"always free" card**, which does not exist. Do both with W5.

**D7 — New decision not in this plan: the referral share ask is gated on consistency.**
`resolveReferralNudge` now requires `currentStreak >= 7` — the app's own first streak
milestone, the one that unlocks the title "Consistent" — instead of an active RevenueCat
entitlement plus a 2-day grace. Free users can now be asked; day-1 subscribers cannot.
Rationale: a payer on day 1 has bought a promise, a free user on day 7 has kept a habit,
and only the second has something to vouch for. The old audience comment's "never
gift/referral" exclusion was NOT ported — on inspection it blocked ordinary A→B→C
referral chains rather than abuse, and `apply_referral` already blocks self-referral
server-side.

**D8 — Interim paywall work, to be reverted by W5.** The existing paywall was trimmed to
one viewport (duplicate honest-billing paragraph, "No payment due today", the "YOU'RE 1
STEP AWAY" eyebrow and the "Everything premium unlocks" label all removed) so Restore /
Terms / Privacy reach the thumb, and its trial copy was corrected from 7 days to **3**,
matching App Store Connect (`sakina_sub_annual`, subscription 6762153970, FREE_TRIAL /
THREE_DAYS; both RC subs P3D). A latent bug surfaced during the trim: the microcopy
hardcoded the annual package and the literal "/year", so selecting Weekly quoted the
annual price. **W5 moves the real offering to 7 days — the corrected copy must flip back
in the same change that updates RevenueCat, not before and not after.**

**D9 — The feeling-first core-loop rewire is folded INTO the ship as a new W4; gate + free
tier and everything after it shift by one.** Founder decision 2026-07-30, overturning
§V6.8.A5's deferral of the rewire to the first post-keep slot. Two facts drove it. First,
**the deferral was never about product doubt** — this plan calls the rewire *"the retention
fix"*, ranks it **#2 of 5** and estimates ~1 week; it was deferred purely for measurement
hygiene, because the ship's read is pre/post with no control arm. Second, **that freeze is
defined relative to T0, and T0 has not happened**, so folding it in before release does not
break one-change-at-a-time — it enlarges what the keep read measures as a single unit.
Weighed against a **D0→D1 return rate of 31%** (69% never come back — the largest leak in
the funnel by volume, and one of the two pieces the diagnosis names as broken), waiting six
weeks to fix the loop that leak flows through was the worse trade.

**The price, recorded so it is not rediscovered at the keep read:** we will know whether the
ship worked; we will **not** be able to separate the paywall's contribution from the loop
change's. Consequence for W6: the within-wave funnel (question shown → answered → reveal
completed) has to carry the attribution weight the cohort read cannot, so it is not optional
instrumentation.

Full design, including the two decisions still open (where the reward ceremony lands; what
the good-day answer returns): [`../specs/2026-07-30-daily-loop-asks-design.md`](../specs/2026-07-30-daily-loop-asks-design.md).
Two corrections to earlier claims are recorded there: the 4-question check-in was removed as
**unreachable dead code**, not on user evidence (and the EMA meta-analysis says it would not
have failed on question count either), and the good-day branch needs **no newly authored
scripture** — `normalizeApprovedVerses` already constrains the AI to an approved catalog that
covers the gratitude Names.

**D10 — W5 founder decisions, 2026-07-31 (paywall build kickoff).** Four calls, taken after
the live App Store Connect / RevenueCat config was read rather than the plan's text.

*① The $59.99 anchor is CUT — annual stays at **$49.99**.* The plan asserted a $59.99 anchor
in the W5 bullet and the approved paywall draft. ASC actually sells `sakina_sub_annual` at
**$49.99** (verified 2026-07-31; AED 199.99 in the AE tier), and `app_strings.dart` agrees
(`paywallAnnualPrice`, `paywallAnnualPerWeek = $0.96`). Shipping the drafted page would have
been a **20% price rise smuggled inside a paywall redesign** — a separate decision with its
own rules for existing subscribers (price preservation or consent, and they can decline).
Founder: do not raise it. Consequence: the paywall copy uses $49.99 / $0.96 a week, the
"Save 50% vs weekly" claim is restated so the math is checkable against the weekly row, and
**W5 loses the price-migration task entirely**. The 3→7-day trial change now stands alone.

*② `discoverName` becomes a genuine 1/day, with a 3-re-roll warmup.* Resolves the ⚠️
2026-07-30 correction above. The day-open check-in is **one per day, free, permanently
ungated** — no gate consulted, per the safety property. A *second* Name the same day is
premium, after a **lifetime warmup of 3 re-rolls** (option (a); the alternative, premium from
minute one, was rejected because a gate nobody has bumped into sells nothing — same reasoning
as the ~3 warmup on Reflect and Build-a-Duʿā). New cohort only; existing users keep today's
effective 2/day until the softener wave. Supporting argument recorded at decision time: while
the D1-D7 queue is live, a free re-roll lets the user pull a Name **out of the order the plan
screen just promised them**, so removing it makes the queue's promise coherent rather than
merely cheaper. Streaks are unaffected — W4 grants the streak day inside `discoverName` at
engagement, and one reveal a day is one grant a day.

*③ Two shipped strings become FALSE the moment the weekly pool ships — fix in the same
change.* Both cap sheets promise a **daily** reset:
`DailyCapSheet._body` — *"Tomorrow's reflection is on us. Or unlock unlimited now."* — and
`WarmupExhaustedSheet._body` — *"From tomorrow you'll get one a day. Or unlock unlimited
now."* Under a 3-per-week Monday-reset pool, tomorrow is **not** on us and you do **not** get
one a day. This is the app breaking a promise on the surface where it asks for money, so it
is a blocker on the pool, not follow-up polish. (Found by tracing the cap path for the
founder's question about what a capped user actually sees; it was on no wave's task list.)

*④ Cap behaviour after W5: paywall only, no tokens.* Recorded because the current behaviour
was not written down anywhere. Today `DailyCapSheet` renders **"Unlock unlimited"** →
`GoRouter.push('/paywall')` as the primary, a **25-token bypass** as a middle slot, and
"Maybe later". There is **no route from that sheet to buying tokens** — under 25, the middle
button simply goes dead with a hint, which is a dead end. W5 removes the middle slot for the
new cohort, leaving headline + paywall + dismiss. The paywall it opens must be the condensed
**`soft_inapp`** placement with a trigger-specific line, never the 3-page ceremony mid-task.

*Open, created by ④ — the token economy loses its main sink.* Audited 2026-07-31: tier-up
cards cost **scrolls**, lantern cosmetics cost **Noor**, and neither touches tokens. After the
bypass is deleted the **only remaining token sink is the paid streak restore**
(`streak_rescue_sheet.dart:292`). Tokens are still sold as IAP (`sakina_tokens_100/250/500`),
premium still advertises *"A monthly gift of tokens & scrolls"* (`paywallPremiumBenefit4`),
and two achievements (`tokens_spent_100/500`) become near-unreachable. Selling a currency
whose main use we just removed is the one outcome to avoid; needs a founder call before the
bypass deletion lands.

**D11 — The exit-offer sheet SURVIVES v1, against the approved paywall draft. Founder
decision 2026-07-31.** The W5 paywall rebuild deleted `_ExitOfferSheet` and its ✕
interception, correctly: the approved draft (`../content/2026-07-25-paywall-DRAFT.md`) says
dismissal is "✕ → home directly", and its own firewall self-check reads **"scarcity: none (no
offers in v1)"**. A weekly downsell fired by tapping ✕ is exactly the backup offer that rules
out. The agent read the source of truth right.

**Overridden deliberately, and the reason is the interesting part: nobody knows what it
earns.** It has been shipping for months against zero instrumentation — the events exist
(`paywall_exit_offer_shown` / `_accepted`) but were never wired to anything that could answer
"is this working". Deleting an unmeasured revenue mechanic is a revenue decision made blind,
and the draft's no-offers rule was written on reverence grounds without a number to weigh
against it. So: **keep it, instrument it, decide at the T0+2wk read with data instead of
taste.**

Consequences recorded so the two documents do not silently disagree:

- **The draft's firewall self-check line "scarcity: none (no offers in v1)" is now FALSE for
  the shipped app.** Treat it as superseded by this entry rather than as a rule the code
  violates. Every *other* firewall clause still binds — no countdown, no guilt, no arc-count,
  no tier-word-beside-a-Name, nothing attributing a stance to Allah or a Name.
- **The instrumentation is the condition of the reprieve, not a nice-to-have.** `shown` and
  `accepted` alone cannot answer the question: they give a ratio with no view of the refusal
  path, and "accepted" means a CTA tap, not money moving. Required: a `declined` event firing
  on **every** route out of the sheet (button, scrim, back gesture — a missed route
  understates declines and flatters the mechanic), `{placement}` on all three, and an
  accepted→purchase link riding the **existing** purchase-sheet chain so the funnel reads
  shown → accepted → started → completed. A parallel purchase event is forbidden; forking a
  live funnel is permanent.
- **Trial duration stays store-derived.** The restored strings keep the `{trial}` templating
  from the rebuild (`paywallExitOfferBodyTemplate` / `AcceptTemplate`), so reviving the sheet
  cannot revive a hardcoded "3 days".
- **Scope is unchanged from prior behaviour** — soft surfaces only. It is not added to the
  hard wall or the onboarding ceremony.
- **Review at T0+2wk** alongside the health read. If the accepted→completed rate does not
  justify it, delete it then as a measured decision — and the draft's line stops being false
  by becoming true again.

Also settled the same day: **the annual savings claim was arithmetically wrong.** Approved
copy said "Save 50% vs weekly"; verified against RevenueCat, annual is **$49.99** and weekly
**$4.99** (= $259.48/yr), an **80.7%** saving. The mock's own rationale was that the chip is
"checkable against the weekly row right below it" — it failed its own test, and understated
the strongest argument for annual on the screen where the choice is made. Founder: **"Save
80%"**.

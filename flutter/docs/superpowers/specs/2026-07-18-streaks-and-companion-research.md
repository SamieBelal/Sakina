# Streaks + Companion (Avatar) — Retention Research & Structure

**Date:** 2026-07-18
**Purpose:** Research-backed structure for the two biggest retention investments in the reel-first plan (`2026-07-03-reel-first-conversion-refactor.md` §C rows 4/5/7): a **streak system** and a **non-figurative companion/avatar**, both tuned to make Sakina maximally retentive *while staying reverent*. Includes the verified answer to "can we use Lottie?".
**Method:** 4 parallel research agents (animation tech; Duolingo teardown; grow-and-tend companion apps; behavioral science + ethical guardrails). All claims sourced; a few figures are secondary-sourced (flagged).

---

## 0. TL;DR decisions

1. **Animation tech (the explicit ask):** Lottie is fine **in-app**, but (a) **Rive is the better tool for the state-driven companion** specifically (a streak *number* drives the visual — that's Rive data-binding's exact use case), and (b) **NO animation engine — Lottie or Rive — runs in a home-screen/Lock-Screen widget**; the widget must show **pre-rendered PNG frames** per streak state. The in-app "I tested Lottie" experiment cannot have surfaced (b).
2. **Streaks:** you already have a streak system + streak-on-widget. The high-leverage work is **streak *defense* + endowed onboarding + reverent framing** — the forgiveness layer *is* the retention strategy, not a concession.
3. **Companion:** **non-figurative garden (jannah imagery) as the long-run collection + an illuminating khatam as the per-cycle "current work" object.** The tend action = the daily muḥāsabah you already ship. Loss = *wilt/dormancy, never death*.
4. **Reverence is the moat, not a constraint.** Gamify *showing up* (istiqāmah/dhikr), never the worship act. Private by default, no leaderboards, no hasanat counter, no guilt pushes.

---

## 1. Animation tech — CAN we use Lottie? (verified)

### In-app (reveal, companion screen, milestones)
- **Lottie works** and can be polished. Flutter `lottie` supports controller-driven playback, **named markers/segments** (one file → `seed`/`sprout`/`bloom`/`wilt`/`protected` frame ranges via `LottieComposition.markers`), and runtime recolor/text via `LottieDelegates`/`ValueDelegate`. Pitfalls: delegates address layers **by name** (brittle — a designer rename silently breaks a recolor), masks/mattes are the CPU-expensive part (a lush garden is exactly that), and **all state logic lives in your Dart** (Lottie has no state machine).
- **Rive is the better fit for the *state-driven* companion.** Rive Flutter 0.14.0 (Dec 2025) shipped **data binding** — bind one `streakLength`/`growth` number and the artwork's seed→bloom→wilt transitions are declarative + **owned by the designer**. Plus ~10–15× smaller files and better perf for complex art (directional benchmarks: Rive ~60fps vs Lottie ~17fps on a weak device). **Caveat (matches CLAUDE.md):** Rive-Flutter has an **open font-fallback gap** and unreliable Arabic shaping → **keep 100% of Arabic in Flutter `Text`** (`AdjustedArabicDisplay`) layered over the Rive canvas. Our companion is non-figurative/non-textual, so this is clean.
- **Tradeoff, honestly:** Lottie/After-Effects talent is abundant + cheap and **we already have a working Lottie pipeline** (`~/lottie-lab`, text-to-lottie). Rive needs a **specialized designer + new toolchain** (art must be authored in Rive's editor; no free AE import).

### The widget (iOS home + Lock Screen; Android)
- **Neither Lottie nor Rive can run in a widget. Verified.** iOS WidgetKit renders SwiftUI views as **archived static snapshots** and **rejects any UIView-backed view** (`PlatformViewRepresentable`) — both the Lottie and Rive iOS runtimes are UIView-backed → they throw. Android home-screen widgets are `RemoteViews` (Jetpack Glance compiles to RemoteViews) — **no continuous animation**.
- **What a widget CAN do "for free":** timeline-entry diffs with an implicit spring, `contentTransition(.numericText())` for the streak counter, and **`Text(timerInterval:)`** (a live countdown, which we already use on the Duʿā widget). Nothing frame-driven.
- **So the widget companion = pre-rendered PNG frames**, one per streak state (`seed`/…/`bloom` + `wilt` + `protected`), rasterized in-app (from the Lottie/Rive art) and shared via App Group, swapped via a **multi-entry precomputed timeline** (`now: OK → 8pm: at-risk → midnight: lost`). **This is exactly how Duolingo's "animated" widget works** — a state-selected pre-rendered owl image per timeline entry, not a live animation.

### Verdict per surface
| Surface | Tool | Note |
|---|---|---|
| In-app companion / reveal | **Rive** (data-bind streak → visual); Lottie-with-markers a viable fallback | keep Arabic in Flutter `Text` |
| Milestone celebrations | **Lottie** (one-shot; reuse existing pipeline) | Rive fine too |
| Home / Lock-Screen widget | **Pre-rendered PNG per state** + timeline; NO live Lottie/Rive | à la Duolingo |

> Sources: Rive 0.14.0 data binding; Rive feature-support (Flutter font-fallback gap, issue #404); lottie-ios discussion #2403 (WidgetKit rejects PlatformViewRepresentable); Apple "Animating data updates in widgets"/WWDC23; Android Glance→RemoteViews docs; duoplanet/Medium Duolingo-widget teardowns.

---

## 2. What actually drives retention (the mechanisms, sourced)

- **Endowed-progress effect** (Nunes & Drèze 2006): a pre-stamped card hit **34% vs 19%** completion. → *Never start a user at "Day 0 / empty garden."*
- **Loss aversion + sunk cost + Zeigarnik** — the "don't break the chain" engine (loss hurts ~2× a gain). Most powerful *and* most abusable lever.
- **Hook model** (trigger→action→variable reward→investment). Sakina's trigger is *internal + emotional* ("a Name for what you're carrying today") — the most durable, no-push-needed kind.
- **66-day habit curve (Lally 2010): a single missed day is statistically invisible** to habit formation; only 2–3 consecutive misses hurt. → **Scientific mandate against hard-resetting a streak on one lapse.**
- **Grace increases effort (counter-intuitive core):** Duolingo streak-freeze users average **17.19 vs 11.62 on-streak days (+48%)**; capped freezes *raised* DAU; Weekend Amulet **+4% weekly return / −5% streak loss**. **Slack is the retention strategy.**
- **Duolingo hard numbers:** 7+ day-streak share nearly **tripled to >half of DAU**; **CURR +21% over 4y (>40% fewer daily-churned power users)**; DAU **4.5×**; **Streak Wager +14% D7**; a single **milestone animation ≈ +1.7% D7** (secondary-sourced). Streaks = *"the single most effective retention lever."*
- **Companion loops:** **Finch D1/D7 ≈ 54%/37%** (beats Duolingo; vs ~70% of wellness apps abandoned in 30d) on a **zero-punishment** loop (the pet never dies/wilts). **Forest** (60M+ users) uses the *same object as reward and scar*. **IKEA/endowment effect**: naming/customizing drives attachment — **but the effect is erased if the creation is destroyed/reset** → *wilt, don't kill.*

---

## 3. STREAK structure (recommended)

- **Endow at start:** onboard on **Day 1 with the garden already sprouted + 1–2 Names pre-revealed** — never "Day 0."
- **Low daily bar, decoupled:** one muḥāsabah / reflection keeps the streak (Duolingo's "one lesson" floor). The streak stays visually *secondary* to the day's Name/verse.
- **Forgiveness layer, built in from day one (this IS the strategy):**
  - **Streak freeze** — auto-equip 1–2, **silently auto-consumed** on a 1-day gap (idempotent server-side); framed as "your garden is protected."
  - **48h repair via *effort*** — restore a lapsed streak by *doing a reflection*, **never by paying** tokens/money (monetizing spiritual anxiety is the hard line).
  - **Soft-decay, never hard-reset** — keep "best streak" + "total days of return" that never zero. A miss is noise, not failure.
  - **Menstruation pause** — near-standard in reverent Islamic apps (Pillars, Deeny); an excused day never breaks the streak.
- **Loss framing:** dormant/dim, fully reversible. Copy = **"you've returned 47 of the last 50 days,"** not "streak broken." Hit the **first-24h-after-lapse** window (it decides long-term retention) with a **gentle** invitation, not pressure.
- **Milestones:** rare, earned celebration at **7 / 30 / 100 / 365** (or Islamically resonant counts) — invest disproportionately in a *few* beautiful moments (Lottie) + a subtle haptic.
- **Widget:** streak indicator + today's Name; the **"not done yet" state is inviting/calm** (an unlit lamp waiting to be lit), **never a panicking character**. (We already carry `streak` + `done/pending/atRisk` on the Name widget — extend, don't rebuild.)
- **Reverence:** gamify **consistency of presence/dhikr (istiqāmah)**, never the worship act. **Private by default — NO public leaderboards (riya' hazard). Never show a hasanat/reward count** (Quranly's backlash). Frame copy toward Allah.
- **AVOID:** guilt/shame pushes, midnight "your streak dies!" alerts, selling streak protection, letting the number eclipse the practice.

---

## 4. COMPANION / avatar structure (recommended)

- **Form (non-figurative, theological):** **a garden framed as jannah imagery** (the long-run accumulating collection) **+ an illuminating khatam** as the per-cycle "current work" object (the goal-gradient near-complete pull). Garden is *scripturally licensed* (dhikr → "plants trees in Jannah" hadith; Quranic jannah imagery). Khatam is the safest/most abstract. **Tree** (kalimah ṭayyibah, Ibrāhīm 14:24 — "a good word is like a good tree") is the single most 1:1 theological mapping if we want one object.
- **The loop (Finch, made reverent):** the **tend action = the daily muḥāsabah you already ship** → it *waters the garden* / *illuminates the next khatam node*. **Same gesture = spiritual act + growth + reward** (the strongest lever). Extra acts (dua/journal/dhikr) generate **overflow "light/water" → cosmetic currency** so nothing done is wasted (Finch's overflow rule).
- **Effort-gated, not calendar-gated:** growth advances by **# of muḥāsabah completed**, not days elapsed — a returning user still progresses, never feels behind.
- **Growth stages (legible, denser over time):** seed → sprout → leaf → bloom → fruiting → **a garden of varied, Quranically-named species** (grapevine, datepalm, pomegranate). Khatam: illuminate node-by-node → a completed star → a **gallery of completed khatams** (the collection axis).
- **Loss:** **dormancy/dimming, fully reversible — never death or reset** (killing the creation erases the IKEA-effect attachment). No countdown/hourglass.
- **The companion GIVES:** it greets, surprises, and **"blesses" with an unprompted verse/duʿā** — *a friend surprises; a guilt-device only punishes.* Never "your garden is dying without you."
- **Ownership:** **name + lightly customize** the garden at onboarding (IKEA/endowment hook); **mirror the tended artifact onto the widget** (broadcasts ownership). **Customization = the paid tier** (Finch's split: core loop free forever, paid = beauty) — dovetails with our existing Cards/token economy.
- **Variable reward, tastefully:** which of the 99 Names surfaces + the verse/dua pairing + how the garden grows *is* the (gacha-style) anticipation — and the payoff is **meaning**, so we never need confetti. **No slot-machine effects on a sacred act** (e.g. the "Ameen" beat stays in reverent stillness).

---

## 5. Recommended build sequence

1. **Streak defense + endowed onboarding + widget streak polish** — highest leverage, mostly *extends* what exists (StreakService, Name-widget streak/status). SQL/RPC + Flutter + widget frames. *(S–M)*
2. **Milestone celebrations** — Lottie (existing pipeline). *(M)*
3. **The garden/khatam companion** — the big net-new: **Rive** in-app (streak-driven) + **pre-rendered PNG frames** for the widget. Needs a designer + a locked art direction. *(L — do last; brainstorm first.)*

## 6. Open decisions (brainstorm before building the companion)
- **Companion form:** garden(jannah) + khatam combo (recommended) vs a single tree(kalimah ṭayyibah) vs khatam-only (most abstract/safe)?
- **Animation tool for the companion:** Rive (better fit, needs a Rive designer) vs Lottie-with-markers (we have the pipeline, manual state logic)? Milestones stay Lottie either way; widget is pre-rendered frames either way.
- **Reverence strictness:** confirm no-leaderboard / no-hasanat-count / no-paid-repair as hard product rules.
- **Economy tie-in:** how the companion's growth resource + cosmetic currency relate to the existing tokens/Cards economy (all writes still via `sync_all_user_data()`).

---

## 7. Art-authoring pipeline — free + Claude-controllable + polished (2026 research)

**Can ChatGPT image gen make SVGs?** No. GPT-4o / DALL·E output **raster PNG**, never vector, and can't convert their own output to vector. Asking an LLM (ChatGPT/Claude) to **write SVG code** works only for *simple/geometric* marks (benchmarks: top models score 2–4/10 on stylistic illustration) — fine for icons/geometry, poor for rich illustration. **Raster→trace ("PNG to SVG") = "fake vector"**: node-soup that isn't cleanly editable/recolorable — a trap for illustrated art.

**Real AI-vector tools (if generating):** **Recraft V3/V4 Vector** = best native editable SVG, ~$10/mo, **has an API** (agent-iterable); **Adobe Firefly Text-to-Vector** = best *licensing* (indemnified, licensed training data), Pattern/Icon modes suit Islamic ornament; **SVG.io** = Recraft-powered. GOTCHA: **free tiers grant NO commercial license** (Recraft free = publicly owned) — never ship free-tier output. AI also mangles Arabic calligraphy — use licensed calligraphy fonts, never AI-generated Quranic letterforms.

**THE KEY FINDING — our art is the *easy* case.** A khatam / 8-point star / girih pattern is **procedural + mathematical** (Hankin "polygons-in-contact" / Kaplan star-pattern methods), so the best pipeline is **not an image generator at all** — it's **Flutter `CustomPainter` + `FragmentShader` (GLSL)**, drawn in code:
- **Most Claude-controllable option that exists** — plain Dart/GLSL in the repo, no editor, no binary asset; Claude edits/regenerates it directly. Streak states are literally uniforms (`illumination: 0→1`, `glowIntensity`, `protected`, `dormant`).
- **Free, zero asset files. Premium for geometric/illumination** (GPU glow/bloom via a ~30-line fragment shader; progressive stroke-reveal via `PathMetric`). Flutter 3.44+ supports fragment shaders natively.
- **Best widget-frame parity** — the SAME painter renders the live animation AND each widget PNG via `RepaintBoundary.toImage(pixelRatio: 3)` → App Group (build-time harness or on streak-change).
- **Honest caveat:** code-drawn is the WRONG tool for **organic/illustrated** art (a soft painterly garden). For that, use the **HYBRID**: AI generates the static look (**Recraft V4 Vector** clean SVG, or a raster base), and **code adds the motion + states + widget frames** on top.

**Ranked pipelines (non-designer, premium, AI-iterable, free):** 1) **Code-drawn CustomPainter+shader** (geometric — the recommendation); 2) **Hybrid** AI-static-base + code-motion (needed only for organic/garden states); 3) **Lottie** (only because our `text-to-lottie` pipeline lets Claude author JSON — good for milestone one-shots); 4) raster+`flutter_animate` (v0 placeholder); 5) AI-SVG per-path (fragile). **Rive: not recommended** — it's editor-first (a human authors `.riv` in a GUI; Claude can't), which fails the "Claude controls it / free" requirement despite its technical strengths.

**→ Decision:** author the **khatam/geometric companion in code** (CustomPainter + fragment shader) — free, most Claude-controllable, premium for exactly this art, and one source of truth for app + widget. Reserve paid AI-vector (Recraft/Firefly) ONLY for an optional organic garden layer later. This also means the companion should lean **geometric/khatam** (which the research §4 already found is the most reverent option too).

## Sources (headline)
Duolingo: streaks/goals blog, widget blog, KDD-2020 bandit, "reshaping Duo," Lenny's/Jorge-Mazal growth writeup. Companion loops: Finch (Deconstructor of Fun D1/D7), Forest, Plant Nanny, Kinder World, Habitica; Snapchat streaks (contrary case). Faith apps: Pillars, Quran.com Growth Journey, Quranly (backlash), MUSA, Muslim Pro (cautionary). Science: Nunes & Drèze (endowed progress), Lally et al. (66-day), Eyal (Hook), Norton/Mochon/Ariely (IKEA effect), Yu-kai Chou (pet-companion design), UX Magazine "Hot Streak Without Shame." Tech: Rive 0.14.0 data-binding + feature-support docs, lottie-ios #2403, Apple WidgetKit docs/WWDC23, Android Glance. (Full URLs in the research-agent transcripts; a handful of figures — the "60% widget," "+1.7% D7," some endowment/percentage stats — are secondary-sourced and flagged as directional.)

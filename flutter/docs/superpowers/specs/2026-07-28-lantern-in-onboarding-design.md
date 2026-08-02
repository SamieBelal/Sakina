# The Lantern in Onboarding — design spec

**Status: APPROVED (founder, 2026-07-28 — four decisions recorded in §2).**
**Date:** 2026-07-28
**Branch/worktree:** `feat/reel-first-w2-onboarding` at `/Users/appleuser/CS Work/Repos/sakina-reel-first` (rebased onto master `433c537` = lantern cosmetics PR #61 merged)
**Parents:** `2026-07-26-one-ship-02-onboarding.md` (W2 plan — this lands as **Wave G**) · `2026-07-18-streaks-and-companion-implementation.md` (the companion itself) · `2026-07-25-lantern-cosmetics-design.md` (skins/backdrops, now merged) · `2026-07-14-name-for-what-youre-carrying-widget-design.md` + `2026-07-15-dua-acceptance-times-widget-design.md` (the other two widgets)
**Trigger:** founder request, 2026-07-28 — "people usually add the avatar that they have in the onboarding… I want to add it so it looks aesthetic and well placed, has nice micro animations." Duolingo's full 17-screen onboarding supplied as reference.

The lantern (fānūs) companion exists on the home screen, the Companion stage, and a home-screen widget, but is almost entirely **absent from onboarding** — the one place a new user forms their relationship with it. This spec puts it there, borrowing Duolingo's layout system while deliberately rejecting its mascot personality.

---

## 1. Research basis

### 1.1 What the Duolingo reference deck actually encodes

Seventeen screens, but only **two layouts alternating on a rhythm**:

- **HERO** (screens 1, 2, 3, 4, 7, 11, 13) — mascot large and centered, bubble *above*, **no progress bar**, one CTA. Used for welcome, introduction, expectation-setting, loading, chapter breaks, payoffs.
- **GUIDE** (screens 5, 6, 8, 9, 10, 12, 14–17) — mascot shrinks to ~15%, pins **top-left**, bubble to its right, progress bar + back arrow above, options fill the body.

The switch between them *is* the information architecture: **progress bar = you are being counted; mascot hero = you are being rewarded.** The two never co-occur.

Six further mechanics, extracted frame-by-frame:

1. **The bubble replaces the title.** No headline text exists anywhere in the flow. The mascot asking *is* the question — this is what stops seven questions reading as a form.
2. **The mascot reacts to answers in real time.** Screens 9→10 are one screen: once three boxes are checked the bubble changes from *"Why are you learning French?"* to *"Let's prepare you for conversations!"*, before any button press.
3. **One costume per phase.** Every question screen uses the identical clipboard-and-pencil pose. Poses change only at phase boundaries (sparkle-eyes = contract, reading-books = loading, eyes-down = chapter break).
4. **Permissions are voiced in first person by the mascot** — *"I'll remind you to practice"* (14), *"I'll cheer you on from your home screen"* (15) — and 14 pairs this with a **mock** iOS permission dialog with an arrow at Allow (pre-permission priming).
5. **Expectation is set before the first question** (4: *"Just 7 quick questions"*), and the CTA becomes a commitment device at the goal screen (*"I'M COMMITTED"*).
6. **The paywall is framed as a question** (17): *"How do you want to get started?"*, RECOMMENDED badge on paid, a real free option, CTA disabled until a choice is made — a fork, not a wall.

**Cadence: never more than 2–3 question screens without a hero beat.** The mascot is the metronome.

### 1.2 Cross-app findings

- Mascots in onboarding correlate with materially lower drop-off (~25% in Adobe's UX figures); Duolingo reports DAU lift after refining Duo's interaction strategy specifically. The mechanism is emotional accountability, not decoration.
- **Finch is our closest analogue and inverts the pattern**: the companion is not a guide, it is the *point*. Onboarding opens by hatching the bird, then naming it and choosing traits. Self-discipline is converted into care for something else.
- **IKEA effect / endowed progress**: people over-value what they helped build (63% WTP premium in the canonical study), and pre-granted progress lifts completion. Drift doubled onboarding from 6 to 12 steps by adding customization and improved retention.
- **Mascots fail in three specific ways**: excessive interruption (Clippy), no authentic tie to the product's purpose, and tonal mismatch with the user's emotional state. The core Clippy critique is that it was a personality bolted onto a *medium* — it had no legitimate standing in what you were writing.
- **Wellness apps avoid the cartoon register.** Headspace's characters are rounded, muted, breath-synced; the illustration carries calm without mugging.
- **Duolingo's animation is a state machine, not clips** — poses/reactions/idles in Rive, one runtime file. The explicit design goal for idle is "alive without becoming distracting."

Sources: Appcues Duolingo onboarding teardown · UserGuiding Duolingo UX breakdown · Raw.Studio "How mascots improve UX" · Sharma, "Mascots in Product Design: why we hate Clippy, love Duo" · Finch UX teardown (Medium) + Pratt IXD design critique · Amplitude "Onboarding with the IKEA effect" · Raw.Studio Headspace case study · Rive/Duolingo creative-technologists post.

---

## 2. The role decision (founder-approved 2026-07-28)

**Duo has a face. Our lantern does not.** Everything load-bearing in the Duolingo flow runs through the speech bubble, and a bubble needs a speaker. A fānūs with a speech bubble becomes a talking object, and a talking object making chirpy first-person promises sits badly against *"I keep sinning and going back."* That is precisely the Clippy failure mode — a voice with no legitimate standing in the moment — and it collides with the reverence firewall already binding this project (no copy attributing a stance to Allah or a Name; no "sign"/"meant for you" language system-initiated or near a price).

In exchange, the lantern has something Duo does not: **seven real states on a brightness axis wired to actual behaviour** (`endowedDim`, `dormant`, `pendingUnlit`, `atRiskUnlit`, `dim`, `glowing`, `fullyLit`, plus the orthogonal `protected` shield). Duo's poses are costumes; our states are *consequences*.

**Decision 1 — the lantern is a MIRROR, not a GUIDE.** It never speaks, never appears in a speech bubble, never uses first person. It shows state; the app's own voice carries copy. In an app about muḥāsabah — self-accounting — a companion that reflects rather than instructs is the more honest design, not a compromise.

**Decision 2 — kindle ONCE (option A).** One designated lighting beat, then calm presence at `endowedDim`. Rejected: progressive per-question kindling, which either overclaims a streak the user has not earned or must visibly drop back at the end (reads as loss).

**Decision 3 — NO lantern on the paywall.** A dim lamp beside a price reads as *pay to light it*. Enforced by test, not just convention (§8).

**Decision 4 — the widget screen offers all THREE widgets in a browsable carousel** (founder override of the recommended single-option version; see §7 for the reasoning that was weighed and set aside).

---

## 3. Corrected baseline — what already exists

Verified against the post-rebase tree, 2026-07-28. **Two of these corrected earlier assumptions in this spec's own first draft and must not be re-derived:**

- **The lantern ALREADY renders inside onboarding.** `card_reveal_overlay.dart:506` holds a `Consumer` watching `renderableLanternSkinProvider` and renders a `CompanionMedallion` as the card's vessel (master `6bece34`, "render the equipped lantern on every surface"). Our reveal screen (reel page 1) pushes that overlay for the Silver card award. So page 1 is **not** a blank slate — the lamp is already seen there, as the vessel the card emerges from. The kindling beat in §5 therefore lands *before* an appearance the user will already get, which is the correct order (introduce, then use).
- **Three widgets ship today**, plus a Live Activity — `SakinaDuaTimesWidget` ("Duʿā Times"), `SakinaWidget` ("A Name for What You're Carrying"), `SakinaCompanionWidget` ("Your Lantern"). Gallery order = declaration order in `SakinaWidgetBundle.swift`, currently Duʿā Times → Name → Lantern.
- `SakinaCompanionWidget` loads pre-rendered `companion_<brightness>.png` frames (7 states) and mirrors `companion_state_mapper.dart`. Regenerated only under `REGEN_WIDGET_FRAMES=1` (master gated this; the frames no longer churn on every test sweep).
- `CompanionMedallion(state:, size:, skin:, animate:, ambient:)` — `skin` defaults to `LanternSkin.classicGold`. `ambient:false` is **required** on light/cream surfaces or the dormant vignette renders as a grey box.
- `renderableLanternSkinProvider` is `Provider.autoDispose<LanternSkin>` and **falls back to `classicGold`** whenever cosmetics state is unloaded. Onboarding is pre-auth for pages 0–7, so it will resolve to `classicGold` there. **That is correct, not a bug** — a brand-new user owns no cosmetics. Do not "fix" it.
- `SacredCanvasThreshold` (master, `78a94b3`) is the shared entrance/exit motion for sacred-canvas surfaces; timings recorded in `docs/superpowers/specs/2026-07-27-sacred-canvas-threshold*`.
- `AppMotion` (`lib/core/constants/app_motion.dart`, landed with the hook-screen redesign) is the motion vocabulary: `feedback` 140ms · `quick` 200 · `entrance` 440 · `layer` 400 · `item` 340 · `recede` 260 · `beat` 180 · `listStart` 320 · `stagger` 40 · `enter` = M3 emphasized `Cubic(0.2, 0, 0, 1)` · `ambient` = easeInOutSine · rise 14/12/10. **No bounce anywhere in the muḥāsabah path.**
- The `/welcome` screen (`HookScreen`, `router.dart:220`) is **deliberately unchanged in W2** (plan review 11). It gets no lantern. Separately and unrelated: it loads its arch illustration from a remote `googleusercontent.com` URL via `CachedNetworkImage` — the app's first screen depends on a network fetch of a Google-hosted Stitch asset. Tracked as debt in §10, out of scope here.

---

## 4. Placement map

Reel flow indices per `onboarding_screen.dart::_reelChildren`.

| # | Screen | Lantern | Rationale |
|---|---|---|---|
| — | `/welcome` | **absent** | Unchanged in W2 by prior decision. Also: introducing the object cold and unexplained, before the user has said anything, is the weakest possible entrance. |
| 0 | Hook — "What's weighing on you right now?" | **absent** | The basmala ornament was removed from this screen on 2026-07-27 for being decoration. Putting a lantern back is the same mistake with better taste. Stays bare. |
| **NEW-A** | **Kindling beat** (replaces the bare loader between hook and reveal) | **HERO — the lighting** | Duolingo screen 7. The lamp catches *because of what the user just said*. The single most important beat in the spec. Not a new page in the PageView — it is the existing `loaderBeat` phase of the reveal screen, given a body. |
| 1 | Reveal — deck → Silver card → Name₂ sealed | **already present, unchanged** | The medallion is the card's vessel inside `CardRevealOverlay` (§3). Nothing added; nothing removed. The sacred canvas otherwise belongs to the Name. |
| 2–4 | Source / carrying duration / aspiration | **absent** | The progress bar is doing this job. Adding a corner lantern here is decoration, and three questions is short enough not to need a metronome. |
| 5 | Reminder time | **absent** | See §10 open item 2 — an ANCHOR here was considered and cut for v1. |
| 6 | Notifications permission | **HERO — `pendingUnlit`** | The highest-value placement in the flow. `pendingUnlit` *literally means* "waiting to be lit"; showing the true state converts an OS permission ask into a stake in something the user already owns. Duolingo voices this in first person; we don't have to. Add the screen-14 mock-dialog priming. |
| **NEW-B** | **Widget carousel** | **HERO in card 1 of 3** | Duolingo screen 15. Placed immediately after notifications to keep the two "keep this alive" asks adjacent. |
| 7 | Queue plan + 8-stamp journey track | **HERO — `endowedDim`** | The payoff artifact. The lantern heads the journey track it is already semantically bound to. |
| 8–11 | Name / save progress / email / password | **absent** | Nobody wants a companion watching them type a password. Duolingo doesn't do it either. |
| 12 | Paywall | **absent — enforced by test** | Decision 3. |

**Net: one genuinely new page (NEW-B), one upgraded existing phase (NEW-A), two existing screens gain a hero medallion.** `onboardingReelLastPageIndex` moves 12 → 13; every index constant and the six index-pinned test files move with it.

---

## 5. NEW-A — the kindling beat

Replaces the bare `SakinaLoader` phase already specified in W2-C1 ("brief loader… not the 3.5s fake theater"). Same duration budget, given a body.

**Composes with the flow's own dissolve — do not build a second loader.** master `1952ba0` made `BeatRevealFlow` dissolve its `loading` status into beat 1 rather than popping, and `SacredCanvasThreshold` (`78a94b3`) is the house entrance/exit motion for sacred-canvas surfaces. The kindling beat lives *inside* that existing loading phase and hands off through the existing dissolve; it does not introduce a competing transition.

**Composition.** Lantern centered at 160pt on the sacred canvas (`ambient: true` — this is a dark immersive surface, so the aura is correct here). Copy below it, app-voice:

> **Your lantern is lit.**
> It brightens each day you come back.

Both lines are claims we actually keep: `glow` rises `dim` (streak 1–3) → `glowing` (4–29) → `fullyLit` (30+). Neither line attributes a stance to Allah or a Name. Neither uses "sign" or "meant for you".

**The lighting.** Pre-kindle frame is `pendingUnlit`'s params with `wear` overridden to `0.0` — glow `0`, `dormant: false`. It must **not** use `dormant: true`: that is the cold snuffed-wick treatment, and a cold Day 0 is a standing reverence guardrail from the companion plan.

**⚠️ Flame-threshold gotcha (from `companion_state.dart` and `lantern_painter.dart`, load-bearing).** The flame's on/off threshold is `g < 0.04`, and the breath pulse modulates `g` by ±10%. Any glow that *lingers* near 0.04 makes the flame blink on and off once per breath — this is exactly why `pendingUnlit` is pinned to a hard `0.0` rather than a small value. **The kindle ramp must cross 0.04 decisively and never settle near it.** Pinned by test (§8).

**Ramp.** `glow` 0 → 0.34 (`endowedDim`) over ~900ms on `AppMotion.enter`, with a luminance flare peaking ~0.45 at ~55% before settling. The flare is **luminance only — no scale, no translate, no spatial overshoot** — so the no-bounce rule is not breached; a flame flaring as it catches is physically true rather than cute. (Flagged for founder confirmation, §10 open item 1.)

Copy arrives after the flame: headline at `AppMotion.entrance` + `riseLarge`, subline at `+AppMotion.beat` on `layer` + `riseMedium` — overlapping, not queued.

**Reduce motion** (`MediaQuery.disableAnimations`): no flare, no travel. Straight cross-fade `glow` 0 → 0.34 over `AppMotion.layer`, copy fades with no rise.

---

## 6. Screen 6 — notifications

Existing `NotificationScreen`, reused; the lantern reframes rather than replaces it.

- Medallion at 120pt, state `CompanionState(brightness: pendingUnlit, protected: false)`, `ambient: false` (this is a light/cream surface — see §3).
- Copy in app-voice, no first person, no urgency, no guilt: the lamp is unlit and a reminder is what keeps it lit. **Never** phrase the lamp as disappointed, and never imply anyone but the user is waiting.
- Borrow Duolingo screen 14's **pre-permission priming**: a mock of the iOS dialog with a pointer at *Allow*, shown before the real `requestPermission` fires. Existing `notification_permission_result` instrumentation is unchanged.

---

## 7. NEW-B — the widget carousel

**Founder decision (2026-07-28): show all three, browsable.** The single-dominant-option version was recommended and set aside; recording the trade so it is not re-litigated blind — Duolingo can say "ADD WIDGET" because they have exactly one, three options at an emotional peak is the choice-overload risk the Chernev meta-analysis describes, and our lantern widget is currently *third* in the gallery. The founder's counter is that browsing three and picking a favourite is itself the desirable moment. Build it as specified.

**⚠️ iOS cannot add a widget programmatically.** There is no API — Duolingo's "ADD WIDGET" button is instructional too, which is why screen 15 pairs it with a phone mockup. The CTA opens an instructional sheet (long-press home screen → **+** → search "Sakina"); it cannot install anything.

**Composition.** Horizontally swipeable `PageView`, three cards, page dots, ~85% viewport width so the neighbours peek (the peek is what signals "swipe" without a hint label).

| Order | Widget | Line | Preview source |
|---|---|---|---|
| 1 | **Your Lantern** | "Your streak, lit." | `companion_endowedDim.png` — the **same asset the widget ships**, so the preview cannot drift |
| 2 | **A Name for What You're Carrying** | "Today's Name, on your home screen." | rendered preview (see risk below) |
| 3 | **Duʿā Times** | "The next window for duʿā." | rendered preview (see risk below) |

Lead with the lantern: it continues the beat that just happened. **Onboarding order deliberately differs from gallery order** (Duʿā Times first) — we are *not* reordering `SakinaWidgetBundle.swift`, which would change the gallery for every existing user. See §10 open item 3.

**⚠️ Preview-drift risk.** Only card 1 has a truthful, shared source. Cards 2 and 3 need mock renders that will silently diverge from the real widgets as those evolve. Build them as Flutter widgets reusing the real layout primitives where possible; where a static asset is unavoidable, regenerate it from a gated test in the same manner as `companion_*.png` (`REGEN_WIDGET_FRAMES` precedent) so drift is at least detectable.

**CTA:** "Show me how" → instructional sheet. **Secondary:** "Not now" — always present, never de-emphasised into invisibility.

---

## 8. Test plan

- **Flame-blink guard** (the highest-value test here): drive the kindle ramp frame by frame and assert `glow` never rests in `[0.02, 0.06]` for more than one frame. Directly encodes the §5 gotcha.
- **Reduce-motion**: with `disableAnimations: true`, assert no flare and no `moveY` on either the medallion or the copy.
- **Paywall ban**: assert **no `CompanionMedallion` anywhere in the page-12 subtree.** This encodes a product rule that convention alone will not hold.
- **Placement map**: assert medallion presence/absence per §4 for pages 0, 2–5, 8–11 (absent) and NEW-A, 6, NEW-B, 7 (present).
- **Widget carousel**: three cards, order pinned, "Not now" reachable, CTA opens the sheet and installs nothing.
- **Index migration**: the six index-pinned files updated for `onboardingReelLastPageIndex` 12 → 13.
- **Pre-auth skin**: with no cosmetics state loaded, the medallion resolves `classicGold` and does not throw. Regression guard for the `autoDispose` fallback in §3.
- Every new surface needs the standing Arabic/Latin isolation check — no mixed-script `Text`.

---

## 9. Implementation notes

- **Shader load is per-instance.** `CompanionMedallion._loadShader()` calls `ui.FragmentProgram.fromAsset('shaders/khatam_glow.frag')` in `initState`, so four placements mean four async loads. Add a static cached `Future<FragmentProgram>` before this ships.
- **Cost.** The painter runs blur + bloom + a fragment shader. `RepaintBoundary` and `VisibilityDetector` bounding are already in place; still, measure on the oldest supported device before committing to four surfaces.
- Use `renderableLanternSkinProvider` for the skin at every placement — never hardcode `LanternSkin.classicGold` — so the equipped skin follows the user everywhere, consistent with master's "every surface" work. The pre-auth fallback handles the new-user case for free.
- `ambient: true` only on the dark sacred canvas (NEW-A). Everywhere else `ambient: false`.
- Analytics constants land here as stubs; **W6 completes them** and must add `flag_reel_first` as a super property (carried over from the Wave E review, P3-9). New events: `onboarding_widget_previewed{widget_kind}`, `onboarding_widget_cta{widget_kind}`, `onboarding_widget_skipped`, `lantern_kindled`.

---

## 10. Open items

1. **Luminance flare vs the no-bounce rule** — §5 argues a flame flare is luminance-only and physically motivated, so it does not breach a rule aimed at spatial overshoot. Founder confirmation wanted; falls back to a plain ramp if rejected.
2. **The ANCHOR layout is cut for v1.** A small persistent lantern on question screens was considered and dropped: without a speech bubble to hold, it is decoration — exactly what we removed the basmala for. Revisit only with a mechanic that makes it *change*.
3. **Widget gallery order** (`SakinaWidgetBundle.swift`) — pointing at the third entry costs us. Reordering changes the gallery for every existing user, so it is a product call, not an implementation one. Not blocking.
4. **`/welcome` remote arch image** — the app's first screen depends on a network fetch of a `googleusercontent.com` Stitch asset (`hook_screen.dart:22`). Should become a bundled asset. Out of scope here; tracked so it is not lost.

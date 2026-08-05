# Guided Tour — Coach-Banner Redesign

**Supersedes** the earlier radial-scrim / edge-docked-card / beak direction (abandoned). That work
is to be reverted to the committed baseline as step 1 of implementation.

**Goal:** Replace the tooltip-card-over-content tour with a **compact coach banner pinned top-left**
that slides in on each step. The banner only names what to do; the user advances by tapping the
highlighted target. Lighter, never covers the content it teaches, and personalized to the user.

**Scope:** `lib/widgets/coachmark/coachmark_overlay.dart` (renderer rewrite),
`lib/features/tour/providers/onboarding_tour_controller.dart` (auto-advance + name injection),
`lib/features/tour/models/onboarding_tour_step.dart` (copy + auto-advance flag),
`lib/widgets/coachmark/coachmark_step.dart` (carry name + auto-advance). No change to the tour's
step sequence, anchors, surfaces, or tap-through advance plumbing.

**Design system:** cream `#FBF7F2`, emerald `#1B6B4A`, gold `#C8985E`, warm-ink `#1B1410`,
DM Serif Display headings / DM Sans UI. Premium, warm, "mushaf not tech product."

---

## Decided mechanics (from /plan-design-review Q&A, 2026-05-31)

1. **Banner = compact, top-left by default**, slides in from the left edge each step. Holds: the
   message + a small **Skip tour** link. **No Continue button.** On the steps whose highlighted
   target sits in the **top region** (step 6 streak pill, step 9 Build's tall upward cutout), the
   banner **drops to just below the target** so it never covers content. 11 steps stay top-left; 2
   adapt. Rule: if the target's top is within the banner's top-left footprint, dock below the
   target's bottom (clamped to the safe area); else top-left.
2. **Advance = tap the outlined target** for the 11 interactive steps. **Steps 6 (streak) and 13
   (final) auto-advance after ~3.5s** (read-only beats). Skip remains available throughout.
3. **Personalized copy** from `display_name`. Step 1 opens with an Islamic greeting; later steps
   weave the name in. Graceful fallback to a warm no-name variant if `display_name` is empty.
4. **Highlight = bright outline ring on the target, minimal/no scrim** (content visibility was the
   whole point). [OPEN — confirmed in Pass 2/6 below.]

### Collision handling (resolved)

Steps 6 (streak pill) and 9 (Build's 280pt upward cutout) highlight the top region, where a top-left
banner would cover content (verified in the mockup — banner landed on the Begin Muḥāsabah CTA). On
those steps the banner **docks just below the highlighted target** instead. Detection is geometric
(target top inside the banner footprint), not a hardcoded step list, so it self-corrects if anchors
move.

---

## The 13-step personalized copy ({name} = display_name; omit ", {name}" if empty)

| # | Step (anchor) | Mode | Banner copy |
|---|---------------|------|-------------|
| 1 | beginMuhasabah | tap | As-salāmu ʿalaykum, {name} 👋 Tap **Begin Muḥāsabah** to start. |
| 2 | goDeeper | tap | Open **Go Deeper**, {name} — reflection, story & dua await. |
| 3 | readStory | tap | Now read a story from the Prophets ﷺ. |
| 4 | ameen | tap | Seal your prayer — tap **Ameen**. |
| 5 | returnHome | tap | Beautifully done, {name}. Head back home. |
| 6 | streakPill | **auto ~3.5s** | Your streak begins today, {name}. Return tomorrow to keep it. |
| 7 | tabCollection | tap | Your first card is waiting — tap **Collection**. |
| 8 | tabDuas | tap | Let's build your first dua, {name}. Tap **Duas**. |
| 9 | buildCta | tap | Type what's on your heart, then tap **Build**. |
| 10 | firstRelatedHeart | tap | Tap ♡ to keep a dua you love. |
| 11 | tabJournal | tap | Your saved duas live in **Journal**, {name}. |
| 12 | firstEntry | tap | Tap any entry to revisit it anytime. |
| 13 | duaDetail.done | **auto ~3.5s** | That's the whole loop, {name}. Sakina is yours now. 🌙 |

Dropped the old "Tap to continue ↗" hints — tapping the outlined target is the only path forward.

---

## Pass 1 — Information Architecture

Order the user perceives: (1) the glowing outlined target (what to tap), (2) the small banner top-
left (what + why), (3) the live page behind, fully readable. Banner is secondary to the target —
the target is the action, the banner is the caption. ASCII:

```
┌─────────────────────────────┐
│ ╔═════════════╗             │  ← banner: top-left, compact, slides in from left
│ ║ As-salāmu…  ║   [Skip]    │     (Skip sits inside/under the banner)
│ ╚═════════════╝             │
│                             │
│        (live page,          │
│         readable)           │
│                             │
│      ⟦ ▢ outlined target ⟧  │  ← bright ring; tap to advance
└─────────────────────────────┘
```

## Pass 2 — Interaction State Coverage

| State | What the user sees |
|-------|--------------------|
| Step reveal | banner slides in from left (~250ms) once the target's anchor has settled (reuse existing reveal-settle gate); outline ring fades in on the target |
| Tap target | banner slides out left, next step's banner slides in; underlying nav/action proceeds |
| Auto-advance (6, 13) | banner shows ~3.5s, then slides out automatically; Skip available the whole time |
| AI latency (step 1→2: NameRevealOverlay) | banner held hidden by the existing blocking-route / reveal-settle gate until the muhasabah screen settles |
| Keyboard up (step 9 Build) | banner fades out so it never covers the field; the Build tap still advances (existing behavior) |
| Reduce-motion | no slide (banner just appears), auto-advance still fires but instant cross-fade; outline ring static |
| Skip tapped | tour ends, overlay removed |
| display_name empty | copy falls back to no-name variant (still warm) |

**Scrim decision (resolving the OPEN item):** no full-screen dim. Just the bright outline ring +
the banner. Rationale: legibility was the whole reason for this redesign; a ring + a small banner is
enough to direct attention on a phone. Tunable on-device if it reads as too subtle.

## Pass 3 — User Journey & Emotional Arc

5-sec: a warm Islamic greeting by name lands as hospitality, not a tutorial. 5-min: the banner
always lives in the same top-left spot, so it becomes predictable, low-effort; the user learns "look
top-left, then tap the glowing thing." 5-year: the personalization (name, "Sakina is yours now 🌙")
frames the app as a companion, not software. The auto-advancing streak + closing beats give the
journey a gentle exhale rather than ending on a chore.

## Pass 4 — AI-Slop Risk

Not generic. App palette + serif + Islamic greeting + name. No purple, no card grid, no centered-
everything. The one risk is the banner reading as a generic "toast" — mitigated by the cream/emerald
treatment, the gold accent dot, and the from-left motion that ties it to the brand's calm feel.

## Pass 5 — Design System Alignment

Reuses the existing cream-gradient surface, emerald/gold accents, DM Sans body. The banner is a new
but small component in the same vocabulary (no new colors/fonts). Calibrated to CLAUDE.md (no
DESIGN.md). Arabic in copy (ʿalaykum, ḥ, ﷺ) must follow the project rule: never mix Arabic + Latin
in one `Text` with ambiguous direction — keep the banner LTR with inline diacritics (safe) and avoid
raw Arabic-script words in the banner (the greeting uses transliteration, not script).

## Pass 6 — Responsive & Accessibility

- **Banner width:** cap ~78% of screen width (small + top-left), min-touch Skip target ≥44pt.
- **Long / Arabic-script names:** clamp to 1 line + ellipsis; banner never grows tall.
- **Small screens (<360):** banner shrinks with the width cap; still top-left.
- **Safe area:** banner top clamped under the status bar / Dynamic Island.
- **A11y:** banner is a `liveRegion` so the message is announced each step; **auto-advance must
  pause / extend when a screen reader is active** (3.5s is too fast for VoiceOver) — gate auto-
  advance on `MediaQuery.accessibleNavigation == false`, otherwise require a tap/skip. Reduce-motion
  disables the slide. Outline ring is decorative (ExcludeSemantics).
- **Contrast:** ink text on cream ≥ 4.5:1 (unchanged from current card).

## Pass 7 — Unresolved Decisions

| Decision | Resolution |
|----------|------------|
| Continue button | removed (tap target / auto-advance) |
| Non-tap step advance | auto-advance ~3.5s (steps 6, 13) |
| Banner position | top-left default; drops below the target on top-region steps (6, 9) |
| Scrim | none — outline ring only |
| Name source / greeting | display_name; Islamic greeting step 1; fallback if empty |
| Screen-reader auto-advance | require tap/skip when accessibleNavigation (no 3.5s timeout) |
| Slide duration | ~250ms ease-out, from left |

---

## NOT in scope
- Tour step sequence / count / anchors — unchanged.
- The reveal-settle gating — reused as-is.
- Localization of the new copy beyond i18n-extractable strings (priority languages later).

## What already exists (reuse)
- Cutout/anchor resolution (`_targetRect`), reveal-settle gate, blocking-route guard, keyboard-fade,
  reduce-motion plumbing, the tap-through advance via `TourAnchor`, the per-frame anchor tracking.

## Implementation order (on approval)
1. **Revert** the radial-scrim / edge-dock / beak changes + the `tooltipBelow` removal to the
   committed baseline (`git checkout` the touched files; restore the deleted field).
2. Rewrite `CoachmarkOverlay` → top-left slide-in banner + outline ring; delete card/beak/scrim.
3. Controller: inject `display_name`; add `autoAdvance` (Duration?) honored for steps 6 & 13, gated
   off under `accessibleNavigation`; rewrite the 13 messages with `{name}` interpolation + fallback.
4. `onboarding_tour_step.dart` / `coachmark_step.dart`: add `autoAdvance`; carry resolved name.
5. Rewrite the widget tests (banner presence/position, auto-advance timing, name interpolation,
   reduce-motion, screen-reader no-timeout).

## Approved Mockups

| Screen | Mockup | Direction | Notes |
|--------|--------|-----------|-------|
| Tour banner (steps 1/6/8) | `~/.gstack/projects/SamieBelal-Sakina/designs/coachmark-banner-20260531/mockup.png` | Top-left coach banner, outline ring, no dim | Step 6 confirmed the top-region collision → banner now drops below the target on steps 6 & 9 |

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 0 | — | — |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | CLEAN (FULL) | score 8/10 → 9/10, collision + a11y resolved |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**UNRESOLVED:** 0
**VERDICT:** DESIGN CLEARED (9/10). Ready to implement. Touches the renderer + tour controller/model
(not just one file) — a quick `/plan-eng-review` is worth it for the auto-advance timer + a11y
gating, but not blocking.

# `name_stories` Deck Format + Review Protocol

**Purpose:** the pre-authored onboarding reveal decks (One Ship §V6.2.1, pipeline per Phase 0.1 decision ③: Claude authors with verified citations, founder reviews good-or-not, sign-off recorded per deck). 14 decks total.

## Beat structure (renders on the shipped `BeatRevealFlow` spine, surface `onboarding_reveal`)

| # | Beat (`beat_kind`) | Content | Source rule |
|---|---|---|---|
| 0 | `recognition` *(sign contract only)* | "You didn't find this by accident." + comfort verse (2:286 theme) | verse from verified catalog only |
| 1 | `bridge` | Chip-specific: "For the weight you named — {chip's canonical phrasing}…" (authored per pair×chip, §V6.8.A4) | authored copy, no scripture |
| 2 | `name_intro` | Arabic display (AdjustedArabicDisplay) + transliteration + one-line meaning | verbatim from `collectible_names.json` |
| 3-5 | `story` ×3 | Prophet/companion narrative, 1-2 sentences per beat, Quran-sourced preferred | every claim traced to quran.com / sunnah.com URL, verified at draft time |
| 6 | `verse` | The verse anchor with reference | verified catalog / quran.com-verified reference |
| 7 | `dua` | The Name's dua (Arabic + transliteration + translation) | verbatim from `collectible_names.json` |
| 8 | `takeaway` | One line the user keeps; on Name₁'s deck this slot is the **pair-synergy beat** ("…and {Name₂} completes the answer — {how they work together}") | authored copy |

Separate-widget rule for all Arabic (never mixed with English in one Text). Story beats never quote invented dialogue — only what the source text carries; paraphrase is marked as paraphrase.

## Per-deck metadata (stored with the content)

```json
{
  "deck_id": "as-salam@1",
  "name_id": 6,
  "chip_keys": ["anxiety"],
  "sources": [{"claim": "...", "url": "...", "type": "quran|hadith", "grade": "..."}],
  "author": "claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

`reviewed_by/at/verdict` filled only by the founder. **Ship-gate: a chip renders only when both its pair's decks have `review_verdict: "good"`.**

## Story sourcing protocol (founder directive 2026-07-25)

For every deck: gather **3-4 candidate stories per Name**, not one — then select. Selection criteria, in order: (1) **impact** — genuinely moving, not merely illustrative; (2) **direct correlation to the Name** — the Name's meaning must be the story's engine, best of all when the Name/phrase appears IN the source text; (3) verifiability. Yaqeen Institute and comparable reputable Islamic institutions are approved as *secondary* sources (framing, context, which stories scholars connect to which Names) — but every factual claim still traces to a primary source (quran.com / sunnah.com), verified at draft time, never from memory. Qur'an-sourced narratives outrank hadith-sourced when impact is comparable. Rejected candidates + reasons are recorded (the anxiety pair's "storm sleep" rejection is the model). Each selected story then passes the adversarial audit before founder review.

## Founder review checklist (per deck)

1. Sources: open each URL — does the quoted text actually appear there? Is the source reputable?
2. Accuracy: does the story beat say anything the source doesn't?
3. Reverence: no waiting/stance attributed to Allah or a Name; no "sign" language; mercy-led register (esp. guilt chip).
4. UX/readability: each beat lands in one breath (1-2 short sentences); a 20-something scrolling from a reel understands every word; no scholar-register vocabulary without need.
5. Verdict: good / not good (+ what to change).

# Content sources — DO NOT DELETE

Raw transcripts of the lecture series the app's Names content was written from.
**These are source material, not build artifacts.** Nothing imports them, and
that is not evidence they are unused.

## What depends on them

`lib/core/constants/knowledge_base.dart` says so in its own header: *"Knowledge
base **distilled from** Sheikh Omar Suleiman's 'The Dua I Need' series …
**drawn directly from the series transcripts**."*

The relationship is one-directional: the transcript is the **input**, the Dart
file is the **output**. You cannot regenerate a transcript from the distillate.

### Coverage — read this before relying on the citation guarantee

Two naming conventions, one series:

- `ep02_…`–`ep29_…` (13 files) — the numbered episodes, named for their Names.
- `episode_01.txt`–`episode_20.txt` (20 files) — an earlier batch, numbered
  only. Ep 7 (Ar-Rahman, Ar-Rahim) lives here as `episode_07.txt`, **not** as an
  `ep07_*` file; it is easy to look for it under the first convention, not find
  it, and wrongly conclude there is a gap.

Between them, every Omar Suleiman episode `knowledge_base.dart` lists has a
transcript.

**The gap that is real:** `knowledge_base.dart` also covers a *second* series —
**"The Name I Need" by Sheikh Mikaeel Smith, Classes 1–22** — and **none of it
is here.** `grep -ril 'mikaeel' .` returns nothing. Roughly half that file's
entries therefore have **no citable source in this repo**. If a teaching
attributed to Al-Shakur, Al-Qabid/Al-Basit, Al-Mu'izz/Al-Mudhil,
Al-Muqaddim/Al-Mu'akhkhir, Ar-Razzaq or the other Mikaeel Smith classes is
questioned, this corpus cannot answer it. Sourcing those transcripts is
outstanding work, not a solved problem.

## Why they matter beyond convenience

This is religious content. When a teaching, a prophetic story, or a dua
attributed to a Name is questioned, **the transcript is the citation** — the
evidence that the app is reporting the scholar and not paraphrasing him into
something he did not say. Losing it means losing the ability to answer that.

## Why this warning exists

They were deleted on 2026-08-02 during a workspace cleanup, on the reasoning
that "no code under `flutter/` references the root `knowledge/` corpus, which
`knowledge_base.dart` superseded." Both halves were wrong: an "is it imported?"
test is meaningless for a text corpus, and `knowledge_base.dart` is its
derivative, not its replacement. Restored the same day, and moved here from the
repo root so the dependency is visible rather than inferred.

## Condition

Auto-transcripts, unedited. Expect mojibake in the Arabic, and at least one file
(`ep02_al_wahid_al_ahad.txt`) has unrelated audio spliced in near the top. Kept
verbatim — a source is worth more unedited, and cleaning them would sever the
link to what was actually said.

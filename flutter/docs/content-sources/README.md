# Content sources — DO NOT DELETE

Raw transcripts of the lecture series the app's Names content was written from.
**These are source material, not build artifacts.** Nothing imports them, and
that is not evidence they are unused.

## What depends on them

`lib/core/constants/knowledge_base.dart` — 3,126 lines — says so in its own
header: *"Knowledge base **distilled from** Sheikh Omar Suleiman's 'The Dua I
Need' series … **drawn directly from the series transcripts**."* Its episode
list maps one-to-one onto the filenames here:

| knowledge_base.dart | file |
|---|---|
| Ep 2 — Al-Wahid, Al-Ahad, Al-Witr | `ep02_al_wahid_al_ahad.txt` |
| Ep 3 — Al-Hadi, An-Nur, Al-Mubin | `ep03_al_hadi_an_nur.txt` |
| Ep 5 — Ar-Rabb, Al-Mawla, An-Nasir | `ep05_ar_rabb.txt` |
| Ep 9 — Al-Ghafir … At-Tawwab | `ep09_al_ghaffar_tawwab.txt` |
| … | … |

`episode_01.txt` … `episode_20.txt` are the earlier, un-renamed batch covering
Al-Wadud, Al-'Afuw, Al-Wakil, Al-Jami', Al-Karim/Al-Wahhab, Al-Hayy/Al-Qayyum,
As-Samad, Al-Wali, Al-Majid/Al-'Azim, As-Salam/Al-Quddus, Al-Qawi/Al-Matin.

The relationship is one-directional: the transcript is the **input**, the Dart
file is the **output**. You cannot regenerate a transcript from the distillate.

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

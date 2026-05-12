# Plan 5 (NameTeaching Corpus Expansion) — Eng Review Findings

Generated 2026-05-12. Plan: `docs/superpowers/plans/2026-05-11-name-teaching-expansion.md`.
Cross-plan findings already locked in `2026-05-11-plan-eng-review-report.md` are NOT re-surfaced here.

## Critical findings

### F1 — `emotionalContext` lowercase test fails today (47 violations in existing 38 entries)

Plan 5 Task 1 asserts every `emotionalContext` string equals `.toLowerCase()`. A scan of `lib/core/constants/knowledge_base.dart` found **47 existing entries violating this rule** (out of ~38 teachings), all caused by proper nouns: `Allah`, `Islam`, contractions written as `I'`/`don't` etc. Examples:

- `"feeling unworthy of Allah's love"` (Ar-Rahman)
- `"sacrificing prayers or Islam for career"` (Al-Mu'izz)
- `"feel like my sins have pushed me away from Allah"` (Al-Qarib)
- `"something feels wrong but I don't know what"` (Al-Jabbar)

The RED test in Task 1 will fail before any new content is added, blocking the TDD loop. Two options:

1. Loosen the assertion to "no uppercase ASCII letters except in proper nouns `{Allah, Islam, Quran, Muhammad, Musa, Ibrahim, ...}`" — fragile.
2. **Recommended:** require lowercase strictly, and as part of Task 1, lowercase the existing 47 strings (or write them as `"allah"` for matcher consistency — the matcher already does `userText.toLowerCase().contains(ctx_first_word)` on the first token only, so `"Allah"` vs `"allah"` doesn't affect matching today). Decide now; don't discover at runtime.

### F2 — Compound-key parts don't match canonical transliterations (16 misses)

Splitting all 38 existing teaching keys on `RegExp(r'\s*[/&]\s*')` produces parts that fail the canonical lookup in `assets/content/collectible_names.json`:

| Teaching key part | Canonical JSON form |
|---|---|
| `Al-Basir` | `Al-Baseer` |
| `Al-Ghafoor` | `Al-Ghafur` |
| `Al-Halim` | `Al-Haleem` |
| `Al-Karim` | `Al-Kareem` |
| `Al-Latif` | `Al-Lateef` |
| `Al-Matin` | `Al-Mateen` |
| `Al-Mujib` | `Al-Mujeeb` |
| `Al-Qawi` | `Al-Qawiyy` |
| `Al-Shakur` | `Ash-Shakur` |
| `Al-Wakil` | `Al-Wakeel` |
| `Al-Ghani` | `Al-Ghaniyy` |
| `Ar-Rabb` | **absent** (Rabb is a Lord-title, not in the 99) |
| `Al-Qarib` | **absent** |
| `Ash-Shahid` | **absent** (canonical is `Ash-Shaheed`) |
| `Al-Dhahir` | **absent** (canonical is `Az-Zahir`) |
| `An-Nasir` | **absent** |

The "every canonical Name appears in some teaching key" test in Task 1 will report all 99 as missing because *zero* teaching parts match canonical strings. Fix is one of:

- Normalize both sides through `findCanonicalName()` from `lib/core/validate_names.dart` (Plan 0 makes this trustworthy across 99 Names).
- Or rewrite teaching `name:` keys to use canonical transliterations.

This is the single highest-leverage Plan 5 fix. Without it the coverage test gives no useful signal.

### F3 — Separator regex is sufficient; `&` IS used

`Grep` of `name:` strings shows two separators in use: ` / ` and ` & ` (e.g. `Al-Dhahir & Al-Batin`, `Al-Qabid & Al-Basit`). The plan's `RegExp(r'\s*[/&]\s*')` covers both. No `,` or ` and ` separators present. OK as-is.

### F4 — `nameTeachings` is already exported

`lib/core/constants/knowledge_base.dart:81` declares `const List<NameTeaching> nameTeachings = [...]` — public. Plan 5's "If not currently exported, also export it" caveat is unnecessary; drop the line to avoid a no-op refactor.

### F5 — `DuaContent` is wrong type name

Plan 5 Task 3 example uses `DuaContent(arabic, transliteration, translation, source)`. The actual class is **`NameTeachingDua`** (`knowledge_base.dart:49`), and all constructor args are **named**, not positional:

```dart
NameTeachingDua(
  arabic: '...',
  transliteration: '...',
  translation: '...',
  source: '...',
)
```

Fix the plan's example or every batch will fail `flutter analyze`.

## Minor findings

### F6 — `getRelevantTeachings` false-positive risk unchanged

Plan 5 inherits the existing matcher: `userText.toLowerCase().contains(firstWordOfContext)` plus the keyword map. `"I'm not sad"` → still matches `sad`. The plan's eval-gate (Task 7) and the new probes catch the obvious cases, but per-context negation handling is out of scope. Document as a known limitation; do not fix in Plan 5.

### F7 — Probe assertion is too loose

`teachings.any((t) => t.name.contains(expectedName))` passes whenever the expected Name appears *anywhere* in the top-3 returned list. If Al-Qahhar also surfaces for "feeling powerless" and ranks first, the probe still passes for Al-Muqtadir as long as it's in the top-3. Tighten to: **top-1 must equal expected**, OR explicitly assert "the expected Name appears at position ≤ N" with N stated. Today's matcher returns up to 3; pin the rank.

### F8 — Ledger "Story Grade" column doesn't apply to Quranic stories

The plan asks for `Story Grade` per row. Quranic stories aren't graded (sahih/hasan/da`if applies to hadith, not Quran). Either: (a) split into `Story Type` (Quran / Hadith) + `Grade` (N/A for Quran, sahih/hasan for hadith), or (b) allow `Story Grade = "Quran (sura:ayah)"` as a literal value. Today's ledger schema invites a category error.

### F9 — Plan 5 example citation is correct (Musa, not Yusuf)

Verified: the plan's example references *Musa* parting the sea with citation Quran 26:61-63 (Ash-Shu'ara). 26:63 ("Strike the sea with your staff") is the splitting verse. Story and citation match; no Islamic-accuracy red flag.

### F10 — Entry count is 48, not 49

`grep "^    name: '"` returns **38 unique teaching keys** representing **48 NameTeaching constructors** (some Names repeat under different keys, e.g. `Ar-Rabb`, `Al-Wakil`, `Al-Wadud`, `As-Salam`, `At-Tawwab`, `Al-Karim`, `Al-Hadi`, `Al-Fattah`, `Al-Wahhab`). Plan says "49 → 99". Either reword as "~48 entries today, target full canonical 99 coverage" or de-duplicate the existing repeats first.

### F11 — iOS bundle id

`com.sakina.app.sakina` (from `ios/Runner.xcodeproj/project.pbxproj:514`). Use this literal in Task 6 Step 1.

## Summary patch list

1. **Decide lowercase policy** and pre-lowercase existing 47 violators in Task 1 (or relax the assertion). Required to get RED → GREEN.
2. **Normalize compound-key parts through `findCanonicalName`** (or rewrite teaching keys to canonical spellings) so the coverage test gives signal. Add explicit dependency on Plan 0's canonical backfill.
3. Drop the "if not exported, export it" caveat — `nameTeachings` is public.
4. Replace `DuaContent(...)` example with `NameTeachingDua(arabic:, transliteration:, translation:, source:)`.
5. Tighten probe assertion from "any contains" to "top-1 equals" (or rank ≤ N).
6. Split ledger `Story Grade` into `Story Type` + `Grade` to avoid grading Quranic narrations.
7. Reword "49 → 99" to "~48 entries / 38 keys today → full 99 canonical Name coverage".
8. Use `com.sakina.app.sakina` as the simulator bundle id.

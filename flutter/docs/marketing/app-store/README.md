# App Store marketing assets

## `1.2.0-shipped/`

The six screenshots **currently live on the App Store**, at Apple's 6.9" iPhone
size (1320×2868), exported 2026-05-24. They are the baseline any new set has to
beat, which is the only reason they are in git — everything else about this
directory is reproducible.

They were rescued from `flutter/.playwright-mcp/`, where they had been sitting
untracked next to console logs and simulator debug captures. That directory is
now gitignored; finished exports belong here.

The `-en-` in each filename is a locale slot from the generator's naming scheme.
Only English has ever been produced.

`_generator-board.png` is the generator's export board with all six tiles
visible — the fastest way to see the set as a set.

### The slide copy, in text

Transcribed because it existed **only** as pixels inside the board image, and
this is the headline copy of the store page — the actual creative decision.
`app-store-copy.txt` covers promotional text and the description, but has never
carried these.

| # | Slide | Eyebrow | Headline |
|---|---|---|---|
| 01 | hero | SAKINA | How are you feeling? |
| 02 | answer | THE ANSWER | Every feeling has a Name. |
| 03 | names | 99 NAMES OF ALLAH | One Name for every moment. |
| 04 | daily | DAILY RITUAL | Show up daily. He always does. |
| 05 | collect | COLLECT | Discover all 99 Names. |
| 06 | journal | JOURNAL | Your soul, gently kept. |

Note slides 01/02/04/06 render on cream and 03/05 on emerald — the alternation
is deliberate.

## What is deliberately NOT here

**The generator.** A Next.js app that composes captures into store-ready
advertisements. It lived at `screenshots-app/` (373M, 368M of it `node_modules`)
and is now gitignored. Rebuild it with the `app-store-screenshots` skill rather
than restoring it by hand. The last hand-built copy is recoverable from
`backup-feat-hard-paywall` (`git show backup-feat-hard-paywall:screenshots-app/src/app/page.tsx`)
if you want the previous layout as a starting point.

**Raw device captures.** Seventeen simulator PNGs (11M) previously at
`flutter/screenshots-raw/`. Deleted rather than committed: they re-capture from a
booted simulator in one pass, and several already depict UI that W2/W5 rebuilt.
Re-shoot them; do not go looking for the old ones.

## Before the next release

`TODO.md` bucket 2 owns this. The short version: **the 1.2.0 set is stale for
1.3.0.** Onboarding and the paywall were both rebuilt, and 1.3.0's whole thesis
is the new onboarding — so shipping a store page that depicts the old one
undersells exactly the thing the release is being measured on.

Order of operations:

1. Re-capture from a simulator running the 1.3.0 build (onboarding and paywall
   first — those are the ones that changed).
2. Scaffold the generator with the `app-store-screenshots` skill; point it at
   the new captures.
3. Export at 1320×2868 and upload to App Store Connect.
4. Move the exported set here as `1.3.0-shipped/` and delete nothing — the
   1.2.0 set stays as the comparison.

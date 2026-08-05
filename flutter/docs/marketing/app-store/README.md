# App Store marketing assets

**No screenshot images are stored here, on purpose.** App Store Connect holds
the live set and hands it back on demand — see the recipe below. Committing
copies costs ~9MB in git to duplicate something Apple already stores, and the
copies go stale silently, which is exactly what happened before.

## The live 1.2.0 store page

Seven screenshots, `APP_IPHONE_67` (1320×2868), English only. The **headline
copy** is the part worth having in text, because it is the creative decision and
it exists nowhere else in this repo:

| # | Slide | Eyebrow | Headline | Ground |
|---|---|---|---|---|
| 01 | hero | SAKINA | How you feel, in Allah's words. | cream |
| 02 | answer | WHAT ALLAH SAYS | A verse for right now. | cream → mint |
| 03 | build-dua | BUILD A DUA | Don't have the words? | gold |
| 04 | names | 99 NAMES OF ALLAH | A Name for every feeling. | emerald |
| 05 | daily | DAILY RITUAL | Show up daily. He always does. | cream |
| 06 | discover | DISCOVER | Every reflection reveals a Name. | emerald |
| 07 | journal | JOURNAL | Look back. See where He carried you. | cream |

The cream/emerald alternation is deliberate, and slide 03 is the only gold one.

## Getting the images back

```
# 1. version id for 1.2.0, then its localization
mcp__asc-mcp__apps_list_versions        app_id=6762153820
mcp__asc-mcp__apps_list_localizations   app_id=6762153820 version_id=<id>
# 2. the set, then the screenshots — each carries an imageAsset.templateUrl
mcp__asc-mcp__screenshots_list_sets     localization_id=<id>
mcp__asc-mcp__screenshots_list          set_id=<id>
```

`templateUrl` looks like `https://…/{w}x{h}bb.{f}`. Substitute to download:

```bash
curl -o 01-hero.png "https://is1-ssl.mzstatic.com/image/thumb/<path>/1320x2868bb.png"
```

As of 2026-08-02: version `bc4f7b91-b6bf-441b-a0fc-0f7d1983a22c`,
localization `ed621cce-5a10-4600-8061-bc3773c263c9`,
set `d8673a01-ca9c-4992-b0da-f98752d0dd50`.

## A warning, paid for once already

The 2026-08-02 cleanup rescued six 1320×2868 PNGs from `.playwright-mcp/` and
committed them as "the screenshots currently live on the App Store." **They were
not.** Querying ASC showed the live page has **seven** slides with different
content — `03-build-dua` and `06-discover` do not exist in that set at all — and
of its six headlines, exactly one ("Show up daily. He always does.") survived to
the live page. The rescued files were a superseded draft, and the filenames gave
no hint of it.

They were deleted and this table written from the live set instead. **A local
PNG is not evidence of what is on the store; ASC is.** Query it.

## Not stored here either

**The generator.** A Next.js app that composes captures into advertisements. It
lived at `screenshots-app/` (373M, 368M of it `node_modules`) and is now
gitignored. Rebuild it with the `app-store-screenshots` skill. The last
hand-built copy is recoverable from `backup-feat-hard-paywall`
(`git show backup-feat-hard-paywall:screenshots-app/src/app/page.tsx`) if you
want the previous layout as a starting point — but note its output was the
*draft* above, not the live page.

**Raw device captures.** Seventeen simulator PNGs previously at
`flutter/screenshots-raw/`. They re-capture from a booted simulator in one pass,
and several already depicted UI that W2/W5 rebuilt.

## Before 1.3.0

`TODO.md` bucket 2 owns this. **The 1.2.0 set is stale for 1.3.0** — onboarding
and the paywall were both rebuilt, and 1.3.0's whole thesis is the new
onboarding, so a store page depicting the old one undersells the release it is
being measured on.

1. Re-capture from a simulator running 1.3.0 (onboarding and paywall first).
2. Scaffold the generator with the `app-store-screenshots` skill.
3. Export at 1320×2868 and upload to ASC.
4. Add a `1.3.0` copy table above; keep the 1.2.0 one for comparison.

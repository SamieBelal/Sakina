---
name: daily-research
description: Run the daily Sakina TikTok trend research pipeline. Pulls hashtag videos + trending sounds from Apify, scores against Sakina's brand voice, writes today's digest to workspace/digests/. Use when the user says "run the daily-research skill" or "do today's TikTok research."
---

# Sakina Daily TikTok Research

This skill is the repeatable invocation of the pipeline first run on 2026-05-19. Read it top to bottom before starting a run.

## Preconditions

1. The Apify MCP server is connected. Sanity check: `mcp__apify__search-actors` is callable. If not, tell the user to run `claude mcp list` and reconnect Apify.
2. The working directory contains `sakina-research/workspace/context/product.md` and `sakina-research/workspace/context/brand-voice.md`. If either is missing, stop and ask the user.
3. Today's digest doesn't already exist at `sakina-research/workspace/digests/digest-YYYY-MM-DD.md`. If it does, ask the user before overwriting.

## Pipeline

### Step 1 — Load context (always)

Read both `workspace/context/product.md` and `workspace/context/brand-voice.md` in full. These are the non-negotiable filter. Do not skip even if you remember them from a previous run; the user may have edited them.

### Step 2 — Pick today's 10–12 hashtag seeds

Default seed list (the one that worked on 2026-05-19):

```
dhikr, namesofallah, quranreflection, muslimmindfulness,
duaforanxiety, revertmuslim, muslimmentalhealth, quranhealing,
islamicaffirmations, muhasabah, islamicjournaling, tawakkul
```

Rotate 2–3 seeds each run to surface new territory. Candidates to swap in: `quranjourney`, `muslimah`, `islamicreminder`, `salahmotivation`, `99namesofallah`, `tawbah`, `sabr`, `gratitudeinislam`, `muhasabahdiri`, `revertstory`. Avoid generic seeds (`muslim`, `wellness`) — they pull noise.

State your seed choices and rotation rationale to the user before firing the actors.

### Step 3 — Fire the three Apify actors (in parallel)

All three are pay-per-result. Set `shouldDownloadVideos/Covers/SlideshowImages: false` on the hashtag scraper to avoid storage charges.

```
mcp__apify__call-actor
  actor: clockworks/tiktok-hashtag-scraper
  input: {
    "hashtags": [<your 10-12 seeds, no #>],
    "resultsPerPage": 20,
    "shouldDownloadVideos": false,
    "shouldDownloadCovers": false,
    "shouldDownloadSlideshowImages": false
  }
  waitSecs: 45
```

```
mcp__apify__call-actor
  actor: khadinakbar/tiktok-trending-hashtags-scraper
  input: { "country": "US", "timePeriod": "7", "maxResults": 100 }
  waitSecs: 45
```

```
mcp__apify__call-actor
  actor: burbn/tiktok-trending-sounds
  input: { "country_code": "US", "period": "7", "maxResults": 30 }
  waitSecs: 45
```

**Expected costs (per run, with resultsPerPage: 20):** clockworks ≈ $0.005/video × 240 = $1.20 · burbn ≈ $0.42 · khadinakbar ≈ $0.03 actor-start. Total ≈ **$1.65/run**. (The first run on 2026-05-19 used resultsPerPage: 8 and cost $0.93, but missed most V/F breakouts in the long tail — see Step 7. The bump is worth it.)

If a run isn't terminal within 45s, poll with `mcp__apify__get-actor-run` (waitSecs:45 again). The clockworks scraper populates the dataset progressively — you can pull partial data via `get-dataset-items` even while RUNNING.

### Step 4 — Pull and inspect results

```
mcp__apify__get-dataset-items
  datasetId: <clockworks datasetId>
  fields: id,text,webVideoUrl,diggCount,shareCount,playCount,commentCount,
          collectCount,isSlideshow,videoMeta.duration,authorMeta.name,
          authorMeta.nickName,authorMeta.fans,authorMeta.verified,
          musicMeta.musicName,musicMeta.musicAuthor,musicMeta.musicOriginal,
          searchHashtag.name,searchHashtag.views
  limit: 100
```

Even with field projection, 96 videos may exceed the MCP token cap and write to a tool-results file. If so, the response will give you the file path — use `Bash` + `jq` to query it.

#### Quirk: flat dot-notation keys
Apify dataset items have flat string keys like `"searchHashtag.name"`, NOT nested objects. `jq` must use bracket syntax:

```bash
jq '.items[0]["searchHashtag.name"]'       # works
jq '.items[0].searchHashtag.name'          # returns null
```

Useful jq for grouping by hashtag with safe nulls:

```bash
jq -r '.items | group_by(.["searchHashtag.name"])
  | map({hashtag: .[0]["searchHashtag.name"],
         views: (.[0]["searchHashtag.views"] // 0),
         count: length})
  | sort_by(-.views)' <file>
```

Compact write for downstream analysis:

```bash
jq '[.items | sort_by(-.playCount) | .[]
  | {url: .webVideoUrl, hashtag: .["searchHashtag.name"], plays: .playCount,
     likes: .diggCount, shares: .shareCount, saves: .collectCount,
     comments: .commentCount, slideshow: .isSlideshow, dur: .["videoMeta.duration"],
     author: .["authorMeta.nickName"], handle: .["authorMeta.name"],
     fans: .["authorMeta.fans"], music: .["musicMeta.musicName"],
     musicAuthor: .["musicMeta.musicAuthor"],
     original: .["musicMeta.musicOriginal"], text: (.text // "")}]' \
  <file> > /tmp/sakina_videos_compact.json
```

### Step 5 — Dedupe across hashtags

Check `[.url] | unique | length` against total. On the first run there were no duplicates (every hashtag returned distinct top videos), but a viral cross-hashtag video will eventually surface — keep the highest-engagement instance.

### Step 6 — Score against brand voice

For each candidate, apply `brand-voice.md`'s scoring rubric (1–5 on five rules). A pick must score ≥4 on rules 1 (format fit), 2 (hook tone), and 4 (audience truth). Rule 3 (sound ethics) ≥3 or FLAG. Rule 5 (adaptability) ≥3.

Common reasons to REJECT outright (these recurred on the first run):
- handle or hashtags include "manifesting" / "manifestation" / "law of attraction"
- mixes Islamic content with "subconscious reprogramming," astrology, or shadow-work pop-psych
- pairs reminders with instrument-heavy commercial tracks
- uses defensive theological framing like "100% HALAL according to ALL scholars" (almost always means it isn't)

Common reasons to FLAG (don't auto-include, don't silently drop):
- music ethics unclear (non-original sound with unverified instrumentation)
- doctrinally fringe practice (e.g. drinking Quran-paper water)
- creator's delivery is intense/preachy enough that it conflicts with our gentle tone
- music labelled "original sound" but attributed to a different creator (provenance unclear)

### Step 7 — Pick the top 8–10 (rank by V/F ratio, NOT raw views)

The single most important metric for Sakina is the **view-to-follower ratio (V/F)** — plays divided by the creator's follower count. It separates algorithm-driven breakouts (replicable for us, who start at zero followers) from fan-driven reach (un-replicable, depends on a brand we don't have yet).

| V/F | Meaning |
|---|---|
| < 1× | Underperformed even own audience |
| 1–3× | Normal fan reach |
| 3–10× | Healthy algo lift |
| 10–50× | Breakout — format/hook carried it |
| 50×+ | Genuine FYP virality on the content alone |

**Ranking rule:** primary sort by V/F (desc), secondary sort by save rate (saves / plays). A 100× breakout from a 5K-follower creator beats a 7× video from a 1M-follower celebrity even if the celebrity got more raw views — because we are going to BE the small creator.

jq for V/F ranking from the compact file:

```bash
jq '[.[] | select(.fans > 0 and .plays > 0) | . + {vf: (.plays / .fans), saveRate: ((.saves // 0) / .plays)}]
  | sort_by(-.vf)
  | .[0:30]
  | .[] | {vf: (.vf | floor), saveRate: (.saveRate * 100 | floor), plays, fans, saves, hashtag, handle, original, music: .musicAuthor, text: (.text[0:100])}' /tmp/sakina_videos_compact.json
```

Pre-filters before ranking:
- Drop entries where `fans < 50` AND `plays < 5000` — too small to be statistically meaningful.
- Drop entries where the language is clearly non-English-led (Malay/Indonesian/Turkish/Azerbaijani text, see Step 4 quirks) for our US/UK/CA/AU audience.
- Drop entries that fail Step 6's brand-voice REJECT list.

Mix formats so the digest exposes different cards: dua-for-emotion, Names of Allah explainer, journaling, scholarly framework, gentle hook. Don't pick ten of the same shape.

### Step 8 — Sounds analysis

The US trending-sounds list will be dominated by commercial music with instruments and will almost entirely fail the Islamic music filter. That's expected. Skim for: voice-only nasheed, ambient pad with no recognisable instrument, nature soundscape, spoken-word. Note any usable ones for the "approved sounds library." On the first run, zero of the top 20 US sounds qualified.

### Step 9 — Write the digest

Output to `sakina-research/workspace/digests/digest-YYYY-MM-DD.md` using today's UTC date. Use the section structure from `digest-2026-05-19.md`:

1. **Replicable breakouts (creators + videos to follow)** — ranked by V/F. For each: handle, follower count, top video URL with V/F + save rate, format, why-it-fits, what we'd subtly plug. THIS IS THE PRIMARY DELIVERABLE.
2. **Top picks (8–10)** — URL, format, hook, engagement, why-it-fits, suggested adaptation. (Now a secondary section — V/F-ranked breakouts above are the action list.)
3. **Format insights (3–5)** — what's dominating, what's over-indexing, sound-filter notes
4. **Content strategy for today** — one recommended format, hook in Sakina's voice, visual approach, one experimental angle
5. **Anti-list — DON'T copy these** — high-view, low-V/F videos that look attractive but only work for already-famous creators
6. **Flagged for human review** — uncertain brand fits with reasons
7. **Run metadata** — pulled / deduped / filtered counts + estimated Apify credits + any substitutions

Then print the digest in chat.

### Step 10 — Note any new quirks

If you hit a new substitution (an actor returns 0 items, a field disappears, a hashtag yields all non-English content), append it to this SKILL's "Known quirks" section at the bottom. The point of the skill file is that the next run is cheaper than this one.

## Known quirks (running list, append over time)

- **2026-05-19** — `khadinakbar/tiktok-trending-hashtags-scraper` returned 0 items with status "⚠️ No data collected." Substituted by leaning on our own 12 seed hashtags. If it keeps failing, swap to `parseforge/tiktok-hashtag-analytics-scraper` (different vendor, also Creative Center).
- **2026-05-19** — `revertmuslim` (3.2B claimed views) catches a lot of non-Islamic "revert" content from gender/dating TikTok. The hashtag scraper still returned Muslim revert content but the views figure is an over-count. Don't trust hashtag-total views as a quality signal.
- **2026-05-19** — Several top videos surfaced in non-English (Malay, Indonesian, Turkish, Azerbaijani). For our US/UK/CA/AU audience these are skip candidates. Worth noting they exist (the niche is global) but don't waste a pick slot on them.
- **2026-05-19** — Apify dataset items use flat dot-notation string keys (see Step 4). Bracket-syntax jq is required.
- **2026-05-21** — `resultsPerPage: 8` (used on the first run) hid most V/F breakouts in the per-hashtag long tail — the top-by-views picks were dominated by big-creator fan-reach videos. Bumped default to `resultsPerPage: 20`. The cost roughly triples ($0.93 → $1.65) but the breakout-discovery yield more than makes up for it.

## Do NOT

- Do not post or DM any of the surfaced creators from this skill. Research only.
- Do not download videos or covers (storage charges, and we don't need the bytes).
- Do not generate hashtag lists from training data without rotating against the working list above — drift toward generic terms degrades the run.
- Do not silently drop borderline picks. If unsure, FLAG.

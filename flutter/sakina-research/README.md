# sakina-research

Phase 1 prototype of the daily TikTok trend research pipeline for Sakina, the Islamic emotional wellness app.

**Status:** local prototype. Will move to a VPS once the run logic is stable.
**Posts nothing.** Research only.

## Layout

```
sakina-research/
├── workspace/
│   ├── context/
│   │   ├── product.md       # Sakina product brief — non-negotiable filter
│   │   └── brand-voice.md   # Allowed formats, blocked formats, tone, scoring rubric
│   └── digests/
│       └── digest-YYYY-MM-DD.md   # One per day. Hand-readable.
├── skills/
│   └── daily-research/
│       └── SKILL.md         # Reusable Claude Code skill: "run the daily-research skill"
└── README.md
```

## Daily run

Invoke the skill in Claude Code:

```
run the daily-research skill
```

It reads `product.md` + `brand-voice.md`, hits the Apify TikTok actors, scores
candidates against the brand-voice rubric, and writes today's digest to
`workspace/digests/`.

## Apify dependencies

- `clockworks/tiktok-hashtag-scraper` — videos + creators + sounds per hashtag
- `khadinakbar/tiktok-trending-hashtags-scraper` — Creative Center top-100 trending hashtags (geo + window)
- `burbn/tiktok-trending-sounds` — Creative Center trending sounds (geo + window)

Apify MCP must be connected. See `skills/daily-research/SKILL.md` for the exact tool calls and any quirks discovered during runs.

## Next steps (Phase 2)

- Cron the pipeline on a small VPS, drop the digest into Slack / email
- Add a "previously surfaced" memory so the same video doesn't re-appear daily
- Bolt a Whisper transcript step onto top picks so the hook is verified, not inferred

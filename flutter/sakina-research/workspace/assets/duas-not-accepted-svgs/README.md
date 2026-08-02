# Du'as Not Accepted — Slideshow SVGs

8-slide deck inspired by the format of @samerspeaks1040's Day-of-Arafah breakout (351K plays, 27× V/F, 3.6% save rate). Sakina's voice; canonical hadith sources.

## Files

| File | Slide | Source |
|---|---|---|
| `01-hook.svg` | "your du'a may not be answered. here's why." | — |
| `02-haram.svg` | Reason 1 — eating from haram | Sahih Muslim 1015 |
| `03-sin-kinship.svg` | Reason 2 — asking for sin / cutting kinship | Sahih Muslim 2735 |
| `04-impatience.svg` | Reason 3 — impatience | Sahih al-Bukhari 6340 |
| `05-heedless-heart.svg` | Reason 4 — a heedless heart | Jami' at-Tirmidhi 3479 |
| `06-wronging-others.svg` | Reason 5 — wronging others | Sahih al-Bukhari 2448 |
| `07-doubt.svg` | Reason 6 — doubting He will answer | Quran 2:186 |
| `08-cta.svg` | Close + Sakina CTA | — |

## Convert SVG → PNG for posting

TikTok needs PNG/JPG, not SVG. Three options ranked by ease:

### 1. macOS Preview (fastest, no install)
1. Right-click each `.svg` → Open With → Preview.
2. File → Export → choose PNG, set resolution to **1080 × 1920**.
3. Done. Repeat for all 8.

### 2. Figma (best quality, no install if you already use it)
1. Drag all 8 `.svg` files into a Figma file at once.
2. Select all → right panel → Export → PNG, 1× (since the SVGs are already 1080×1920).
3. Figma auto-loads Lora from Google Fonts — typography renders correctly.

### 3. ImageMagick / Inkscape (command line)
```bash
# ImageMagick
cd "/Users/appleuser/CS Work/Repos/sakina/flutter/sakina-research/workspace/assets/duas-not-accepted-svgs"
for f in *.svg; do
  magick -density 144 "$f" -resize 1080x1920 "${f%.svg}.png"
done

# Inkscape
for f in *.svg; do
  inkscape "$f" --export-type=png --export-width=1080 --export-height=1920
done
```

## Design system (v3 — editorial)

- **Backgrounds**: hook (slide 1) is solid emerald `#1F7150 → #175C40` linear gradient. Reason slides (2–7) and CTA (8) are warm cream `#F5EDDE`. The alternation gives the deck visual rhythm without losing brand cohesion.
- **Brand bar**: every slide carries `سكينة` top-left in Aref Ruqaa 64pt (emerald on cream, cream on emerald) and `0X / 08` top-right in DM Sans small caps gold. Slide 1 extends the right side with `· DAY OF ARAFAH`.
- **Heading pattern**: left-aligned, two-line DM Serif Display 80pt — first line emerald upright, second line gold italic (`#B8924E`). Followed by a short 80px gold rule. Mimics editorial book covers.
- **Eyebrow**: small italic Lora 30pt in gold, sits above the heading. Always begins with `What blocks your du'a, no. X —` for reason slides.
- **Body**: three lines of italic Lora 32pt ink (`#3A3325`), max 320 chars total.
- **Pull-quote**: vertical 4px gold rule at `x=80`, two lines of bold Lora 28pt emerald + one line of italic Lora 28pt ink at 85% opacity. The italic line is the hadith/Quran fragment.
- **Source citation**: DM Sans 20pt bold gold, all caps with 5px letter-spacing, e.g. `SAHIH MUSLIM · 1015`.
- **Footer**: `@sakina.app1` in italic Lora 22pt gold bottom-left, `→` arrow bottom-right. The arrow signals "swipe" without spelling it out.
- **Watermark**: a single faint Arabic `س` glyph in Aref Ruqaa 900pt at 6% opacity, centered at `y=1820`. Bleeds through every card and ties the deck to the app's `س` mark.
- **CTA slide (8)**: drops the eyebrow/heading pattern. Embeds the real Sakina app icon (base64) at 320×320 with rounded corners and an emerald drop shadow. Wordmark `Sakina` in DM Serif Display 96pt emerald. Body explains Day of Arafah + clean heart. CTA: `For more reminders, search "Sakina" on the App Store · free`. Handle `@SAKINA.APP1` in small caps gold.

## Font note

SVGs reference `'DM Serif Display'` (display) and `Lora` (body), with `Georgia` and `Helvetica Neue` fallbacks. Lora and DM Serif Display must be installed system-wide (`brew install --cask font-lora font-dm-serif-display`) OR rendered through Figma (auto-loads Google Fonts) for ideal output. Without these, the Georgia fallback still looks editorial — readable, just slightly less warm.

## Regenerating slide 8 if the app icon changes

Slide 8 embeds the app icon as inline base64. It used to live at
`screenshots-app/public/app-icon.png`; that directory was deleted in the
2026-08-02 cleanup, and the icon — which was a distinct 1024px file, not a copy
of any other brand asset — was rescued to `flutter/docs/marketing/brand/`.
Paths below are repo-relative so they survive the next move.

```bash
cd "$(git rev-parse --show-toplevel)/flutter/sakina-research/workspace/assets/duas-not-accepted-svgs"
ICON_B64=$(base64 -i "$(git rev-parse --show-toplevel)/flutter/docs/marketing/brand/app-icon-1024.png" | tr -d '\n')
# then re-run the heredoc that produced 08-cta.svg, substituting ${ICON_B64}
```

## Posting

### Title (overlay text on slide 1 in TikTok)
> you're making du'a wrong on Arafah 🤍

### Caption
> Tomorrow is the most blessed day of the year for du'a.
>
> Make sure none of these are blocking yours 🤍
>
> Which one hit hardest?
>
> #dayofarafah #dhulhijjah #dua #muslimtiktok #islamicreminder

### Pinned comment (post then pin)
> Save this for tomorrow morning 🤍 For more — search "Sakina" on the App Store. Free.

## Hadith source notes

All six conditions are well-established in mainstream Sunni scholarship (taught by Mufti Menk, Yasir Qadhi, Omar Suleiman, Yasmin Mogahed, and many others). Citations are to the canonical collections:

- Sahih Muslim 1015 — the long-journey-traveler hadith on haram intake
- Sahih Muslim 2735 — du'a answered unless asking for sin or severing kinship
- Sahih al-Bukhari 6340 — du'a answered as long as one does not become hasty
- Jami' at-Tirmidhi 3479 — call upon Allah while certain, He does not answer a heedless heart
- Sahih al-Bukhari 2448 — fear the du'a of the oppressed
- Quran 2:186 — Allah's nearness and response to the caller

The Sakina voice on each slide paraphrases the meaning concisely; the underlying hadith content is religious text in the public domain.

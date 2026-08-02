# Regenerating the onboarding widget-preview screenshots

The three images in `assets/images/widget_previews/` are **real screenshots** of
the shipped widgets on an iPhone Home Screen. They are what the widget-offer
screen (reel onboarding page 12) shows.

They can go stale silently: redesign a widget and nothing here fails, the
screenshot just keeps showing the old one. Re-shoot whenever
`ios/SakinaWidget/*.swift` changes what a medium widget looks like.

## What Apple allows (the binding constraint)

From Apple's **Marketing Resources and Identity Guidelines**, "Home Screen":

> If your app supports widgets, you may show your app's widget on the Home
> Screen **as long as no third-party content is depicted** in your
> communications. Otherwise, don't display an iPhone, iPad, iPod touch, Apple
> Watch, or Apple TV Home Screen.

So the crop must contain **only the Sakina widget and wallpaper**. No dock, no
app icons, no other widgets. The capture below also excludes the status bar and
the "Sakina" caption iOS draws under the widget — those are chrome the in-app
card does not need (it has its own caption).

If you ever reuse these as App Store screenshots, the status bar becomes
required and must show a full network icon, full Wi-Fi and full battery.

## 1. Capture

Use **medium** widgets — all three support `.systemSmall` and `.systemMedium`,
and medium is what ships here.

Physical device or simulator both work. On the simulator you can pin the status
bar, which matters only if these become App Store assets:

```bash
xcrun simctl status_bar booted override \
  --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 \
  --batteryState charged --batteryLevel 100
```

Then, for each of **Duʿā Times**, **A Name for What You're Carrying** and
**Your Lantern**:

1. Long-press the Home Screen → **Edit** → **Add Widget** → search `Sakina`
2. Add the widget at **medium**
3. Press **Done** (no jiggle, no minus badges)
4. Screenshot the whole Home Screen

Put the three full-screen PNGs somewhere together. The crop script finds the
widget itself, so they do not need to be framed carefully.

**Check the widget is in a real state, not a degraded one.** Duʿā Times renders
"Open Sakina to turn on precise times" until a schedule exists — open the home
screen's duʿā card once first, or you will ship a screenshot telling the user to
go fix something.

## 2. Crop

The script finds the cream card by row/column brightness density, so it ignores
the status bar and the caption (a few bright pixels on a dark row) and locks
onto the card (~1000px of solid cream). All three come out identically sized,
which the carousel depends on — differing heights make it jump between pages.

```python
from PIL import Image

M, M_BOTTOM = 24, 8  # @3x px of wallpaper; bottom is tighter to miss the caption

for src, out in [("shot_dua.png",     "widget_dua_times.png"),
                 ("shot_name.png",    "widget_daily_name.png"),
                 ("shot_lantern.png", "widget_lantern.png")]:
    im = Image.open(src).convert("RGB")
    W, H = im.size
    px = im.load()
    def bright(x, y):
        r, g, b = px[x, y]
        return r > 200 and g > 195 and b > 185
    rows = [y for y in range(0, H // 2)
            if sum(1 for x in range(0, W, 4) if bright(x, y)) > (W // 4) * 0.6]
    y0, y1 = min(rows), max(rows)
    cols = [x for x in range(0, W)
            if sum(1 for y in range(y0, y1, 4) if bright(x, y)) > ((y1 - y0) // 4) * 0.6]
    x0, x1 = min(cols), max(cols)
    im.crop((max(0, x0 - M), max(0, y0 - M),
             min(W, x1 + M), min(H, y1 + M_BOTTOM))).save(out)
```

Thresholds assume a **light widget on a dark wallpaper**. On a light wallpaper
the density test will not separate card from background — shoot against
something dark.

## 3. Install

Copy the three outputs into `assets/images/widget_previews/` under exactly these
names (they are referenced from
`lib/features/onboarding/content/onboarding_widgets.dart`):

- `widget_dua_times.png`
- `widget_daily_name.png`
- `widget_lantern.png`

Then run:

```bash
flutter test test/features/onboarding/screens/widget_offer_screen_test.dart
```

That test asserts each asset exists, is registered in `pubspec.yaml`, and that
all three share one aspect ratio. If the crop box changed, update
`WidgetPreviewCard.previewAspectRatio` to match.

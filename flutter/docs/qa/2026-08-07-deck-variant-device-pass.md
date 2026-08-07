# Deck variants — device pass (2026-08-07)

Branch `feat/journaling-and-name-mastery` @ `891501a`. The selector has been
code-reviewed once (its first) and the deck **content** has 35 verdict/audit
documents. Neither has ever run against a real device, real SharedPreferences,
or a real Supabase uid.

**Four things need the device. Everything else is pinned by tests** — the
ladder, byte-identity, no-repeat rotation, exhaustion, the ship gate,
abandon-vs-complete — and re-checking those by hand tells you nothing.

Each item below corresponds to a case the review named as uncovered. Ordered
by risk, highest first.

---

## Setup

```bash
cd /Users/appleuser/conductor/workspaces/sakina/beirut/flutter
cp /private/tmp/poll/flutter/env.json .          # this worktree has none
flutter run --dart-define-from-file=env.json -d <sim-udid>
```

Bundle id `com.sakina.app.sakina`. Account `qatester1@sakina-test.dev` / `abc123`
(uid `3e09623f-ab5b-44ce-af7e-0788a36ec1c5`).

**Two standing gotchas on this device.** Fresh accounts inherit a sandbox
RevenueCat entitlement → `isPremium = true` → onboarding may skip steps
silently; that is not a bug. And there is a pre-onboarded-account recipe in
`docs/qa/2026-08-01-w5-gate-and-free-tier-test-plan.md` §3.6 if you want to
jump straight to the daily path.

### Reading the rotation from outside the app

This is what makes items 1 and 2 checkable rather than a vibe.

```bash
SIM=$(xcrun simctl list devices booted -j | python3 -c "import json,sys;d=json.load(sys.stdin)['devices'];print([x['udid'] for v in d.values() for x in v if x['state']=='Booted'][0])")
APP=$(xcrun simctl get_app_container "$SIM" com.sakina.app.sakina data)
PLIST="$APP/Library/Preferences/com.sakina.app.sakina.plist"

# every deck-rotation key, scoped and unscoped
plutil -convert xml1 -o - "$PLIST" | grep -A2 "sakina_deck_variants"
```

Key shape: `flutter.sakina_deck_variants_<deckId>` while signed out,
`flutter.sakina_deck_variants_<deckId>:<uid>` once signed in. Value is JSON:
`{"seen":[...],"n":<completedEncounters>}`.

Deck ids are `<slug>@<position>`, e.g. `ar-rahman@1`, `al-malik@1`.

### The sentences you are comparing

Every one of the 99 decks has bridge variants. Two worked examples — the
`__primary__` line is what you get when personalisation does **not** happen, so
these are exactly what tells a pass from a silent failure:

**`ar-rahman@1` (Ar-Rahman)**
| variant | opening words |
|---|---|
| `__primary__` | *Before any Name for what hurts, there is the Name that opens the Qur'an itself.* |
| `anxiety` | *You are looking for something wide enough to steady the noise…* |
| `heavy` | *You are carrying all of it at once…* |
| `guilt` | *You came expecting to be met with the account of what you did…* |
| `far_from_allah` | *However far you have decided you have got…* |
| `rizq` | *You have been counting what is not there…* |
| `unseen` | *Nobody has looked at this properly…* |

**`al-malik@1` (Al-Malik)**
| variant | opening words |
|---|---|
| `__primary__` | *Most of what shapes your week was decided by people who never asked you…* |
| `rizq` | *Your income is decided in rooms you will never sit in…* |
| `anxiety` | *You keep running an outcome you cannot control…* |
| `unseen` | *The people with a say over your life have not looked at you closely…* |
| `heavy` | *So much of the weight is decisions you had no part in…* |

---

## 1. The prefs seam — three checks, and the newest code first

The real `SharedPreferencesDeckVariantStore` against a real uid has never run.
It got **newer** on 2026-08-07: `891501a` changed this exact seam.

### 1a. The onboarding claim (highest risk — shipped today, fake-prefs only)

Onboarding runs **before sign-up**, so `scopedKey` has no uid and writes the
bare key. A second account on the device used to inherit that rotation; the fix
claims the bare entry on the first read that has a uid.

1. Erase the sim (`xcrun simctl erase <udid>`) and install fresh.
2. Onboard. Tap a chip you can remember. Complete the reveal through **Ameen**.
3. **Before signing up**, dump the plist. Expect a key with **no** `:uid`
   suffix.
4. Finish sign-up.
5. Reach any daily reveal (this triggers the first read with a uid).
6. Dump again.

**PASS** — the bare key is *gone*, a `…:<uid>` key exists, and its `seen` array
still contains what onboarding wrote.
**FAIL** — the bare key survives (leak to the next account), or the `:uid` key
is empty (the user's own rotation was lost).

### 1b. Two accounts, one device — the bug the fix exists for

1. Continue from 1a as user A. Note the variant A saw.
2. Sign out. Sign in as a second account.
3. Draw the same Name.

**PASS** — B gets the variant written for their chip.
**FAIL** — B gets `__primary__` because A consumed it. That is the first thing
B ever sees.

### 1c. Rotation across a real force-quit

1. Complete a deck fully (through Ameen). Note the bridge sentence verbatim.
2. Dump the plist — `n` should have incremented and `seen` should list the
   variant id.
3. Force-quit (swipe up, don't just background).
4. Relaunch, draw the same Name.

**PASS** — a *different* bridge sentence.
**FAIL, and it looks identical to working** — the same sentence, meaning the
key never persisted.

> **Known hazard, don't mistake it for flakiness.** `completeDeeper` marks the
> rotation *before* persisting `deeperDone`. A kill inside that gap replays a
> finished reveal **with a different bridge line** and double-counts the
> encounter. If you see a completed reveal replay itself, that is review
> finding #3 — a one-line ordering swap, not yet fixed.

---

## 2 + 3. The onboarding budget and the event — ONE check

These merge, and merging them makes the check far sharper.

`selectBudget` is 1200 ms (`onboarding_reveal_screen.dart:68`) applied via
`.timeout()` at `:286`. But `select` emits `deck_variant_selected` **inside
itself** (`deck_variant_selector.dart:531`), and Dart's `Future.timeout` does
not cancel the source future.

**So the failure is not "onboarding silently serves primary."** It is worse and
more diagnosable: the screen shows the generic line while Mixpanel records a
personalisation that never happened. And because the miss is dropped rather
than reported as `fallback`, it biases the **>35 % fallback alarm in the
safe-looking direction** — the alarm stays quiet exactly when it should fire.

1. Erase the sim. Cold first launch (worst-case prefs latency — do not warm it
   up first).
2. Onboard, tapping a chip you can remember.
3. **Read the bridge sentence on screen** and write it down.
4. In Mixpanel, find `deck_variant_selected` for this distinct_id.

**PASS** — `variant_id` matches the sentence you read, and `source` is `chip`.
**FAIL** — the screen showed `__primary__` but an event claims a variant, or
vice versa. **Disagreement between screen and event is the bug**, in either
direction.

While you have the event open, check the rest of the payload:

| property | expected |
|---|---|
| `source` | `chip` in onboarding; `category` / `rotation` / `fallback` in daily |
| `variant_id` | the id whose sentence you read, or `__primary__` |
| `reflection_matched` | bool |
| `encounter_index` | 0 on a first encounter |
| `problem_category` | a taxonomy id, `unmatched`, or `none` |
| `category_unmatched` | bool |

> **The one that is a breach, not a metrics bug:** `problem_category` must
> **never** contain the user's typed text. The review traced this and it holds —
> `_problemCategoryFor` maps through `problemChipsByKey` and can only return a
> category or the sentinel — but it is worth eyeballing on a real event.

Also worth noting while you are here: **the daily restore path double-emits.**
Cold-restart a resumed-but-unfinished reveal and you will see two
`deck_variant_selected` for one encounter. That is known and acknowledged in
the code. `deck_id` + `encounter_index` + distinct_id dedupes it — that belongs
in `docs/analytics/` next to the fallback alarm, or the "personalisation
worked" numerator is quietly inflated by the resume rate.

---

## 4. Judgment — does the variant read right at the flow's pace?

Not a test question, and the only one a person has to answer.

1. **Onboarding, chip path.** Tap a chip. Does the bridge sentence sound like it
   was written for the thing you just named, or like it is straining to?
2. **Daily, free-text path on a different theme.** Answer the daily question by
   typing — not a chip — about something *unlike* the chip you tapped. Free text
   routes through `matchChipKeyForText` (`daily_loop_provider.dart:1089`), so
   this also exercises the matcher whose recall was widened 65 % → 94 % in
   `a7a8f3a`.

**What you are judging:** does the bridge suit what you actually wrote, and does
it arrive at a pace that feels like a reply rather than a lookup? A variant that
is *correct* but reads as a non-sequitur after your own sentence is a content
finding worth raising even though every test passes.

Try at least one deliberately awkward input — something the matcher will not
place — and confirm the `unmatched` path still reads as an authored line rather
than a shrug.

---

## Reporting

For each item: **PASS**, or the observed-vs-expected pair plus the plist dump or
the Mixpanel event that shows it. A screenshot of the bridge beat next to the
event payload settles items 2+3 on its own.

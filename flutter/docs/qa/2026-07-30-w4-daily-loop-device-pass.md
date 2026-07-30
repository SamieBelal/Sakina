# W4 — Daily Loop Restructure: Physical Device Pass

**Date:** 2026-07-30
**Branch:** `feat/reel-first-w2-onboarding`
**Waves under test:** W4 Waves 1–7 (`b61572d`, `8241923`, `4fff416`, `30dbf76`, `41e868f`, `5527507`, `b368766`, `a631377`, `ff34a6e`, `21494e6`)
**Plan:** [`../superpowers/plans/2026-07-30-one-ship-04-daily-loop-restructure.md`](../superpowers/plans/2026-07-30-one-ship-04-daily-loop-restructure.md) §11
**Spec:** [`../superpowers/specs/2026-07-30-daily-loop-asks-design.md`](../superpowers/specs/2026-07-30-daily-loop-asks-design.md)

W4 rebuilt the daily loop around a question. The day-open no longer hands out a
reward before the user has done anything; it asks *"What's on your heart
today?"*, and the answer drives the reflection.

**Why a device pass and not just the suite.** 2900+ automated tests cover the
state machine, the markers and the routing. What they cannot see: whether the
card actually appears before the AI answers, whether the keyboard covers the
field on a real 6.1" screen, whether a widget tap on a cold launch lands where
it should, and whether any of it *feels* like a ceremony rather than a form.
Everything below is a thing to do with your thumb.

**Time budget:** ~60–75 min for the full sweep, plus a second session the next
day for §7 (cross-midnight) if you want that verified rather than reasoned.

**Legend**

- 🔴 **BLOCKER** — do not ship if this is wrong.
- ♻️ **REGRESSION-RISK** — worked before W4; W4 could plausibly have broken it.
- ✨ **NEW SURFACE** — did not exist before W4; being seen for the first time.
- ⚠️ **KNOWN GAP** — already understood and deliberately unfixed. Confirm it
  behaves as described; do not file it as new.

---

## Pre-flight

### Build

```bash
cd flutter
flutter run --release -d <device_id> --dart-define-from-file=env.json
```

Release, not debug: §2's latency check is meaningless in debug, where the
reveal animation and the AI call are both slower for unrelated reasons.

### Account state you will need

You need to reach **a day where nothing has been done yet**, more than once.
Settings → "Reset daily loop" is the lever, and it clears **both** day-open
gates alongside the loop state.

> That pairing was broken until `e5faf16`: W4 added a second, user-local
> gate and every reset path cleared only the original UTC one, so a "reset"
> re-armed the overlay while leaving the question suppressed for the rest of
> the local day. If you are testing a build older than that, expect the
> question not to return after a reset and do not file it — update instead.

- **A free account past warmup** is the honest default. `warmupBudget` gives a
  fresh free user 5 uncounted discovers, so a brand-new account will not meet
  the daily cap and §9 will silently pass for the wrong reason.
- **A premium account** for one pass of §1, to confirm nothing gates.
- Note the account's timezone. §7 is written for a **UTC-negative** zone
  (Americas); if the device is UTC-positive the disagreement runs the other way
  and the check is different — see the note there.

### Before you start

Screenshot the home screen. §8 asks whether the CTA is above the fold, and
that is much easier to judge against a before.

---

## 1. 🔴 The full new day-open, end to end ✨

The wave in one run. Do this first; if it does not hold together, the rest is
detail.

1. Force-quit. Relaunch into the app's first open of the day.
2. **The ambient frame appears.** Lantern, streak count, greeting, *"Begin
   today"*, and a quiet *"Not now"*.
   - ✅ **No Name anywhere on this screen.** No "Today's Name", no "Your
     Starting Name", no Arabic calligraphy. This is the check that the last
     unearned-Name surface is gone.
   - ✅ No reward strip, no "Claim Reward", no day counter.
   - ✅ It reads as *glanceable* — you could take it in and tap through in
     about two seconds.
3. Tap **Begin today**.
4. **The question appears** on the emerald sacred canvas.
   - ✅ Header: *"What's on your heart today?"*
   - ✅ Placeholder: *"A worry, a thanks, a question — however it comes out."*
     🔴 **This line is load-bearing** — it is the only thing telling the user a
     grateful answer is allowed. If it is missing or truncated, that is a
     blocker, not a copy nit.
   - ✅ A one-line muḥāsabah gloss. ✅ Muḥāsabah is **not** on any button.
   - ✅ Seven chips below the field. ✅ *"Not right now"* visible **without
     scrolling**.
5. Type a real sentence — something you would actually write.
6. Tap **Continue**.
7. 🔴 **The card reveal must start immediately.** See §2.
8. Tap through the beat flow. ✅ The reflection is about **what you typed**,
   not about the card's generic blurb.
9. Tap **Ameen**.
10. ✅ **The ceremony appears now** — "Day N", what you earned, past tense.
    ✅ Nothing on it is tappable; there is no second thing to collect.
11. ✅ Streak incremented. ✅ Lantern lit.

**Run this once on premium too.** Nothing in the sequence should gate, prompt,
or mention upgrading.

---

## 2. 🔴 The reveal does not wait on the AI ✨

The single most important timing property in the wave, and the one the April
2026 commit removed the questions to protect.

Between tapping **Continue** and seeing your **card**, count.

- ✅ The card reveal starts **immediately** — sub-second, no spinner.
- ✅ The reflection may arrive later; the canvas covers the wait.
- ❌ If you see a loading state *before* the card, that is a blocker. It means
  something re-introduced an `await` between submit and reveal.

Worth doing twice: once on good WiFi, once on a deliberately poor connection
(Network Link Conditioner, or walk to the edge of range). **The gap between
those two runs should be invisible at the card**, and visible only in how long
the reflection takes to land.

---

## 3. 🔴 Defer — "Not right now" ♻️✨

The escape hatch, and the thing most likely to be wrong in a way that costs a
day's reward.

1. Reach the question. Tap **Not right now**.
2. ✅ You land on **home**.
3. ✅ **Nothing was consumed**: no card, no reveal, no tokens, no streak
   change, no XP.
4. ✅ The home CTA is in its **not-started** state (filled emerald), above the
   fold, and looks like the day is still available.
5. **Background the app and reopen it.** ✅ 🔴 **The question does not throw
   itself at you again.** Auto-entry is once per local day; after a defer the
   CTA is the only way in. Repeat two or three times — this is the check that
   the exit does not feel fake.
6. Tap the home CTA. ✅ You get the **full flow from the top** — question,
   answer, reveal.
7. Complete it. ✅ 🔴 **The reward is claimed normally.** Deferring earlier
   must not have cost the day's reward or reset the ladder.

Then, separately:

8. Reach the question again on a fresh day and leave with the **system back
   gesture** rather than the button.
   ✅ Same outcome: nothing consumed, and no re-throw on the next open. (The
   day marker is stamped when the app *asks*, not when you decline, precisely
   so this path behaves.)

---

## 4. 🔴 Entry paths — all three reach the question ✨

| Entry | Expected |
|---|---|
| Day-open (first launch of the day) | Ambient frame → question |
| Home CTA | Straight into the question |
| Home-screen widget tap | Straight into the question |

Then the one that was actually broken before this wave:

1. **Enter via the widget** and complete the whole loop through "Ameen".
2. Return to the home screen, wait, and **relaunch the app**.
3. ✅ 🔴 **The day-open does not fire.** Before W4 the launch marker was
   written only by the overlay, so a widget user who finished everything met
   the day-open again an hour later on a day already done.

Do this on a **cold launch** as well as a warm one — the widget deep link
replays differently in each.

---

## 5. 🔴 The duʿā-widget race ♻️

**A bug W4 would have introduced.** It needs eyes on a device because it is a
timing race that no test can reproduce faithfully.

1. Force-quit the app entirely.
2. From the home screen, tap the **duʿā-times widget** (Build-a-Duʿā), *not*
   the daily-Name widget.
3. ✅ 🔴 **You land on the duʿā screen and stay there.**
4. ❌ If the day-open appears over it, or you end up in the muḥāsabah question,
   that is a blocker — the app has taken someone who asked for one thing and
   put a question about their heart in front of them.

Repeat **at least three times**, including once on a slow/no network — the race
is between a network reconcile and the deep-link replay, so a slow network makes
the bad ordering *more* likely, not less. Also try it as the very first launch
of the day, when the day-open genuinely wants to fire.

---

## 6. 🔴 Pop-then-route ♻️

1. First launch of the day → ambient frame → **Begin today**.
2. You are now on the question.
3. **Swipe back** (or press back on Android).
4. ✅ You reach **home**.
5. ❌ 🔴 If you land back in the day-open frame, the overlay was left mounted
   underneath — an opaque route that was routed past rather than popped.

---

## 7. Cross-midnight — the UTC/local seam ✨

The case the two-clock design exists for. **Needs two sessions**, or a device
clock you are willing to move.

Written for a **UTC-negative** zone (e.g. America/Los_Angeles, UTC-7):

1. **Local afternoon** (say 16:00): complete the whole loop.
2. **Same local evening, after 17:00 local** — which is past **UTC midnight**:
   force-quit and relaunch.
3. ✅ 🔴 **No second question.** No day-open. The local day has not turned over,
   and the app must not ask again just because the UTC date rolled.
4. Next morning, local: ✅ the day-open fires normally and the question returns.

**If your device is UTC-positive** (Europe/Asia), the disagreement runs the
other way: the local day turns over *before* UTC. Expected behaviour there is
that the day-open may not fire until the UTC day catches up, and **the home CTA
still works the whole time**. That is pre-existing launch-gate behaviour, not a
W4 regression — the design deliberately fails toward not-asking. Confirm you are
never *blocked*, only occasionally not auto-entered.

---

## 8. Home screen ♻️

1. ✅ The CTA is **above the fold** on this device without scrolling. Compare
   against your pre-flight screenshot.
2. ✅ It does not read as one row in a settings stack.
3. ✅ It is not labelled "Begin Muhāsabah"; it names the job.
4. ✅ No 11px question subtitle under it.
5. Complete the day, return home. ✅ The **completed state** is designed —
   not an unstyled text row.

---

## 9. Gating and caps ♻️

W4 Wave 1 moved the charge off the CTA and into the reveal, which is the
riskiest edit in the wave.

1. **Open the question and back out** (§3). ✅ Nothing consumed — verify by
   completing successfully afterwards on the same day.
2. **Double-tap the home CTA** hard. ✅ One question, one reveal, one charge.
3. On a **capped free account**, tap the CTA. ✅ You are told *before* being
   asked to disclose anything — the cap sheet appears at the tap, not after
   you have typed your sentence.
4. ✅ The **day's first reveal is free and unmetered** for everyone.
5. If you can reach warmup exhaustion (5 discovers), ✅ the warmup-exhausted
   sheet still appears, once.

---

## 10. The widget's awaiting state ✨

⚠️ Wave 6 flagged this as **type-checked but never rendered** — the Swift
extension recomputed its own Name and ignored the Dart payload unless
`mode == "personalized"`. So this is genuinely first-time-seen on a device.

Check **small and medium** families:

1. **Before the day's reveal:** ✅ lantern + streak, ✅ **no Name at all** —
   no Arabic, no transliteration, and **no teaching line** (the anchor is that
   Name's teaching line and would smuggle the claim back in through copy).
   ✅ It reads *"What's on your heart today?"* — the same sentence as the home
   CTA and the question screen.
2. **Complete the loop.** ✅ Within a reasonable interval the widget flips to
   the **real revealed Name**.
3. ✅ The Name on the widget is **the one you actually got**, not a rotation.

---

## 11. Off-topic input ⚠️

Type something the classifier will reject — a shopping list, a URL, keyboard
mash.

**Expected behaviour at time of writing:** the canvas shows *"Share how you're
feeling, and I'll find a Name for it."* with **"Return home" as the only
action**.

⚠️ **The re-ask is a known gap and is still in flight.** There is deliberately
no "Try again" button, because re-entering the question after a reveal has
already happened needs a guard against running a second reveal for the day.

- ✅ Confirm the copy reads as an **invitation**, not an error or a scolding.
- ✅ Confirm the user **keeps their card, streak and reward** — only the day's
  reflection is lost.
- ❌ Do **not** file "no way to try again" as a new bug. If the re-ask fix has
  landed by the time you test, the expected behaviour changes to: original text
  pre-filled, a way forward, and **still exactly one reveal for the day** —
  check that last part hardest.

---

## 12. The tour coachmark ♻️

Legacy/replay path only (Settings → replay tour).

✅ The coachmark pointing at the home CTA must **not name a button that does
not exist**. W4 Wave 5 renamed the CTA; a hint saying "Tap Begin Muhāsabah"
reads as the app being broken.

The fix has landed — the step is now positional (*"Tap here to begin today's
reflection"*), which cannot drift when the CTA is renamed again. ✅ Confirm the
coachmark actually lands on the CTA and that tapping through advances the
tour.

---

## 13. Accessibility ✨

On **every new surface** (ambient frame, question, ceremony):

1. **Dynamic Type at the largest non-accessibility size, then the largest
   accessibility size.**
   ✅ Nothing clips. ✅ The question's field, chips and *"Not right now"* all
   remain reachable. ✅ Tap targets stay ≥44pt.
2. **RTL** (Settings → language → Arabic, or the RTL debug toggle).
   ✅ Layout mirrors cleanly. ✅ 🔴 **No Arabic/English bleed** — no Arabic
   text leaking direction into an adjacent English line, or vice versa. Check
   the ceremony and the beat flow especially, where Arabic and English sit
   closest together.
3. **VoiceOver** on the question screen.
   ✅ The header is announced as a heading. ✅ The placeholder is read as the
   field's hint. ✅ The chips announce as buttons with their full sentence.
   ✅ *"Not right now"* is reachable and clearly labelled.
4. **Reduce Motion** on.
   ✅ Entrances still resolve; nothing is stuck invisible or mid-animation.

---

## 14. Keyboard behaviour on a real screen ✨

The house pattern is meant to make this impossible, but it has only ever been
verified in a test viewport.

1. Tap into the field. ✅ The keyboard does not cover the field or the
   Continue button.
2. Type several lines. ✅ The field grows; nothing overflows the bottom.
3. ✅ *"Not right now"* stays visible **above the keyboard**.
4. Dismiss the keyboard. ✅ Layout settles without a jump.
5. Repeat on the **smallest device you have** (SE-class if possible).

---

## 15. Failure and interruption ♻️

1. **Airplane mode, then answer the question.**
   ✅ You get a real error or retry path. ✅ 🔴 **Never a wrong Name** — the
   app must not substitute a Name it did not actually unseal.
   ✅ Recover: turn networking back on, retry, and confirm the day completes.
2. **Force-quit mid-question** (text typed, not submitted).
   ✅ Relaunch is coherent. ✅ Nothing was consumed.
3. **Force-quit mid-reveal** (after Continue, before Ameen).
   ✅ Relaunch does **not** run a second reveal. ✅ The day resumes rather than
   restarting. This is the phantom-second-gacha bug class — treat any second
   card as a blocker.
4. **Background mid-beat-flow for several minutes**, then return.
   ✅ You are where you left off.

---

## 16. Copy firewall ♻️

A read-through rather than a test. Across everything you saw today:

- ✅ No countdown, clock or timer anywhere near the reveal.
- ✅ No guilt phrasing — nothing about missing out, breaking a streak, or
  letting anything down, especially on the way *out* of the question.
- ✅ No tier word ("premium", "gold") adjacent to a Name.
- ✅ No "sign"/"meant for you" language near a price.
- ✅ Nothing on re-entry references having skipped earlier.

---

## Reporting

For anything that fails, capture: **device + iOS version**, **account tier**,
**local time and timezone**, whether it was a **cold or warm launch**, and the
**entry path** (day-open / CTA / widget). The day-open behaviours in §3, §4, §5
and §7 are all sensitive to at least one of those, and a report without them
usually cannot be reproduced.

File findings in `docs/qa/findings/` as `2026-07-30-w4-<slug>.md`.

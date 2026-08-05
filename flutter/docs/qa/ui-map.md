# Sakina iOS Sim UI Map

Living reference for iOS simulator MCP automation. Every coordinate is in **logical points** (what `mcp__ios-simulator__ui_tap` expects). Screenshots are 2x → if you read a coord off a `.png`, divide by 2.

## Device

- Simulator: **iPhone 17**, UDID `E1152EC8-6A80-4966-92D9-7D7425A81CD2`
- Logical viewport: **402 × 874** (width × height in points)
- Screenshot pixel size: 804 × 1748 (2x)
- Bundle ID: `com.sakina.app.sakina`
- idb companion: `idb_companion --udid <UDID> --grpc-port 10882 &` (required for ui_tap / ui_type / ui_describe_all / ui_swipe)

## Global chrome

- **Status bar:** y 0–62
- **Bottom tab bar:** y 784–840, 5 tabs of width 80.4 each
  - Home tab center: (40, 812)
  - Collection tab center: (120, 812)
  - Reflect tab center: (200, 812)
  - Duas tab center: (280, 812)
  - Journal tab center: (360, 812)
- **No Settings tab** — Settings is opened via top-right icon on Home.

## Screens

### Home (signed-in)

Route: `/`

Top-right icons at y≈127:
- Icon 1: **(316, 127)** — purpose TBD (likely notifications/bell)
- Icon 2: **(360, 127)** — **Settings** ✅ confirmed

Content:
- Header "Assalamu Alaykum!": top-left, y≈127
- Level/Title pill: left, y≈223
- Streak + XP: right, y≈223
- XP progress bar: y≈248
- "Today's Name" card: centered, y≈380 (tappable → name detail, probably)
- "Begin Muḥāsabah" card: y≈588
- "Quests" card: y≈675
- "Discover Your Anchor Names" card: y≈740

### DailyLaunchOverlay

Shown on first app open each day (if unclaimed daily reward). Dismisses itself once shown for the day — relaunch skips it.

Step 0 (Streak intro):
- "1 day streak" headline centered y≈315
- Today's Name card y≈520
- **Begin button: (201, 711)** → advances to reward claim step.

Step 1 (Daily Reward):
- D1–D7 progress circles at y≈880 (pixel) / logical ~440 — recheck when revisited
- "10 Tokens / Day 2 reward" card
- **Claim Reward button** — ⚠️ DO NOT tap in QA unless claiming is intended (writes `user_daily_rewards`).

Dismiss without claiming: force-quit + relaunch (`launch_app terminate_running:true`).

### Settings

Route: pushed from Home top-right gear.

Scroll order top → bottom:
1. Back button (top-left) + "Settings" title
2. Profile card (avatar + email)
3. Streak/Total XP tiles
4. "Your Title" card (tap pencil to edit; icon at ~(1045, 1367) px → logical ~(523, 684) — off-screen, recheck)
5. "Your Anchor Names" + Take the Quiz button
6. **Store row** → `/store`
7. **Account section → Sign Out** ← confirmed at **(200, 585)** after scrolling up to top
8. Preferences: Push Notifications / Daily Reminder / Streak Reminders / Weekly Reflection / Come Back Nudge / New Content & Updates (all toggles)
9. About: Version / Privacy Policy / Terms of Service
10. Danger Zone: Reset Daily Loop / Clear Card Collection / Delete Account

**Sign Out confirmation dialog** (AlertDialog):
- Title "Sign Out" y=381
- Body "Are you sure you want to sign out?" y=429
- **Cancel button center: (194, 497)**
- **Sign Out (confirm, destructive) button center: (276, 497)**
- Tapping outside dialog (anywhere on "Dismiss" barrier) does NOT dismiss (barrierDismissible likely true for AlertDialog default but confirmed by code — tap Cancel to exit cleanly).

**Sign Out row tap target (post-scroll):** With Settings scrolled so the Account section is visible, the Sign Out row sits at center **(201, 432)** (frame 24.5, 405, 353×54). At top scroll the row is offscreen below the fold; swipe up modestly until the "Account" header is visible at y≈400.

**Toggle switch column (Preferences section):** all 6 switches share x≈331 (frame 301.5, w=60). Y centers, top → bottom, with header "Preferences" visible:
- Push Notifications: y=221
- Daily Reminder: y=286
- Streak Reminders: y=351
- Weekly Reflection: y=416
- Come Back Nudge: y=481
- New Content & Updates: y=546

When master Push Notifications is OFF, the 5 sub-toggles render visually disabled (greyed) but their `AXValue` still reflects the per-category column's stored value. Tapping the master ON when iOS perm is denied triggers the iOS-style "Open Settings" dialog and leaves DB `push_enabled=false` (correct three-store integrity gate; see findings/2026-04-26-push-enabled-drift.md).

**Danger Zone row tap targets** (visible after scrolling Settings down past About):
- Reset Daily Loop row: center **(201, 550)** (frame 24.5, 523.5, 353×54)
- Clear Card Collection row: center **(201, 605)** (frame 24.5, 578.5, 353×54)
- Delete Account row: center **(201, 660)** (frame 24.5, 633.5, 353×54)

**Reset Daily Loop confirmation dialog:**
- Title "Reset Daily Loop" y=361
- Body y=409
- Cancel button center: **(232, 517)** (frame 198.84, 493, 67.16×48)
- Reset (destructive) button center: **(306, 517)** (frame 274, 493, 64×48)

**Clear Card Collection confirmation dialog:**
- Title "Clear Card Collection" y=361
- Body y=409
- Cancel button center: **(165, 517)** (frame 131.31, 493, 67.16×48)
- Clear Collection (destructive) button center: **(272, 517)** (frame 206.47, 493, 131.53×48)

**Delete Account confirmation — step 1 (warning):** AlertDialog
- Title "Delete Account" y=351
- Body y=399 (~80h): "This will permanently delete your account and all associated data — streaks, saved reflections, journal entries, and preferences. This cannot be undone."
- Cancel button center: **(212, 527)** (frame 178.46, 503, 67.16×48)
- Continue button center: **(296, 527)** (frame 253.62, 503, 84.38×48). Continue is destructive-styled (red) but advances to step 2 rather than executing.

**Delete Account confirmation — step 2 (type DELETE):** AlertDialog with TextField
- Title "Are you sure?" y=347
- Body "Type DELETE to confirm account deletion." y=395
- Text field (autofocus) frame (65.75, 427, 270.5×56) → center **(201, 455)**. Hint text "DELETE" (placeholder, not pre-filled).
- Cancel button center: **(145, 531)** (frame 111.37, 507, 67.16×48)
- Delete My Account button center: **(261, 531)** (frame 186.53, 507, 149.72×48). **Disabled** (`enabled=false`) until the text field's trimmed value equals exactly "DELETE". Verified in widget tests at `test/features/settings/delete_account_dialogs_test.dart`.

When Delete My Account is tapped: `AuthService.deleteAccount()` → calls `delete_own_account` RPC → FK CASCADE wipes 18 user-owned tables → app calls `signOut()` → routes to `/welcome`. Verified end-to-end on QABot 2026-04-26 (auth_users 1→0, all 11 sampled public tables 0).

**⚠️ Important coord overlap:** the Delete My Account button center (261, 531) sits very close to the underlying Reset Daily Loop row at (201, 550) when Settings is scrolled to the Danger Zone. If the dialog dismisses before the tap registers (or the button is still disabled), a tap at (261, 531) can pass through to Reset Daily Loop. Verify the Delete My Account button is enabled before tapping.

### Welcome / Hook

Route: `/welcome`. Dark emerald background, ornate mihrab illustration centered.

- "Sakina" wordmark header: y=121 (center)
- Mihrab illustration: y~150–500
- Tagline "Tell me how you feel." y=557
- Subtagline "I'll show you what Allah says." y=588
- **Get Started button (primary white pill)**: center **(201, 724)**
- **I Already Have an Account (text link)**: center **(201, 792)** → `/signin`

### Sign-In (TBD)

Route: `/signin`. Not yet captured.

### Onboarding pages 0–25

Common chrome:
- **Back arrow** (top-left): center **(50, 100)**, 44×44 tap target
- **Progress bar**: y=290 on survey pages. Hidden on encouragement pages (12, 21) and the new paywall flow (22-25). Updated 2026-05-05 by paywall flow redesign.
- **Bottom primary button (Continue/Reflect/etc)**: center x=201. Y varies per screen (typically 752+28=780 for full-width pill).

#### Paywall flow pages (22-25, added 2026-05-05)

Page 22 — Generating loader (4 steps over 3.5s); auto-advances. No back button.
Page 23 — Personalized Plan (gold "✨ Crafted for you" ribbon at top, 4 plan tiles, "Continue" CTA).
Page 24 — Your Journey ("Where you'll be in 30 days, {name}." + 3 milestone cards on a gold timeline rail. "Begin my 30 days" CTA).
Page 25 — Paywall (shrunken hero ~28% viewport, gold "YOU'RE 1 STEP AWAY, {name}" line above headline, microcopy below pricing, "No payment due today." line below CTA when trial available).
Coords TBD after manual smoke test on device.

Keyboard handling on sim:
- Hardware keyboard is connected by default → soft keyboard does NOT appear on focus. To force the soft keyboard for scroll/spacing tests:
  ```bash
  # Toggle off hardware keyboard
  defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false
  # (Must be done while sim app is running; menu: I/O → Keyboard → Connect Hardware Keyboard)
  ```
  OR send cmd+K key to the Simulator.app via AppleScript.

#### Page 0 — First Check-in (`progressSegment=0`)

Headline: "How are you feeling today?" y=540.
- **Text field** ("Type how you're feeling..."): frame (28, 415, 346×84) → center **(201, 457)**
- **Emotion chips** row 1 (y=535): Anxious (72, 535), Sad (154, 535), Grateful (239, 535)
- **Emotion chips** row 2 (y=583): Frustrated (82, 583), Lost (175, 583), Hopeful (259, 583)
- **Reflect button** (disabled until input): frame (28, 752, 346×56) → center **(201, 780)**. Validation ✅ (enabled=false when empty).

Observation: text field auto-focuses (cursor visible) but soft keyboard doesn't render because hardware keyboard is attached. No scroll/spacing issue visible in default state.

### Home (signed-in, post-onboarding) — extended

Confirmed 2026-04-22 during core-loop QA run.

Top card (y≈603–707):
- Level badge + title: left, y≈631–683
- Streak flame: y≈657 center-left of token pill
- Tokens pill: center
- Quest / tier-up-scrolls pill: right
- Progress bar thin line: y≈714

Today's Name card:
- "Today's Name" header: y≈928
- Arabic (large, Aref Ruqaa): y≈1050–1280 pixels
- Transliteration + English: y≈1368
- Subtitle: y≈1450–1500

**Begin Muḥāsabah CTA** (only when daily-reward reset + not claimed today):
- Button area y≈1650–1790 (visible as green pill with play icon + "Begin Muḥāsabah" + sub-question)
- Tap center: **(201, 587)** logical — navigates directly to NameRevealOverlay gacha (NOT to muhasabah question flow on fresh-today state)

"Discover a New Name" CTA (after today's claim already done):
- Costs 50 tokens, AI-triggered paid reflect variant
- Tap center: **(201, 680)** logical

### Native notifications dialog (iOS-generated)

Appears on **every** cold launch post-onboarding when notifications are off:
- Title "Open Settings": y≈375
- Body: y≈404–468
- Cancel button: frame (57, 487, 140×48) → center **(127, 511)**
- Open Settings button: frame (205, 487, 140×48) → center **(275, 511)**

### NameRevealOverlay (gacha) — full-screen modal, dark bg

Route: overlay, not a page.

- Tier ribbon ("BRONZE"/"SILVER"/…): centered top, y≈351
- Large Arabic name: y≈480–590
- English name: y≈633
- Subtitle: y≈684
- "NEW CARD" banner: y≈999
- "Your dua was heard…" card: y≈1050–1150
- **Continue button** frame (32, 745, 338×55) → center **(201, 773)**.
- **⚠️ KNOWN BUG:** Continue `Container` lacks `GestureDetector`. A tap on the button text is a no-op. The overlay background dismisses via a parent `onTap` — so the **second** tap (anywhere on the overlay including the button area) advances. Code ref: `lib/features/daily/widgets/name_reveal_overlay.dart`. Fix: wrap Continue in a GestureDetector with `onTap: _handleContinue`.

### Muhasabah / daily result sequence (post-gacha)

Observed as a chain of screens with a single bottom CTA each. On fresh-today state with current_streak=0, the multi-question sequence is SKIPPED (see run log F2); user is dropped into:

**Reflection preview** (after gacha):
- "Your Reflection" label: y≈815 pixel (logical ~407)
- Name card: y≈875–1580 pixel (logical 438–790)
- "Go Deeper" button frame (24, 612.5, 354×56) → center **(201, 640)**

**AI Reflection result:**
- "Reflection" chip (green): y≈277
- Paragraph card: y≈311–554
- "Read the Story" button frame (24, 601.5, 354×53) → center **(201, 628)**

**Story screen:**
- "A Prophetic Story" chip: y≈235
- Paragraph: y≈269–595
- "See the Dua" button frame (24, 643, 354×53) → center **(201, 670)**
- Back label (24, 712, 67×31) → center **(58, 728)**

**Dua screen:**
- "Dua" chip: y≈308
- Large Arabic: y≈342
- Transliteration: y≈440
- English: y≈470
- Source ref (e.g. "Quran 11:61"): y≈501
- "Ameen" button frame (24, 567.5, 354×56) → center **(201, 595)**
- Back label (24, 639.5)

**Muhāsabah Complete:**
- Heading "Muḥāsabah Complete": y≈432
- Subtitle "You've reflected, gone deeper…": y≈464
- "Seek Another Name (50)" button frame (52, 539.5, 298×56) → center **(201, 567)**
- "Return to Home" text link frame (154, 619.5, 94×19) → center **(201, 629)**

### Reflect tab (route: nav tab 3)

Tab-bar center: **(200, 812)**.

Input state:
- "Reflect" H1: y≈94
- Subtitle "Share what is on your heart…": y≈143
- Decorative book icon: y≈266–406
- Text field "What are you carrying today...": frame (25.5, 384.3, 351×176) → center **(201, 472)**. Hardware keyboard attached means soft keyboard does NOT render; ui_type works fine regardless.
- Emotion chips row 1 (y≈598): Anxious (68, 598), Sad (152, 598), Grateful (237, 598)
- Emotion chips row 2 (y≈647): Frustrated (78, 647), Lost (172, 647), Hopeful (257, 647)
- Emotion chips row 3 (y≈696): Lonely (64, 696), Overwhelmed (178, 696)
- **Reflect button** (bottom pill): y≈768–798. Tap center **(201, 778)**.

Follow-up #1 (slider):
- "Skip" link top-right: frame (220, 208, 25×18) → center **(233, 217)**
- Question text: y≈318–396
- Current value (e.g. "5"): y≈432
- Slider: y≈482
- Left label "Not at all": y≈530
- Right label "Very much": y≈530
- Continue text: y≈565–614. Tap **(201, 589)**.

Follow-up #2 (multi-choice, auto-advance on tap):
- Skip link y≈184
- Question y≈281–359
- Options each 306×56 at x=48, vertically stacked 66px apart starting y=387 (Joy/Stress/Anticipation/Creativity pattern). Option centers: **(201, 415)**, **(201, 481)**, **(201, 547)**, **(201, 613)**.

Result card:
- "A Name for your heart" label: y≈256
- Large Arabic: y≈296–364
- English name: y≈382
- "Related Names of Allah:" label: y≈437
- Related name chips (up to 3) at y≈470 and y≈511
- **"See Reflection"** button frame (56, 570, 290×56) → center **(201, 598)**

Detail pages mirror the daily flow (Reflection → Read the Story → Dua → Reflect Again/Return).

### Reflect token gate (free-limit modal)

Shown when `daily_usage_reflect_<date> ≥ 3` and user taps Reflect:
- Scrim covers screen above y=312
- "Daily limit reached" headline: y≈457
- Body "You've used your 3 free Reflect sessions today…": y≈491–530
- "Your balance: N tokens": y≈581
- Primary button frame (24, 628, 354×56) → center **(201, 656)**
- Secondary "Not now" frame (161, 696, 80×48) → center **(201, 720)**

### Journal tab (route: nav tab 5)

Tab-bar center: **(360, 812)**.

List view: Reflection cards with REFLECTION tag / Today / Arabic name / Name / user text excerpt / View full. Card frame (24, 329, 354×173) on first card; tap center for first card **(201, 415)**.

### Journal detail / Reflection detail

Header (fixed):
- Back arrow frame (8, 70, 48×48) → center **(32, 94)**
- "Reflection" title: y≈83
- Delete icon frame (298, 70, 48×48) → center **(322, 94)**
- **Share icon** frame (346, 70, 48×48) → center **(370, 94)**

Body (scrollable from y=126):
- Quoted user text: y≈182
- Green/emerald card with name: y≈262–697
- "Reflection" (text paragraph) block: y≈637+
- Further sections (Quran Verse, A Prophetic Story, Dua) are present in the accessibility tree but offscreen until scrolled

### Share Preview sheet

Opens full-screen when Share icon tapped:
- "Preview" title: y≈266
- Close "X" frame top-left → center **(32, 277)**
- SAKINA wordmark: y≈660
- Large Arabic: y≈800–900
- English name: y≈960
- Verse 1 Arabic + translation + reference: y≈1050–1400
- Dua Arabic + translation + reference: y≈1500–1900
- **"Share" button** (bottom pill): frame (24, 772, 354×52) → center **(201, 798)** (logical). Opens native iOS share sheet; do NOT tap in QA unless testing share sheet specifically.

### Duas tab (route: nav tab 4)

Tab-bar center: **(280, 812)**.

⚠️ **Note:** Duas tab is **Build-a-Dua only**. There is NO browse list / categories /
favorite UI despite manual-test-plan §7's description. See
`docs/qa/findings/2026-04-26-duas-browse-aspirational.md`.

Input state:
- "Build a Dua" H1: y=94
- Subtitle "Describe your specific need...": y=143
- Decorative mihrab illustration: y≈260–390
- 4-step indicator (numbered circles + labels): y=403 (number) + y=432 (label)
  - Praise: x≈64, Salawat: x≈155, Ask: x≈248, Close: x≈340
- Text field "What do you need a dua for...": frame (25.5, 472.5, 351×176) → center **(201, 560)**
- **Build My Dua** button (disabled until input): frame (24, 666, 354×56) → center **(201, 694)**.
  Sage-green when disabled, full-emerald when active.

Loading state:
- Mihrab illustration centered
- Big % counter (e.g., "80%"): y≈380 (logical ~190 with image height conversion — recheck on next visit)
- "Crafting your dua..." subtitle below
- Progress bar
- Stage check pills (Praise / Salawat / Your ask / Closing) row at bottom — fill green as each stage completes

Multi-step result (4 dots progress; one screen per stage):
- Top dots indicator: y≈207 (active = filled gold)
- Stage label (e.g. "Opening Praise" / "Salawat" / "The Ask" / "Closing"): y=176
- Arabic card (green bg, white text): y≈230
- Transliteration: italic gray
- English translation: black body
- **Next button** (last step is "Ameen" instead): frame ~(24, varies, 354×53). Y position
  shifts based on content height — re-measure with `ui_describe_all` per stage. Centers
  observed: stage 2 (201, 586), stage 3 (201, 734), stage 4 Ameen (201, 686)
- ⚠️ Stage 3 ("The Ask") may require scroll-up to reach Next button (long Arabic content).
- Back arrow (top-left, post stage 1): center (32, 92)

Final completion screen ("Ameen"):
- Solid emerald bg (full screen)
- Large "آمين" calligraphy: y≈230
- "Ameen" English: y≈276
- Subtitle "May Allah accept your dua": y≈304
- **Build Another Dua** white pill button: frame (24, 340, 354×56) → center **(201, 368)**
- "Names Called Upon" header: y≈440
- Per-name rows (gold star + transliteration + Arabic + 2-line meaning)
- "Related Duas" section below scroll
- Top-right share icon for the built dua

### Token gate (Build-a-Dua "Daily limit reached")

Bottom-sheet modal. Shown when `built_dua_uses ≥ 3` and user taps Build:
- Scrim/dim above sheet
- Token coin icon: y≈410 logical
- "Daily limit reached" headline: y≈455
- Body "You've used your 3 free Build a Dua sessions today. Spend 50 tokens to continue.": y≈491
- "Your balance: N tokens" pill: y≈580
- Primary "Spend 50 tokens to continue" button: y≈645
- Secondary "Not now" text link: y≈720

### Build-a-Dua off-topic state

- "This place is for your heart" headline: y≈384 logical
- Subtitle "Please describe a sincere need or intention for your dua.": y≈428–460
- **Try Again** button: frame (143, 482, 116×48) → center **(201, 506)**
- ⚠️ **BUG (filed):** Try Again does NOT clear the input field text. See
  `docs/qa/findings/2026-04-26-build-dua-tryagain-no-clear.md`.

### Discovery quiz (route from Home → "Discover Your Anchor Names" or Settings → Take the Quiz)

Full-screen, no nav bar.

Per-question screen (6 questions total):
- Progress segments at top (7 dots/dashes — 6 + completion?): y≈275, currently filled = green
- "Question N of 6" subtitle: y=134
- Back arrow (post Q1): top-left (32, 92)
- Question text card (light bg, large): centered y=181–253 (varies by length)
- 4 answer cards stacked vertically. Frames vary by content length (60 or 86 height).
  Common centers (Q1 layout):
  - Answer 1: (201, 307) for 60-height OR (201, 392) for 86-height first slot
  - Answer 2: (201, 392) or (201, 438)
  - Answer 3: (201, 478) or (201, 536)
  - Answer 4: (201, 564) or (201, 634)

Tapping answer auto-advances (no Continue button).

### Discovery results screen ("Your Anchor Names")

- "Your Anchor Names" H1: y≈338
- Subtitle "These are the Names of Allah that resonate most deeply with your soul": y≈400
- Per-anchor card (3 cards, scrollable):
  - Rank badge (#1, #2, #3) green circle: y≈810
  - Name English: y≈900 (large bold)
  - Arabic calligraphy (gold): y≈1080
  - Anchor headline: y≈1280
  - Detail paragraph: y≈1380
- (No exit/done button observed at bottom — likely auto-routes back or has back button)

### Journal tab — extended (route: nav tab 5)

Tab-bar center: **(360, 812)**.

List view header:
- "Journal" H1: y=94
- "N entries" counter: y=139

Stats card (y≈174–250):
- 4 columns, value y=208, label y=229:
  - Reflections (book icon, green) at x≈80
  - Duas (sparkle icon, gold) at x≈158
  - Names (star icon, gold) at x≈242
  - Best streak (flame icon, orange) at x≈320

Filter pills row (y=274, height 38, width 88 each):
- All: x=25 (default selected, emerald fill)
- Reflections: x=113
- Duas: x=201
- Badges: x=289

Entry list (scroll, starts y≈329):
- Each card 354×~150–175 px tall (varies by user_text length)
- First card y=329, subsequent cards stack with spacing
- Card content: type badge ("REFLECTION" green / "PERSONAL DUA" amber), date right-aligned,
  Name pill (Arabic + transliteration), user_text excerpt italic, "View full" link bottom-right
- Tap any card → detail screen

### Journal detail (built Dua variant)

Header (fixed):
- Back arrow frame (8, 70, 48×48) → center **(32, 94)**
- "Dua" title: y≈83
- Delete (trash) icon frame (298, 70, 48×48) → center **(322, 94)**
  ⚠️ **BUG (filed):** No confirmation dialog before delete. See
  `docs/qa/findings/2026-04-26-journal-delete-no-confirm.md`.
- Share icon frame (346, 70, 48×48) → center **(370, 94)**

Body (scrollable from y=126):
- User need text (the original input): y≈182
- Decorative sparkle: y≈260
- Big green dua card with all 4 sections concatenated (Arabic, transliteration, English):
  y≈286–840+

## Conventions for future edits

- When adding a new screen, capture a screenshot first, run `ui_describe_all`, then record:
  - Route path
  - Key interactive element labels + **logical** (x, y) centers (grab from `AXFrame: {{x, y}, {w, h}}` → center is `(x+w/2, y+h/2)`)
  - Scroll behavior (does content extend below y=784?)
  - Any modal/dialog coords separately (they float above scroll)
- Prefer `ui_find_element` by label for buttons — it's coord-independent and survives layout changes.
- For keyboard-up screens, record two coord sets: keyboard-down and keyboard-up (keyboard takes ~y>520 on iPhone 17).

# Sakina

Islamic spiritual wellness app. User says how they feel → app maps it to a Name of Allah, Quran verses, and a dua. Flutter mobile app with Supabase backend.

## Why This Exists

There is no "Bible Feels for Muslims." 2 billion Muslims, zero polished apps that connect emotions to Islamic scripture. The Christian equivalents (Hallow, Glorify, Bible Feels) have raised $240M+ combined. This is a wedge into that market.

The app does ONE thing: "Tell me how you feel, and I'll show you what Allah says."

## Core Loop (this IS the product)

1. User opens app → "How are you feeling?" (free-text input OR tap from emotion grid)
2. AI matches feeling → returns a Name of Allah + 1-2 Quran verses + a dua
3. User sees a beautiful result card they can save, share, or reflect on
4. Streak tracks daily check-ins. Widget pulls them back in.

Everything in the app serves this loop or retains users around it. If a feature doesn't map to this loop, don't build it.

## Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Supabase (auth, Postgres DB, edge functions, storage)
- **AI:** OpenAI Chat Completions (`gpt-4o-mini`) for emotion → content matching
- **Payments:** RevenueCat (enabled; purchases do not work on iOS simulator — test on a physical device)
- **Paywall:** RevenueCat Paywalls (native, integrated)
- **Analytics:** Mixpanel
- **Push Notifications:** OneSignal
- **State Management:** Riverpod
- **Routing:** GoRouter

## Project Structure

```
lib/
  core/           # Theme, constants, router, app session, utilities
  features/
    auth/         # Apple + Google Sign In
    onboarding/   # Goals, pain points, notifications, paywall
    daily/        # Daily check-in modal, muhasabah, daily rewards, gacha reveal
    reflect/      # AI-powered reflection on feelings
    duas/         # Dua browser & AI suggestions
    names/        # 99 Names of Allah browser
    discovery/    # Discovery quiz (emotion-to-name matching)
    journal/      # Saved check-in history
    collection/   # Collectible cards (bronze, silver, gold, emerald tiers)
    store/        # Premium card shop (free + premium tabs)
    quests/       # Quest system + First Steps beginner quests
    streaks/      # Streak tracking UI
    progress/     # XP/level progress
    settings/     # Profile, preferences, account deletion
  widgets/        # Reusable UI components
  models/         # Data models (Feeling, NameOfAllah, Verse, Dua, Card, etc.)
  services/       # Supabase, AI, analytics, economy, sync services
```

## Commands

```bash
# Run app
flutter run

# Run on specific device
flutter run -d <device_id>

# Build release
flutter build ios --release
flutter build appbundle --release

# Run tests
flutter test

# Run single test file
flutter test test/path/to/test.dart

# Generate code (Freezed, Riverpod codegen)
dart run build_runner build --delete-conflicting-outputs

# Lint
flutter analyze
```

## Design System & UI

IMPORTANT: The UI must feel premium, warm, and spiritually grounded — like opening a beautiful devotional book, not a tech product.

**Design references (study these closely):**

- **Glorify** — THE primary visual reference. Warm cream/off-white backgrounds, editorial layout, generous whitespace, soft rounded cards, navy headings, golden accents. The daily devotional flow (quote → passage → devotional → reflection) is the UX model. Light mode is the default.
- **Hallow** — Reference for the dark mode option. Warm charcoal (NOT pure black), nature photography behind session cards, gold/amber highlights, cream text. Feels like a candlelit chapel. Also reference their session cards and prayer journal UI.
- **Duolingo** — Reference ONLY for gamification UI patterns: streak flame icon, daily progress ring, celebration animations on completion, the "streak freeze" ice cube. Borrow the mechanics and interaction patterns, NOT the bright/playful color palette.
- **Cal AI** — Reference for onboarding flow: short demo video → personalization questions → social proof → paywall. Minimal friction to first value moment.
- **Calm** — Reference for how they make wellness feel premium: soft gradients, nature imagery, rounded shapes, breathing animations.

**Visual direction:**

- Light mode is the DEFAULT. Warm, cream-toned, editorial, like a beautifully typeset mushaf. Dark mode is a secondary option.
- Arabic calligraphy is a first-class visual element displayed large and beautifully, not squeezed into a corner
- Generous whitespace everywhere — 20-30% more padding than feels necessary
- Soft, rounded cards (12-16px border radius) with subtle shadows
- Soft entrance animations on result cards (fade + slight upward drift, 300ms ease-out)
- Islamic geometric patterns used VERY sparingly as decorative accents on section dividers or card backgrounds at 5-8% opacity — never busy or competing with content
- The result card (Name of Allah + verse + dua) must be beautiful enough that users screenshot and share it on Instagram/TikTok unprompted. This is a growth mechanic, not just aesthetics.

**Fonts:**

- Arabic scripture: Amiri (for Quran verses — elegant, naskh style) or Scheherazade New
- Arabic display: Aref Ruqaa for the Name of Allah hero display (decorative, calligraphic)
- English display/headings: DM Serif Display (warm, high-contrast transitional serif — the Google Fonts equivalent of Apple's New York font used by Hallow. Editorial and devotional, NOT a basic serif like Lora or Times)
- English body/UI: DM Sans (clean, rounded, warm sans-serif — same design family as DM Serif Display, pairs naturally. Similar to the body fonts Glorify and Calm use)

**Color Palette — Light Mode (default):**

```
Background:        #FBF7F2  (warm cream — Glorify-style, NOT cold white)
Surface/Cards:     #FFFFFF  (white cards on cream bg for subtle lift)
Surface Alt:       #F3EDE4  (slightly warmer for alternating sections)

Primary:           #1B6B4A  (deep emerald green — traditional Islamic color, grounded and trustworthy)
Primary Light:     #E8F5EE  (soft green tint for selected states, badges, streak backgrounds)
Primary Dark:      #134D36  (pressed/active states)

Secondary:         #C8985E  (warm matte gold — for Arabic calligraphy accents, premium highlights, stars)
Secondary Light:   #F5EBD9  (gold tint for subtle highlights)

Text Primary:      #1A1A2E  (near-black with warmth — NOT pure #000000)
Text Secondary:    #6B7280  (muted gray for captions, timestamps, secondary info)
Text Tertiary:     #9CA3AF  (placeholder text, disabled states)
Text On Primary:   #FFFFFF  (white text on green buttons)

Streak/Success:    #F59E0B  (warm amber — for streak flame, XP celebrations, achievement badges)
Streak Background: #FEF3C7  (soft amber tint behind streak counters)

Error:             #DC2626  (red for errors, broken streaks)
Error Background:  #FEE2E2  (soft red tint)

Border:            #E5E0D8  (warm light border — NOT cold gray)
Divider:           #F0EBE3  (barely visible warm divider)
```

**Color Palette — Dark Mode (optional):**

```
Background:        #1C1917  (warm charcoal — stone-900, NOT cold navy or pure black)
Surface/Cards:     #292524  (stone-800, elevated cards)
Surface Alt:       #1E1B19  (subtle variation)

Primary:           #4ADE80  (bright emerald green — desaturated from light mode for dark bg readability)
Primary Light:     #1A3A2A  (dark green tint for selected states)

Secondary:         #D4A44C  (warm gold — slightly brighter for dark bg contrast)
Secondary Light:   #3D2E1A  (dark gold tint)

Text Primary:      #F5F0EB  (warm off-white — NOT pure #FFFFFF to reduce glare)
Text Secondary:    #A8A29E  (stone-400)

Streak/Success:    #FBBF24  (brighter amber for dark mode visibility)
Error:             #F87171
Border:            #44403C  (stone-700)
```

**Gamification visual patterns (borrowed from Duolingo):**

- Streak flame: warm amber (#F59E0B) icon that glows/pulses when active. Show streak count prominently on home screen.
- Daily check-in ring: circular progress indicator around the user's emotion check-in. Green fill on completion.
- Celebration on save: when user completes a check-in, play a brief confetti/sparkle animation with a gentle haptic. Keep it tasteful — 500ms max, not Duolingo-loud.
- Streak freeze: show as an ice crystal icon in settings. Premium feature.

## Content Data

The 99 Names of Allah, Quran verses, and duas are stored in Supabase. Each Name has:

- `name_arabic` — Arabic text
- `name_transliteration` — English transliteration
- `name_english` — English meaning
- `description` — Brief explanation of the Name's significance
- `emotions` — Array of emotion tags this Name maps to
- `related_verses` — Foreign keys to Quran verses table
- `related_duas` — Foreign keys to duas table

The AI service receives the user's free-text emotion input and returns a structured response mapping to existing content in the database. The AI does NOT generate Quran verses or hadith — it only selects from the pre-verified dataset. This is critical for Islamic scholarly accuracy.

## Economy & Monetization

**Tokens:** In-app currency. Earned via daily rewards, quests, and streak milestones. Gate premium actions (AI reflect, dua generation, card upgrades).

**Cards:** Collectible card system with tiers — Bronze → Silver → Gold → Emerald. Cards are earned through daily gacha (after check-in) or purchased in the Store. Each Name of Allah has a corresponding collectible card.

**XP & Levels:** Users gain XP from check-ins, quests, and achievements. Level progression unlocks cosmetics and titles.

**Titles:** User badges/display names earned from achievements, synced to Supabase via the title service.

**Store:** Two tabs — free cards (earnable with tokens) and premium cards (higher tier). RevenueCat is enabled and drives subscription entitlement; the token economy layers on top. Simulator cannot complete StoreKit purchases — verify purchase flows on a physical device.

## Onboarding Flow

Canonical page order (confirmed 2026-04-22; see `docs/qa/ui-map.md` for coords and `docs/manual-test-plan.md` §3 for test steps):

0. **First Check-in** — "How are you feeling today?" + emotion chips → `NameRevealOverlay` → "Your Reflection" result teaser
1. **Name** — "What should we call you?"
2. **Age range** — 13–17 / 18–24 / 25–34 / 35–44 / 45–54 / 55+
3. **Intention** — "What brings you here?" (Spiritual Growth / Difficult Time / Just Curious / Build a Daily Habit)
4. **Prayer frequency** — 5 options with warm copy
5. **Quran connection** — Daily / Weekly / Occasionally / Rarely
6. **99 Names familiarity** — Just Getting Started / Somewhat Familiar / Very Familiar
7. **Resonant Name picker** — horizontal card carousel; selection becomes first card in collection
8. **Dua topics** — multi-select chips + optional "something else on your heart" text field
9. **Common emotions** — multi-select chips
10. **Aspirations** — pick up to 3 (More patient / More grateful / Closer to Allah / More present / Stronger faith / More consistent)
11. **Daily commitment minutes** — 1 / 3 / 5 / 10 / Custom
12. **Attribution** — "Where did you hear about Sakina?" (multi-select)
13. **Encouragement interstitial** — "You're not alone in this."
14. **Reminder time** — time picker (default 08:00 AM)
15. **Notifications** — OS permission ask ("Enable Notifications" / "Not now")
16. **Commitment pact** — "I commit to X min a day" + Tap to commit
17. **Personalization plan** — "Your plan, <name>" summary
18. **Value prop** — Daily check-in / 99 Names / Journal
19. **Social proof** — 4.9 stars + testimonials
20. **Save Your Progress** — Apple / Google / Continue with Email
21. **Email** — enter email
22. **Password** — ≥6 chars, `Create Account` triggers Supabase signup + analytics identify + onboarding-data persist
23. **Encouragement** — "Something beautiful awaits you, <name>"
24. **Paywall** — RevenueCat (annual + weekly offerings); close X routes to home

Constant: `onboardingLastPageIndex = 25` in `onboarding_provider.dart` (PageView has 26 children; gacha on page 0 is an overlay, not a page).

**Progress bar:** segments show page index 0…22 (paywall + both encouragement interstitials sit outside the bar).

**Key onboarding notes:**
- Social auth (`onSocialAuthComplete`) calls `_next`, not `_goToPaywall` — keeps user in flow
- Password screen calls `persistOnboardingToSupabase` immediately after `authService.signUpWithEmail` (so RLS-authorized writes succeed); `completeOnboarding` also calls it as a belt-and-braces flush
- `saveOnboardingData` in `auth_service.dart` writes to `user_profiles` and must use exact column names: `display_name`, `onboarding_intention`, `onboarding_familiarity`, `onboarding_quran_connection`, `onboarding_attribution`, `age_range`, `prayer_frequency`, **`resonant_name_id`** (NOT `resonant_name_slug`), `dua_topics`, `dua_topics_other`, `common_emotions`, `aspirations`, `daily_commitment_minutes`, `reminder_time`, `commitment_accepted`. A single mis-named column will silently fail the whole UPDATE.
- All survey/feature screens end with `SizedBox(height: AppSpacing.lg)` after `OnboardingContinueButton` for consistent button positioning
- Any text-entry screen must wrap its `Column` in `LayoutBuilder → SingleChildScrollView → ConstrainedBox(minHeight: constraints.maxHeight) → IntrinsicHeight` so the keyboard doesn't cause bottom overflow. `first_checkin_screen`, `sign_up_email_screen`, `sign_up_password_screen` use this pattern.

## Code Conventions

- Use Riverpod for all state management. No setState except in trivial local UI state.
- All API calls go through service classes in `lib/services/`. Never call Supabase or external APIs directly from widgets.
- Models use Freezed for immutability and JSON serialization.
- Error handling: wrap all async calls in try/catch, surface user-friendly error messages via snackbars.
- File naming: `snake_case.dart` for files, `PascalCase` for classes, `camelCase` for variables/functions.
- One widget per file. Keep widget files under 200 lines — extract sub-widgets if they grow beyond this.
- All user-facing strings must be extracted for future localization (Arabic, Urdu, Malay, Turkish, French are priority languages).
- Write unit tests for all service classes and core business logic. Widget tests for critical flows (onboarding, emotion check-in, paywall).

## Daily flow — two muhasabah paths

There are two entry points with intentionally different behavior:

1. **DailyLaunchOverlay** (`lib/features/daily/screens/daily_launch_overlay.dart`) → calls `answerCheckin()` in `daily_loop_provider.dart:465`. Walks the user through 4 check-in questions, then AI-generates a Name match. Used on the "fresh launch of the day" path.
2. **Home's `Begin Muḥāsabah` CTA** routes to `/muhasabah` (`lib/features/daily/screens/muhasabah_screen.dart:173-178`) which auto-triggers `discoverName()` in `daily_loop_provider.dart:402`. **Skips questions entirely**, picks an undiscovered/lowest-tier card, jumps to the gacha animation. Writes `user_checkin_history` with `q1='discover'` and q2/q3/q4 empty. This is **intentional** — empty q2/q3/q4 in the DB on this path is not a bug.

`answerCheckin` is referred to as "legacy — used by deeper reflection" in code comments but is still the live multi-question path on the launch overlay.

## Gotchas

- NEVER generate or fabricate Quran verses, hadith, or scholarly content. All Islamic content must come from the pre-verified database. The AI selects from existing entries only.
- Arabic text rendering in Flutter requires explicit `TextDirection.rtl` and careful font handling. Never mix Arabic and English in a single `Text` widget — use separate widgets with explicit text direction, or use `RichText` with `TextSpan`. Mixing directions in one widget causes RTL bleed into adjacent UI.
- All economy/user data (tokens, XP, streaks, achievements, titles) syncs through `sync_all_user_data()` RPC. Do NOT write directly to individual economy tables from Flutter — always go through the service layer which calls the RPC.
- Public catalog content (names, duas, quiz questions) uses `public_catalog_service.dart` with anonymous read access. No auth is needed to read content — do not add auth guards to public content fetches.
- Supabase Row Level Security must be enabled on all user-facing tables. Users should only access their own journal entries, streak data, check-in history, and economy data.
- The shareable result card is generated as an image (not a screenshot). Use a Flutter widget-to-image approach so the card always looks clean regardless of device.

## Known Bugs

- **Gacha overlay eager-dismiss** (`flutter/lib/features/daily/widgets/name_reveal_overlay.dart`): The outer `GestureDetector` at line ~103 calls `_handleContinue` on *any* tap once `_phase >= 2` — which starts ~1600ms after mount and is ~1200ms before the Continue button is actually rendered (phase 3 at ~2800ms). A user who taps during that window can advance before seeing the reward details. The Continue button *does* have its own `GestureDetector` (line ~407), so tapping the button directly at phase 3 works as expected. Fix option: gate the outer handler on `_phase >= 3` instead of `>= 2`, so taps before the Continue button renders are absorbed. (The prior note about "plain Container with no GestureDetector" is stale — a `GestureDetector` was added; the remaining issue is the phase-2 window.)
- **Arabic text bleeding into header** (e.g. `flutter/lib/features/feelings/screens/home_screen.dart:192`): Mixed Arabic + English in a single `Text` widget causes RTL rendering to bleed into surrounding UI. Fix: split into two separate `Text` widgets with explicit `textDirection` on the Arabic one.

## Aref Ruqaa Font Metric Fix

Aref Ruqaa (`AppTypography.nameOfAllahDisplay`) has a large built-in ascender — ~32% of font size of invisible whitespace above the visible glyphs. This causes Arabic calligraphy to visually bleed into whatever sits above it regardless of `height`, `StrutStyle`, `FittedBox`, or `OverflowBox` — all of those either clip glyphs or don't actually shift the glyph position within its line box.

**The fix:** Use `AdjustedArabicDisplay` (`flutter/lib/widgets/adjusted_arabic_display.dart`) instead of a raw `Text` widget for any large Aref Ruqaa display. It applies `Transform.translate(offset: Offset(0, -(fontSize * 0.05)))` — a small upward visual shift without affecting layout — and you compensate with explicit `SizedBox` padding above/below:

- **Above the Arabic:** `SizedBox(height: 44)` for fontSize 48, scale proportionally for other sizes (e.g. `height: 33` for fontSize 36)
- **Below the Arabic:** `SizedBox(height: 20)`

Do NOT attempt to fix this with `height`, `StrutStyle(forceStrutHeight: true)`, `FittedBox`, `OverflowBox`, `ClipRect`, or negative padding — none of these work reliably across navigation rebuilds.

## What NOT to Build

These remain out of scope — don't get distracted:

- Full Quran reader (Muslim Pro owns this)
- Prayer times / Qibla compass (Muslim Pro, Athan own this)
- Hadith collection browser
- Audio library / nasheed playlists
- Sleep content
- Community features / social
- Chat or AI conversation mode
- Multi-day courses or guided plans
- Dhikr/tasbeeh counter (it's tempting — resist it)

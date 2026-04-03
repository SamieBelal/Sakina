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
- **AI:** Anthropic Claude API for emotion → content matching
- **Payments:** RevenueCat for subscription management
- **Paywall:** Superwall SDK (Flutter) for remote paywall config and A/B testing
- **Analytics:** Mixpanel
- **Push Notifications:** OneSignal
- **State Management:** Riverpod
- **Routing:** GoRouter

## Project Structure

```
lib/
  core/           # Theme, constants, shared utilities, API clients
  features/
    onboarding/   # Onboarding flow screens + paywall trigger
    feelings/     # Emotion input, result display, share card generation
    names/        # 99 Names of Allah browser
    streaks/      # Streak tracking logic and UI
    journal/      # Saved reflections and history
    settings/     # Preferences, account, subscription management
  widgets/        # Reusable UI components
  models/         # Data models (Feeling, NameOfAllah, Verse, Dua, etc.)
  services/       # Supabase client, AI service, RevenueCat, OneSignal
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

## Paywall & Monetization

**Free tier:**
- 1 emotion check-in per day
- Basic result (Name + verse, no extended content)
- Streak tracking
- Widget

**Premium ($49.99/year or $4.99/week with 3-day free trial):**
- Unlimited emotion check-ins
- Full result with tafsir snippet, audio recitation, guided dua
- Streak freeze
- Full history of past check-ins and saved results
- Ad-free

**Paywall placement:** After the user completes their first free emotion check-in and sees the result. They've experienced the value — now gate continued access. Use Superwall for remote paywall config so we can A/B test without app updates.

## Onboarding Flow

1. Hook screen with short auto-playing demo (someone typing a feeling → beautiful result appears)
2. "What brings you here?" (single select: spiritual growth / difficult time / build habits / curious)
3. "What do you struggle with most?" (multi-select: anxiety, sadness, anger, loneliness, motivation, gratitude)
4. Social proof screen (user count + star rating + 1-2 testimonials)
5. Notification permission request with context
6. First free emotion check-in (they experience the core value)
7. Paywall

## Code Conventions

- Use Riverpod for all state management. No setState except in trivial local UI state.
- All API calls go through service classes in `lib/services/`. Never call Supabase or external APIs directly from widgets.
- Models use Freezed for immutability and JSON serialization.
- Error handling: wrap all async calls in try/catch, surface user-friendly error messages via snackbars.
- File naming: `snake_case.dart` for files, `PascalCase` for classes, `camelCase` for variables/functions.
- One widget per file. Keep widget files under 200 lines — extract sub-widgets if they grow beyond this.
- All user-facing strings must be extracted for future localization (Arabic, Urdu, Malay, Turkish, French are priority languages).
- Write unit tests for all service classes and core business logic. Widget tests for critical flows (onboarding, emotion check-in, paywall).

## Gotchas

- NEVER generate or fabricate Quran verses, hadith, or scholarly content. All Islamic content must come from the pre-verified database. The AI selects from existing entries only.
- Arabic text rendering in Flutter requires explicit `TextDirection.rtl` and careful font handling. Test on real devices — emulators sometimes render Arabic incorrectly.
- RevenueCat and Superwall both manage subscription state. RevenueCat is the source of truth for entitlements. Superwall handles paywall presentation only.
- Supabase Row Level Security must be enabled on all user-facing tables. Users should only access their own journal entries, streak data, and check-in history.
- The shareable result card is generated as an image (not a screenshot). Use a Flutter widget-to-image approach so the card always looks clean regardless of device.
- iOS widgets use WidgetKit via a native Swift extension. Flutter communicates widget data through shared UserDefaults / App Groups.

## What NOT to Build

Do not add these features. They are out of scope for the MVP and will cause scope creep:

- Full Quran reader (Muslim Pro owns this)
- Prayer times / Qibla compass (Muslim Pro, Athan own this)
- Hadith collection browser
- Audio library / nasheed playlists
- Sleep content
- Community features / social
- Chat or AI conversation mode
- Multi-day courses or guided plans
- Dhikr/tasbeeh counter (it's tempting — resist it)
# Sakina — Claude Code Project Memory

Islamic spiritual wellness app. User says how they feel → app maps it to a Name of Allah, Quran verses, and a dua. Flutter mobile app with Supabase backend.

> **See also:** [`TODO.md`](./TODO.md) for deferred production-readiness work (Android signing, OpenAI proxy, open bugs, etc.) with triggers and step-by-step recipes. Check before starting any Play Store / TestFlight / App Store release.

## Commands

```bash
# Run app (ALWAYS pass env.json — required for Supabase/OpenAI/RevenueCat keys)
flutter run --dart-define-from-file=env.json
flutter run -d <device_id> --dart-define-from-file=env.json

# Build release
flutter build ios --release --dart-define-from-file=env.json
flutter build appbundle --release --dart-define-from-file=env.json

# Tests + lint
flutter test
flutter test test/path/to/test.dart   # single file
flutter analyze

# Codegen (Freezed, JSON serialization)
dart run build_runner build --delete-conflicting-outputs

# Pre-release tripwire (run before any TestFlight / App Store push)
./scripts/check_no_fake_strings.sh
```

## Critical rules (read first)

- **NEVER fabricate Quran verses, hadith, or scholarly content.** All Islamic content must come from the pre-verified Supabase database. The AI selects from existing entries only — it does not generate scripture.
- **NEVER mix Arabic and English in a single `Text` widget.** Mixed direction causes RTL bleed into adjacent UI. Use separate widgets with explicit `textDirection`, or `RichText` with `TextSpan`.
- **NEVER write to economy tables directly from Flutter.** Tokens / XP / streaks / achievements / titles all flow through `sync_all_user_data()` RPC via the service layer.
- **NEVER skip `--dart-define-from-file=env.json`.** All env values (Supabase, OpenAI, RevenueCat, Mixpanel, OneSignal) are compile-time constants — without the flag the app boots with empty keys and silently degrades.
- **NEVER add server-only secrets to `env.json`.** `SUPABASE_SERVICE_ROLE_KEY` and `REVENUECAT_WEBHOOK_SECRET` belong in Supabase Edge Function secrets only — they would otherwise be baked into every IPA.
- **iOS Simulator screenshots: always `sips -Z 1600 <path>.png` immediately after capture.** Native @3x resolution (~3-5MB) trips Claude Code's image size cap. 1600px is above the internal downscale floor so visual quality is preserved while files drop under 500KB.

## Tech stack

Flutter (Dart) · Supabase (Postgres + Edge Functions + auth + storage) · Riverpod · GoRouter · OpenAI Chat Completions (`gpt-4o-mini`) · RevenueCat (subs + paywall) · Mixpanel · OneSignal. Light mode default; physical device required for any RevenueCat purchase flow (simulator can't complete StoreKit).

## Project structure

```
lib/
  core/           # Theme, constants, router, env, app session
  features/      # auth, onboarding, daily, reflect, duas, names, discovery,
                  # journal, collection, store, quests, streaks, progress,
                  # settings, gifts, referrals, paywall
  widgets/        # Reusable UI
  models/         # Freezed data models
  services/       # Supabase, AI, analytics, economy, sync, gating, gift,
                  # purchase, referral
supabase/
  migrations/     # Source of truth for schema + RPCs + RLS
  tests/          # pgtap files (run via psql in CI)
  functions/      # Edge functions (Deno)
docs/
  superpowers/    # Plans for major features
  qa/             # Manual QA plans, findings, ui-map
  decisions/      # ADRs
  analytics/      # Funnel/flag dimensions + how to query Mixpanel
```

## Analytics & funnel querying

The onboarding→tour→paywall funnel is ONE funnel segmented by feature-flag **super properties** (`flag_onboarding_trim`, `flag_hard_paywall`, `flag_tour_ab`, `tour_variant`, `app_version`) — never separate event streams per flag. Before querying Mixpanel (project `4013350`) or adding funnel instrumentation, read [`docs/analytics/funnel-flags-and-querying.md`](./docs/analytics/funnel-flags-and-querying.md): it documents what each flag differentiates, the canonical event/property schema (incl. `placement` on paywall events, `step_id` vs `step_index` for cross-variant tour funnels), and the gotchas (test-ID exclusion, new events only populate post-release, identity is Simplified-ID-Merge). Add new event-name constants to `lib/services/analytics_event_names.dart`; emit from providers via the static `onAnalyticsEvent` hook pattern (no Riverpod in services).

## Code conventions

- **State management:** Riverpod. No `setState` except trivial local UI state.
- **Service layer required:** never call Supabase or external APIs directly from widgets — always go through `lib/services/`.
- **Models:** Freezed for immutability + JSON serialization.
- **Async errors:** wrap in try/catch, surface user-facing errors via snackbars.
- **File/symbol naming:** `snake_case.dart` files · `PascalCase` classes · `camelCase` vars/functions.
- **Widget size:** one widget per file, keep under 200 lines (extract sub-widgets).
- **i18n-ready:** all user-facing strings should be extractable for Arabic, Urdu, Malay, Turkish, French (priority languages).
- **Testing:** unit tests for service classes + business logic; widget tests for critical flows (onboarding, check-in, paywall).
- **Env values:** import `lib/core/env.dart`, use `Env.openAiApiKey` etc. Never `String.fromEnvironment` inline at call sites.

## Design system

UI must feel premium, warm, spiritually grounded — like opening a beautifully typeset mushaf, not a tech product. Light mode is the DEFAULT (warm cream `#FBF7F2`), dark mode is secondary (warm charcoal, NOT pure black).

- **Colors:** full palettes in `lib/core/constants/app_colors.dart`. Primary is deep emerald `#1B6B4A`, secondary is warm matte gold `#C8985E`.
- **Fonts:** Amiri / Scheherazade New for Quran verses, Aref Ruqaa for Name-of-Allah hero display (use [`AdjustedArabicDisplay`](./lib/widgets/adjusted_arabic_display.dart) — direct Aref Ruqaa text bleeds into surrounding UI). DM Serif Display for English headings, DM Sans for body/UI.
- **References:** Glorify (primary visual reference) · Hallow (dark mode reference) · Calm (premium wellness feel) · Duolingo (gamification mechanics only — NOT the bright palette) · Cal AI (onboarding flow).
- **Generous whitespace (20-30% more padding than feels necessary). Soft 12-16px rounded cards. Islamic geometric patterns ONLY as 5-8% opacity decorative accents.**
- The result card (Name + verse + dua) must be share-worthy unprompted — that's a growth mechanic, not just aesthetics.

## Daily flow — the muḥāsabah path

The single live muḥāsabah path is **`discoverName()`** (`daily_loop_provider.dart`), reached from the Home **`Begin Muḥāsabah`** CTA → `/muhasabah` (`muhasabah_screen.dart`, auto-triggers it). It **skips questions entirely**, picks an undiscovered/lowest-tier card, and jumps to the gacha animation. Writes `user_checkin_history` with `q1='discover'` and q2/q3/q4 empty — **intentional, not a bug**.

`DailyLaunchOverlay` (`lib/features/daily/screens/daily_launch_overlay.dart`) is the **fresh-launch-of-the-day gate** — it shows the streak + today's Name and routes into the daily-reward → home flow. It does **NOT** render a check-in questionnaire.

> **DEPRECATED — do not assume it runs:** the old 4-question `answerCheckin()` flow in `daily_loop_provider.dart` is **dormant**. The launch overlay's `_CheckInStep` question UI was removed 2026-04-26 (see `docs/qa/findings/2026-04-26-launch-overlay-dead-checkinstep.md`), so `answerCheckin` has **no live callers** today — it's preserved only as a reference for the AI-context shape (and so the `check_in_completed{path:'questionnaire'}` instrument fires if a multi-question UI ever returns). In practice `check_in_completed` only emits `path:'discover'`. Delete with the next muhasabah refactor unless the questionnaire returns.

## Onboarding flow

27 pages (0-indexed) when `Env.ratingGateEnabled` is true (26 pages when false). Canonical order is the source of truth in `onboarding_provider.dart` (`onboardingLastPageIndex` constant) and `docs/qa/ui-map.md`. Paywall flow lives at pages 22-26 (loader → plan → journey → rating gate → paywall) with the progress bar hidden — they have their own visual identity.

**Key onboarding gotchas:**
- Social auth (`onSocialAuthComplete`) jumps from page 18 (Save Progress) directly to page 21 (Encouragement), skipping the email/password screens. Pinned by `test/features/onboarding/onboarding_auth_routing_test.dart`.
- Password screen calls `persistOnboardingToSupabase` immediately after `signUpWithEmail` so RLS-authorized writes succeed.
- `saveOnboardingData` in `auth_service.dart` writes to `user_profiles` using **exact** column names — a single mismatched column silently fails the whole UPDATE.
- Any text-entry screen wraps its `Column` in `LayoutBuilder → SingleChildScrollView → ConstrainedBox → IntrinsicHeight` so the keyboard doesn't cause bottom overflow.

## Economy & monetization

- **Premium has two server-side sources:** RevenueCat entitlement (paid path, source of truth for billing) OR `user_profiles.referral_premium_until > now()` / `gift_premium_until > now()` (granted via SECURITY DEFINER RPCs, never converts to RC). `PurchaseService.isPremium()` ORs over all three, cached per-user in SharedPreferences.
- **Tokens / Cards / XP / Levels / Titles:** all sync through `sync_all_user_data()` RPC — never write directly.
- **Cards:** Bronze → Silver → Gold → Emerald tiers, earned via daily gacha or Store. Each Name of Allah has a corresponding card.
- **AI bypass:** free users can pay 25 tokens to bypass the daily 1-use-per-AI-feature cap (max 2/day). Premium users must NEVER reach `GatingService.reserveBypass` — short-circuit pinned at `gating_service.dart`. Entitlement columns (`referral_premium_until`, `gift_premium_until`) and bypass counters are protected by the freemium-guard triggers.

## Public catalog content

99 Names of Allah, Quran verses, duas, and quiz questions are anonymously readable via `public_catalog_service.dart` — no auth needed and no RLS guards. Do NOT add auth on public content fetches.

## Sakina Gift (Ramadan / Eid)

`RamadanGiftCard` (`lib/features/gifts/widgets/`) renders during seeded `islamic_occasions` windows. `claim_sakina_gift` RPC is SECURITY DEFINER, atomic via `INSERT … ON CONFLICT DO NOTHING`, mirrors `expires_at` to `user_profiles.gift_premium_until` via `greatest()` coalesce. Client clock seam: `GiftService.debugGiftClock`. Server is the timestamp authority — client clocks only decide whether to RENDER the card, never grant out-of-window.

## Environment configuration

All env values are compile-time constants via `--dart-define-from-file=env.json`. There is no `flutter_dotenv` and no runtime asset load.

- `env.json` — gitignored, real values.
- `env.example.json` — committed, placeholder shape.
- `lib/core/env.dart` — `Env` constants class. **Add new keys here, never `String.fromEnvironment` inline.**
- `pubspec.yaml` — does NOT bundle `env.json` as an asset.

**`OPENAI_API_KEY` is currently baked into the IPA via `String.fromEnvironment`.** A determined attacker with one IPA and `strings`/Hopper recovers it. Must move behind a Supabase Edge Function proxy before any external TestFlight / App Store release — see `TODO.md` for the recipe. `SUPABASE_ANON_KEY` and RevenueCat public SDK keys are designed to be public; safe to ship.

## What NOT to build

These remain out of scope — don't get distracted:

- Full Quran reader (Muslim Pro owns this)
- Prayer times / Qibla compass (Muslim Pro, Athan own this)
- Hadith collection browser
- Audio library / nasheed playlists
- Sleep content
- Community / social features
- Chat or AI conversation mode
- Multi-day courses or guided plans
- Dhikr / tasbeeh counter (resist it — it's tempting and off-mission)

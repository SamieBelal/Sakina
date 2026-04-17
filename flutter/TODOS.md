# TODOs

Pre-launch code review findings, organized into four parallel workstreams.

| File | Items | Can start now? | Summary |
|------|-------|----------------|---------|
<!-- | TODOS-session-cleanup.md~~ | ~~5~~ | DONE | Sign-out data bleed, cache cleanup, hydration retry | -->
<!-- | [TODOS-economy-bugs.md](TODOS-economy-bugs.md) | 10 | YES | Double-tap spend, silent earn drops, non-atomic rewards | -->
<!-- | [TODOS-premium-grants-polish.md](TODOS-premium-grants-polish.md) | 5 | YES | Concurrency guard, totalSpent zeroing, hardcoded amounts | -->
| [TODOS-revenuecat-integration.md](TODOS-revenuecat-integration.md) | 15 | BLOCKED (RevenueCat setup) | Paywall wiring, entitlement guard, subscription state |

## Pre-Launch Legal/Compliance

- [ ] **Privacy policy update for Mixpanel user profiles.** The analytics plan stores `intention` ("Difficult Time"), `quran_connection`, and `struggles` ("Anxiety", "Grief", "Loneliness") as Mixpanel user profile properties. These are religious-behavior and mental-state signals stored in a third-party analytics platform. The privacy policy must disclose this before App Store submission. Review with legal counsel if available.

  **Extended by the onboarding refactor (spec `docs/superpowers/specs/2026-04-16-onboarding-refactor-design.md`):** the following additional user properties / `user_profiles` columns are captured by the new input-driven onboarding and must be disclosed in the same policy update: `aspirations`, `prayer_frequency`, `age_range`, `common_emotions`, `dua_topics` (+ `dua_topics_other` free text), `resonant_name_id`, `daily_commitment_minutes`, `reminder_time`. Free-text inputs are capped at 280 chars and trimmed client-side before persist. **The onboarding refactor ships after this policy is updated, not before.**
- [ ] **Privacy policy update for Supabase notification preferences.** `user_notification_preferences` table stores `timezone`, `streak_count` (via `user_streaks`), last-active date, and per-category notification toggles. Disclose alongside Mixpanel data collection. (Note: we no longer sync these to OneSignal tags — server-side only.)
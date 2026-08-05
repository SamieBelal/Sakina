# Onboarding: Core Loop First Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the first check-in experience (with gacha reveal) to page 2 of onboarding so users experience the core loop before seeing feature showcases, while keeping all existing screens intact.

**Architecture:** Reorder the `pages` list in `onboarding_screen.dart`, wire the `NameRevealOverlay` into `FirstCheckinScreen`'s result phase, and update each feature showcase screen's framing copy to reference what the user just experienced. No screens are deleted — order changes and copy tweaks only.

**Tech Stack:** Flutter, Riverpod (`StateNotifierProvider`), `flutter_animate`, `GoRouter`, `NameRevealOverlay` (existing widget), `DemoResultData` (existing static data), `AppStrings` (existing constants)

---

## New Page Order (reference throughout)

| Index | Widget | Change? |
|-------|--------|---------|
| 0 | `IntentionScreen` | none |
| 1 | `EncouragementScreen` | none (now follows intention directly) |
| 2 | `FirstCheckinScreen` | **moved from 14 → 2; gacha added** |
| 3 | `FeatureNamesScreen` | **moved + copy tweak** |
| 4 | `FeatureDuaScreen` | **moved + copy tweak** |
| 5 | `FeatureQuestsScreen` | **moved + copy tweak** |
| 6 | `FeatureJournalScreen` | **moved** |
| 7 | `StrugglesScreen` | moved from 1 → 7 |
| 8 | `ValuePropScreen` | moved from 2 → 8 |
| 9 | `FamiliarityScreen` | moved from 3 → 9 |
| 10 | `QuranConnectionScreen` | moved from 4 → 10 |
| 11 | `AttributionScreen` | moved from 5 → 11 |
| 12 | `SocialProofScreen` | moved from 11 → 12 |
| 13 | `NotificationScreen` | unchanged |
| 14 | `GeneratingScreen` | unchanged |
| 15 | `SaveProgressScreen` | unchanged |
| 16 | `SignUpEmailScreen` | unchanged |
| 17 | `SignUpPasswordScreen` | unchanged |
| 18 | `SignUpNameScreen` | unchanged |
| 19 | `PaywallScreen` | unchanged |

---

## Files To Modify

| File | What Changes |
|------|-------------|
| `flutter/lib/features/onboarding/screens/onboarding_screen.dart` | Reorder `pages` list |
| `flutter/lib/features/onboarding/screens/first_checkin_screen.dart` | Add `NameRevealOverlay` push after result is shown; add `demoNameData` field to pass name data to overlay |
| `flutter/lib/core/constants/app_strings.dart` | Add new framing strings for feature showcase screens |
| `flutter/lib/features/onboarding/screens/feature_names_screen.dart` | Swap headline/subtitle to "You just met one — here's your collection" framing |
| `flutter/lib/features/onboarding/screens/feature_dua_screen.dart` | Swap headline/subtitle to post-loop framing |
| `flutter/lib/features/onboarding/screens/feature_quests_screen.dart` | Swap headline/subtitle to post-loop framing |

---

## Task 1: Reorder the pages list in onboarding_screen.dart

**Files:**
- Modify: `flutter/lib/features/onboarding/screens/onboarding_screen.dart`

This is a pure list reorder — no logic changes. The `_next()`, `_back()`, and `_goToPaywall()` methods are index-agnostic (they use relative navigation or hardcoded index 19 for paywall), so they remain correct after reorder.

- [ ] **Step 1: Open the file and locate the pages list**

Open `flutter/lib/features/onboarding/screens/onboarding_screen.dart`. Find the `List<Widget>` (or inline `PageView` children) defining the 20 pages. It currently reads (indices 0–19):

```
0:  IntentionScreen
1:  StrugglesScreen
2:  ValuePropScreen
3:  FamiliarityScreen
4:  QuranConnectionScreen
5:  AttributionScreen
6:  EncouragementScreen
7:  FeatureDuaScreen
8:  FeatureNamesScreen
9:  FeatureQuestsScreen
10: FeatureJournalScreen
11: SocialProofScreen
12: NotificationScreen
13: GeneratingScreen
14: FirstCheckinScreen
15: SaveProgressScreen
16: SignUpEmailScreen
17: SignUpPasswordScreen
18: SignUpNameScreen
19: PaywallScreen
```

- [ ] **Step 2: Reorder the list**

Replace the pages list so it reads:

```dart
final pages = [
  IntentionScreen(onNext: _next, onBack: _back),         // 0
  EncouragementScreen(onNext: _next, onBack: _back),     // 1
  FirstCheckinScreen(onNext: _next, onBack: _back),      // 2  ← moved
  FeatureNamesScreen(onNext: _next, onBack: _back),      // 3  ← moved
  FeatureDuaScreen(onNext: _next, onBack: _back),        // 4  ← moved
  FeatureQuestsScreen(onNext: _next, onBack: _back),     // 5  ← moved
  FeatureJournalScreen(onNext: _next, onBack: _back),    // 6  ← moved
  StrugglesScreen(onNext: _next, onBack: _back),         // 7  ← moved
  ValuePropScreen(onNext: _next, onBack: _back),         // 8  ← moved
  FamiliarityScreen(onNext: _next, onBack: _back),       // 9  ← moved
  QuranConnectionScreen(onNext: _next, onBack: _back),   // 10 ← moved
  AttributionScreen(onNext: _next, onBack: _back),       // 11 ← moved
  SocialProofScreen(onNext: _next, onBack: _back),       // 12 ← moved
  NotificationScreen(onNext: _next, onBack: _back),      // 13
  GeneratingScreen(onNext: _next, onBack: _back),        // 14
  SaveProgressScreen(onNext: _next, onBack: _back, onSocialAuthComplete: _goToPaywall), // 15
  SignUpEmailScreen(onNext: _next, onBack: _back),       // 16
  SignUpPasswordScreen(onNext: _next, onBack: _back),    // 17
  SignUpNameScreen(onNext: _next, onBack: _back),        // 18
  PaywallScreen(onComplete: _completeOnboarding),        // 19
];
```

Note: The exact constructor argument names may differ slightly — match them to what's in the file. The principle is: same widgets, new order.

- [ ] **Step 3: Verify `_goToPaywall` still targets index 19**

Find the `_goToPaywall()` method. It should call `_goToPage(19)` or similar. `PaywallScreen` is still at index 19 — no change needed. Confirm this is still correct.

- [ ] **Step 4: Hot restart and manually tap through pages 0–6**

```bash
flutter run
```

Tap through: Intention → Encouragement → FirstCheckin (input phase only, no need to submit) → FeatureNames → FeatureDua → FeatureQuests → FeatureJournal. Confirm back button works at each step.

- [ ] **Step 5: Commit**

```bash
git add flutter/lib/features/onboarding/screens/onboarding_screen.dart
git commit -m "feat(onboarding): move core loop (first check-in) to page 2, feature showcases to pages 3-6"
```

---

## Task 2: Add NameRevealOverlay to FirstCheckinScreen result phase

**Files:**
- Modify: `flutter/lib/features/onboarding/screens/first_checkin_screen.dart`

Currently, `FirstCheckinScreen` shows a `DemoResultCard` in its result phase with no gacha animation. We want to push `NameRevealOverlay` as a full-screen overlay route immediately when the result phase begins — before the `DemoResultCard` is shown — giving the user the real gacha experience.

The overlay is dismissed by the user tapping "Continue". After dismissal, the existing result card UI (`_buildResult`) is shown as normal. The "Continue" button in `_buildResult` then calls `widget.onNext` to advance onboarding.

**Data mapping:** `DemoResultData` has `nameArabic`, `nameEnglish` (meaning), `nameTransliteration`. `NameRevealOverlay` needs `nameArabic`, `nameEnglish` (transliteration), `nameEnglishMeaning`, `teaching`. We map:
- `nameArabic` → `nameArabic`
- `nameTransliteration` → `nameEnglish` (the transliteration slot)
- `nameEnglish` → `nameEnglishMeaning` (the meaning slot)
- `teaching` → use the verse translation as a short teaching line (e.g. `data.verseTranslation`)
- `card` → `null` (no card object in onboarding)
- `engageResult` → `null` (no card engage in onboarding — overlay will show generic "NEW CARD" state; that's fine)

- [ ] **Step 1: Locate where the result phase is triggered in first_checkin_screen.dart**

Find `completeDemoCheckin()` call site in `first_checkin_screen.dart`. It is called from the "Reflect" button's `onPressed`. After this call completes (it's `async`, 2-second delay), the provider sets `demoCheckinCompleted = true` and the `AnimatedSwitcher` switches to `_buildResult`.

The `_buildResult` method is what we want to intercept — we push the overlay right as the result becomes available, before the card animates in.

- [ ] **Step 2: Add a `_hasShownReveal` flag to state**

In `_FirstCheckinScreenState`, add:

```dart
bool _hasShownReveal = false;
```

This prevents the overlay from re-pushing if the widget rebuilds.

- [ ] **Step 3: Add `_showRevealOverlay` method**

Add this method to `_FirstCheckinScreenState`:

```dart
void _showRevealOverlay(DemoResultData data) {
  if (_hasShownReveal) return;
  _hasShownReveal = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => NameRevealOverlay(
          nameArabic: data.nameArabic,
          nameEnglish: data.nameTransliteration,
          nameEnglishMeaning: data.nameEnglish,
          teaching: data.verseTranslation,
          card: null,
          engageResult: null,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  });
}
```

- [ ] **Step 4: Call `_showRevealOverlay` when result phase becomes active**

In `_buildResult`, at the top before returning the widget tree, add the overlay trigger. Find the line in `_buildResult` that reads something like:

```dart
Widget _buildResult() {
  final feeling = ref.read(onboardingProvider).demoFeelingInput ?? '';
  final data = DemoResultData.forEmotion(feeling);
  // ... returns widget
}
```

Add `_showRevealOverlay(data)` call right after `data` is resolved:

```dart
Widget _buildResult() {
  final feeling = ref.read(onboardingProvider).demoFeelingInput ?? '';
  final data = DemoResultData.forEmotion(feeling);
  _showRevealOverlay(data);   // ← add this line
  // ... existing widget tree unchanged
}
```

The `postFrameCallback` inside `_showRevealOverlay` ensures it fires after the current build frame completes, avoiding "setState during build" errors.

- [ ] **Step 5: Add the NameRevealOverlay import**

At the top of `first_checkin_screen.dart`, add:

```dart
import '../../../features/daily/widgets/name_reveal_overlay.dart';
```

Verify the relative path is correct from `features/onboarding/screens/` to `features/daily/widgets/`.

- [ ] **Step 6: Hot restart and test the full result flow**

```bash
flutter run
```

Navigate to page 2 (FirstCheckinScreen). Enter a feeling (e.g. "anxious"), tap Reflect. After 2-second loading:
- Confirm `NameRevealOverlay` pushes as a full-screen overlay with the 4-phase animation
- Confirm tapping "Continue" in the overlay dismisses it
- Confirm the `DemoResultCard` is visible after dismissal
- Confirm tapping the "Continue" button in `_buildResult` advances to page 3

- [ ] **Step 7: Commit**

```bash
git add flutter/lib/features/onboarding/screens/first_checkin_screen.dart
git commit -m "feat(onboarding): add gacha NameRevealOverlay to first check-in result phase"
```

---

## Task 3: Update feature showcase framing copy

**Files:**
- Modify: `flutter/lib/core/constants/app_strings.dart`
- Modify: `flutter/lib/features/onboarding/screens/feature_names_screen.dart`
- Modify: `flutter/lib/features/onboarding/screens/feature_dua_screen.dart`
- Modify: `flutter/lib/features/onboarding/screens/feature_quests_screen.dart`

The feature showcases now appear *after* the user has experienced the check-in and gacha reveal. Update their headlines and subtitles to reference that experience rather than making forward promises.

- [ ] **Step 1: Add new strings to app_strings.dart**

Open `flutter/lib/core/constants/app_strings.dart`. Add the following constants (place them near the existing `featureNames*` constants):

```dart
// Feature Names screen — post-loop framing
static const featureNamesHeadlinePostLoop =
    'That name is now yours';
static const featureNamesSubtitlePostLoop =
    'Every check-in reveals a Name of Allah. Collect all 99 — each one in bronze, silver, and gold.';

// Feature Dua screen — post-loop framing
static const featureDuaHeadlinePostLoop =
    'Go deeper with a personal dua';
static const featureDuaSubtitlePostLoop =
    'After each check-in you can craft a dua built around your feeling and the Name you just met.';

// Feature Quests screen — post-loop framing
static const featureQuestsHeadlinePostLoop =
    'Come back every day';
static const featureQuestsSubtitlePostLoop =
    'Daily quests, streaks, and ranks grow with your practice. The more you check in, the more you unlock.';
```

- [ ] **Step 2: Update FeatureNamesScreen headline and subtitle**

Open `flutter/lib/features/onboarding/screens/feature_names_screen.dart`. Find the `Text` widgets rendering `AppStrings.featureNamesHeadline` and `AppStrings.featureNamesSubtitle`. Replace them with the new post-loop strings:

```dart
// Before:
Text(AppStrings.featureNamesHeadline, ...)
Text(AppStrings.featureNamesSubtitle, ...)

// After:
Text(AppStrings.featureNamesHeadlinePostLoop, ...)
Text(AppStrings.featureNamesSubtitlePostLoop, ...)
```

The style, animation, and layout are unchanged — only the string constants swap.

- [ ] **Step 3: Update FeatureDuaScreen headline and subtitle**

Open `flutter/lib/features/onboarding/screens/feature_dua_screen.dart`. Apply the same swap for the dua screen:

```dart
// Before (whatever the current headline/subtitle constants are):
Text(AppStrings.featureDuaHeadline, ...)
Text(AppStrings.featureDuaSubtitle, ...)

// After:
Text(AppStrings.featureDuaHeadlinePostLoop, ...)
Text(AppStrings.featureDuaSubtitlePostLoop, ...)
```

- [ ] **Step 4: Update FeatureQuestsScreen headline and subtitle**

Open `flutter/lib/features/onboarding/screens/feature_quests_screen.dart`. Apply the same swap:

```dart
// Before:
Text(AppStrings.featureQuestsHeadline, ...)
Text(AppStrings.featureQuestsSubtitle, ...)

// After:
Text(AppStrings.featureQuestsHeadlinePostLoop, ...)
Text(AppStrings.featureQuestsSubtitlePostLoop, ...)
```

- [ ] **Step 5: Hot restart and read through pages 3–6**

```bash
flutter run
```

Navigate past FirstCheckinScreen to pages 3–6. Read each headline/subtitle and confirm the new copy feels connected to what the user just experienced in the check-in.

- [ ] **Step 6: Commit**

```bash
git add flutter/lib/core/constants/app_strings.dart \
        flutter/lib/features/onboarding/screens/feature_names_screen.dart \
        flutter/lib/features/onboarding/screens/feature_dua_screen.dart \
        flutter/lib/features/onboarding/screens/feature_quests_screen.dart
git commit -m "feat(onboarding): update feature showcase copy to reference completed check-in"
```

---

## Verification (end-to-end)

Run through the full onboarding flow manually:

1. **Page 0 — Intention:** Select an intention, tap Continue
2. **Page 1 — Encouragement:** Read the personalized message, tap Continue
3. **Page 2 — First Check-In:** Type a feeling (or tap a chip), tap Reflect → 2s loading → `NameRevealOverlay` pushes with 4-phase gacha animation → tap Continue in overlay → `DemoResultCard` visible → tap Continue button → advances
4. **Pages 3–6 — Feature showcases:** Confirm each has post-loop copy. The FeatureNames screen should feel like "that card you just got lives here."
5. **Pages 7–12 — Profiling + social proof:** All unchanged, still work
6. **Pages 13–14 — Generating + (redundant check-in if still present):** Confirm the generating theater still advances correctly
7. **Pages 15–19 — Sign-up + paywall:** Confirm `_goToPaywall()` still lands on page 19 (`PaywallScreen`)

**Regression checks:**
- Back button on page 2 goes to page 1 (Encouragement), not to the old page 1 (Struggles)
- `_goToPaywall()` from `SaveProgressScreen` still jumps to index 19
- `currentPage` persisted in SharedPreferences still restores correctly (if user quits mid-onboarding and returns, they land on the right page)

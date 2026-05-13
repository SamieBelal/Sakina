# Settings Premium Entry — Design Spec

**Date:** 2026-05-13
**Status:** Approved + Eng-reviewed, ready for implementation plan
**Author:** brainstorming session w/ Claude
**Revisions:** 2026-05-13 — applied /plan-eng-review decisions
  (Issue 1: native StoreKit sheet via RC SDK, Issue 2: single combined
  `premiumStateProvider`, Issue 3: parameterized row + distinct free card,
  test coverage expanded to 4 files).

## Problem

Apple App Review rejected the binary because the reviewer (iPad Air M3) could
not find the Weekly/Annual Premium subscriptions. Root causes:

1. The paywall only renders at the end of onboarding (page 25). A reviewer who
   skipped/closed onboarding never reached it.
2. There is no persistent "Upgrade to Premium" entry point anywhere in the
   main app for an already-signed-in user.
3. The Store screen sells **token packs** (consumables), not the Premium
   subscription — so a reviewer exploring the app sees the Store but cannot
   find a way to buy a subscription.

Apple's expectation: a clear, persistent upgrade affordance available outside
the onboarding flow.

## Goal

Add a single always-accessible Premium entry in the Settings screen that:

- For **free users**: clearly advertises Sakina Premium (Weekly + Annual) and
  opens the existing standalone paywall at `/paywall`.
- For **premium users**: confirms the active subscription and deep-links to
  iOS / Google Play subscription management.
- For **premium users with a billing issue**: surfaces the problem and routes
  to the same subscription-management deep-link so they can update payment.

Scope is **Settings only**. A Home-screen banner was considered and explicitly
deferred — if Apple bounces a second time we can revisit.

## Non-goals

- No Home banner. (Deferred — Apple's main concern is the existence of a
  persistent entry, not its multiplicity.)
- No renewal-date / plan-name display on the active row. (Question 1 option B/C
  rejected in favor of "Minimal".)
- No duplicate Restore Purchases button. Restore already exists on the Store
  screen as a floating pill; Settings → Store → Restore is two taps and
  Apple-acceptable.
- No iPad-specific layout work. Card is full-width and inherits Settings'
  existing horizontal padding.

## User-facing behavior

The card slot sits in `settings_screen.dart` between the profile card and the
stats row. It has three resolved visual states plus a loading skeleton.

### State 1 — Free / unknown user (the App Review fix)

A warm gold card pulls the eye against the cream Settings background.

- Background: gold gradient (`AppColors.secondaryLight` → `AppColors.secondary`
  at ~12% opacity).
- Border: 1px `AppColors.secondary` at 40% opacity.
- 44×44 gold-tinted circle holding `Icons.workspace_premium_rounded` in
  `AppColors.secondary`.
- Title: **"Sakina Premium"** (`AppTypography.displaySmall` at size 18,
  `AppColors.textPrimaryLight`).
- Subtitle: **"Weekly & Annual plans · Unlock everything"** (`bodySmall`,
  `AppColors.textSecondaryLight`).
- Trailing chevron in `AppColors.secondary`.
- Soft 12% gold drop shadow.

Tap → `context.push('/paywall')`. The route already exists and instantiates
`PaywallScreen(inOnboardingFlow: false, onComplete: () => GoRouter.of(context).pop())`.

### State 2 — Premium · active

Subtle row that confirms status without shouting at a paying user.

- Background: `AppColors.surfaceLight` (matches other settings cards).
- 22px `Icons.workspace_premium_rounded` in `AppColors.primary` (emerald, not
  gold — signals "you're in").
- Title: **"Sakina Premium"**.
- Subtitle: **"Active · Manage subscription"** in `textSecondaryLight`.
- Trailing chevron.

Tap → calls `Purchases.showManageSubscriptions()` from the RevenueCat
Flutter SDK (`purchases_flutter`). This presents the StoreKit-native
"Manage Subscriptions" sheet *inside the app* on iOS 15+ (no app-switch
to Safari/App Store) and auto-falls-back to the platform URL on older
iOS. On Android it presents the Play Store subscription manager. This
is Apple's canonical post-iOS-15 mechanism and gives App Review the
expected modern UX.

### State 3 — Premium · billing issue

Same row shape as State 2, amber-tinted to signal action needed.

- Background: `AppColors.streakBackground` (existing soft amber tint).
- Border: 1px `AppColors.streakAmber`.
- Icon: `Icons.warning_amber_rounded` in `AppColors.streakAmber`.
- Title: **"Payment issue"**.
- Subtitle: **"Tap to update payment"**.
- Trailing chevron in `AppColors.streakAmber`.

Tap → same `Purchases.showManageSubscriptions()` call as State 2 (where
the user updates their card).

### Loading state

While either driving provider is loading on first build, render a neutral
skeleton row at the same height as the resolved states (~78px) so the page
does not jump.

## Architecture

### Providers — single combined `premiumStateProvider`

A single `FutureProvider<PremiumState>` replaces the existing
`isPremiumProvider`. Lives in
`lib/features/daily/providers/daily_rewards_provider.dart`.

```dart
typedef PremiumState = ({bool isPremium, String? billingIssueAt});

final premiumStateProvider = FutureProvider<PremiumState>((ref) async {
  final service = PurchaseService();
  final isPremium = await service.isPremium();
  final billingIssueAt =
      isPremium ? await service.getBillingIssueDetectedAt() : null;
  return (isPremium: isPremium, billingIssueAt: billingIssueAt);
});
```

**Why combined:** atomic snapshot of premium state in one `AsyncValue`. Two
separate providers would let one resolve while the other was loading or
errored, producing an inconsistent intermediate state on the card. The
combined provider also short-circuits the billing-issue fetch for free users
(no point asking RC for a billing issue on a non-subscriber).

**Migration cost:** ~18 existing `isPremiumProvider` call sites get updated
to `premiumStateProvider` and read `.value?.isPremium`. Mostly mechanical;
each site already handled the `AsyncValue` shape.

### State resolution

The card watches the combined provider. Resolution priority:

```
AsyncValue.loading                          → Loading skeleton
AsyncValue.error                            → State 1 (graceful fallback)
state.isPremium == false                    → State 1 (Free)
state.isPremium && billingIssueAt != null   → State 3 (Billing issue)
state.isPremium && billingIssueAt == null   → State 2 (Active)
```

The error → State 1 fallback ensures that a transient RevenueCat failure never
hides the upgrade affordance from a free user (the App Review failure mode we
are explicitly solving).

### Invalidation seams

Every existing `ref.invalidate(isPremiumProvider)` call site flips to
`ref.invalidate(premiumStateProvider)` as part of the migration. Known
call sites (audit during implementation):

- `paywall_screen.dart:_completePurchaseFlow` (purchase success).
- `paywall_screen.dart:_handleRestore` (restore success — current code
  already invalidates via `_completePurchaseFlow`, no change needed).
- `invalidateAllUserProviders` in `lib/core/utils/invalidate_providers.dart`
  (sign-out, account deletion).
- Any other site surfaced by `grep -rn "isPremiumProvider" lib/`.

### Lifecycle refresh (returning from App Store)

When the user fixes payment via the StoreKit sheet and returns, the provider
must re-fetch so the card updates without manual refresh. (Even though
`showManageSubscriptions` presents in-app, on iOS <15 RC falls back to the
URL which does background the app; the lifecycle hook covers that.) The
card listens for `AppLifecycleState.resumed` via a `WidgetsBindingObserver`
and calls `ref.invalidate(premiumStateProvider)`. Observer is added in
`initState` and removed in `dispose`. Scoped to the card widget — no
app-wide lifecycle plumbing.

### Widget structure

```
lib/features/settings/widgets/settings_premium_card.dart
├─ class SettingsPremiumCard extends ConsumerStatefulWidget
│  └─ State: WidgetsBindingObserver for didChangeAppLifecycleState
├─ class _PremiumCardFree extends StatelessWidget    (State 1 — distinct
│                                                     gold card layout)
├─ class _PremiumCardRow extends StatelessWidget     (States 2, 3, and
│                                                     loading skeleton —
│                                                     parameterized by
│                                                     icon, iconColor,
│                                                     bgColor, borderColor,
│                                                     title, subtitle,
│                                                     onTap)
└─ Future<void> _openManageSubscription(BuildContext) (calls
                                                       Purchases
                                                       .showManageSubscriptions
                                                       with try/catch +
                                                       snackbar fallback)
```

**Why parameterized row + distinct free card:** States 2, 3, and the loading
skeleton share the same icon-title-subtitle-chevron scaffold and differ only
in colors and copy. One parameterized widget eliminates ~3 copies of the
scaffold. State 1 is genuinely different (gold gradient, larger icon disc,
heavier visual weight) and stays its own widget.

Sub-widgets take only a tap callback and the analytics-event name. Keeps
each visual state independently testable.

File size budget: ≤200 lines per CLAUDE.md convention.

### Settings screen edit

A 3-line insert in `settings_screen.dart` `build()`, immediately after
`_buildProfileCard()`:

```dart
const SizedBox(height: AppSpacing.md),
const SettingsPremiumCard(),
const SizedBox(height: AppSpacing.lg),
```

No refactor of `_buildSettingsList` or any other Settings section.

### Manage Subscription mechanism — native StoreKit sheet

`purchases_flutter` is already a project dependency (powers the paywall).

```dart
Future<void> _openManageSubscription(BuildContext context) async {
  try {
    await Purchases.showManageSubscriptions();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not open subscription management. '
          'Open the App Store directly to manage your subscription.',
        ),
      ),
    );
  }
}
```

`Purchases.showManageSubscriptions` presents StoreKit's native sheet on
iOS 15+ (in-app, no app-switch) and auto-falls-back to the platform URL
on older OSes. Handles both iOS and Android. This is the Apple-canonical
post-iOS-15 pattern — exactly what App Review expects to see in a modern
subscription app.

### Analytics

Three new events tracked via the existing `analyticsProvider`. Names follow
the project's existing `paywall_*` event style:

- `settings_premium_cta_tapped` (free → paywall)
- `settings_premium_manage_tapped` (active → store)
- `settings_premium_billing_issue_tapped` (billing issue → store)

## Edge cases

| Case | Behavior |
|------|----------|
| RevenueCat not initialized | `isPremium()` returns false → State 1. User can still tap → paywall (which has its own offline messaging). |
| `isPremium` errors | State 1 fallback (never hide the upgrade affordance from a free user). |
| Stale state after purchase | `paywall_screen.dart:_completePurchaseFlow` already invalidates `isPremiumProvider`; we add the sibling invalidate. Card flips on return. |
| Returning from App Store | `didChangeAppLifecycleState(resumed)` invalidates both providers. RevenueCat refetches CustomerInfo. |
| Account deletion | `invalidateAllUserProviders` already covers `isPremiumProvider`; we add the new one to the same helper. |
| iPad layout | Card is full-width and inherits Settings' horizontal padding. No iPad-specific code. |
| Apple guideline 3.1.1 | Card copy uses "Sakina Premium" / "Manage subscription" — no third-party payment terms. App Store deep-link is the canonical Apple-sanctioned management path. |

## Testing

Four test files (expanded from 2 in the original draft per /plan-eng-review
coverage audit; covers 12 identified code/user-flow paths):

1. **`test/features/settings/widgets/settings_premium_card_test.dart`** —
   render assertions per state, pumped with `ProviderScope` overrides on
   `premiumStateProvider`:
   - State 1 (`AsyncValue.data((isPremium: false, billingIssueAt: null))`)
     renders gold card + "Sakina Premium" + "Weekly & Annual" subtitle.
   - State 2 (`AsyncValue.data((isPremium: true, billingIssueAt: null))`)
     renders emerald icon + "Active · Manage subscription" subtitle.
   - State 3 (`AsyncValue.data((isPremium: true, billingIssueAt: <iso>))`)
     renders amber bg + "Payment issue" + warning icon.
   - Loading state (`AsyncValue.loading`) renders skeleton at the same
     height as resolved states (golden-rule: no page jump).
   - Error state (`AsyncValue.error`) falls back to State 1 (graceful
     degradation — App Review fix preserved even on RC outages).

2. **`test/features/settings/widgets/settings_premium_card_tap_test.dart`** —
   tap behavior with `PurchaseService.debugSetOverride` for SDK mocking, a
   fake `GoRouter` observer for navigation, and an analytics provider
   override that captures fired events:
   - State 1 tap → `/paywall` push + `settings_premium_cta_tapped`
     analytics event fires.
   - State 2 tap → `Purchases.showManageSubscriptions` invoked +
     `settings_premium_manage_tapped` fires.
   - State 3 tap → same SDK call + `settings_premium_billing_issue_tapped`
     fires.
   - SDK throws on tap → snackbar appears with "Could not open subscription
     management" copy; no crash.

3. **`test/features/settings/widgets/settings_premium_card_lifecycle_test.dart`** —
   simulates `tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed)`
   and asserts `premiumStateProvider` is invalidated. Use a counter
   provider listener to detect re-execution. Also asserts the observer is
   removed on widget dispose (no leak / no invalidation after unmount).

4. **`test/features/daily/providers/premium_state_provider_test.dart`** —
   unit test for the new combined provider with `PurchaseService.debugSetOverride`:
   - Returns `(isPremium: false, billingIssueAt: null)` when SDK reports
     not premium.
   - Returns `(isPremium: true, billingIssueAt: null)` when premium and no
     billing issue.
   - Returns `(isPremium: true, billingIssueAt: '<iso>')` when premium with
     billing issue.
   - Short-circuits the billing-issue fetch when `isPremium == false`
     (assert `getBillingIssueDetectedAt` not called via mock spy).

Existing `settings_screen` tests must keep passing — we are only adding a
widget. Existing `isPremiumProvider` consumers (~18 sites) are migrated to
`premiumStateProvider`; their existing tests get a mechanical update to the
new provider shape.

## Out of scope

- Home-screen banner (deferred; revisit if Apple bounces again).
- Renewal date / plan name display.
- Restore Purchases duplicate in Settings (Store screen owns it).
- iPad-specific layout.
- Renewal reminder push notifications.
- Win-back offers / churn flows.

## Open questions

None. Brainstorming resolved 1A/2A/3A/4A. /plan-eng-review resolved:

- **Manage Subscription mechanism:** native `Purchases.showManageSubscriptions()`
  (StoreKit sheet) over URL deep-link.
- **Provider shape:** single combined `premiumStateProvider` returning a
  record over two separate providers; ~18 call-site migration accepted.
- **Widget shape:** parameterized `_PremiumCardRow` for states 2/3/loading
  plus distinct `_PremiumCardFree` for state 1.
- **Test coverage:** 4 test files covering 12 identified paths (render,
  taps, lifecycle, provider unit).
- **Home banner:** captured in `TODO.md` with explicit triggers (Apple
  re-rejection OR <2% tap-through on Settings card within 30 days).

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR (PLAN) | 3 issues found, 3 resolved; 0 critical gaps |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**UNRESOLVED:** 0
**VERDICT:** ENG CLEARED — ready to implement. Run `/plan-design-review`
for visual polish on the gold card + amber billing variant, or skip and
proceed to writing-plans → implementation.

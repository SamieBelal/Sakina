# Subscription Cancellation Feedback — Design

**Date:** 2026-05-31
**Status:** Implemented on branch `cancellation-feedback` (2026-05-31), merged up
to date with master. All three paths wired; 29 Flutter tests + 28 Deno webhook
tests pass; `flutter analyze` clean. DB migrations not yet applied to a live
project — apply via the normal migration flow before release.
**Author:** Ibrahim Ahmed (with Claude)

## Goal

When a user cancels their Sakina subscription — a free trial, an active paid
subscription, anything that turns off auto-renew — ask them (optionally) *why*
they are leaving, capture a free-text note plus a structured reason, and land
the data somewhere we can analyze it. Feedback-only: **no win-back offer, no
deterrent flow in this feature** (explicitly out of scope for v1).

## Key constraint (why the design looks the way it does)

The actual "Cancel Subscription" tap happens in Apple/Google system UI, which
the app cannot intercept. Verified against the installed SDKs:

- The app already presents RevenueCat **Customer Center** as its in-app
  "Manage subscription" entry point (`settings_premium_card.dart:105`,
  `RevenueCatUI.presentCustomerCenter()`).
- RevenueCat's Customer Center *does* expose cancellation event listeners
  (`onManagementOptionSelected` → "cancel", `onFeedbackSurveyCompleted`) — **but
  only on the native iOS/Android/Unity SDKs.** The Flutter wrapper
  (`purchases_ui_flutter` 8.11.0) exposes **only** `presentCustomerCenter()`
  with no callbacks (source comment: `// handling result will be implemented in
  upcoming PRs`). Catching the cancel tap in-app would require custom
  Swift+Kotlin platform-channel code, which is high-effort, fragile across SDK
  updates, and still misses users who cancel directly in the OS Settings app.
- RevenueCat does **not** push subscription changes to the device; `customerInfo`
  only refreshes on an outbound call (cache > 5 min). So a cancellation is
  observed on the next app open/resume, not at the instant it happens.

Therefore the trigger is **reactive** (observe the cancellation after the fact),
and we close the "user never reopens the app" gap with a **server-side push**
fired from the existing CANCELLATION webhook.

### Decisions made during brainstorming

| Decision | Choice |
|---|---|
| Survey mechanism | Custom in-app survey writing to a Supabase table we own (not RevenueCat's built-in survey — it is multiple-choice only, no free-text) |
| Trigger | Two paths, **one survey**: (a) **instant** — when the in-app Customer Center sheet closes, refresh status and present our survey immediately if they just cancelled; (b) **reactive** — for cancels done in the OS Settings app, present on next app open + push. Both show the same custom survey and write the same table. |
| Coverage booster | OneSignal push fired from the existing `CANCELLATION` webhook, deep-linking into the survey |
| Results destination | Supabase table = source of truth; mirror each submission to a Mixpanel event for charts |

## Architecture

```
 PATH A — cancel via in-app Customer Center            PATH B — cancel via OS Settings app
        │                                                       │
  await presentCustomerCenter() returns                  CANCELLATION webhook
        │                                                  ├─ upsert user_subscriptions
   invalidate + getCustomerInfo()                         │    (canceled_at, expires_at,
        │  just cancelled?                                │     period_type)  [transition?]
        ▼  YES → INSTANT                                  └─ NEW: OneSignal push (on null→cancel
        │                                                        transition only) → deep-link
        │                                          next app open / resume      push tapped
        │                                                  │                        │
        │                                                  └─ query user_subscriptions
        │                                                     (server = source of truth)
        ▼                                                              ▼
        └────────────► CancellationFeedbackController ◄────────────────┘
                         shared predicate: cancelled? not billing-issue?
                         no feedback row for (user_id, expires_at)? authed?
                         ▼
                 CancellationFeedbackSheet  (reasons + optional free-text)
                         │ Submit / Skip
                         ▼
            CancellationFeedbackService   (dedupe key: user_id + expires_at)
              ├─ INSERT cancellation_feedback  (Supabase — source of truth)
              └─ Mixpanel track('Cancellation Feedback Submitted', {...})
```
Path A reads the client `EntitlementInfo` (fresh, right after Customer Center
closes). Path B reads the server row. Both write the same table, deduped on the
`(user_id, expires_at)` episode key, so a cancellation is surveyed exactly once.

### Components / units

- **`cancellation_feedback` table + RLS** (new Supabase migration) — owns the data.
- **`CancellationFeedbackService`** (`lib/services/`) — single responsibility: write
  a feedback/dismissal record to Supabase and fire the Mixpanel event. Pure I/O;
  no detection logic.
- **`CancellationFeedbackController`** (Riverpod provider, `lib/features/.../providers/`)
  — decides *whether* to prompt. Reads RevenueCat `customerInfo` and the
  authoritative `user_subscriptions.canceled_at`; applies the voluntary-cancel
  and not-yet-surveyed gates. Exposes a `shouldPrompt` signal + the cancellation
  context. Depends on PurchaseService + Supabase, not on the UI.
- **`CancellationFeedbackSheet`** (`lib/features/.../widgets/`, < 200 lines) — the
  modal UI. Stateless w.r.t. detection; receives context, returns the user's
  choice. Trial vs paid copy driven by `period_type`.
- **Webhook push** — extension to `revenuecat-webhook/handler.ts` (+ a small
  idempotency guard) that sends the OneSignal notification.
- **Deep-link route** — new GoRouter route for `sakina://cancellation-feedback`
  that opens the sheet (still dedupe-checked).

Each unit is independently testable: the controller's gating is pure logic over
inputs; the service is I/O you can stub; the sheet is a widget test; the webhook
push is a handler unit test.

## Data model — `cancellation_feedback`

| column | type | notes |
|---|---|---|
| `id` | uuid pk | `gen_random_uuid()` |
| `user_id` | uuid not null | FK `auth.users` |
| `created_at` | timestamptz | default `now()` |
| `expires_at` | timestamptz not null | current entitlement period end — **dedupe key** ("cancellation episode") |
| `canceled_at` | timestamptz null | when the cancel was detected (data, not the key) |
| `reason_code` | text null | null when skipped/dismissed |
| `reason_text` | text null | optional free-text |
| `period_type` | text null | `trial` / `normal` |
| `product_id` | text null | context |
| `store` | text null | `app_store` / `play_store` |
| `platform` | text null | `ios` / `android` |
| `source` | text not null | `in_app_instant` / `in_app_reactive` / `push` |
| `status` | text not null | `submitted` / `dismissed` |

- **Dedupe key is `(user_id, expires_at)`, NOT `canceled_at`** (eng-review
  decision). Reason: the two trigger paths read the cancellation at different
  moments from different sources — the **instant** path reads the client
  `EntitlementInfo` right after Customer Center closes (before the webhook may have
  written the server row), the **reactive** path reads `user_subscriptions`. A
  timestamp-based key would differ between them and double-survey. `expires_at`
  (the entitlement's current period end) is **identical** in the client
  `EntitlementInfo.expirationDate` and the server `user_subscriptions.expires_at`,
  and is stable for the whole "this period won't renew" episode. A
  resubscribe/renewal advances `expires_at` → new episode → surveyable again.
- All writes use `INSERT … ON CONFLICT DO NOTHING` and **MUST name the composite
  conflict columns explicitly** (`onConflict: 'user_id,expires_at'`). The Supabase
  SDK defaults to PK-conflict resolution, which would insert a fresh uuid row, hit
  the composite unique violation, and *silently fail* (prior learning, confidence
  9/10). The test fake MUST model the `(user_id, expires_at)` uniqueness or the
  dedupe tests give false confidence (prior learning, confidence 9/10).
- **Defensive:** if `expires_at` is ever null (non-expiring entitlement — not
  expected for the weekly/annual products, but guard anyway), fall back to skipping
  the prompt rather than writing a null-keyed row.
- **`reason_code` is a Dart enum with stable string values**, one definition
  feeding both this column and the Mixpanel property so the taxonomy can't drift.
- **RLS:** authenticated user may `INSERT` and `SELECT` only rows where
  `user_id = auth.uid()`. No service-role writes from the client. Follows the
  existing per-user table conventions in the codebase.
- This is **not** an economy table — it is written directly via the service
  layer (`supabase.from('cancellation_feedback').insert(...)`), which is allowed;
  the "never write directly" rule applies only to tokens/XP/streaks/economy.

## Detection logic (`CancellationFeedbackController`)

There are **two trigger paths that show the same survey** and dedupe against the
same `(user_id, expires_at)` episode key, so a cancellation is only ever surveyed
once regardless of how it was detected.

The shared predicate, "is this a voluntary, not-yet-surveyed cancellation?", is one
function over `(expires_at, isCancelled, hasBillingIssue)`: prompt iff cancelled,
**not** a billing issue (involuntary churn is never surveyed), and no
`cancellation_feedback` row exists for `(user_id, expires_at)`. Only the *input
source* differs between the two paths.

### Path A — instant (Customer Center)

`settings_premium_card.dart:_openManageSubscription` already `await`s
`RevenueCatUI.presentCustomerCenter()`. When it returns (sheet dismissed):

1. `Purchases.invalidateCustomerInfoCache()` then `getCustomerInfo()` to force a
   fresh read.
2. Inspect the `premium` entitlement (in `entitlements.all`): cancelled iff
   `!willRenew && unsubscribeDetectedAt != null && billingIssueDetectedAt == null`.
3. If cancelled and the shared predicate passes, present our survey **immediately**
   (`source = in_app_instant`). `expires_at` comes from
   `entitlement.expirationDate`; `period_type` from `entitlement.periodType`.

This gives the near-instant moment for users who cancel inside the app, in our own
sheet, with free-text — without RevenueCat's built-in survey and without splitting
data.

### Path B — reactive (Settings-app cancels, or instant path missed)

**Server `user_subscriptions` is the source of truth here** (it can't rely on the
client, which may be stale; prior learning: *"model from lifecycle timestamps."*).
On app launch and `AppLifecycleState.resumed`:

1. Require an authenticated Supabase user; otherwise bail.
2. **Single query** against `user_subscriptions`: a row where `canceled_at IS NOT
   NULL` **and** `billing_issue_detected_at IS NULL`, with **no**
   `cancellation_feedback` row for `(user_id, expires_at)`. (`expires_at` and
   `period_type` come from that row — see the webhook change below.)
3. If yes → surface the sheet **at a calm moment**: from the home screen via a
   post-frame one-shot, gated on `route == home` and no daily overlay / onboarding
   / paywall / gacha active. One present-call, one place. (`source =
   in_app_reactive`, or `push` when arrived via the deep link.)

**Skip** (either path) writes a `dismissed` row keyed on `(user_id, expires_at)` →
never re-asks for that episode. Because both paths share the episode key, a user
who gets the instant survey is never re-asked on next open, and vice-versa.

## Survey UI (`CancellationFeedbackSheet`)

- Modal bottom sheet. Single-select reason chips + optional free-text field +
  **Skip** and **Submit**. Everything is optional — Submit is enabled even with
  no reason and no text (per requirement).
- Copy adapts to `period_type`: trial → "Before your trial ends…"; paid →
  "Sorry to see you go." Warm, on-brand (cream `#FBF7F2` / emerald `#1B6B4A`).
- Arabic + English never mixed in one `Text` widget (project rule). All strings
  i18n-extractable.
- **Reason taxonomy (codes):**
  `too_expensive` (Too expensive) · `not_using` (Not using it enough) ·
  `missing_feature` (Missing something I need) · `found_alternative` (Found a
  better app) · `technical_issues` (Bugs / technical problems) · `just_break`
  (Just taking a break) · `other` (Other).

## Webhook push

Extend `supabase/functions/revenuecat-webhook/handler.ts`. Reuses the established
OneSignal pattern from `notify-referral-confirmed/index.ts` (modern v2:
`include_aliases.external_id`, `data.type`, `Authorization: Key <REST_KEY>`).
The app already calls `OneSignal.login(userId)`, so `external_id` targets our
Supabase user; the tap is routed by
`notification_service.dart:routeForNotificationType()` (add one `case`).

- Also add `period_type` to the `user_subscriptions` upsert (the RC event carries
  it) so detection can render trial vs paid copy from the server row.
- **Push fires only on the `canceled_at` null → set transition** (eng-review
  decision): the upsert reports whether this event is a *new* cancellation, and
  the push is sent only then. Redeliveries/retries see no transition → no push.
  No new storage, idempotency falls out of the state change. A resubscribe resets
  `canceled_at` to null, so a later cancel transitions again and can push again.
- **Isolation (non-negotiable):** the OneSignal call is fully wrapped,
  best-effort, fire-and-forget. A push failure must **never** change the
  webhook's 200/500 for the subscription upsert — otherwise a OneSignal hiccup →
  500 → RevenueCat retries the whole event → re-runs the consumable clawback.
- OneSignal REST key is an **Edge Function secret**, never in `env.json`.
- New GoRouter route handles `sakina://cancellation-feedback`; tapping the push
  opens the same sheet, which still performs the dedupe check before showing.

## Results / analytics

- **Supabase** = source of truth. Free-text and structured reasons queryable via
  the Supabase dashboard / SQL editor.
- **Mixpanel** event per submission: `track('Cancellation Feedback Submitted',
  { reason_code, period_type, has_text, source })` via the existing
  `analytics_service.track(...)` API. Gives reason breakdown, trial-vs-paid, and
  trend charts with no extra infra. (Skips/dismissals can fire a lighter
  `Cancellation Feedback Dismissed` event if useful.)

## Error handling

- All Supabase writes wrapped in try/catch; failure is silent and non-blocking —
  cancellation feedback must never interrupt or error in the user's face.
- Mixpanel mirror is best-effort; failure never blocks the Supabase write.
- Push send failures are logged server-side; the in-app reactive path is the
  backstop, so a failed push does not lose the response.

## Edge cases

| Case | Behavior |
|---|---|
| Cancels via Customer Center | **Instant** survey when the sheet closes (Path A) |
| Cancels in OS Settings app, reopens | Surveyed on next open (Path B, server row) |
| Never reopens the app | Reached via webhook push |
| Reopens only after full expiry | Surveyed via `entitlements.all` / server row |
| Billing failure (involuntary) | **Not** surveyed (billing-issue gate) |
| Cancels then un-cancels | **Not** surveyed (`willRenew` true) |
| Instant path missed (force-quit before sheet) | Caught by Path B on next open |
| Instant survey done, then reopens | **Not** re-asked — same `(user_id, expires_at)` row |
| Multiple devices / push+in-app race | Unique `(user_id, expires_at)` dedupes |
| Anonymous / unauthed | Skipped (cannot attribute) |
| Cancel → resubscribe → cancel again | New `expires_at` → surveyed again |
| Non-expiring entitlement (`expires_at` null) | Skipped (defensive — no null-keyed row) |

## Testing

- **Unit (controller):** voluntary vs billing-issue vs expired vs resubscribed;
  dedupe against existing row; unauthed bail.
- **Widget (sheet):** renders; Skip writes `dismissed`; Submit writes `submitted`
  with/without free-text; trial vs paid copy.
- **Service:** correct Supabase payload + Mixpanel event; conflict is a no-op.
- **Webhook:** push fired only on voluntary subscription `CANCELLATION`;
  idempotent on event id; not fired for billing/expiration/consumable events.

## Out of scope (v1)

- Win-back / retention offers or any attempt to change the user's mind.
- RevenueCat's built-in multiple-choice Customer Center survey (no free-text).
  **Disabled in the RC dashboard** (verified 2026-06-01: Customer Center
  `CANCEL` path `feedback_survey: null`) so it never double-shows alongside our
  in-app sheet. Must stay off — re-enabling it would surface two surveys on a
  single cancellation.
- Native platform-channel Customer Center listeners.
- Localizing into the priority languages beyond keeping strings extractable.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | skipped | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR | 3 arch issues (all resolved), 0 critical gaps |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | n/a | — |

**Eng-review decisions folded into the spec:** (1) server `user_subscriptions` row is
the single source of truth for reactive detection; (2) survey presents from the home
screen, gated, never over another overlay; (3) webhook push fires only on the
`canceled_at` null→set transition, fully isolated from billing sync; (4) instant +
reactive paths share one survey, deduped on the `(user_id, expires_at)` episode key.

**UNRESOLVED:** none.
**VERDICT:** ENG CLEARED — ready to implement (feedback-only v1; win-back deferred to `TODO.md`).

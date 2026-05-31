# Subscription Cancellation Feedback — Design

**Date:** 2026-05-31
**Status:** Approved (design); pending implementation plan
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
| Trigger | Reactive: detect voluntary cancel on next app open/resume; also reachable via push deep-link |
| Coverage booster | OneSignal push fired from the existing `CANCELLATION` webhook, deep-linking into the survey |
| Results destination | Supabase table = source of truth; mirror each submission to a Mixpanel event for charts |

## Architecture

```
RevenueCat cancel (Customer Center OR OS Settings app)
        │
        ├──────────────► CANCELLATION webhook (supabase/functions/revenuecat-webhook)
        │                   ├─ upsert user_subscriptions.canceled_at        (already exists)
        │                   └─ NEW: OneSignal push → deep-link sakina://cancellation-feedback
        │                          (idempotent on RC event id)
        │
   next app open / resume                          push tapped
        │                                               │
        └──────────► CancellationFeedbackController ◄────┘
                         │ voluntary cancel? not yet surveyed? authed?
                         ▼
                 CancellationFeedbackSheet  (reasons + optional free-text)
                         │ Submit / Skip
                         ▼
            CancellationFeedbackService
              ├─ INSERT cancellation_feedback  (Supabase — source of truth)
              └─ Mixpanel track('Cancellation Feedback Submitted', {...})
```

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
| `canceled_at` | timestamptz not null | the cancellation this record belongs to — **dedupe key** |
| `reason_code` | text null | null when skipped/dismissed |
| `reason_text` | text null | optional free-text |
| `period_type` | text null | `trial` / `normal` |
| `product_id` | text null | context |
| `store` | text null | `app_store` / `play_store` |
| `platform` | text null | `ios` / `android` |
| `app_version` | text null | context |
| `expires_at` | timestamptz null | when access ends |
| `source` | text not null | `in_app` / `push` |
| `status` | text not null | `submitted` / `dismissed` |

- **Unique `(user_id, canceled_at)`**; all writes use `INSERT … ON CONFLICT DO
  NOTHING`. One record per cancellation event → handles the push/in-app race and
  multiple devices. A user who cancels, resubscribes, then cancels again gets a
  new `canceled_at` and is surveyed again.
- **RLS:** authenticated user may `INSERT` and `SELECT` only rows where
  `user_id = auth.uid()`. No service-role writes from the client. Follows the
  existing per-user table conventions in the codebase.
- This is **not** an economy table — it is written directly via the service
  layer (`supabase.from('cancellation_feedback').insert(...)`), which is allowed;
  the "never write directly" rule applies only to tokens/XP/streaks/economy.

## Detection logic (`CancellationFeedbackController`)

Runs on app launch and on `AppLifecycleState.resumed`:

1. Require an authenticated Supabase user; otherwise bail (cannot attribute).
2. Refresh / invalidate the RevenueCat `customerInfo` cache so a same-session
   Customer Center cancel is observed.
3. Read the `premium` entitlement (check `entitlements.all`, not only `.active`,
   so a recently-expired-but-cancelled sub is still seen).
4. Treat as a **voluntary cancellation** iff `unsubscribeDetectedAt != null` **and**
   `billingIssueDetectedAt == null`. Billing failures (involuntary churn) are
   never surveyed. Cross-check with the authoritative server
   `user_subscriptions.canceled_at` (instant + reliable, sidesteps the 5-min
   client cache).
5. Skip if `willRenew == true` (un-cancelled / resubscribed).
6. Query `cancellation_feedback` for a row matching `(user_id, canceled_at)`. If
   one exists (submitted *or* dismissed), do not prompt.
7. Otherwise surface the sheet at a calm moment (home screen settle), once.
   **Skip** writes a `dismissed` row → never re-asks for that cancellation.

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

Extend `supabase/functions/revenuecat-webhook/handler.ts`:

- On a **subscription** `CANCELLATION` event (entitlement `premium`; voluntary by
  definition — billing issues arrive as `BILLING_ISSUE`, expirations as
  `EXPIRATION`), call OneSignal to send a gentle notification ("We'd love to know
  why — 10 seconds?") with launch URL `sakina://cancellation-feedback`.
- **Idempotent** on the RevenueCat event id so webhook retries do not double-push
  (reuse the existing idempotency-table pattern, or a
  `cancellation_survey_pushed` guard).
- OneSignal REST key is stored as an **Edge Function secret**, never in `env.json`
  (consistent with the project's secret-handling rule).
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
| Cancels via Customer Center, reopens | Surveyed (happy path) |
| Cancels in OS Settings app, reopens | Surveyed (webhook `canceled_at` + client signals) |
| Never reopens the app | Reached via webhook push |
| Reopens only after full expiry | Surveyed via `entitlements.all` / server `canceled_at` |
| Billing failure (involuntary) | **Not** surveyed |
| Cancels then un-cancels | **Not** surveyed (`willRenew` true) |
| Same-session cancel in Customer Center | Cache invalidated on resume → seen |
| Multiple devices / push+in-app race | Unique `(user_id, canceled_at)` dedupes |
| Anonymous / unauthed | Skipped (cannot attribute) |
| Cancel → resubscribe → cancel again | New `canceled_at` → surveyed again |

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
- Native platform-channel Customer Center listeners.
- Localizing into the priority languages beyond keeping strings extractable.

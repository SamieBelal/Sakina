# RevenueCat Sandbox Verification

Repeatable procedure for verifying subscription purchases and the webhook round-trip in sandbox/test environments. Run before every release that touches RevenueCat, `PurchaseService`, the paywall, or the webhook handler.

## Prerequisites

- RevenueCat dashboard access
- App Store Connect sandbox tester account (iOS) — manage via **Users and Access → Sandbox Testers**
- Google Play Console license tester email added to Setup → License testing (Android)
- Supabase dashboard access to inspect `public.user_subscriptions` and webhook function logs
- `.env` has valid `REVENUECAT_API_KEY_APPLE`, `REVENUECAT_API_KEY_GOOGLE`, `REVENUECAT_WEBHOOK_SECRET`

## iOS

1. **Install a dev build on a physical iPhone.** Simulator does not process StoreKit receipts.
2. **Sign into a sandbox Apple ID** from Settings → App Store → Sandbox Account. Do NOT sign into the main Apple ID account at the device level — that triggers a real charge.
3. **Onboard to the paywall.** Tap the annual CTA. Confirm the StoreKit sheet shows `[Environment: Sandbox]` and price `$0.00`.
4. **Tap Subscribe.** Expect:
   - `PurchaseService.purchase()` returns `true`
   - "Welcome to Premium" reveal overlay appears
   - Onboarding completes and lands on home
5. **Verify server state within 60 seconds.** RevenueCat webhook delivers asynchronously. In Supabase SQL editor:
   ```sql
   select user_id, entitlement, product_id, expires_at, last_event_type, last_event_at
     from public.user_subscriptions
     where user_id = '<your test user uuid>';
   ```
   Expect: one row, `entitlement = 'premium'`, `product_id = 'sakina_sub_annual'`, `last_event_type = 'INITIAL_PURCHASE'`, `expires_at` in the future.
6. **Verify monthly grant gating.** Call `grant_premium_monthly()` RPC — should return `granted: true` on the first call in a calendar month.
7. **Test restore.** Delete and reinstall the app. Go through onboarding, tap **Restore Purchase** on the paywall. Same reveal + landing behavior.

## Android

1. **Build and upload an AAB to the Play Console internal test track.**
   ```bash
   flutter build appbundle --release
   ```
   Upload at Play Console → Testing → Internal testing → Create new release. Add your Google account as a tester in Testers → create a tester list → add email → save.
2. **Join the internal test track** via the opt-in URL shown in the Play Console. Wait ~15 minutes for propagation.
3. **Install from Play Store** on a physical Android device signed into the tester Google account. Repeat steps 3–7 from iOS above.
4. **Play Billing quirks to watch for:**
   - Test purchases sometimes remain in a `PENDING` state briefly. `PurchaseService.purchase()` should still return a final `true/false`.
   - First-time Play Billing initialization can 500ms-stall the paywall button. Acceptable, but regression-worthy if it gets worse.
   - Play Console's "License testing" (different from internal track testers) is the correct setting for free sandbox purchases. Confirm the tester email is in BOTH places.

## Webhook payload capture

To populate this section's example payloads, tail the Supabase edge function logs during step 5:

```bash
supabase functions logs revenuecat-webhook --follow
```

Capture one representative payload per event type (`INITIAL_PURCHASE`, `RENEWAL`, `CANCELLATION`, `EXPIRATION`, `BILLING_ISSUE`, `UNCANCELLATION`) and paste into `docs/qa/revenuecat-webhook-payloads.md` (create on first capture). Future debugging avoids guessing at field shapes.

## Sign-off checklist

- [ ] iOS annual purchase writes row within 60s
- [ ] iOS weekly purchase writes row within 60s
- [ ] iOS restore writes row within 60s
- [ ] iOS purchase cancellation does not complete onboarding
- [ ] Android annual purchase writes row within 60s
- [ ] Android restore writes row within 60s
- [ ] `grant_premium_monthly()` returns `granted: true` post-purchase
- [ ] `grant_premium_monthly()` returns `reason: not_premium` for non-subscribed test user
- [ ] Out-of-order webhook replay (replay an older `EXPIRATION` after a newer `RENEWAL`) is logged as `skipped: stale_event`

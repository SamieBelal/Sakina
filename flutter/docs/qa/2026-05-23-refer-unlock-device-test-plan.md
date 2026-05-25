# Refer-to-Unlock — Physical Device Test Plan

**PR:** [#16](https://github.com/SamieBelal/Sakina/pull/16) — refer-to-unlock + in-onboarding gift + Settings redeem + My Referrals + push on confirm

**Scope:** Everything bundled in the PR (PR-16 foundation + PR-18 hybrid code entry + PR-19 referrer surface + hardened push).

**Time budget:** ~45–60 min for the full sweep. Sections are independent — you can skip ahead if a flow obviously works.

---

## Pre-flight (do once, ~10 min)

### What you need

- **2 physical iPhones** (call them **Phone A** = referrer, **Phone B** = referee). One phone works for everything except the deep-link handoff test and the push delivery test, which want a real cross-device.
- **3 test email addresses** you can sign up with. Sandbox-friendly: `qa-a-<timestamp>@sakina-test.dev`, `qa-b-...`, `qa-c-...`. They never need to receive real email.
- **Ability to apply migrations + run ops commands** (Supabase Studio or psql).
- **Notifications permission granted** on Phone A (referrer must allow push to receive the confirmation push).

### Ops setup (one-time, runs before push works)

This must complete before **Section E** (Push on confirm). The rest of the PR works without it.

```bash
# 1. Generate the shared secret
SECRET=$(openssl rand -hex 16)
echo "$SECRET"  # save it
```

```bash
# 2. Set on the edge side
supabase secrets set NOTIFY_REFERRAL_SECRET=$SECRET
```

```sql
-- 3. Set both GUCs on the DB (Supabase Studio SQL editor)
ALTER DATABASE postgres SET app.notify_referral_url =
  'https://smhvsqrxqoehqncphjrq.supabase.co/functions/v1/notify-referral-confirmed';
ALTER DATABASE postgres SET app.notify_referral_secret = '<paste-your-secret>';
-- Verify:
SHOW app.notify_referral_url;
SHOW app.notify_referral_secret;
```

```bash
# 4. Deploy the edge function (--no-verify-jwt because shared-secret is the gate)
supabase functions deploy notify-referral-confirmed --no-verify-jwt
```

```sql
-- 5. Apply the migration (via mcp__supabase__apply_migration OR Studio)
-- File: supabase/migrations/20260523010000_push_on_referral_confirm.sql
```

```bash
# 6. Restart your DB session (psql disconnect+reconnect) so the new GUCs take effect
```

### Build + install

```bash
cd "/Users/appleuser/CS Work/Repos/sakina/refer-unlock/flutter"
flutter run --release --dart-define-from-file=env.json -d <phone-A-udid>
# In another terminal:
flutter run --release --dart-define-from-file=env.json -d <phone-B-udid>
```

---

## Section A — ReferUnlockScreen + the Start-Trial bug fix (PR-16)

The original PR-16 flow. Also verifies the **PopScope canPop:false → canPop:true** bug fix (Start Trial used to freeze the screen).

### A1. Reach the ReferUnlockScreen via paywall dismiss

| Step | Action | Expected |
|------|--------|----------|
| 1 | On Phone A: uninstall + reinstall the app. Open it. | Welcome screen — "Reflect · Build · Discover". |
| 2 | Tap **Get Started**. Walk onboarding to the paywall (page ~26). | "YOU'RE 1 STEP AWAY, <Name>" + Yearly/Weekly cards. |
| 3 | Tap the **X** in the top-right of the paywall. | "Wait — try weekly first?" exit-offer sheet. |
| 4 | Tap **No thanks**. | **ReferUnlockScreen** loads. Title "Two paths forward", two cards (OPTION 1 Start trial, OPTION 2 Send a dua to 3 friends). |
| 5 | Verify the hadith block renders. | OPTION 2 card contains the Sahih Muslim 2732b quote ("He who supplicates for his brother…") with `— Sahih Muslim 2732b` citation in gold below it. |
| 6 | Verify your code is shown at the bottom. | `Your code: XXXXXXXX` (8 chars, all from `A-HJ-NP-Z2-9` — no I/O/0/1). |

**Pass criteria:** All 6 rows match. ☐

### A2. Start Trial CTA actually pops (regression check — was broken)

| Step | Action | Expected |
|------|--------|----------|
| 1 | On the ReferUnlockScreen, tap **Start free trial** (OPTION 1). | Paywall reappears (the screen pops). **Previously this froze the screen — the bug fix is `PopScope canPop:true`.** |
| 2 | Tap the **X** + **No thanks** again to come back to ReferUnlockScreen. | Back at "Two paths forward". |

**Pass criteria:** Start Trial does NOT freeze. ☐

### A3. Back gesture fires analytics + returns to paywall

| Step | Action | Expected |
|------|--------|----------|
| 1 | Swipe from the left edge (iOS system back) OR tap the back arrow (`<`) in the SubpageHeader. | Paywall reappears. (If you have Mixpanel open: `refer_unlock_back_to_paywall` event fires.) |
| 2 | Verify the back-arrow icon style. | Should be the iOS-style chevron `arrow_back_ios_new_rounded`, NOT the Android round arrow. (This is the SubpageHeader DRY pass artifact.) |

**Pass criteria:** Back works both ways, icon is iOS-style. ☐

### A4. Share intent fires + sharePositionOrigin fix (iPad popover safety)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Come back to ReferUnlockScreen (X → No thanks). Tap **Send to friends (0 / 3 joined)**. | iOS share sheet opens. **No PlatformException crash** ("sharePositionOrigin must be non-zero" was the prior bug). |
| 2 | Verify the share text. | `I made a dua for you. Sakina helped me reflect on Allah's Names — open this to join me: sakina://r/XXXXXXXX` |
| 3 | Pick **Copy** from the share sheet. Paste into Notes to verify. | The string above with your real code. |
| 4 | Dismiss the share sheet. | Back on ReferUnlockScreen. |

**Pass criteria:** Share sheet opens cleanly, text is exact. ☐

---

## Section B — In-onboarding "Did a friend send you a gift?" field (PR-18)

Fresh-install path from Phone B. Tests the disclosure widget, live validation chip, debounce, charset filtering, source attribution.

### B0. Pre-seed a valid foreign code (so you have one to type)

Use Phone A's code from Section A1 step 6 (above). Or run this in Supabase SQL editor for a known test user:

```sql
-- Pick any user OTHER than the one you'll sign up as on Phone B, then:
SELECT public.ensure_referral_code('<some-other-user-id>'::uuid);
-- Note the returned 8-char code. Call it CODE_FOREIGN.
```

### B1. Disclosure renders collapsed on Save Your Progress (page 18)

| Step | Action | Expected |
|------|--------|----------|
| 1 | On Phone B: uninstall + reinstall. Open the app. Tap Get Started. Walk onboarding to page 18 (Save Your Progress). | Header "Save your progress", subtitle "Keep your reflections, streaks, and progress safe across devices." |
| 2 | Look ABOVE the Apple Sign-In button. | A centered collapsed tap target: gift icon + "Did a friend send you a gift?" + chevron-down. Muted gray styling. |
| 3 | Verify the Apple / Google / Email buttons are unaffected. | All three buttons render below, enabled. |

**Pass criteria:** Disclosure exists, is collapsed by default, doesn't block other buttons. ☐

### B2. Tap to expand → field appears + correct description

| Step | Action | Expected |
|------|--------|----------|
| 1 | Tap the disclosure header. | Expands. Shows a description line: "Got a code from a friend? Enter it here for 7 free days of Sakina, our gift to you." |
| 2 | Below the description, verify the input field. | TextField with placeholder "Enter their code", green focus border. |
| 3 | Verify the buttons below are still enabled. | Apple / Google / Email buttons all still enabled — the disclosure DOES NOT gate them. |

**Pass criteria:** Expansion works, copy is exact, buttons remain enabled. ☐

### B3. Live validation — tooShort state (no chip below 8 chars)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Tap the field. Soft keyboard appears. | Cursor in the field. |
| 2 | Type `ABC` (3 chars). Wait 1 second. | No chip below the field. (State = `tooShort`, no RPC fires.) |
| 3 | Continue typing to `ABCD2EF` (7 chars). Wait 1s. | Still no chip. |

**Pass criteria:** No chip appears below 8 chars. ☐

### B4. Live validation — invalid code (8+ chars, soft-fail chip)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Type one more char to reach `ABCD2EFG` (8 chars). Wait 1s. | Chip appears below: muted `?` (help icon) + "We didn't find that code" in tertiary gray. **NOT red, NOT an error icon.** |
| 2 | Verify the buttons are still enabled. | Apple / Google / Email still tappable. |

**Pass criteria:** Soft-fail chip renders in muted styling, no red error. ☐

### B5. Live validation — valid code (green chip)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Clear the field (long-press → Select All → delete, OR tap the clear button). | Chip vanishes (state goes back to `empty`). |
| 2 | Type `CODE_FOREIGN` (the 8-char code you grabbed in B0). Wait 1s. | Chip flips to GREEN: `✓ Valid gift code` in primary green. |

**Pass criteria:** Green chip renders with check icon. ☐

### B6. Charset filter (I/O/0/1 stripped)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Clear the field. Type `NOTACODE`. | Field displays `NTACDE` (both O's stripped — `NOTACODE` → `N-T-A-C-D-E` = 6 chars). |
| 2 | Try typing `0` and `1` and `I` from the keyboard. | None of them appear in the field. |
| 3 | Try typing lowercase `abcd`. | Field shows `ABCD` (auto-uppercased). |

**Pass criteria:** Confusables filtered, lowercase auto-uppercased. ☐

### B7. Code persists to prefs — signup carries it forward

| Step | Action | Expected |
|------|--------|----------|
| 1 | Clear the field again. Type the valid `CODE_FOREIGN`. Wait for green chip. | Green chip. |
| 2 | Tap **Continue with Email** (or Sign in with Apple / Google if those are wired). Walk to email + password screens. Use email `qa-b-<timestamp>@sakina-test.dev` and any 6+ char password. | Account creation completes. Continues through encouragement → paywall flow. |
| 3 | After signup, verify in Supabase: `SELECT referee_id, status, referrer_id FROM referrals WHERE referee_id = '<the-new-user-id>';` | One row exists. status = `pending`. referrer_id is the user who owns CODE_FOREIGN. |
| 4 | Also verify: `SELECT referral_premium_until FROM user_profiles WHERE id = '<the-new-user-id>';` | Set to roughly `now() + 7 days`. |

**Pass criteria:** Referral row + 7d premium grant exist for the new user. ☐

### B8. Source attribution analytics

If Mixpanel is wired to a debug pipe:

| Step | Action | Expected |
|------|--------|----------|
| 1 | Check the most recent `referee_signed_up_with_referral` event. | `source: "onboarding_field"`. NOT `deep_link`, NOT `settings_redeem`. |
| 2 | Check for `referee_granted_7d_window`. | Same `source: "onboarding_field"`. |

**Pass criteria:** Analytics carry the right source. ☐

---

## Section C — Settings → Redeem a referral code (PR-18)

Post-onboarding receiver path. Tests the bottom sheet, all 7 result branches, the **A1 silent-clobber bug fix** (`already_referred_other_code`), and the C2 double-tap fix.

For these tests you need a **fresh user** (call them **User Q**) who has NOT yet redeemed any code, plus two different valid foreign codes (`CODE_FOREIGN_1` and `CODE_FOREIGN_2`).

### C1. Settings row renders in the correct position

| Step | Action | Expected |
|------|--------|----------|
| 1 | Sign User Q in (or sign up fresh). Reach the home screen. | Home loads. |
| 2 | Tap the gear icon (top-right) to open Settings. Scroll to the section just above Account. | Two rows in the same card: **"Refer a friend"** (`Icons.send_rounded`) ON TOP, **"Redeem a referral code"** (`Icons.card_giftcard_rounded`) BELOW it. |

**Pass criteria:** Both rows render, Refer-a-friend above Redeem. ☐

### C2. Sheet opens with focus on input + keyboard up

| Step | Action | Expected |
|------|--------|----------|
| 1 | Tap **Redeem a referral code**. | Bottom sheet rises from the bottom. Header "Redeem your friend's gift". Field with "Enter their code" placeholder. Redeem button at the bottom (disabled until you type ≥8 chars). |
| 2 | Verify the soft keyboard pushes the sheet up cleanly. | No clipping, no overflow. |

**Pass criteria:** Sheet + keyboard interaction is clean. ☐

### C3. Invalid code branch

| Step | Action | Expected |
|------|--------|----------|
| 1 | Type `WRNG2CD8` (random 8-char string that doesn't match any user). Wait for validation. | Field shows muted soft-fail chip "We didn't find that code" (same as B4). Redeem button enabled (validation is advisory, not gating). |
| 2 | Tap **Redeem**. | Result panel replaces the sheet body: "We couldn't find that code. Double-check it and try again." Field stays populated. Try-again button visible. |
| 3 | Tap **Try again**. | Returns to entry state. Field still has `WRNG2CD8`. |

**Pass criteria:** Invalid result renders + Try-again returns to entry. ☐

### C4. Self-referral branch

| Step | Action | Expected |
|------|--------|----------|
| 1 | Find User Q's OWN referral code. `SELECT referral_code FROM user_profiles WHERE id = '<user-q-id>';` | Note it. |
| 2 | Clear the field. Type User Q's own code. Validate chip → green (validate RPC has the self-check but auth.uid is set here so it returns false → muted chip). Tap **Redeem**. | Result: "You can't redeem your own code." |
| 3 | Tap **Close** / dismiss the sheet. | Sheet closes. |

**Pass criteria:** Self-referral copy renders. ☐

### C5. Happy-path redemption

| Step | Action | Expected |
|------|--------|----------|
| 1 | Re-open the Redeem sheet (Settings → Redeem a referral code). | Sheet opens fresh, field empty. |
| 2 | Type `CODE_FOREIGN_1`. Green ✓ chip. Tap **Redeem**. | Result panel: green check + **"جزاك الله خيرًا — your friend just gave you 7 days of Sakina."** (Arabic renders RTL.) |
| 3 | Wait 2.5 seconds. | Sheet auto-dismisses. |
| 4 | Verify in Supabase: `SELECT referrer_id, status FROM referrals WHERE referee_id = '<user-q-id>';` | One row, status=`pending` (will flip to `confirmed` after onboarding_completed). |
| 5 | Verify `SELECT referral_premium_until FROM user_profiles WHERE id = '<user-q-id>';` | ~`now() + 7 days`. |

**Pass criteria:** Blessing renders + auto-dismiss + DB row + grant. ☐

### C6. Idempotent same-code re-redeem

| Step | Action | Expected |
|------|--------|----------|
| 1 | Re-open the Redeem sheet. Type `CODE_FOREIGN_1` AGAIN (the same one User Q just used). Tap **Redeem**. | Result panel: muted info icon + **"You've already used this code."** Auto-dismisses after 2.5s. |

**Pass criteria:** Friendly idempotent message + auto-dismiss. ☐

### C7. THE A1 BUG FIX: different-code lockout

This is the regression-prone branch — previously, the SQL silently dropped the second code and the UI rendered "Your code was applied" (incorrect).

| Step | Action | Expected |
|------|--------|----------|
| 1 | Re-open the Redeem sheet. This time type `CODE_FOREIGN_2` (a DIFFERENT valid code from another user). Tap **Redeem**. | Result panel: **"You've already redeemed a code on this account — only one per account."** **Does NOT auto-dismiss** (you must tap Close yourself — copy is too important to flash past). |
| 2 | Tap **Close**. | Sheet dismisses. |
| 3 | Verify in Supabase no spurious row: `SELECT count(*) FROM referrals WHERE referee_id = '<user-q-id>';` | 1 (the original referral, not 2). |

**Pass criteria:** Lockout copy renders, sheet stays mounted, no extra DB row. ☐

### C8. C2 fix: double-tap doesn't fire RPC twice

| Step | Action | Expected |
|------|--------|----------|
| 1 | Re-open the Redeem sheet on a fresh user (or use Phone B's test user that hasn't redeemed). Type a valid code. **Tap Redeem twice rapidly (within ~200ms).** | One RPC call (button visibly disables on first tap; second tap is absorbed). Result panel shows the SUCCESS state once, not twice. |

**Pass criteria:** Only one RPC fires; no flicker, no double-grant. ☐

### C9. Network error branch (offline)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Enable Airplane Mode. Open Redeem sheet on a fresh user. Type a valid code. Tap Redeem. | Validation chip flips to neutral "Couldn't check right now…" (no RPC, can't reach Supabase). Tap Redeem anyway. Result: "We couldn't apply that code. Check your connection and try again." Field stays populated. |
| 2 | Disable Airplane Mode. Tap **Try again**. | Returns to entry. Type valid code again. Validation succeeds (green chip). Tap Redeem. Success state. |

**Pass criteria:** Offline path is graceful + recovery works. ☐

---

## Section D — Settings → Refer a friend → /my-referrals (PR-19)

The referrer-side surface. Tests the new screen, tap-to-copy, share factor, X/3 progress dots.

For these tests, you need User Q to have a referral code already (auto-created on signup). Optionally, you want some confirmations queued up so the progress dots have something to show.

### D1. Reach the screen

| Step | Action | Expected |
|------|--------|----------|
| 1 | On Phone A with User Q signed in: Settings → tap **Refer a friend** (the new row above Redeem). | New screen pushes from the right. Header `< Refer a friend` (iOS-style back chevron). Subtitle "Send a dua to 3 friends to unlock 30 days + a Gold card." |

**Pass criteria:** Screen pushes cleanly. ☐

### D2. Code card renders + tap-to-copy

| Step | Action | Expected |
|------|--------|----------|
| 1 | Look at the top card. | "Your code" label, then the code displayed huge + letter-spaced (monospace-feel), then "Tap to copy" hint below in muted gray. |
| 2 | Tap the code. | Subtle haptic. Snackbar appears: "Code copied". |
| 3 | Switch to Notes app, paste. | Your code (8 chars). |
| 4 | If Mixpanel is open: check for `my_referrals_code_copied` event. | Event fires. |

**Pass criteria:** Tap-to-copy works + snackbar + haptic + analytics. ☐

### D3. Share button

| Step | Action | Expected |
|------|--------|----------|
| 1 | Below the code card: a primary green Share button with `Icons.ios_share`. Tap it. | iOS share sheet opens. Text: `I made a dua for you. Sakina helped me reflect on Allah's Names — open this to join me: sakina://r/XXXXXXXX`. **NO PlatformException — sharePositionOrigin fix is shared via `shareMyCode` helper.** |
| 2 | Dismiss the share sheet. | Back on My Referrals. |
| 3 | If Mixpanel is open: `my_referrals_share_tapped` event. | Event fires. |

**Pass criteria:** Share opens, no crash, text exact, analytics fire. ☐

### D4. Progress dots (X / 3)

State for User Q at this point: 0 confirmed referrals (the receivers from Section B + C haven't confirmed yet — they're still `pending`).

| Step | Action | Expected |
|------|--------|----------|
| 1 | Scroll to the Progress section. | "X friends joined" headline + 3 dots below. All 3 dots are unfilled (gray). |
| 2 | Manually mark one referral confirmed for User Q: `UPDATE referrals SET status = 'confirmed', confirmed_at = now() WHERE referrer_id = '<user-q-id>' AND status = 'pending' LIMIT 1;` (DB-side, simulates the receiver finishing onboarding) | After re-entering the screen (pop + push) or pull-to-refresh: 1 dot filled green, 2 unfilled. Headline "1 friend joined". |
| 3 | Mark a 2nd row confirmed. Re-enter the screen. | 2 dots filled. |
| 4 | Mark a 3rd row confirmed. Re-enter. | 3 dots filled → grant fires server-side. A `referral_grants` row should appear. After re-enter: 0/3 dots (reset). The grants list below should show one entry: "Today — Gold card + 30 days". |

**Pass criteria:** Progress dots track X/3, reset on grant, grants list updates. ☐

### D5. Empty state

| Step | Action | Expected |
|------|--------|----------|
| 1 | If User Q has 0 confirmed referrals and 0 grants, the footer at the bottom of the screen should render. | "Once friends join with your code, you'll see them here." (or similar empty-state copy). |

**Pass criteria:** Empty state renders when zero data. ☐

### D6. Error state + retry

| Step | Action | Expected |
|------|--------|----------|
| 1 | Enable Airplane Mode. Pop the screen and re-enter (via Settings → Refer a friend). | The load fails. Screen shows an error state with a Retry button. |
| 2 | Disable Airplane Mode. Tap Retry. | Normal render. |

**Pass criteria:** Errors don't crash; retry works. ☐

---

## Section E — Push on referral confirmation (PR-19)

**Requires:** Pre-flight ops checklist (Section 0) completed AND Phone A has notifications allowed.

### E1. Receive a push when a referee confirms

| Step | Action | Expected |
|------|--------|----------|
| 1 | On Phone A: ensure User Q is signed in and notifications are enabled (Settings → Sakina → Notifications → Allow). Lock the screen or background the app. | Phone A idle. |
| 2 | On Phone B (different user): walk through onboarding for a new email signup using `CODE_FOREIGN` = User Q's code. Finish onboarding (reach Home — the apply_referral fires on signup, then `confirm_referral_if_pending` fires on `onboardingComplete`). | Within ~10 seconds: Phone A receives a push notification: heading **"A friend joined"**, body **"<NameOfPhoneBUser> just joined Sakina with your code 🌙"**. |
| 3 | Tap the push notification. | Opens the app on Phone A (no deep-link routing in v1 — just opens the app). |
| 4 | Verify the OneSignal dashboard: Delivery → Recent. | The notification shows up, recipients = 1. |

**Pass criteria:** Push arrives on Phone A within 10s. ☐

### E2. Display-name sanitization (S2 fix — phishing prevention)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Create a malicious-display-name account. SQL: `UPDATE user_profiles SET display_name = 'Free 1yr → bit.ly/xyz' WHERE id = '<phone-b-user-id>';` | DB updated. |
| 2 | Trigger a fresh confirmation (e.g. another new referee using Phone B's user as the referrer — set up a new chain, OR just `UPDATE referrals SET status='pending' WHERE referee_id='<phone-b-user-id>'; UPDATE referrals SET status='confirmed' WHERE referee_id='<phone-b-user-id>';` to refire the trigger). | Push arrives on Phone A. |
| 3 | Read the push body. | Should say **"A friend just joined Sakina with your code 🌙"** — the malicious string is REJECTED by the sanitizer (contains `://`) and falls back to "A friend". |

**Pass criteria:** Malicious display_name is filtered, not delivered. ☐

### E3. Tightened WHEN clause (S4 fix — no resurrection push)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Take a `confirmed` referral row. SQL: `UPDATE referrals SET status='rejected' WHERE referee_id='<some-referee>';` | Row now rejected. (Trigger no-op — confirmed→rejected isn't in the WHEN clause.) |
| 2 | Flip it back: `UPDATE referrals SET status='confirmed' WHERE referee_id='<some-referee>';` | **No push fires.** Phone A receives nothing. (Because `OLD.status = 'pending'` is now required, and OLD here is `'rejected'`.) |

**Pass criteria:** Resurrection does NOT fire a push. ☐

### E4. Shared-secret gate works (S1 fix — abuse rejection)

| Step | Action | Expected |
|------|--------|----------|
| 1 | From your laptop, try calling the function directly WITHOUT the secret: `curl -X POST 'https://smhvsqrxqoehqncphjrq.supabase.co/functions/v1/notify-referral-confirmed' -H 'Content-Type: application/json' -d '{"referrer_id":"00000000-0000-0000-0000-000000000001","referee_id":"00000000-0000-0000-0000-000000000002"}'` | Response: HTTP **401**, body `{"error":"Unauthorized"}`. **No push delivered.** |
| 2 | Try with WRONG secret: add `-H 'X-Notify-Secret: wrong-value'`. | Same: HTTP 401. |
| 3 | Try with the CORRECT secret: `-H 'X-Notify-Secret: <your-actual-secret>'`. | HTTP 200 (push fires if the UUIDs exist as users). |

**Pass criteria:** 401 without secret, 200 with correct secret. ☐

### E5. Fail-soft when GUC unset

| Step | Action | Expected |
|------|--------|----------|
| 1 | (Optional, only if you're comfortable bouncing the GUC) Wipe the secret in DB: `ALTER DATABASE postgres RESET app.notify_referral_secret; -- reconnect session` | GUC gone. |
| 2 | Trigger a confirmation. | **No push fires** (trigger no-ops). Supabase logs show `WARNING: notify_referrer_on_confirm: app.notify_referral_url and/or app.notify_referral_secret unset; skipping push`. |
| 3 | Restore: `ALTER DATABASE postgres SET app.notify_referral_secret = '<secret>';` reconnect. | Back to normal. |

**Pass criteria:** Unset GUC = no push, no crash, warning logged. ☐

---

## Section F — Deep link path (PR-16 original)

Requires 2 phones. Tests the original `sakina://r/<code>` capture.

### F1. Deep link captured on cold launch

| Step | Action | Expected |
|------|--------|----------|
| 1 | On Phone B (a fresh phone with no Sakina installed): install the app via TestFlight or direct build. **Do NOT open it yet.** | App icon on home screen. |
| 2 | On Phone B, open iMessage to yourself (or Notes). Paste the URL `sakina://r/<CODE_FOREIGN>` (use Phone A's actual code). Tap the link. | iOS prompts "Open in Sakina?" → tap Open. App launches to onboarding. |
| 3 | Walk onboarding to Page 18 (Save Your Progress). | Disclosure should be **auto-expanded AND locked** — code from the deep link is pre-filled, "Change code" link visible. |
| 4 | Verify: complete signup. After onboarding: `SELECT referrer_id FROM referrals WHERE referee_id = '<phone-b-user>';` | Referrer matches the deep-link code's owner. Analytics: `refereeSignedUpWithReferral` with `source: 'deep_link'`. |

**Pass criteria:** Deep link captured → pre-fill locked → applied on signup with deep_link source. ☐

### F2. "Change code" unlocks pre-fill (A3 fix — prevents clobber)

| Step | Action | Expected |
|------|--------|----------|
| 1 | On the pre-filled-and-locked disclosure (from F1 step 3), try to tap the field directly. | Field is read-only — no keyboard appears. |
| 2 | Tap the **Change code** text link. | Field becomes editable. The pre-fill is cleared. |
| 3 | Type a different code (or leave blank). Verify in Settings (after signup if not blank): only one referral exists with the NEW code, NOT the original deep-link one. | A3 fix: pre-fill is preserved unless user explicitly taps Change code. |

**Pass criteria:** Pre-fill lock prevents accidental clobber. ☐

---

## Section G — Edge cases + regression spot-checks

### G1. Chain-referral guard

| Step | Action | Expected |
|------|--------|----------|
| 1 | Pick a user who has ALREADY referred someone (i.e., has a row in `referrals` as `referrer_id`). Try to redeem someone else's code from Settings → Redeem on their account. | Result: **"This account isn't eligible."** (chain_referral) — no DB row created. |

### G2. Email validation in onboarding

| Step | Action | Expected |
|------|--------|----------|
| 1 | On the email signup screen, type an obvious typo like `qa@@sakina.dev` (double @). | Continue button disabled until valid. Error message clear. |

### G3. Sign-out drains both prefs keys

| Step | Action | Expected |
|------|--------|----------|
| 1 | After Section B7 (you typed a code into onboarding field but signed up as User B): open Phone B's Settings → Account → Sign Out. | Confirm dialog → Sign out. |
| 2 | In Supabase or via debug tools, check that both SharedPreferences keys are cleared: `pending_referral` AND `pending_referral_source`. | Both gone. (Otherwise the next signup would inherit B's source attribution.) |

### G4. CLAUDE.md docs match reality

| Step | Action | Expected |
|------|--------|----------|
| 1 | Open `CLAUDE.md` (project root). Read the "Refer-to-Unlock" + "Three referral code ingress paths" + "Referrer-side progress surface" + "Push on referral confirmation" paragraphs. | All describe behavior you just verified. |

---

## Final ship checklist

- ☐ Section A (ReferUnlockScreen + Start Trial fix)
- ☐ Section B (in-onboarding disclosure)
- ☐ Section C (Settings Redeem + A1 lockout fix)
- ☐ Section D (My Referrals screen)
- ☐ Section E (push on confirm + 4 security gates)
- ☐ Section F (deep link + A3 pre-fill lock)
- ☐ Section G (edge cases)
- ☐ OneSignal dashboard Delivery tab shows your test pushes
- ☐ Mixpanel (if wired): all 5 source-attribution events fire with correct `source` property
- ☐ Supabase logs: no unexpected ERROR rows from this PR's surfaces

If all green: ✅ **safe to merge**.

If anything fails: file an issue with section number + step + actual-vs-expected, then ping back here — I'll triage.

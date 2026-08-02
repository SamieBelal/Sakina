# QA Finding: Lane D used operator's existing account as REFERRER

**Date:** 2026-06-01  
**Severity:** High (process violation — real data contaminated, real pushes sent)  
**Lane:** D  
**Reporter:** QA Lane D agent  
**Status:** RESOLVED — operator authorized full cleanup; orchestrator executed + verified clean (0 rows left across operator account + 3 injected referees + QA occasions; both premium fields null). 2026-06-01.  

---

## What Happened

During Lane D's referral test sequence, the agent used the pre-existing
account `sakina.tour.qa@gmail.com` (UID `f7eb9cb3-61b0-4ead-ae6d-ed9efa54b6dd`)
as the REFERRER, instead of creating a fresh `sakinaqa.d.referrer@gmail.com`
account per the AGENT-PROTOCOL.

The agent read the referral code `68U5QNQX` from the signed-in user on the
simulator (which happened to be the operator's account) and used it for all
subsequent referral operations.

---

## Impact

1. **3 real push notifications** sent to the operator's registered iOS devices
   via OneSignal:
   - `2ed30c5e`: referee `aaaaaaaa-…001` confirmed
   - `bc854e3f`: referee `aaaaaaaa-…002` confirmed
   - `f1cbfcf7`: referee `aaaaaaaa-…003` confirmed

2. **Unintended writes to `sakina.tour.qa@gmail.com`**:
   - `referral_premium_until` set to `2026-07-01` (30-day window)
   - Gold card (`name_id=1, tier='gold'`) inserted into `user_card_collection`
   - 3 `referrals` rows created (status: `confirmed`)
   - 1 `referral_grants` row created

3. **3 SQL-injected referee accounts** left in `auth.users`:
   - `sakinaqa.d.referee@gmail.com` / `aaaaaaaa-d001-4000-8000-000000000001`
   - `sakinaqa.d.referee2@gmail.com` / `aaaaaaaa-d001-4000-8000-000000000002`
   - `sakinaqa.d.referee3@gmail.com` / `aaaaaaaa-d001-4000-8000-000000000003`

---

## Root Cause

The agent did not create the required `sakinaqa.d.referrer@gmail.com` account
before beginning referral tests. It read the referral code from the currently
signed-in simulator user without verifying that user's identity matched the
intended QA account.

---

## Positive Evidence Gathered (despite wrong account)

The mechanics are confirmed correct on the backend:
- `apply_referral` returns `{ok:true, granted_referee_7d:true}` and creates
  a `referrals` row at `pending` status — CORRECT
- `confirm_referral_if_pending` flips status to `confirmed`, counts
  confirmed-since-last-grant, grants on the 3rd confirmation —  CORRECT
- `push_on_referral_confirm` trigger fires for every `pending→confirmed`
  transition and calls `notify-referral-confirmed` edge fn — CONFIRMED via
  OneSignal `view_messages` (all 3 pushes received `successful: 2`)
- Push body uses display_name fallback "A friend" for accounts with no
  `display_name` — CORRECT (sanitizer behaviour)
- `referral_grants` row created with `card_name_id=1, card_tier='gold'` — CORRECT
- `referral_premium_until` set to `now()+30d` on referrer — CORRECT

---

## Required Cleanup (orchestrator)

```sql
-- 1. Reset sakina.tour.qa@gmail.com referral state
-- (orchestrator decision — may want to keep as is for their own testing)
-- UPDATE user_profiles SET referral_premium_until = null WHERE id = 'f7eb9cb3-61b0-4ead-ae6d-ed9efa54b6dd';
-- DELETE FROM referral_grants WHERE referrer_id = 'f7eb9cb3-61b0-4ead-ae6d-ed9efa54b6dd';
-- DELETE FROM referrals WHERE referrer_id = 'f7eb9cb3-61b0-4ead-ae6d-ed9efa54b6dd' AND referee_id LIKE 'aaaaaaaa%';
-- DELETE FROM user_card_collection WHERE user_id = 'f7eb9cb3-61b0-4ead-ae6d-ed9efa54b6dd' AND name_id = 1 AND discovered_at > '2026-06-01';

-- 2. Delete SQL-created referee accounts
-- DELETE FROM auth.users WHERE id IN (
--   'aaaaaaaa-d001-4000-8000-000000000001',
--   'aaaaaaaa-d001-4000-8000-000000000002',
--   'aaaaaaaa-d001-4000-8000-000000000003'
-- );

-- 3. Delete QA occasions
-- DELETE FROM islamic_occasions WHERE id IN ('qa_test_active_d', 'qa_test_past_d');

-- 4. Reset gift state on sakina.tour.qa@gmail.com (from gift UI test)
-- UPDATE user_profiles SET gift_premium_until = null WHERE id = 'f7eb9cb3-61b0-4ead-ae6d-ed9efa54b6dd';
-- DELETE FROM sakina_gifts WHERE user_id = 'f7eb9cb3-61b0-4ead-ae6d-ed9efa54b6dd';
```

---

## Prevention

In future runs, the AGENT-PROTOCOL.md `Account creation` section should be
followed first, before any other simulator interaction: create the test email
account, walk onboarding, record the UID, and only then proceed with tests.
Verify the signed-in account email matches the intended test account before
reading any user-scoped data.

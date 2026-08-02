# Ramadan Gift Manual QA Plan — PR #17

> **Status:** plan only, not executed. Created 2026-05-25.
> **PR:** https://github.com/SamieBelal/Sakina/pull/17 (`feat/2026-05-14-ramadan-gift`, commit `180f946`)
> **Worktree:** `/Users/appleuser/CS Work/Repos/sakina/ramadan-gift`
> **Tools:** iOS Simulator MCP, Supabase MCP, direct Bash, temporary code modifications, direct SQL.

---

## Why this plan exists

PR #17 already has strong automated coverage:

| Layer | Coverage |
|-------|----------|
| pgtap | 14 assertions (`supabase/tests/ramadan_gifts_test.sql`) — happy path, idempotency, race-safe atomic claim, outside-window, unknown occasion, unauthorized, `greatest()` coalesce, RLS |
| Dart unit | 14 GiftService tests + 5 PurchaseService gift tests (`gift_service_test.dart`, `purchase_service_gift_test.dart`) |
| Widget | 5 RamadanGiftCard tests including SizedBox.shrink loading-state pin, post-claim transition, outside-window inactive |
| CI | flutter-tests + sql-tests green on `180f946` |

Manual QA fills the gaps automated tests structurally **can't** cover:

1. **Real end-to-end claim** against the live `claim_sakina_gift` RPC on the deployed Supabase project, not a mocked Postgrest stub.
2. **Rendering** on a real device — fonts (Aref Ruqaa metric fix), animation timing, Arabic RTL behavior, color contrast.
3. **Entitlement integration** — does `isPremium()` actually unlock the premium-gated features (AI bypass paths, store, etc.) after a successful claim?
4. **Cross-device** — does `refreshGiftPremiumCache()` restore entitlement on a second device sign-in?
5. **The new TOCTOU fix** — does a real double-tap on the Accept button resolve cleanly with no snackbar?
6. **Kill switch** — does flipping `RAMADAN_GIFT_ENABLED=false` in env.json truly elide the surface?

If these pass, the PR ships with confidence. If they don't, the gap surfaces before a real user touches it.

---

## Safety rails — DO NOT pollute prod

The Supabase project URL in `env.json` is **production** (`smhvsqrxqoehqncphjrq.supabase.co`). All testing happens on this project — there is no separate QA branch in the current setup. This means:

- **Use a dedicated test user** — create an email like `qa-ramadan-2026-05-25@sakina-test.local` (or sign in with darkmatter8789+qa@gmail.com). Never run claim tests against the developer's primary user — the `sakina_gifts.(user_id, occasion_id)` PK is single-claim-per-occasion-per-year, so a botched claim attempt with the wrong clock would burn the real Ramadan 2027 claim.
- **Insert test occasions with synthetic ids** (`qa_test_<timestamp>`) — never edit the real seed rows (`ramadan_2027`, `eid_fitr_2027`, `eid_adha_2027`).
- **Clean up after every section.** Cleanup queries live at the end of each section below.
- **Don't permanently change `gift_premium_until` on a real user.** The follow-up PR closes the freemium guard gap; until then we can write to this column via the RPC, but we must not leave a far-future value behind.

---

## Section 1 — Backend correctness (Supabase MCP, no simulator needed)

These tests run via `mcp__supabase__execute_sql` against the live Postgres. The pgtap suite already covers most of this; this section is the **live re-verification** that the deployed RPC behaves identically to the in-test transaction.

### B0 — Test setup (run once at section start)

Create the QA user with a known password so the tester can sign in via the app's normal email/password flow during Section 2. We use Supabase's `auth.users` schema directly because the email-confirmation step would otherwise block signup.

```sql
-- Bcrypt hash for password "QaRamadan!2026" (replace with your own — generate via
-- `htpasswd -bnBC 10 "" "yourpw" | tr -d ':\n'`). DO NOT reuse any real password.
do $$
declare
  v_uid uuid := '00000000-0000-0000-0000-00000000aa01'::uuid;
  v_pwhash text := '$2y$10$xQ4ZqQjNqJlJqJqJqJqJqOZ8zKjQzKjQzKjQzKjQzKjQzKjQzKjQ.';  -- placeholder, generate fresh
begin
  if not exists (select 1 from auth.users where id = v_uid) then
    insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
                            email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
                            created_at, updated_at)
    values ('00000000-0000-0000-0000-000000000000'::uuid, v_uid, 'authenticated',
            'authenticated', 'qa-ramadan-2026-05-25@sakina-test.local', v_pwhash,
            now(),
            '{"provider":"email","providers":["email"]}'::jsonb,
            '{}'::jsonb, now(), now());
    -- Required for the app's onboarding-complete path to recognize the user.
    insert into public.user_profiles (id, created_at, updated_at)
    values (v_uid, now(), now())
    on conflict (id) do nothing;
  end if;
end $$;

-- Active QA occasion brackets *real* now() so the UI tests in Section 2 see a
-- live window without the client clock seam disagreeing with the server's
-- expires_at stamp. The seeded 2027 occasions stay untouched.
insert into public.islamic_occasions(id, display_name, starts_at, ends_at)
values ('qa_test_active', 'QA Active Occasion',
        now() - interval '1 day', now() + interval '6 days')
on conflict (id) do nothing;

-- Past QA occasion for outside_window check
insert into public.islamic_occasions(id, display_name, starts_at, ends_at)
values ('qa_test_past', 'QA Past Occasion',
        now() - interval '30 days', now() - interval '20 days')
on conflict (id) do nothing;
```

### B1 — Live happy-path claim
**Verifies:** `claim_sakina_gift` returns `granted=true`, writes `sakina_gifts` and `user_profiles.gift_premium_until`.

```sql
-- Impersonate the QA user
set local request.jwt.claim.sub = '00000000-0000-0000-0000-00000000aa01';

select public.claim_sakina_gift(
  '00000000-0000-0000-0000-00000000aa01'::uuid,
  'qa_test_active'
);
-- Expected: {"granted":true,"granted_at":"...","expires_at":"... +7d","reused":false}

select expires_at - granted_at as span,
       expires_at > now() + interval '6 days 23 hours' as is_seven_d
  from public.sakina_gifts
 where user_id = '00000000-0000-0000-0000-00000000aa01'::uuid
   and occasion_id = 'qa_test_active';
-- Expected: span ≈ 7 days, is_seven_d = true

select gift_premium_until
  from public.user_profiles
 where id = '00000000-0000-0000-0000-00000000aa01'::uuid;
-- Expected: same timestamp as sakina_gifts.expires_at
```

### B2 — Idempotent re-claim (already-claimed within window)
**Verifies:** Atomic INSERT … ON CONFLICT DO NOTHING returns `reused=true` with unchanged timestamps.

```sql
set local request.jwt.claim.sub = '00000000-0000-0000-0000-00000000aa01';
select public.claim_sakina_gift(
  '00000000-0000-0000-0000-00000000aa01'::uuid,
  'qa_test_active'
);
-- Expected: reused=true, granted_at + expires_at == B1's values

select count(*) from public.sakina_gifts
 where user_id = '00000000-0000-0000-0000-00000000aa01'::uuid
   and occasion_id = 'qa_test_active';
-- Expected: 1
```

### B3 — Race-safe concurrent claim (TOCTOU fix)
**Verifies:** the new `20260525110000_claim_sakina_gift_race_fix.sql` is live and concurrent calls resolve cleanly. With the OLD code, one would raise `unique_violation`. With the new code, both return `granted=true` (one `reused=false`, one `reused=true`).

The MCP `execute_sql` tool serializes calls within a session, so we run this via Bash + psql with two background subshells racing the RPC. Get the project credentials from `env.json` (the Supabase service role is needed because we're impersonating JWTs).

```bash
# Drop existing claim first so the race window is open
psql "$SUPABASE_DB_URL" -c "delete from public.sakina_gifts where user_id = '00000000-0000-0000-0000-00000000aa01'::uuid and occasion_id = 'qa_test_active';"

# Fire two claims in parallel. Both should succeed; neither should raise.
QUERY="set local request.jwt.claim.sub = '00000000-0000-0000-0000-00000000aa01'; select public.claim_sakina_gift('00000000-0000-0000-0000-00000000aa01'::uuid, 'qa_test_active');"

(psql "$SUPABASE_DB_URL" -c "$QUERY" > /tmp/race_a.txt 2>&1) &
(psql "$SUPABASE_DB_URL" -c "$QUERY" > /tmp/race_b.txt 2>&1) &
wait

cat /tmp/race_a.txt /tmp/race_b.txt
# Expected: both files contain {"granted":true,...}. Exactly one has reused=false
# (won the insert). Exactly one has reused=true (saw the conflict, read the existing row).
# Neither file contains "ERROR" or "unique_violation".

# Verify exactly one row exists
psql "$SUPABASE_DB_URL" -c "select count(*) from public.sakina_gifts where user_id = '00000000-0000-0000-0000-00000000aa01'::uuid and occasion_id = 'qa_test_active';"
# Expected: 1
```

If `psql` against the prod URL isn't available locally, the secondary verification is reading the deployed function body and confirming the migration shipped:

```sql
select pg_get_functiondef('public.claim_sakina_gift'::regproc::oid);
-- Body must contain "on conflict (user_id, occasion_id) do nothing"
```

### B4 — outside_window denial
**Verifies:** past occasion returns `outside_window`, writes nothing.

```sql
set local request.jwt.claim.sub = '00000000-0000-0000-0000-00000000aa01';
select public.claim_sakina_gift(
  '00000000-0000-0000-0000-00000000aa01'::uuid,
  'qa_test_past'
);
-- Expected: {"granted":false,"reason":"outside_window"}

select count(*) from public.sakina_gifts
 where user_id = '00000000-0000-0000-0000-00000000aa01'::uuid
   and occasion_id = 'qa_test_past';
-- Expected: 0
```

### B5 — unknown_occasion denial
```sql
set local request.jwt.claim.sub = '00000000-0000-0000-0000-00000000aa01';
select public.claim_sakina_gift(
  '00000000-0000-0000-0000-00000000aa01'::uuid,
  'this_does_not_exist'
);
-- Expected: {"granted":false,"reason":"unknown_occasion"}
```

### B6 — unauthorized denial (auth.uid() mismatch)
```sql
set local request.jwt.claim.sub = '00000000-0000-0000-0000-00000000aa01';
-- Try to claim for someone else
select public.claim_sakina_gift(
  '11111111-1111-1111-1111-111111111111'::uuid,  -- arbitrary other UID
  'qa_test_active'
);
-- Expected: {"granted":false,"reason":"unauthorized"}
```

### B7 — RLS on `sakina_gifts`
**Verifies:** User A cannot SELECT user B's rows.

```sql
-- Insert a row for our QA user
set local request.jwt.claim.sub = '00000000-0000-0000-0000-00000000aa01';
select public.claim_sakina_gift(
  '00000000-0000-0000-0000-00000000aa01'::uuid,
  'qa_test_active'
);

-- Switch identity to a different authenticated user
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
set local role authenticated;
select count(*) from public.sakina_gifts
 where user_id = '00000000-0000-0000-0000-00000000aa01'::uuid;
-- Expected: 0 (RLS hides the row)

reset role;
```

### B8 — `islamic_occasions` is anon-readable
```sql
set local role anon;
select count(*) > 0 from public.islamic_occasions;
-- Expected: true

reset role;
```

### B9 — Mawlid rows are gone
**Verifies:** the cleanup migration `20260525100000_remove_mawlid_occasions.sql` ran.

```sql
select count(*) from public.islamic_occasions where id like 'mawlid\_%' escape '\';
-- Expected: 0

select count(*) from public.sakina_gifts where occasion_id like 'mawlid\_%' escape '\';
-- Expected: 0
```

### B10 — `greatest()` coalesce keeps the longer window
```sql
-- Pre-set a 90d window on QA user
update public.user_profiles
   set gift_premium_until = now() + interval '90 days'
 where id = '00000000-0000-0000-0000-00000000aa01'::uuid;

-- Drop existing claim and re-claim
delete from public.sakina_gifts
 where user_id = '00000000-0000-0000-0000-00000000aa01'::uuid
   and occasion_id = 'qa_test_active';

set local request.jwt.claim.sub = '00000000-0000-0000-0000-00000000aa01';
select public.claim_sakina_gift(
  '00000000-0000-0000-0000-00000000aa01'::uuid,
  'qa_test_active'
);

select gift_premium_until > now() + interval '89 days'
  from public.user_profiles
 where id = '00000000-0000-0000-0000-00000000aa01'::uuid;
-- Expected: true (pre-existing longer window preserved)
```

### B11 — Migration version uniqueness
**Verifies:** the rename `20260525000000` → `20260525100000` actually shipped (the CI failure that surfaced earlier).

```sql
select version, name from supabase_migrations.schema_migrations
 where version like '20260525%';
-- Expected rows:
--   20260525000000_push_referral_vault_secrets
--   20260525100000_remove_mawlid_occasions
--   20260525110000_claim_sakina_gift_race_fix
```

### Section 1 cleanup

```sql
-- Drop QA-only rows
delete from public.sakina_gifts where occasion_id in ('qa_test_active', 'qa_test_past');
delete from public.islamic_occasions where id in ('qa_test_active', 'qa_test_past');
-- Reset gift_premium_until on QA user
update public.user_profiles set gift_premium_until = null
 where id = '00000000-0000-0000-0000-00000000aa01'::uuid;
```

---

## Section 2 — UI rendering (iOS Simulator MCP + temp code mods)

Run the app on a booted iOS simulator with these preconditions:

1. **Section 1 B0 ran successfully.** The QA user exists in `auth.users` with a known password, and `qa_test_active` brackets real `now()`. The plan now drives the UI tests against `qa_test_active` (real-time window) instead of the Feb 2027 seam. The 2027 seam approach was rejected because the server stamps `expires_at = now() + 7d` on the server's clock, not the client's seam — a tester would see "expected Feb 27 2027 / got real-now + 7d" and assume the feature is broken.

2. **Sign in via the app UI.** Open the app on the simulator, complete onboarding OR sign in via email with the credentials from B0:
   - Email: `qa-ramadan-2026-05-25@sakina-test.local`
   - Password: the one whose bcrypt hash you set in B0
   After sign-in, verify via Supabase MCP that `supabaseSyncService.currentUserId` matches the QA user UUID (`00000000-0000-0000-0000-00000000aa01`).

3. **Temp code mod — clock seam override (UI render tests only).** For U3, U4, U5 — the "which occasion is active" rendering tests — temporarily override `GiftService.debugGiftClock` in `lib/main.dart` to point at the seeded 2027 windows so we exercise the `ramadan_` / `eid_fitr_` / `eid_adha_` ID-prefix branches. For U6 (claim flow), U7 (post-claim restart), and U8 (animations), use the **real-time `qa_test_active` occasion** so the post-claim formatted date matches what a real user would see.

Take screenshots after every step. Always `sips -Z 1600 <path>.png` immediately after capture per CLAUDE.md.

### U1 — Loading state collapses to zero height (no 220px flash)
**Verifies:** `_GiftCardLoading() => SizedBox.shrink()` matches the inactive state visually.

Cold-launch the app with `GiftService.debugGiftClock` temporarily replaced with one that adds `await Future.delayed(...)` before returning, so the loader phase is visible. The home dashboard should NOT flash a 220px placeholder.

Easier alternative: just verify the existing widget test (`renders zero-height during loading`) is passing and inspect the home screen during the very first cold-launch frame.

### U2 — Inactive (outside window) renders nothing
**Code mod:** `GiftService.debugGiftClock = () => DateTime.utc(2026, 6, 1)` (between any seeded occasion windows).

Launch app → home screen. The dashboard cards should sit directly below the greeting with no gap. **Take screenshot** and confirm no gift card surface is present (`ui_describe_all` should not include "Accept your gift" text).

### U3 — Pre-claim Ramadan card
**Code mod:** `GiftService.debugGiftClock = () => DateTime.utc(2027, 2, 20)` (mid Ramadan 2027).

Launch app → home screen. Verify:

- Arabic header reads **"رمضان مبارك"** (`mcp__ios-simulator__ui_describe_all` should find the string)
- English headline: **"A gift from Sakina for Ramadan"**
- Body: **"We're celebrating with you. Enjoy 7 days of full Sakina, on us."**
- CTA: **"Accept your gift"**
- Take screenshot; visually verify:
  - Gold Arabic at the top (`AppColors.secondary`)
  - Cream background card with subtle shadow
  - Arabic doesn't bleed into the section above (Aref Ruqaa metric fix)

### U4 — Pre-claim Eid al-Fitr card
**Code mod:** `GiftService.debugGiftClock = () => DateTime.utc(2027, 3, 21)`.

Verify:
- Arabic header: **"عيد مبارك"** (NOT "رمضان مبارك")
- English headline: **"A gift from Sakina for Eid al-Fitr"**

### U5 — Pre-claim Eid al-Adha card
**Code mod:** `GiftService.debugGiftClock = () => DateTime.utc(2027, 5, 28)`.

Verify:
- Arabic header: **"عيد مبارك"**
- English headline: **"A gift from Sakina for Eid al-Adha"**

### U6 — Claim flow (Accept → post-claim)
**Pre-req:** clock seam reverted to `DateTime.now().toUtc()` (real time). The `qa_test_active` occasion from B0 brackets real now, so the card renders pre-claim.

1. Tap **"Accept your gift"** (`mcp__ios-simulator__ui_tap`).
2. Immediately verify the button shows the spinner (claiming=true).
3. Wait up to 5 seconds.
4. Verify the card transitions to the post-claim status row:
   - Card-gift icon (`Icons.card_giftcard_rounded`)
   - Text: **"Your Sakina gift is active until <date>"**
   - The date is **7 days after the current real-world date**. Compute it: `today + 7d` formatted as `MMMM d, yyyy` (e.g., if testing on 2026-05-25, expect "June 1, 2026").
   - Background: `AppColors.primaryLight` (soft green tint)
5. **Take screenshot** of post-claim state.
6. Pull via Supabase MCP: verify the QA user's `sakina_gifts` row exists and `user_profiles.gift_premium_until` is populated.

### U6b — Idempotent re-claim fires `ramadan_gift_claimed` with `reused=true`
**Verifies:** the analytics event fires on BOTH the first claim and the re-claim path. Without this we'd miss a regression where the client only fires the event on `reused=false`.

1. Confirm Section 5 M2 has the first `ramadan_gift_claimed` event from U6 (`reused: false`).
2. Via Supabase MCP, delete the local cache key for this user:
   ```sql
   -- The app reads from SharedPreferences. We force re-resolution by clearing
   -- gift_premium_until on user_profiles AND uninstalling/reinstalling the app,
   -- OR (faster) by manually setting the prefs key to null via a debug action.
   -- Simplest: uninstall + reinstall the app on the simulator, sign in again.
   ```
   `xcrun simctl uninstall booted com.sakina.app` then `flutter run` and sign back in.
3. With `qa_test_active` still active (Section 1 B0 occasion), the home card renders pre-claim again because `cachedExpiresAt()` now returns null. But the `sakina_gifts` row still exists server-side.
4. Tap **"Accept your gift"**. The RPC returns `granted=true, reused=true` (server saw the existing row).
5. Verify the card transitions to post-claim immediately.
6. In Mixpanel (Section 5 M2), confirm a second `ramadan_gift_claimed` event fired with `reused: true` and the same `occasion_id`.

### U7 — Post-claim cold restart
With the cache populated by U6, hot-restart the app.

Expect: the home screen renders the post-claim status row directly (skipping pre-claim) because `cachedExpiresAt()` returns a future timestamp.

### U8 — Animation
Visually verify (record video with `mcp__ios-simulator__record_video`):

- Pre-claim card fades in over ~400ms with an 8px upward drift (`fadeIn` + `moveY`).
- Post-claim status row fades in over ~300ms (no movement).

### U9 — Kill switch
**Code mod:** `Env.ramadanGiftEnabled = false` (or run with `flutter run --dart-define-from-file=env.json --dart-define=RAMADAN_GIFT_ENABLED=false`).

Launch app with `GiftService.debugGiftClock` still at mid-Ramadan. The card must NOT render — `_resolve()` short-circuits to `_GiftCardInactive` when `Env.ramadanGiftEnabled == false`.

### U10 — Mawlid does NOT render
This is the regression pin from the post-removal commit. Even if a Mawlid row were re-seeded, the widget no longer has a `mawlid_` branch in `_arabicHeader` or `_englishHeadline`. Verify by temporarily inserting a Mawlid row via Supabase MCP and pointing the clock seam at it:

```sql
insert into public.islamic_occasions(id, display_name, starts_at, ends_at)
values ('qa_test_mawlid', 'QA Mawlid Test',
        now() - interval '1 day', now() + interval '1 day')
on conflict (id) do nothing;
```

Set clock seam to now-ish, launch app. The card SHOULD render (because the clock is inside `qa_test_mawlid`'s window), but it should fall through to the default branches: Arabic `"رمضان مبارك"` (default), English `"A gift from Sakina"` (no `qa_test_mawlid` prefix match).

Cleanup: `delete from public.islamic_occasions where id = 'qa_test_mawlid';`

### U11 — Signed-out user
Sign out from the app. Cold launch. With the clock seam at mid-Ramadan, the card should still render the pre-claim surface (the `currentOccasion()` call is anon-read on `islamic_occasions`), but tapping Accept should fail because `supabaseSyncService.currentUserId` is null. Snackbar appears with "We couldn't accept the gift just now."

Wait — actually look at `GiftService.claim()` line 81-84: it returns `GiftClaim.denied(reason: 'unauthorized')` when userId is null/empty. The widget's `_acceptGift` then falls through to the snackbar path. Confirm this is the UX we want (it is — defensive).

---

## Section 3 — Entitlement integration (iOS Simulator + Supabase MCP + temp code mods)

The whole point of the gift is that `isPremium()` flips true. Section 2's claim flow only verifies the surface. This section verifies the **integration** with premium-gated features.

### E1 — `isPremium()` returns true after claim
With U6 completed (post-claim state visible), navigate to a premium-gated screen — e.g., the Reflect feature past the free daily cap. Pre-claim, the app should have shown a daily-cap sheet for free users; post-claim, the user should bypass the cap.

Concretely:
1. Before the gift claim: trigger the daily cap (use Reflect once, then again — second tap should show the AI bypass / paywall sheet).
2. Reset state (sign out, sign in again).
3. Claim the gift via U6.
4. Try the same Reflect flow. Expected: premium user — no cap, no paywall, normal response.

### E2 — Premium status disappears at expiry
**Code mod:** advance `GiftService.debugGiftClock` past the server-stamped `expires_at`. Read the actual `gift_premium_until` value from Supabase first (it was stamped at real-now + 7d during U6), then set the seam to ~1 hour after that timestamp.

```sql
select gift_premium_until from public.user_profiles
 where id = '00000000-0000-0000-0000-00000000aa01'::uuid;
-- Suppose it returns 2026-06-01T15:30:00Z
```

Set `GiftService.debugGiftClock = () => DateTime.utc(2026, 6, 1, 16, 30);` (one hour past). Also adjust `qa_test_active.ends_at` to be before that seam so no active occasion brackets the seam either:

```sql
update public.islamic_occasions
   set starts_at = now() - interval '30 days',
       ends_at   = now() - interval '5 days'
 where id = 'qa_test_active';
```

Hot-restart. Verify:
1. Home card flips to **inactive** (cached expiry has passed; no active occasion brackets the seam).
2. The `ramadan_gift_window_expired` analytics event fires exactly once (idempotent — verify a second restart doesn't re-fire).
3. `isPremium()` returns false → premium gates re-engage (re-test the Reflect cap from E1).

Reset `qa_test_active` to bracketing real-now afterward so subsequent tests still see an active window.

### E3 — Cross-device cache refresh
**Setup:**
1. Sign in on Simulator A as the QA user.
2. Claim the gift via U6. Confirm cache populated.
3. Wipe the simulator's app data (`xcrun simctl uninstall booted com.sakina.app` or use a second simulator).
4. Sign in on Simulator B as the same QA user. Cold launch.

Expected: thanks to `refreshGiftPremiumCache()` being called from `app_session.dart:131` on auth foreground, `_isGiftPremium()` returns true on Simulator B even though no `claim()` was made there. The home card renders the post-claim status row (or, if the clock is also inside the occasion window, depending on `cachedExpiresAt()` ordering vs `currentOccasion()`, see widget code).

### E4 — Gift survives RC kill switch
**Code mod:** patch `PurchaseService.initialize` to throw early (or just don't pass RC keys).

Verify the home card still renders post-claim correctly and `isPremium()` returns true — because the gift check runs **before** the `_initialized` guard. This is the key behavioral fix in the rebased `isPremium()` ordering.

---

## Section 4 — Race and edge cases

### R1 — Double-tap on Accept (race)
On the pre-claim card, tap **"Accept your gift"** twice in quick succession (use `mcp__ios-simulator__ui_tap` twice with no wait between).

Expected:
- The widget's `_claiming` re-entry guard absorbs the second tap (line 166: `if (_claiming) return;`).
- Only one RPC fires.
- Card transitions to post-claim cleanly. No snackbar.

If the guard were buggy and two RPCs fired: the new TOCTOU fix in the RPC ensures both return `granted=true, reused=true|false`. No exception path on the server side. Still — the client guard should prevent the second call entirely.

### R2 — Network failure on claim
Disable simulator network mid-claim. Tap Accept. Expected: `claim()` returns `denied(reason='unknown')` → snackbar shows "We couldn't accept the gift just now."

Re-enable network. Hot-restart. Card returns to pre-claim. Tap Accept again. Expected: succeeds.

### R3 — `currentOccasion()` fails
**Code mod:** temporarily replace `fetchPublicRows` to throw. Launch app. Expected: `_resolve()` catches the exception (line 130-134), flips state to `_GiftCardInactive`, renders nothing. No crash.

### R4 — Malformed cached expiry
**Setup:** manually write a garbage value to SharedPreferences for `gift_premium_until:<uid>` via a debug widget or by running with a key like `gift_premium_until:<uid> = 'not-a-date'`.

Expected: `cachedExpiresAt()` returns null (line 162-163), `_isGiftPremium()` returns false, card behaves as if no claim happened.

### R5 — Clock skew (client claims to be in window, server says no)
Set `debugGiftClock` ahead of the occasion `ends_at`. Tap Accept. Expected: server RPC returns `outside_window`, client surfaces snackbar.

Set `debugGiftClock` after the occasion `starts_at` but before server `now()`. (This is the time-travel scenario.) Expected: card renders pre-claim, but tap shows the same snackbar. This is the "client-skew never grants" property.

### R6 — Far-future `gift_premium_until` already set
**Setup (QA-only, this is a test user — cleanup is mandatory below):**

Before claim, manually set `user_profiles.gift_premium_until = now() + interval '365 days'` for the QA user. The next PR adds a freemium guard that blocks this write — until then it's testable. **The tester MUST run the cleanup snippet at the bottom of this test before leaving QA.**

```sql
update public.user_profiles
   set gift_premium_until = now() + interval '365 days'
 where id = '00000000-0000-0000-0000-00000000aa01'::uuid;
```

Claim the gift. Expected: `greatest()` coalesce preserves the 365-day window (server-side).

Reading `gift_service.dart:111-115`: the client cache stamps the RPC's returned `expires_at` (the just-claimed window) verbatim — NOT the server's coalesced 365-day value. This means a previously-set far-future `gift_premium_until` on the server is NOT reflected in the client cache after a fresh claim. The next `refreshGiftPremiumCache()` call (auth foreground, post-onboarding) corrects it.

**Test sequence:**
1. After the claim, query the server: `select gift_premium_until from public.user_profiles where id = ...` — expect ~365 days from now.
2. Read the client cache (SharedPrefs key `gift_premium_until:<uid>`) — expect ~7 days from now (verbatim from claim RPC response).
3. Trigger `refreshGiftPremiumCache()` by closing/reopening the app (auth foreground triggers it via `app_session.dart:131-134`).
4. Re-read the client cache — expect ~365 days from now (refreshed from server).

**Cleanup (MANDATORY — do not skip):**

```sql
-- Reset the QA user's gift_premium_until so we don't leave a 365-day window on a test account.
update public.user_profiles
   set gift_premium_until = null
 where id = '00000000-0000-0000-0000-00000000aa01'::uuid;

delete from public.sakina_gifts
 where user_id = '00000000-0000-0000-0000-00000000aa01'::uuid;
```

### R7 — Window-expired event fires once per cached expiry
1. Claim the gift normally (clock at Feb 20 2027).
2. Advance clock to March 1, 2027 (past 7-day expiry). Hot-restart.
3. Verify the home card is inactive AND `ramadan_gift_window_expired` analytics fired once.
4. Hot-restart again with the same clock. Verify the event does NOT fire again (idempotent via SharedPrefs key).

### R8 — Two overlapping occasion windows
**Setup:** insert two QA test rows that overlap:

```sql
insert into public.islamic_occasions(id, display_name, starts_at, ends_at) values
  ('qa_overlap_a', 'Overlap A', now() - interval '2 days', now() + interval '2 days'),
  ('qa_overlap_b', 'Overlap B', now() - interval '1 day', now() + interval '3 days')
on conflict (id) do nothing;
```

Launch app. Expected: `currentOccasion()` iterates `order by starts_at asc` and returns the first match — `qa_overlap_a`. The card renders for that occasion. Tapping Accept claims `qa_overlap_a`.

Verify: future improvement candidate — should we instead prefer the occasion with the latest `starts_at` (more specific) or the longest remaining window? Today's behavior is "first by start time" which is acceptable for the seeded data (no overlap) but worth noting in the post-mortem.

---

## Section 5 — Analytics verification (Mixpanel MCP)

After Sections 2-4, verify the events fired correctly via `mcp__claude_ai_Mixpanel__Run-Query` or `mcp__claude_ai_Mixpanel__Get-Events`.

### M1 — `ramadan_gift_shown`
Filter: `event = ramadan_gift_shown AND $user_id = <qa-user-id> AND time >= today`.
Expected: 1 event per pre-claim render (U3, U4, U5 → 3 events with distinct `occasion_id` properties).

### M2 — `ramadan_gift_claimed`
Expected: 1 event per claim with `occasion_id` and `reused` properties.

### M3 — `ramadan_gift_window_expired`
Expected: 1 event after R7 (expiry transition), with `expired_at` property.

### M4 — No spurious events outside the gift flow
Skim other events on the QA user's timeline. No `ramadan_gift_*` events should appear during U2 (inactive state) or before claim.

---

## Section 6 — Build + lint pass

### L1 — `flutter analyze`
```bash
cd flutter && flutter analyze
```
Expected: clean for all files touched by this PR. Baseline issues elsewhere acceptable.

### L2 — Full test suite
```bash
cd flutter && flutter test
```
Expected: every test passes including the 51 gift/referral/analytics tests.

### L3 — Release build smoke
```bash
cd flutter && flutter build ios --release --dart-define-from-file=env.json
./scripts/check_no_fake_strings.sh
```
Expected: build succeeds, fake-strings tripwire clean.

---

## Execution order (recommended)

For efficiency, run sections in this order:

1. **Section 1 (Backend)** — fast, deterministic, no simulator needed. ~10 minutes via Supabase MCP. **Single biggest signal** if the deployed RPC is correct.
2. **Section 6 (Build / lint)** — confirms the working tree is shippable. ~3 minutes.
3. **Section 2 (UI)** — simulator boot + claim flow. ~20 minutes. Most of the time is the temp code mod cycle (edit, hot-restart, screenshot).
4. **Section 3 (Entitlement integration)** — ties UI to premium gates. ~15 minutes.
5. **Section 4 (Race / edge cases)** — narrow but important. ~15 minutes.
6. **Section 5 (Analytics)** — last, after enough events have fired. ~5 minutes.

Total: ~70 minutes of focused execution.

---

## Definition of done

PR #17 is ready for the merge button when:

- All Section 1 backend tests return the expected payloads.
- Section 2 U3-U7 screenshots show the correct Arabic headers, English headlines, claim flow, post-claim state.
- Section 3 E1 confirms `isPremium()` actually unlocks premium gates.
- Section 4 R1 confirms double-tap doesn't double-claim or error.
- Section 5 analytics events fire with the right shape.
- Section 6 build + tests + tripwire pass.
- No findings beyond the already-deferred `gift_premium_until` freemium guard (queued as next PR).

If any test fails, fix or document, then re-run the affected section.

---

## Cleanup after QA

```sql
-- Remove all QA-only rows (idempotent)
delete from public.sakina_gifts
 where occasion_id like 'qa\_%' escape '\';

delete from public.islamic_occasions
 where id like 'qa\_%' escape '\';

-- Reset gift state on QA user
update public.user_profiles
   set gift_premium_until = null
 where id = '00000000-0000-0000-0000-00000000aa01'::uuid;

-- Optional: delete the QA auth user entirely if it was created just for this run
-- delete from auth.users where id = '00000000-0000-0000-0000-00000000aa01'::uuid;
```

Also revert all temp code mods (clock seam overrides, kill switch toggles, RC initialization patches). The plan only allows them inside the QA window; nothing committed.

---

## NOT in scope (post-/plan-eng-review)

| Item | Why deferred |
|------|--------------|
| Multi-region timezone matrix | Sakina ships English-only single-region for v1; Ramadan window crossings across MENA / SE Asia not relevant pre-launch. |
| Battery / network-disconnect resilience matrix | App-wide concern, not gift-specific. Existing QA framework doesn't cover it; deferring until a real device test pass. |
| Load test on `claim_sakina_gift` RPC | Pre-launch user base. Will only matter if we see >100 concurrent claims on day 1 of Ramadan 2027. File as a post-launch TODO if needed. |
| Accessibility audit (VoiceOver, Dynamic Type) of `RamadanGiftCard` | Worth doing for the whole app, not gift-specific. Defer to a dedicated a11y QA pass. |
| Eid al-Fitr 2027 windowed pre-test (different occasion ID prefix) | U4 covers the `eid_fitr_` branch via the clock seam. A real-time window for Eid is what the 2027 launch QA will do. |
| Localization (Arabic UI, RTL flip of the whole app) | Out of scope for v1. `RamadanGiftCard` mixes Arabic + English by design via `AdjustedArabicDisplay`. |
| Performance profiling of `currentOccasion()` SELECT | Table has 3 rows. Even a full scan is <1ms. Not worth measuring. |

## What already exists (don't rebuild)

| Sub-problem | Existing coverage | Plan uses it? |
|-------------|-------------------|---------------|
| Claim RPC semantics (in-window, idempotent, denial paths, RLS) | `supabase/tests/ramadan_gifts_test.sql` — 14 pgtap assertions | Section 1 re-verifies live against the deployed RPC, doesn't rebuild. |
| Client cache logic | `test/services/purchase_service_gift_test.dart` — 5 tests | E1-E2 verify integration with premium gates, not the unit logic. |
| Widget state machine | `test/features/gifts/ramadan_gift_card_test.dart` — 5 tests | Section 2 verifies the real device rendering, not the state transitions. |
| Migration uniqueness check | CI `sql-tests` job applies all migrations | B11 is a quick deployed-state assertion, lighter weight. |
| Mawlid removal regression | `ramadan_gift_card_test.dart` (test deleted post-removal); cleanup migration applied | B9 + U10 verify deployment + widget-level fallback. |

## Coverage diagram

```
PR #17 CODE PATHS vs MANUAL QA COVERAGE
============================================
[+] supabase/migrations/20260514100000_ramadan_gifts.sql
    │  (covered live by Section 1)
    ├── [★★★ B1]    Happy path claim — granted=true, sakina_gifts + user_profiles written
    ├── [★★★ B2]    Idempotent re-claim — reused=true, no double insert
    ├── [★★  B4]    outside_window denial
    ├── [★★  B5]    unknown_occasion denial
    ├── [★★  B6]    unauthorized denial (auth.uid() mismatch)
    ├── [★★★ B7]    RLS on sakina_gifts (anon + authenticated other user)
    ├── [★★  B8]    islamic_occasions anon-readable
    └── [★★★ B10]   greatest() coalesce

[+] supabase/migrations/20260525100000_remove_mawlid_occasions.sql
    └── [★★  B9]    Mawlid rows deleted

[+] supabase/migrations/20260525110000_claim_sakina_gift_race_fix.sql
    └── [★★★ B3]    Race-safe concurrent claim (psql parallel sessions)

[+] lib/services/gift_service.dart
    │  (covered by unit tests; integration in Sections 2-3)
    ├── claim()           — [★★★ U6/U6b] end-to-end including reused=true path
    ├── currentOccasion() — [★★★ U3/U4/U5] bracket-match per occasion family
    └── cachedExpiresAt() — [★★★ U7] post-claim cold restart honors cache

[+] lib/services/purchase_service.dart
    ├── isPremium()              — [★★★ E1] flips true after claim, unlocks AI bypass
    ├── _isGiftPremium()         — [★★★ E4] honored even when RC uninitialized
    └── refreshGiftPremiumCache()— [★★★ E3] cross-device entitlement restore
                                  [★★  R6] reconciles server's greatest() value

[+] lib/features/gifts/widgets/ramadan_gift_card.dart
    │
    ├── _GiftCardLoading → SizedBox.shrink       — [★★  U1]
    ├── _GiftCardInactive (outside window)       — [★★★ U2]
    ├── _GiftCardInactive (kill switch tripped)  — [★★★ U9]
    ├── _GiftCardInactive (caught exception)     — [★★  R3]
    ├── _GiftCardPreClaim (ramadan_)             — [★★★ U3]
    ├── _GiftCardPreClaim (eid_fitr_)            — [★★★ U4]
    ├── _GiftCardPreClaim (eid_adha_)            — [★★★ U5]
    ├── _GiftCardPreClaim (unknown prefix → default headers) — [★★  U10]
    ├── _GiftCardPostClaim                       — [★★★ U6/U7]
    ├── _acceptGift (success)                    — [★★★ U6]
    ├── _acceptGift (denial → snackbar)          — [★★★ U11]
    ├── _acceptGift (re-entry guard on double-tap) — [★★★ R1]
    ├── _maybeFireExpiredEvent (once)            — [★★★ R7/M3]
    └── _fireShownEventOnce                      — [★★  M1]

[+] lib/services/analytics_events.dart
    ├── ramadan_gift_shown        — [★★  M1]
    ├── ramadan_gift_claimed (reused=false) — [★★★ M2 via U6]
    ├── ramadan_gift_claimed (reused=true)  — [★★★ M2 via U6b]
    └── ramadan_gift_window_expired — [★★★ M3 via R7/E2]

[+] lib/core/env.dart::ramadanGiftEnabled       — [★★★ U9]
[+] lib/features/progress/screens/progress_screen.dart — [★★  U2 / U6]
[+] lib/core/app_session.dart::refreshGiftPremiumCache call site — [★★★ E3 / R6]
[+] lib/features/onboarding/providers/onboarding_provider.dart::refreshGiftPremiumCache call site — [★★ implicit via E3, not exercised]

──────────────────────────────────────────
COVERAGE: 36/36 paths covered (100%)
QUALITY:  ★★★: 24  ★★: 12  ★: 0
GAPS: 1 partial — onboarding_provider refresh call site is exercised only when the user re-onboards after the gift; the plan doesn't drive a re-onboarding cycle. Considered LOW priority (covered indirectly by E3's auth-foreground path which calls the same method).
──────────────────────────────────────────
```

## Failure modes

For each new codepath, one realistic production failure + whether the plan catches it:

| Codepath | Failure | Has test? | Has error handling? | Surfaced to user? |
|----------|---------|-----------|---------------------|-------------------|
| `claim_sakina_gift` RPC: server timeout (Postgrest 30s) | Client gets HTTP 504 | ✅ R2 (network disable) | ✅ `GiftService.claim` catches null → `denied(reason='unknown')` | ✅ snackbar |
| `claim_sakina_gift` RPC: unique_violation (race, OLD code) | RPC throws | ✅ B3 (race test) | ✅ NEW migration: `on conflict do nothing` | N/A (resolved silently) |
| `currentOccasion()` SELECT: anon RLS regression | Returns 0 rows | ✅ B8 + R3 | ✅ widget catches throw → `_GiftCardInactive` | ✅ silent (correct UX) |
| `_isGiftPremium`: SharedPreferences throws | Cache read fails | ✅ R4 (malformed value) | ✅ try/catch fall-through to RC | ✅ silent fall-through |
| `refreshGiftPremiumCache`: Supabase 503 | Cache stays stale | ❌ (best-effort silent swallow) | ✅ try/catch around fetch | ⚠️ silent — user keeps old cache |
| `_acceptGift`: server returns `granted:false` mid-claim | Card stays pre-claim | ✅ R5 (clock skew) | ✅ snackbar | ✅ "couldn't accept" message |
| `_fireShownEventOnce`: Mixpanel offline | Event lost | ❌ no test | ❌ no retry | ⚠️ silent loss |
| `_maybeFireExpiredEvent`: SharedPrefs full | Key not written | ❌ no test | ⚠️ no try/catch around `setBool` | ⚠️ event could fire twice |

**Critical gaps:** 0. All silent-failure modes are bounded (loss of an analytics event vs loss of money). Two minor gaps (Mixpanel offline, SharedPrefs full) are app-wide concerns, not gift-specific.

## TODOS proposed

The QA pass may surface real bugs. Captured as TODOs only if they're not blocking the v1 launch:

1. **Add unit test for `refreshGiftPremiumCache` reading from Supabase.** No coverage exists for either `refreshReferralPremiumCache` or the new `refreshGiftPremiumCache` — both hit Supabase and are untested. Would need a Postgrest mock pattern.
2. **Add a re-onboarding test path.** The `onboarding_provider.dart` refresh call site at `:560` only fires during signup. No test drives a user through signup → claim → re-onboarding to confirm the second cache restore path. Low priority (covered indirectly).
3. **Document the `mawlid_2026` test occasion convention.** If future tests use `mawlid_*` ids for unrelated tests, they'll get auto-deleted on next migration application. Worth a note in the migration file.

## Worktree parallelization

Section 1 (Backend) is the only parallelization opportunity — all SQL via Supabase MCP. Could split B1-B6 (claim path) and B7-B11 (RLS / migrations) across two MCP sessions. Saves ~3 minutes.

Sections 2-5 are simulator-bound and sequential by nature (one simulator, one app instance).

**Recommended:** sequential execution. The plan's ~70 minute estimate already assumes that.

## Completion summary

- **Step 0 Scope Challenge:** accepted as-is (single feature, no scope reduction)
- **Section 1 — Plan structure:** 5 issues found, 5 resolved (U6/E2 server clock, B3 race rigor, Section 2 auth gap, R6 cleanup emphasis, U6b idempotent event)
- **Section 2 — Plan quality:** No additional issues
- **Section 3 — Coverage:** 36/36 paths covered (100%), 24★★★ / 12★★ / 0★
- **Section 4 — Execution efficiency:** Plan claims ~70min; realistic if no failures
- **NOT in scope:** written (7 items)
- **What already exists:** written (5 mappings)
- **TODOS:** 3 items proposed
- **Failure modes:** 0 critical gaps, 2 minor app-wide concerns flagged
- **Outside voice:** skipped (small scope review, no cross-model tension expected)
- **Lake Score:** 5/5 (all 5 issues resolved with complete options, no shortcuts)

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR (PLAN) | 5 issues found + applied, 36/36 paths covered, 0 critical gaps |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**UNRESOLVED:** 0
**VERDICT:** ENG CLEARED — plan ready to execute. Recommended order: Section 1 (Supabase MCP, ~10min) → Section 6 (Build/lint, ~3min) → Section 2 (Simulator UI, ~20min) → Section 3 (Entitlement, ~15min) → Section 4 (Edge cases, ~15min) → Section 5 (Mixpanel, ~5min).

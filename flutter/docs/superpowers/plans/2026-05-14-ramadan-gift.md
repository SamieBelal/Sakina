# Ramadan / Eid Gift Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a calendar-anchored "Sakina Gift" that grants any signed-in user 7 days of full premium during Islamic occasions (Ramadan, Eid al-Fitr, Eid al-Adha). The gift is automatic (no dismissal trigger, no countdown, no discount), shown as a beautiful welcome card on app open during the occasion window, and never gated behind any dark pattern. It serves as both retention (existing free users get a glimpse of premium during their highest spiritual-engagement moments) and growth (premium users feel rewarded; share-worthy moment). Brand-additive, not brand-extractive.

**Architecture:** A new `RamadanGiftCard` shown on home-screen mount during active occasion windows. Server-side `islamic_occasions` table (or hardcoded constants for v1) defines the calendar:

- Ramadan 2027: 2027-02-17 to 2027-03-19
- Eid al-Fitr 2027: 2027-03-20 to 2027-03-22
- Hajj/Eid al-Adha 2027: 2027-05-27 to 2027-06-04

Each user gets ONE 7-day premium window per occasion per year, granted on first qualifying app open during the window. Tracked server-side via `sakina_gifts` table (user_id, occasion_id, granted_at, expires_at). Mechanism: same `referral_premium_until` column pattern from refer-unlock (or a sibling `gift_premium_until` for clarity) — Supabase-only, never RevenueCat, no StoreKit involvement.

NO countdown. NO discount. NO urgency. Pure gift framing.

**Tech Stack:** Flutter 3.41.6, Supabase RPC + RLS, shared_preferences for client-side cached entitlement window (user-scoped keys per `auth_service.dart`'s `scopedKey` pattern), `Env.ramadanGiftEnabled` kill-switch flag.

---

## Background — why this matters

Sakina is named after the Arabic word for tranquility (sakīna). A ticking gold 24h countdown is tonally incompatible with the product proposition. The original winback-discount plan optimized ARPU at the cost of brand. The Ramadan/Eid Gift inverts the mechanic: instead of "we'll punish you with urgency if you don't pay," it's "we're celebrating Allah's blessings with you." Same approximate conversion impact (RevenueCat shows seasonal-gift mechanics in spiritual apps drive higher annual conversion in the 30 days following the gift expiry, since users now know what they're missing). Apple-compliant, FTC-compliant, brand-additive.

> **App Review reviewer note (copy this into the App Store Connect review note field when submitting):**
>
> Sakina grants signed-in users a 7-day full-premium window once per Islamic occasion per year (Ramadan, Eid al-Fitr, Eid al-Adha). This is non-IAP content delivery, calendar-anchored, never triggered by user behavior or dismissal. There is no discount, no countdown timer, no urgency UX. Server-enforced single-claim per occasion. RevenueCat entitlements are NOT touched; the gift is purely a Supabase-side feature-access window. No StoreKit interaction.

Sakina is pre-launch with zero users, so cannibalization, baseline-measurement, and price-anchor concerns from the original winback plan are moot. Brand stance is **no urgency** (Hallow/Glorify/Calm spectrum) — not heavy urgency (Duolingo/Cal-AI). This mechanic is the v2 direction per CEO review's 10x recommendation.

---

## File Structure

**Modify:**

- `lib/services/purchase_service.dart` — extend `_isReferralPremium()` OR add a parallel `_isGiftPremium()` reading `user_profiles.gift_premium_until` (sibling field). Both paths OR'd into `isPremium()`. If reusing the refer-unlock cache, add `gift_premium_until:<uid>` as a second scoped SharedPreferences key.
- `lib/features/daily/screens/home_screen.dart` (or whichever is the post-onboarding root) — show `RamadanGiftCard` widget conditional on an active occasion + user not already-claimed.
- `lib/services/analytics_events.dart` — add `ramadan_gift_shown`, `ramadan_gift_claimed`, `ramadan_gift_window_expired` events.
- `lib/core/env.dart` — add `Env.ramadanGiftEnabled` kill-switch flag (compile-time `String.fromEnvironment('RAMADAN_GIFT_ENABLED')`, defaults to enabled if unset; matches the rest of the `Env` pattern). Mirror the key in `env.json` and `env.example.json`.

**Create:**

- `supabase/migrations/20260514100000_ramadan_gifts.sql` — `islamic_occasions` table (id, name, starts_at, ends_at), `sakina_gifts` table (user_id, occasion_id unique-together, granted_at, expires_at), `claim_sakina_gift(p_user, p_occasion)` RPC, seed data for 2027 occasions.
- `supabase/tests/ramadan_gifts_test.sql` — pgtap covering: occasion in range, single-claim idempotency, expired occasion no grant, RLS.
- `lib/features/gifts/widgets/ramadan_gift_card.dart` — the home-screen welcome card.
- `lib/services/gift_service.dart` — client wrapper around `claim_sakina_gift` with `debugGiftClock` test seam (mirrors `debugRewardsClock` / `debugLaunchGateClock` per CLAUDE.md Known Bugs section).
- `test/services/gift_service_test.dart`.

**Do NOT modify:**

- The refer-unlock `paywall_dismiss_count` infrastructure — no longer needed by this plan.
- The RevenueCat dashboard — no separate offering, no discount product needed.
- Any subscription group configuration — no separate group, no SKU at all.

---

## Task 0: Define Islamic occasion calendar dates

This must be done before Task 1 so the migration seeds correct dates.

- [ ] **Step 1: Verify Hijri-to-Gregorian conversions for 2027 onwards**

Document the source as Umm al-Qura (the Saudi authoritative calendar) or a comparable scholarly source. Note that observation-based moonsighting can shift Ramadan/Eid by ±1 day per region — we accept that v1 uses a single canonical date set rather than per-region observation. Local calendar variance is a Phase 2 concern.

Canonical seed for 2027:

| Occasion          | Starts (UTC) | Ends (UTC)   | Notes                                |
| ----------------- | ------------ | ------------ | ------------------------------------ |
| Ramadan 2027      | 2027-02-17   | 2027-03-19   | ~30-day window                       |
| Eid al-Fitr 2027  | 2027-03-20   | 2027-03-22   | 3-day window                         |
| Eid al-Adha 2027  | 2027-05-27   | 2027-06-04   | Hajj period + 3-day Eid              |

All `starts_at` / `ends_at` are `timestamptz` boundaries at `00:00:00Z` and `23:59:59Z` respectively. Server-side `now() between starts_at and ends_at` is the authoritative check.

- [ ] **Step 2: Save the source reference**

Create `docs/decisions/2026-05-14-islamic-occasion-calendar-source.md` with the citation + screenshot of the source page. This avoids future debate when a developer asks "where did these dates come from?".

- [ ] **Step 3: No commit**

---

## Task 1: Supabase schema + claim RPC + pgtap

**Files:**

- Create: `supabase/migrations/20260514100000_ramadan_gifts.sql`
- Create: `supabase/tests/ramadan_gifts_test.sql`

- [ ] **Step 1: Migration**

```sql
-- 20260514100000_ramadan_gifts.sql

create table if not exists public.islamic_occasions (
  id           text primary key,            -- e.g. 'ramadan_2027', 'eid_fitr_2027'
  display_name text not null,
  starts_at    timestamptz not null,
  ends_at      timestamptz not null,
  constraint occasion_window_valid check (ends_at >= starts_at)
);

alter table public.islamic_occasions enable row level security;

-- Public read; anon can see the calendar but cannot write.
create policy "occasions readable by all"
  on public.islamic_occasions for select using (true);

create table if not exists public.sakina_gifts (
  user_id     uuid not null references auth.users(id) on delete cascade,
  occasion_id text not null references public.islamic_occasions(id),
  granted_at  timestamptz not null default now(),
  expires_at  timestamptz not null,
  primary key (user_id, occasion_id)
);

alter table public.sakina_gifts enable row level security;

create policy "gifts readable by owner"
  on public.sakina_gifts for select using (auth.uid() = user_id);

-- No INSERT/UPDATE/DELETE policy; only the SECURITY DEFINER RPC writes.

-- Companion column on user_profiles for fast premium-window checks without a join.
alter table public.user_profiles
  add column if not exists gift_premium_until timestamptz;

-- Claim the gift if the user is inside an active occasion window and has not
-- already claimed this occasion. Idempotent: re-calling within the window
-- returns the existing grant. After ends_at, no grant.
create or replace function public.claim_sakina_gift(p_user uuid, p_occasion text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_occ        public.islamic_occasions%rowtype;
  v_existing   public.sakina_gifts%rowtype;
  v_expires_at timestamptz;
begin
  if auth.uid() is null or auth.uid() <> p_user then
    return jsonb_build_object('granted', false, 'reason', 'unauthorized');
  end if;

  select * into v_occ from public.islamic_occasions where id = p_occasion;
  if not found then
    return jsonb_build_object('granted', false, 'reason', 'unknown_occasion');
  end if;

  if now() < v_occ.starts_at or now() > v_occ.ends_at then
    return jsonb_build_object('granted', false, 'reason', 'outside_window');
  end if;

  -- Idempotency: if already claimed for this occasion, return existing grant.
  select * into v_existing
    from public.sakina_gifts
   where user_id = p_user and occasion_id = p_occasion;

  if found then
    return jsonb_build_object(
      'granted', true,
      'granted_at', v_existing.granted_at,
      'expires_at', v_existing.expires_at,
      'reused', true
    );
  end if;

  v_expires_at := now() + interval '7 days';

  insert into public.sakina_gifts(user_id, occasion_id, granted_at, expires_at)
  values (p_user, p_occasion, now(), v_expires_at);

  -- Mirror to user_profiles for cheap premium gate. If a later occasion's
  -- window pushes the date further out, GREATEST keeps the longer window.
  update public.user_profiles
     set gift_premium_until = greatest(coalesce(gift_premium_until, now()), v_expires_at)
   where id = p_user;

  return jsonb_build_object(
    'granted', true,
    'granted_at', now(),
    'expires_at', v_expires_at,
    'reused', false
  );
end $$;

revoke execute on function public.claim_sakina_gift(uuid, text) from anon;

-- Seed 2027 occasions. Idempotent via ON CONFLICT.
insert into public.islamic_occasions(id, display_name, starts_at, ends_at) values
  ('ramadan_2027',    'Ramadan 2027',     '2027-02-17 00:00:00+00', '2027-03-19 23:59:59+00'),
  ('eid_fitr_2027',   'Eid al-Fitr 2027', '2027-03-20 00:00:00+00', '2027-03-22 23:59:59+00'),
  ('eid_adha_2027',   'Eid al-Adha 2027', '2027-05-27 00:00:00+00', '2027-06-04 23:59:59+00')
on conflict (id) do nothing;
```

`claim_sakina_gift` is SECURITY DEFINER with `search_path = public` pinned (matches the project's `20260510000000_pin_function_search_path.sql` posture). It self-checks `auth.uid()` to prevent user A from claiming gifts for user B. The PRIMARY KEY on `(user_id, occasion_id)` is what enforces single-claim per occasion — the explicit existing-row check is for returning the idempotent payload, not for correctness.

- [ ] **Step 2: Apply via Supabase MCP + write pgtap**

Cover:

- In-window first call returns `{granted: true, reused: false, expires_at: now()+7d}` and writes both `sakina_gifts` and `user_profiles.gift_premium_until`.
- In-window second call returns the SAME `granted_at` / `expires_at` with `reused: true` (idempotent — no re-stamp, no double 7-day extension).
- Pre-window call returns `{granted: false, reason: 'outside_window'}`, writes nothing.
- Post-window call returns `{granted: false, reason: 'outside_window'}`, writes nothing.
- Unknown `p_occasion` returns `{granted: false, reason: 'unknown_occasion'}`.
- `auth.uid()` mismatch: caller authenticated as user A passes `p_user = B` → returns `{granted: false, reason: 'unauthorized'}` and does NOT stamp B's row. Pin with `set_config('request.jwt.claim.sub', '<A>', true)` then call `claim_sakina_gift('<B>', 'ramadan_2027')`.
- RLS: anon `select` from `sakina_gifts` returns 0 rows even when rows exist; authenticated user B selecting user A's row returns 0 rows.
- `greatest()` coalesce: if `gift_premium_until` already holds a future timestamp (from a previous occasion), claiming a shorter overlapping occasion does not regress the window.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260514100000_ramadan_gifts.sql supabase/tests/ramadan_gifts_test.sql
git commit -m "feat(gifts): islamic_occasions + sakina_gifts + claim RPC

Calendar-anchored 7-day premium gift granted once per Islamic occasion
per user. SECURITY DEFINER claim RPC with pinned search_path, owner-only
RLS on the gifts table. Seed data for Ramadan, Eid al-Fitr, and Eid
al-Adha 2027."
```

---

## Task 2: `GiftService` client wrapper

**Files:**

- Create: `lib/services/gift_service.dart`
- Create: `test/services/gift_service_test.dart`

- [ ] **Step 1: Write the failing test**

Mock the Supabase RPC. Verify:

- `claim()` proxies `claim_sakina_gift` and returns a parsed `GiftClaim` record.
- Server-returned `expiresAt` is preserved verbatim (NOT recomputed client-side).
- `outside_window` / `unauthorized` / `unknown_occasion` responses each surface as a typed result.
- The service mirrors `expiresAt` to a user-scoped SharedPreferences key (`gift_premium_until:<uid>` via `supabaseSyncService.scopedKey`) so `PurchaseService` can read the window without a network round-trip.
- `debugGiftClock` seam lets tests drive deterministic time.
- `currentOccasion()` returns the active occasion id for `debugGiftClock()` falling inside a window, or null otherwise.

- [ ] **Step 2: Implement**

```dart
class GiftService {
  GiftService(this._supabase);
  final SupabaseClient _supabase;

  // Clock-skew acknowledgment: server returns `expires_at` (authoritative);
  // client reads it back via debugGiftClock() for window checks. Mirrors
  // debugRewardsClock / debugLaunchGateClock per CLAUDE.md Known Bugs.
  @visibleForTesting
  static DateTime Function() debugGiftClock = () => DateTime.now().toUtc();

  Future<GiftClaim> claim(String userId, String occasionId) async {
    final response = await _supabase.rpc(
      'claim_sakina_gift',
      params: {'p_user': userId, 'p_occasion': occasionId},
    );
    final map = response as Map<String, dynamic>;
    if (map['granted'] != true) {
      return GiftClaim.denied(reason: map['reason'] as String? ?? 'unknown');
    }
    final expiresAt = DateTime.parse(map['expires_at'] as String).toUtc();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      supabaseSyncService.scopedKey('gift_premium_until'),
      expiresAt.toIso8601String(),
    );
    return GiftClaim.granted(
      expiresAt: expiresAt,
      reused: map['reused'] as bool? ?? false,
    );
  }

  // Reads the seeded islamic_occasions table; returns the id of whichever
  // occasion brackets debugGiftClock(), or null.
  Future<String?> currentOccasion() async { /* ... */ }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/services/gift_service.dart test/services/gift_service_test.dart
git commit -m "feat(gifts): GiftService — claim RPC wrapper, occasion lookup, scoped cache

claim() proxies claim_sakina_gift and mirrors expiresAt to a user-scoped
SharedPreferences key for instant cold-launch entitlement checks.
currentOccasion() returns the active occasion id from islamic_occasions
based on debugGiftClock(). Seam mirrors debugRewardsClock / debugLaunchGateClock
per CLAUDE.md."
```

---

## Task 3: `RamadanGiftCard` widget + home-screen wiring + kill switch

**Files:**

- Create: `lib/features/gifts/widgets/ramadan_gift_card.dart`
- Modify: `lib/features/daily/screens/home_screen.dart` (or whichever is the post-onboarding root)
- Modify: `lib/core/env.dart`
- Modify: `env.example.json`

- [ ] **Step 1: Add the `Env.ramadanGiftEnabled` flag**

In `lib/core/env.dart`:

```dart
static const String ramadanGiftEnabled =
    String.fromEnvironment('RAMADAN_GIFT_ENABLED', defaultValue: 'true');
```

Mirror in `env.example.json` so clean checkouts know the key exists. The flag is a kill switch — flip to `false` in `env.json` and rebuild to disable the gift surface entirely.

- [ ] **Step 2: Build `RamadanGiftCard`**

Layout (top to bottom), wrapped in the home-screen welcome stack:

- Soft cream surface (`AppColors.surface`) with 16px rounded corners and a subtle Islamic-geometric watermark at 5-8% opacity (per CLAUDE.md design system).
- Header in `AdjustedArabicDisplay` (Aref Ruqaa, fontSize 36): `رمضان مبارك` or `عيد مبارك` depending on occasion. Use the `AdjustedArabicDisplay` widget per CLAUDE.md's Aref Ruqaa font-metric fix, with `SizedBox(height: 33)` above and `SizedBox(height: 20)` below.
- English headline (DM Serif Display): "A gift from Sakina for Ramadan" (or the active occasion's display name).
- Body copy (DM Sans, `AppColors.textSecondary`): "We're celebrating with you. Enjoy 7 days of full Sakina, on us." NO urgency, NO countdown, NO discount language.
- Single CTA: "Accept your gift" — green pill (`AppColors.primary`), DM Sans medium. Tap calls `GiftService.claim()` for the current occasion.
- Below CTA, small footer caption: "Expires <date>" (DM Sans 12px, `AppColors.textTertiary`). Renders the date verbatim from server `expires_at` — no live countdown, no ticking timer.

Show ONLY if all are true:

1. `Env.ramadanGiftEnabled == 'true'`
2. `GiftService.currentOccasion()` returns non-null
3. The user has NOT already claimed this occasion (`sakina_gifts` lookup OR `gift_premium_until` already past for this occasion's window)

If the user already accepted the gift for the active occasion, replace the card with a quieter "Your Sakina gift is active until <date>" status row instead of hiding it entirely — premium feels rewarded.

**Loading-gate pattern (mirrors `_rewardsLoaded` in `daily_launch_overlay.dart` per CLAUDE.md Known Bugs / PR #8):**

The home screen must NOT render a flickering "no card → card appears" state on cold launch. Gate the welcome stack on a `_giftStateLoaded` flag; render `SakinaLoader()` (or the existing welcome skeleton) until `currentOccasion()` + claim-status lookup resolves. Wrap in `.timeout(10s)` so a hung network can't trap users on the spinner.

- [ ] **Step 3: Wire the home screen**

Add the card to the home-screen welcome stack. Fire analytics:

- `ramadan_gift_shown` (occasion_id) — once per session when the card renders.
- `ramadan_gift_claimed` (occasion_id, reused) — when claim succeeds.
- `ramadan_gift_window_expired` (occasion_id) — when `gift_premium_until` lapses (fire-once via SharedPrefs marker, scoped by user).

- [ ] **Step 4: Commit**

```bash
git add lib/features/gifts/widgets/ramadan_gift_card.dart lib/features/daily/screens/home_screen.dart lib/core/env.dart lib/services/analytics_events.dart env.example.json
git commit -m "feat(gifts): RamadanGiftCard home-screen surface + kill switch

Calendar-anchored welcome card shown only inside an active Islamic
occasion window. AdjustedArabicDisplay for the bismillah-style Arabic
greeting per CLAUDE.md font-metric fix. CTA calls GiftService.claim;
no countdown, no urgency, no discount. Env.ramadanGiftEnabled flag
provides a compile-time kill switch."
```

---

## Task 4: Extend `PurchaseService.isPremium()` to OR over the gift window

**Files:**

- Modify: `lib/services/purchase_service.dart`

- [ ] **Step 1: Add the gift-premium check**

Mirror the refer-unlock `_isReferralPremium()` shape exactly. Read the user-scoped `gift_premium_until:<uid>` SharedPreferences key, parse the ISO timestamp, compare against `debugGiftClock()` (or whichever clock seam already lives on `PurchaseService`). OR the result into `isPremium()` alongside the RC entitlement check and the existing referral check.

```dart
Future<bool> isPremium() async {
  if (await _isRevenueCatPremium()) return true;
  if (await _isReferralPremium())   return true;
  if (await _isGiftPremium())       return true;
  return false;
}

Future<bool> _isGiftPremium() async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return false;
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(supabaseSyncService.scopedKey('gift_premium_until'));
  if (raw == null) return false;
  final until = DateTime.tryParse(raw)?.toUtc();
  if (until == null) return false;
  return GiftService.debugGiftClock().isBefore(until);
}
```

Caveat: the SharedPrefs cache is best-effort. The Supabase `user_profiles.gift_premium_until` column is authoritative. On app launch, the existing `sync_all_user_data` RPC should already pull `gift_premium_until` into local cache (extend the RPC's projection if needed — but only in a follow-up plan, not here; this plan ships with claim-time write being the cache populator).

- [ ] **Step 2: Test**

Unit test `_isGiftPremium()`:

- Returns false when no cached value.
- Returns true when cached `gift_premium_until` is in the future.
- Returns false when cached `gift_premium_until` is in the past.
- `debugGiftClock` override drives all of the above deterministically.

- [ ] **Step 3: Commit**

```bash
git add lib/services/purchase_service.dart test/services/purchase_service_gift_test.dart
git commit -m "feat(gifts): PurchaseService.isPremium honors gift_premium_until window

OR-s the gift window into the entitlement check alongside the RC and
refer-unlock paths. SharedPrefs cache is user-scoped via scopedKey;
debugGiftClock seam matches the rest of the UTC clock-seam pattern
per CLAUDE.md."
```

---

## Task 5: Full verification

- [ ] **Step 1: `flutter test && flutter analyze`**

Confirm clean run with the new test files.

- [ ] **Step 2: Manual sign-in-during-occasion simulation**

Override `GiftService.debugGiftClock` from a debug toggle (or via a one-off test harness) to a date inside the Ramadan 2027 window. Walk through:

1. Fresh install, complete onboarding, sign in.
2. Land on home screen. Expect: `RamadanGiftCard` renders with "Ramadan Mubarak" header.
3. Tap "Accept your gift". Expect: card transitions to "Your Sakina gift is active until <date>".
4. Navigate to any premium-gated surface. Expect: gates open (no paywall).
5. Force-quit and cold-launch. Expect: `_isGiftPremium()` reads the cached `gift_premium_until` and premium remains active without a network round-trip.
6. Override `debugGiftClock` to 8 days past `granted_at`. Expect: premium-gated surfaces gate again, and the home card returns to its pre-claim state for the NEXT occasion (no re-claim possible for the same occasion).

- [ ] **Step 3: Out-of-window sanity**

Set `debugGiftClock` to 2027-04-15 (between Eid al-Fitr and Eid al-Adha). Expect: no card on home screen, `currentOccasion()` returns null, no analytics fires.

- [ ] **Step 4: Kill-switch sanity**

Build with `RAMADAN_GIFT_ENABLED=false` in `env.json`. Confirm the card never renders even with `debugGiftClock` inside a window.

- [ ] **Step 5: No commit**

---

## NOT in scope

- **Push notifications announcing the gift** ("Sakina is gifting you premium for Ramadan!") — defer to Phase 2 once notifications infra is proven.
- **Localized greetings** ("Ramadan Mubarak / Eid Mubarak") in non-English — defer with all other i18n work.
- **Year-over-year occasion data seeding** — for v1 seed 2027 only; revisit annually or build a Hijri calendar service.
- **Custom occasion gifting** (birthday, account anniversary) — feature creep.
- **Lifetime gift on first install** ("Welcome to Sakina, 7 days on us") — separate plan if desired.
- **Per-region moonsighting variance** — single canonical date set for v1; per-region observation is a Phase 2 concern.
- **24h countdown timers / 50% discount mechanics** — explicitly out of scope. The brand stance is no urgency. The original winback-discount mechanic this plan replaces is also out of scope and should not be revived.

---

## GSTACK REVIEW REPORT

> **Plan rewritten 2026-05-14** from "Win-back Discount" to "Ramadan / Eid Gift" per CEO review's 10x recommendation. Prior reviews are NOT carried over; this is effectively a new plan.

| Review        | Trigger              | Why                       | Runs | Status | Findings |
| ------------- | -------------------- | ------------------------- | ---- | ------ | -------- |
| CEO Review    | `/plan-ceo-review`   | Scope & strategy          | 0    | —      | —        |
| Codex Review  | `/codex review`      | Independent 2nd opinion   | 0    | —      | —        |
| Eng Review    | `/plan-eng-review`   | Architecture & tests      | 0    | —      | —        |
| Design Review | `/plan-design-review`| UI/UX gaps                | 0    | —      | —        |
| DX Review     | `/plan-devex-review` | Developer experience      | 0    | —      | —        |

**UNRESOLVED:** 0
**VERDICT:** DRAFT — awaiting reviews

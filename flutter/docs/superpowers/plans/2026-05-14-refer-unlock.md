# Refer-to-Unlock Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When a user dismisses the onboarding paywall the FIRST time, show a full-screen "Send a dua to 3 friends — you unlock 30 days + a Gold card. They each get 7 days free." page (not a PageView page — a route presented imperatively). Generate the user an 8-char referral code stored on `user_profiles`, deep link `sakina://r/<code>` (custom scheme — see Architecture), share via `share_plus`. When 3 of their invitees complete onboarding + first muhasabah, the referrer's `referral_premium_until = now() + 30d` and a `gold_referral_reward` card is granted via the existing economy RPC. The REFEREE also gets `referral_premium_until = now() + 7d` at the moment `apply_referral` succeeds — mutual reward, not asymmetric. `PurchaseService.isPremium()` is extended to OR over this server-side referral premium window.

**Pre-launch context (load-bearing):** Sakina is pre-launch with zero users. Refer-unlock is the PRIMARY growth mechanic — paid acquisition budget is $0, the wedge is high-trust word-of-mouth from Muslim friends/family. There is no cohort to confound, no paywall data to wait on, no cannibalization to measure against a baseline. v1 IS the baseline.

**Architecture:** Premium becomes a two-source value:
- RevenueCat entitlement (`premium` key) — the paid path, source of truth for billing.
- `user_profiles.referral_premium_until > now()` — the referred path, granted via SECURITY DEFINER RPC, never converts to RC.

This split is intentional. Granting a real RevenueCat entitlement (via their promotional entitlements API) would create a billable record at next sync and complicate Apple/Play compliance. By keeping the referral grant Supabase-only, we stay clean — the reward is non-IAP content delivery (premium feature access + a card), which is explicitly allowed under Apple Guideline 3.1.1.

**Mutual reward (spiritual etiquette).** Referrer gets 30 days + Gold card on the 3rd confirmed referee. Referee gets 7 days at the moment they apply a valid code (before they even onboard). Both writes go through the same `referral_premium_until` column, just different windows. The referee grant is intentionally smaller (7d vs 30d) and intentionally NOT conditional on the referrer having "earned" it — the gift is the gift, not a means to the referrer's benefit. This inverts toward Islamic giving etiquette where the act of giving is its own reward.

**Share verb is "send a dua to a friend" — the spiritual moat.** Generic Dropbox-style "invite 3 friends, get a free month" copy is commodity. It also clashes with Sakina's brand (Hallow/Glorify/Calm spectrum: no urgency, no FOMO, no manipulation). The reframe is that sending the link IS an act of worship — you're making dua for your friend, the app is just the vessel. Share intent text:

> "I made a dua for you. Sakina helped me reflect on Allah's Names — open this to join me: sakina://r/<code>"

The Refer Unlock screen uses "Send a dua to 3 friends" as the primary verb, NOT "invite". This is the moat that competitors (Christian devotional apps, generic referral SaaS) cannot copy without sounding hollow.

**Hot-path caching.** `PurchaseService.isPremium()` is called from at least 8 call sites: `reflect_provider.dart` (×2), `duas_provider.dart` (×2), `muhasabah_screen.dart`, `gating_service.dart` (×2), `daily_rewards_provider.dart`, `premium_grants_service.dart`, `lapsed_trial_service.dart`. Today this is a fast local RC method-channel call. Adding a raw Supabase HTTP call to every invocation would balloon network usage and add per-call latency to the entire premium gate. We cache `referral_premium_until` in user-scoped SharedPreferences (`referral_premium_until:<uid>`, following the `auth_service.dart:14-28` `:<uid>` scoping convention) and refresh that cache only at three deterministic moments:

1. App foreground + authenticated session (`AppSessionNotifier._handleAuthenticatedChange` is the natural hook).
2. Right after `completeOnboarding()` (the referee's confirmation may have flipped the referrer's window — but more importantly this is when the referee gets a NEW window if they themselves were referred and previously crossed the threshold via some other path; mostly defensive).
3. Right after `confirm_referral_if_pending` and `apply_referral` RPC calls return (in case the response indicates we crossed the threshold).

`_isReferralPremium()` reads from SharedPreferences only — never hits Supabase. Result: zero additional Supabase traffic on the premium hot path.

**Deep linking: custom scheme ONLY for v1.** `sakina://r/<code>` is the primary and only deep-link path in v1. We do NOT own the `sakina.app` domain — that is a hard fact, not a TODO. Without domain ownership we cannot serve AASA, cannot ship the `applinks:` entitlement, cannot get Apple/Google to autoverify. Universal Links and Android App Links are therefore explicitly out of scope for v1 (see Phase 2 at the bottom of this plan).

The `app_links` package is still the right library — it handles BOTH universal links and custom schemes; in v1 we only wire the custom-scheme path. The share intent emits `sakina://r/<code>` directly (no `https://` URL is constructed).

**v1 UX trade-off (accepted).** If a friend receives the share message and does NOT have Sakina installed, tapping `sakina://r/<code>` does nothing on their device. The link is "dead" for non-installed friends. That is acceptable for v1: our pre-launch target audience is Muslim friends/family with high install intent (the trust signal is the personal dua, not the link); friends who are curious enough will search "Sakina" on the App Store and install manually. Install-time attribution for those manual installs is gone in v1 — Phase 2 (post-domain-acquisition) restores it via universal links.

**Tech Stack:** Flutter 3.41.6, `app_links: ^6.x`, `share_plus: ^10.x`, Supabase Postgres + SECURITY DEFINER RPCs + RLS, `purchases_flutter` (read-only for the premium gate), existing economy + card services.

---

## Background — why this matters

Per the 2026-05-13 research: Dropbox's referral program ("Get more space") drove their 3900% in 15 months. Tiered referral rewards (1 = $X, 3 = free month, 10 = bundle) is the canonical pattern. Subscription apps that pair a referral fallback with the paywall convert price-sensitive users who would otherwise abandon at the price screen — capturing a population the paid funnel was already losing. For Sakina specifically, word-of-mouth from Muslim friends/family is the highest-trust acquisition channel, dwarfing paid ads on retention.

**Cannibalization is not a v1 concern.** Pre-launch with zero users means there is no paying cohort to cannibalize from. Forward-instrument the events anyway (see Task 5) so the funnel becomes analyzable as users arrive — but do NOT gate this plan on paywall-rebuild data that does not exist. v1 is the baseline. Future plans (Phase 2+) can layer cannibalization-measurement dashboards on top of the events emitted here.

Mechanism caps that limit downside even without a baseline: (a) refer-unlock only shown AFTER paywall dismiss, never as the primary offer; (b) referrer reward is 30 days, not lifetime — at day 31 they hit the paywall again, by which point they've used the app and are more conversion-ready; (c) referee reward is 7 days — short enough that a serious user will renew through the paid path.

---

## File Structure

**Modify:**
- `pubspec.yaml` — add `app_links: ^6.4.0`. (`share_plus: ^10.1.4` is ALREADY present at line 53 — do not re-add.)
- `lib/services/purchase_service.dart` — `isPremium()` becomes the OR of RC entitlement and a SharedPreferences-cached server-side referral window.
- `lib/services/auth_service.dart` — on signup, call the new `ensure_referral_code` RPC to populate the user's code; on signup, consume any pending referral code from SharedPreferences and seed the referral-premium cache.
- `lib/features/onboarding/screens/save_progress_screen.dart` — hook `applyPendingReferralIfAny` INSIDE `_signInWithApple` / `_signInWithGoogle` / email signup AFTER the AuthResponse resolves. The screen-level `onSocialAuthComplete` callback is just `_skipToEncouragement` — too late.
- `lib/core/app_session.dart` — on cold launch, capture inbound `app_links` custom-scheme deep link, persist as `pending_referral` if it matches `sakina://r/<code>`. Also refresh the referral-premium cache on every authenticated foreground.
- `lib/features/onboarding/providers/onboarding_provider.dart` — on `completeOnboarding()`, call `confirm_referral_if_pending` RPC, then refresh the referral-premium cache.
- `ios/Runner/Info.plist` — register the `sakina` URL scheme under `CFBundleURLTypes` (custom-scheme handling only — no `applinks:` entitlement in v1).
- `android/app/src/main/AndroidManifest.xml` — add intent filter for `sakina://r/` custom scheme only (no `https://sakina.app/r/` data filter in v1).
- `lib/services/analytics_events.dart` — add referral-related events.
- `CLAUDE.md` — document referral as a premium grant path in the "Economy & Monetization" section.

**Create:**
- `supabase/migrations/20260514000000_referrals.sql` — schema (incl. `referral_grants` ledger), RPCs (`ensure_referral_code`, `apply_referral`, `confirm_referral_if_pending`), RLS, AND extension of the `guard_user_profiles_freemium_fields` trigger from `20260510010000_lock_freemium_gating_fields.sql` to cover `referral_premium_until`.
- `supabase/tests/referrals_test.sql` — pgtap tests covering: self-referral rejection, duplicate-referee rejection, chain-referral rejection (referee already a referrer), 3-confirmed grant, re-grant after window expires + 3 NEW confirms, RLS lockdown on `referral_premium_until`.
- `lib/features/paywall/screens/refer_unlock_screen.dart` — the post-dismiss route.
- `lib/services/referral_service.dart` — thin client wrapper around the SQL RPCs + share intent + referral-premium cache refresh.
- `test/services/referral_service_test.dart`.
- `test/services/purchase_service_referral_premium_test.dart` — unit-tests `DateTime.parse(...).isAfter(DateTime.now().toUtc())` against the exact `timestamptz` ISO shape Supabase emits (with offset).
- `test/features/paywall/refer_unlock_screen_test.dart`.

**Do NOT modify:**
- RevenueCat dashboard. The referral path never grants RC entitlement — only Supabase-side premium.
- Existing economy tables / `sync_all_user_data` RPC. The referral grant uses its own RPC; sync continues to read from `user_profiles` as today.

---

## Task 0: BLOCKING prerequisites — schema reconnaissance + custom-scheme smoke gate

This task BLOCKS Task 1. If step 1 below fails, halt the plan and resolve before continuing.

- [ ] **Step 1: Custom-scheme TestFlight gate (deferred to Task 6 end-to-end run)**

We do NOT own `sakina.app`. Universal Links / App Links are explicitly OUT OF
SCOPE for v1 (see Architecture and Phase 2). The only deep-link path is the
custom scheme `sakina://r/<code>`. No DNS, AASA, or assetlinks.json work is
needed in v1.

The verification this step gates is the v1 equivalent of "the link actually
works": on a fresh install via TestFlight (iOS) and an internal-track APK
(Android), tapping `sakina://r/TESTCODE` from Notes/iMessage/Slack must launch
Sakina and persist `TESTCODE` to `pending_referral` prefs. This is validated
end-to-end in Task 6 Step 2; this Task 0 step exists to surface the gate
early so the agent knows custom-scheme registration in Info.plist /
AndroidManifest is load-bearing and must be tested on real devices, not just
the simulator.

- [ ] **Step 2: Verify `grant_card` does NOT exist (it doesn't) + lock in the card-insert shape**

Pre-verified for the plan author: `grep -r "grant_card" supabase/migrations lib`
returns zero hits. Card grants today are direct INSERTs to
`public.user_card_collection`. The schema (`supabase/migrations/20260407000000_initial_schema.sql:217-228`):

```sql
create table public.user_card_collection (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name_id int not null,           -- catalog FK; NOT a slug
  tier public.card_tier not null default 'bronze',  -- bronze | silver | gold | emerald
  discovered_at timestamptz not null default now(),
  last_engaged_at timestamptz not null default now(),
  unique (user_id, name_id)
);
```

There is NO `slug` column on cards. The referral reward must therefore pick a
SPECIFIC `name_id` to grant at `tier = 'gold'`. Use the canonical "first Name"
catalog id used by `seedStarterCard` in `auth_service.dart` IF the user doesn't
already own that card at gold tier; otherwise grant Ar-Rahman (`name_id = 1`)
at gold. The Task 1 migration writes this INSERT directly — no `grant_card` RPC
is introduced.

- [ ] **Step 3: Confirm `share_plus` already present**

`pubspec.yaml:53` already has `share_plus: ^10.1.4`. Task 3 must NOT re-add it.

---

## Task 1: Supabase schema + RPCs + tests + RLS lockdown extension

**Files:**
- Create: `supabase/migrations/20260514000000_referrals.sql`
- Create: `supabase/tests/referrals_test.sql`

- [ ] **Step 1: Write the migration**

```sql
-- 20260514000000_referrals.sql
alter table public.user_profiles
  add column if not exists referral_code text unique,
  add column if not exists referral_premium_until timestamptz;

create table if not exists public.referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references auth.users(id) on delete cascade,
  referee_id  uuid not null references auth.users(id) on delete cascade,
  status text not null check (status in ('pending','confirmed','rejected')),
  created_at timestamptz not null default now(),
  confirmed_at timestamptz,
  unique (referee_id) -- a user can only be referred ONCE in their lifetime
);

create index if not exists referrals_referrer_status_idx
  on public.referrals(referrer_id, status);

alter table public.referrals enable row level security;

-- Referrer can SELECT their own rows (to show "1 of 3 confirmed" counter).
create policy referrals_select_referrer on public.referrals
  for select using (auth.uid() = referrer_id);

-- All writes go through SECURITY DEFINER RPCs below — no direct insert/update.

-- Ledger of GRANTS (distinct from referrals). One row per 30d window awarded.
-- This is the source of truth for "have they been rewarded for THIS cohort of
-- 3 referees?". Without a ledger, the threshold check is "count(confirmed) >=
-- 3" which is one-shot: after the first grant, the count is permanently >= 3
-- and a re-grant logic that keys off referral_premium_until going stale would
-- need to know "which 3 referees does this NEW grant correspond to". The
-- ledger lets us count "confirmed referrals created AFTER the most recent
-- grant_at", giving us a clean cohort boundary.
create table if not exists public.referral_grants (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references auth.users(id) on delete cascade,
  granted_at timestamptz not null default now(),
  expires_at timestamptz not null,
  card_name_id int not null,
  card_tier public.card_tier not null
);
create index if not exists referral_grants_referrer_idx
  on public.referral_grants(referrer_id, granted_at desc);
alter table public.referral_grants enable row level security;
create policy referral_grants_select_owner on public.referral_grants
  for select using (auth.uid() = referrer_id);

-- ---------------------------------------------------------------------------
-- ensure_referral_code(p_user) — server-side code generation
--
-- Why server-side: client-side generation would let a malicious client write
-- arbitrary referral_code values (e.g. squat a high-value short code, or
-- collide deliberately with someone else's). The unique constraint catches
-- the latter but not the former. SECURITY DEFINER + RLS-locked column means
-- only this RPC can populate referral_code; the freemium-gating guard
-- trigger (extended below) blocks direct UPDATEs.
--
-- Alphabet excludes confusables I/O/0/1 — 8 chars from a 32-char alphabet =
-- ~10^12 codes, collision-safe for our growth horizon.
-- ---------------------------------------------------------------------------
create or replace function public.ensure_referral_code(p_user uuid)
returns text
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_existing text;
  v_alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- no I/O/0/1
  v_code text;
  v_attempt int := 0;
begin
  select referral_code into v_existing from public.user_profiles where id = p_user;
  if v_existing is not null then
    return v_existing;
  end if;

  while v_attempt < 5 loop
    v_code := '';
    for i in 1..8 loop
      v_code := v_code || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
    end loop;

    begin
      update public.user_profiles
         set referral_code = v_code
       where id = p_user
         and referral_code is null;
      if found then
        return v_code;
      end if;
      -- Row exists but already has a code (race) — read and return.
      select referral_code into v_existing from public.user_profiles where id = p_user;
      if v_existing is not null then
        return v_existing;
      end if;
    exception when unique_violation then
      -- Collision with another user's code; retry.
      v_attempt := v_attempt + 1;
      continue;
    end;
    v_attempt := v_attempt + 1;
  end loop;

  raise exception 'failed_to_generate_referral_code_after_5_attempts';
end $$;

-- ---------------------------------------------------------------------------
-- apply_referral(p_code, p_referee)
--
-- Rejects:
--   * invalid_code   — no referrer matches.
--   * self_referral  — referrer == referee.
--   * chain_referral — the referee is themselves a referrer (sybil hardening:
--                      a chain referrer ring needs N+1 distinct Apple IDs
--                      instead of N — raises the cost; not a perfect defense
--                      against Apple Private Relay-based ring inflation).
-- Idempotent: re-applying the same code is a no-op (unique constraint).
--
-- MUTUAL REWARD: on a successful insert (not a no-op), grant the REFEREE a
-- 7-day premium window via referral_premium_until. The grant is intentionally
-- unconditional on the referrer side — the gift is the gift. Skipped on
-- conflict-no-op so re-applying the same code doesn't keep extending the
-- referee's window.
-- ---------------------------------------------------------------------------
create or replace function public.apply_referral(p_code text, p_referee uuid)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_referrer uuid;
  v_inserted boolean := false;
  v_referee_until timestamptz;
begin
  select id into v_referrer from public.user_profiles where referral_code = p_code;
  if v_referrer is null then
    return jsonb_build_object('ok', false, 'reason', 'invalid_code');
  end if;
  if v_referrer = p_referee then
    return jsonb_build_object('ok', false, 'reason', 'self_referral');
  end if;
  -- Chain-referral guard: a user who has themselves referred someone cannot
  -- now be the referee of another user.
  if exists (select 1 from public.referrals where referrer_id = p_referee) then
    return jsonb_build_object('ok', false, 'reason', 'chain_referral');
  end if;

  with ins as (
    insert into public.referrals(referrer_id, referee_id, status)
      values (v_referrer, p_referee, 'pending')
      on conflict (referee_id) do nothing
      returning 1
  )
  select exists(select 1 from ins) into v_inserted;

  if v_inserted then
    -- Grant the referee 7 days of premium. The freemium-gating trigger
    -- (extended below) bypasses for service_role/postgres, so this
    -- SECURITY DEFINER RPC writes through cleanly.
    v_referee_until := now() + interval '7 days';
    update public.user_profiles
       set referral_premium_until = v_referee_until
     where id = p_referee
       and (referral_premium_until is null or referral_premium_until < v_referee_until);
    return jsonb_build_object(
      'ok', true,
      'referee_premium_until', v_referee_until,
      'granted_referee_7d', true
    );
  end if;

  -- Idempotent re-application (already-referred referee): no new grant.
  return jsonb_build_object('ok', true, 'granted_referee_7d', false);
end $$;

-- ---------------------------------------------------------------------------
-- confirm_referral_if_pending(p_referee)
--
-- Threshold logic rewrite: we count "confirmed referrals created AFTER the
-- most recent grant for this referrer". This lets a referrer get a SECOND
-- 30-day window after the first expires, provided they bring 3 MORE
-- referees in.
--
-- Re-grant condition: referral_premium_until is NULL or in the past.
--
-- Card grant: INSERT directly into user_card_collection (there is no
-- grant_card RPC — verified in Task 0). Use name_id = 1 (Ar-Rahman) at gold
-- tier; ON CONFLICT do nothing so a re-grant doesn't error if the user
-- already owns that card. The referral_grants ledger captures the grant
-- regardless of whether the card upgrade was a no-op.
-- ---------------------------------------------------------------------------
create or replace function public.confirm_referral_if_pending(p_referee uuid)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_referrer uuid;
  v_last_grant_at timestamptz;
  v_new_confirmed_count int;
  v_existing_until timestamptz;
  v_new_until timestamptz;
  v_card_name_id constant int := 1; -- Ar-Rahman
  v_card_tier constant public.card_tier := 'gold';
begin
  update public.referrals
     set status = 'confirmed', confirmed_at = now()
   where referee_id = p_referee and status = 'pending'
   returning referrer_id into v_referrer;

  if v_referrer is null then
    return jsonb_build_object('ok', true, 'confirmed', false);
  end if;

  -- "Confirmed since last grant" — the cohort that hasn't been rewarded yet.
  select max(granted_at) into v_last_grant_at
    from public.referral_grants
   where referrer_id = v_referrer;

  select count(*) into v_new_confirmed_count
    from public.referrals
   where referrer_id = v_referrer
     and status = 'confirmed'
     and (v_last_grant_at is null or confirmed_at > v_last_grant_at);

  if v_new_confirmed_count < 3 then
    return jsonb_build_object(
      'ok', true, 'confirmed', true,
      'new_confirmed_count', v_new_confirmed_count,
      'granted', false
    );
  end if;

  -- Re-grant condition: window is NULL or has expired. The freemium-gating
  -- trigger (extended below) allows server_role/postgres writes through.
  select referral_premium_until into v_existing_until
    from public.user_profiles where id = v_referrer;

  if v_existing_until is not null and v_existing_until > now() then
    -- Already has an active window — don't stack/extend. Future plan: tiered.
    return jsonb_build_object(
      'ok', true, 'confirmed', true,
      'new_confirmed_count', v_new_confirmed_count,
      'granted', false, 'reason', 'window_still_active'
    );
  end if;

  v_new_until := now() + interval '30 days';

  update public.user_profiles
     set referral_premium_until = v_new_until
   where id = v_referrer;

  insert into public.referral_grants(referrer_id, expires_at, card_name_id, card_tier)
    values (v_referrer, v_new_until, v_card_name_id, v_card_tier);

  -- Card grant — direct insert (no grant_card RPC exists).
  insert into public.user_card_collection(user_id, name_id, tier)
    values (v_referrer, v_card_name_id, v_card_tier)
    on conflict (user_id, name_id) do update
      set tier = case
        -- Upgrade tier if the user already owns this card at a lower tier.
        -- card_tier enum order: bronze < silver < gold < emerald.
        when public.user_card_collection.tier in ('bronze','silver') then 'gold'::public.card_tier
        else public.user_card_collection.tier
      end,
      last_engaged_at = now();

  return jsonb_build_object(
    'ok', true, 'confirmed', true,
    'new_confirmed_count', v_new_confirmed_count,
    'granted', true,
    'referral_premium_until', v_new_until
  );
end $$;

-- ---------------------------------------------------------------------------
-- RLS lockdown extension — extend the freemium-fields guard trigger from
-- 20260510010000_lock_freemium_gating_fields.sql to also block client
-- UPDATEs to referral_premium_until and referral_code.
--
-- We rewrite the existing function (CREATE OR REPLACE) so the trigger
-- definition doesn't need to change — only the body's checks grow.
-- ---------------------------------------------------------------------------
create or replace function public.guard_user_profiles_freemium_fields()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if current_user in ('service_role', 'postgres', 'supabase_admin') then
    return new;
  end if;

  -- Existing checks (preserved verbatim from 20260510010000):
  if new.warmup_reflect_remaining > old.warmup_reflect_remaining then
    raise exception 'cannot reset/refill freemium gating field: warmup_reflect_remaining (% -> %)',
      old.warmup_reflect_remaining, new.warmup_reflect_remaining using errcode = 'check_violation';
  end if;
  if new.warmup_built_dua_remaining > old.warmup_built_dua_remaining then
    raise exception 'cannot reset/refill freemium gating field: warmup_built_dua_remaining (% -> %)',
      old.warmup_built_dua_remaining, new.warmup_built_dua_remaining using errcode = 'check_violation';
  end if;
  if new.warmup_discover_name_remaining > old.warmup_discover_name_remaining then
    raise exception 'cannot reset/refill freemium gating field: warmup_discover_name_remaining (% -> %)',
      old.warmup_discover_name_remaining, new.warmup_discover_name_remaining using errcode = 'check_violation';
  end if;
  if old.had_trial = true and new.had_trial = false then
    raise exception 'cannot reset/refill freemium gating field: had_trial (true -> false is forbidden)'
      using errcode = 'check_violation';
  end if;

  -- NEW checks for referral fields:
  -- referral_code is write-once via ensure_referral_code() RPC.
  if old.referral_code is not null and new.referral_code is distinct from old.referral_code then
    raise exception 'cannot modify referral_code after initial assignment (% -> %)',
      old.referral_code, new.referral_code using errcode = 'check_violation';
  end if;
  -- referral_premium_until is write-only via confirm_referral_if_pending() RPC.
  if new.referral_premium_until is distinct from old.referral_premium_until then
    raise exception 'cannot modify referral_premium_until directly; must go through SECURITY DEFINER RPC'
      using errcode = 'check_violation';
  end if;

  return new;
end
$$;
-- Trigger from 20260510010000 already exists and references this function;
-- the CREATE OR REPLACE above rebinds it automatically.

-- Revoke anon execute per CLAUDE.md migration 20260509000000 pattern.
revoke execute on function public.ensure_referral_code(uuid) from anon;
revoke execute on function public.apply_referral(text, uuid) from anon;
revoke execute on function public.confirm_referral_if_pending(uuid) from anon;
```

- [ ] **Step 2: Apply the migration via the Supabase MCP**

Use `mcp__supabase__apply_migration` with the SQL above. Then run `mcp__supabase__get_advisors` and resolve any security/performance findings before proceeding.

- [ ] **Step 3: Write pgtap tests** — `supabase/tests/referrals_test.sql`

Follow the pattern in `supabase/tests/backend_rls_test.sql` and
`supabase/tests/freemium_gating_lockdown_test.sql`. Cover:

- `ensure_referral_code` populates `referral_code` and returns it; second call returns the same code.
- `apply_referral` with invalid code → `{ok:false, reason:'invalid_code'}`.
- `apply_referral` with self-referral → `{ok:false, reason:'self_referral'}`.
- `apply_referral` where the referee has themselves referred someone → `{ok:false, reason:'chain_referral'}`.
- `apply_referral` with valid code, new referee → inserts pending row AND sets the REFEREE's `referral_premium_until` ~7d out (mutual reward fires).
- `apply_referral` with valid code, already-referred referee → no-op (idempotent); referee's `referral_premium_until` is NOT re-extended on the second call.
- `apply_referral` 7-day referee grant never shrinks an existing longer window (e.g. if a referee was previously granted 30d as a referrer, applying a code does NOT shrink them to 7d).
- `confirm_referral_if_pending` flips pending → confirmed.
- After 3 confirmations, referrer's `referral_premium_until` is set ~30d out AND a row exists in `referral_grants` AND a `gold` `user_card_collection` row exists for `name_id = 1`.
- A 4th confirmation while the window is still active does NOT extend the window (returns `granted: false, reason: 'window_still_active'`).
- After the 30d window expires + 3 NEW confirmed referrals (post the first `granted_at`), a SECOND grant occurs: `referral_premium_until` extends, a new `referral_grants` row appears, card stays at gold.
- RLS lockdown: an `authenticated` role session attempting `UPDATE user_profiles SET referral_premium_until = ...` raises `check_violation`.
- RLS lockdown: same role attempting `UPDATE user_profiles SET referral_code = 'HACK1234'` (where existing code is non-null) raises `check_violation`.
- RLS lockdown: service_role bypass works (the `confirm_referral_if_pending` RPC writes through cleanly).

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260514000000_referrals.sql supabase/tests/referrals_test.sql
git commit -m "feat(referrals): schema + RPCs for mutual refer-unlock (30d referrer / 7d referee)

user_profiles.referral_code + referral_premium_until columns. New
referrals + referral_grants tables. ensure_referral_code generates
server-side codes from a 32-char no-confusables alphabet (no I/O/0/1).
apply_referral rejects self + chain referrals AND grants the referee 7
days of premium on successful insert (mutual reward — the gift is the
gift, not a means to the referrer's benefit). confirm_referral_if_pending
counts confirmed-since-last-grant so a returning user gets a SECOND
30d window after bringing in 3 more friends. Card grant inserts
directly into user_card_collection (no grant_card RPC exists).
Extends the freemium-gating trigger to lock referral_code (write-once)
and referral_premium_until (RPC-only). Pgtap covers all of the above."
```

---

## Task 2: Extend `PurchaseService.isPremium()` to OR over the referral window

**Files:**
- Modify: `lib/services/purchase_service.dart`
- Modify: `test/services/purchase_service_test.dart`

**Hot-path constraint:** `isPremium()` is invoked from 8+ call sites (see Architecture section). It MUST stay synchronous-style fast — no per-call Supabase round-trip. The referral window is read from a SharedPreferences cache that is refreshed at deterministic moments (auth foreground, post-RPC).

- [ ] **Step 1: Write the failing tests**

In `purchase_service_test.dart` (and the new `purchase_service_referral_premium_test.dart`), add cases:

1. When RC reports no entitlement AND the SharedPreferences cache (`referral_premium_until:<uid>`) holds an ISO timestamp in the future → `isPremium()` returns true.
2. When that ISO is in the past → returns false.
3. When the cache is missing entirely → returns false (does NOT hit Supabase).
4. When `currentUser` is null/empty uid → `_isReferralPremium()` short-circuits and returns false WITHOUT any Supabase or prefs read.
5. **`DateTime.parse` ISO compatibility:** unit-test the exact shapes Supabase emits for `timestamptz`: `"2026-06-13T12:34:56.789+00:00"`, `"2026-06-13T12:34:56+00"`, and the `Z` short form. All must parse and compare correctly against `DateTime.now().toUtc()`.

- [ ] **Step 2: Extend `isPremium()` to consult the local cache**

```dart
import 'package:sakina/services/supabase_sync_service.dart';

@visibleForTesting
static const String referralPremiumUntilPrefsBaseKey = 'referral_premium_until';

Future<bool> isPremium() async {
  if (_initialized) {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      if (customerInfo.entitlements.active.containsKey('premium')) {
        return true;
      }
    } catch (_) {
      // Fall through to referral check.
    }
  }
  return _isReferralPremium();
}

/// Reads from the local cache only. The cache is populated by
/// [refreshReferralPremiumCache] at auth foreground, after signup, and after
/// referral RPCs return. Never hits Supabase from the hot path.
Future<bool> _isReferralPremium() async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null || uid.isEmpty) return false;
  final prefs = await SharedPreferences.getInstance();
  final scopedKey = supabaseSyncService.scopedKey(referralPremiumUntilPrefsBaseKey);
  final iso = prefs.getString(scopedKey);
  if (iso == null || iso.isEmpty) return false;
  try {
    return DateTime.parse(iso).isAfter(DateTime.now().toUtc());
  } catch (_) {
    return false;
  }
}

/// Fetches referral_premium_until from Supabase and updates the local cache.
/// Call at: app foreground (authenticated), after completeOnboarding(),
/// after apply_referral / confirm_referral_if_pending RPC returns.
Future<void> refreshReferralPremiumCache() async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null || uid.isEmpty) return;
  try {
    final row = await Supabase.instance.client
        .from('user_profiles')
        .select('referral_premium_until')
        .eq('id', uid)
        .maybeSingle();
    final iso = row?['referral_premium_until'] as String?;
    final prefs = await SharedPreferences.getInstance();
    final scopedKey = supabaseSyncService.scopedKey(referralPremiumUntilPrefsBaseKey);
    if (iso == null) {
      await prefs.remove(scopedKey);
    } else {
      await prefs.setString(scopedKey, iso);
    }
  } catch (_) {
    // Best-effort; stale cache is acceptable until next refresh moment.
  }
}
```

- [ ] **Step 3: Wire the refresh hooks**

- `lib/core/app_session.dart` `_handleAuthenticatedChange`: after `PurchaseService().setUserId(...)`, add `unawaited(PurchaseService().refreshReferralPremiumCache());` (best-effort, doesn't block hydration).
- `lib/services/referral_service.dart` `applyPendingReferralIfAny` and `confirmReferralIfPending`: after the RPC returns, call `refreshReferralPremiumCache`.
- `lib/features/onboarding/providers/onboarding_provider.dart` `completeOnboarding()`: after `confirmReferralIfPending`, call `refreshReferralPremiumCache`.

- [ ] **Step 4: Run tests — expect PASS, then commit**

```bash
git add lib/services/purchase_service.dart lib/core/app_session.dart test/services/purchase_service_test.dart test/services/purchase_service_referral_premium_test.dart
git commit -m "feat(premium): OR isPremium() over cached referral window

PurchaseService.isPremium() returns true if either RC reports the
premium entitlement OR a locally-cached referral_premium_until ISO
(SharedPreferences, user-scoped key) is in the future. Cache is
refreshed at auth foreground, after referral RPCs, and after
completeOnboarding — never on the isPremium() hot path (which is
called from 8+ providers). Keeps RC as billing source of truth;
referral grant lives only in Supabase + the local cache."
```

---

## Task 3: Add `app_links` + capture inbound custom-scheme deep links

**Files:**
- Modify: `pubspec.yaml`, `lib/core/app_session.dart`, `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`.

Universal links and Android App Links are explicitly OUT OF SCOPE for v1
(see Architecture). We do not own `sakina.app`. v1 ships custom-scheme
handling only.

- [ ] **Step 1: Add packages**

`pubspec.yaml` — add ONLY `app_links` (per Task 0 Step 3, `share_plus: ^10.1.4` is already at line 53):
```yaml
  app_links: ^6.4.0
```
Run `flutter pub get`.

- [ ] **Step 2: Register the iOS custom URL scheme in `Info.plist`**

Edit `ios/Runner/Info.plist`. Add (or merge into existing `CFBundleURLTypes` array):
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>com.sakina.app.referral</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>sakina</string>
    </array>
  </dict>
</array>
```

Do NOT add `com.apple.developer.associated-domains` / `applinks:sakina.app`
to `Runner.entitlements` in v1 — that entitlement requires AASA hosting at
a domain we do not own.

- [ ] **Step 3: Register the Android custom-scheme intent filter**

`android/app/src/main/AndroidManifest.xml` — in the main `<activity>`, add (alongside existing intent filters):
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="sakina" android:host="r" />
</intent-filter>
```

Do NOT add the `android:scheme="https" android:host="sakina.app"` data filter
in v1 — that requires `assetlinks.json` hosting at a domain we do not own.
Do NOT add `android:autoVerify="true"` (autoverify is only meaningful for
https App Links).

- [ ] **Step 4: Capture inbound links in `main.dart` BEFORE `runApp`**

The order is load-bearing: `applyPendingReferralIfAny` (Task 4) reads from
`pending_referral` SharedPrefs. If we don't AWAIT the initial-link capture
before runApp, the signup flow can read prefs before the app_links plugin
has handed us the cold-launch URI, and the pending code is lost. The
`getInitialLink()` future MUST be awaited; the `uriLinkStream` subscription
can be set up fire-and-forget AFTER runApp (or fire-and-forget here — but the
initial-link capture is the one that races).

```dart
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

// NOTE: not user-scoped — at this point we may have no authenticated user yet.
// The signup flow consumes the key and clears it.
const String pendingReferralPrefsKey = 'pending_referral';

Future<void> _captureInboundReferral() async {
  final appLinks = AppLinks();
  try {
    final initial = await appLinks.getInitialLink();
    if (initial != null) await _persistReferralFromUri(initial);
  } catch (_) {
    // First-launch on Android sometimes throws on getInitialLink — non-fatal.
  }
  // Warm-launch deep links — subscribe AFTER awaiting the initial-link.
  appLinks.uriLinkStream.listen(_persistReferralFromUri);
}

Future<void> _persistReferralFromUri(Uri uri) async {
  // v1: custom scheme only (sakina://r/<code>). Universal-link path
  // (https://sakina.app/r/<code>) is Phase 2.
  if (uri.scheme != 'sakina' || uri.host != 'r') return;
  if (uri.pathSegments.isEmpty) return;
  final code = uri.pathSegments[0];
  if (code.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(pendingReferralPrefsKey, code);
}
```

In `main.dart`, AWAIT the capture call before `runApp`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ... existing init (Supabase, RC, etc.) ...
  await _captureInboundReferral(); // <-- AWAIT, do not fire-and-forget
  runApp(const SakinaApp());
}
```

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/app_session.dart ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml
git commit -m "feat(referrals): capture inbound sakina://r/<code> custom-scheme links

iOS Info.plist CFBundleURLSchemes + Android intent-filter for the
sakina:// custom scheme. Universal links / App Links are deferred to
Phase 2 (requires sakina.app domain ownership + AASA + assetlinks
hosting). Persists code to SharedPreferences as pending_referral;
consumed at signup."
```

---

## Task 4: Consume pending referral on signup + confirm on onboarding complete

**Files:**
- Modify: `lib/services/auth_service.dart`
- Modify: `lib/features/onboarding/screens/save_progress_screen.dart` — hook social auth at the RIGHT place (see Step 2).
- Modify: `lib/features/onboarding/providers/onboarding_provider.dart`
- Modify: `lib/core/app_session.dart` — defensive cold-launch reconciliation.
- Create: `lib/services/referral_service.dart`

- [ ] **Step 1: Create the service wrapper**

```dart
// lib/services/referral_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sakina/services/purchase_service.dart';

class ReferralService {
  ReferralService(this._supabase);
  final SupabaseClient _supabase;

  Future<void> applyPendingReferralIfAny(String userId) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('pending_referral');
    if (code == null || code.isEmpty) return;
    try {
      await _supabase.rpc('apply_referral', params: {
        'p_code': code,
        'p_referee': userId,
      });
      // Only remove prefs AFTER RPC returns (kill-resilient).
      await prefs.remove('pending_referral');
      await PurchaseService().refreshReferralPremiumCache();
    } catch (e) {
      // Leave prefs in place — defensive cold-launch path (Step 4) retries.
      rethrow;
    }
  }

  Future<void> ensureReferralCode(String userId) async {
    if (userId.isEmpty) return;
    await _supabase.rpc('ensure_referral_code', params: {'p_user': userId});
  }

  Future<String?> getMyReferralCode(String userId) async {
    final row = await _supabase
        .from('user_profiles')
        .select('referral_code')
        .eq('id', userId)
        .maybeSingle();
    return row?['referral_code'] as String?;
  }

  Future<void> confirmReferralIfPending(String userId) async {
    if (userId.isEmpty) return;
    await _supabase.rpc('confirm_referral_if_pending', params: {
      'p_referee': userId,
    });
    await PurchaseService().refreshReferralPremiumCache();
  }

  Future<int> confirmedCount(String userId) async {
    if (userId.isEmpty) return 0;
    final rows = await _supabase
        .from('referrals')
        .select('id')
        .eq('referrer_id', userId)
        .eq('status', 'confirmed');
    return (rows as List).length;
  }
}
```

- [ ] **Step 2: Wire into the THREE signup paths**

The `onSocialAuthComplete` callback in `onboarding_screen.dart:251` is just `_skipToEncouragement` — it runs LONG after the actual `signInWithApple` / `signInWithGoogle` call resolves. We need to hook AS SOON AS the AuthResponse comes back, before `persistOnboardingToSupabase` (so the referral row is written under the correct authenticated session).

In `lib/features/onboarding/screens/save_progress_screen.dart`:

- `_signInWithApple`: after `await ref.read(authServiceProvider).signInWithApple();` resolves and `userId` is captured (currently around line 47), AND BEFORE `persistOnboardingToSupabase()`, add:
  ```dart
  await ref.read(referralServiceProvider).ensureReferralCode(userId);
  try {
    await ref.read(referralServiceProvider).applyPendingReferralIfAny(userId);
  } catch (e) {
    debugPrint('[SaveProgress] applyPendingReferral failed (non-fatal): $e');
  }
  ```
- `_signInWithGoogle`: same insertion at the analogous point (around line 80).
- Email signup path (`sign_up_password_screen.dart` — the screen that calls `signUpWithEmail`): same pattern after the `AuthResponse` and before `persistOnboardingToSupabase`.

Add `referralServiceProvider` to `lib/services/referral_service.dart`:
```dart
final referralServiceProvider = Provider<ReferralService>(
  (ref) => ReferralService(Supabase.instance.client),
);
```

- [ ] **Step 3: Confirm on onboarding complete**

In `onboarding_provider.dart`'s `completeOnboarding()`, after the final batch sync, add:

```dart
try {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid != null && uid.isNotEmpty) {
    await ref.read(referralServiceProvider).confirmReferralIfPending(uid);
  }
} catch (e, st) {
  debugPrint('Referral confirm failed (non-fatal): $e');
}
```

Wrap in try/catch — this must NEVER block onboarding completion.

- [ ] **Step 4: Defensive cold-launch reconciliation**

There's a kill-window between signup completing and `applyPendingReferralIfAny` being called (or RPC submitted): the user could force-quit. After relaunch the user is authenticated AND `pending_referral` is still in prefs, but no `referrals` row exists. Patch `AppSessionNotifier._handleAuthenticatedChange` to defensively call `applyPendingReferralIfAny` whenever an authenticated session loads and the prefs key is still present. The RPC is idempotent on the `(referee_id)` unique constraint — calling it twice is safe.

```dart
// In _handleAuthenticatedChange, after the existing identifyUser block:
try {
  final prefs = await SharedPreferences.getInstance();
  if ((prefs.getString('pending_referral') ?? '').isNotEmpty) {
    await ReferralService(Supabase.instance.client)
        .applyPendingReferralIfAny(sessionUserId);
  }
} catch (e) {
  debugPrint('app_session: defensive applyPendingReferral failed: $e');
}
```

- [ ] **Step 5: Tests + commit**

Write `test/services/referral_service_test.dart` covering:

- Prefs lifecycle: set → applyPendingReferralIfAny → RPC called → prefs cleared.
- RPC failure: prefs are NOT cleared (defensive cold-launch path can retry).
- Empty / null user id: no-op (no RPC call, no prefs read).
- Defensive cold-launch: prefs set + authenticated session triggers the RPC again (idempotent on server side).

```bash
git add lib/services/referral_service.dart lib/services/auth_service.dart lib/features/onboarding/screens/save_progress_screen.dart lib/features/onboarding/screens/sign_up_password_screen.dart lib/features/onboarding/providers/onboarding_provider.dart lib/core/app_session.dart test/services/referral_service_test.dart
git commit -m "feat(referrals): apply pending code on signup, confirm on onboarding finish

ReferralService.applyPendingReferralIfAny() drains pending_referral
prefs AFTER the apply_referral RPC returns (kill-resilient: if app
dies between RPC submit and response, prefs stay set and the next
authenticated session retries via the defensive cold-launch hook in
AppSession). Hooked at the THREE real signup points
(_signInWithApple, _signInWithGoogle, email-password), NOT the
screen-level onSocialAuthComplete callback. ensureReferralCode RPC
populates the server-side referral_code on signup.
confirmReferralIfPending fires at onboarding completion (try/catch —
non-fatal). When the referrer crosses 3 confirmed, the SQL RPC handles
the 30d window grant + gold card atomically; the client refreshes its
cache so isPremium() picks up the change."
```

---

## Task 5: Build `ReferUnlockScreen` + wire into post-paywall-dismiss flow

**Files:**
- Create: `lib/features/paywall/screens/refer_unlock_screen.dart`
- Create: `test/features/paywall/refer_unlock_screen_test.dart`
- Modify: `lib/features/onboarding/screens/paywall_screen.dart` (or wherever dismiss is handled) to route here on dismiss.

- [ ] **Step 1: Build the screen — spiritual-native copy, not Dropbox copy**

Two-card layout:
- Top card: "Start your 7-day free trial" → calls back to the paywall.
- Bottom card primary headline: **"Send a dua to 3 friends"** (NOT "Invite 3 friends"). Subhead: "You unlock 30 days + a Gold card. They each get 7 days free." On tap, fetches the user's code via `ReferralService.getMyReferralCode(userId)` (or `ensureReferralCode` if null), constructs the v1 share intent and calls `Share.share(...)` with the spiritual-native message body:

  ```dart
  final shareText =
      "I made a dua for you. Sakina helped me reflect on Allah's Names — "
      "open this to join me: sakina://r/$myCode";
  await Share.share(shareText);
  ```

  Do NOT use generic "Join me on Sakina" copy. Do NOT construct an `https://sakina.app/r/<code>` URL — we do not own the domain in v1 and the link would be dead. The custom scheme link is dead on non-installed devices in v1; that trade-off is accepted (see Architecture).

- Below: live "X of 3 friends joined" chip, polled from `ReferralService.confirmedCount()` on screen show.

Use `flutter_animate` for entry transitions matching the rest of the onboarding flow. NO urgency animations (no countdown timers, no "limited time" badges) — brand is Hallow/Glorify/Calm spectrum.

- [ ] **Step 2: Route on dismiss**

In `paywall_screen.dart`, find where dismiss is handled (the close button / swipe / "Maybe later" tap). Use a **user-scoped** SharedPreferences counter so it doesn't bleed across users on a shared device, following the `auth_service.dart:14-28` `:<uid>` convention. Read via `supabaseSyncService.scopedKey('paywall_dismiss_count')`. Increment; if count == 1, push `ReferUnlockScreen`; if count >= 2, push the WinbackScreen from the separate plan. If the user is somehow not authenticated at this point (shouldn't happen — paywall is post-signup — but defensively), fall back to the bare key + log a warning.

Capture `paywall_dwell_seconds` (time between paywall shown and dismiss) and pass it as a property on `refer_unlock_shown` — this is the dwell signal the CEO review wanted for forward instrumentation.

- [ ] **Step 3: Analytics — forward instrumentation**

The CEO review wanted cannibalization-vs-conversion signal events even though there's no baseline yet. Wire them now so that as v1 users arrive, the funnel becomes analyzable.

Add events to `lib/services/analytics_events.dart`:
- `refer_unlock_shown` — properties: `paywall_dwell_seconds` (int).
- `refer_unlock_share_tapped` — fired when user taps the share button.
- `refer_unlock_share_no_universal_links` — fired on every share in v1 since universal links are deferred. Allows future Phase 2 dashboards to compare install-funnel before/after universal link rollout.
- `refer_unlock_start_trial_tapped` — fired when user picks "Start trial" instead.
- `refer_unlock_back_to_paywall` — fired on swipe-back / explicit return to paywall.
- `referee_signed_up_with_referral` — fired client-side on `apply_referral` success (from `ReferralService.applyPendingReferralIfAny` after the RPC returns ok).
- `referrer_granted_30d_window` — fired client-side on `confirm_referral_if_pending` returning `granted: true`.
- `referee_granted_7d_window` — fired client-side on `apply_referral` returning `granted_referee_7d: true` (the mutual reward firing).

Hook the last three from `ReferralService` (Task 4) — pass the analytics service in via Riverpod and fire there, not from the UI layer.

- [ ] **Step 4: Tests + commit**

```bash
git add lib/features/paywall/screens/refer_unlock_screen.dart test/features/paywall/refer_unlock_screen_test.dart lib/features/onboarding/screens/paywall_screen.dart lib/services/analytics_events.dart lib/services/referral_service.dart
git commit -m "feat(referrals): ReferUnlockScreen — 'send a dua to 3 friends' framing

Two-card layout reframes 'pay vs walk away' as 'pay vs send a dua'.
Share intent is spiritual-native: 'I made a dua for you. Sakina
helped me reflect on Allah's Names — open this to join me: sakina://r/...'
Live 'X of 3 friends joined' counter via ReferralService.confirmedCount.
Forward-instruments cannibalization + dwell + mutual-grant events for
post-launch funnel analysis (no v1 baseline; this is the baseline)."
```

---

## Task 6: Verification

- [ ] **Step 1: Full test suite + analyze**

Run: `flutter test && flutter analyze`

- [ ] **Step 2: End-to-end manual test on real devices (TestFlight + Android internal track)**

Use TWO devices / accounts (cannot self-refer). The custom scheme MUST be tested on real devices, not the simulator — simulator handling of `sakina://` is unreliable and not representative of TestFlight.

1. User A finishes onboarding → opens ReferUnlockScreen via paywall dismiss → taps Share → confirm the share sheet shows the spiritual-native body ("I made a dua for you...sakina://r/<code>") and NOT a generic Dropbox-style message.
2. Send the message to User B via iMessage / WhatsApp / SMS.
3. **Pre-installed case:** User B has Sakina installed. Tap the `sakina://r/<code>` link from the message — Sakina opens, `pending_referral` is persisted. Walk User B through signup.
4. **Not-installed case (v1 known limitation):** confirm that tapping `sakina://r/<code>` on a device WITHOUT Sakina installed does nothing (no crash, no error toast). User installs from App Store search manually, onboards without the code — confirms the "dead link for non-installed friends" UX trade-off is real but not catastrophic.
5. After User B (with code applied) completes signup, run a Supabase query to confirm: (a) `referrals` row went `pending` → `confirmed` after onboarding, (b) User B's `referral_premium_until` is ~7 days out (mutual reward fired at apply_referral time).
6. Repeat for User C, then User D. After User D, confirm User A's `referral_premium_until` is set ~30d out and a Gold card was granted (visible in their collection).
7. Confirm `PurchaseService.isPremium()` returns true for User A AND User B/C/D even without a RevenueCat purchase.
8. Confirm Mixpanel shows `refer_unlock_shown` (with `paywall_dwell_seconds`), `refer_unlock_share_tapped`, `refer_unlock_share_no_universal_links`, `referee_signed_up_with_referral` (×3), `referee_granted_7d_window` (×3), and `referrer_granted_30d_window` (×1).

---

## NOT in scope (v1)

- **Lifetime premium for referrers.** 30 days only. Capping the window prevents abuse and ensures referred-users still hit a paywall eventually.
- **Cash incentives.** Apple Guideline forbids paying users in IAP credit for off-platform actions. Non-IAP rewards (premium feature time, cards) only.
- **Refer-to-extend** (more referrals = more days). Linear is simpler, ships first; tiered can be a follow-up after we measure cannibalization.
- **Re-engagement push to lapsed referrers** when their 30-day window expires. Separate future plan.
- **Replacing the paid trial with refer-unlock as the primary path.** Refer is ONLY shown post-dismiss, never first.
- **Universal Links / Android App Links.** Requires `sakina.app` domain ownership + AASA + assetlinks.json hosting. Deferred to Phase 2 (see below).
- **Sakina Care / Pay What You Can tier.** The CEO review surfaced a real equity concern — social-capital-as-currency disadvantages users without large Muslim community ties. Deferred until v1 ships and we have signal on whether this materializes in practice. Footnoting here rather than blocking v1.

## Phase 2 candidates (post-v1)

These are real, scoped follow-ups — not vague aspirations. Each has a defined trigger.

- **Universal Links + Android App Links.** Trigger: `sakina.app` domain acquired and a static-hosting target is available. Restores share-link previews in iMessage and install-time attribution for non-installed friends. Wires the `https://sakina.app/r/<code>` paths back into `_persistReferralFromUri`, adds the AASA file + `applinks:` entitlement + Android autoverify intent filter that this v1 plan explicitly omits.
- **Ramadan / Eid seasonal copy.** Trigger: month-of-Ramadan / week-of-Eid. Share intent body and ReferUnlockScreen primary copy variant: "Send a Ramadan gift to a friend" / "Send an Eid blessing".
- **Collect-Names-through-community variant.** Trigger: 30d post-launch retention data on the gold-card grant — if redemption/engagement is low, swap the reward from "Gold card on Ar-Rahman" to "deeper teaching content unlocked on one of the 99 Names per confirmed referee". Ties referrals directly into the Names collection loop instead of the parallel card-tier track.
- **Gender-aware copy** (akhī/ukhtī variant detection). Trigger: when a settings-level gender field or a confident `displayName` heuristic ships. v1 stays gender-neutral ("friend") to avoid mis-gendering.
- **Cannibalization measurement dashboard.** Trigger: ~1k paying users. Cross-references `refer_unlock_shown` cohort against trial-start / paid-conversion rates. The forward-instrumented events from Task 5 Step 3 are designed to feed this dashboard with no schema migration.
- **Sakina Care / PWYC tier.** Trigger: CEO/eng pair revisits equity concern post-launch. Could be a separate `subsidized_premium_until` column + a "request" flow with no shame — fully isolated from referral path.

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 1 | CLEARED (custom-scheme + mutual reward + dua framing) | primary growth mechanic for pre-launch; universal links deferred until domain owned; spiritual-native framing addresses brand moat; mutual reward fixes asymmetry; forward instrumentation in lieu of pre-launch cannibalization gating; equity concern footnoted as Phase 2. |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests | 1 | BLOCK → CLEAR-WITH-CHANGES (revised) | grant_card RPC absent (replaced with direct INSERT); referral_code generation moved to server RPC; isPremium hot path cached in scoped prefs; AASA/assetlinks promoted to Task 0; chain-referral + re-grant + ledger; OAuth hook moved into save_progress_screen; awaited getInitialLink; scoped paywall_dismiss_count; RLS lockdown extended to referral fields. |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience | 0 | — | — |

**UNRESOLVED:** 0.
**VERDICT:** CLEAR-WITH-CHANGES — CEO + eng reviewed; ready for Design / DX / Codex passes.

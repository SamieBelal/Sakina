-- Subscription cancellation feedback survey.
--
-- Spec: docs/superpowers/specs/2026-05-31-cancellation-feedback-design.md
--
-- One row per cancellation "episode", keyed on (user_id, expires_at). The
-- expiration date is the dedupe key (NOT canceled_at) because the survey can
-- fire from two paths that read the cancellation at different moments from
-- different sources:
--   * instant  — client RevenueCat EntitlementInfo right after Customer Center
--                closes (before the webhook may have written the server row)
--   * reactive — the user_subscriptions row written by the webhook
-- expires_at is identical in both (EntitlementInfo.expirationDate ==
-- user_subscriptions.expires_at) and stable for the whole non-renewing period,
-- so both paths land on the same row and a cancellation is surveyed once.
--
-- This is NOT an economy table; it is written directly by the client through
-- the service layer (the "never write directly" rule is economy-only).

create table if not exists public.cancellation_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  -- Dedupe key: the entitlement's current period end (the cancellation episode).
  expires_at timestamptz not null,
  -- When the cancellation was detected (data, not the key).
  canceled_at timestamptz,
  -- null when the user skipped/dismissed the survey.
  reason_code text,
  reason_text text,
  period_type text,
  product_id text,
  store text,
  platform text,
  app_version text,
  -- in_app_instant | in_app_reactive | push
  source text not null,
  -- submitted | dismissed
  status text not null,
  constraint uq_cancellation_feedback_user_episode unique (user_id, expires_at)
);

create index if not exists idx_cancellation_feedback_user
  on public.cancellation_feedback (user_id);

alter table public.cancellation_feedback enable row level security;

-- The client owns this table: it may insert, read, and update (the upsert on
-- the dedupe key needs both insert and update) only its own rows. No
-- service-role writes from the app.
drop policy if exists "Users can view own cancellation feedback"
  on public.cancellation_feedback;
create policy "Users can view own cancellation feedback"
  on public.cancellation_feedback
  for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own cancellation feedback"
  on public.cancellation_feedback;
create policy "Users can insert own cancellation feedback"
  on public.cancellation_feedback
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own cancellation feedback"
  on public.cancellation_feedback;
create policy "Users can update own cancellation feedback"
  on public.cancellation_feedback
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- The reactive detection path and the survey copy both need period_type
-- (trial vs paid). The RevenueCat CANCELLATION event carries it; the webhook
-- upsert is extended to persist it here.
alter table public.user_subscriptions
  add column if not exists period_type text;

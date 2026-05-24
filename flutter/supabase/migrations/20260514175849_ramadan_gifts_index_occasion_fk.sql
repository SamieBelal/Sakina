-- Index for the sakina_gifts occasion FK lookups.
-- Pulled from prod (version 20260514175849) alongside the parent ramadan_gifts
-- migration. See note in 20260514175835_ramadan_gifts.sql for why this lands
-- in PR #27.

create index if not exists sakina_gifts_occasion_id_idx
  on public.sakina_gifts (occasion_id);

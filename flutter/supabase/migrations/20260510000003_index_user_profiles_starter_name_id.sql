-- 2026-05-10: Add covering index on user_profiles.starter_name_id FK.
-- Resolves Supabase advisor lint 0001 (unindexed_foreign_keys).
--
-- The FK has ON DELETE SET NULL, so a delete on collectible_names triggers
-- a child-row scan of user_profiles. Without this index that's a seq scan.
-- collectible_names is a static catalog today, but indexing FK columns is
-- the canonical practice — costs nothing on writes (column is sparse) and
-- removes a future scaling foot-gun.

create index if not exists user_profiles_starter_name_id_idx
  on public.user_profiles (starter_name_id);

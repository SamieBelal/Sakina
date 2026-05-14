-- PR #12 (feat(duas): expand browse_duas 76 → 121) added 12 new categories to
-- assets/content/browse_duas.json but never added a migration. This adds the
-- enum values so the next migration can seed the rows that reference them.
-- Idempotent: ADD VALUE IF NOT EXISTS is a no-op when already present.
alter type public.dua_category add value if not exists 'addiction';
alter type public.dua_category add value if not exists 'anger';
alter type public.dua_category add value if not exists 'burnout';
alter type public.dua_category add value if not exists 'death_grief';
alter type public.dua_category add value if not exists 'envy';
alter type public.dua_category add value if not exists 'illness';
alter type public.dua_category add value if not exists 'loneliness';
alter type public.dua_category add value if not exists 'lust';
alter type public.dua_category add value if not exists 'marriage_conflict';
alter type public.dua_category add value if not exists 'parenting';
alter type public.dua_category add value if not exists 'shame';
alter type public.dua_category add value if not exists 'work';

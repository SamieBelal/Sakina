-- ---------------------------------------------------------------------------
-- Remove Mawlid occasions from islamic_occasions.
--
-- The original 20260514100000 migration seeded a `mawlid_2027` row and was
-- applied to remote Supabase before this cleanup. Mawlid is not an occasion
-- Sakina celebrates, so this migration removes any seeded mawlid_* rows.
--
-- Any sakina_gifts row referencing a mawlid_* occasion is also removed so
-- the FK constraint stays satisfied. In practice the seed row was never
-- claimed (its window starts 2027-09-04), but the DELETE is defensive.
-- ---------------------------------------------------------------------------

delete from public.sakina_gifts
where occasion_id like 'mawlid\_%' escape '\';

delete from public.islamic_occasions
where id like 'mawlid\_%' escape '\';

-- =============================================================================
-- Normalize First Steps quests into user_quest_progress (enum extension)
-- =============================================================================
-- PostgreSQL does not allow a newly-added enum value to be used until the
-- transaction that added it commits, so the data backfill lives in the next
-- migration file.
-- =============================================================================

alter type public.quest_cadence add value if not exists 'one_time';

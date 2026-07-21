-- Adds the 'emerald' value to the card_tier enum (tier 4, premium ceiling).
-- Standalone migration: ADD VALUE only, never USES the value in this file, so
-- it is safe under Supabase's per-migration transaction. The client and the
-- backfill RPC (next migration) depend on this value existing first.
alter type public.card_tier add value if not exists 'emerald';

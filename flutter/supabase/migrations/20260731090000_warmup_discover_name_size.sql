-- One Ship W5 / Wave D.1 — the third warmup dial
-- (docs/superpowers/plans/2026-07-31-one-ship-05-gate-and-free-tier.md §4.D.1 + §7)
--
-- W1's migration 20260727100200 seeded `warmup_reflect_size` and
-- `warmup_built_dua_size` but not the discover-name sibling, because
-- `handle_new_user` only stamps the two pooled features at signup. D10②
-- (founder decision, confirmed 2026-07-31) makes `discoverName` a genuine
-- 1/day with a 3-use lifetime RE-ROLL warmup, so the client needs the same
-- dial for it that it has for the other two.
--
-- This is a permanent tuning knob, not a flag: no deletion date, no kill
-- switch semantics. `GatingService.warmupSizeConfigKey` is the reader; the
-- client's hardcoded `discoverName: 5` survives only as the offline fallback
-- for a launch that can reach neither cache nor network.
--
-- Idempotent (`on conflict do nothing`), matching the house style of
-- 20260727100200: re-running never stomps a value tuned from the dashboard.

insert into public.app_config (key, value) values
  ('warmup_discover_name_size', '3')
on conflict (key) do nothing;

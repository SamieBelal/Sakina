-- `milestone_day` is deliberately absent: it gated nothing and is dropped by
-- 20260727120000_drop_inert_cosmetic_milestone_day.sql. Seeding a value here
-- would only be written and then discarded later in the same chain.
insert into public.cosmetic_catalog(item_type,item_id,noor_price,is_premium_exclusive,is_seasonal,season_key,iap_product_id,sort) values
  ('lantern_skin', 'classic_gold', 0, false, false, null, null, 0),
  ('lantern_skin', 'moonlit_silver', 120, false, false, null, null, 1),
  ('lantern_skin', 'emerald_jade', 120, false, false, null, null, 2),
  ('lantern_skin', 'rose_quartz', 120, false, false, null, null, 3),
  ('lantern_skin', 'obsidian_gold', 200, false, false, null, 'sakina.skin.obsidian', 4),
  ('lantern_skin', 'masjid_brass', 300, false, false, null, 'sakina.skin.masjid', 5),
  ('lantern_skin', 'crystal_star', 300, false, false, null, 'sakina.skin.crystal', 6),
  ('lantern_skin', 'ramadan_royal', null, true, true, 'ramadan', null, 7),
  ('backdrop', 'default', 0, false, false, null, null, 0),
  ('backdrop', 'laylat_night', 150, false, false, null, null, 1),
  ('backdrop', 'emerald_sanctuary', 150, false, false, null, null, 2),
  -- Added with the backdrop scene rebuild: Backdrop.all in
  -- lib/features/streaks/models/backdrop.dart and the _catalog mirror in
  -- cosmetic_catalog_ui.dart both carry these, so without rows here the
  -- wardrobe offers two backdrops that unlock_cosmetic rejects as
  -- 'item not Noor-purchasable or inactive' on a freshly-built database.
  ('backdrop', 'desert_night', 150, false, false, null, null, 3),
  ('backdrop', 'fajr_courtyard', 200, false, false, null, null, 4)
on conflict (item_type,item_id) do nothing;

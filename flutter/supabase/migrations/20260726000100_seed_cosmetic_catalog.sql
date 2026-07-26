insert into public.cosmetic_catalog(item_type,item_id,noor_price,milestone_day,is_premium_exclusive,is_seasonal,season_key,iap_product_id,sort) values
  ('lantern_skin','classic_gold',    0,    null, false, false, null, null, 0),
  ('lantern_skin','moonlit_silver',  120,  null, false, false, null, null, 1),
  ('lantern_skin','emerald_jade',    120,  7,    false, false, null, null, 2),
  ('lantern_skin','rose_quartz',     120,  null, false, false, null, null, 3),
  ('lantern_skin','obsidian_gold',   200,  30,   false, false, null, 'sakina.skin.obsidian', 4),
  ('lantern_skin','masjid_brass',    300,  null, false, false, null, 'sakina.skin.masjid', 5),
  ('lantern_skin','crystal_star',    300,  null, false, false, null, 'sakina.skin.crystal', 6),
  ('lantern_skin','ramadan_royal',   null, null, true,  true,  'ramadan', null, 7),
  ('backdrop','default',             0,    null, false, false, null, null, 0),
  ('backdrop','laylat_night',        150,  14,   false, false, null, null, 1),
  ('backdrop','emerald_sanctuary',   150,  null, false, false, null, null, 2)
on conflict (item_type,item_id) do nothing;

begin;
select plan(12);

select has_table('public','user_cosmetics','user_cosmetics exists');
select has_table('public','cosmetic_catalog','cosmetic_catalog exists');
select has_table('public','noor_grants','noor_grants ledger exists');
select col_is_pk('public','user_cosmetics', array['user_id','item_type','item_id'],'inventory PK');
select col_is_pk('public','noor_grants', array['user_id','reason_key'],'ledger PK (idempotency)');
select has_column('public','user_profiles','noor_balance','noor_balance col');
select has_column('public','user_profiles','noor_total_earned','earned col');
select has_column('public','user_profiles','noor_total_spent','spent col');
select has_column('public','user_profiles','equipped_lantern_skin','equipped skin col');
select has_column('public','user_profiles','equipped_backdrop','equipped backdrop col');
select has_column('public','cosmetic_catalog','min_app_version','catalog min_app_version');
select has_column('public','cosmetic_catalog','iap_product_id','catalog iap product id');

select * from finish();
rollback;

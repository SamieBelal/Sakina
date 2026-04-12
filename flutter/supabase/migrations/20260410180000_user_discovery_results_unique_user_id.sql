alter table public.user_discovery_results
  add constraint user_discovery_results_user_id_key unique (user_id);

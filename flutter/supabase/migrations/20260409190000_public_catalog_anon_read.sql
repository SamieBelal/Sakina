alter table public.browse_duas enable row level security;
alter table public.daily_questions enable row level security;
alter table public.discovery_quiz_questions enable row level security;
alter table public.name_anchors enable row level security;
alter table public.collectible_names enable row level security;

create policy "Anyone can read browse duas"
  on public.browse_duas
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can read daily questions"
  on public.daily_questions
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can read discovery quiz questions"
  on public.discovery_quiz_questions
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can read name anchors"
  on public.name_anchors
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can read collectible names"
  on public.collectible_names
  for select
  to anon, authenticated
  using (true);

create or replace function public.sync_all_user_data()
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  return jsonb_build_object(
    'xp',
      coalesce(
        (
          select jsonb_build_object(
            'total_xp', x.total_xp
          )
          from public.user_xp x
          where x.user_id = current_user_id
        ),
        jsonb_build_object('total_xp', 0)
      ),
    'tokens',
      coalesce(
        (
          select jsonb_build_object(
            'balance', t.balance,
            'total_spent', t.total_spent
          )
          from public.user_tokens t
          where t.user_id = current_user_id
        ),
        jsonb_build_object(
          'balance', 100,
          'total_spent', 0
        )
      ),
    'streak',
      coalesce(
        (
          select jsonb_build_object(
            'current_streak', s.current_streak,
            'longest_streak', s.longest_streak,
            'last_active', s.last_active
          )
          from public.user_streaks s
          where s.user_id = current_user_id
        ),
        jsonb_build_object(
          'current_streak', 0,
          'longest_streak', 0,
          'last_active', null
        )
      ),
    'daily_rewards',
      coalesce(
        (
          select jsonb_build_object(
            'current_day', r.current_day,
            'last_claim_date', r.last_claim_date,
            'streak_freeze_owned', r.streak_freeze_owned
          )
          from public.user_daily_rewards r
          where r.user_id = current_user_id
        ),
        jsonb_build_object(
          'current_day', 0,
          'last_claim_date', null,
          'streak_freeze_owned', false
        )
      ),
    'checkin_history',
      coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'checked_in_at', c.checked_in_at,
              'q1', c.q1,
              'q2', c.q2,
              'q3', c.q3,
              'q4', c.q4,
              'name_returned', c.name_returned,
              'name_arabic', c.name_arabic
            )
            order by c.checked_in_at desc
          )
          from public.user_checkin_history c
          where c.user_id = current_user_id
        ),
        '[]'::jsonb
      ),
    'reflections',
      coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'id', r.id,
              'saved_at', r.saved_at,
              'user_text', r.user_text,
              'name', r.name,
              'name_arabic', r.name_arabic,
              'reframe_preview', r.reframe_preview,
              'reframe', r.reframe,
              'story', r.story,
              'dua_arabic', r.dua_arabic,
              'dua_transliteration', r.dua_transliteration,
              'dua_translation', r.dua_translation,
              'dua_source', r.dua_source,
              'related_names', r.related_names
            )
            order by r.saved_at desc
          )
          from public.user_reflections r
          where r.user_id = current_user_id
        ),
        '[]'::jsonb
      ),
    'built_duas',
      coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'id', d.id,
              'saved_at', d.saved_at,
              'need', d.need,
              'arabic', d.arabic,
              'transliteration', d.transliteration,
              'translation', d.translation
            )
            order by d.saved_at desc
          )
          from public.user_built_duas d
          where d.user_id = current_user_id
        ),
        '[]'::jsonb
      ),
    'card_collection',
      coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'name_id', cc.name_id,
              'tier', cc.tier,
              'discovered_at', cc.discovered_at,
              'last_engaged_at', cc.last_engaged_at
            )
            order by cc.discovered_at asc
          )
          from public.user_card_collection cc
          where cc.user_id = current_user_id
        ),
        '[]'::jsonb
      ),
    'profile',
      coalesce(
        (
          select jsonb_build_object(
            'selected_title', p.selected_title,
            'is_auto_title', p.is_auto_title
          )
          from public.user_profiles p
          where p.id = current_user_id
        ),
        jsonb_build_object(
          'selected_title', null,
          'is_auto_title', true
        )
      )
  );
end;
$$;

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
            'total_spent', t.total_spent,
            'tier_up_scrolls', t.tier_up_scrolls
          )
          from public.user_tokens t
          where t.user_id = current_user_id
        ),
        jsonb_build_object(
          'balance', 100,
          'total_spent', 0,
          'tier_up_scrolls', 0
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
            'streak_freeze_owned', r.streak_freeze_owned,
            'last_premium_grant_month', r.last_premium_grant_month
          )
          from public.user_daily_rewards r
          where r.user_id = current_user_id
        ),
        jsonb_build_object(
          'current_day', 0,
          'last_claim_date', null,
          'streak_freeze_owned', false,
          'last_premium_grant_month', null
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
            'is_auto_title', p.is_auto_title,
            'created_at', p.created_at
          )
          from public.user_profiles p
          where p.id = current_user_id
        ),
        jsonb_build_object(
          'selected_title', null,
          'is_auto_title', true,
          'created_at', null
        )
      ),
    'achievements',
      coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'achievement_id', a.achievement_id,
              'unlocked_at', a.unlocked_at
            )
            order by a.unlocked_at desc
          )
          from public.user_achievements a
          where a.user_id = current_user_id
        ),
        '[]'::jsonb
      ),
    'discovery_results',
      (
        select jsonb_build_object(
          'anchor_names', d.anchor_names
        )
        from public.user_discovery_results d
        where d.user_id = current_user_id
      ),
    'daily_usage',
      coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'usage_date', u.usage_date,
              'reflect_uses', u.reflect_uses,
              'built_dua_uses', u.built_dua_uses
            )
            order by u.usage_date desc
          )
          from public.user_daily_usage u
          where u.user_id = current_user_id
            and u.usage_date between
              timezone('utc', now())::date - 1 and
              timezone('utc', now())::date + 1
        ),
        '[]'::jsonb
      ),
    'daily_answers',
      coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'answered_at', da.answered_at,
              'question_id', da.question_id,
              'selected_option', da.selected_option,
              'name_returned', da.name_returned,
              'name_arabic', da.name_arabic,
              'teaching', da.teaching,
              'dua_arabic', da.dua_arabic,
              'dua_transliteration', da.dua_transliteration,
              'dua_translation', da.dua_translation
            )
            order by da.answered_at desc
          )
          from public.user_daily_answers da
          where da.user_id = current_user_id
            and da.answered_at::date between
              timezone('utc', now())::date - 1 and
              timezone('utc', now())::date
        ),
        '[]'::jsonb
      ),
    'quest_progress',
      coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'quest_id', q.quest_id,
              'cadence', q.cadence,
              'progress', q.progress,
              'completed', q.completed,
              'period_start', q.period_start,
              'updated_at', q.updated_at
            )
            order by q.updated_at desc
          )
          from public.user_quest_progress q
          where q.user_id = current_user_id
        ),
        '[]'::jsonb
      )
  );
end;
$$;

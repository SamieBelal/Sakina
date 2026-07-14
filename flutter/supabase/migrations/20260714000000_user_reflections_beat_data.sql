-- 2026-07-14: Structured "beat_data" for the bite-sized reflection flow.
-- Adds a single nullable jsonb column holding the tap-through beats
-- {reframeKey, reframeBody, storyTitle, storyBeats[], storySource, takeaway}.
-- NULL for legacy rows (they fall back to splitIntoBeats over reframe/story).
-- Follows the same length + shape defense-in-depth as verses[] (migration
-- 20260524164841): a verbose or attacker-crafted response is clamped client-side
-- (decision 9A) and rejected here as a backstop. When beat_data is present it is
-- the source of truth; reframe/story remain derived (joined) values.

alter table public.user_reflections add column if not exists beat_data jsonb;

-- Top-level type cap: beat_data, when present, must be an object.
alter table public.user_reflections drop constraint if exists user_reflections_beat_data_type;
alter table public.user_reflections add constraint user_reflections_beat_data_type
  check (beat_data is null or jsonb_typeof(beat_data) = 'object');

-- Shape validator: every present field is a string within its cap; storyBeats
-- is an array of <= 3 strings, each <= 500 chars. Mirrors the client clamps in
-- reflect_provider.dart (_beat*MaxChars) EXACTLY.
create or replace function public._validate_user_reflections_beat_data_shape()
returns trigger language plpgsql security invoker set search_path = public, pg_temp as $$
declare v_beat jsonb;
begin
  if new.beat_data is not null then
    -- Scalar string fields.
    if (new.beat_data ? 'reframeKey'   and (jsonb_typeof(new.beat_data->'reframeKey')   <> 'string' or length(new.beat_data->>'reframeKey')   > 200))
    or (new.beat_data ? 'reframeBody'  and (jsonb_typeof(new.beat_data->'reframeBody')  <> 'string' or length(new.beat_data->>'reframeBody')  > 500))
    or (new.beat_data ? 'storyTitle'   and (jsonb_typeof(new.beat_data->'storyTitle')   <> 'string' or length(new.beat_data->>'storyTitle')   > 120))
    or (new.beat_data ? 'storySource'  and (jsonb_typeof(new.beat_data->'storySource')  <> 'string' or length(new.beat_data->>'storySource')  > 200))
    or (new.beat_data ? 'takeaway'     and (jsonb_typeof(new.beat_data->'takeaway')     <> 'string' or length(new.beat_data->>'takeaway')     > 200)) then
      raise exception 'user_reflections.beat_data fails scalar-field shape validation'
        using errcode = 'check_violation';
    end if;

    -- storyBeats: optional array of <= 3 strings, each <= 500 chars.
    if new.beat_data ? 'storyBeats' then
      if jsonb_typeof(new.beat_data->'storyBeats') <> 'array'
         or jsonb_array_length(new.beat_data->'storyBeats') > 3 then
        raise exception 'user_reflections.beat_data.storyBeats must be an array of <= 3'
          using errcode = 'check_violation';
      end if;
      for v_beat in select jsonb_array_elements(new.beat_data->'storyBeats') loop
        if jsonb_typeof(v_beat) <> 'string' or length(v_beat #>> '{}') > 500 then
          raise exception 'user_reflections.beat_data.storyBeats element fails shape validation: %', v_beat
            using errcode = 'check_violation';
        end if;
      end loop;
    end if;
  end if;
  return new;
end $$;

drop trigger if exists user_reflections_beat_data_shape on public.user_reflections;
create trigger user_reflections_beat_data_shape
  before insert or update on public.user_reflections
  for each row execute function public._validate_user_reflections_beat_data_shape();

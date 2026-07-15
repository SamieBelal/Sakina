-- 2026-07-15: Harden the user_reflections.beat_data shape validator.
-- The original trigger (20260714000000) validated only the six known keys and
-- had no total-size cap, so an authenticated client could hand-craft a
-- PostgREST insert storing an arbitrarily large blob under an UNKNOWN key
-- (client-side clamps don't apply to raw inserts — only RLS gates the write).
-- That re-opened the 50KB-blob storage-abuse class the sibling length-caps
-- migration (20260524164841) exists to close, and the bloat flows back through
-- hydration + the share-card renderer. This adds a total-size cap and rejects
-- any key outside the six-field schema. Idempotent create-or-replace of the
-- existing trigger function; no data change.

create or replace function public._validate_user_reflections_beat_data_shape()
returns trigger language plpgsql security invoker set search_path = public, pg_temp as $$
declare v_beat jsonb;
begin
  if new.beat_data is not null then
    -- Total-size cap (the six capped fields legitimately reach ~1.7KB; 8KB is
    -- generous headroom and rejects the multi-KB/MB blob class).
    if pg_column_size(new.beat_data) > 8192 then
      raise exception 'user_reflections.beat_data exceeds size cap'
        using errcode = 'check_violation';
    end if;

    -- Only the six known beat fields are allowed — reject any other key.
    if exists (
      select 1 from jsonb_object_keys(new.beat_data) k
      where k not in ('reframeKey', 'reframeBody', 'storyTitle',
                      'storyBeats', 'storySource', 'takeaway')
    ) then
      raise exception 'user_reflections.beat_data has unexpected keys'
        using errcode = 'check_violation';
    end if;

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

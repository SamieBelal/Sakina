-- 2026-05-26: Length + shape validation on user_reflections.
-- Closes P2-5 from docs/qa/findings/2026-05-24-ai-bypass-p1-p2-review.md.
-- Live-verified exploit: 55KB reframe + 30 fabricated verses accepted by prod
-- because user_reflections had only PK + FK constraints. Defense-in-depth
-- against prompt-injection landing in user_reflections / sync_all_user_data /
-- share-card image generator with arbitrarily-large or shape-violating content.

-- Length caps. Numbers chosen to be MUCH larger than any legitimate AI
-- response (typical reframe: 200-800 chars; typical story: 500-1500 chars).
-- A 4KB cap leaves 5x headroom and rejects the 50KB attack class.
alter table public.user_reflections drop constraint if exists user_reflections_text_length_caps;
alter table public.user_reflections add constraint user_reflections_text_length_caps
  check (
    length(coalesce(reframe, '')) <= 4096
    and length(coalesce(story, '')) <= 4096
    and length(coalesce(reframe_preview, '')) <= 300
    and length(coalesce(name, '')) <= 200
    and length(coalesce(name_arabic, '')) <= 200
    and length(coalesce(dua_arabic, '')) <= 1024
    and length(coalesce(dua_transliteration, '')) <= 1024
    and length(coalesce(dua_translation, '')) <= 1024
    and length(coalesce(dua_source, '')) <= 200
    and length(coalesce(user_text, '')) <= 2048
  );

-- JSON array shape + size caps for verses[] and related_names[].
alter table public.user_reflections drop constraint if exists user_reflections_jsonb_array_caps;
alter table public.user_reflections add constraint user_reflections_jsonb_array_caps
  check (
    (verses is null or (jsonb_typeof(verses) = 'array' and jsonb_array_length(verses) <= 8))
    and (related_names is null or (jsonb_typeof(related_names) = 'array' and jsonb_array_length(related_names) <= 8))
  );

-- Per-verse shape validator. Each verses[] element MUST be an object with
-- string fields {arabic, translation, reference}. Other element shapes
-- (raw strings, arrays, missing required keys) get rejected here.
create or replace function public._validate_user_reflections_verses_shape()
returns trigger language plpgsql security invoker set search_path = public, pg_temp as $$
declare v_verse jsonb;
begin
  if new.verses is not null then
    for v_verse in select jsonb_array_elements(new.verses) loop
      if jsonb_typeof(v_verse) <> 'object'
         or v_verse->>'arabic' is null
         or v_verse->>'translation' is null
         or v_verse->>'reference' is null
         or length(v_verse->>'arabic') > 2048
         or length(v_verse->>'translation') > 2048
         or length(v_verse->>'reference') > 200 then
        raise exception 'user_reflections.verses[] element fails shape validation: %', v_verse
          using errcode = 'check_violation';
      end if;
    end loop;
  end if;
  return new;
end $$;

drop trigger if exists user_reflections_verses_shape on public.user_reflections;
create trigger user_reflections_verses_shape
  before insert or update on public.user_reflections
  for each row execute function public._validate_user_reflections_verses_shape();

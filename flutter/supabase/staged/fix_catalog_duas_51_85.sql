-- Catalog duʿā repair — Al-Barr (id 85) only.
-- STAGED: do not apply to any remote database from this file. See README.md.
--
-- Scope note (2026-08-02): this script was scoped for ids 51 and 85. Id 51
-- (Al-Ghafur) was VERIFIED CORRECT and is deliberately NOT touched — its duʿā
-- is Sunan Abi Dawud 1516 (Ibn ʿUmar, Sahih per al-Albani) verbatim, ending
-- التَّوَّابُ الرَّحِيمُ. Id 11 (Al-Ghaffar) carries the Tirmidhi route of the
-- same hadith, ending التَّوَّابُ الْغَفُورُ. They are two routes, not a
-- near-miss. Do not "fix" either into the other.
--
-- Id 85 IS defective and is repaired here. Its duʿā is an AUTHORED catalog
-- invocation ("Ya <Name> ..." house form, 47 of 99 entries) with no narrated
-- source — searches for the Arabic phrases returned nothing in the hadith
-- corpus, and ارتجف is not a Qur'anic form. This is therefore an orthographic
-- and grammatical repair of authored text, NOT a change to narrated scripture.
--
-- Three defects, minimally repaired:
--   1. Arabic terminated on قُلُوبُ — an indefinite/construct-state noun with no
--      complement, leaving the clause hanging mid-genitive. → الْقُلُوبُ.
--   2. Transliteration typos: thabbintni → thabbitni, rasikhana → rasikhan.
--      Article assimilation follows house style (cf. tuhibbul-'afwa, id 86).
--   3. English disagreed in number with the Arabic ("my heart trembles" for a
--      plural subject). → "when the hearts tremble".
--
-- Must stay byte-identical to assets/content/collectible_names.json, which the
-- deck ship gate (test/content/name_stories_ship_gate_test.dart) asserts
-- against. Edit both or neither.
--
-- Idempotent: matches on the exact broken Arabic string, so a re-run after a
-- successful apply updates 0 rows. Safe to re-run.

do $$
declare
  v_rows integer;
begin
  update public.collectible_names
  set
    dua_arabic = 'يَا بَرُّ ثَبِّتْنِي عَلَى بِرِّكَ وَاجْعَلْ إِيمَانِي رَاسِخًا حِينَ تَرْتَجِفُ الْقُلُوبُ',
    dua_transliteration = 'Ya Barr, thabbitni ''ala birrik waj''al imani rasikhan hina tartajiful-qulub',
    dua_translation = 'O Source of Goodness, keep me firm on the grounds of Your goodness. Make my faith steady when the hearts tremble.'
  where id = 85
    and dua_arabic = 'يَا بَرُّ ثَبِّتْنِي عَلَى بِرِّكَ وَاجْعَلْ إِيمَانِي رَاسِخًا حِينَ تَرْتَجِفُ قُلُوبُ';

  get diagnostics v_rows = row_count;

  if v_rows = 0 then
    -- Either already applied, or the served row differs from what we audited.
    -- Both are non-fatal, but the second must not pass silently.
    if exists (
      select 1 from public.collectible_names
      where id = 85
        and dua_arabic = 'يَا بَرُّ ثَبِّتْنِي عَلَى بِرِّكَ وَاجْعَلْ إِيمَانِي رَاسِخًا حِينَ تَرْتَجِفُ الْقُلُوبُ'
    ) then
      raise notice 'id 85 already carries the repaired duʿā — no-op.';
    else
      raise exception 'id 85 dua_arabic matched neither the known-broken nor the repaired text; inspect before applying';
    end if;
  else
    raise notice 'id 85 duʿā repaired (% row).', v_rows;
  end if;
end $$;

-- Verification — run after applying. Expect exactly one row, and id 51
-- unchanged from what ships today.
--
-- select id, dua_arabic, dua_transliteration, dua_translation
-- from public.collectible_names
-- where id in (51, 85)
-- order by id;

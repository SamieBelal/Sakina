-- ============================================================================
-- ✅ APPLIED 2026-08-05 to production, on founder instruction.
--
-- Al-Qawiyy (62) and Al-Mateen (63): drop the `الْعَلِيِّ الْعَظِيمِ` epithet and
-- use the bare form the Ṣaḥīḥayn actually carry.
--
-- WHY. This started as "the same defect as ids 26/49" — a shared duʿā invoking
-- Names that are neither the deck's nor its pair's (Al-ʿAliyy 52 and Al-ʿAẓīm
-- 50). It turned out to be worse than that: a MISATTRIBUTION.
--
--   * `lib/core/constants/knowledge_base.dart` entry 24 (Al-Qawi / Al-Matin)
--     quoted the BARE form in its propheticStory, cited to Sahih al-Bukhari
--     4205, while its duʿā field carried the EXTENDED form and sourced it to
--     "Bukhari and Muslim". The entry contradicted itself.
--   * `collectible_names` id 63's own `hadith` field quotes Sahih al-Bukhari
--     6610 in the BARE form, while its `dua_arabic` used the extended one. The
--     card contradicted itself.
--   * Sahih al-Bukhari 6610's CHAPTER HEADING is
--     `باب لاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ` — bare. The Prophet ﷺ
--     teaches ʿAbdullāh b. Qays exactly that sentence, with no epithet.
--   * Diacritic-normalised sweep of the supplication chapters of six
--     collections: the BARE form appears in Bukhārī, Muslim, Abū Dāwūd, Ibn
--     Mājah and Tirmidhī. The EXTENDED form appears twice, both in the Sunan,
--     and in neither Ṣaḥīḥ.
--
-- So the extended form was attributed to collections that do not carry it.
-- The bare form fixes three things at once: it is what the Ṣaḥīḥayn say, it
-- makes knowledge_base's own source line TRUE, and it invokes no third Name.
-- It also still carries `قُوَّةَ` — Al-Qawiyy's own root.
--
-- CONTENT COUPLING, handled. `al-qawiyy@1` called this "nine quiet words" in
-- its bridge, takeaway and reflection, and its draft claimed "the duʿā you are
-- about to say is the same nine words". Nine is the EXTENDED form's word count;
-- the bare form is seven — and seven is what the story it narrates actually
-- teaches. The deck was already describing a sentence its own source does not
-- contain. Reworded to seven.
--
-- MIRRORS — all updated together (see 323ecd3 for why this matters):
--   1. public.collectible_names ids 62, 63          (this file)
--   2. assets/content/collectible_names.json        ✅
--   3. lib/services/card_collection_service.dart    ✅ (2 entries)
--   4. lib/core/constants/knowledge_base.dart       ✅ (entry 24)
--   5. lib/core/constants/dua_knowledge.dart        ✅ (Al-Mateen guidance)
--   6. the staged al-qawiyy@1 / al-mateen@1 deck beat 7 ✅ — the ship gate
--      asserts these are byte-identical to the catalogue, so they move together
--      or CI goes red on merge.
--
-- Guarded on the old value: re-running is a no-op and it cannot clobber a
-- later edit. Verified after applying: re-export vs the committed asset shows
-- 0 field-level differences across all 99 rows.
-- ============================================================================

update public.collectible_names
   set dua_arabic          = 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
       dua_transliteration = 'La hawla wa la quwwata illa billah',
       dua_translation     = 'There is neither might nor power except with Allah.'
 where id in (62, 63)
   and dua_arabic = 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ';

-- Verification — expect 2 rows, both bare:
--   select id, transliteration, dua_arabic from public.collectible_names
--    where id in (62, 63);

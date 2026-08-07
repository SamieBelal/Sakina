-- ============================================================================
-- APPLIED 2026-08-05 to production. Recorded here, NOT in supabase/migrations/,
-- to match the convention set by fix_catalog_duas_51_85.sql and
-- fix_catalog_hadith_2026_08_03.sql: catalogue CONTENT repairs are staged data
-- changes, not schema migrations.
--
-- Applied out-of-band via execute_sql on founder instruction, so it does NOT
-- appear in the supabase_migrations history table. It is guarded on the old
-- value, so re-running is a no-op either way.
--
-- MIRRORS — all four updated together (see 323ecd3 for why this matters):
--   1. public.collectible_names id 26            (this file)
--   2. assets/content/collectible_names.json     ✅
--   3. lib/services/card_collection_service.dart ✅
--   4. lib/core/constants/dua_knowledge.dart     ✅ (AI prompt context)
--   -- lib/core/constants/knowledge_base.dart:349 DELIBERATELY UNCHANGED: that
--      entry is the "Al-'Alim / Al-Hakim / Al-Latif" triad teaching and its own
--      source field reads "Traditional dua derived from the Name Al-Latif".
--      The ya Latif dua is correct there.
-- ============================================================================

-- Al-Hakeem (id 26): replace the shared `yā Laṭīf` duʿā with a narrated
-- supplication that actually invokes this Name.
--
-- WHY. Ids 26 and 49 shared one duʿā whose vocative is `يَا لَطِيفُ` —
-- Al-Lateef's (id 36), which carries a different duʿā of its own. Two decks
-- about wisdom and awareness both closed on a plea to a third Name. The drift
-- is explicable (`لَطِيفٌ خَبِيرٌ` is a fixed Qurʾānic pair, and
-- `حَكِيمٌ خَبِيرٌ` is another, so 26 inherited 49's partner's duʿā) but it is
-- still wrong.
--
-- WHAT. Ṣaḥīḥ Muslim 2696, Book 48 (Dhikr, Supplication, Repentance and
-- Istighfār), Ḥadīth 43, chapter "The Virtue Of Tahlil, Tasbih And Duʿa".
-- A bedouin asks the Prophet ﷺ to teach him words to say; the reply closes
-- `بِاللَّهِ الْعَزِيزِ الْحَكِيمِ`. Verified by fetching sunnah.com/muslim:2696
-- individually. Ṣaḥīḥ by collection (sunnah.com prints no grade line for the
-- Ṣaḥīḥayn — recorded as a collection-level inference, not a read grade).
--
-- Research: docs/superpowers/content/decks/2026-08-05-DUA-COLLISION-RESEARCH.md
--
-- NOT FIXED HERE, deliberately:
--   * id 49 (Al-Khabeer) keeps the `yā Laṭīf` duʿā. No authentic supplication
--     invoking Al-Khabeer exists — all 43 Qurʾānic occurrences of the Name-form
--     are declarative, and `يا خبير` returns zero across the supplication
--     chapters of six collections.
--   * ids 62/63 (Al-Qawiyy/Al-Mateen) share a duʿā invoking Al-ʿAliyy and
--     Al-ʿAẓīm and neither of them. Same defect class, separate decision.
--
-- Guarded on the old value so re-running is a no-op and so this cannot clobber
-- a later edit. `assets/content/collectible_names.json` is a GENERATED snapshot
-- of this table (tool/export_public_catalog_snapshots.dart) — re-export after
-- applying, or the bundled fallback and the server disagree.

update public.collectible_names
   set dua_arabic         = 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ اللَّهُ أَكْبَرُ كَبِيرًا وَالْحَمْدُ لِلَّهِ كَثِيرًا سُبْحَانَ اللَّهِ رَبِّ الْعَالَمِينَ لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَزِيزِ الْحَكِيمِ',
       dua_transliteration = 'La ilaha illallahu wahdahu la shareeka lah, Allahu akbaru kabeera, wal-hamdu lillahi katheera, subhanallahi rabbil ''alameen, la hawla wa la quwwata illa billahil ''Azeezil Hakeem',
       dua_translation     = 'There is no god but Allah, the One, having no partner with Him. Allah is the Greatest of the great and all praise is due to Him. Exalted is Allah (He is free from imperfection), the Lord of the worlds, there is no Might and Power but that of Allah, the All-Powerful and the Wise.'
 where id = 26
   and dua_arabic = 'اللَّهُمَّ يَا لَطِيفُ الْطُفْ بِي فِي أُمُورِي كُلِّهَا';

-- Catalogue repair — public.collectible_names.hadith, 27 of 99 rows.
--
-- ============================================================================
-- ✅ APPLIED TO PRODUCTION 2026-08-05, on founder instruction. P0 CLOSED.
--
-- Applied via PostgREST (service role) rather than by executing this file,
-- because the tooling available could not pipe a file to the database and
-- retyping 27 rows of Arabic-bearing religious text by hand was the larger
-- risk. The three passes below were replicated exactly:
--   PASS 1  read-before-write drift check across all 27 rows  -> no drift
--   PASS 2  write only rows still holding the old value       -> 27 written
--   PASS 3  per-row post-condition                            -> all ok
-- Equivalence proved before applying: every `new` value in this file was
-- confirmed byte-identical to assets/content/collectible_names.json, so the
-- writes were sourced from the asset and no religious text passed through a
-- human or model transcription step.
--
-- ONE DIFFERENCE, stated: PostgREST issues 27 separate writes, so this did NOT
-- run in a single transaction the way `BEGIN … COMMIT` below would have. A
-- partial apply would have been caught by PASS 3 and is idempotently
-- re-runnable, but the atomicity guarantee was not available.
--
-- Post-conditions verified after apply:
--   99 rows · 0 NULL hadith · 14 emptied · 13 replaced
--   0 rows still carrying "(Derived from Names teachings)" / "(Yaqeen…" / "(Hadith)"
--   re-export vs committed asset: 0 field-level differences across all 99 rows
--   (1 byte differs — the exporter writes a trailing newline the committed
--    asset lacks. Pre-existing and cosmetic; content is identical.)
--
-- Re-running this file is safe: PASS 2 updates 0 rows once applied.
-- ============================================================================
--
-- STAGED: do not apply to any remote database from this file. See README.md.
--
-- Companion report:
--   docs/superpowers/content/decks/2026-08-03-CATALOGUE-HADITH-FIX-REPORT.md
-- Audit this repairs:
--   docs/superpowers/content/decks/2026-08-03-CATALOGUE-HADITH-AUDIT.md
--
-- Precedent: supabase/staged/fix_catalog_duas_51_85.sql
--   * read-before-write
--   * idempotent -- re-running after a successful apply updates 0 rows
--   * RAISES on drift instead of overwriting silently: if a live row holds
--     neither the expected OLD value nor the new value, every warning is
--     emitted and then the whole transaction aborts. Nothing is written.
--
-- 27 rows touched. 13 replaced with a fetched Sahih narration,
-- 14 emptied to '' because no sahih narration demonstrating that Name
-- could be verified. '' and NOT NULL is deliberate: the client contract
-- (lib/services/public_catalog_contracts.dart) requires hadith to be non-null
-- on all 99 rows, and the card UI getter hasTier2Content (hadith.isNotEmpty)
-- (lib/services/card_collection_service.dart:125) degrades an empty value to
-- the existing "Coming soon..." state. NULL would break the contract.
--
-- Must stay byte-identical to assets/content/collectible_names.json and to
-- allCollectibleNames in lib/services/card_collection_service.dart, which
-- this pass already updated. Edit all three or none.

BEGIN;

DO $$
DECLARE
  v_current text;
  v_drift   int := 0;
  r         record;
  expected  jsonb := jsonb_build_object(
    '5', jsonb_build_object('old', 'The angels glorify Him saying: "Holy, Holy, Holy is the Lord of the angels and the spirit." (Muslim)'::text, 'new', '''A''isha (RA) reported that the Prophet ﷺ used to say while bowing and prostrating: "All Glorious, All Holy, Lord of the Angels and the Spirit." Al-Quddus is holy beyond every flaw the mind could imagine. (Sahih Muslim 487a — Sahih)'::text),
    '8', jsonb_build_object('old', 'The Prophet ﷺ said: "Might belongs to Allah, His Messenger, and the believers." (Quran 63:8)'::text, 'new', 'Allah says: "…And to Allah belongs [all] honor, and to His Messenger, and to the believers…" Al-Azeez is the source of every might that is real. (Quran 63:8)'::text),
    '14', jsonb_build_object('old', 'The Prophet ﷺ said: "Allah knew what His servants would do, and He wrote it all fifty thousand years before creating the heavens and the earth." (Muslim)'::text, 'new', 'The Prophet ﷺ said: "The keys of Unseen are five which none knows but Allah: None knows what will happen tomorrow but Allah; none knows what is in the wombs (a male child or a female) but Allah; none knows when it will rain but Allah; none knows at what place one will die; none knows when the Hour will be established but Allah." Al-Aleem alone holds what no one else can reach. (Sahih al-Bukhari 4697 — Sahih)'::text),
    '15', jsonb_build_object('old', 'The Prophet ﷺ said: "Call upon Allah using ''Ya Hayyu Ya Qayyum'' — by Your mercy I seek relief." (Tirmidhi)'::text, 'new', ''::text),
    '16', jsonb_build_object('old', 'The Prophet ﷺ said to Fatima: "Do not leave off a morning or evening without saying: Ya Hayyu Ya Qayyum, bi rahmatika astagheeth." (Al-Hakim)'::text, 'new', ''::text),
    '19', jsonb_build_object('old', 'The Prophet ﷺ said: "Greatness is My cloak and pride is My garment. Whoever competes with Me in either, I will throw into the Fire." (Muslim)'::text, 'new', 'In a hadith qudsi, the Prophet ﷺ reported that Allah said: "Glory is His lower garment and Majesty is His cloak and (Allah says,) He who contends with Me in regard to them I shall torment him." Greatness belongs to Al-Mutakabbir alone. (Sahih Muslim 2620 — Sahih)'::text),
    '20', jsonb_build_object('old', 'The Prophet ﷺ said: "You brought me out of nothingness into being." Al-Baari perfects what He produces — He repairs what we have broken within ourselves. (Yaqeen, The Name I Need)'::text, 'new', ''::text),
    '35', jsonb_build_object('old', 'Ibrahim (AS), when thrown into the fire, said: "Hasbunallah wa ni''mal Wakeel." Allah commanded the fire: "Be cool and safe for Ibrahim." (Quran 3:173)'::text, 'new', 'Ibn ''Abbas (RA) said: "''Allah is Sufficient for us and He is the Best Disposer of affairs'' was said by Abraham [Ibrahim] when he was thrown into the fire; and it was said by Muhammad ﷺ when they (i.e. hypocrites) said, ''A great army is gathering against you, therefore, fear them,'' but it only increased their faith…" Al-Wakeel is the One you hand the outcome to. (Sahih al-Bukhari 4563 — Sahih; mawquf — these are Ibn ''Abbas''s words, not the Prophet''s ﷺ)'::text),
    '43', jsonb_build_object('old', 'Umar (RA) said: "We were a debased people. Allah gave us honor through Islam. If we seek honor through anything else, we will be debased again." (Al-Hakim)'::text, 'new', ''::text),
    '44', jsonb_build_object('old', 'Umar (RA) said: "We were a debased people. Allah gave us honor through Islam. If we seek honor through anything else, we will be debased again." (Al-Hakim)'::text, 'new', ''::text),
    '45', jsonb_build_object('old', 'Zakariyya (AS) made a silent call in the corner of the masjid. Before he could finish, Allah said: "I heard you — and here is the child, already named Yahya." (Quran 19:3-7)'::text, 'new', 'When the companions raised their voices in dhikr on a journey, the Prophet ﷺ said: "O people! Be merciful to yourselves (i.e. don''t raise your voice), for you are not calling a deaf or an absent one, but One Who is with you, no doubt He is All-Hearer, ever Near (to all things)." As-Sami hears the call you never said aloud. (Sahih al-Bukhari 2992 — Sahih)'::text),
    '50', jsonb_build_object('old', 'When Surah Al-A''la was revealed, the Prophet ﷺ said: "Make this in your sujud." In our deepest prostration we declare His highest. (Abu Dawud)'::text, 'new', 'Hudhayfah (RA) prayed a night prayer with the Prophet ﷺ and reported that he would bow and say: "Glory be to my Mighty Lord." In ruku'' the servant names Al-Azeem. (Sahih Muslim 772 — Sahih)'::text),
    '52', jsonb_build_object('old', 'The Prophet ﷺ said: "Whoever humbles himself for Allah, Allah exalts him. Whoever exalts himself, Allah lowers him." (Muslim)'::text, 'new', ''::text),
    '54', jsonb_build_object('old', 'The Prophet ﷺ said: "Allah provides for every creature — He is Al-Muqeet, the Nourisher of all things." Not just bodies but souls and purposes are sustained by Him. (Ibn Kathir, Tafsir of Quran 4:85)'::text, 'new', ''::text),
    '56', jsonb_build_object('old', 'The Prophet ﷺ said: "Fill your heart with reverence of Allah that draws you near, not fear that drives you away." Al-Jaleel is the Majestic whose awe refines the servant. (Yaqeen, The Name I Need Day 06)'::text, 'new', ''::text),
    '63', jsonb_build_object('old', 'The Prophet ﷺ said: "Shall I not teach you a treasure from beneath the throne? La hawla wa la quwwata illa billah." (Bukhari & Muslim)'::text, 'new', 'The Prophet ﷺ said: "O ''Abdullah bin Qais! Shall I teach you a sentence which is from the treasures of Paradise? (It is): La hawla wa la quwwata illa billah — there is neither might nor power except with Allah." All strength is Allah''s alone. (Sahih al-Bukhari 6610 — Sahih)'::text),
    '64', jsonb_build_object('old', 'The Prophet ﷺ said: "Be in this world as if you are a stranger or a wayfarer." Your only consistent companion is Al-Wali. (Bukhari)'::text, 'new', 'In a hadith qudsi, the Prophet ﷺ reported that Allah said: "I will declare war against him who shows hostility to a pious worshipper of Mine… and if he asks Me, I will give him, and if he asks My protection (Refuge), I will protect him." Al-Waliyy is the ally who never withdraws. (Sahih al-Bukhari 6502 — Sahih)'::text),
    '65', jsonb_build_object('old', 'In a Hadith Qudsi: "O child of Adam, devote yourself to My worship, and I will fill your heart with richness." The more you praise a blessing, the more fulfilling it becomes. (Muslim)'::text, 'new', 'The Prophet ﷺ said: "Allah is pleased with His servant who says: Al-Hamdu lillah while taking a morsel of food and while drinking." Al-Hameed is praised in the smallest mouthful. (Sahih Muslim 2734a — Sahih)'::text),
    '66', jsonb_build_object('old', 'The Prophet ﷺ said: "Not a leaf falls but that He knows it. There is no grain in the darkness of the earth, nor anything moist or dry, but that it is written in a clear record." Al-Muhsi has numbered every tear. (Quran 6:59)'::text, 'new', 'Allah says: "…Not a leaf falls but that He knows it. And no grain is there within the darknesses of the earth and no moist or dry [thing] but that it is [written] in a clear record." Al-Muhsi has numbered every tear. (Quran 6:59)'::text),
    '71', jsonb_build_object('old', 'The Prophet ﷺ said: "Allah is never at a loss for what you need." Al-Wajid finds whatever He wills and lacks nothing — He always finds a way for His servant. (Derived from Names teachings)'::text, 'new', ''::text),
    '75', jsonb_build_object('old', 'The Prophet ﷺ said: "Nothing is beyond the power of Allah." Al-Qadir parts seas and revives the dead — what seems impossible to you is effortless for Al-Qadir. (Muslim)'::text, 'new', ''::text),
    '77', jsonb_build_object('old', 'The Prophet ﷺ said: "Your rizq chases you the way death chases you." What Al-Muqaddim advances is always on time. (Hadith)'::text, 'new', 'The Prophet ﷺ used to invoke: "…Allahumma ighfir li ma qaddamtu wa ma akhkhartu wa ma asrartu wa ma a''lantu. Anta-l-muqaddimu wa anta-l-mu''akhkhiru, wa anta ''ala kulli shai''in qadir." Al-Muqaddim is named in the Prophet''s own supplication — He brings forward whom He wills. (Sahih al-Bukhari 6398 — Sahih)'::text),
    '82', jsonb_build_object('old', 'A man the Prophet ﷺ pointed to as a person of Jannah had one hidden deed: "I never go to sleep without cleaning my heart of any hatred toward any person." (Ahmad)'::text, 'new', ''::text),
    '84', jsonb_build_object('old', 'The Prophet ﷺ said: "Whoever humbles himself for Allah, Allah exalts him. Whoever exalts himself, Allah lowers him." (Muslim)'::text, 'new', ''::text),
    '85', jsonb_build_object('old', 'The Prophet ﷺ said upon completing Hajj: "Our Lord is Al-Barr, Al-Ghafur." Al-Barr is the source of all kindness whose goodness is the origin of every blessing you have received. (Muslim 1342)'::text, 'new', ''::text),
    '94', jsonb_build_object('old', 'The Prophet ﷺ said: "What Allah withholds is also His mercy." Al-Mani prevents what would harm and withholds what would not benefit — His prevention is His protection. (Derived from Names teachings)'::text, 'new', 'The Prophet ﷺ used to say after every compulsory prayer: "…Allahumma la mani''a lima a''taita, wa la mu''tiya lima mana''ta… [O Allah! Nobody can hold back what you gave, nobody can give what You held back…]" What Al-Mani withholds, no one can release. (Sahih al-Bukhari 844 — Sahih)'::text),
    '96', jsonb_build_object('old', 'The Prophet ﷺ said: "Ask Allah for benefit (naf'') in this world and the next." An-Nafi placed benefit in places you have not yet looked — every good thing traces back to Him. (Ibn Majah 3846)'::text, 'new', ''::text)
  );
BEGIN
  -- Pass 1: read before write. Detect drift across ALL rows first, so the
  -- operator sees every problem at once rather than one per re-run.
  FOR r IN SELECT key::int AS id, value->>'old' AS old_v, value->>'new' AS new_v
           FROM jsonb_each(expected) ORDER BY key::int
  LOOP
    SELECT hadith INTO v_current FROM public.collectible_names WHERE id = r.id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'collectible_names id % is missing from the live table', r.id;
    END IF;

    IF v_current IS DISTINCT FROM r.old_v AND v_current IS DISTINCT FROM r.new_v THEN
      v_drift := v_drift + 1;
      RAISE WARNING 'DRIFT id %: live value matches neither the audited old value nor the new one. Live: %', r.id, v_current;
    END IF;
  END LOOP;

  IF v_drift > 0 THEN
    RAISE EXCEPTION 'Aborting: % row(s) drifted from the audited value. Nothing written. Re-audit before applying.', v_drift;
  END IF;

  -- Pass 2: write only rows still holding the old value (so a re-run is a no-op).
  FOR r IN SELECT key::int AS id, value->>'old' AS old_v, value->>'new' AS new_v
           FROM jsonb_each(expected) ORDER BY key::int
  LOOP
    UPDATE public.collectible_names
       SET hadith = r.new_v
     WHERE id = r.id
       AND hadith IS NOT DISTINCT FROM r.old_v;
  END LOOP;

  -- Pass 3: per-row post-condition. Every targeted row must now hold exactly
  -- the new value, or the transaction must not commit.
  FOR r IN SELECT key::int AS id, value->>'new' AS new_v
           FROM jsonb_each(expected) ORDER BY key::int
  LOOP
    SELECT hadith INTO v_current FROM public.collectible_names WHERE id = r.id;
    IF v_current IS DISTINCT FROM r.new_v THEN
      RAISE EXCEPTION 'Post-condition failed for id %: row does not hold the new value.', r.id;
    END IF;
  END LOOP;

  RAISE NOTICE 'collectible_names.hadith repaired: 27 row(s) targeted.';
END $$;

-- Global post-condition: 99 rows, none NULL. The client contract needs both.
DO $$
DECLARE
  v_bad int;
BEGIN
  SELECT count(*) INTO v_bad FROM public.collectible_names WHERE hadith IS NULL;
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'Post-condition failed: % row(s) have a NULL hadith.', v_bad;
  END IF;

  SELECT count(*) INTO v_bad FROM public.collectible_names;
  IF v_bad <> 99 THEN
    RAISE EXCEPTION 'Post-condition failed: expected 99 rows, found %.', v_bad;
  END IF;
END $$;

COMMIT;

-- Verification -- run after applying. Expect 13 populated, 14 empty.
--
-- select id, transliteration, (hadith = '') as emptied, hadith
-- from public.collectible_names
-- where id in (5, 8, 14, 15, 16, 19, 20, 35, 43, 44, 45, 50, 52, 54, 56, 63, 64, 65, 66, 71, 75, 77, 82, 84, 85, 94, 96)
-- order by id;
--
-- Then re-export the snapshots so the table and the JSON asset cannot
-- diverge again (the exporter writes the identical format, so this should
-- produce a no-op diff):
--   dart run tool/export_public_catalog_snapshots.dart

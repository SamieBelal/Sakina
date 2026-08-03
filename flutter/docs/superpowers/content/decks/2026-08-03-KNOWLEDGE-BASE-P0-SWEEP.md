# knowledge_base.dart — P0 sweep: quoted speech attributed to Allah or the Prophet ﷺ

**Target file:** `/Users/appleuser/conductor/workspaces/sakina/beirut/flutter/lib/core/constants/knowledge_base.dart`
**Scope:** `const List<NameTeaching> nameTeachings` (line 81 → 3126). **100 entries**, each with a `coreTeaching` and a `propheticStory` string → 200 prose strings extracted programmatically.
**Failure class hunted:** a passage in quotation marks attributed to Allah or to the Prophet ﷺ that cannot be located in a source. Nothing else.
**REPORT ONLY — no repository file was modified.**

---

## 1. Method (what I actually did)

1. Wrote a Dart-literal reader in Python that walks `coreTeaching:` / `propheticStory:` field labels, consumes adjacent string literals, and decodes `\uXXXX`, `\'`, `\"`, `\n`. All 200 strings extracted → `/tmp/hv/kb_records.json`.
2. Extracted every quoted span from those strings. **Two passes were needed** — my first single-quote regex silently dropped quotes containing internal apostrophes (`'Who am I? I can't read. I'm nobody.'`), which is exactly where one of the fabrications lives. Second pass used word-boundary delimiters and recovered 45 additional spans. **462 + 45 quoted spans total.**
3. Attribution-filtered on the 110 characters preceding each span (`The Prophet ﷺ said`, `Allah says/said/answers/commanded/cut him off`, `In a Hadith Qudsi`, `the Quran says`, `the verse says`, `He said`, …) → **240 candidate quotations of divine or prophetic speech**, then read the surrounding prose by hand to discard scholar/companion attributions.
4. Located each candidate:
   - **Qur'an:** `api.quran.com/api/v4/verses/by_key/{s}:{a}?translations=20` (Sahih International). 17 keys fetched verbatim.
   - **Hadith:** built a local full-text index over the `fawazahmed0/hadith-api` English editions — `bukhari, muslim, abudawud, tirmidhi, nasai, ibnmajah, malik, nawawi (40), qudsi (40)` — searched by distinctive 4–6 word phrases, with multiple phrasings per quote (English translations vary wildly; e.g. "burns off filth from iron" only surfaced under "furnace removes the alloy of iron").
   - **Outside those books:** targeted web retrieval to establish whether a real source exists (Musnad Ahmad, al-Adab al-Mufrad, al-Nasa'i's al-Sunan al-Kubra, Hilyat al-Awliya').
5. I retrieved and cited. I did not compose, reconstruct, or recall scripture from memory at any point.

---

## 2. THE DELIVERABLE — quotations attributed to Allah or the Prophet ﷺ that I could NOT locate

| # | Name entry | ~Line | Exact quoted sentence | Attributed to | What I searched, and where | Verdict |
|---|---|---|---|---|---|---|
| 1 | `As-Sami' / Al-Qarib / Al-Mujib` | 255 | `I heard you — and here is the child you were asking for, already named Yahya.` | "Allah cut him off:" | Q19:7 fetched verbatim (`api.quran.com`): *"[He was told], 'O Zechariah, indeed We give you good tidings of a boy whose name will be John…'"*. Also Q19:9, Q21:89, Q3:38. Phrase search "I heard you" / "already named Yahya" across all 9 hadith editions. | **INVENTED divine speech.** (the already-known case, confirmed) |
| 2 | `Al-Ghaffar / Al-Ghafoor / At-Tawwab` | 222 | tail of the Prophet's quote: `…— because sometimes a sin that brings you closer to Allah is better than a good deed that fills you with arrogance.` | `The Prophet ﷺ said:` | Located the *first half*: **Sahih Muslim (USC 6965 = 2749)** — *"…if you were not to commit sin, Allah would sweep you out of existence and He would replace (you by) those people who would commit sin and seek forgiveness from Allah, and He would have pardoned them."* The hadith **ends there**. Web-verified the trailing clause: it is **Ibn al-Qayyim's** saying (*Madarij* / widely circulated: "A sin that leads to humility is more beloved to Him than an act of obedience which fills a person with conceit"). The same sentiment is correctly attributed to **Ibn Ata'illah** twice elsewhere in this very file (L934, L1362). | **A scholar's aphorism sealed inside the Prophet's ﷺ quotation marks.** |
| 3 | `Al-Shakur` | 1362 | `You did that for me.` | `A man moved a thorn branch from a path. Allah said:` | Primary text located: **Muwatta Malik 292**, Bukhari 652 / Muslim 1914 — *"Allah thanks him for doing it and forgives him."* There is **no divine direct speech** anywhere in the narration. Searched "branch of thorns", "removed it", "thanked him" across all editions. | **INVENTED divine speech.** |
| 4 | `Al-Shakur` | 1362 | `You did that for my creation.` | `…gave water to a thirsty dog. Allah said:` | Primary text located: **Sahih Muslim (USC 5859, 5860, 5861)** — *"So Allah appreciated this act of his and pardoned him"* / *"she was pardoned because of this."* Again **no divine direct speech**. | **INVENTED divine speech.** |
| 5 | `Al-Shakur` | 1364 | `Bear witness that I have forgiven everyone in this gathering for every sin they ever committed in their entire life.` | `Allah says to the angels:` | Source located: **Jami' at-Tirmidhi 3600** (Sahih; = Bukhari 6408 / Muslim 2689), full text retrieved. Allah's words are *"So I do call You to witness that I have forgiven them."* The clause **"for every sin they ever committed in their entire life" is not in the narration.** | **Embellished divine speech** — words added inside Allah's quotation marks. |
| 6 | `Al-Wadud` | 1436 | `That you cause other people to love Me — remind them of My blessings upon them.` (and the paired `Dawood (AS) asked Allah: 'What do you love most?'`) | `Allah said:` | Zero hits across bukhari/muslim/abudawud/tirmidhi/nasai/ibnmajah/malik/nawawi40/qudsi40 for "make Me beloved", "love Me and make Me beloved", "describe My bounties". Web retrieval surfaces the text **only** in later devotional compilations (al-Majlisi's *Hayat al-Qulub*) and unsourced repostings; no Sunni isnad established, not in the 40 Hadith Qudsi. | **Not located.** Divine speech with no retrievable source. |
| 7 | `Al-Qarib / Al-Mujib` | 1151 | `Answer him. Of course I will.` | `They brought his dua before Allah. Allah said:` | The Yunus/angels narration exists — **Musnad al-Bazzar (Kashf al-Astar 2254) / Ibn Jarir's Tafsir**, via Anas — but the retrievable text has the angels saying *"a familiar voice from an unfamiliar place"* and interceding. **No divine reply is quoted in the sources I could retrieve.** | **Not located.** |
| 8 | `Al-Karim` | 1294 | `Who am I? I can't read. I'm nobody.` | `The Prophet felt completely unworthy:` | The first-revelation account is **Sahih al-Bukhari 3**; the Prophet's ﷺ words there are *"Ma ana bi qari'"* ("I do not know how to read"). Searched "who am I", "I'm nobody", "nobody" across all editions. | **INVENTED prophetic speech.** ⚠️ This one was *missed by the first extraction pass* because of the internal apostrophes. |
| 9 | `Al-Karim` | 1294 | `I've got you.` | `…because you realize He's already said:` | No source exists or was claimed. Colloquial divine speech in quotation marks. | **INVENTED divine speech.** |
| 10 | `Al-Wahhab` | 1658 | `I said so.` | `Zakariah asked: 'How?' Allah's answer:` | Q19:9 fetched verbatim: *"[An angel] said, 'Thus [it will be]; your Lord says, "It is easy for Me, for I created you before, while you were nothing."'"* — "I said so" is nowhere in it. | **Not located.** Divine speech that does not match the verse it stands in for. |
| 11 | `Al-Mani` | 2821 | `Stay.` (and the whole narrative: a companion dreams he will die on a journey, obeys, the caravan is attacked) | `He returned and told the Prophet ﷺ, who said:` | Searched "dream", "journey", "caravan", "attacked" combinations across all 9 editions; nothing matching. No collection or grade given in the file. | **Not located.** A prophetic quotation inside an uncited story. |
| 12 | `An-Nasir` | 1042 | `We're safe.` | `The Prophet looked at Abu Bakr and smiled:` | The Buraydah/Aslam *salimna* wordplay is sirah material (Ibn Hisham / al-Bayhaqi's *Dala'il*); not in the six books. Searched "Buraydah", "Aslam", "we are safe". | **Not located** in any canonical collection; sirah-only at best. Lower confidence than 1–11 — flagged, not condemned. |
| 13 | `Al-Azeez` | 1783 | `What do you think I will do to you?` … `Go, for you are free.` | the Prophet ﷺ at the conquest of Mecca | Not in the six books (searched "noble brother", "son of a noble brother", "free"). Standard sirah (Ibn Hisham; al-Bayhaqi). | **Not located** in a canonical collection. Sirah-grade, presented in the file with no source. |

### 2b. Divine speech quoted as Qur'an that does not match the verse

Same failure class (words in Allah's mouth), different mechanism — these are presented as `The Quran says: "…"` but are paraphrase, not the text.

| Name entry | ~Line | Quoted as Qur'an | The actual verse (fetched verbatim from api.quran.com) |
|---|---|---|---|
| `Al-Fattah` | 1328 | `If you believe in Him and are aware of Him, Allah will open up baraka in your life.` | **Q7:96** — *"And if only the people of the cities had believed and feared Allāh, We would have opened [i.e., bestowed] upon them blessings from the heaven and the earth; but they denied…"* A **counterfactual about past nations**, re-cast as a present-tense promise to the reader. |
| `Al-Qahhar / Al-Jabbar` | 373 | `They plot, and Allah plots, and His plot always prevails.` | **Q8:30** — *"But they plan, and Allāh plans. And Allāh is the best of planners."* "His plot always prevails" is added. |
| `Al-Karim` | 1294 | `Allah introduced Himself … in the very first revelation as 'Al-Karim'` | **Q96:3** — *"Recite, and your Lord is the most Generous"* (**al-Akram**, the superlative, not *al-Karim*). Minor, same root — recorded for completeness. |
| `Al-Qawi / Al-Matin` | 831 | `Shall I not teach you a word that is a treasure from beneath the throne?` | Source located (**Bukhari 6409 / Muslim USC 6864**) but reads *"a sentence from the **treasure of Paradise**."* "Beneath the throne" is not in the retrieved wording. |

---

## 3. Quotations I DID locate (the sweep was real)

Grades are as carried in the corpus metadata (Albani / Shakir / Zubair Ali Zai / Shu'ayb al-Arna'ut, as available).

| Name entry (~line) | Quote (short) | Located at | Retrieved from |
|---|---|---|---|
| Ar-Rahman 98 | "My mercy prevails over My wrath" (above the Throne) | **Bukhari 7453, 7553, 7554** | local corpus |
| Ar-Rahman 100 | "Do you think this woman could throw her child into a fire?" + "Allah is more merciful…" | **Muslim USC 6978** | local corpus |
| Al-Hadi/An-Nur 160 | "All of you are astray except those I have guided…" | **Muslim USC 6572**; **Qudsi 17**; **Nawawi 24**; Tirmidhi 2495 | local corpus |
| Al-Hadi/An-Nur 160 | "O Allah, place light in my heart…" | **Muslim USC 1797**; **Nasa'i 1121** (Sahih) | local corpus |
| Al-Ghaffar 222 (first half) | "if you did not sin, Allah would replace you…" | **Muslim USC 6965 (=2749)** | local corpus |
| Al-Ghaffar 222 | "an earth full of sins … an earth full of forgiveness" | **Tirmidhi 3540** (Sahih); **Qudsi 34**; **Nawawi 42** | local corpus |
| As-Sami' 253 | "I am close." | **Q2:186** | api.quran.com |
| Al-Ghani/Al-Fattah 312 | "O child of Adam, devote yourself to My worship…" | **Tirmidhi 2466** (Sahih); **Ibn Majah 4107** (Sahih) | local corpus |
| Al-Ghani/Al-Fattah 314 | "So We opened the gates of the heaven…" / "a clear conquest" | **Q54:11**, **Q48:1** | api.quran.com |
| Al-Qahhar 373 | "Never think Allah is unaware of what the wrongdoers do…" | **Q14:42** | api.quran.com |
| Ash-Shafi 435 / 437 | "Take away the harm, Lord of people…" | **Ibn Majah 3520** (Sahih) (= Bukhari 5675 / Muslim 2191) | local corpus |
| Ash-Shafi 435 | "Do not curse the fever…" | **Muslim USC 6570 (=2575)** | local corpus |
| Ash-Shafi 437 | "O son of Adam, I was sick but you did not visit Me" + reply | **Muslim USC 6556** | local corpus |
| As-Sabur/Al-Halim 466 | "No one has ever been given a gift better and more vast than patience" | **Bukhari 1469** (full text read) | local corpus |
| As-Sabur/Al-Halim 468 | the woman with seizures; "be patient and you will have Paradise" | **Bukhari 5652**; **Muslim USC 6571** | local corpus |
| Al-Awwal/Al-Akhir 496 & Al-Dhahir 899 | "You are the First — nothing before You…" | **Ibn Majah 3873** (Sahih = Muslim 2713) | local corpus |
| Al-Awwal 498 | "If the Hour is established and one of you has a small plant…" | **Al-Adab al-Mufrad 479** (Albani: Sahih); **Musnad Ahmad 12902** | web retrieval (not in the 9 editions) |
| Al-Wadud 529 / 1436 | "I love so-and-so, so love him" (Jibreel) | **Muslim USC 6705**; **Qudsi 24**; **Malik 1744** | local corpus |
| Al-Wadud 1436 | "Can you imagine her throwing her child into the fire?" | **Muslim USC 6978** | local corpus |
| Al-Wadud 1436 | "They go home with livestock and gold. You go home with me." | **Bukhari 4332, 4334** | local corpus |
| Al-'Afuw 560 | "Allahumma innaka 'Afuwwun tuhibbul-'afwa fa'fu 'anni" | **Ibn Majah 3850** (Sahih) | local corpus |
| Al-Wakil 591 | "Be cool and safe for Ibrahim" | **Q21:69** | api.quran.com |
| Al-Karim/Al-Wahhab 648 | "Indeed Allah is Jawad and He loves generosity" | **Tirmidhi 2799** — ⚠️ **Da'if** by Shakir, Albani, Bashar Awad, Zubair Ali Zai | local corpus |
| Al-Karim/Al-Wahhab 648 | "If you were to trust Allah as He should be trusted … the birds" | **Ibn Majah 4164** (Sahih) | local corpus |
| Al-Hayy/Al-Qayyum 678 | the Fatima du'a "Ya Hayyu Ya Qayyum … wa la takilni ila nafsi tarfata 'ayn" | **al-Nasa'i, al-Sunan al-Kubra / 'Amal al-Yawm wa'l-Layla**; al-Hakim (Sahih), al-Mundhiri, Albani (Hasan) | web retrieval (not in the 9 editions) |
| Al-Hayy 680 / Dhul-Jalal 2727 | "Ya Hayyu Ya Qayyum bi-rahmatika astaghith" | **Tirmidhi 3524** (Hasan) | local corpus |
| Al-Wali 740 | "Be in this world as if you're a stranger or a wayfarer" | **Nawawi 40** (= Bukhari 6416) | local corpus |
| Al-Wali 742 | "May Allah have mercy on the mother of Isma'il…" | **Bukhari 2368** | local corpus |
| Al-'Ali/Al-Majid 772, Al-Muta'ali 862 | "Glory be to my Lord most High" (in sujud) | **Tirmidhi 262** (Sahih, Hudhayfah) | local corpus |
| As-Salam/Al-Quddus 800 | "Astaghfirullah" ×3 + "Allahumma anta's-Salam…" | **Nasa'i 1338** (Sahih = Muslim 591); Muslim USC 1334 | local corpus |
| Al-Qawi 829 | "The strong one is not the one who overcomes others…" | **Bukhari 6114** | local corpus |
| Al-Qawi 831 | "La hawla wa la quwwata illa billah" — treasure | **Bukhari 6409**; **Muslim USC 6864** (wording variance — §2b) | local corpus |
| Al-Muta'ali 860 | "No one humbles himself for the sake of Allah except that Allah raises him" | **Tirmidhi 2029** (Sahih) (= Muslim 2588) | local corpus |
| Al-Dhahir 899 | "The next man who walks in is a man of Jannah" + the man's answer | **Musnad Ahmad 12697** (Hasan) | web retrieval (not in the 9 editions) |
| Al-Ghani 934 | "Richness is not having many things…" | **Tirmidhi 2373** (Sahih = Bukhari 6446) | local corpus |
| Al-Ghani 934 | "O Allah, enrich me with Your bounty so that I don't need anyone but You" | **Tirmidhi 3563** — *"suffice me with Your lawful against Your prohibited, and make me independent of all those besides You"* | local corpus |
| Al-Mu'izz 969 | "Whoever desires honor — all honor belongs to Allah" | **Q35:10** | api.quran.com (root check) |
| Al-Jabbar 1006 / 1008 | "O Allah, forgive me, guide me, set me right" (between the sajdahs) | **Abu Dawud 850** (Hasan); **Tirmidhi 284** | local corpus |
| Al-Jabbar 1008 / Ad-Darr 2844 | "If the entire world gathered to harm you…" | **Tirmidhi 2516** (Sahih); **Nawawi 19** | local corpus |
| Ar-Rabb 1079 | "Recite in the name of your Rabb" / "You are given what you asked…" | **Q96:1**, **Q20:36–37** | api.quran.com |
| Ar-Razzaq 1112 | "Wretched is the slave of the dollar and the dinar" | **Ibn Majah 4135, 4136** (Sahih Bukhari) | local corpus |
| Al-Qarib 1149 | "When My servant asks about Me — I am near" | **Q2:186** | api.quran.com |
| As-Salam 1188 | "Did I say this year?" | **Bukhari 2731 / 2732** (full Umar dialogue read verbatim) | local corpus |
| Al-'Afuww 1261 | "Let them pardon and overlook. Do you not want Allah to forgive you?" | **Q24:22** | api.quran.com |
| Al-Fattah 1328 | "Whatever Allah opens for people from His mercy, no one can hold it back" | **Q35:2** | api.quran.com |
| Al-Fattah 1328 | "I am shy — shy to let your raised hands come back empty" | **Tirmidhi 3556** (Hasan/Sahih) — note: the source is the *Prophet describing* Allah, the file renders it as Allah speaking | local corpus |
| Al-Fattah 1330 / Al-Muqaddim 1582,1584 | "Indeed We have given you a clear conquest" | **Q48:1** | api.quran.com |
| Al-Shakur 1364 | "…I become the hearing with which he hears…" | **Qudsi 25 / Bukhari 6502** family; located in corpus | local corpus |
| Al-Wakil 1401 | "What do you think about two people, the third of which is Allah?" | **Bukhari 3653**; **Tirmidhi 3096** (Sahih) | local corpus |
| At-Tawwab 1471 | "as long as you call upon Me and never lose hope in Me…" | **Tirmidhi 3540**; **Qudsi 34** | local corpus |
| Al-Hadi 1508 | "Ya ibadi, kullukum dall…" | **Muslim USC 6572**; **Qudsi 17** | local corpus |
| Al-Hadi 1510 | "These are not the words of a poet" | **Q69:41** | api.quran.com |
| Al-Qabid 1545 | "I don't fear poverty for you — I fear that the dunya will be opened up…" | **Ibn Majah 3997** (Sahih, Agreed Upon) | local corpus |
| Al-Qabid 1547 | "Sometimes here, sometimes there" (Hanzala) | **Tirmidhi 2514** (Sahih) — *"There is a time for this and a time for that"* | local corpus |
| Al-Muqaddim 1582 | "Your rizq chases you the way death chases you" | **Hilyat al-Awliya'** via Jabir; Albani: Hasan | web retrieval (not in the 9 editions) |
| Al-Wahhab 1658 | "O Allah, do not leave me alone" / "Rabbi hab li" | **Q21:89**, **Q3:38** | api.quran.com |
| Ar-Raheem 1700, 1702 | "O My servants who have exceeded the limits…" / Adam's repentance | **Q39:53**, **Q2:37** | api.quran.com |
| Al-Malik 1729 | "I am the King: where are the kings of the earth?" | **Bukhari 4812**; **Ibn Majah 192** (Sahih) | local corpus |
| Al-Mutakabbir 1885 | "Pride is disdaining the truth … and contempt for the people" | **Muslim USC 265** (file cites *Sahih Muslim 91a* — correct) | local corpus |
| Al-Azeem 2152 | "Lā ilāha illā Allāh al-ʿAẓīm al-Ḥalīm…" | **Bukhari 7431** (= 6346) | local corpus |
| Al-Muhsi 2474 | "Why have you testified against us?" / "We have been made to speak by Allah" | **Q41:21** | api.quran.com |
| Al-Mumeet 2568 | "The eyes shed tears and the heart grieves…" | **Bukhari 1303** | local corpus |
| Al-Wajid 2589 / Ar-Rasheed 2939 | "Did He not find you as an orphan then sheltered you?" / "And He found you lost and guided you" | **Q93:6–7** | api.quran.com |
| Al-Qadir 2614 | "O Allah, if this small band perishes today…" | **Muslim USC 4588 (=1763)** | local corpus |
| Dhul-Jalal 2729 | "Allahumma inni as'aluka bi-anna laka al-hamd… al-Mannan…" + "the Greatest Name" | **Ibn Majah 3858** (Hasan Sahih); **Tirmidhi 3544** (Sahih) | local corpus |
| Al-Muqsit 2750 | "Ya ʿibadi, inni harramtu az-zulma ʿala nafsi…" | **Muslim USC 6572**; **Qudsi 17**; **Nawawi 24** (file's own citation to Sahih Muslim is correct) | local corpus |
| Al-Muqsit 2752 | Farewell sermon: "your blood, your property, and your honour are sacred…" | **Ibn Majah 3055** (Sahih) (= Bukhari 67) | local corpus |
| Al-Ghaniyy 2775 | "O My servants, all of you are astray…" | **Muslim USC 6572**; **Qudsi 17** | local corpus |
| Al-Mughni 2798 | "Wealth is not in having many possessions…" | **Tirmidhi 2373** (= Bukhari 6446) | local corpus |
| An-Nafi 2867 | "Whoever fulfilled the needs of his brother, Allah will fulfill his needs" | **Bukhari 2442**; **Tirmidhi 1426** | local corpus |
| Al-Baqi 2916 | Khabbab: the ditch and the saw; "By Allah, this religion will be perfected…" | **Bukhari 3612** | local corpus |
| Al-Badi 2891 | "Be! And it is" | **Q2:117**, **Q6:101** | api.quran.com (root check) |

(Qur'an keys fetched verbatim and confirmed: 2:37, 2:186, 7:96, 8:30, 14:42, 19:7, 19:9, 21:89, 24:22, 35:2, 39:53, 48:1, 54:11, 69:41, 93:7, 96:3, 3:38.)

---

## 4. Coverage statement — be precise about this

**Extraction: 100% of the list.** All 100 entries, both prose fields, lines 86 → 2939, were parsed, de-escaped, quote-scanned (twice, after the apostrophe bug) and attribution-filtered. No entry was skipped at the scanning stage.

**Verification depth — two tiers:**

- **TIER 1 — every divine/prophetic quotation individually sourced (entries 0–47, lines 86 → 1686).** These are the Omar Suleiman "The Dua I Need" entries and the Mikaeel Smith "The Name I Need" entries. This is the narrative-heavy half of the file — long uncited stories, hadith retold from memory — and it is where **all 12 of the confirmed findings live**. Entries: Ar-Rahman, Al-Wahid/Al-Ahad, Al-Hadi/An-Nur, Ar-Rabb (179), Al-Ghaffar/Al-Ghafoor/At-Tawwab, As-Sami'/Al-Qarib/Al-Mujib, Al-Basir/Ash-Shahid, Al-Ghani/Al-Fattah, Al-'Alim/Al-Hakim/Al-Latif, Al-Qahhar/Al-Jabbar, Al-'Adl/Al-Hakam/Al-Hasib, Ash-Shafi, As-Sabur/Al-Halim, Al-Awwal/Al-Akhir/Az-Zahir/Al-Batin, Al-Wadud (515), Al-'Afuw (546), Al-Wakil (577), Al-Jami', Al-Karim/Al-Wahhab, Al-Hayy/Al-Qayyum, As-Samad, Al-Wali, Al-'Ali/Al-'Azim/Al-Majid, As-Salam/Al-Quddus, Al-Qawi/Al-Matin, Al-'Ali/Al-Muta'ali, Al-Dhahir & Al-Batin, Al-Ghani (917), Al-Mu'izz & Al-Mudhil, Al-Jabbar (989), An-Nasir, Ar-Rabb (1060), Ar-Razzaq, Al-Qarib/Al-Mujib (1132), As-Salam (1169), An-Nur (1206), Al-'Afuww (1243), Al-Karim (1279), Al-Fattah (1311), Al-Shakur (1345), Al-Wakil (1382), Al-Wadud (1417), At-Tawwab (1454), Al-Hadi (1491), Al-Qabid & Al-Basit, Al-Muqaddim & Al-Mu'akhkhir, Al-Latif (1602), Al-Wahhab (1639).

- **TIER 2 — prophetic quotations individually sourced; Qur'an citations spot-checked, not exhaustively re-fetched (entries 48–99, lines 1688 → 2939).** From `Ar-Raheem` (1688) through `Ar-Rasheed` (2926). These entries have a completely different construction: they are overwhelmingly Qur'an quotations that **carry their own surah:ayah citation inline** (`Quran 11:57`, `Quran 4:85`, `Sūrat al-Raḥmān`, …), often with the transliterated Arabic alongside the translation. I verified **every** quotation in this block that is attributed to the Prophet ﷺ (Al-Malik 1729, Al-Azeez 1783, Al-Mutakabbir 1885, Al-Azeem 2152, Al-Mumeet 2568, Al-Qadir 2614, Dhul-Jalali 2727/2729, Al-Muqsit 2752, Al-Ghaniyy 2775, Al-Mughni 2798, Al-Mani 2821, Ad-Darr 2844, An-Nafi 2867, Al-Baqi 2916, Ar-Rasheed 2939) — two of the findings above (Al-Azeez 1783, Al-Mani 2821) come from this pass. I did **not** re-fetch every one of the ~110 Qur'anic citations in this block one at a time; I fetched a 17-key sample plus every key implicated in a suspicion.

**What I did NOT reach:** no entry was skipped. The honest gap is the **un-refetched Qur'an citations in entries 48–99** — roughly 110 inline `Quran x:y` claims where I trusted the file's own citation rather than fetching. That is the one place a wrong verse number or a drifting translation could still be hiding. It is a *lower-risk* class than the P0 class you asked for (the citation is present and checkable, and the surrounding prose does not invent divine dialogue), but it is not zero.

---

## 5. Adjacent things I noticed and did NOT chase (as instructed)

- **Uncited scholar sayings in quotation marks** — a large, consistent pattern. Recorded, not chased: Imam Ahmad ("A sincere prayer from a pure heart", L253 — the case you named); Ibn al-Qayyim (L129 "For One, be one upon one"; L191 "flee to Allah"; L435 "I stayed in Mecca ill…"); Ibn Taymiyyah (L312 "O teacher of Ibrahim…"; L404 "Allah will sustain a just nation…"); Ibn Ata'illah (L934, L936, L1362); Ibn al-Jawzi (L934 "In the heart there is a void…"); al-Ghazali (L897); al-Nabulusi (L1259); Bilal ibn Sa'd (L1783 — **this one is properly cited**, *Hilyat al-Awliya'* 5/223); Jinan Yousef's Yaqeen papers (L1808, L1912, L1939, L2126 — cited by publication, not page).
- **`The narration says` + Iblis's direct speech** (L934: *"This creation is hollow inside. I know how to get him lost — I'll make him greedy for more."*). Not Allah or the Prophet, so out of scope, but it is direct speech attributed to an unnamed "narration" with no collection.
- **`Scholars say the angels heard his call…`** (L1151) — the frame that carries finding #7.
- **The Ta'if du'a** (L971, *"O Allah, I complain to you of my weakness…"*) — a real and famous supplication, but its chain (Ibn Ishaq / al-Tabarani) is widely graded weak. Presented with no source.
- **`The Yaqeen Ramadan series prays for Al-Muqsit: "Restore to the victims…"`** (L2750) — a modern devotional composition sitting one sentence away from a Hadith Qudsi, inside the same prose block that goes into the LLM prompt.
- **First-person testimony from Sheikh Mikaeel** (L936, L1330, L1364, L1621) in the same quoted-speech register as the hadith around it — a *prompt-injection-shaped* risk more than a citation risk: the model has no signal distinguishing "the Prophet ﷺ said" from "Sheikh Mikaeel reflects" when both are `'…'` in the same paragraph.
- **One located-but-weak prophetic quote:** L648 *"Indeed Allah is Jawad and He loves generosity"* — **Tirmidhi 2799, graded Da'if by all four graders in the corpus**, and mawquf to Sa'id b. al-Musayyab in the main chain. Presented as `The Prophet ﷺ said`.

---

## 6. Limits of this method — stated plainly

1. **I did not reach a corpus genuinely independent of sunnah.com.** The `fawazahmed0/hadith-api` editions are derived from sunnah.com's English texts; the 40 Qudsi and Nawawi 40 sets likewise. My web retrievals (Musnad Ahmad, Adab al-Mufrad, al-Nasa'i's Kubra, Hilyat al-Awliya') went through secondary English-language sites, not manuscript or printed critical editions. **For a "located" verdict this is adequate; for a "not located" verdict it is a bounded negative** — I can say "not in the six books + Malik + the two forty-collections, and not surfaced by targeted retrieval", not "does not exist".
2. **I audited no isnad.** Not one. Where I report a grade it is the grade carried as metadata by the corpus (Albani / Shakir / Bashar Awad / Zubair Ali Zai / Shu'ayb al-Arna'ut), copied, not evaluated. I did not open a single chain of narration.
3. **Numbering is a trap I avoided by not using it.** The corpus uses old USC numbering, not modern sunnah.com numbering. Every match in §3 was made on **text**, and every "USC nnnn" above is the corpus's own key, not a sunnah.com reference. Do not paste those numbers into sunnah.com.
4. **Translation variance is the main false-negative risk.** Several quotes only matched on the third or fourth phrasing tried (the fever hadith surfaced only under "furnace removes the alloy of iron"; the patience hadith only by dumping Bukhari 1469 in full). A quote I marked "not located" after 4–6 phrasings could still exist under a wording I did not guess — though for findings 1, 3, 4, 8 and 9 the *primary narration itself was located and read*, and the disputed words are demonstrably absent from it. Those five are the strongest.
5. **My extractor had a real bug and it mattered.** The first single-quote pass dropped every quoted span containing an internal apostrophe. Finding #8 (`'Who am I? I can't read. I'm nobody.'`) lived exactly in that blind spot. I re-scanned and recovered 45 spans, but this is a reminder that the census in §4 is only as complete as the second regex — a quote using a delimiter pattern neither pass models could still be unseen.
6. **Rate limits:** the Wayback `available` API returned 504 and CDX throttled under load; I routed around it via the local corpus and direct web retrieval rather than retrying into a wall. No sunnah.com page was fetched directly (it 403s automation).

# Blind adversarial verdict — batch `power`

**Decks:** `2026-08-03-al-qawiyy-DRAFT.md` (id 62, Al-Qawiyy) · `2026-08-03-al-mateen-DRAFT.md` (id 63,
Al-Mateen) · `2026-08-03-al-qahhar-DRAFT.md` (id 22, Al-Qahhar) · `2026-08-03-al-mutakabbir-DRAFT.md`
(id 19, Al-Mutakabbir).

**Method.** Every scriptural, ḥadīth and catalogue claim below was fetched live in this session —
Qur'an via `api.quran.com/api/v4`, ḥadīth via `web.archive.org` raw captures of the exact `sunnah.com`
pages the drafts cite, root sweeps via `corpus.quran.com/qurandictionary.jsp`, catalogue fields by
direct `python3 -c "json.load(...)"` reads of `assets/content/collectible_names.json` and
`assets/content/name_stories.json` (**45 decks**, counted directly, not taken from any draft's stated
figure). Nothing below is asserted from a draft's table without an independent fetch beside it.

---

## 1 · Citation table — every fetch, what it actually returned

### Qur'an — the two flagged translation defects (brief item 2)

| claim | fetched key | text returned | ✅/⚠️/❌ |
|---|---|---|---|
| `al-mateen@1` beat 6, "We created the heavens and the earth and all that is between them in six days, and no weariness even touched Us." attributed to Usmani (`translations=84`) | `50:38?translations=20,84,85,19,22` | translations=84: **"We created the heavens and the earth and all that is between them in six days, and no weariness even touched Us."** — exact character match | ✅ **verbatim, single translation, correctly named. R1 fix is real and correct.** |
| `al-qawiyy@1` beat 6, "…then created weakness and old age after strength…" attributed to Usmani (`translations=84`); Saheeh's own "white hair" avoided | `30:54?translations=20,84,85,19,22` | translations=84: **"Allah is the One who created you in a state of weakness, then He created strength after weakness, then created weakness and old age after strength. He creates what He wills, and He is All-Knowing, All-Powerful."** — deck's excerpt is this string up to "after strength", visible ellipsis, then cut | ✅ **verbatim up to the cut, single translation, correctly named. Trailing `يَخْلُقُ مَا يَشَآءُ ۖ وَهُوَ ٱلْعَلِيمُ ٱلْقَدِيرُ` (Al-Aleem/Al-Qadeer) confirmed dropped.** |

Both R1 fixes hold up under independent re-derivation. Neither is a splice; both name the translation
that agrees and quote it exactly to the cut point.

### Qur'an — Al-Qahhar, Sūrat al-Fīl in full (brief item 3)

| verse | fetched Arabic | fetched Saheeh (20) | deck's rendering | ✅/⚠️/❌ |
|---|---|---|---|---|
| 105:1 | أَلَمْ تَرَ كَيْفَ فَعَلَ رَبُّكَ بِأَصْحَـٰبِ ٱلْفِيلِ | "Have you not considered, [O Muḥammad], how your Lord dealt with the companions of the elephant?" | "Have you not considered how your Lord dealt with the companions of the elephant?" | ✅ verbatim (editorial bracket dropped, standard convention) |
| 105:2 | أَلَمْ يَجْعَلْ كَيْدَهُمْ فِى تَضْلِيلٍ | "Did He not make their plan into misguidance?" | matches | ✅ |
| 105:3 | وَأَرْسَلَ عَلَيْهِمْ طَيْرًا أَبَابِيلَ | "And He sent against them birds in flocks," | matches | ✅ |
| 105:4 | تَرْمِيهِم بِحِجَارَةٍ مِّن سِجِّيلٍ | "Striking them with stones of hard clay," | matches | ✅ |
| 105:5 | فَجَعَلَهُمْ كَعَصْفٍ مَّأْكُولٍۭ | "And He made them like eaten straw." | matches | ✅ |
| 105:6 | — | **HTTP 404** | claimed sūrah-final | ✅ confirmed — Sūrat al-Fīl is 5 āyāt, the whole sūrah is rendered |
| 104:9 (preceding sūrah) | فِى عَمَدٍ مُّمَدَّدَةٍۭ | "In extended columns" | disclosed as "unrelated content" | ⚠️ **understated** — 104:6–9 is explicit Hellfire imagery (fetched: "the fire of Allāh, eternally fueled... mounts directed at the hearts... closed down upon them, in extended columns"). It's a different sūrah/topic, correctly not part of Sūrat al-Fīl's own discourse, but it sits **immediately before** the excerpt in the muṣḥaf and is stronger than the deck's one-line dismissal suggests. Not blocking on its own — recorded because the deck's disclosure undersold it. |

**Ruling on bar 5, independently: CONTESTED, not a clean pass.** The excerpt is verbatim, complete
(the whole sūrah), sūrah-final, and the punishment lands entirely on a named-by-deed external
aggressor, never the reader — the deck's argument for why this differs from an eschatological
Fire/Judgment passage is sound as far as it goes. But the content itself is a graphic, visceral
annihilation scene (an army crushed by aerial bombardment, reduced to "eaten straw") rendered at full
strength for a user in acute distress at 11pm, and — the deck discloses this itself, credit where due
— **another agent, on this exact project, independently fetched this exact passage for a different
Name and called it "a punishment narrative. Refused on bar 5."** That is in-project precedent against
shipping this text, not manufactured by me. The "it's softer than Firʿawn/Thamūd" argument is true but
is comparing to the wrong bar — the standing question is whether *any* graphic-destruction narrative
belongs on this specific screen, not whether this one is the worst available. **I do not rule this a
FAIL outright** — the counter-argument (protected-party framing, historical rather than eschatological,
complete sūrah, no address to "you") is real and well-supported by fetch — but I will not rule it a
clean PASS either. A founder should read beats 2–4 once, specifically imagining a distressed reader,
before signing.

### Qur'an — Al-Qahhar's verse beat, 6:18, and the trailing pair (brief item 3)

| | fetched | ✅/⚠️/❌ |
|---|---|---|
| 6:18 full | `وَهُوَ ٱلْقَاهِرُ فَوْقَ عِبَادِهِۦ ۚ وَهُوَ ٱلْحَكِيمُ ٱلْخَبِيرُ` / "And He is the subjugator over His servants. And He is the Wise, the Aware." | deck renders only "And He is the subjugator over His servants…" — trailing `ٱلْحَكِيمُ ٱلْخَبِيرُ` **confirmed dropped** |
| id 26 | `collectible_names.json` id 26 = Al-Hakeem, `الْحَكِيمُ`, "The All-Wise" | ✅ confirms trailing word belongs to a pending id, correctly unrendered |
| id 49 | `collectible_names.json` id 49 = Al-Khabeer, `الْخَبِيرُ`, "The All-Aware" | ✅ same |
| 6:17 (n−1) | "And if Allāh should touch you with adversity, there is no remover of it except Him. And if He touches you with good — then He is over all things competent." | ✅ clean, matches deck's claim |
| 6:19 (n+1) | tawḥīd declaration, no partners, no punishment | ✅ clean, matches deck's claim |

Bar 1/4/5 for the verse beat itself: **PASS, independently confirmed.**

### Qur'an — Al-Mutakabbir, 7:11–7:18 in full (brief item 4)

| verse | fetched Saheeh (20) | on a beat? |
|---|---|---|
| 7:11 | angels commanded to prostrate to Adam; Iblīs refuses | beat 2, paraphrased, ✅ |
| 7:12 | "I am better than him. You created me from fire and created him from clay." | beat 3, ✅ verbatim |
| 7:13 | "Descend from it, for it is not for you to be arrogant therein. So get out; indeed, you are of the debased." | beat 4 quotes only "…it is not for you to be arrogant therein…" verbatim, ✅; **paraphrases** the expulsion clause ("he was told to leave") and **does not render "debased."** |
| 7:14 | Iblīs requests reprieve | not rendered |
| 7:15 | reprieve granted | not rendered |
| 7:16–17 | Iblīs vows to attack humanity from every side | not rendered |
| 7:18 | "Depart from it, reproached and expelled. Whoever follows you among them — I will surely fill Hell with you, all together." | not rendered — **5 āyāt past the excerpt's end** |

**Ruling on bar 5, independently: CONTESTED.** 7:13 itself — the āyah the deck does quote from — is
already a divine rebuke-and-expulsion: Allah's direct second-person speech commanding a specific being
to leave, "you are of the debased." The bar-5 language in the brief reads *"No rebuke passages…no
accusation of the reader"* — if "no rebuke passages" is a categorical rule, this excerpt fails it on
its face, addressee notwithstanding; if it means "no rebuke **of the reader**," the excerpt passes,
because every second-person verb in the quoted clause is grammatically `لَكَ`/`فِيهَا` to Iblīs, never
to "you" the reader, and the takeaway's only imperative energy points outward ("nothing posturing as
bigger than you tonight has ever outranked that"). **I read the rule the second way and rule this a
narrow PASS**, but it is genuinely closer to the line than `al-qahhar@1`'s own residual risk, and the
deck's own author says so in the clearest terms I've seen a drafter use in this project ("I am
recording this as the harder of the two decks in this pair on the reverence question"). The 5-āyah
buffer before the explicit Hell threat (7:18) is real and does the work the deck claims it does — it
is not adjacent, not alluded to, not quoted.

### Corpus sweep — م-ت-ن (brief item 6)

```
corpus.quran.com/qurandictionary.jsp?q=mtn
"The triliteral root mīm tā nūn (م ت ن) occurs three times in the Quran as the nominal matīn (مَتِين)."
  (7:183:5) matīnun — وَأُمْلِى لَهُمْ ۚ إِنَّ كَيْدِى مَتِينٌ
  (68:45:5) matīnun — وَأُمْلِى لَهُمْ ۚ إِنَّ كَيْدِى مَتِينٌ
  (51:58:7) l-matīnu — إِنَّ ٱللَّهَ هُوَ ٱلرَّزَّاقُ ذُو ٱلْقُوَّةِ ٱلْمَتِينُ
```

**Confirmed exactly: 3 occurrences, matching the deck's claim precisely** (7:183, 68:45, 51:58 — same
three, same rejections: 7:183/68:45 sit inside `سَنَسْتَدْرِجُهُم` entrapment-of-deniers passages, and
51:58 puts the epithet in the same clause as `ٱلرَّزَّاقُ`, shipped `ar-razzaq@1`). **Bar 4's total
trade for `al-mateen@1` is genuinely forced — ruled PASS on "forced," independently re-derived, not
taken from the table.**

### Corpus sweep — ك-ب-ر, cross-check of Al-Mutakabbir's root claims

Fetched `corpus.quran.com/qurandictionary.jsp?q=kbr` in full. Confirms, independently:
- **161 total occurrences**, 18 derived forms, matching the deck's stated total.
- **Form-V verb (`تَتَكَبَّرَ`/`يَتَكَبَّرُونَ`) occurs exactly twice**: 7:13 and 7:146. Matches.
- **Noun `كِبْرِيَآء` occurs exactly twice**: 10:78 and 45:37. Matches.
- **The adjectival form `ٱلْمُتَكَبِّرُ`** (singular, definite, referring to Allah) occurs **exactly
  once**, at 59:23 — confirmed by corpus's own listing under "Active participle (form V) — (2)
  Adjective: (59:23:15) l-mutakabiru 'the Supreme'". The other 6 form-V active-participle occurrences
  are the **plural noun** `ٱلْمُتَكَبِّرِينَ` ("the arrogant ones," condemned to Hell — 16:29, 39:60,
  39:72, 40:27, 40:35, 40:76), a different word. **The deck's "occurs EXACTLY ONCE" claim is precise
  and correct, not a rounding of a messier reality.**
- **59:23 fetched directly**: `... ٱلْعَزِيزُ ٱلْجَبَّارُ ٱلْمُتَكَبِّرُ` — confirmed a nine-Name chain,
  `ٱلْجَبَّارُ` (Al-Jabbar, shipped) immediately preceding. Confirmed unusable, as claimed.

**Bar 1/4 for `al-mutakabbir@1`: PASS, independently re-derived — this is the one deck in the batch
where the root sweep leaves no daylight for a verifier to attack.**

### ⚠️ New defect found, not disclosed by any draft — Al-Mutakabbir beat 5 (45:37) is not verbatim any published translation

| | text |
|---|---|
| deck beat 5 | "And to Him belongs all greatness in the heavens and the earth…" |
| 45:37 Arabic | `وَلَهُ ٱلْكِبْرِيَآءُ فِى ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ ۖ وَهُوَ ٱلْعَزِيزُ ٱلْحَكِيمُ` |
| Saheeh (20) | "And to Him belongs [all] **grandeur within** the heavens and the earth, and He is the Exalted in Might, the Wise." |
| Usmani (84) | "And to Him belongs **majesty in** the heavens and the earth. And He is the Mighty, the Wise." |
| Abdel Haleem (85) | "True **greatness** in the heavens and the earth is rightfully His: He is the Mighty, the Wise." |
| Pickthall (19) | "And unto Him (alone) belongeth **Majesty** in the heavens and the earth…" |
| Yusuf Ali (22) | "To Him be **glory** throughout the heavens and the earth…" |
| Maududi (95) | "His is the **glory** in the heavens and the earth." |
| Hilali-Khan (203) | "And His (Alone) is the **Majesty** in the heavens and the earth…" |

**None of the seven standard translations reads "And to Him belongs all greatness in the heavens and
the earth."** The deck's sentence takes Saheeh's opening ("And to Him belongs") and closing ("in the
heavens and the earth" — actually closer to Usmani/Pickthall/Hilali's "in," not Saheeh's "within") and
inserts Abdel Haleem's word choice ("greatness") into a sentence structure none of the seven actually
uses. This is the exact failure shape named in the brief's §9bh/§9bj — **an unattributed re-rendering,
not a named verbatim translation, and it was not caught or disclosed by either the R0 or R1 pass that
caught the other two translation defects in this same batch.** The claim table for this deck (item 4)
marks it "✅ verified" without naming which translation it verified against — because none matches.
**This is the third translation-fidelity defect in this batch, and the only one still live.**

### Ḥadīth — every page fetched, Arabic and grade read directly

**Bukhārī 43** (`web.archive.org/web/2024id_/https://sunnah.com/bukhari:43`) — Book 2, كتاب الإيمان
(Belief), Chapter 32.
> **Arabic (matn), quoted in full from the fetch:**
> `حَدَّثَنَا مُحَمَّدُ بْنُ الْمُثَنَّى، حَدَّثَنَا يَحْيَى، عَنْ هِشَامٍ، قَالَ أَخْبَرَنِي أَبِي، عَنْ عَائِشَةَ، أَنَّ النَّبِيَّ صلى الله عليه وسلم دَخَلَ عَلَيْهَا وَعِنْدَهَا امْرَأَةٌ قَالَ ‏"‏ مَنْ هَذِهِ ‏"‏‏.‏ قَالَتْ فُلاَنَةُ‏.‏ تَذْكُرُ مِنْ صَلاَتِهَا‏.‏ قَالَ ‏"‏ مَهْ، عَلَيْكُمْ بِمَا تُطِيقُونَ، فَوَاللَّهِ لاَ يَمَلُّ اللَّهُ حَتَّى تَمَلُّوا ‏"‏‏.‏ وَكَانَ أَحَبَّ الدِّينِ إِلَيْهِ مَا دَامَ عَلَيْهِ صَاحِبُهُ‏.‏`
> **Printed grade line: none shown.** Sunnah.com does not print a separate grade line for Bukhārī or
> Muslim (they are the two collections graded ṣaḥīḥ by inclusion) — the "Grade" tab exists in the page
> chrome but renders no text for these two collections in this capture. Same for all four ḥadīth below.
> **Confirmed against the deck's own convention ("collection-level inference, no printed grade line").**
>
> Al-Mateen's beat 4 ("Take on only what you are able to sustain — for Allah does not grow weary until
> you do") is confirmed a **re-rendering of the Arabic**, not the page's own English ("Do (good) deeds
> which is within your capacity… as Allah does not get tired… but you will get tired"). The Arabic —
> `عَلَيْكُمْ بِمَا تُطِيقُونَ` (what you are able/capable of) `فَوَاللَّهِ لاَ يَمَلُّ اللَّهُ حَتَّى
> تَمَلُّوا` (Allah does not tire until you tire) — **does support the deck's rendering.** Not a
> fabrication; a defensible paraphrase, and disclosed as such in the deck's own bar-1 row rather than
> mis-cited as the page's published English.

**Bukhārī 6610** (`.../bukhari:6610`) — Book 82, **كتاب القدر** (Divine Will / al-Qadar), Chapter 7,
"La ḥawla wa lā quwwata illā billāh."
> **Arabic, quoted in full:**
> `حَدَّثَنِي مُحَمَّدُ بْنُ مُقَاتِلٍ أَبُو الْحَسَنِ، أَخْبَرَنَا عَبْدُ اللَّهِ، أَخْبَرَنَا خَالِدٌ الْحَذَّاءُ، عَنْ أَبِي عُثْمَانَ النَّهْدِيِّ، عَنْ أَبِي مُوسَى، قَالَ كُنَّا مَعَ رَسُولِ اللَّهِ صلى الله عليه وسلم فِي غَزَاةٍ فَجَعَلْنَا لاَ نَصْعَدُ شَرَفًا، وَلاَ نَعْلُو شَرَفًا، وَلاَ نَهْبِطُ فِي وَادٍ، إِلاَّ رَفَعْنَا أَصْوَاتَنَا بِالتَّكْبِيرِ ـ قَالَ ـ فَدَنَا مِنَّا رَسُولُ اللَّهِ صلى الله عليه وسلم فَقَالَ ‏"‏ يَا أَيُّهَا النَّاسُ ارْبَعُوا عَلَى أَنْفُسِكُمْ فَإِنَّكُمْ لاَ تَدْعُونَ أَصَمَّ وَلاَ غَائِبًا إِنَّمَا تَدْعُونَ سَمِيعًا بَصِيرًا ‏"‏‏.‏ ثُمَّ قَالَ ‏"‏ يَا عَبْدَ اللَّهِ بْنَ قَيْسٍ، أَلاَ أُعَلِّمُكَ كَلِمَةً هِيَ مِنْ كُنُوزِ الْجَنَّةِ، لاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ ‏"‏‏.‏`
> **Printed grade line: none** (as above).
> **Confirmed exactly against `al-qawiyy@1`'s claim table** — every quoted fragment on beats 3–5
> present and accurate, the elided continuation (`إِنَّمَا تَدْعُونَ سَمِيعًا بَصِيرًا`) confirmed
> genuinely dropped from beat 4.
>
> ⚠️ **Defect: the deck's own book-heading claim is wrong.** `al-qawiyy@1`'s Register section states
> the chapter is `كتاب الأدب` ("the chapter concerns manners toward the caller"). **The fetched page
> gives the book as `كتاب القدر`, Book 82, "Divine Will (Al-Qadar)"**, chapter "La ḥawla wa lā quwwata
> illā billāh" — not Al-Adab (Book of Manners) at all. This is a factual citation error, independently
> caught by fetching rather than trusting the table. It does not affect any rendered beat (book
> headings are never shown to a user), but it is exactly the kind of unverified assertion the brief
> warns against, and it slightly undercuts the deck's "disclosed, not concealed" evidentiary case for
> why the ḥadīth's military setting (`فِي غَزَاةٍ`, confirmed present) is non-blocking.

**Bukhārī 6384** (`.../bukhari:6384`) — Book 80, كتاب الدعوات (Invocations), Chapter 50.
> **Arabic, the relevant clause, confirmed:**
> `‏...‏ فَقَالَ ‏"‏ يَا عَبْدَ اللَّهِ بْنَ قَيْسٍ قُلْ لاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ فَإِنَّهَا‏.‏ كَنْزٌ مِنْ كُنُوزِ الْجَنَّةِ ‏"‏‏.‏ أَوْ قَالَ ‏"‏ أَلاَ أَدُلُّكَ عَلَى كَلِمَةٍ هِيَ كَنْزٌ مِنْ كُنُوزِ الْجَنَّةِ، لاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ ‏"‏‏.‏`
> **Printed grade line: none.** **Confirmed carries the narrator's `أَوْ قَالَ` (shakk) exactly as
> both decks claim.** Correctly excluded from every beat in both drafts.

**Sahih Muslim 385** (`.../muslim:385`) — Book 4, كتاب الصلاة (Prayers), Chapter 7 (adhān response).
> **Arabic, the relevant clause:** `... ثُمَّ قَالَ حَىَّ عَلَى الصَّلاَةِ ‏.‏ قَالَ لاَ حَوْلَ وَلاَ
> قُوَّةَ إِلاَّ بِاللَّهِ ‏.‏` — "There is no might and no power except with Allah," said in response to
> "Come to prayer." **Printed grade line: none.** **Confirmed matches the deck's characterization**
> exactly ("the adhān-response ḥadīth"), and confirmed **not used on any beat** in either draft.

### Catalogue — `collectible_names.json`, byte-for-byte checks

| id | field | value | matches deck's claim? |
|---|---|---|---|
| 62 | `english` | "The Strong" | ✅ matches `al-qawiyy@1` beat 2 |
| 63 | `english` | "The Firm" | ✅ matches `al-mateen@1` beat 2 |
| 22 | `english` | "The Subduer" | ✅ matches `al-qahhar@1` beat 1 |
| 19 | `english` | "The Supreme" | ✅ matches `al-mutakabbir@1` beat 1 |
| 62, 63 | `dua_arabic`/`transliteration`/`translation` | `لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ` / … / "There is no power and no strength except through Allah, the Most High, the Most Magnificent." | ✅ byte-identical across both ids, byte-identical to both decks' beat 7 |
| 19, 22 | `dua_arabic`/`transliteration`/`translation` | `يَا قَهَّارُ اقْهَرْ كُلَّ جَبَّارٍ عَنِيدٍ وَيَا جَبَّارُ اجْبُرْ كَسْرِي` / … / "O Subduer, subdue every stubborn tyrant. O Compeller-Healer, mend my brokenness." | ✅ byte-identical across both ids, byte-identical to both decks' beat 6 |
| 9 (Al-Jabbar, shipped) | `dua_arabic`/`translation` | `يَا جَبَّارُ اجْبُرْ كَسْرِي` / "O Compeller, mend my brokenness." | ✅ **confirmed the collision claim** — ids 19/22's duʿā embeds id 9's entire `dua_arabic` verbatim as its own closing clause, and the English "mend my brokenness" is byte-identical to shipped `al-jabbar@1`'s own duʿā beat |
| 19, 22 | `dua`-beat `source` in both drafts | `""` (empty) | ✅ **both decks correctly render an empty `source` and mark UNPINNED** — this is honest disclosure of an unpinned catalogue-authored composite, not the "unpinned deck growing a citation" fabrication shape the brief warns about. The catalogue text is inherited, not authored by either drafter, and neither drafter invents a source for it. |

### Shipped ground, read directly — `al-azeez@1`, `al-jabbar@1`

Both read in full from `assets/content/name_stories.json`. `al-azeez@1`'s engine ("a third messenger
added, not agreement gained" — 36:13–14) and `al-jabbar@1`'s engine (Yaʿqūb's grief mended by Yūsuf's
shirt — 12:84–96) share no citation, no root, and no rendered n-gram ≥3 with any of the four `power`
decks, confirmed by direct read. The only real link to either shipped deck is the confirmed duʿā
collision with `al-jabbar@1` above — not a story/verse/move collision.

---

## 2 · Five-bars verdicts

### `al-qawiyy@1` (id 62)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | Bukhārī 6610's own matn, undoubted route (no shakk), Allah's own root `قُوَّةَ` inside the taught sentence — confirmed by fetch |
| 2 | **PASS** | a specific correction of a specific group, narrated, not asserted |
| 3 | **CONTESTED** — see §3 below | twin-collapse risk against `al-mateen@1`, plus a new, previously undisclosed near-collision against shipped `al-kareem@1` (§3) |
| 4 | **PASS** | root `قُوَّةَ` renders on 3 beats (story matn, verse, duʿā Arabic) |
| 5 | **PASS, with a caught factual error** | no beat renders battle/punishment content; the deck's own supporting claim about 6610's book heading (`كتاب الأدب`) is **wrong** — confirmed `كتاب القدر` — corrected in §1 |

**Ship/no-ship: SHIP WITH FIXES.** Fix the book-heading misstatement (delete or correct it — it isn't
load-bearing for the register argument, which stands without it, since `فِي غَزَاةٍ` is independently
confirmed and the shipped-precedent argument doesn't depend on the book title). Address the §3
sibling-collapse finding, at minimum by rewording the pair-synergy takeaway (beat 8) so it does not
use near-interchangeable vocabulary with `al-mateen@1`'s own beat 8. Author a `reflection` beat before
this reaches the personalised tier (self-disclosed gap, not new).

### `al-mateen@1` (id 63)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | Bukhārī 43's finite negative verb (`لاَ يَمَلُّ`), Allah the explicit subject, confirmed Arabic supports the beat's re-rendering; 50:38's first-person plural, confirmed verbatim Usmani |
| 2 | **PASS** | a specific correction with a stated, specific reason |
| 3 | **CONTESTED** — see §3 | same twin/al-kareem@1 finding as the twin |
| 4 | **PASS, honestly at zero** | م-ت-ن occurs exactly 3 times in the whole Qur'an, all three independently confirmed rejected on other bars; the deck states its own bar-4 score as zero rather than softening it — this candor is itself worth crediting |
| 5 | **PASS** | 50:38 is not sūrah-final but its immediate neighbours are clean (fetched 50:37, 50:39); the same-theme rejects (46:33, 50:15) are cited from the ledger and from a live fetch of 50:12–15's refrain, not independently re-fetched by me — see limits |

**Ship/no-ship: SHIP WITH FIXES.** Same §3 sibling-collapse fix as the twin. The zero-bar-4 outcome is
a real, disclosed trade the founder should sign off on consciously — the deck already asks for this
explicitly and I have no grounds to overrule it; it is the correct call given the enumeration. Reflection
beat needed.

### `al-qahhar@1` (id 22)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | 6:18's `ٱلْقَاهِرُ فَوْقَ عِبَادِهِۦ` — an independent clause's whole predicate, Allah's own third-person narration, not a trailing epithet — confirmed by fetch |
| 2 | **PASS on the story** | the story shows via a five-clause narrative, no editorializing |
| 3 | **PASS** | independently re-grepped "tyrant/elephant/subdue/arrogan/greatness/debased/birds" against the 45-deck shipped asset — matches the deck's own findings exactly (zero hits except `arrogan*` in `al-khafid@1`'s duʿā and `birds` in `ar-razzaq@1`/`al-qadir@1`, both correctly ruled non-blocking, different jobs) |
| 4 | **PASS** | root on the verse beat (`ٱلْقَاهِرُ`); story is a disclosed bar-4 trade |
| 5 | **CONTESTED — the central finding of this report** | see §1's full ruling above. Not a clean pass; not a flat fail |

**Ship/no-ship: HOLD FOR EXPLICIT FOUNDER SIGN-OFF ON BAR 5**, specifically because a different agent
on this same project independently reached and refused this exact passage for a different Name. That
is not dispositive against this deck — the deck's relevance argument (its whole purpose is this
demonstration; the other deck's wasn't) is real — but it is exactly the kind of disagreement the
protocol wants surfaced, not silently overridden. If shipped, still needs a `reflection` beat.

### `al-mutakabbir@1` (id 19)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS, strongest form available** | 7:13's finite verb `تَتَكَبَّرَ` in Allah's own direct speech; 45:37's `ٱلْكِبْرِيَآءُ` in Allah's own third-person declaration — confirmed both, and confirmed by corpus sweep that no stronger candidate exists anywhere in the Qur'an |
| 2 | **PASS** | demonstration by refusal, not assertion |
| 3 | **CONTESTED** | the duʿā collision with shipped `al-jabbar@1` is real and confirmed (§1); the move-adjacency to `al-muzill@1` is disclosed but not independently verified by me (see limits) |
| 4 | **PASS, forced and maximal** | confirmed by corpus sweep: exactly one usable verb occurrence (7:13), exactly one usable noun occurrence (45:37), zero fallback candidates for either |
| 5 | **CONTESTED, narrow PASS on my own reading** | 7:13 is itself a rebuke-and-expulsion clause; passes only if "no rebuke passages" is read as "no rebuke **of the reader**" — see §1's full reasoning. The deck's own author calls this the harder of the two decks in the pair, and I agree with that self-assessment |
| — | **NEW DEFECT** | beat 5 (45:37) is not verbatim any of 7 standard published translations — an unattributed splice, see §1. **This must be fixed before ship.** |

**Ship/no-ship: HOLD.** The translation-verbatim defect on beat 5 is a straightforward, mechanical fix
(quote Usmani's "And to Him belongs majesty in the heavens and the earth" verbatim, or find a
translation that actually says "greatness… in the heavens and the earth" and name it) and should block
shipping until corrected — this is precisely the failure class the brief opens with. Bar 5 is a narrower
call than `al-qahhar@1`'s and I lean toward accepting it, but a founder should read §1's reasoning
directly rather than take my lean as a verdict. Reflection beat needed.

---

## 3 · Bar 3(c) — "the move," and whether Al-Qawiyy/Al-Mateen are one deck twice

**Swept against 45 decks, counted directly** (`len(data) == 45` in `assets/content/name_stories.json`,
verified by direct read, not inherited from any draft).

**Not one deck twice, but closer than either deck's own table admits.** Citation-wise they are
cleanly separate: different ḥadīth, different companions (Abū Mūsā vs. ʿĀʾisha), different collections'
numbering, different verses (30:54's human life-cycle vs. 50:38's single act of creation), and the
mechanical n-gram diff genuinely finds zero shared strings ≥4 words in the *rendered* beats — I have no
reason to doubt that count; it is a simple substring search and both files are short enough to check by
eye, which I did.

But the **thematic payload is close enough to be a real finding, not a false alarm**, on two independent
axes:

1. **Both stories are Prophetic corrections of well-meaning over-exertion in worship** — shouting takbīr
   louder (Qawiyy) vs. praying longer without rest (Mateen) — followed by the identical structural move
   in both decks: *your intensity/volume was never the mechanism; here is what actually doesn't run out.*
   That is one lesson taught through two different behavioral surfaces (loudness vs. duration), not two
   different lessons.

2. **The two decks' own official, rendered `takeaway` beats characterize each other using
   near-interchangeable language.** `al-qawiyy@1` beat 8, describing Al-Mateen: *"not a supply you could
   run out of, a foundation that was never yours to hold up."* `al-mateen@1` beat 8, describing Al-Qawiyy:
   *"the one that is never depleted by being leaned on."* These two clauses could be swapped between the
   decks and no reader would notice the substitution — "a supply you could run out of" and "never
   depleted by being leaned on" are the same claim in different words. This is exactly the kind of thing
   a mechanical n-gram diff cannot catch (different words, same content) and exactly what bar 3(c) exists
   to catch instead.

**A third, previously undisclosed finding, from directly grepping the shipped asset rather than trusting
either draft's token table:** shipped `al-kareem@1`'s own takeaway reads *"You are not drawing on a
supply that runs down. The One being asked is Free of need — the asking costs Him nothing at all."*
Neither draft's bar-3(b) sweep searched the token "supply" — both searched "power," "weak(ness)," and
"sustain/capacity" but not the word both of their *own* unrendered "Read as a user at 11pm" sections
independently reach for ("running on… the same supply" / "not a supply you could run out of"). Al-Kareem's
theme (generosity costs nothing) and this pair's theme (effort doesn't generate the outcome) are
genuinely different arguments, so I am not calling this a hard bar-3 collision — but three Names now
converging on the identical "inexhaustible supply" metaphor, one of them shipped, is worth a founder's
attention, and it was not caught by either drafter's own sweep because neither searched for the word
their own prose was using.

**Verdict on the brief's explicit question: CONTESTED, not FAIL.** The four Names — Qawiyy, Mateen,
Qahhar, Mutakabbir — are cleanly separated from each other as a group of four; the risk is entirely
contained within the Qawiyy/Mateen pair, and even there it is a matter of the same lesson told through
two behaviorally-different but thematically-adjacent stories, not literal duplication. I would not block
shipping on this alone, but I would not sign off on it as "no sibling collapse, full stop" either — the
cheapest real fix is rewording the two pair-synergy takeaways (beat 8 of each) so they stop describing
each other in swappable language.

**Against shipped `al-azeez@1`/`al-jabbar@1`, per the brief's specific ask:** clean separation
confirmed by direct read of both shipped decks (§1) — no shared citation, root, or rendered n-gram
beyond the already-confirmed duʿā collision (which is a catalogue fact, not a drafting choice).

---

## 4 · Bar 3(b), measured — the integer

**45 decks**, `assets/content/name_stories.json`, counted directly via `len(json.load(...))` in this
session, matching every draft's own stated count. Not stale — I read the file fresh, not from any
draft's cached figure.

---

## 5 · Every rendered ḥadīth — printed grade line, quoted

**None of the four ḥadīth cited in this batch (Bukhārī 43, 6610, 6384; Muslim 385) prints a "Grade:"
line on its sunnah.com page.** This is expected and consistent, not a gap: sunnah.com only prints a
separate grade line for collections outside the two ṣaḥīḥayn; Bukhārī and Muslim entries carry no such
line because inclusion in either collection is itself the grading convention that site uses. I fetched
all four Wayback captures directly and read the rendered HTML body (not just the page chrome) to confirm
this rather than assume it. **Confirmed against each deck's own stated convention** ("no printed grade
line — collection-level inference").

---

## 6 · What I could not verify

1. **Al-Mateen's same-theme rejects (46:33, 50:15, 50:12–14) were fetched partially, not exhaustively.**
   I independently fetched 50:36, 50:37, 50:39, and 105/6:17-19/7:11-18/45:37-38/59:23, but did not
   re-fetch 46:33/46:34 or 50:12–15 myself — I am relying on the deck's own quoted Arabic for those,
   which I have less direct confidence in than the rows I fetched myself. A verifier with more time
   should close this gap.
2. **The move-adjacency between `al-mutakabbir@1` and `al-muzill@1`** (id 44, concurrently drafted) is
   disclosed at length in the draft but I did not read `2026-08-03-al-muzill-DRAFT.md` myself — I cannot
   independently confirm or dispute that comparison, only note that the drafter followed the project's
   own disclosure rule (§9bd) rather than self-clearing it.
3. **No isnād was audited for any of the four ḥadīth.** I confirmed the matn text and the absence of a
   printed grade line; I did not independently research the chain of narrators for any of Bukhārī
   43/6610/6384 or Muslim 385.
4. **The duʿā's "UNPINNED" status** — I did not run an exhaustive search of every duʿā/adhkār compilation
   beyond the four ḥadīth routes both decks already checked (6610, 4205, 6384, Muslim 385) for the
   `q-w-y` pair's provenance, or beyond the shared `يَا قَهَّارُ...` composite's own two halves for the
   `q-h-r`/`j-b-r` pair. I take "not found in the routes checked" at face value, not as "does not exist
   anywhere."
5. **I did not independently verify `al-jabbar@1`'s own bar-4 status** (whether its root is genuinely
   "duʿā only," as `al-qahhar@1` claims by way of justifying its own story-beat bar-4 trade as
   precedented) — I read `al-jabbar@1`'s shipped beats directly and confirmed the duʿā collision, but did
   not re-run a root sweep for `ج-ب-ر` myself.
6. **I did not run `flutter test`** or touch any gate-relevant file — read-only throughout, per the
   task's hard constraints.
7. **The 104:6–9 Hellfire-imagery finding (§1)** is a disclosure I am making at face value from one
   fetch; I did not check whether other shipped decks treat sūrah-boundary adjacency the same way, so I
   cannot say whether the project's own convention already has an answer for how much weight
   preceding-sūrah content should carry. I flag it as understated, not as blocking.

---

## Reconciliation with `2026-08-04-R2-VERIFICATION.md`

**Where I agree.** R2's §2.3/§2.4 entries for `al-mateen@1` (50:38) and `al-qawiyy@1` (30:54) match my
own independent re-derivation exactly, down to the fix chosen (Usmani, `translations=84`, named) — I
re-fetched both from scratch and got the same result, which is the strongest form of agreement this
protocol allows. R2's §3 table entry for Bukhārī 43 ("Ṣaḥīḥ, collection-level; Arabic verified
character-for-character") and its note on `al-mateen@1`'s re-rendering (`عَلَيْكُمْ بِمَا تُطِيقُونَ`)
also match what I found independently. R2's own §0 is honest about its limits — it explicitly says
bar-5 register calls and bar-1 ladder judgements are "not reliable" from this pass and that "a blind
Sonnet verifier is still owed" — and on that specific point I have nothing to disagree with; R2 correctly
declined to rule on the two hardest calls in this batch (Sūrat al-Fīl's register, 7:13's rebuke shape)
and left them for exactly this review.

**Where I disagree, and it matters.**

1. **R2 missed a real translation-fidelity defect.** R2's method claims **159 rendered quoted segments**
   were substring-matched against their cited āyah, resulting in exactly **8 defects** (§2.1–§2.9), none
   of which is `al-mutakabbir@1`'s beat 5 (45:37). I independently fetched all seven standard
   translations for 45:37 and **none reads "And to Him belongs all greatness in the heavens and the
   earth"** — the deck's rendering is an unattributed splice of Saheeh's sentence frame and Abdel
   Haleem's word choice, the exact §9bh failure R2 itself caught twice elsewhere in this same batch
   (§2.3, §2.4). **This is the single most concrete disagreement in this report**: R2's own stated
   method should have caught this and did not. I recommend re-running R2's automated substring/bracket-
   fold check specifically against 45:37 to find out why it passed — my guess, unverified, is that the
   fold-and-strip normalisation treated "greatness"/"grandeur" or "in"/"within" as equivalent when they
   are not the same word.
2. **R2's §4 claim that "no two neighbours run the same engine" does not survive contact with
   Qawiyy/Mateen's own rendered beat-8 takeaways.** R2's story-impact section is confident and
   sweeping across all 54 decks; I am not disputing the other 52, but for this pair specifically, the two
   decks' own official `takeaway` beats describe each other using language ("not a supply you could run
   out of" / "never depleted by being leaned on") that is semantically interchangeable, which R2's pass —
   focused on citation fidelity and per-deck fit, not cross-deck engine comparison at the sentence level —
   did not surface. R2's §4 table of "structurally compromised by the catalogue" decks does not include
   this pair at all; I am adding it as a softer, non-catalogue-forced finding R2's method wasn't built to
   catch.
3. **R2 never engages the `al-kareem@1` "supply" near-collision**, because R2's method (per its own §1
   table) checks Qurʾān fidelity, translation attribution, ḥadīth authenticity, locked-string bytes, and
   AI-slot safety — it has no step that greps the shipped asset for a metaphor vehicle shared across
   Names with different literal vocabulary. This is not a fault in R2's method for what it was built to
   do; it is a gap only a bar-3(c) pass like this one is positioned to find.
4. **R2 does not catch my book-heading citation error** (`al-qawiyy@1` claiming Bukhārī 6610 sits under
   `كتاب الأدب` when it is actually `كتاب القدر`) — a minor miss, consistent with R2's method targeting
   quoted-span fidelity and grade lines, not surrounding prose claims about a page's book/chapter
   metadata.
5. **On the two register calls R2 explicitly left open** (`al-qahhar@1`'s Sūrat al-Fīl, `al-mutakabbir@1`'s
   7:13), I am not overturning R2 because R2 never made a call to overturn — I am supplying the
   independent ruling R2's §0 and §4 both say is still owed. My rulings (CONTESTED on both, narrow
   leans toward accept on `al-mutakabbir@1` and toward hold-for-sign-off on `al-qahhar@1`) should be
   read as answering that open item, not as a correction to R2.

**Net effect on R2's "54 verified, 8 defects" headline.** For this batch of four, I would revise that to
**9 defects** (adding `al-mutakabbir@1`'s 45:37 splice) and would add a **10th finding that isn't a
defect but is a real gap**: the Qawiyy/Mateen pair-synergy takeaway wording. R2's "spine incomplete on
19 decks" figure is unchanged and independently confirmed for all four decks in this batch.

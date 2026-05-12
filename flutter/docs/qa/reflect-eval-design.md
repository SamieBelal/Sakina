# Reflect Name-Pick Eval

## Purpose
Detect AI Name-pick quality regressions when the system prompt changes
(Plans 1, 2, 5 in the 2026-05-11 content batch all change prompt content).

## Fixture shape
- 25 phrases spanning the emotional spectrum.
- Each phrase has an `expected_names` set (1-3 Names).
- A response PASSES the row if the returned Name is in the expected set.

## Baseline
`test/evals/reflect_name_pick_baseline.json` stores:
- `pass_rate`: float (e.g. 0.84 = 21 of 25 pass)
- `per_row_status`: array of {phrase, last_returned_name, pass}

## Update protocol
When a plan intentionally improves Name routing, run the eval, inspect failures,
update the baseline only if the failures are theologically defensible improvements.
Never update the baseline to mask a regression.

## Establishing the baseline (first run, post-Plan-0)

Requires `env.json` with a working `OPENAI_API_KEY`:

```bash
RUN_LIVE_EVALS=1 flutter test --dart-define-from-file=env.json \
  test/evals/reflect_name_pick_eval.dart
```

The runner writes `test/evals/reflect_name_pick_last_run.json`. After verifying
no demo-fallback rows fired and the per-row status looks defensible:

```bash
test -s test/evals/reflect_name_pick_last_run.json
jq '.per_row_status | length' test/evals/reflect_name_pick_last_run.json  # must print 25
cp test/evals/reflect_name_pick_last_run.json test/evals/reflect_name_pick_baseline.json
git add test/evals/reflect_name_pick_baseline.json
git commit -m "feat(evals): establish initial reflect Name-pick baseline"
```

If the runner hard-fails on demo-fallback, the API is misbehaving — fix that before
pinning a baseline. Do not paper over a flaky run.

## Scholar review of flagged rows — completed 2026-05-12

The fixture author flagged 4 rows for review. Each was cross-referenced against
authoritative Islamic sources (Yaqeen Institute, Virtual Mosque, MyIslam,
MeetQuran, Understand Quran Academy, classical tafsir summaries). Outcomes:

### 1. Illness row — REVISED ✓

**Before:** `expected_names: [Ash-Shafi, Ar-Rahman, Al-Muhyi]`
**After:** `expected_names: [Ash-Shafi, Ar-Rahman, Al-Lateef]`

**Reason:** Ash-Shafi is THE canonical Name invoked in the Prophet's healing
dua: *"Allahumma Rabb an-naas, adh-hib al-ba's, ishfi anta ash-Shafi…"*
(Bukhari, Muslim). Al-Muhyi appears in no major healing source we reviewed;
its canonical pairing with Al-Mumeet (giver of death) makes it pastorally
heavy on a fresh diagnosis. Al-Lateef ("the gentle, arranges hidden mercies")
is the classical pastoral framing for hardship — same Name used in our
hidden-wisdom row.

### 2. Jealousy row — REVISED ✓

**Before:** `expected_names: [Ar-Razzaq, Al-Hakeem, Al-Muqsit]`
**After:** `expected_names: [Ar-Razzaq, Al-Hakeem, Ash-Shakur]`

**Reason:** No source connected Al-Muqsit specifically to envy or comparison.
Al-Muqsit's classical scope is judicial / equitable distribution, not
disposition of the heart. Authoritative Islamic remedies for jealousy center
on **gratitude and contentment** ("Allahumma tahhir qalbi min al-hasad" plus
Surah Al-Falaq for protection from envy), recognition of portioned rizq
(Ar-Razzaq), and Allah's wisdom in calibration (Al-Hakeem). Ash-Shakur ("the
most appreciative") is the Name that mirrors the gratitude posture the
classical remedies prescribe.

### 3. Relationship + family-conflict rows — CONFIRMED ✓

**Kept:** Al-Jami across both rows.

**Reason:** Virtual Mosque article titled "Al-Jaami': The Uniter" explicitly
describes Al-Jami as "the One who reconciles hearts, who connects opposites
and that which is similar." Classical tafsir summaries (MyIslam, MeetQuran,
Threshold Society) all support the dual reading: gatherer of hearts now AND
gatherer on the Day of Judgment. The pastoral application to estranged
relationships and family conflict is well-established, not innovative.

### 4. Shame row — CONFIRMED ✓

**Kept:** Al-Wadud in the set with Al-Ghafur and At-Tawwab.

**Reason:** Yaqeen Institute's paper "The Meaning of Allah's Name Al-Wadūd:
Seeking The Love of Allah" makes the connection explicit: *"Feeling shame
about sin is not a barrier to Al-Wadud's love — it's often the doorway
through which it enters."* The Quran itself pairs Al-Wadud with repentance
in 11:90: *"Ask forgiveness from your Lord and repent to Him. Indeed, my Lord
is Merciful and Loving."* The fixture's "He still loves you on the worst day"
framing is canonical, not affective overreach.

### Sources consulted

- [Yaqeen Institute: The Meaning of Allah's Name Al-Wadud](https://yaqeeninstitute.org/read/paper/the-meaning-of-allahs-name-al-wadud-seeking-the-love-of-allah)
- [Virtual Mosque: Al-Jaami' - the Uniter](https://www.virtualmosque.com/relationships/withthedivine/al-jaami-the-uniter/)
- [Understand Quran Academy: Ash-Shaafee — healer's dua](https://understandquran.com/19384-2/)
- [MyIslam: Al-Muqsit](https://myislam.org/99-names-of-allah/al-muqsit/)
- [Life With Allah: Envy and Evil Eye remedies](https://lifewithallah.com/articles/ruqyah/envy-and-evil-eye/)

The baseline can now be established with confidence. If a future plan changes
any of the revised rows, re-run scholar review.

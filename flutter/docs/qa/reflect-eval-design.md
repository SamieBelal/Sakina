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

## Pending scholar review

The fixture author flagged 4 rows for scholar review before the baseline is
treated as authoritative. Confirm or revise these `expected_names` choices:

1. **Illness row — Al-Muhyi paired with Ash-Shafi.** Al-Muhyi (giver of life)
   is theologically apt for healing, but is canonically paired with Al-Mumeet
   (giver of death). On a freshly-diagnosed user the pairing may land heavily.
   Scholar may prefer **Al-Hayy** or **Al-Lateef** in place of Al-Muhyi.

2. **Jealousy row — Al-Muqsit framing "Allah's distribution is just."**
   Doctrinally correct, but Al-Muqsit is among the less idiomatic Names in
   everyday duʿā usage. Scholar may prefer **Al-Hakeem** alone.

3. **Relationship / family-conflict row — Al-Jami as "gatherer of estranged
   hearts".** The more conservative reading of Al-Jami is "gatherer on the
   Day of Judgment." Confirm the broader interpretive use is accepted in
   the content team's tafsir base.

4. **Shame row — Al-Wadud as "He still loves you".** Pastorally powerful but
   a reviewer should confirm the team is comfortable with this affective
   framing vs. a more classical mercy framing (Al-Ghafur / At-Tawwab) leading.

If any flagged row is revised, update the fixture before establishing the
baseline — not after.

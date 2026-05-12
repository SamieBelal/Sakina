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

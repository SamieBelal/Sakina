# Pre-ship beat content source review (decision 16A)

**Ship gate.** The bite-sized reflection prompt compresses prophetic narratives into
`≤3 × 20-word` beats + a citation. Compression is exactly where a small model can
invent or distort — and fabricated hadith/Quran content is the app's one
NEVER-rule (see `CLAUDE.md` critical rules). The mechanical eval
(`test/evals/reflect_beat_shape_eval.dart`) checks that a citation *looks* like a
citation; it does NOT check that the story *matches* its source. This human pass
is the only check that reads the content against the source. It is repeated after
**any** change to the reflect system prompt.

## How to run

1. Generate outputs against the canned feelings:
   ```
   RUN_LIVE_EVALS=1 flutter test --dart-define-from-file=env.json \
     test/evals/reflect_beat_shape_eval.dart
   ```
   (The eval prints WARNINGS for over-length beats; capture the full responses by
   temporarily logging `r` in the loop, or run the app against each feeling.)
2. For each response, open the cited `storySource` (the Quran verse or hadith) and
   verify the story beats against it.

## Checklist (per response)

- [ ] **Story is real** — the events in `storyBeats` actually occur in the cited
      source. No invented dialogue, no conflated narratives, no embellishment added
      to fit the word cap.
- [ ] **Citation is correct** — `storySource` points to the actual source of the
      story (not a plausible-looking but wrong reference).
- [ ] **No fabricated scripture** — the dua Arabic/translation and any verse come
      from the pre-verified catalog (the model selects, never generates — this is
      enforced upstream, but confirm nothing leaked through).
- [ ] **Compression is faithful** — the beat split changed the packaging only; the
      meaning matches the full narrative.
- [ ] **Key line / takeaway are grounded** — no theological overreach or claims the
      source doesn't support.

## Outcome

- All rows pass → record the run date + prompt commit here and ship.
- Any distortion → iterate the prompt (tighten the authenticity rules / word caps)
  and re-run this review. Do NOT ship a distorted-content prompt.

## Log

| Date | Prompt commit | Rows reviewed | Result |
|------|---------------|---------------|--------|
| _(pending first pre-ship run)_ | | | |

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';

/// A labelled evaluation of [matchChipKeyForText] — the keyword matcher that
/// decides which `problem_category` a typed answer gets, and therefore which
/// deck variant the reader is served.
///
/// ## Why this exists
///
/// The 2026-08-05 personalisation waves authored 778 variants keyed on the
/// seven `problemCategory` values. All of them are unreachable for a reader the
/// matcher cannot place: an unmatched answer falls to the no-category ladder,
/// where only the seven chip-echo decks carry a `default` and the other 92 serve
/// the same `primary` they served before any of this existed. **The matcher's
/// recall is the ceiling on how much of that work is ever felt.**
///
/// ## The asymmetry that shapes every decision here
///
/// **A false positive is strictly worse than a miss.** A miss serves neutral
/// authored text that is appropriate for anyone. A wrong match serves a bridge
/// about money to someone who wrote about a death. So this file asserts a hard
/// floor on PRECISION and a softer one on RECALL, and any keyword added to
/// widen recall must not cost a single point of precision.
///
/// ## What the corpus is, and what it is not
///
/// 60 first-person answers of the kind someone actually types at night, plus 8
/// that genuinely cannot be placed. It was written BEFORE the keyword lists were
/// touched, precisely so it could not be tuned to them — several entries below
/// still fail, and are left failing rather than deleted, because a corpus you
/// edit until it passes measures nothing.
///
/// It is NOT production data. It is one author's model of how users write, so
/// treat the numbers as a floor to defend and a regression alarm, not as a
/// measurement of the real unmatched rate. That number is only knowable from
/// `deck_variant_selected{source}` once the daily question is in production
/// (plan §2), and it is what the deferred D7 classifier decision waits on.
void main() {
  // (answer, expected chipKey) — null means "should genuinely not match".
  const corpus = <(String, String?)>[
    // ── anxiety — the mind that will not stop ────────────────────────────────
    ("my head won't switch off at night", 'anxiety'),
    ('i keep replaying the same conversation over and over', 'anxiety'),
    ("i can't sleep, too much on my mind", 'anxiety'),
    ("i'm terrified about my results next week", 'anxiety'),
    ('constantly on edge waiting for bad news', 'anxiety'),
    ('i overthink everything before i do it', 'anxiety'),
    ('my heart races when i think about tomorrow', 'anxiety'),
    ('worried sick about the interview', 'anxiety'),
    ('i keep imagining everything going wrong', 'anxiety'),
    ('panic attacks have come back', 'anxiety'),

    // ── heavy — everything at once ───────────────────────────────────────────
    ('everything feels like too much lately', 'heavy'),
    ("i've been crying for no reason", 'heavy'),
    ('i lost my mother last month', 'heavy'),
    ('nothing brings me joy anymore', 'heavy'),
    ('i feel completely numb', 'heavy'),
    ('my dad is in hospital', 'heavy'),
    ('grieving someone i never got to say goodbye to', 'heavy'),
    ("the weight of it doesn't lift", 'heavy'),
    ('i have nothing left to give', 'heavy'),
    ('burnt out and running on empty', 'heavy'),

    // ── guilt — the sin returned to ──────────────────────────────────────────
    ('i keep going back to the same sin', 'guilt'),
    ("i can't forgive myself for what i did", 'guilt'),
    ('i relapsed again this week', 'guilt'),
    ("ashamed of who i've become", 'guilt'),
    ("i promised Allah i'd stop and i didn't", 'guilt'),
    ('the same mistake over and over', 'guilt'),
    ("i don't deserve to make dua", 'guilt'),
    ('i did something i can never tell anyone', 'guilt'),

    // ── far-from-allah — the distance ────────────────────────────────────────
    ("i don't feel anything when i pray anymore", 'far-from-allah'),
    ('my salah has become empty', 'far-from-allah'),
    ('i feel far from Allah', 'far-from-allah'),
    ("i've stopped reading quran", 'far-from-allah'),
    ('going through the motions', 'far-from-allah'),
    ('my iman is at its lowest', 'far-from-allah'),
    ("i pray but i don't feel connected", 'far-from-allah'),
    ("i've drifted and don't know how to come back", 'far-from-allah'),

    // ── rizq — providing ─────────────────────────────────────────────────────
    ("rent is due and i'm short again", 'rizq'),
    ('i lost my job last week', 'rizq'),
    ("i can't provide for my kids", 'rizq'),
    ('drowning in debt', 'rizq'),
    ('work is crushing me', 'rizq'),
    ("i don't know how i'll pay for any of it", 'rizq'),
    ('money is so tight this month', 'rizq'),
    ('been unemployed for six months', 'rizq'),

    // ── unseen — nobody sees it ──────────────────────────────────────────────
    ('nobody knows how tired i am', 'unseen'),
    ('i feel invisible in my own home', 'unseen'),
    ('i am the one everyone leans on and no one asks about me', 'unseen'),
    ('still not married and everyone keeps asking', 'unseen'),
    ('i have no one to talk to', 'unseen'),
    ('lonely even around people', 'unseen'),
    ("my husband doesn't understand", 'unseen'),
    ('carrying this by myself', 'unseen'),

    // ── genuinely unplaceable — the `sign` chip's whole reason to exist ──────
    ("i don't know", null),
    ('everything', null),
    ('just off', null),
    ('hard to explain', null),
    ("i can't put it into words", null),
    ('not sure', null),
    ('everything and nothing', null),
    ('idk really', null),
  ];

  ({int correct, int wrong, int missed, int falsePositive}) score() {
    var correct = 0, wrong = 0, missed = 0, falsePositive = 0;
    for (final (text, expected) in corpus) {
      final got = matchChipKeyForText(text);
      if (expected == null) {
        if (got == null) {
          correct++;
        } else {
          falsePositive++;
        }
      } else if (got == null) {
        missed++;
      } else if (got == expected) {
        correct++;
      } else {
        wrong++;
      }
    }
    return (
      correct: correct,
      wrong: wrong,
      missed: missed,
      falsePositive: falsePositive
    );
  }

  // The 2026-08-05 recall pass added ~60 keywords, and its FIRST draft broke
  // three of these. They are pinned because the file's own doc comment records
  // that bare `praying` and `disconnected` were added and then removed on
  // 2026-07-26 for exactly this reason — the lesson has now been learned twice,
  // so it is worth a test rather than a third rediscovery.
  //
  // The rule that survives: a devotional or relational word may only be added
  // as a PHRASE that pins whose experience it is. "when i pray" is the reader's
  // own worship; "i pray for my mother" is a sentence about grief.
  test('ambient words do not steal a sentence that is about something else',
      () {
    const cases = <(String, String?)>[
      // `weak` in `guilt` — and `guilt` is FIRST in the map, so it outranked
      // every other category for any sentence containing the word.
      ('i feel weak and exhausted', 'heavy'),
      // Bare `pray` claimed intercession, where the topic is the person prayed
      // for, not the reader's own distance.
      ('i pray for my mother who is in hospital', 'heavy'),
      ('i pray my brother recovers', 'heavy'),
      // Bare `disconnected` claimed interpersonal distance for spiritual
      // distance. `unseen` is the right home for this one.
      ("i don't feel connected to my wife", 'unseen'),
      // An empty bank account is provision, not heaviness.
      ('my bank account is empty', 'rizq'),
      // `weight` had to be narrowed to the burden sense, or it caught this.
      ('i am trying to lose weight', null),
    ];
    for (final (text, expected) in cases) {
      expect(matchChipKeyForText(text), expected,
          reason: '"$text" should resolve to $expected');
    }
  });

  test('matcher precision and recall over a labelled corpus', () {
    final s = score();
    final labelled = corpus.where((e) => e.$2 != null).length;
    final answered = s.correct + s.wrong + s.falsePositive;
    // Of the answers it CHOSE to place, how many did it place correctly?
    final precision = (s.correct - (corpus.length - labelled - s.falsePositive)) /
        (answered - (corpus.length - labelled - s.falsePositive)).clamp(1, 999);
    final recall = (labelled - s.missed) / labelled;

    // ignore: avoid_print
    print('EVAL  correct=${s.correct} wrong=${s.wrong} missed=${s.missed} '
        'falsePositive=${s.falsePositive}  '
        'precision=${(precision * 100).toStringAsFixed(1)}%  '
        'recall=${(recall * 100).toStringAsFixed(1)}%');
    for (final (text, expected) in corpus) {
      final got = matchChipKeyForText(text);
      if (got != expected) {
        // ignore: avoid_print
        print('  ${got == null ? "MISS " : "WRONG"} "$text" want=$expected got=$got');
      }
    }

    // ── The two floors ──────────────────────────────────────────────────────
    // PRECISION is the hard one. Placing a reader in the wrong category serves
    // them a bridge about someone else's problem; leaving them unplaced serves
    // them neutral authored text. Never trade this away for recall.
    expect(s.wrong, lessThanOrEqualTo(2),
        reason: 'a wrong category is worse than no category — it serves a '
            'bridge about a problem the reader does not have');
    expect(s.falsePositive, 0,
        reason: 'an answer that names nothing must stay unplaced: that is the '
            'entire reason the `sign` chip and the `default` variants exist');
    // RECALL is the ceiling on how much of the 778-variant corpus is ever felt.
    // Raise this floor whenever the lists genuinely improve; never lower it to
    // make a change pass.
    expect(recall, greaterThanOrEqualTo(0.80),
        reason: 'recall is the ceiling on how much of the authored variant '
            'corpus a real reader ever meets');
  });
}

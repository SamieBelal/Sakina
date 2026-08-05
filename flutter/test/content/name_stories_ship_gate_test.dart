import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';

/// One Ship W2-A2 — the deck SHIP GATE, enforced in CI rather than at runtime.
///
/// A chip may only render when BOTH its decks carry recorded founder sign-off
/// (plan-of-record ship gate). These assertions make an unapproved, malformed,
/// or scripture-unsafe deck a BUILD FAILURE, so the gate can never regress
/// silently. Content itself is transcribed verbatim from the approved files in
/// docs/superpowers/content/decks/ — this test checks structure and safety
/// invariants, never rewrites content.
void main() {
  // The 7 rendered chips (6 problem + sign). The sign pair doubles as the
  // comfort-pair fallback for unmatched free text.
  const chipKeys = {
    'anxiety',
    'far-from-allah',
    'guilt',
    'heavy',
    'rizq',
    'sign',
    'unseen',
  };

  // `pair_synergy` is deliberately NOT a kind: the shipped convention is a
  // `takeaway` beat carrying a `synergy` label (see the pair-synergy test at the
  // bottom), and no deck has ever used the kind. Keeping it allowed would let a
  // second, unrendered spelling of the same beat into the asset.
  const allowedKinds = {
    'bridge',
    'name_intro',
    'story',
    'verse',
    'dua',
    'takeaway',
    'recognition',
    'comfort_verse',
    'reflection',
  };

  // The two beats the runtime is allowed to REPLACE with AI-personalised text,
  // so that a user drawing the same Name twice does not read the same words
  // twice. Everything else on a deck is the pre-authored religious core and
  // renders byte-identically every time.
  //
  // What ships in the asset for these two kinds is the FALLBACK — what a user
  // sees offline, when the model call fails, or when they are outside the tier
  // that gets personalisation. It is not decoration; it is the floor.
  //
  // These kinds are forbidden from carrying `source` or `arabic` (asserted
  // below). That is the whole safety property: the generated text sits in slots
  // that structurally cannot hold scripture, so a model that invents a verse has
  // nowhere in the deck to put it. The gate can only see the asset — it never
  // sees generated text — so the guarantee has to come from the shape of the
  // slot rather than from checking the output.
  const personalisableKinds = {'bridge', 'reflection'};

  // Duʿa provenance that RENDERS (`DuaTextBlock` shows the source line). Only
  // these decks cite the duʿa itself — their sources table names the exact
  // verse/hadith the words come from. Pinned so the attribution can never be
  // silently dropped. Every other duʿa is a catalog invocation with no citation
  // anywhere in its deck, and byte-identity with the verified catalog (below)
  // is its provenance.
  //
  // This map is EXHAUSTIVE, not a whitelist — see the assertion below. An
  // earlier version of this comment claimed "the gate will not accept an
  // invented one" while the check was `if (pinned != null)`, i.e. it asserted
  // nothing at all about the unpinned decks: a fabricated `source` on any of
  // them would have rendered on screen and passed CI silently. Adding a deck
  // that cites its duʿa means adding it here, and that is the point — a
  // citation nobody had to write down is a citation nobody verified.
  const renderedDuaSources = {
    'as-salam@1': 'Sahih Muslim 591',
    'al-wakeel@1': "Qur'an 3:173",
    'ash-shafi@1': 'cf. Sahih al-Bukhari 5743',
    // Batch 1 + 2, transcribed 2026-08-03. Each pin was read off the deck's own
    // duʿa beat by the agent that transcribed it, never copied from a report —
    // al-waliyy@1's was reported stale twice, and a pin that happens to match
    // for the wrong reason ships a wrong citation silently rather than loudly.
    'ar-raheem@1': "Qur'an 18:10",
    'al-ghafur@1': 'Sunan Abi Dawud 1516',
    'al-afuw@1': 'Sunan Ibn Majah 3850',
    'al-mujeeb@1': "Qur'an 21:87",
    // 2026-08-05. Replaced a shared `yā Laṭīf` invocation that named neither
    // this deck's Name nor its pair's — see
    // `docs/superpowers/content/decks/2026-08-05-DUA-COLLISION-RESEARCH.md`.
    // Verified against sunnah.com/muslim:2696 individually, not off a listing
    // page: Book 48 (Dhikr, Supplication, Repentance and Istighfār), Hadith 43,
    // chapter "The Virtue Of Tahlil, Tasbih And Du'a". Ṣaḥīḥ by collection —
    // sunnah.com prints no grade line for the Ṣaḥīḥayn, so this is a
    // collection-level inference and is recorded as one.
    'al-hakeem@1': 'Sahih Muslim 2696',
    'al-waliyy@1': 'Sahih Muslim 1342',
    // Wave 1, transcribed 2026-08-03. Same rule: each read off the deck's own
    // duʿa beat by the agent that transcribed it, never copied from a report.
    // Both carry a parenthesised qualifier because the catalogue duʿa is a
    // TRUNCATION of the cited ayah — a bare citation would claim on screen that
    // the user is reading the whole verse, which is the class of quiet
    // overclaim this project spent a wave learning to catch.
    'al-malik@1': "Qur'an 3:26 (opening)",
    'al-aleem@1': "Jami' at-Tirmidhi 3392 (opening of the supplication)",
    // Read off the transcribed fragment's own duʿa beat, not from a report.
    // Bare (no `cf.`, no qualifier) because id 5's catalogue duʿa is the
    // narration's words in full, not a truncation of them.
    'al-quddus@1': 'Sahih Muslim 487a',
    // Deliberately absent, and each verified as absent rather than assumed:
    // al-haleem@1, al-kareem@1, al-qayyum@1, al-qadir@1, al-muid@1 render NO
    // duʿa citation. Their duʿa is the catalogue's own authored invocation, so
    // a pin here would assert a provenance the text does not have — which is
    // the exact fabrication this map's other direction exists to catch.
  };

  late List<dynamic> decks;
  late Set<int> catalogIds;
  late Map<int, String> catalogDuaArabic;
  late Map<int, String> catalogDuaTransliteration;
  late Map<int, String> catalogDuaTranslation;

  setUpAll(() {
    decks = jsonDecode(
      File('assets/content/name_stories.json').readAsStringSync(),
    ) as List<dynamic>;
    final catalog = jsonDecode(
      File('assets/content/collectible_names.json').readAsStringSync(),
    ) as List<dynamic>;
    catalogIds = catalog.map<int>((n) => n['id'] as int).toSet();
    catalogDuaArabic = {
      for (final n in catalog) n['id'] as int: (n['dua_arabic'] ?? '') as String,
    };
    catalogDuaTransliteration = {
      for (final n in catalog)
        n['id'] as int: (n['dua_transliteration'] ?? '') as String,
    };
    catalogDuaTranslation = {
      for (final n in catalog)
        n['id'] as int: (n['dua_translation'] ?? '') as String,
    };
  });

  test('every rendered chip maps to exactly two decks (positions 1 and 2)',
      () {
    for (final chip in chipKeys) {
      final forChip = decks
          .where((d) => (d['chip_keys'] as List).contains(chip))
          .toList();
      expect(forChip, hasLength(2), reason: 'chip "$chip" needs its pair');
      expect(
        forChip.map((d) => d['position_in_pair']).toSet(),
        {1, 2},
        reason: 'chip "$chip" pair must cover positions 1 and 2',
      );
    }
  });

  test('SHIP GATE: every deck carries recorded founder sign-off', () {
    for (final d in decks) {
      expect(d['review_verdict'], 'good',
          reason: '${d['deck_id']} is not approved — it MUST NOT ship');
      expect((d['reviewed_by'] as String).isNotEmpty, isTrue,
          reason: '${d['deck_id']} missing reviewer');
      expect((d['reviewed_at'] as String).isNotEmpty, isTrue,
          reason: '${d['deck_id']} missing review date');
    }
  });

  test('every deck name_id exists in the collectible_names catalog', () {
    for (final d in decks) {
      expect(catalogIds.contains(d['name_id']), isTrue,
          reason: '${d['deck_id']} name_id ${d['name_id']} not in catalog');
    }
  });

  test('no field mixes Arabic body text with Latin text (RTL-bleed rule)', () {
    // Full Arabic coverage: Arabic (U+0600-06FF), Supplement (U+0750-077F),
    // Extended-A (U+08A0-08FF) and BOTH Presentation Forms blocks (U+FB50-FDFF,
    // U+FE70-FEFF) — a deck pasted from a source that uses presentation forms
    // would otherwise slip Arabic body text into a Latin field unnoticed.
    // The three composite honorifics are stripped first: ﷺ (U+FDFA), ﷻ
    // (U+FDFB) and ﷽ (U+FDFD) appear inline in English renderings by design.
    final arabicBody = RegExp(r'[؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-﻿]');
    String strip(String s) => s.replaceAll(RegExp(r'[ﷺﷻ﷽]'), '');
    final latin = RegExp(r'[A-Za-z]');
    for (final d in decks) {
      for (final b in d['beats'] as List) {
        // `source` renders; `label` renders for story beats and is read by
        // reviewers everywhere else — both must stay single-script.
        for (final field in [
          'primary',
          'translation',
          'transliteration',
          'label',
          'source',
        ]) {
          final v = strip((b[field] ?? '') as String);
          expect(arabicBody.hasMatch(v), isFalse,
              reason:
                  '${d['deck_id']} $field contains Arabic body text — Arabic '
                  'belongs only in the arabic field (never mixed with Latin)');
        }
        final arabicField = (b['arabic'] ?? '') as String;
        expect(latin.hasMatch(arabicField), isFalse,
            reason: '${d['deck_id']} arabic field contains Latin text');
      }
    }
  });

  test('beat kinds are from the spec set; every deck ends dua-before-takeaway '
      'ordering rules hold', () {
    for (final d in decks) {
      final beats = d['beats'] as List;
      final kinds = beats.map((b) => b['kind'] as String).toList();
      for (final k in kinds) {
        expect(allowedKinds.contains(k), isTrue,
            reason: '${d['deck_id']} has unknown beat kind "$k"');
      }
      // Standard spine: bridge → name_intro → story×3 → verse → dua →
      // takeaway. The sign Name₁ deck prepends recognition + comfort_verse, and
      // a deck may append one optional `reflection` beat.
      final core = kinds
          .where((k) =>
              k != 'recognition' && k != 'comfort_verse' && k != 'reflection')
          .toList();
      expect(
        core,
        ['bridge', 'name_intro', 'story', 'story', 'story', 'verse', 'dua',
          'takeaway'],
        reason: '${d['deck_id']} core beat order deviates from the spec',
      );
      if (kinds.contains('recognition')) {
        expect(kinds.sublist(0, 2), ['recognition', 'comfort_verse'],
            reason: 'recognition beats must open the sign deck');
      }
      // `reflection` closes the deck or does not exist. It is deliberately NOT
      // required: the 45 decks authored before personalisation existed have no
      // reflection beat, and backfilling them is a content decision, not a
      // structural one. Requiring it here would turn that decision into a red
      // suite.
      expect(kinds.where((k) => k == 'reflection').length, lessThanOrEqualTo(1),
          reason: '${d['deck_id']} has more than one reflection beat');
      if (kinds.contains('reflection')) {
        expect(kinds.last, 'reflection',
            reason: '${d['deck_id']} reflection beat must close the deck');
      }
    }
  });

  test('the AI-personalisable beats cannot carry scripture', () {
    // The runtime may replace a `bridge` or `reflection` beat with generated
    // text. Those two slots therefore may never carry a citation or an Arabic
    // field — not because today's authored text would misuse one, but because
    // the shape of the slot is the only guarantee available once the text stops
    // being authored. A model asked for "a short bridge connecting this Name to
    // how you're feeling" will occasionally produce a verse; this is what makes
    // that unshippable rather than merely unlikely.
    for (final d in decks) {
      for (final b in (d['beats'] as List)) {
        final kind = b['kind'] as String;
        if (!personalisableKinds.contains(kind)) continue;
        expect((b['source'] ?? '') as String, isEmpty,
            reason: '${d['deck_id']} $kind beat carries a source citation — '
                'this slot is replaceable by generated text, so scripture '
                'must live on a fixed beat instead');
        expect((b['arabic'] ?? '') as String, isEmpty,
            reason: '${d['deck_id']} $kind beat carries an arabic field — '
                'see above; move it to a fixed beat');
      }
    }
  });

  // ---------------------------------------------------------------------
  // Variants — the selection pool the personalisation layer draws from.
  //
  // A `bridge` or `reflection` beat may carry `variants`: alternative
  // renderings of the SAME beat, all founder-authored, one of which the
  // selector shows. The model never writes prose — it picks an id. That is
  // what makes the safety property structural rather than a filter over
  // generated text, which cannot catch paraphrased scripture.
  //
  // Two assertions, and the first is the one that matters. The scripture
  // check above `continue`s past every kind that is not personalisable, so
  // adding `variants` to the schema opens a second place text can hide —
  // one no existing assertion reaches. Arabic sitting in `verse.variants`
  // would be dead data today AND unguarded, one renderer change from
  // surfacing. Asserting the field EMPTY on those kinds makes the illegal
  // state unrepresentable instead of merely sanitised.
  //
  // Variants are `{id, text}` objects, never bare strings. A selection is
  // persisted so a re-opened night shows the same words, and an array index
  // stops meaning the same thing the moment a later release reorders or
  // deletes a variant — the cache would then point at different copy with
  // nothing to detect it. Ids are stable; positions are not.
  test('SHIP GATE: variants exist only where scripture cannot follow', () {
    // Same class the beat-field check uses (presentation forms included) — a
    // variant pasted from a source that uses them must not slip through.
    final arabicBody = RegExp(r'[؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-﻿]');
    // …with the same honorific carve-out the RTL-bleed rule makes above: ﷺ, ﷻ
    // and ﷽ are single codepoints inside the presentation-forms block but read
    // as English-side punctuation. Without this the gate forbids a variant from
    // saying "the Prophet ﷺ" — which several `primary` texts already do, so the
    // rule would have banned from the variant exactly what it permits one field
    // over. (Wave 3's mutation test used real Arabic words and never reached
    // this case; the first batch of authored content did, immediately.)
    String stripHonorifics(String s) => s.replaceAll(RegExp(r'[ﷺﷻ﷽]'), '');
    // Read off the live chip taxonomy, never transcribed — a copied list would
    // drift the moment a chip is renamed, and drift here is undetectable.
    final validProblemCategories =
        problemChips.map((c) => c.problemCategory).toSet();
    for (final d in decks) {
      for (final b in (d['beats'] as List)) {
        final kind = b['kind'] as String;
        final raw = b['variants'];
        if (!personalisableKinds.contains(kind)) {
          expect(raw == null || (raw as List).isEmpty, isTrue,
              reason: '${d['deck_id']} $kind beat carries `variants`. Only '
                  '${personalisableKinds.join('/')} beats may — every other '
                  'kind holds scripture, and a variants array there is text '
                  'no other assertion in this file reaches');
          continue;
        }
        if (raw == null) continue;
        final seen = <String>{};
        // `primary` is the default AND the fallback (plan §4.1), and it is in
        // the rotation pool. A variant that merely restates it therefore costs
        // a repeat encounter: the selector believes it rotated, the reader gets
        // the same sentence twice. It is also a drift surface of exactly the
        // kind this repo keeps paying for — edit `primary`, forget the copy,
        // and one category silently keeps serving the old words.
        final seenText = <String>{
          ((b['primary'] ?? '') as String).trim(),
        };
        for (final v in (raw as List)) {
          final m = v as Map<String, dynamic>;
          final id = (m['id'] ?? '') as String;
          final text = (m['text'] ?? '') as String;
          expect(id.isNotEmpty, isTrue,
              reason: '${d['deck_id']} $kind variant has no id — selections '
                  'are persisted by id, and a positional fallback silently '
                  'points at different copy once variants are reordered');
          // An id is either `default` or one of the seven `problemCategory`
          // values the on-device matcher actually produces.
          //
          // `default` is NOT a copy of `primary` — the duplicate-text rule
          // below rejects that. It is the *no-category* text, for the case the
          // matcher returns `unmatched` (free text with no keyword hit).
          // `unmatched` is deliberately not a legal id: it is not a chip, and
          // pinning ids to the live chip list is what catches typos.
          //
          // This distinction is load-bearing for the seven chip-pair decks
          // whose `primary` echoes the chip label back ("For the weight you
          // named — a mind that won't stop racing"). Onboarding picks those
          // decks BY chip, so `primary` is always true there. Daily picks them
          // by `deckForName(queueCard.id)` — the drawn card, not the answer —
          // so an unmatched answer would otherwise be told it named a weight
          // it never named.
          //
          // This is pinned against the live taxonomy rather than a copy,
          // because the first seeded batch used `far-from-allah` — the
          // CHIP KEY — where the category is `far_from_allah`. Nothing would
          // have failed: the selector simply would never have matched that
          // variant, and the deck would have quietly served its default
          // forever. A variant nobody can select is worse than no variant,
          // because it looks like coverage.
          expect(
            id == 'default' || validProblemCategories.contains(id),
            isTrue,
            reason: '${d['deck_id']} $kind variant id "$id" is neither '
                '`default` nor a real problem_category '
                '(${validProblemCategories.join(', ')}). The selector keys on '
                'problem_category, so this variant could never be chosen',
          );
          expect(seen.add(id), isTrue,
              reason: '${d['deck_id']} $kind has two variants with id "$id" — '
                  'a persisted selection would be ambiguous');
          expect(text.trim().isNotEmpty, isTrue,
              reason: '${d['deck_id']} $kind variant "$id" has no text');
          expect(m.containsKey('source'), isFalse,
              reason: '${d['deck_id']} $kind variant "$id" carries a source '
                  'citation — a variant is the same slot as the beat it '
                  'replaces, and that slot may never hold scripture');
          expect(m.containsKey('arabic'), isFalse,
              reason: '${d['deck_id']} $kind variant "$id" carries an arabic '
                  'field — see above');
          expect(arabicBody.hasMatch(stripHonorifics(text)), isFalse,
              reason: '${d['deck_id']} $kind variant "$id" contains Arabic '
                  'script in its text. The gate cannot verify scripture that '
                  'reaches a screen this way, which is the whole reason this '
                  'slot is restricted');
          expect(seenText.add(text.trim()), isTrue,
              reason: '${d['deck_id']} $kind variant "$id" repeats text already '
                  'in this beat (either `primary` or an earlier variant). That '
                  'is not coverage — it spends a rotation slot to show the '
                  'reader the same sentence again, and it duplicates a string '
                  'that will drift the first time one copy is edited. A '
                  'category with nothing distinctive to say should carry no '
                  'variant and fall through to `primary`');
        }
      }
    }
  });

  test('scripture beats carry the split script fields; duas match the '
      'verified catalog byte-for-byte', () {
    for (final d in decks) {
      for (final b in d['beats'] as List) {
        final kind = b['kind'] as String;
        if (kind == 'dua' || kind == 'name_intro') {
          expect(((b['arabic'] ?? '') as String).isNotEmpty, isTrue,
              reason: '${d['deck_id']} $kind beat missing arabic');
          expect(((b['transliteration'] ?? '') as String).isNotEmpty, isTrue,
              reason: '${d['deck_id']} $kind beat missing transliteration');
        }
        if (kind == 'dua') {
          // Duas are never authored — all three scripts come from the verified
          // catalog, byte for byte. The deck holds the translation on `primary`
          // (see the field table on NameStoryBeat), so that is what the catalog
          // translation is compared against.
          expect(b['arabic'], catalogDuaArabic[d['name_id']],
              reason:
                  '${d['deck_id']} dua arabic diverges from the verified '
                  'catalog — decks must never carry non-catalog scripture');
          expect(b['transliteration'],
              catalogDuaTransliteration[d['name_id']],
              reason: '${d['deck_id']} dua transliteration diverges from the '
                  'verified catalog');
          expect(b['primary'], catalogDuaTranslation[d['name_id']],
              reason: '${d['deck_id']} dua translation diverges from the '
                  'verified catalog');
          // Both directions, because each failure is real and they are
          // different failures:
          //   * a pinned deck losing its citation is a content regression —
          //     the attribution renders, so dropping it silently unattributes
          //     words the sources table says came from somewhere specific;
          //   * an UNPINNED deck growing one is worse. It renders a provenance
          //     claim under `DuaTextBlock` that no sources table backs and no
          //     human ever verified. That is the fabrication this whole gate
          //     exists to make impossible, and until now it was the one shape
          //     of it the gate could not see.
          final pinned = renderedDuaSources[d['deck_id']] ?? '';
          expect(((b['source'] ?? '') as String), pinned,
              reason: pinned.isEmpty
                  ? '${d['deck_id']} renders a duʿa citation that is not in '
                      'renderedDuaSources. Either it is invented — in which '
                      'case delete it — or it is real, in which case verify it '
                      'and pin it here.'
                  : '${d['deck_id']} dropped the duʿa citation its own sources '
                      'table carries — attribution renders, so losing it is a '
                      'content regression');
        }
        if (kind == 'verse' || kind == 'comfort_verse') {
          expect(((b['source'] ?? '') as String).isNotEmpty, isTrue,
              reason: '${d['deck_id']} $kind beat missing source citation');
        }
      }
    }
  });

  test('every beat carries body text', () {
    // `primary` is the one field every kind renders. An empty one ships a blank
    // screen the user has to tap past.
    for (final d in decks) {
      for (final b in d['beats'] as List) {
        expect(((b['primary'] ?? '') as String).trim().isNotEmpty, isTrue,
            reason: '${d['deck_id']} ${b['kind']} beat has no primary text');
      }
    }
  });

  // ---------------------------------------------------------------------
  // Must-ship-together Name pairs.
  //
  // Five pairs are ruled inseparable (COLLISION-LEDGER §9bg): each deck's
  // takeaway hands the reader to its partner by name, and Ad-Darr's in
  // particular — The Distresser — "structurally cannot resolve into relief"
  // on its own material. Half a pair is not half a lesson; it is a setup with
  // no payoff, delivered to someone in distress.
  //
  // This CANNOT be expressed through `chip_keys`. Those are the seven mood
  // tags the free-text matcher uses, all seven already spoken for, and the
  // pair assertions above only iterate over decks carrying one — so every
  // deck below was invisible to them. Populating `chip_keys` to reach those
  // tests would newly FAIL them, because none of these decks declares
  // `position_in_pair` 1 or 2 and none carries a synergy beat. The relation
  // is a different relation and needs its own assertion.
  const mustShipTogether = {
    'ad-darr@1': 'an-nafi@1',
    'an-nafi@1': 'ad-darr@1',
    'al-qabid@1': 'al-basit@1',
    'al-basit@1': 'al-qabid@1',
    'al-khafid@1': 'ar-rafi@1',
    'ar-rafi@1': 'al-khafid@1',
    'al-muizz@1': 'al-muzill@1',
    'al-muzill@1': 'al-muizz@1',
    'al-muqaddim@1': 'al-muakhkhir@1',
    'al-muakhkhir@1': 'al-muqaddim@1',
  };

  test('SHIP GATE: a must-ship-together deck never ships without its partner',
      () {
    final present = decks.map((d) => d['deck_id'] as String).toSet();
    for (final entry in mustShipTogether.entries) {
      if (!present.contains(entry.key)) continue;
      expect(
        present.contains(entry.value),
        isTrue,
        reason: '${entry.key} is in the asset but ${entry.value} is not. '
            'These two are ruled inseparable — the first hands the reader to '
            'the second by name, so shipping it alone delivers a setup with '
            'no resolution. Ship both or neither.',
      );
    }
  });

  test('a must-ship-together deck that names its partner still resolves alone',
      () {
    // The gate above guarantees the partner is in the ASSET. It cannot
    // guarantee the reader has drawn it — decks are served one Name at a time
    // by `deckForName`, so a user can meet Ad-Darr months before An-Nafi.
    // The takeaway may therefore point forward, but must not DEPEND on the
    // partner to land: no beat may end on the partner's name as its final
    // clause, which is what turns a pointer into a cliffhanger.
    for (final d in decks) {
      final partner = mustShipTogether[d['deck_id']];
      if (partner == null) continue;
      // Hyphens are normalised on BOTH sides. Stripping them from the deck_id
      // alone produced `an nafi`, which can never match the rendered `An-Nafi`
      // — the assertion below looked thorough and matched nothing, so it
      // passed for every deck by finding zero candidates rather than by the
      // content being right. A gate that cannot fail is not a gate.
      final partnerName =
          partner.replaceAll('@1', '').replaceAll('-', ' ').toLowerCase();
      for (final b in d['beats'] as List) {
        final text = ((b['primary'] ?? '') as String).trim();
        if (text.isEmpty) continue;
        final tail = text.length < 60 ? text : text.substring(text.length - 60);
        final tailNorm = tail.toLowerCase().replaceAll('-', ' ');
        expect(
          tailNorm.contains(partnerName) &&
              (tail.endsWith('.') || tail.endsWith('!')) &&
              tailNorm.indexOf(partnerName) >
                  tail.length - partnerName.length - 25,
          isFalse,
          reason: '${d['deck_id']} ${b['kind']} beat ends on its partner\'s '
              'name. The partner is a pointer, not a dependency — this beat '
              'has to resolve for a reader who has not drawn $partner yet',
        );
      }
    }
  });

  test('exactly one pair-synergy beat per pair, carried by position 1', () {
    for (final chip in chipKeys) {
      final forChip =
          decks.where((d) => (d['chip_keys'] as List).contains(chip));
      for (final d in forChip) {
        final synergyBeats = (d['beats'] as List).where((b) =>
            ((b['label'] ?? '') as String).toLowerCase().contains('synergy') ||
            b['kind'] == 'pair_synergy');
        if (d['position_in_pair'] == 1) {
          expect(synergyBeats, hasLength(1),
              reason: '${d['deck_id']} (Name₁) must carry the synergy beat');
        } else {
          expect(synergyBeats, isEmpty,
              reason: '${d['deck_id']} (Name₂) must not carry a synergy beat');
        }
      }
    }
  });
}

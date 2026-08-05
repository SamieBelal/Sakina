#!/usr/bin/env python3
"""Merge a variant patch into assets/content/name_stories.json.

Wave 2 authors ~100 decks' worth of bridge/reflection variants in batches. Doing
that by hand-editing a 99-deck JSON file is how you lose a deck; this reads a
patch of {deck_id: {beat_kind: [{id, text}, ...]}} and writes it into place,
refusing anything the ship gate would reject anyway (unknown deck, wrong beat
kind, text identical to `primary`).

Usage:  python3 tool/apply_variant_patch.py <patch.json>
"""
import json
import sys

ASSET = 'assets/content/name_stories.json'
PERSONALISABLE = {'bridge', 'reflection'}


def main(patch_path: str) -> int:
    decks = json.load(open(ASSET))
    patch = json.load(open(patch_path))
    by_id = {d['deck_id']: d for d in decks}

    errors, applied = [], 0
    for deck_id, beats in patch.items():
        deck = by_id.get(deck_id)
        if deck is None:
            errors.append(f'{deck_id}: no such deck')
            continue
        for kind, variants in beats.items():
            if kind not in PERSONALISABLE:
                errors.append(f'{deck_id}/{kind}: not a personalisable beat')
                continue
            targets = [b for b in deck['beats'] if b['kind'] == kind]
            if len(targets) != 1:
                errors.append(
                    f'{deck_id}/{kind}: {len(targets)} such beats, expected 1')
                continue
            beat = targets[0]
            primary = beat['primary'].strip()
            seen_text = {primary}
            seen_id = set()
            for v in variants:
                if v['text'].strip() in seen_text:
                    errors.append(
                        f'{deck_id}/{kind}/{v["id"]}: text repeats `primary` or '
                        'a sibling variant')
                if v['id'] in seen_id:
                    errors.append(f'{deck_id}/{kind}: duplicate id {v["id"]}')
                seen_text.add(v['text'].strip())
                seen_id.add(v['id'])
            beat['variants'] = variants
            applied += len(variants)

    if errors:
        print('REFUSED — patch not applied:')
        for e in errors:
            print('  ', e)
        return 1

    with open(ASSET, 'w') as f:
        json.dump(decks, f, ensure_ascii=False, indent=2)
        f.write('\n')
    covered = sum(
        1 for d in decks
        for b in d['beats'] if b['kind'] == 'bridge' and b.get('variants'))
    print(f'applied {applied} variants across {len(patch)} decks '
          f'({covered}/{len(decks)} bridges now covered)')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))

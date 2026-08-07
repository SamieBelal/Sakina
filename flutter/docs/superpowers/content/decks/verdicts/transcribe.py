#!/usr/bin/env python3
"""transcribe — DRAFT.md -> name_stories.json beat objects.

Emits nothing it had to guess. Every deck either parses cleanly and is
asserted against the catalogue, or is reported as NEEDS-HAND-TRANSCRIPTION
with the reason. A silently-wrong beat is worse than an unparsed one.

  python3 .context/transcribe.py            # report
  python3 .context/transcribe.py --emit OUT # write staging JSON
"""
import re, os, json, sys, glob, unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FL   = os.path.join(ROOT, 'flutter')
DECKS= os.path.join(FL, 'docs/superpowers/content/decks')
CAT  = {n['id']: n for n in json.load(open(os.path.join(FL,'assets/content/collectible_names.json')))}
SHIP = {d['deck_id'] for d in json.load(open(os.path.join(FL,'assets/content/name_stories.json')))}
KINDS= ['bridge','name_intro','story','story','story','verse','dua','takeaway','reflection']

def clean(s):
    # Editorial annotations live in the draft next to the beat text. They must
    # NOT reach `primary` — a rendered beat reading "(R1: truncated at the
    # clause boundary — see bar 3(b))" is an authoring note shown to a user.
    s = re.sub(r'\*\(\s*\*?\*?R\d[^)]*\)\*', '', s)
    s = re.sub(r'\((?:\*\*)?R\d\b[^)]*\)', '', s)
    # `*(source: Qur'an 6:101)` sits inline in some drafts' story beats. It is a
    # citation, not body text — it belongs in `source` and must not render.
    s = re.sub(r"\*?\(\s*`?source`?\s*:[^)]*\)\*?", '', s)
    s = re.sub(r'\*\*|\*(?!\S)|`', '', s)
    s = re.sub(r'^\s*\d+\.\s*', '', s.strip())
    return re.sub(r'\s{2,}', ' ', s).strip()

def parse_blockquote(t):
    """Newer format: **Beat N · kind** followed by > lines."""
    beats, cur = [], None
    for line in t.split('\n'):
        m = re.match(r'\*\*Beat[s]?\s+([\d–\-]+)\s*·\s*([^\s*]+)', line)
        if m:
            src = ''
            k = re.search(r"(?:Qur['’]?an|Quran)\s*[\d:–\-]+", line)
            if k: src = k.group(0).replace('’',"'")
            kind = m.group(2).strip('*:').strip()
            kind = 'dua' if kind.startswith('du') else kind
            cur = {'kind': kind, 'src': src, 'lines': []}
            beats.append(cur); continue
        if line.startswith('#') or line.startswith('---'): cur = None; continue
        if cur is not None and line.startswith('>'):
            body = line[1:].strip()
            # Drafters append verification notes inside the same blockquote.
            # They are authoring apparatus and must never reach `primary` —
            # al-batin@1's reflection shipped "Swept, 45 decks: max shared
            # word-run 3…" into the rendered beat before this guard existed.
            NOTE = re.compile(r'^\*{0,2}(R\d\b|Swept\b|Twin-diff\b|Register check\b|'
                              r'Source:|source:|Measured\b|Sweep\b|NO source|'
                              r'\*\*(?:Source|Swept|R\d))', re.I)
            if body:
                if NOTE.match(body):
                    cur['closed'] = True
                elif not cur.get('closed'):
                    cur['lines'].append(body)
    return beats

def build(nid, beats):
    """Expand the beat groups into the 9-beat spine, or fail loudly."""
    out, problems = [], []
    c = CAT[nid]
    for b in beats:
        k, ls = b['kind'], b['lines']
        if not ls: continue
        if k == 'story':
            grouped, curl = [], None
            for l in ls:
                if re.match(r'^\d+\.', l):
                    curl = l; grouped.append(curl)
                elif grouped:
                    grouped[-1] += ' ' + l
                else:
                    grouped.append(l)
            for l in grouped:
                mm = re.search(r"`?source`?\s*:\s*((?:Qur['’]?an|Quran)\s*[\d:–\-]+)", l)
                if mm and not b['src']: b['src'] = mm.group(1).replace('’', "'")
                src = b['src']
                m = re.search(r"—\s*((?:Qur['’]?an|Quran)[^—]*)$", l)
                if m: src = m.group(1).strip(); l = l[:m.start()].strip()
                out.append(dict(kind='story', label='', primary=clean(l).strip('"'),
                                arabic='', transliteration='', translation='', source=src))
        elif k == 'verse':
            body = [x for x in ls if not re.match(r'^`?source`?\s*:', x)]
            srcline = [x for x in ls if re.match(r'^`?source`?\s*:', x)]
            if srcline and not b['src']:
                mm = re.search(r"((?:Qur['’]?an|Quran)\s*[\d:–\-]+)", srcline[0])
                if mm: b['src'] = mm.group(1).replace('’',"'")
            l = ' '.join(body); src = b['src']
            m = re.search(r"—\s*((?:Qur['’]?an|Quran)[^—]*)$", l)
            if m: src = m.group(1).strip(); l = l[:m.start()].strip()
            if not src: problems.append('verse beat has no source')
            out.append(dict(kind='verse', label='', primary=clean(l).strip('"'),
                            arabic='', transliteration='', translation='', source=src))
        elif k == 'dua':
            out.append(dict(kind='dua', label='', primary=c['dua_translation'],
                            arabic=c['dua_arabic'], transliteration=c['dua_transliteration'],
                            translation='', source=''))
        elif k == 'name_intro':
            out.append(dict(kind='name_intro', label=f'catalog id {nid} english verbatim',
                            primary=c['english'], arabic=c['arabic'],
                            transliteration=c['transliteration'], translation='', source=''))
        elif k in ('bridge','reflection'):
            out.append(dict(kind=k, label='', primary=clean(' '.join(ls)),
                            arabic='', transliteration='', translation='', source=''))
        elif k == 'takeaway':
            out.append(dict(kind='takeaway', label='', primary=clean(' '.join(ls)),
                            arabic='', transliteration='', translation='', source=''))
    return out, problems

def check(nid, beats):
    p = []
    kinds = [b['kind'] for b in beats]
    if kinds[:2] != ['bridge','name_intro']: p.append(f'spine starts {kinds[:2]}')
    if kinds.count('story') != 3: p.append(f"{kinds.count('story')} story beats, need 3")
    for want in ('verse','dua','takeaway'):
        if kinds.count(want) != 1: p.append(f"{kinds.count(want)} {want} beats, need 1")
    if 'reflection' in kinds and kinds[-1] != 'reflection': p.append('reflection not last')
    c = CAT[nid]
    for b in beats:
        if b['kind'] == 'dua':
            for f, k in (('dua_arabic','arabic'),('dua_transliteration','transliteration'),('dua_translation','primary')):
                if b[k] != c[f]: p.append(f'dua {k} != catalogue {f}')
        if b['kind'] in ('bridge','reflection'):
            if b['source'] or b['arabic']: p.append(f'{b["kind"]} carries source/arabic — GATE VIOLATION')
        if not (b['primary'] or '').strip(): p.append(f'{b["kind"]} has empty primary')
    return p

def build_table(nid, t):
    """Older format: | N | `kind` | primary | arabic | source |"""
    c, out, probs = CAT[nid], [], []
    seen = False
    # column order varies between drafts — read it off the header row
    order = None
    for line in t.split('\n'):
        if not line.startswith('|'): continue
        cells = [x.strip() for x in line.strip().strip('|').split('|')]
        low = [x.lower().strip('`* ') for x in cells]
        if 'kind' in low and ('primary' in low or 'primary text' in low):
            order = {}
            for idx, name in enumerate(low):
                if name == 'kind': order['kind'] = idx
                elif name.startswith('primary'): order['primary'] = idx
                elif name == 'arabic': order['arabic'] = idx
                elif name == 'source': order['source'] = idx
            continue
        if len(cells) < 5: continue
        if order:
            k = cells[order['kind']].strip('`').strip()
        else:
            k = cells[1].strip('`').strip()
        if k not in ('bridge','name_intro','story','verse','dua','takeaway','reflection'): continue
        seen = True
        if order:
            g = lambda key: cells[order[key]] if key in order and order[key] < len(cells) else ''
            prim, ar, src = g('primary'), g('arabic'), g('source')
        else:
            prim, ar, src = cells[2], cells[3], cells[4]
        if not order and k in ('bridge','reflection'): ar, src = '', ' '
        m_ar = re.search(r'[؀-ۿ][؀-ۿ\s\u0610-\u065f\u06d6-\u06ed]+', ar)
        ar = m_ar.group(0).strip() if m_ar else ''
        src = re.sub(r"Qur['’ʾ]?[aā]n", "Qur'an", src)
        # A `source` renders to the reader. Drafting apparatus inside it does not
        # belong on screen: "(paraphrase throughout — not a verbatim quotation;
        # trailing qadir clause dropped)" is a note to a verifier, not a citation.
        src = re.sub(r'\(paraphrase[^)]*\)', '(paraphrased)', src)
        src = re.sub(r'\(close\)\s*\+', '+', src)
        if not re.search(r"(?:Qur'an|Bukhari|Muslim|Tirmidhi|Majah|Dawud|Nasa|Ahmad)", src): src = ''

        src = '' if ('empty' in src.lower() or src.strip() in ('—','-','')) else src.strip('`* ')
        src = re.sub(r'\s*\(excerpt\)$', ' (excerpt)', src)
        if k == 'dua':
            out.append(dict(kind='dua', label='', primary=c['dua_translation'],
                            arabic=c['dua_arabic'], transliteration=c['dua_transliteration'],
                            translation='', source=''))
        elif k == 'name_intro':
            out.append(dict(kind='name_intro', label=f'catalog id {nid} english verbatim',
                            primary=c['english'], arabic=c['arabic'],
                            transliteration=c['transliteration'], translation='', source=''))
        else:
            out.append(dict(kind=k, label='', primary=clean(prim).strip('"'),
                            arabic='' if ar in ('—','-','') else ar,
                            transliteration='', translation='',
                            source='' if k in ('bridge','reflection') else src))
    if not seen: probs.append('no parseable beats table')
    return out, probs

def build_json(nid, t):
    """Draft already carries a literal beats array — take it, then re-assert."""
    c, probs = CAT[nid], []
    m = re.search(r'"beats"\s*:\s*\[', t)
    if not m: return [], ['no beats array found']
    i = t.index('[', m.start()); depth = 0
    for j in range(i, len(t)):
        if t[j] == '[': depth += 1
        elif t[j] == ']':
            depth -= 1
            if depth == 0: break
    try:
        arr = json.loads(t[i:j+1])
    except Exception as e:
        return [], [f'beats array does not parse: {e}']
    out = []
    for b in arr:
        k = b.get('kind')
        if k == 'dua':
            out.append(dict(kind='dua', label=b.get('label',''), primary=c['dua_translation'],
                            arabic=c['dua_arabic'], transliteration=c['dua_transliteration'],
                            translation='', source=''))
        elif k == 'name_intro':
            out.append(dict(kind='name_intro', label=b.get('label',''), primary=c['english'],
                            arabic=c['arabic'], transliteration=c['transliteration'],
                            translation='', source=''))
        else:
            out.append(dict(kind=k, label=b.get('label',''), primary=clean(b.get('primary','')),
                            arabic=b.get('arabic',''), transliteration=b.get('transliteration',''),
                            translation=b.get('translation',''), source=b.get('source','')))
    return out, probs

def normalise_sources(beats):
    """A `source` renders to the reader; drafting apparatus inside one does not
    belong on screen. Applied centrally so every draft format gets it."""
    for b in beats:
        s = b.get('source') or ''
        if not s: continue
        s = re.sub(r"Qur['’ʾ]?[aā]n", "Qur'an", s)
        s = re.sub(r'\(paraphrase[^)]*\)', '(paraphrased)', s)
        s = re.sub(r'\(close\)\s*\+', '+', s)
        b['source'] = re.sub(r'\s{2,}', ' ', s).strip()

def balance_quotes(beats):
    """Shipped decks never leave a quote open across beats — 0 of 45 do.
    Several drafts open a quotation on beat 3 and close it on beat 5, which
    renders as a dangling quote mark on each screen. Close each beat's own
    quotation at its ellipsis, which is what the shipped decks do."""
    fixed = 0
    for b in beats:
        p = b.get('primary') or ''
        if p.count('"') % 2 == 0: continue
        if p.rstrip().endswith(('…', '...')):
            b['primary'] = p.rstrip() + '"'; fixed += 1
        elif p.lstrip().startswith(('…', '...')):
            b['primary'] = '"' + p.lstrip(); fixed += 1
        elif p.rstrip().endswith('.') or p.rstrip().endswith('?'):
            b['primary'] = p.rstrip() + '"'; fixed += 1
    return fixed

rows, ok = [], {}
for f in sorted(glob.glob(DECKS + '/*-DRAFT.md')):
    t = open(f, encoding='utf-8').read()
    # The id MUST come from this deck's own metadata block. Taking min() over
    # every id in the file put three decks under a sibling's Name, because the
    # prose discusses neighbours by id.
    blk = re.search(r'"deck_id":\s*"([^"]+)"[^{}]*?"name_id":\s*(\d+)', t, re.S)
    if blk:
        did, nid = blk.group(1), int(blk.group(2))
    else:
        m1 = re.search(r'catalogue id (\d+)', t)
        if not m1: continue
        nid = int(m1.group(1))
        did = os.path.basename(f)[11:-9] + '@1'
    if CAT[nid]['transliteration'].lower().replace('-','').replace(' ','') \
       not in did.lower().replace('-','').replace('@1',''):
        print(f'  !! id/slug mismatch: {did} carries name_id {nid} '
              f'({CAT[nid]["transliteration"]}) — REFUSING')
        continue
    if did in SHIP: continue
    if '"kind":' in t and '"beats"' in t:
        beats, probs = build_json(nid, t)
    elif '**Beat 1' not in t:
        beats, probs = build_table(nid, t)
    else:
        beats, probs = build(nid, parse_blockquote(t))
    probs += check(nid, beats)
    normalise_sources(beats)
    nq = balance_quotes(beats)
    if nq: probs = [x for x in probs if 'quote' not in x]
    rows.append((did, nid, probs))
    if not probs: ok[did] = dict(deck_id=did, name_id=nid,
                                 transliteration=CAT[nid]['transliteration'],
                                 chip_keys=[], position_in_pair=0, beats=beats)

clean_n = sum(1 for _,_,p in rows if not p)
print(f'{len(rows)} pending decks · {clean_n} parse clean and pass every assertion · {len(rows)-clean_n} need hands\n')
for did, nid, p in rows:
    if p: print(f'  {did:26} (id {nid:2}) — ' + '; '.join(p))

if '--emit' in sys.argv:
    out = sys.argv[sys.argv.index('--emit')+1]
    json.dump(list(ok.values()), open(out,'w'), ensure_ascii=False, indent=2)
    print(f'\nwrote {len(ok)} decks -> {out}')

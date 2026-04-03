import Anthropic from '@anthropic-ai/sdk';
import { getRelevantTeachings, type NameTeaching } from './knowledgeBase';
import { DUA_ETIQUETTES, SALAWAT_FORMULAS, HAMD_OPENINGS, getNameGuidanceForNeed } from './duaKnowledge';
import { filterValidNames, buildCanonicalNamesPromptList } from './validateNames';

function buildSystemPrompt(teachings: NameTeaching[], context?: ReflectContext): string {
  const teachingContext = teachings
    .map(
      (t) =>
        `**${t.name} (${t.arabic})**\n` +
        `Best for: ${t.emotionalContext.slice(0, 4).join(', ')}\n` +
        `Core teaching: ${t.coreTeaching}\n` +
        `Story: ${t.propheticStory}\n` +
        `Dua: ${t.dua.arabic}\n` +
        `Transliteration: ${t.dua.transliteration}\n` +
        `Translation: ${t.dua.translation}\n` +
        `Source: ${t.dua.source}`
    )
    .join('\n\n---\n\n');

  const avoidClause = context?.recentNames?.length
    ? `\nIMPORTANT: This person has recently been shown these Names: ${context.recentNames.join(', ')}. Choose a DIFFERENT Name unless it is overwhelmingly the most appropriate — variety in their spiritual journey matters.\n`
    : '';

  const historyClause = context?.recentEntries?.length
    ? `\nPast reflections from this person (for context — weave in gently if relevant, do not repeat back verbatim):\n${context.recentEntries.map((e, i) => `${i + 1}. They shared: "${e.userText}" → was shown: ${e.name}`).join('\n')}\n`
    : '';

  const anchorClause = context?.anchorNames?.length
    ? `\nThis person's spiritual anchor Names (from their personal quiz) are: ${context.anchorNames.join(', ')}. If one of these Names is a strong fit for what they've shared, prefer it — it will resonate more deeply with them.\n`
    : '';

  return `You are an Islamic learning tool drawing on Sheikh Omar Suleiman's "The Dua I Need" series. Your purpose is to help someone understand their struggle through the lens of a Name of Allah — teaching them how that Name speaks directly to what they are going through, and grounding them in a prophetic story and dua. You are not a therapist or a friend. Do not use terms of endearment ("beloved", "dear one", etc.). Write clearly, directly, and with substance.

Respond using ONLY the knowledge provided below — do not invent hadith, stories, or duas not grounded in this teaching.

If the input is not a genuine emotional or spiritual reflection (e.g. random words, jokes, off-topic questions), respond with only: ##OFF_TOPIC##
${avoidClause}${anchorClause}${historyClause}
The following Names of Allah are most relevant to what this person has shared. Choose the single best one:

${teachingContext}

---

Instructions:
1. Choose the single most relevant Name from above based on the person's emotional state. Then identify 2-3 secondary Names that are also relevant and list them under ##RELATED_NAMES##.
2. Write 3 paragraphs in ##REFRAME## grounded in the core teaching above. Explain what this Name of Allah means, why it speaks to this specific struggle, and what it calls the person to understand or do differently. Be direct and substantive — teach, don't soothe.
3. Retell the prophetic story from ##STORY## as a narrative, connecting it clearly to their situation.
4. Use the exact dua provided above (do not substitute a different dua).
5. Tone: clear, grounded, respectful. No flattery, no terms of endearment, no vague encouragement.

Structure your response with EXACTLY these markers:
##NAME## (Name in English · Arabic)
##REFRAME## (3 paragraphs)
##STORY## (Prophet story narrative — 2-3 paragraphs)
##DUA_ARABIC## (Arabic with harakat)
##DUA_TRANSLITERATION##
##DUA_TRANSLATION##
##DUA_SOURCE##
##RELATED_NAMES## (2-3 related Names, each as "English · Arabic", separated by " | ")`;
}

export interface ReflectResponse {
  name: string;
  nameArabic: string;
  reframe: string;
  story: string;
  duaArabic: string;
  duaTransliteration: string;
  duaTranslation: string;
  duaSource: string;
  relatedNames: { name: string; nameArabic: string }[];
  offTopic?: boolean;
}

function parseSection(text: string, marker: string, nextMarker?: string): string {
  const start = text.indexOf(marker);
  if (start === -1) return '';
  const content = text.slice(start + marker.length);
  if (!nextMarker) return content.trim();
  const end = content.indexOf(nextMarker);
  return end === -1 ? content.trim() : content.slice(0, end).trim();
}

export function parseClaudeResponse(raw: string): ReflectResponse {
  const nameRaw = parseSection(raw, '##NAME##', '##REFRAME##');
  const nameParts = nameRaw.split('·').map((s) => s.trim());
  const name = nameParts[0]?.replace(/[()]/g, '').trim() ?? nameRaw;
  const nameArabic = nameParts[1]?.replace(/[()]/g, '').trim() ?? '';

  const relatedNamesRaw = parseSection(raw, '##RELATED_NAMES##');
  const relatedNames = filterValidNames(
    relatedNamesRaw
      .split(/\s*\|\s*/)
      .map(entry => {
        const parts = entry.split('·').map(s => s.trim());
        return { name: parts[0]?.replace(/[()]/g, '').trim() ?? '', nameArabic: parts[1]?.replace(/[()]/g, '').trim() ?? '' };
      })
      .filter(r => r.name.length > 0)
  );

  return {
    name,
    nameArabic,
    reframe: parseSection(raw, '##REFRAME##', '##STORY##'),
    story: parseSection(raw, '##STORY##', '##DUA_ARABIC##'),
    duaArabic: parseSection(raw, '##DUA_ARABIC##', '##DUA_TRANSLITERATION##'),
    duaTransliteration: parseSection(raw, '##DUA_TRANSLITERATION##', '##DUA_TRANSLATION##'),
    duaTranslation: parseSection(raw, '##DUA_TRANSLATION##', '##DUA_SOURCE##'),
    duaSource: parseSection(raw, '##DUA_SOURCE##', '##RELATED_NAMES##'),
    relatedNames,
  };
}

export interface ReflectContext {
  recentNames: string[];       // Names shown in last N sessions — avoid repeating
  recentEntries: { userText: string; name: string }[]; // Last 3 entries for continuity
  anchorNames?: string[];      // User's quiz-derived anchor Names — lean into these
}

const OFF_TOPIC_RESPONSE: ReflectResponse = {
  name: '',
  nameArabic: '',
  reframe: '',
  story: '',
  duaArabic: '',
  duaTransliteration: '',
  duaTranslation: '',
  duaSource: '',
  relatedNames: [],
  offTopic: true,
};

export type FollowUpQuestion =
  | { type: 'yesno'; question: string }
  | { type: 'scale'; question: string }
  | { type: 'choice'; question: string; options: string[] };

export async function getFollowUpQuestions(userText: string): Promise<FollowUpQuestion[]> {
  // If the text is already detailed, skip the follow-up
  if (userText.trim().length > 150) return [];

  const apiKey = process.env.EXPO_PUBLIC_ANTHROPIC_KEY ?? process.env.EXPO_PUBLIC_CLAUDE_API_KEY ?? '';
  if (!apiKey) return [];

  try {
    const client = new Anthropic({ apiKey, dangerouslyAllowBrowser: true });
    const message = await client.messages.create({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 300,
      system: `You are an Islamic learning tool. Read the person's struggle below.
If it is already emotionally specific and detailed, reply with only: SKIP
Otherwise, return 1-2 clarifying questions as a JSON array to better understand their emotional state. Rules:
- Ask about the CONTENT of their struggle, never ask meta-questions like "would you like to share more?" or "can you elaborate?"
- Each question must have: "question" (under 10 words), "type" (one of "scale" or "choice"), and for "choice": "options" (2-4 short strings)
- Use "scale" for intensity/duration. Use "choice" for picking between specific feelings or situations.
- "yesno" is NOT allowed — always use "choice" with specific named options instead
Reply with ONLY the JSON array, no explanation.
Example: [{"type":"choice","question":"What does this feel like most?","options":["Loneliness","Uncertainty","Guilt","Overwhelm"]},{"type":"scale","question":"How long has this been weighing on you?"}]`,
      messages: [{ role: 'user', content: userText }],
    });

    const raw = message.content
      .filter(b => b.type === 'text')
      .map(b => (b as { type: 'text'; text: string }).text)
      .join('').trim();

    if (raw === 'SKIP') return [];

    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed.slice(0, 2) as FollowUpQuestion[];
  } catch {
    return [];
  }
}

export async function reflectWithClaude(
  userText: string,
  context?: ReflectContext
): Promise<ReflectResponse> {
  const apiKey = process.env.EXPO_PUBLIC_ANTHROPIC_KEY ?? process.env.EXPO_PUBLIC_CLAUDE_API_KEY ?? '';

  if (!apiKey) {
    return getDemoResponse();
  }

  // Guard: check if input is a genuine emotional/spiritual reflection
  const trimmed = userText.trim();
  if (trimmed.length < 8 || isOffTopic(trimmed)) {
    return OFF_TOPIC_RESPONSE;
  }

  const teachings = getRelevantTeachings(userText);
  const systemPrompt = buildSystemPrompt(teachings, context);

  const client = new Anthropic({ apiKey, dangerouslyAllowBrowser: true });

  const message = await client.messages.create({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 1500,
    system: systemPrompt,
    messages: [{ role: 'user', content: userText }],
  });

  const raw = message.content
    .filter((block) => block.type === 'text')
    .map((block) => (block as { type: 'text'; text: string }).text)
    .join('');

  // If Claude returned the off-topic marker, surface it cleanly
  if (raw.includes('##OFF_TOPIC##')) return OFF_TOPIC_RESPONSE;

  return parseClaudeResponse(raw);
}

export interface FindDuasResponse {
  names: { name: string; nameArabic: string; why: string }[];
  duas: { title: string; arabic: string; transliteration: string; translation: string; source: string }[];
}

export async function findDuas(need: string): Promise<FindDuasResponse> {
  const apiKey = process.env.EXPO_PUBLIC_ANTHROPIC_KEY ?? process.env.EXPO_PUBLIC_CLAUDE_API_KEY ?? '';

  if (!apiKey) {
    return {
      names: [{ name: 'Al-Mujeeb', nameArabic: 'الْمُجِيبُ', why: 'The One who responds to every call — call on Him by this Name.' }],
      duas: [{ title: 'The Dua of Need', arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ', transliteration: "Allahumma inni as'aluk", translation: 'O Allah, I ask You.', source: 'General' }],
    };
  }

  const teachings = getRelevantTeachings(need);
  const teachingContext = teachings.slice(0, 5).map(t =>
    `${t.name} (${t.arabic}): ${t.emotionalContext.slice(0, 3).join(', ')} — ${t.coreTeaching}\nDua: ${t.dua.arabic} | ${t.dua.transliteration} | ${t.dua.translation} | ${t.dua.source}`
  ).join('\n\n');

  const canonicalList = buildCanonicalNamesPromptList();

  const client = new Anthropic({ apiKey, dangerouslyAllowBrowser: true });
  const message = await client.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 800,
    system: `You are an Islamic learning tool. A person has described what they want to make dua for. Based on the Names of Allah below, identify the 2-3 most fitting Names to call upon for this need, and provide 3-4 relevant duas they can recite.

Available Names and their duas:
${teachingContext}

IMPORTANT — Canonical Names of Allah (you MUST only use Names from this list, exact spelling):
${canonicalList}

Instructions:
- Choose 2-3 Names most relevant to their need — only from the canonical list above
- For each Name, write one sentence explaining why this Name is appropriate to call upon (specific to their need, not generic)
- Provide 3-4 duas — use the exact duas from the Names above where appropriate, and supplement with authentic Quranic/hadith duas if needed
- All duas must be authentic — from Quran or hadith only

Respond with EXACTLY:
##NAMES##
Each name on its own line as: English · Arabic · [one sentence why]
##DUAS##
Each dua as: Title | Arabic | Transliteration | Translation | Source
(one dua per line)`,
    messages: [{ role: 'user', content: need }],
  });

  const raw = message.content
    .filter(b => b.type === 'text')
    .map(b => (b as { type: 'text'; text: string }).text)
    .join('').trim();

  const namesRaw = parseSection(raw, '##NAMES##', '##DUAS##');
  const names = filterValidNames(
    namesRaw.split('\n').filter(l => l.trim() && l.includes('·')).map(line => {
      const parts = line.split('·').map(s => s.trim());
      const whyMatch = parts[2]?.match(/\[(.+)\]/);
      return {
        name: parts[0]?.replace(/^[-\d.)\s]+/, '').trim() ?? '',
        nameArabic: parts[1]?.trim() ?? '',
        why: whyMatch?.[1] ?? parts[2]?.trim() ?? '',
      };
    }).filter(n => n.name.length > 0)
  );

  const duasRaw = parseSection(raw, '##DUAS##');
  const duas = duasRaw.split('\n').filter(l => l.trim() && l.includes('|')).map(line => {
    const parts = line.split('|').map(s => s.trim());
    return {
      title: parts[0]?.replace(/^[-\d.)\s]+/, '').trim() ?? '',
      arabic: parts[1] ?? '',
      transliteration: parts[2] ?? '',
      translation: parts[3] ?? '',
      source: parts[4] ?? '',
    };
  }).filter(d => d.title.length > 0 && d.arabic.length > 0);

  return { names, duas };
}

export interface BuiltDua {
  arabic: string;
  transliteration: string;
  translation: string;
  breakdown: { label: string; arabic: string; transliteration: string; translation: string }[];
  namesUsed: { name: string; nameArabic: string; why: string }[];
  relatedDuas: { title: string; arabic: string; transliteration: string; translation: string; source: string }[];
}

export async function buildDua(need: string): Promise<BuiltDua> {
  const apiKey = process.env.EXPO_PUBLIC_ANTHROPIC_KEY ?? process.env.EXPO_PUBLIC_CLAUDE_API_KEY ?? '';

  if (!apiKey) {
    return {
      arabic: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
      transliteration: 'Bismillahi r-rahmani r-rahim',
      translation: 'In the name of Allah, the Most Gracious, the Most Merciful.',
      breakdown: [{ label: 'Opening', arabic: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ', transliteration: 'Bismillahi r-rahmani r-rahim', translation: 'In the name of Allah, the Most Gracious, the Most Merciful.' }],
      namesUsed: [],
      relatedDuas: [],
    };
  }

  // Get relevant Names from both knowledge bases
  const nameGuidance = getNameGuidanceForNeed(need);
  const knowledgeBaseTeachings = nameGuidance.length < 2 ? getRelevantTeachings(need) : [];

  // Build name context: prioritise duaKnowledge guidance, supplement with knowledgeBase
  const primaryNames = nameGuidance.slice(0, 3).length > 0
    ? nameGuidance.slice(0, 3)
    : knowledgeBaseTeachings.slice(0, 3).map(t => ({
        name: t.name, arabic: t.arabic,
        callFor: t.emotionalContext,
        invocationStyle: t.dua.transliteration,
        samplePhrase: t.dua.arabic,
      }));

  const nameContext = primaryNames.map(n =>
    `- ${n.name} (${n.arabic}): Call upon for ${n.callFor.slice(0, 3).join(', ')}\n  Invocation: ${n.invocationStyle}\n  Sample phrase: ${n.samplePhrase}`
  ).join('\n');

  // Pick the most thematically fitting hamd opening
  const needLower = need.toLowerCase();
  const hamdOpening = HAMD_OPENINGS.find(h =>
    needLower.includes(h.theme) ||
    (h.theme === 'provision' && /money|job|debt|rizq|sustain|provide/.test(needLower)) ||
    (h.theme === 'healing' && /sick|health|ill|pain|hurt|heal/.test(needLower)) ||
    (h.theme === 'guidance' && /guide|lost|direction|confus|decision/.test(needLower)) ||
    (h.theme === 'mercy' && /sin|forgiv|guilt|shame|return/.test(needLower))
  ) ?? HAMD_OPENINGS[0];

  const canonicalNamesList = buildCanonicalNamesPromptList();

  const client = new Anthropic({ apiKey, dangerouslyAllowBrowser: true });
  const message = await client.messages.create({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 2500,
    system: `You are an Islamic scholar constructing a personal dua in classical Arabic following authentic prophetic etiquette (adab al-du'a).

CRITICAL — You MUST only invoke Names of Allah from this canonical list. Do not invent or use any Name not on this list:
${canonicalNamesList}


${DUA_ETIQUETTES}

---

NAMES OF ALLAH MOST RELEVANT TO THIS NEED:
${nameContext}

---

STRUCTURE — follow this EXACTLY, four sections, no exceptions:

SECTION 1 — OPENING PRAISE (Hamd and Thana)
- Begin with hamd of Allah. You may use this authentic opening as your base, then expand with the relevant Names above:
  Arabic: ${hamdOpening.arabic}
  Meaning: ${hamdOpening.translation}
- Praise Allah using the Names most relevant to this specific need. Address Him directly.
- Do NOT make any request yet — this section is praise only.

SECTION 2 — SALAWAT ON THE PROPHET ﷺ
- Use this authentic salawat:
  Arabic: ${SALAWAT_FORMULAS.standard.arabic}
  Transliteration: ${SALAWAT_FORMULAS.standard.transliteration}
- You may expand it slightly but must include the core formula.

SECTION 3 — THE ASK
- Now make the specific request, addressing Allah directly with "Ya [Name]..." or "Allahumma..."
- Be specific and personal to the need — not generic.
- Invoke the relevant Names of Allah within the ask itself.
- Express humility: acknowledge weakness, Allah's power, and trust in His wisdom.
- Use phrases like: "inni as'aluka...", "ya [Name], urzuqni...", "ya [Name], ihdini..."

SECTION 4 — CLOSING
- Send salawat on the Prophet ﷺ again.
- Close with hamd: ${SALAWAT_FORMULAS.closing.arabic}

RULES:
- Classical Arabic with full harakat (vowel marks) throughout
- Every phrase grammatically sound
- The Ask must feel personal to this specific need — not boilerplate
- This is a constructed personal dua, not from hadith — do not claim otherwise

Respond with EXACTLY these 12 markers in order — no extra text outside them:

##S1_ARABIC##
(Arabic of Opening Praise only)
##S1_TRANSLIT##
(transliteration of Opening Praise)
##S1_TRANSLATION##
(English translation of Opening Praise)
##S2_ARABIC##
(Arabic of Salawat only)
##S2_TRANSLIT##
(transliteration of Salawat)
##S2_TRANSLATION##
(English translation of Salawat)
##S3_ARABIC##
(Arabic of The Ask only)
##S3_TRANSLIT##
(transliteration of The Ask)
##S3_TRANSLATION##
(English translation of The Ask)
##S4_ARABIC##
(Arabic of Closing only)
##S4_TRANSLIT##
(transliteration of Closing)
##S4_TRANSLATION##
(English translation of Closing)
##NAMES_USED##
List each Name of Allah you invoked, one per line as: English · Arabic · one sentence on why this Name fits this need
##RELATED_DUAS##
3 authentic duas from Quran or hadith related to this need, each on one line as:
Title | Arabic | Transliteration | Translation | Source`,
    messages: [{ role: 'user', content: `I want to make dua for: ${need}` }],
  });

  const raw = message.content
    .filter(b => b.type === 'text')
    .map(b => (b as { type: 'text'; text: string }).text)
    .join('').trim();

  const SECTION_DEFS = [
    { label: 'Opening Praise', a: '##S1_ARABIC##', t: '##S1_TRANSLIT##', tr: '##S1_TRANSLATION##' },
    { label: 'Salawat',        a: '##S2_ARABIC##', t: '##S2_TRANSLIT##', tr: '##S2_TRANSLATION##' },
    { label: 'The Ask',        a: '##S3_ARABIC##', t: '##S3_TRANSLIT##', tr: '##S3_TRANSLATION##' },
    { label: 'Closing',        a: '##S4_ARABIC##', t: '##S4_TRANSLIT##', tr: '##S4_TRANSLATION##' },
  ];

  const breakdown = SECTION_DEFS.map((s, i) => ({
    label: s.label,
    arabic: parseSection(raw, s.a, s.t),
    transliteration: parseSection(raw, s.t, s.tr),
    translation: parseSection(raw, s.tr, SECTION_DEFS[i + 1]?.a ?? '##NAMES_USED##'),
  })).filter(s => s.arabic.trim().length > 0);

  // Full dua = join all sections
  const arabic = breakdown.map(s => s.arabic).join('\n\n');
  const transliteration = breakdown.map(s => s.transliteration).join('\n\n');
  const translation = breakdown.map(s => s.translation).join('\n\n');

  // Parse names used — filter against canonical list to prevent hallucination
  const namesRaw = parseSection(raw, '##NAMES_USED##', '##RELATED_DUAS##');
  const namesUsed = filterValidNames(
    namesRaw.split('\n').filter(l => l.trim() && l.includes('·')).map(line => {
      const parts = line.split('·').map(s => s.trim());
      return {
        name: parts[0]?.replace(/^[-\d.)\s]+/, '').trim() ?? '',
        nameArabic: parts[1]?.trim() ?? '',
        why: parts[2]?.trim() ?? '',
      };
    }).filter(n => n.name.length > 0)
  );

  // Parse related duas
  const relatedRaw = parseSection(raw, '##RELATED_DUAS##');
  const relatedDuas = relatedRaw.split('\n').filter(l => l.trim() && l.includes('|')).map(line => {
    const parts = line.split('|').map(s => s.trim());
    return {
      title: parts[0]?.replace(/^[-\d.)\s]+/, '').trim() ?? '',
      arabic: parts[1] ?? '',
      transliteration: parts[2] ?? '',
      translation: parts[3] ?? '',
      source: parts[4] ?? '',
    };
  }).filter(d => d.title.length > 0 && d.arabic.length > 0);

  return { arabic, transliteration, translation, breakdown, namesUsed, relatedDuas };
}

export interface DailyReflectResponse {
  name: string;
  nameArabic: string;
  teaching: string;
  duaArabic: string;
  duaTransliteration: string;
  duaTranslation: string;
}

export async function getDailyResponse(question: string, answer: string): Promise<DailyReflectResponse> {
  const apiKey = process.env.EXPO_PUBLIC_ANTHROPIC_KEY ?? process.env.EXPO_PUBLIC_CLAUDE_API_KEY ?? '';

  if (!apiKey) {
    return {
      name: 'Al-Lateef',
      nameArabic: 'اللَّطِيفُ',
      teaching: 'Allah, Al-Lateef — the Subtle, the Gentle — sees the finest details of your heart. His care for you is precise, not general. He knows exactly where you are and what you carry, and He is already working in ways you cannot yet perceive.',
      duaArabic: 'اللَّهُمَّ يَا لَطِيفُ الْطُفْ بِي فِي أُمُورِي كُلِّهَا',
      duaTransliteration: 'Allahumma ya Lateefu, lutf bi fi umuri kulliha',
      duaTranslation: 'O Allah, O Gentle One, be gentle with me in all my affairs.',
    };
  }

  const teachings = getRelevantTeachings(`${question} ${answer}`);
  const teachingContext = teachings
    .slice(0, 4)
    .map(t =>
      `**${t.name} (${t.arabic})**\nCore teaching: ${t.coreTeaching}\nDua: ${t.dua.arabic}\nTransliteration: ${t.dua.transliteration}\nTranslation: ${t.dua.translation}`
    )
    .join('\n\n---\n\n');

  const dailyCanonicalList = buildCanonicalNamesPromptList();

  const client = new Anthropic({ apiKey, dangerouslyAllowBrowser: true });
  const message = await client.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 600,
    system: `You are an Islamic learning tool. A person has answered a daily orientation question. Based on their answer, identify the single most fitting Name of Allah from the list below and write a short, grounded teaching.

${teachingContext}

IMPORTANT — You MUST only use a Name from this canonical list of the 99 Names:
${dailyCanonicalList}

---

Instructions:
1. Choose the single most relevant Name — it MUST be from the canonical list above.
2. Write ONE paragraph (3-5 sentences) explaining what this Name means and how it speaks directly to what they have shared. Be direct and substantive — teach, not comfort. No terms of endearment.
3. Use the exact dua provided for that Name.

Respond with EXACTLY these markers:
##NAME## (English · Arabic)
##TEACHING## (one paragraph)
##DUA_ARABIC##
##DUA_TRANSLITERATION##
##DUA_TRANSLATION##`,
    messages: [{ role: 'user', content: `Question: ${question}\nAnswer: ${answer}` }],
  });

  const raw = message.content
    .filter(b => b.type === 'text')
    .map(b => (b as { type: 'text'; text: string }).text)
    .join('').trim();

  const nameRaw = parseSection(raw, '##NAME##', '##TEACHING##');
  const nameParts = nameRaw.split('·').map(s => s.trim());
  const parsedName = nameParts[0]?.replace(/[()]/g, '').trim() ?? 'Al-Lateef';
  const parsedNameArabic = nameParts[1]?.replace(/[()]/g, '').trim() ?? '';
  const [validatedDailyName] = filterValidNames([{ name: parsedName, nameArabic: parsedNameArabic }]);

  return {
    name: validatedDailyName?.name ?? 'Al-Lateef',
    nameArabic: validatedDailyName?.nameArabic ?? parsedNameArabic,
    teaching: parseSection(raw, '##TEACHING##', '##DUA_ARABIC##'),
    duaArabic: parseSection(raw, '##DUA_ARABIC##', '##DUA_TRANSLITERATION##'),
    duaTransliteration: parseSection(raw, '##DUA_TRANSLITERATION##', '##DUA_TRANSLATION##'),
    duaTranslation: parseSection(raw, '##DUA_TRANSLATION##'),
  };
}

function isOffTopic(text: string): boolean {
  // Catch clearly non-spiritual inputs before spending an API call
  const lower = text.toLowerCase();
  const offTopicPatterns = [
    /^(hi|hello|hey|test|testing|lol|haha|ok|okay|yes|no|maybe|idk)\b/,
    /\b(bathroom|toilet|hungry|food|weather|sport|game|movie|music)\b/,
  ];
  return offTopicPatterns.some(p => p.test(lower));
}

function getDemoResponse(): ReflectResponse {
  const raw = `##NAME## The Most Gentle · اللَّطِيفُ

##REFRAME## Allah, Al-Lateef — the Subtle, the Gentle, the One who knows the finest details of your heart — sees exactly where you are right now. He does not see a burden too heavy; He sees a soul reaching upward, and that reaching itself is worship.

Sheikh Omar Suleiman teaches that Al-Lateef is the Name of Allah that reminds us His interventions are not always thunderbolts. Often He works through the smallest mercies: a kind word at the right moment, a door that opens when you had stopped knocking, a peace that arrives before the answer does.

You are not invisible in your struggle. Al-Lateef is aware of every tremor in your chest. His gentleness is not weakness — it is the most powerful force in existence arranging what you cannot arrange for yourself.

##STORY## There was a time when Musa (peace be upon him) fled alone into the desert, with nothing but the clothes on his back and a heart full of fear. He had left everything behind. Yet when he reached Madyan, exhausted and without provision, he helped two women water their flock — a small act of kindness when he had nothing left to give.

It was that moment of selflessness that Allah used as a hinge point. The father of those women called him in, fed him, sheltered him, and within days his entire life had pivoted. He had not planned it. He had not networked or strategized. Al-Lateef arranged it through a gesture as small as helping strangers with their sheep.

Your story is still being written. The turn you cannot see is closer than you think.

##DUA_ARABIC## اللَّهُمَّ يَا لَطِيفُ الْطُفْ بِي فِي أُمُورِي كُلِّهَا

##DUA_TRANSLITERATION## Allahumma ya Lateefu, lutf bi fi umuri kulliha

##DUA_TRANSLATION## O Allah, O Gentle One, be gentle with me in all my affairs.

##DUA_SOURCE## Traditional dua derived from the Name Al-Lateef

##RELATED_NAMES## Al-Wakil · الْوَكِيلُ | As-Sabur · الصَّبُورُ`;

  return parseClaudeResponse(raw);
}

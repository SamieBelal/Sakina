/**
 * Validates Names of Allah returned by Claude against the canonical 99 Names list.
 * Prevents hallucinated or non-standard names from appearing in the app.
 */
import { ALLAH_NAMES } from '@/constants/allahNames';

// Build a normalised lookup set from the canonical list
// Normalise: lowercase, remove diacritics, remove "al-"/"ar-"/"as-"/"ash-" prefix variation
function normalise(name: string): string {
  return name
    .toLowerCase()
    .replace(/[\u0600-\u06FF\s]/g, '') // strip Arabic script
    .replace(/[^a-z]/g, '')            // strip non-alpha
    .replace(/^(al|ar|as|ash|at|az|an)/, ''); // strip common prefixes
}

const CANONICAL_NORMALISED = new Set(
  ALLAH_NAMES.map(n => normalise(n.transliteration))
);

// Also build a map from normalised -> canonical entry for lookup
const CANONICAL_MAP = new Map(
  ALLAH_NAMES.map(n => [normalise(n.transliteration), n])
);

export function isValidAllahName(name: string): boolean {
  return CANONICAL_NORMALISED.has(normalise(name));
}

/**
 * Given a name string returned by Claude, find the closest canonical match.
 * Returns the canonical entry if found, null if it's a hallucination.
 */
export function findCanonicalName(name: string): { name: string; nameArabic: string } | null {
  const key = normalise(name);
  const entry = CANONICAL_MAP.get(key);
  if (entry) return { name: entry.transliteration, nameArabic: entry.arabic };
  return null;
}

/**
 * Filter a list of {name, nameArabic, ...} objects to only include valid Names.
 * Replaces name/nameArabic with canonical values where a match is found.
 */
export function filterValidNames<T extends { name: string; nameArabic: string }>(
  names: T[]
): T[] {
  return names.reduce<T[]>((acc, item) => {
    const canonical = findCanonicalName(item.name);
    if (canonical) {
      acc.push({ ...item, name: canonical.name, nameArabic: canonical.nameArabic });
    }
    return acc;
  }, []);
}

/**
 * Build a compact canonical names reference string to inject into Claude prompts.
 * This constrains Claude to only use real Names.
 */
export function buildCanonicalNamesPromptList(): string {
  return ALLAH_NAMES.map(n => `${n.transliteration} (${n.arabic}) — ${n.english}`).join('\n');
}

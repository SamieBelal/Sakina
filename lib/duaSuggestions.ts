/**
 * Computes personalised dua suggestions for the home screen and duas landing.
 * Sources: journal reflection names, saved duas, daily answer, saved built duas.
 */
import { DUAS, type Dua } from '@/constants/duas';
import { getJournalEntries } from './journal';
import { getSavedDuas } from './supabase';
import { getSavedBuiltDuas, type SavedBuiltDua } from './savedDuas';
import { getTodaysDailyAnswer } from './dailyQuestion';
import AsyncStorage from '@react-native-async-storage/async-storage';

const READ_KEY = '@sakina_read_suggested_duas';

export interface DuaSuggestion {
  type: 'browse' | 'built';
  reason: string;
  // for browse
  dua?: Dua;
  // for built
  builtDua?: SavedBuiltDua;
}

// Map Names of Allah (lowercase fragments) → dua emotion tags
const NAME_TO_TAGS: Record<string, string[]> = {
  lateef:    ['anxiety', 'hope', 'peace'],
  rahman:    ['morning', 'gratitude', 'hope'],
  rahim:     ['forgiveness', 'hope', 'gratitude'],
  tawwab:    ['forgiveness'],
  ghaffar:   ['forgiveness'],
  ghafur:    ['forgiveness'],
  mujeeb:    ['general', 'hope'],
  wakeel:    ['anxiety', 'protection', 'trust'],
  hafiz:     ['protection'],
  salam:     ['anxiety', 'peace', 'protection'],
  shafi:     ['grief', 'hope'],
  razzaq:    ['general'],
  hadi:      ['hope', 'guidance'],
  sabur:     ['grief', 'anxiety'],
  qarib:     ['general', 'hope'],
  wadud:     ['grief', 'hope', 'gratitude'],
  karim:     ['gratitude', 'hope'],
  shakur:    ['gratitude'],
};

function tagsForName(name: string): string[] {
  const lower = name.toLowerCase();
  for (const [fragment, tags] of Object.entries(NAME_TO_TAGS)) {
    if (lower.includes(fragment)) return tags;
  }
  return [];
}

function score(dua: Dua, targetTags: string[]): number {
  if (!dua.emotionTags) return 0;
  return dua.emotionTags.filter(t => targetTags.includes(t)).length;
}

export async function getDuaSuggestions(): Promise<DuaSuggestion[]> {
  const [entries, savedIds, savedBuilt, dailyAnswer] = await Promise.all([
    getJournalEntries(),
    getSavedDuas(),
    getSavedBuiltDuas(),
    getTodaysDailyAnswer(),
  ]);

  const readIds = await getReadSuggestedDuas();

  const suggestions: DuaSuggestion[] = [];

  // 1. If user has a saved built dua, surface the most recent one not yet shown
  const unshownBuilt = savedBuilt.find(b => !readIds.includes(`built:${b.id}`));
  if (unshownBuilt) {
    suggestions.push({
      type: 'built',
      reason: 'A dua you saved',
      builtDua: unshownBuilt,
    });
  }

  // 2. From reflection journal — use most recent 3 names to derive tags
  const recentNames = entries.slice(0, 3).map(e => e.name);
  const dailyName = dailyAnswer?.name;
  const allNames = dailyName ? [dailyName, ...recentNames] : recentNames;

  const targetTags: string[] = [];
  for (const name of allNames) {
    tagsForName(name).forEach(t => { if (!targetTags.includes(t)) targetTags.push(t); });
  }

  // 3. Score all browse duas by relevance to those tags, exclude already-saved and already-read
  const unread = DUAS.filter(d => !readIds.includes(`browse:${d.id}`));
  const scored = unread
    .map(d => ({ dua: d, s: score(d, targetTags) }))
    .sort((a, b) => b.s - a.s);

  // Pick top 2 (or 1 if we already have a built dua suggestion)
  const limit = suggestions.length > 0 ? 1 : 2;
  const picks = scored.slice(0, limit);

  for (const { dua } of picks) {
    const reasonName = allNames[0] ?? null;
    const reason = reasonName ? `For ${reasonName}` : 'Recommended for you';
    suggestions.push({ type: 'browse', reason, dua });
  }

  // 4. Always surface a time-of-day dua if we have fewer than 2 suggestions
  if (suggestions.length < 2) {
    const hour = new Date().getHours();
    const timeCategory = hour < 12 ? 'morning' : hour < 18 ? 'general' : 'evening';
    const timeDua = DUAS.find(
      d => d.category === timeCategory && !readIds.includes(`browse:${d.id}`) && !suggestions.some(s => s.dua?.id === d.id)
    );
    if (timeDua) {
      const label = timeCategory === 'morning' ? 'Morning' : timeCategory === 'evening' ? 'Evening' : 'Afternoon';
      suggestions.push({ type: 'browse', reason: `${label} dua`, dua: timeDua });
    }
  }

  return suggestions.slice(0, 3);
}

export async function getReadSuggestedDuas(): Promise<string[]> {
  const raw = await AsyncStorage.getItem(READ_KEY);
  return raw ? JSON.parse(raw) : [];
}

export async function markDuaRead(id: string): Promise<void> {
  const existing = await getReadSuggestedDuas();
  if (!existing.includes(id)) {
    await AsyncStorage.setItem(READ_KEY, JSON.stringify([id, ...existing].slice(0, 200)));
  }
}

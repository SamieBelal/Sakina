import AsyncStorage from '@react-native-async-storage/async-storage';

const JOURNAL_KEY = '@sakina_journal';

export interface JournalEntry {
  id: string;
  date: string;           // ISO date string
  userText: string;       // What the user typed
  name: string;           // Name of Allah returned
  nameArabic: string;
  reframe: string;        // First paragraph of reframe only (preview)
  emotionTags: string[];  // Derived from the name's emotionalContext keywords
}

export async function getJournalEntries(): Promise<JournalEntry[]> {
  const raw = await AsyncStorage.getItem(JOURNAL_KEY);
  if (!raw) return [];
  try {
    return JSON.parse(raw);
  } catch {
    return [];
  }
}

export async function saveJournalEntry(entry: Omit<JournalEntry, 'id'>): Promise<void> {
  const entries = await getJournalEntries();
  const newEntry: JournalEntry = {
    ...entry,
    id: `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
  };
  // Most recent first
  const updated = [newEntry, ...entries];
  await AsyncStorage.setItem(JOURNAL_KEY, JSON.stringify(updated));
}

export async function deleteJournalEntry(id: string): Promise<void> {
  const entries = await getJournalEntries();
  const updated = entries.filter(e => e.id !== id);
  await AsyncStorage.setItem(JOURNAL_KEY, JSON.stringify(updated));
}

export function formatJournalDate(isoString: string): string {
  const date = new Date(isoString);
  const now = new Date();
  const diffDays = Math.floor((now.getTime() - date.getTime()) / 86400000);

  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return date.toLocaleDateString('en-US', { weekday: 'long' });
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

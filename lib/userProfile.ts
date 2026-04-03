import AsyncStorage from '@react-native-async-storage/async-storage';
import { type AnchorResult } from '@/constants/quiz';

const ANCHORS_KEY = '@sakina_anchors';
const NAME_COUNTS_KEY = '@sakina_name_counts';

// ─── Anchor Names (from quiz) ─────────────────────────────────────────────

export async function saveAnchors(anchors: AnchorResult[]): Promise<void> {
  await AsyncStorage.setItem(ANCHORS_KEY, JSON.stringify(anchors));
}

export async function getAnchors(): Promise<AnchorResult[]> {
  const raw = await AsyncStorage.getItem(ANCHORS_KEY);
  if (!raw) return [];
  try { return JSON.parse(raw); } catch { return []; }
}

// ─── Name frequency counter ───────────────────────────────────────────────

export type NameCounts = Record<string, number>; // name string → total times shown

export async function getNameCounts(): Promise<NameCounts> {
  const raw = await AsyncStorage.getItem(NAME_COUNTS_KEY);
  if (!raw) return {};
  try { return JSON.parse(raw); } catch { return {}; }
}

export async function incrementNameCount(name: string): Promise<void> {
  const counts = await getNameCounts();
  counts[name] = (counts[name] ?? 0) + 1;
  await AsyncStorage.setItem(NAME_COUNTS_KEY, JSON.stringify(counts));
}

export async function getTopNames(limit = 5): Promise<{ name: string; count: number }[]> {
  const counts = await getNameCounts();
  return Object.entries(counts)
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, limit);
}

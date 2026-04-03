import AsyncStorage from '@react-native-async-storage/async-storage';

const KEY = '@sakina_xp';

export interface XPState {
  total: number;
  level: number;
  title: string;
  titleArabic: string;
  xpForNextLevel: number;
  xpIntoCurrentLevel: number;
}

export const XP_REWARDS = {
  reflection: 25,
  storyRead: 10,
  duaRead: 10,
  dailyStreak: 5,
} as const;

export type XPAction = keyof typeof XP_REWARDS;

const LEVELS: { minXP: number; title: string; titleArabic: string }[] = [
  { minXP: 0,    title: 'Seeker',      titleArabic: 'طَالِب' },
  { minXP: 50,   title: 'Reflector',   titleArabic: 'مُتَفَكِّر' },
  { minXP: 150,  title: 'Devoted',     titleArabic: 'مُخْلِص' },
  { minXP: 350,  title: 'Enlightened', titleArabic: 'مُنَوَّر' },
  { minXP: 700,  title: 'Sage',        titleArabic: 'حَكِيم' },
];

function getLevelData(total: number): { level: number; title: string; titleArabic: string; xpForNextLevel: number; xpIntoCurrentLevel: number } {
  let current = LEVELS[0];
  let currentIndex = 0;
  for (let i = 0; i < LEVELS.length; i++) {
    if (total >= LEVELS[i].minXP) {
      current = LEVELS[i];
      currentIndex = i;
    }
  }
  const next = LEVELS[currentIndex + 1];
  const xpForNextLevel = next ? next.minXP - current.minXP : 0;
  const xpIntoCurrentLevel = next ? total - current.minXP : xpForNextLevel;
  return {
    level: currentIndex + 1,
    title: current.title,
    titleArabic: current.titleArabic,
    xpForNextLevel,
    xpIntoCurrentLevel,
  };
}

export async function getXP(): Promise<XPState> {
  const raw = await AsyncStorage.getItem(KEY);
  const total = raw ? JSON.parse(raw) : 0;
  return { total, ...getLevelData(total) };
}

export async function awardXP(action: XPAction): Promise<{ xpState: XPState; gained: number; leveledUp: boolean }> {
  const gained = XP_REWARDS[action];
  const raw = await AsyncStorage.getItem(KEY);
  const prev = raw ? JSON.parse(raw) : 0;
  const prevLevel = getLevelData(prev).level;
  const next = prev + gained;
  await AsyncStorage.setItem(KEY, JSON.stringify(next));
  const xpState = { total: next, ...getLevelData(next) };
  return { xpState, gained, leveledUp: xpState.level > prevLevel };
}

import AsyncStorage from '@react-native-async-storage/async-storage';

const KEY = '@sakina_streak';

export async function getLocalStreak(): Promise<number> {
  const raw = await AsyncStorage.getItem(KEY);
  if (!raw) return 0;
  const { streak, lastActive } = JSON.parse(raw);
  const today = new Date().toISOString().split('T')[0];
  const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
  if (lastActive === today || lastActive === yesterday) return streak;
  return 0;
}

export async function markActiveToday(): Promise<number> {
  const today = new Date().toISOString().split('T')[0];
  const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
  const raw = await AsyncStorage.getItem(KEY);

  let streak = 1;
  if (raw) {
    const parsed = JSON.parse(raw);
    if (parsed.lastActive === today) return parsed.streak;
    if (parsed.lastActive === yesterday) streak = parsed.streak + 1;
  }

  await AsyncStorage.setItem(KEY, JSON.stringify({ streak, lastActive: today }));
  return streak;
}

export async function getActivityLog(): Promise<string[]> {
  const raw = await AsyncStorage.getItem('@sakina_activity');
  return raw ? JSON.parse(raw) : [];
}

export async function logActivity(): Promise<void> {
  const today = new Date().toISOString().split('T')[0];
  const log = await getActivityLog();
  if (!log.includes(today)) {
    await AsyncStorage.setItem('@sakina_activity', JSON.stringify([...log, today]));
  }
}

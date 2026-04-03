import 'react-native-url-polyfill/auto';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL ?? '';
const supabaseAnonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY ?? '';

const hasSupabase = Boolean(supabaseUrl && supabaseAnonKey);

export const supabase: SupabaseClient | null = hasSupabase
  ? createClient(supabaseUrl, supabaseAnonKey, {
      auth: {
        storage: AsyncStorage,
        autoRefreshToken: true,
        persistSession: true,
        detectSessionInUrl: false,
      },
    })
  : null;

// Streak helpers
export async function getStreak(userId: string): Promise<number> {
  if (!supabase) return getLocalStreak();
  const { data } = await supabase
    .from('streaks')
    .select('current_streak, last_active')
    .eq('user_id', userId)
    .single();
  return data?.current_streak ?? 0;
}

export async function updateStreak(userId: string): Promise<number> {
  if (!supabase) return updateLocalStreak();
  const today = new Date().toISOString().split('T')[0];
  const { data: existing } = await supabase
    .from('streaks')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (!existing) {
    await supabase.from('streaks').insert({
      user_id: userId,
      current_streak: 1,
      longest_streak: 1,
      last_active: today,
    });
    return 1;
  }

  const lastActive = existing.last_active;
  const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];

  let newStreak = existing.current_streak;
  if (lastActive === today) return newStreak;
  if (lastActive === yesterday) newStreak += 1;
  else newStreak = 1;

  await supabase
    .from('streaks')
    .update({
      current_streak: newStreak,
      longest_streak: Math.max(newStreak, existing.longest_streak),
      last_active: today,
    })
    .eq('user_id', userId);

  return newStreak;
}

// Local (offline) streak fallback using AsyncStorage
async function getLocalStreak(): Promise<number> {
  const raw = await AsyncStorage.getItem('@sakina_streak');
  if (!raw) return 0;
  const { streak, lastActive } = JSON.parse(raw);
  const today = new Date().toISOString().split('T')[0];
  const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
  if (lastActive === today || lastActive === yesterday) return streak;
  return 0;
}

async function updateLocalStreak(): Promise<number> {
  const today = new Date().toISOString().split('T')[0];
  const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
  const raw = await AsyncStorage.getItem('@sakina_streak');

  let streak = 1;
  if (raw) {
    const parsed = JSON.parse(raw);
    if (parsed.lastActive === today) return parsed.streak;
    if (parsed.lastActive === yesterday) streak = parsed.streak + 1;
  }

  await AsyncStorage.setItem('@sakina_streak', JSON.stringify({ streak, lastActive: today }));
  return streak;
}

// Saved duas
export async function getSavedDuas(): Promise<string[]> {
  const raw = await AsyncStorage.getItem('@sakina_saved_duas');
  return raw ? JSON.parse(raw) : [];
}

export async function toggleSavedDua(duaId: string): Promise<string[]> {
  const saved = await getSavedDuas();
  const updated = saved.includes(duaId)
    ? saved.filter((id) => id !== duaId)
    : [...saved, duaId];
  await AsyncStorage.setItem('@sakina_saved_duas', JSON.stringify(updated));
  return updated;
}

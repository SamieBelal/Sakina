import AsyncStorage from '@react-native-async-storage/async-storage';

const KEY = '@sakina_saved_built_duas';

export interface SavedBuiltDua {
  id: string;
  savedAt: string;
  need: string;
  arabic: string;
  transliteration: string;
  translation: string;
}

export async function getSavedBuiltDuas(): Promise<SavedBuiltDua[]> {
  const raw = await AsyncStorage.getItem(KEY);
  return raw ? JSON.parse(raw) : [];
}

export async function saveBuiltDua(dua: Omit<SavedBuiltDua, 'id' | 'savedAt'>): Promise<SavedBuiltDua> {
  const saved = await getSavedBuiltDuas();
  const entry: SavedBuiltDua = {
    ...dua,
    id: Date.now().toString(),
    savedAt: new Date().toISOString(),
  };
  await AsyncStorage.setItem(KEY, JSON.stringify([entry, ...saved]));
  return entry;
}

export async function removeSavedBuiltDua(id: string): Promise<void> {
  const saved = await getSavedBuiltDuas();
  await AsyncStorage.setItem(KEY, JSON.stringify(saved.filter(d => d.id !== id)));
}

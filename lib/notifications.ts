import * as Notifications from 'expo-notifications';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';

const NOTIF_ENABLED_KEY = '@sakina_notif_enabled';
const NOTIF_HOUR_KEY = '@sakina_notif_hour';
const NOTIF_MINUTE_KEY = '@sakina_notif_minute';
const NOTIF_ID_KEY = '@sakina_notif_id';

const CHECK_IN_MESSAGES = [
  'How are you feeling today?',
  'Take a moment to reflect. How is your heart?',
  'Your heart deserves a moment. How are you today?',
  'A quiet check-in — how are you feeling right now?',
  'Pause and reflect. What is on your heart today?',
];

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowBanner: true,
    shouldPlaySound: false,
    shouldSetBadge: false,
    shouldShowList: true,
  }),
});

export async function requestNotificationPermission(): Promise<boolean> {
  if (Platform.OS === 'web') return false;

  const { status: existing } = await Notifications.getPermissionsAsync();
  if (existing === 'granted') return true;

  const { status } = await Notifications.requestPermissionsAsync();
  return status === 'granted';
}

export async function scheduleCheckIn(hour: number, minute: number): Promise<void> {
  // Cancel any existing scheduled check-in first
  await cancelCheckIn();

  const granted = await requestNotificationPermission();
  if (!granted) return;

  const body = CHECK_IN_MESSAGES[Math.floor(Math.random() * CHECK_IN_MESSAGES.length)];

  const id = await Notifications.scheduleNotificationAsync({
    content: {
      title: 'Sakina',
      body,
      data: { screen: 'reflect' },
    },
    trigger: {
      type: Notifications.SchedulableTriggerInputTypes.DAILY,
      hour,
      minute,
    },
  });

  await AsyncStorage.multiSet([
    [NOTIF_ENABLED_KEY, 'true'],
    [NOTIF_HOUR_KEY, String(hour)],
    [NOTIF_MINUTE_KEY, String(minute)],
    [NOTIF_ID_KEY, id],
  ]);
}

export async function cancelCheckIn(): Promise<void> {
  const id = await AsyncStorage.getItem(NOTIF_ID_KEY);
  if (id) {
    await Notifications.cancelScheduledNotificationAsync(id);
  }
  await AsyncStorage.multiRemove([NOTIF_ENABLED_KEY, NOTIF_ID_KEY]);
}

export async function getNotificationPrefs(): Promise<{
  enabled: boolean;
  hour: number;
  minute: number;
}> {
  const [enabled, hour, minute] = await AsyncStorage.multiGet([
    NOTIF_ENABLED_KEY,
    NOTIF_HOUR_KEY,
    NOTIF_MINUTE_KEY,
  ]);
  return {
    enabled: enabled[1] === 'true',
    hour: parseInt(hour[1] ?? '8', 10),
    minute: parseInt(minute[1] ?? '0', 10),
  };
}

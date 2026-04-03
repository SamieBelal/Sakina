import { Stack, useRouter, useSegments } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Notifications from 'expo-notifications';
import { Colors } from '@/constants/colors';
import { AuthProvider, useAuth } from '@/lib/auth';
import { ONBOARDING_COMPLETE_KEY } from './onboarding';

function RootNavigator() {
  const { user, isGuest, isLoading } = useAuth();
  const router = useRouter();
  const segments = useSegments();

  useEffect(() => {
    const sub = Notifications.addNotificationResponseReceivedListener(response => {
      const screen = response.notification.request.content.data?.screen;
      if (screen === 'reflect') router.push('/(tabs)/reflect');
    });
    return () => sub.remove();
  }, []);

  useEffect(() => {
    if (isLoading) return;
    const inAuth = segments[0] === 'welcome';
    const inOnboarding = segments[0] === 'onboarding';
    const hasAccess = user || isGuest;

    if (!hasAccess && !inAuth) {
      router.replace('/welcome');
      return;
    }

    if (hasAccess && !inAuth && !inOnboarding) {
      AsyncStorage.getItem(ONBOARDING_COMPLETE_KEY).then(done => {
        if (!done) router.replace('/onboarding');
      });
    }
  }, [user, isGuest, isLoading, segments]);

  return (
    <>
      <StatusBar style="dark" backgroundColor={Colors.background} />
      <Stack screenOptions={{ headerShown: false }} />
    </>
  );
}

export default function RootLayout() {
  return (
    <AuthProvider>
      <RootNavigator />
    </AuthProvider>
  );
}

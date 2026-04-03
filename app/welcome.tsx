import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Colors } from '@/constants/colors';
import { useAuth } from '@/lib/auth';

type Mode = 'landing' | 'signin' | 'signup';

export default function WelcomeScreen() {
  const router = useRouter();
  const { signIn, signUp, upgradeGuest, continueAsGuest, isGuest, user } = useAuth();
  const isUpgrading = isGuest && !user;
  const [mode, setMode] = useState<Mode>(isUpgrading ? 'signup' : 'landing');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleGuest = async () => {
    await continueAsGuest();
    router.replace('/(tabs)');
  };

  const handleSubmit = async () => {
    if (!email.trim() || !password.trim()) {
      setError('Please enter your email and password.');
      return;
    }
    setError('');
    setLoading(true);
    let err: string | null;
    if (mode === 'signup') {
      err = isUpgrading ? await upgradeGuest(email.trim(), password) : await signUp(email.trim(), password);
    } else {
      err = await signIn(email.trim(), password);
    }
    setLoading(false);
    if (err) {
      setError(err);
    } else {
      router.replace('/(tabs)');
    }
  };

  if (mode === 'landing') {
    return (
      <View style={styles.safe}>
        <View style={styles.landingContent}>
          <View style={styles.logoArea}>
            <Text style={styles.logoArabic}>سَكِينَة</Text>
            <Text style={styles.logoLatin}>Sakina</Text>
            <Text style={styles.tagline}>Find peace through the Names of Allah</Text>
          </View>

          <View style={styles.actions}>
            <TouchableOpacity style={styles.primaryBtn} onPress={() => setMode('signup')} activeOpacity={0.85}>
              <Text style={styles.primaryBtnText}>Create account</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.secondaryBtn} onPress={() => setMode('signin')} activeOpacity={0.85}>
              <Text style={styles.secondaryBtnText}>Sign in</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.ghostBtn} onPress={handleGuest} activeOpacity={0.7}>
              <Text style={styles.ghostBtnText}>Continue without account</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView style={styles.safe} behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
      <ScrollView contentContainerStyle={styles.formOuter} keyboardShouldPersistTaps="handled">
        <TouchableOpacity
          onPress={() => isUpgrading ? router.back() : (setMode('landing'), setError(''))}
          style={styles.backBtn}
        >
          <Text style={styles.backBtnText}>‹ Back</Text>
        </TouchableOpacity>

        <Text style={styles.formTitle}>{mode === 'signup' ? 'Create account' : 'Welcome back'}</Text>
        <Text style={styles.formSubtitle}>
          {mode === 'signup'
            ? isUpgrading ? 'Your streak and progress will be saved to your account.' : 'Save your streak and duas across devices.'
            : 'Sign in to sync your progress.'}
        </Text>

        <View style={styles.fields}>
          <TextInput
            style={styles.input}
            placeholder="Email"
            placeholderTextColor={Colors.textMuted}
            autoCapitalize="none"
            keyboardType="email-address"
            value={email}
            onChangeText={setEmail}
          />
          <TextInput
            style={styles.input}
            placeholder="Password"
            placeholderTextColor={Colors.textMuted}
            secureTextEntry
            value={password}
            onChangeText={setPassword}
          />
        </View>

        {error ? <Text style={styles.error}>{error}</Text> : null}

        <TouchableOpacity style={styles.primaryBtn} onPress={handleSubmit} disabled={loading} activeOpacity={0.85}>
          {loading
            ? <ActivityIndicator color={Colors.white} />
            : <Text style={styles.primaryBtnText}>{mode === 'signup' ? 'Create account' : 'Sign in'}</Text>
          }
        </TouchableOpacity>

        <TouchableOpacity onPress={() => { setMode(mode === 'signup' ? 'signin' : 'signup'); setError(''); }} style={styles.switchBtn}>
          <Text style={styles.switchBtnText}>
            {mode === 'signup' ? 'Already have an account? Sign in' : "Don't have an account? Sign up"}
          </Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.ghostBtn} onPress={handleGuest} activeOpacity={0.7}>
          <Text style={styles.ghostBtnText}>Continue without account</Text>
        </TouchableOpacity>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.background },
  landingContent: {
    flex: 1,
    padding: 32,
    justifyContent: 'space-between',
    paddingTop: 100,
    paddingBottom: 60,
  },
  logoArea: { alignItems: 'center', gap: 8 },
  logoArabic: { fontSize: 56, color: Colors.primaryDark, lineHeight: 72 },
  logoLatin: { fontSize: 28, fontWeight: '800', color: Colors.textPrimary, letterSpacing: -0.5 },
  tagline: { fontSize: 15, color: Colors.textMuted, textAlign: 'center', marginTop: 8 },

  actions: { gap: 12 },
  primaryBtn: {
    backgroundColor: Colors.primary,
    borderRadius: 16,
    paddingVertical: 18,
    alignItems: 'center',
  },
  primaryBtnText: { color: Colors.white, fontSize: 16, fontWeight: '700' },
  secondaryBtn: {
    backgroundColor: Colors.white,
    borderRadius: 16,
    paddingVertical: 18,
    alignItems: 'center',
    borderWidth: 1.5,
    borderColor: Colors.border,
  },
  secondaryBtnText: { color: Colors.textPrimary, fontSize: 16, fontWeight: '600' },
  ghostBtn: { alignItems: 'center', paddingVertical: 12 },
  ghostBtnText: { color: Colors.textMuted, fontSize: 14 },

  formOuter: { padding: 28, paddingTop: 60, gap: 16 },
  backBtn: { marginBottom: 8 },
  backBtnText: { fontSize: 16, color: Colors.primary, fontWeight: '600' },
  formTitle: { fontSize: 26, fontWeight: '800', color: Colors.textPrimary, letterSpacing: -0.5 },
  formSubtitle: { fontSize: 14, color: Colors.textMuted, lineHeight: 20 },
  fields: { gap: 12, marginTop: 8 },
  input: {
    backgroundColor: Colors.white,
    borderRadius: 14,
    paddingHorizontal: 18,
    paddingVertical: 16,
    fontSize: 16,
    color: Colors.textPrimary,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  error: { fontSize: 13, color: '#C0392B', lineHeight: 18 },
  switchBtn: { alignItems: 'center', paddingVertical: 4 },
  switchBtnText: { color: Colors.primary, fontSize: 14, fontWeight: '500' },
});

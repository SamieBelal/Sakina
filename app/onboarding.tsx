import React, { useState, useRef } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  Animated,
  Dimensions,
} from 'react-native';
import { useRouter } from 'expo-router';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Colors } from '@/constants/colors';
import { scheduleCheckIn, requestNotificationPermission } from '@/lib/notifications';

export const ONBOARDING_COMPLETE_KEY = '@sakina_onboarding_complete';
export const ONBOARDING_STRUGGLES_KEY = '@sakina_onboarding_struggles';
export const ONBOARDING_REASON_KEY = '@sakina_onboarding_reason';

const { width } = Dimensions.get('window');

const REASONS = [
  { id: 'strengthen', label: 'Strengthen my relationship with Allah', icon: '✦' },
  { id: 'difficult', label: "I'm going through a difficult time", icon: '◎' },
  { id: 'habits', label: 'Build better spiritual habits', icon: '☽' },
  { id: 'curious', label: 'Curious about Islamic emotional wellness', icon: '◈' },
] as const;

type ReasonId = typeof REASONS[number]['id'];

const STRUGGLES = [
  { id: 'anxiety', label: 'Anxiety & Worry', icon: '🫁' },
  { id: 'sadness', label: 'Sadness & Grief', icon: '🌧' },
  { id: 'purpose', label: 'Lack of Purpose', icon: '🧭' },
  { id: 'disconnected', label: 'Feeling Far from Allah', icon: '🌙' },
  { id: 'anger', label: 'Anger & Frustration', icon: '🌊' },
  { id: 'loneliness', label: 'Loneliness', icon: '🕊' },
] as const;

type StruggleId = typeof STRUGGLES[number]['id'];

type Step = 'reason' | 'struggles' | 'ready';

export default function OnboardingScreen() {
  const router = useRouter();
  const [step, setStep] = useState<Step>('reason');
  const [selectedReason, setSelectedReason] = useState<ReasonId | null>(null);
  const [selectedStruggles, setSelectedStruggles] = useState<Set<StruggleId>>(new Set());
  const fadeAnim = useRef(new Animated.Value(1)).current;

  const transitionTo = (next: Step) => {
    Animated.timing(fadeAnim, {
      toValue: 0,
      duration: 180,
      useNativeDriver: true,
    }).start(() => {
      setStep(next);
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 220,
        useNativeDriver: true,
      }).start();
    });
  };

  const toggleStruggle = (id: StruggleId) => {
    setSelectedStruggles(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const handleComplete = async () => {
    await AsyncStorage.setItem(ONBOARDING_COMPLETE_KEY, 'true');
    if (selectedReason) {
      await AsyncStorage.setItem(ONBOARDING_REASON_KEY, selectedReason);
    }
    if (selectedStruggles.size > 0) {
      await AsyncStorage.setItem(
        ONBOARDING_STRUGGLES_KEY,
        JSON.stringify(Array.from(selectedStruggles))
      );
    }
    router.replace('/(tabs)');
  };

  const stepIndex = step === 'reason' ? 0 : step === 'struggles' ? 1 : 2;

  return (
    <SafeAreaView style={styles.safe}>
      {/* Progress dots */}
      <View style={styles.progressRow}>
        {[0, 1, 2].map(i => (
          <View
            key={i}
            style={[styles.dot, i <= stepIndex && styles.dotActive]}
          />
        ))}
      </View>

      <Animated.View style={[styles.content, { opacity: fadeAnim }]}>
        {step === 'reason' && (
          <ReasonStep
            selected={selectedReason}
            onSelect={id => {
              setSelectedReason(id);
              setTimeout(() => transitionTo('struggles'), 250);
            }}
          />
        )}
        {step === 'struggles' && (
          <StrugglesStep
            selected={selectedStruggles}
            onToggle={toggleStruggle}
            onContinue={() => transitionTo('ready')}
          />
        )}
        {step === 'ready' && (
          <ReadyStep struggles={selectedStruggles} onComplete={handleComplete} />
        )}
      </Animated.View>
    </SafeAreaView>
  );
}

function ReasonStep({
  selected,
  onSelect,
}: {
  selected: ReasonId | null;
  onSelect: (id: ReasonId) => void;
}) {
  return (
    <ScrollView contentContainerStyle={styles.stepContent} showsVerticalScrollIndicator={false}>
      <View style={styles.stepHeader}>
        <Text style={styles.arabicSmall}>سَكِينَة</Text>
        <Text style={styles.stepTitle}>What brings you here?</Text>
        <Text style={styles.stepSubtitle}>
          This helps us make your experience personal to you.
        </Text>
      </View>

      <View style={styles.optionsCol}>
        {REASONS.map(r => (
          <TouchableOpacity
            key={r.id}
            style={[styles.optionRow, selected === r.id && styles.optionRowActive]}
            onPress={() => onSelect(r.id)}
            activeOpacity={0.75}
          >
            <Text style={styles.optionIcon}>{r.icon}</Text>
            <Text style={[styles.optionLabel, selected === r.id && styles.optionLabelActive]}>
              {r.label}
            </Text>
            {selected === r.id && <Text style={styles.optionCheck}>✓</Text>}
          </TouchableOpacity>
        ))}
      </View>
    </ScrollView>
  );
}

function StrugglesStep({
  selected,
  onToggle,
  onContinue,
}: {
  selected: Set<StruggleId>;
  onToggle: (id: StruggleId) => void;
  onContinue: () => void;
}) {
  return (
    <ScrollView contentContainerStyle={styles.stepContent} showsVerticalScrollIndicator={false}>
      <View style={styles.stepHeader}>
        <Text style={styles.stepTitle}>What do you struggle with most?</Text>
        <Text style={styles.stepSubtitle}>
          Select all that apply. We'll make sure you have the right guidance.
        </Text>
      </View>

      <View style={styles.tileGrid}>
        {STRUGGLES.map(s => {
          const active = selected.has(s.id);
          return (
            <TouchableOpacity
              key={s.id}
              style={[styles.tile, active && styles.tileActive]}
              onPress={() => onToggle(s.id)}
              activeOpacity={0.75}
            >
              <Text style={styles.tileIcon}>{s.icon}</Text>
              <Text style={[styles.tileLabel, active && styles.tileLabelActive]}>
                {s.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>

      <TouchableOpacity
        style={[styles.continueBtn, selected.size === 0 && styles.continueBtnDisabled]}
        onPress={onContinue}
        disabled={selected.size === 0}
        activeOpacity={0.85}
      >
        <Text style={styles.continueBtnText}>Continue</Text>
      </TouchableOpacity>

      <TouchableOpacity onPress={onContinue} style={styles.skipBtn}>
        <Text style={styles.skipBtnText}>Skip for now</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const STRUGGLE_TO_MESSAGE: Record<StruggleId, { name: string; arabic: string; line: string }> = {
  anxiety: {
    name: 'Al-Wakil',
    arabic: 'الْوَكِيلُ',
    line: 'The One who handles what you cannot. You were never meant to carry this alone.',
  },
  sadness: {
    name: 'Al-Wadud',
    arabic: 'الْوَدُودُ',
    line: 'The Most Loving. Hardship is not His rejection — it is His closeness.',
  },
  purpose: {
    name: 'Al-Hadi',
    arabic: 'الْهَادِي',
    line: 'The Guide. When you feel lost, He is the One who clears the path.',
  },
  disconnected: {
    name: 'Al-Qarib',
    arabic: 'الْقَرِيبُ',
    line: 'The Near. He is closer to you than you are to yourself.',
  },
  anger: {
    name: 'Al-Halim',
    arabic: 'الْحَلِيمُ',
    line: 'The Forbearing. He sees your frustration and does not abandon you.',
  },
  loneliness: {
    name: 'Al-Wali',
    arabic: 'الْوَلِيُّ',
    line: 'The Protecting Friend. You are never truly without a companion.',
  },
};

function ReadyStep({
  struggles,
  onComplete,
}: {
  struggles: Set<StruggleId>;
  onComplete: () => void;
}) {
  const [notifAsked, setNotifAsked] = useState(false);

  // Pick the first selected struggle to show a preview; fallback to purpose
  const firstStruggle: StruggleId =
    struggles.size > 0 ? Array.from(struggles)[0] : 'purpose';
  const preview = STRUGGLE_TO_MESSAGE[firstStruggle];

  const handleEnableNotifs = async () => {
    const granted = await requestNotificationPermission();
    if (granted) {
      await scheduleCheckIn(8, 0); // default 8:00 AM, user can change in profile
    }
    setNotifAsked(true);
  };

  return (
    <View style={styles.readyContent}>
      <View style={styles.stepHeader}>
        <Text style={styles.stepTitle}>Sakina is ready for you.</Text>
        <Text style={styles.stepSubtitle}>
          Here's one of the Names of Allah we think you need right now.
        </Text>
      </View>

      <View style={styles.previewCard}>
        <Text style={styles.previewLabel}>A Name for your heart</Text>
        <Text style={styles.previewArabic}>{preview.arabic}</Text>
        <Text style={styles.previewName}>{preview.name}</Text>
        <View style={styles.previewDivider} />
        <Text style={styles.previewLine}>{preview.line}</Text>
      </View>

      {!notifAsked ? (
        <View style={styles.notifPrompt}>
          <Text style={styles.notifPromptTitle}>Get a daily check-in?</Text>
          <Text style={styles.notifPromptBody}>
            A gentle nudge each morning: "How are you feeling today?" — straight into Reflect.
          </Text>
          <TouchableOpacity style={styles.continueBtn} onPress={handleEnableNotifs} activeOpacity={0.85}>
            <Text style={styles.continueBtnText}>Yes, remind me</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.skipBtn} onPress={() => setNotifAsked(true)}>
            <Text style={styles.skipBtnText}>Not now</Text>
          </TouchableOpacity>
        </View>
      ) : (
        <>
          <Text style={styles.readyCta}>
            Use the Reflect tab to go deeper with any Name of Allah — anytime you need it.
          </Text>
          <TouchableOpacity style={styles.continueBtn} onPress={onComplete} activeOpacity={0.85}>
            <Text style={styles.continueBtnText}>Enter Sakina</Text>
          </TouchableOpacity>
        </>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.background },
  progressRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 8,
    paddingTop: 16,
    paddingBottom: 8,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: Colors.border,
  },
  dotActive: {
    backgroundColor: Colors.primary,
  },
  content: { flex: 1 },

  // Step shared
  stepContent: {
    padding: 28,
    paddingTop: 20,
    gap: 24,
  },
  stepHeader: { gap: 8 },
  arabicSmall: {
    fontSize: 22,
    color: Colors.primaryDark,
    marginBottom: 4,
  },
  stepTitle: {
    fontSize: 26,
    fontWeight: '800',
    color: Colors.textPrimary,
    letterSpacing: -0.5,
    lineHeight: 34,
  },
  stepSubtitle: {
    fontSize: 14,
    color: Colors.textMuted,
    lineHeight: 22,
  },

  // Reason step
  optionsCol: { gap: 12 },
  optionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.white,
    borderRadius: 16,
    padding: 18,
    gap: 14,
    borderWidth: 1.5,
    borderColor: Colors.border,
  },
  optionRowActive: {
    borderColor: Colors.primary,
    backgroundColor: Colors.primary + '08',
  },
  optionIcon: { fontSize: 18, width: 24, textAlign: 'center' },
  optionLabel: {
    flex: 1,
    fontSize: 15,
    color: Colors.textPrimary,
    fontWeight: '500',
    lineHeight: 22,
  },
  optionLabelActive: { color: Colors.primaryDark, fontWeight: '600' },
  optionCheck: { fontSize: 16, color: Colors.primary, fontWeight: '700' },

  // Struggles step
  tileGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  tile: {
    width: (width - 56 - 12) / 2,
    backgroundColor: Colors.white,
    borderRadius: 16,
    padding: 18,
    gap: 8,
    borderWidth: 1.5,
    borderColor: Colors.border,
    alignItems: 'flex-start',
  },
  tileActive: {
    borderColor: Colors.primary,
    backgroundColor: Colors.primary + '08',
  },
  tileIcon: { fontSize: 22 },
  tileLabel: {
    fontSize: 14,
    color: Colors.textSecondary,
    fontWeight: '500',
    lineHeight: 20,
  },
  tileLabelActive: { color: Colors.primaryDark, fontWeight: '600' },

  // Continue / skip
  continueBtn: {
    backgroundColor: Colors.primary,
    borderRadius: 16,
    paddingVertical: 18,
    alignItems: 'center',
    marginTop: 8,
  },
  continueBtnDisabled: { opacity: 0.4 },
  continueBtnText: { color: Colors.white, fontSize: 16, fontWeight: '700' },
  skipBtn: { alignItems: 'center', paddingVertical: 12 },
  skipBtnText: { color: Colors.textMuted, fontSize: 14 },

  // Ready step
  readyContent: {
    flex: 1,
    padding: 28,
    paddingTop: 20,
    gap: 24,
    justifyContent: 'center',
  },
  previewCard: {
    backgroundColor: Colors.white,
    borderRadius: 24,
    padding: 28,
    alignItems: 'center',
    shadowColor: Colors.cardShadow,
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 1,
    shadowRadius: 20,
    elevation: 6,
    gap: 6,
  },
  previewLabel: {
    fontSize: 11,
    color: Colors.textMuted,
    letterSpacing: 1.5,
    textTransform: 'uppercase',
    fontWeight: '500',
    marginBottom: 8,
  },
  previewArabic: {
    fontSize: 44,
    color: Colors.primaryDark,
    lineHeight: 60,
    textAlign: 'center',
  },
  previewName: {
    fontSize: 18,
    fontWeight: '700',
    color: Colors.textPrimary,
    marginBottom: 4,
  },
  previewDivider: {
    width: 36,
    height: 1.5,
    backgroundColor: Colors.border,
    marginVertical: 8,
  },
  previewLine: {
    fontSize: 14,
    color: Colors.textSecondary,
    textAlign: 'center',
    lineHeight: 22,
    fontStyle: 'italic',
  },
  readyCta: {
    fontSize: 14,
    color: Colors.textMuted,
    textAlign: 'center',
    lineHeight: 22,
    paddingHorizontal: 8,
  },
  notifPrompt: { gap: 12 },
  notifPromptTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: Colors.textPrimary,
    textAlign: 'center',
  },
  notifPromptBody: {
    fontSize: 14,
    color: Colors.textMuted,
    textAlign: 'center',
    lineHeight: 22,
    paddingHorizontal: 8,
    marginBottom: 4,
  },
});

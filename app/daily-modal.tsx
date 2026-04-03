import React, { useState, useRef, useCallback, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  Animated,
  ScrollView,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Colors } from '@/constants/colors';
import { getTodaysDailyQuestion, saveDailyAnswer } from '@/lib/dailyQuestion';
import { getDailyResponse } from '@/lib/claude';
import { awardXP, type XPState } from '@/lib/xp';
import { XPCelebration } from '@/components/XPCelebration';

type Step = 'question' | 'loading' | 'result';

export default function DailyModal() {
  const router = useRouter();
  const question = getTodaysDailyQuestion();

  const [step, setStep] = useState<Step>('question');
  const [selectedOption, setSelectedOption] = useState<string | null>(null);
  const [result, setResult] = useState<{
    name: string; nameArabic: string; teaching: string;
    duaArabic: string; duaTransliteration: string; duaTranslation: string;
  } | null>(null);

  const fadeAnim = useRef(new Animated.Value(1)).current;
  const ripple1 = useRef(new Animated.Value(0)).current;
  const ripple2 = useRef(new Animated.Value(0)).current;
  const ripple3 = useRef(new Animated.Value(0)).current;
  const rippleActive = useRef(false);

  // XP toast
  const [celebration, setCelebration] = useState<{ gained: number; xpState: XPState; message: string } | null>(null);

  useEffect(() => {
    if (step === 'loading') {
      rippleActive.current = true;
      const runRipple = (anim: Animated.Value, delay: number) => {
        const cycle = () => {
          if (!rippleActive.current) return;
          anim.setValue(0);
          Animated.timing(anim, { toValue: 1, duration: 1600, useNativeDriver: true })
            .start(({ finished }) => { if (finished && rippleActive.current) cycle(); });
        };
        setTimeout(cycle, delay);
      };
      runRipple(ripple1, 0);
      runRipple(ripple2, 530);
      runRipple(ripple3, 1060);
    } else {
      rippleActive.current = false;
      ripple1.setValue(0); ripple2.setValue(0); ripple3.setValue(0);
    }
  }, [step]);

  const fadeTo = useCallback((val: number, duration = 350, cb?: () => void) => {
    Animated.timing(fadeAnim, { toValue: val, duration, useNativeDriver: true })
      .start(() => cb?.());
  }, [fadeAnim]);

  const handleAnswer = useCallback(async (option: string) => {
    setSelectedOption(option);
    fadeTo(0, 250, async () => {
      setStep('loading');
      fadeAnim.setValue(1);
      try {
        const response = await getDailyResponse(question.question, option);
        setResult(response);

        await saveDailyAnswer({
          questionId: question.id,
          answer: option,
          name: response.name,
          nameArabic: response.nameArabic,
          teaching: response.teaching,
          duaArabic: response.duaArabic,
          duaTransliteration: response.duaTransliteration,
          duaTranslation: response.duaTranslation,
        });

        awardXP('dailyStreak').then(({ gained, xpState }) => {
          setCelebration({ gained, xpState, message: 'Daily orientation complete' });
        });

        fadeTo(0, 0, () => {
          setStep('result');
          fadeTo(1, 400);
        });
      } catch {
        router.back();
      }
    });
  }, [question, fadeAnim, fadeTo, router]);

  const rippleStyle = (anim: Animated.Value) => ({
    opacity: anim.interpolate({ inputRange: [0, 0.3, 1], outputRange: [0.6, 0.3, 0] }),
    transform: [{ scale: anim.interpolate({ inputRange: [0, 1], outputRange: [0.3, 2.2] }) }],
  });

  return (
    <SafeAreaView style={styles.safe}>
      {/* Loading */}
      {step === 'loading' && (
        <View style={styles.loadingScreen}>
          <View style={styles.rippleContainer}>
            <Animated.View style={[styles.rippleRing, rippleStyle(ripple1)]} />
            <Animated.View style={[styles.rippleRing, rippleStyle(ripple2)]} />
            <Animated.View style={[styles.rippleRing, rippleStyle(ripple3)]} />
            <View style={styles.rippleCore} />
          </View>
          <Text style={styles.loadingText}>Finding your Name...</Text>
        </View>
      )}

      {/* Question */}
      {step === 'question' && (
        <Animated.View style={[styles.screen, { opacity: fadeAnim }]}>
          <View style={styles.topRow}>
            <Text style={styles.eyebrow}>Daily Orientation</Text>
            <TouchableOpacity onPress={() => router.back()} activeOpacity={0.7}>
              <Text style={styles.closeBtn}>✕</Text>
            </TouchableOpacity>
          </View>

          <View style={styles.questionBlock}>
            <Text style={styles.question}>{question.question}</Text>
          </View>

          <View style={styles.optionsBlock}>
            {question.options.map(opt => (
              <TouchableOpacity
                key={opt}
                style={[styles.optionBtn, selectedOption === opt && styles.optionBtnSelected]}
                onPress={() => handleAnswer(opt)}
                activeOpacity={0.75}
              >
                <Text style={[styles.optionText, selectedOption === opt && styles.optionTextSelected]}>
                  {opt}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </Animated.View>
      )}

      {/* Result */}
      {step === 'result' && result && (
        <Animated.View style={[styles.flex, { opacity: fadeAnim }]}>
          <ScrollView
            contentContainerStyle={styles.resultContent}
            showsVerticalScrollIndicator={false}
          >
            {/* Name header */}
            <View style={styles.nameHeader}>
              <Text style={styles.nameEyebrow}>A Name for today</Text>
              <Text style={styles.nameArabic}>{result.nameArabic}</Text>
              <Text style={styles.nameEnglish}>{result.name}</Text>
            </View>

            {/* Teaching */}
            <View style={styles.teachingCard}>
              <Text style={styles.teachingText}>{result.teaching}</Text>
            </View>

            {/* Dua */}
            <View style={styles.duaCard}>
              <Text style={styles.duaEyebrow}>Dua</Text>
              <Text style={styles.duaArabic}>{result.duaArabic}</Text>
              <View style={styles.duaDivider} />
              <Text style={styles.duaTranslit}>{result.duaTransliteration}</Text>
              <Text style={styles.duaTranslation}>{result.duaTranslation}</Text>
            </View>

            <TouchableOpacity
              style={styles.doneBtn}
              onPress={() => router.back()}
              activeOpacity={0.85}
            >
              <Text style={styles.doneBtnText}>Done</Text>
            </TouchableOpacity>
          </ScrollView>
        </Animated.View>
      )}

      <XPCelebration
        visible={!!celebration}
        gained={celebration?.gained ?? 0}
        xpState={celebration?.xpState ?? { total: 0, level: 1, title: 'Seeker', titleArabic: 'طَالِب', xpForNextLevel: 50, xpIntoCurrentLevel: 0 }}
        message={celebration?.message ?? ''}
        onDismiss={() => setCelebration(null)}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.background },
  flex: { flex: 1 },
  screen: { flex: 1, paddingHorizontal: 28, paddingTop: 20, paddingBottom: 32 },

  topRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 40 },
  eyebrow: { fontSize: 11, fontWeight: '700', color: Colors.primary, letterSpacing: 1.5, textTransform: 'uppercase' },
  closeBtn: { fontSize: 18, color: Colors.textMuted, paddingLeft: 16, paddingVertical: 4 },

  questionBlock: { flex: 1, justifyContent: 'center', paddingBottom: 20 },
  question: { fontSize: 26, fontWeight: '800', color: Colors.textPrimary, lineHeight: 36, letterSpacing: -0.5 },

  optionsBlock: { gap: 12, paddingBottom: 8 },
  optionBtn: {
    paddingVertical: 16, paddingHorizontal: 20, borderRadius: 16,
    borderWidth: 1.5, borderColor: Colors.border, backgroundColor: Colors.white,
  },
  optionBtnSelected: { borderColor: Colors.primary, backgroundColor: Colors.primary + '12' },
  optionText: { fontSize: 16, color: Colors.textPrimary, fontWeight: '500' },
  optionTextSelected: { color: Colors.primary, fontWeight: '600' },

  // Loading
  loadingScreen: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 24 },
  rippleContainer: { width: 120, height: 120, alignItems: 'center', justifyContent: 'center' },
  rippleRing: {
    position: 'absolute', width: 120, height: 120, borderRadius: 60,
    borderWidth: 2, borderColor: Colors.primary, backgroundColor: 'transparent',
  },
  rippleCore: { width: 20, height: 20, borderRadius: 10, backgroundColor: Colors.primary },
  loadingText: { fontSize: 18, fontWeight: '700', color: Colors.primary },

  // Result
  resultContent: { paddingHorizontal: 24, paddingTop: 48, paddingBottom: 48, gap: 20 },

  nameHeader: { alignItems: 'center', gap: 8, paddingBottom: 8 },
  nameEyebrow: { fontSize: 10, fontWeight: '700', color: Colors.textMuted, letterSpacing: 1.5, textTransform: 'uppercase' },
  nameArabic: { fontSize: 56, color: Colors.primary, lineHeight: 72, textAlign: 'center' },
  nameEnglish: { fontSize: 20, fontWeight: '700', color: Colors.primaryDark, textAlign: 'center' },

  teachingCard: {
    backgroundColor: Colors.white, borderRadius: 20, padding: 22,
    shadowColor: Colors.cardShadow, shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 1, shadowRadius: 16, elevation: 4,
  },
  teachingText: { fontSize: 15, color: Colors.textPrimary, lineHeight: 26, letterSpacing: 0.1 },

  duaCard: {
    backgroundColor: Colors.duaCard, borderRadius: 20, padding: 22,
    borderWidth: 1, borderColor: Colors.duaCardBorder, gap: 10,
  },
  duaEyebrow: { fontSize: 10, fontWeight: '700', color: Colors.primary, letterSpacing: 1.5, textTransform: 'uppercase' },
  duaArabic: { fontSize: 22, color: Colors.primaryDark, lineHeight: 38, textAlign: 'right' },
  duaDivider: { height: 1, backgroundColor: Colors.duaCardBorder },
  duaTranslit: { fontSize: 13, color: Colors.textSecondary, fontStyle: 'italic', lineHeight: 22 },
  duaTranslation: { fontSize: 14, color: Colors.textPrimary, lineHeight: 22, fontWeight: '500' },

  doneBtn: { backgroundColor: Colors.primaryDark, borderRadius: 16, paddingVertical: 18, alignItems: 'center' },
  doneBtnText: { color: Colors.white, fontSize: 17, fontWeight: '700', letterSpacing: 0.3 },

  xpToast: {
    position: 'absolute', bottom: 100, alignSelf: 'center',
    backgroundColor: Colors.primaryDark, borderRadius: 20,
    paddingHorizontal: 18, paddingVertical: 8,
  },
  xpToastText: { color: Colors.white, fontSize: 14, fontWeight: '700' },
});

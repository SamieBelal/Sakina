import React, { useState, useRef, useCallback, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  SafeAreaView,
  Animated,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import ViewShot from 'react-native-view-shot';
import * as Sharing from 'expo-sharing';
import { Colors } from '@/constants/colors';
import { reflectWithClaude, getFollowUpQuestions, type ReflectResponse, type ReflectContext, type FollowUpQuestion } from '@/lib/claude';
import { ReflectDuaCard } from '@/components/ReflectDuaCard';
import { markActiveToday, logActivity } from '@/lib/localStreak';
import { updateStreak } from '@/lib/supabase';
import { useAuth } from '@/lib/auth';
import { saveJournalEntry, getJournalEntries } from '@/lib/journal';
import { getAnchors, incrementNameCount } from '@/lib/userProfile';
import { awardXP, type XPState } from '@/lib/xp';
import { XPCelebration } from '@/components/XPCelebration';

type ScreenState = 'input' | 'followup' | 'loading' | 'result' | 'offtopic';
type ResultStep = 'name' | 'reflection' | 'story' | 'dua';

const NEXT_STEP: Record<ResultStep, ResultStep | null> = {
  name: 'reflection', reflection: 'story', story: 'dua', dua: null,
};

const CONTINUE_LABEL: Record<ResultStep, string> = {
  name: 'See Reflection',
  reflection: 'Read the Story',
  story: 'See the Dua',
  dua: '',
};

export default function ReflectScreen() {
  const { user } = useAuth();
  const [state, setState] = useState<ScreenState>('input');
  const [text, setText] = useState('');
  const [result, setResult] = useState<ReflectResponse | null>(null);
  const [errorMsg, setErrorMsg] = useState('');
  const [resultStep, setResultStep] = useState<ResultStep>('name');

  // Follow-up state
  const [followUpQuestions, setFollowUpQuestions] = useState<FollowUpQuestion[]>([]);
  const [followUpAnswers, setFollowUpAnswers] = useState<(string | null)[]>([]);
  const [followUpIndex, setFollowUpIndex] = useState(0);
  const questionFade = useRef(new Animated.Value(0)).current;

  const [celebration, setCelebration] = useState<{ gained: number; xpState: XPState; message: string } | null>(null);

  const showCelebration = useCallback((gained: number, xpState: XPState, message: string) => {
    setCelebration({ gained, xpState, message });
  }, []);

  const fadeAnim = useRef(new Animated.Value(0)).current;
  const scrollRef = useRef<ScrollView>(null);
  const shareCardRef = useRef<ViewShot>(null);
  const [isSharing, setIsSharing] = useState(false);

  // Ripple loader
  const ripple1 = useRef(new Animated.Value(0)).current;
  const ripple2 = useRef(new Animated.Value(0)).current;
  const ripple3 = useRef(new Animated.Value(0)).current;
  const rippleActive = useRef(false);

  useEffect(() => {
    if (state === 'loading') {
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
  }, [state]);

  const fadeTo = useCallback((toValue: number, duration = 400, cb?: () => void) => {
    Animated.timing(fadeAnim, { toValue, duration, useNativeDriver: true })
      .start(() => cb?.());
  }, [fadeAnim]);

  const handleShare = useCallback(async () => {
    if (!shareCardRef.current || isSharing) return;
    setIsSharing(true);
    try {
      const uri = await (shareCardRef.current as any).capture();
      await Sharing.shareAsync(uri, { mimeType: 'image/png', dialogTitle: 'Share reflection' });
    } catch { /* user cancelled */ } finally {
      setIsSharing(false);
    }
  }, [isSharing]);

  const handleReflect = useCallback(async (combinedText: string) => {
    setState('loading');
    try {
      const [entries, anchors] = await Promise.all([getJournalEntries(), getAnchors()]);
      const recent = entries.slice(0, 5);
      const context: ReflectContext = {
        recentNames: recent.map(e => e.name),
        recentEntries: recent.slice(0, 3).map(e => ({ userText: e.userText, name: e.name })),
        anchorNames: anchors.map(a => a.name),
      };

      const response = await reflectWithClaude(combinedText, context);

      if (response.offTopic) {
        setState('offtopic');
        return;
      }

      setResult(response);
      setResultStep('name');
      setState('result');
      fadeAnim.setValue(0);
      fadeTo(1);

      if (user) updateStreak(user.id); else markActiveToday();
      logActivity();
      incrementNameCount(response.name);
      awardXP('reflection').then(({ gained, xpState }) => {
        showCelebration(gained, xpState, 'Reflection complete');
      });
      saveJournalEntry({
        date: new Date().toISOString(),
        userText: combinedText,
        name: response.name,
        nameArabic: response.nameArabic,
        reframe: response.reframe.split('\n\n')[0] ?? response.reframe,
        emotionTags: [response.name],
      });
    } catch {
      setState('input');
      setErrorMsg('Something went wrong — please try again');
    }
  }, [user, fadeAnim, fadeTo]);

  const handleSubmit = useCallback(async () => {
    if (!text.trim()) return;
    setErrorMsg('');

    const questions = await getFollowUpQuestions(text.trim());
    if (questions.length > 0) {
      setFollowUpQuestions(questions);
      setFollowUpAnswers(new Array(questions.length).fill(null));
      setFollowUpIndex(0);
      questionFade.setValue(0);
      setState('followup');
      Animated.timing(questionFade, { toValue: 1, duration: 400, useNativeDriver: true }).start();
    } else {
      handleReflect(text.trim());
    }
  }, [text, handleReflect]);

  const submitFollowUps = useCallback((answers: (string | null)[]) => {
    const parts = followUpQuestions.map((q, i) => {
      const ans = answers[i];
      if (!ans) return null;
      return `${q.question} ${ans}`;
    }).filter(Boolean);
    const combined = parts.length > 0
      ? `${text.trim()}\n\nMore context: ${parts.join('. ')}`
      : text.trim();
    handleReflect(combined);
  }, [text, followUpQuestions, handleReflect]);


  const handleFollowUpAnswer = useCallback((val: string) => {
    const updated = [...followUpAnswers];
    updated[followUpIndex] = val;
    setFollowUpAnswers(updated);

    const isLast = followUpIndex >= followUpQuestions.length - 1;
    if (isLast) {
      submitFollowUps(updated);
    } else {
      Animated.timing(questionFade, { toValue: 0, duration: 250, useNativeDriver: true }).start(() => {
        setFollowUpIndex(followUpIndex + 1);
        Animated.timing(questionFade, { toValue: 1, duration: 350, useNativeDriver: true }).start();
      });
    }
  }, [followUpAnswers, followUpIndex, followUpQuestions.length, questionFade, submitFollowUps]);


  const handleReset = useCallback(() => {
    setState('input');
    setText('');
    setResult(null);
    setErrorMsg('');
    setFollowUpQuestions([]);
    setFollowUpAnswers([]);
  }, []);

  const handleContinue = useCallback(() => {
    const next = NEXT_STEP[resultStep];
    if (!next) return;
    if (next === 'story') {
      awardXP('storyRead').then(({ gained, xpState }) => showCelebration(gained, xpState, 'Story read'));
    } else if (next === 'dua') {
      awardXP('duaRead').then(({ gained, xpState }) => showCelebration(gained, xpState, 'Dua recited'));
    }
    fadeTo(0, 300, () => {
      setResultStep(next);
      scrollRef.current?.scrollTo({ y: 0, animated: false });
      fadeTo(1, 400);
    });
  }, [resultStep, fadeTo, showCelebration]);

  // ─── Loading ───────────────────────────────────────────────────────────────
  if (state === 'loading') {
    const rippleStyle = (anim: Animated.Value) => ({
      opacity: anim.interpolate({ inputRange: [0, 0.3, 1], outputRange: [0.6, 0.3, 0] }),
      transform: [{ scale: anim.interpolate({ inputRange: [0, 1], outputRange: [0.3, 2.2] }) }],
    });
    return (
      <SafeAreaView style={styles.safe}>
        <View style={styles.loadingScreen}>
          <View style={styles.rippleContainer}>
            <Animated.View style={[styles.rippleRing, rippleStyle(ripple1)]} />
            <Animated.View style={[styles.rippleRing, rippleStyle(ripple2)]} />
            <Animated.View style={[styles.rippleRing, rippleStyle(ripple3)]} />
            <View style={styles.rippleCore} />
          </View>
          <Text style={styles.loadingText}>Reflecting...</Text>
          <Text style={styles.loadingSubtext}>Finding the right Name of Allah for your heart</Text>
        </View>
      </SafeAreaView>
    );
  }

  // ─── Follow-up ─────────────────────────────────────────────────────────────
  if (state === 'followup') {
    const q = followUpQuestions[followUpIndex];
    const progress = `${followUpIndex + 1} / ${followUpQuestions.length}`;
    return (
      <SafeAreaView style={styles.safe}>
        <View style={styles.followupScreen}>
          {/* Progress + skip */}
          <View style={styles.followupTopRow}>
            <Text style={styles.followupProgress}>{progress}</Text>
            <TouchableOpacity onPress={() => handleReflect(text.trim())}>
              <Text style={styles.skipLinkText}>Skip</Text>
            </TouchableOpacity>
          </View>

          {/* Centered question + options */}
          <Animated.View style={[styles.followupCenter, { opacity: questionFade }]}>
            <Text style={styles.followupQuestion}>{q.question}</Text>

            {q.type === 'yesno' && (
              <View style={styles.chipRowCentered}>
                {['Yes', 'No'].map(opt => (
                  <TouchableOpacity
                    key={opt}
                    style={styles.chipLarge}
                    onPress={() => handleFollowUpAnswer(opt)}
                    activeOpacity={0.7}
                  >
                    <Text style={styles.chipLargeText}>{opt}</Text>
                  </TouchableOpacity>
                ))}
              </View>
            )}

            {q.type === 'scale' && (
              <>
                <View style={styles.chipRowCentered}>
                  {['1','2','3','4','5'].map(n => (
                    <TouchableOpacity
                      key={n}
                      style={styles.chipSquare}
                      onPress={() => handleFollowUpAnswer(n)}
                      activeOpacity={0.7}
                    >
                      <Text style={styles.chipText}>{n}</Text>
                    </TouchableOpacity>
                  ))}
                </View>
                <View style={styles.chipRowCentered}>
                  {['6','7','8','9','10'].map(n => (
                    <TouchableOpacity
                      key={n}
                      style={styles.chipSquare}
                      onPress={() => handleFollowUpAnswer(n)}
                      activeOpacity={0.7}
                    >
                      <Text style={styles.chipText}>{n}</Text>
                    </TouchableOpacity>
                  ))}
                </View>
                <View style={styles.scaleLabels}>
                  <Text style={styles.scaleLabelText}>Not at all</Text>
                  <Text style={styles.scaleLabelText}>Very much</Text>
                </View>
              </>
            )}

            {q.type === 'choice' && (
              <View style={styles.chipRowCentered}>
                {q.options.map(opt => (
                  <TouchableOpacity
                    key={opt}
                    style={styles.chipLarge}
                    onPress={() => handleFollowUpAnswer(opt)}
                    activeOpacity={0.7}
                  >
                    <Text style={styles.chipLargeText}>{opt}</Text>
                  </TouchableOpacity>
                ))}
              </View>
            )}
          </Animated.View>
        </View>
      </SafeAreaView>
    );
  }

  // ─── Off-topic ─────────────────────────────────────────────────────────────
  if (state === 'offtopic') {
    return (
      <SafeAreaView style={styles.safe}>
        <View style={styles.offTopicScreen}>
          <Text style={styles.offTopicEmoji}>🤲</Text>
          <Text style={styles.offTopicTitle}>This space is for your heart</Text>
          <Text style={styles.offTopicBody}>
            Share something you're genuinely carrying — a worry, a feeling, something weighing on you. Sakina will meet you there.
          </Text>
          <TouchableOpacity style={styles.submitBtn} onPress={handleReset} activeOpacity={0.85}>
            <Text style={styles.submitBtnText}>Try again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  // ─── Result ────────────────────────────────────────────────────────────────
  if (state === 'result' && result) {
    const continueLabel = CONTINUE_LABEL[resultStep];
    const isNameStep = resultStep === 'name';

    return (
      <SafeAreaView style={[styles.safe, isNameStep && styles.safeGreen]}>
        <Animated.View style={[styles.flex, { opacity: fadeAnim }]}>
          <ScrollView
            ref={scrollRef}
            contentContainerStyle={[styles.stepContent, isNameStep && styles.stepContentGreen]}
            showsVerticalScrollIndicator={false}
            style={isNameStep && styles.scrollGreen}
          >
            {/* Step: Name */}
            {isNameStep && (
              <View style={styles.nameStepContainer}>
                <View style={styles.nameStep}>
                  <Text style={styles.nameStepEyebrow}>A Name for your heart</Text>
                  <Text style={styles.nameStepArabic}>{result.nameArabic}</Text>
                  <Text style={styles.nameStepName}>{result.name}</Text>

                  {result.relatedNames.length > 0 && (
                    <View style={styles.relatedNamesRow}>
                      <Text style={styles.relatedNamesLabel}>Also</Text>
                      {result.relatedNames.map((r, i) => (
                        <View key={i} style={styles.relatedNamePill}>
                          <Text style={styles.relatedNamePillText}>{r.name}</Text>
                        </View>
                      ))}
                    </View>
                  )}
                </View>
              </View>
            )}

            {/* Step: Reflection */}
            {resultStep === 'reflection' && (
              <View style={styles.textCard}>
                {result.reframe.split('\n\n').filter(Boolean).map((para, i) => (
                  <Text key={i} style={[styles.bodyText, i > 0 && styles.paraSpacer]}>
                    {para.trim()}
                  </Text>
                ))}
              </View>
            )}

            {/* Step: Story */}
            {resultStep === 'story' && (
              <View style={styles.textCard}>
                <Text style={styles.storyEyebrow}>A Prophetic Story</Text>
                {result.story.split('\n\n').filter(Boolean).map((para, i) => (
                  <Text key={i} style={[styles.storyText, i > 0 && styles.paraSpacer]}>
                    {para.trim()}
                  </Text>
                ))}
              </View>
            )}

            {/* Step: Dua */}
            {resultStep === 'dua' && (
              <ReflectDuaCard
                arabic={result.duaArabic}
                transliteration={result.duaTransliteration}
                translation={result.duaTranslation}
                source={result.duaSource}
              />
            )}

            {/* Continue / actions */}
            <View style={styles.stepActions}>
              {continueLabel ? (
                <TouchableOpacity
                  style={[styles.continueBtn, isNameStep && styles.continueBtnDark]}
                  onPress={handleContinue}
                  activeOpacity={0.85}
                >
                  <Text style={styles.continueBtnText}>{continueLabel}</Text>
                </TouchableOpacity>
              ) : (
                <TouchableOpacity style={styles.shareBtn} onPress={handleShare} activeOpacity={0.8}>
                  <Text style={styles.shareBtnText}>{isSharing ? 'Preparing...' : 'Share this reflection'}</Text>
                </TouchableOpacity>
              )}
              {!isNameStep && (
                <TouchableOpacity onPress={handleReset} style={styles.newBtn}>
                  <Text style={styles.newBtnText}>Start over</Text>
                </TouchableOpacity>
              )}
            </View>
          </ScrollView>
        </Animated.View>

        <XPCelebration
          visible={!!celebration}
          gained={celebration?.gained ?? 0}
          xpState={celebration?.xpState ?? { total: 0, level: 1, title: 'Seeker', titleArabic: 'طَالِب', xpForNextLevel: 50, xpIntoCurrentLevel: 0 }}
          message={celebration?.message ?? ''}
          onDismiss={() => setCelebration(null)}
        />

        {/* Off-screen share card */}
        <View style={styles.offScreen}>
          <ViewShot ref={shareCardRef} options={{ format: 'png', quality: 1 }}>
            <ShareCard
              name={result.name}
              nameArabic={result.nameArabic}
              reframe={result.reframe.split('\n\n')[0] ?? result.reframe}
            />
          </ViewShot>
        </View>
      </SafeAreaView>
    );
  }

  // ─── Input ─────────────────────────────────────────────────────────────────
  return (
    <SafeAreaView style={styles.safe}>
      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        <ScrollView
          contentContainerStyle={styles.inputScreen}
          keyboardDismissMode="interactive"
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
          bounces={false}
        >
          <View style={styles.inputHeader}>
            <Text style={styles.inputTitle}>Reflect</Text>
            <Text style={styles.inputSubtitle}>Share what is on your heart. This space is yours.</Text>
          </View>

          <View style={styles.inputWrapper}>
            <TextInput
              style={styles.input}
              multiline
              placeholder="What are you carrying today..."
              placeholderTextColor={Colors.textMuted}
              value={text}
              onChangeText={setText}
              textAlignVertical="top"
              scrollEnabled={false}
            />
          </View>

          {errorMsg ? (
            <View style={styles.errorBox}>
              <Text style={styles.errorText}>{errorMsg}</Text>
            </View>
          ) : null}

          <TouchableOpacity
            style={[styles.submitBtn, !text.trim() && styles.submitBtnDisabled]}
            onPress={handleSubmit}
            disabled={!text.trim()}
            activeOpacity={0.85}
          >
            <Text style={styles.submitBtnText}>Reflect</Text>
          </TouchableOpacity>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

function ShareCard({ name, nameArabic, reframe }: { name: string; nameArabic: string; reframe: string }) {
  const preview = reframe.length > 180 ? reframe.slice(0, 177) + '…' : reframe;
  return (
    <View style={styles.shareCard}>
      <View style={styles.shareCardTop}>
        <Text style={styles.shareCardLabel}>A Name for your heart</Text>
        <Text style={styles.shareCardArabic}>{nameArabic}</Text>
        <Text style={styles.shareCardName}>{name}</Text>
      </View>
      <View style={styles.shareCardDivider} />
      <Text style={styles.shareCardReframe}>{preview}</Text>
      <Text style={styles.shareCardBranding}>Sakina · سَكِينَة</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.background },
  safeGreen: { backgroundColor: Colors.primary },
  flex: { flex: 1 },

  // Loading
  loadingScreen: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 24 },
  rippleContainer: { width: 120, height: 120, alignItems: 'center', justifyContent: 'center' },
  rippleRing: {
    position: 'absolute', width: 120, height: 120, borderRadius: 60,
    borderWidth: 2, borderColor: Colors.primary, backgroundColor: 'transparent',
  },
  rippleCore: { width: 20, height: 20, borderRadius: 10, backgroundColor: Colors.primary },
  loadingText: { fontSize: 18, fontWeight: '700', color: Colors.primary },
  loadingSubtext: { fontSize: 13, color: Colors.textMuted, textAlign: 'center', paddingHorizontal: 40, lineHeight: 20 },

  // Off-topic
  offTopicScreen: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 36, gap: 16 },
  offTopicEmoji: { fontSize: 48 },
  offTopicTitle: { fontSize: 20, fontWeight: '700', color: Colors.textPrimary, textAlign: 'center' },
  offTopicBody: { fontSize: 15, color: Colors.textSecondary, textAlign: 'center', lineHeight: 24 },

  // Follow-up screen
  followupScreen: { flex: 1, paddingHorizontal: 32, paddingTop: 20, paddingBottom: 40 },
  followupTopRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 0 },
  followupProgress: { fontSize: 12, color: Colors.textMuted, fontWeight: '500' },
  followupCenter: { flex: 1, justifyContent: 'center', alignItems: 'center', gap: 32 },
  followupOriginalText: { fontSize: 14, color: Colors.textMuted, fontStyle: 'italic', lineHeight: 22 },
  followupDivider: { height: 1, backgroundColor: Colors.border },
  followupQuestionBlock: { gap: 10 },
  followupQuestion: { fontSize: 20, fontWeight: '700', color: Colors.textPrimary, lineHeight: 30, textAlign: 'center' },
  skipLink: { alignItems: 'center', paddingVertical: 8 },
  skipLinkText: { fontSize: 13, color: Colors.textMuted },
  chipRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  chipRowCentered: { flexDirection: 'row', flexWrap: 'wrap', gap: 12, justifyContent: 'center' },
  chipLarge: {
    paddingHorizontal: 28, paddingVertical: 14, borderRadius: 28,
    borderWidth: 1, borderColor: Colors.border, backgroundColor: Colors.white,
  },
  chipLargeText: { fontSize: 16, color: Colors.textPrimary, fontWeight: '500' },
  chipSquare: {
    width: 52, height: 52, borderRadius: 12, alignItems: 'center', justifyContent: 'center',
    borderWidth: 1, borderColor: Colors.border, backgroundColor: Colors.white,
  },
  scaleLabels: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 4 },
  scaleLabelText: { fontSize: 11, color: Colors.textMuted },
  chip: {
    paddingHorizontal: 18, paddingVertical: 10, borderRadius: 20,
    borderWidth: 1, borderColor: Colors.border, backgroundColor: Colors.white,
  },
  chipSmall: {
    width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center',
    borderWidth: 1, borderColor: Colors.border, backgroundColor: Colors.white,
  },
  chipSelected: { backgroundColor: Colors.primary, borderColor: Colors.primary },
  chipText: { fontSize: 14, color: Colors.textPrimary, fontWeight: '500' },
  chipTextSelected: { color: Colors.white },

  // Result step content
  stepContent: { paddingHorizontal: 24, paddingTop: 60, paddingBottom: 48 },
  stepContentGreen: { flexGrow: 1, backgroundColor: Colors.primary },
  scrollGreen: { backgroundColor: Colors.primary },

  // Name step
  nameStepContainer: {
    flex: 1, backgroundColor: Colors.primary,
    margin: -24, padding: 48,
    alignItems: 'center', justifyContent: 'center', minHeight: 500,
  },
  nameStep: { alignItems: 'center', gap: 16 },
  nameStepEyebrow: {
    fontSize: 11, fontWeight: '700', color: 'rgba(255,255,255,0.6)',
    letterSpacing: 2, textTransform: 'uppercase',
  },
  nameStepArabic: { fontSize: 64, color: Colors.white, lineHeight: 80, textAlign: 'center' },
  nameStepName: { fontSize: 22, fontWeight: '700', color: Colors.white, textAlign: 'center' },

  // Related names
  relatedNamesRow: { flexDirection: 'row', alignItems: 'center', gap: 8, flexWrap: 'wrap', justifyContent: 'center', marginTop: 8 },
  relatedNamesLabel: { fontSize: 12, color: 'rgba(255,255,255,0.5)', fontWeight: '500' },
  relatedNamePill: {
    paddingHorizontal: 12, paddingVertical: 5,
    borderRadius: 20, borderWidth: 1, borderColor: 'rgba(255,255,255,0.3)',
  },
  relatedNamePillText: { fontSize: 12, color: 'rgba(255,255,255,0.8)', fontWeight: '500' },

  // Text cards
  textCard: {
    backgroundColor: Colors.white, borderRadius: 24, padding: 24,
    shadowColor: Colors.cardShadow, shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 1, shadowRadius: 16, elevation: 4, marginBottom: 16,
  },
  bodyText: { fontSize: 15, color: Colors.textPrimary, lineHeight: 28, letterSpacing: 0.1 },
  storyEyebrow: {
    fontSize: 10, fontWeight: '700', color: Colors.primary,
    letterSpacing: 1.5, textTransform: 'uppercase', marginBottom: 16,
  },
  storyText: { fontSize: 15, color: Colors.textSecondary, lineHeight: 28, letterSpacing: 0.1 },
  paraSpacer: { marginTop: 20 },

  // Step actions
  stepActions: { gap: 12, marginTop: 8 },
  continueBtn: {
    backgroundColor: Colors.primary, borderRadius: 16,
    paddingVertical: 18, alignItems: 'center',
  },
  continueBtnDark: { backgroundColor: Colors.primaryDark },
  continueBtnText: { color: Colors.white, fontSize: 17, fontWeight: '700', letterSpacing: 0.3 },
  shareBtn: {
    borderRadius: 14, borderWidth: 1, borderColor: Colors.border,
    paddingVertical: 14, alignItems: 'center',
  },
  shareBtnText: { fontSize: 13, fontWeight: '500', color: Colors.textMuted },
  newBtn: { alignItems: 'center', paddingVertical: 10 },
  newBtnText: { fontSize: 13, color: Colors.textMuted },

  // Input screen
  inputScreen: { flexGrow: 1, padding: 24, gap: 20 },
  inputHeader: { paddingTop: 8, gap: 6 },
  inputTitle: { fontSize: 28, fontWeight: '800', color: Colors.textPrimary, letterSpacing: -0.5 },
  inputSubtitle: { fontSize: 14, color: Colors.textMuted, lineHeight: 20 },
  inputWrapper: {
    minHeight: 220, backgroundColor: Colors.white, borderRadius: 20, padding: 20,
    shadowColor: Colors.cardShadow, shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 1, shadowRadius: 16, elevation: 4,
  },
  input: { minHeight: 180, fontSize: 17, color: Colors.textPrimary, lineHeight: 28, fontStyle: 'italic' },
  errorBox: { backgroundColor: '#FFF0F0', borderRadius: 12, padding: 14, borderWidth: 1, borderColor: '#FFCCCC' },
  errorText: { fontSize: 14, color: '#C0392B', lineHeight: 20 },
  submitBtn: { backgroundColor: Colors.primary, borderRadius: 16, paddingVertical: 18, alignItems: 'center', marginBottom: 8 },
  submitBtnDisabled: { opacity: 0.45 },
  submitBtnText: { color: Colors.white, fontSize: 17, fontWeight: '700', letterSpacing: 0.3 },

  offScreen: { position: 'absolute', top: -9999, left: -9999 },
  xpToast: {
    position: 'absolute', bottom: 100, alignSelf: 'center',
    backgroundColor: Colors.primaryDark, borderRadius: 20,
    paddingHorizontal: 18, paddingVertical: 8,
  },
  xpToastText: { color: Colors.white, fontSize: 14, fontWeight: '700' },

  // Share card (ViewShot)
  shareCard: { width: 360, backgroundColor: Colors.primaryDark, padding: 36, gap: 20 },
  shareCardTop: { gap: 6, alignItems: 'center' },
  shareCardLabel: { fontSize: 11, color: 'rgba(255,255,255,0.5)', letterSpacing: 2, textTransform: 'uppercase', fontWeight: '600' },
  shareCardArabic: { fontSize: 52, color: Colors.white, textAlign: 'center', lineHeight: 68 },
  shareCardName: { fontSize: 20, fontWeight: '700', color: Colors.white, textAlign: 'center' },
  shareCardDivider: { height: 1, backgroundColor: 'rgba(255,255,255,0.15)' },
  shareCardReframe: { fontSize: 15, color: 'rgba(255,255,255,0.85)', lineHeight: 24, fontStyle: 'italic', textAlign: 'center' },
  shareCardBranding: { fontSize: 12, color: 'rgba(255,255,255,0.4)', textAlign: 'center', letterSpacing: 1, marginTop: 4 },
});

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
import { Colors } from '@/constants/colors';
import { QUIZ_QUESTIONS, NAME_ANCHORS, type AnchorResult } from '@/constants/quiz';
import { saveAnchors } from '@/lib/userProfile';

const { width: SCREEN_WIDTH } = Dimensions.get('window');
const TOTAL = QUIZ_QUESTIONS.length;

function computeAnchors(selections: { qIdx: number; oIdx: number }[]): AnchorResult[] {
  const scores: Record<string, number> = {};
  for (const { qIdx, oIdx } of selections) {
    const q = QUIZ_QUESTIONS[qIdx];
    const option = q.options[oIdx];
    for (const [key, pts] of Object.entries(option.scores)) {
      scores[key] = (scores[key] ?? 0) + pts;
    }
  }
  const sorted = Object.entries(scores)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3);

  return sorted.map(([key, score]) => {
    const meta = NAME_ANCHORS[key];
    if (!meta) return null;
    return { nameKey: key, score, ...meta } as AnchorResult;
  }).filter(Boolean) as AnchorResult[];
}

type Phase = 'intro' | 'quiz' | 'result';

export default function DiscoverScreen() {
  const router = useRouter();
  const [phase, setPhase] = useState<Phase>('intro');
  const [qIdx, setQIdx] = useState(0);
  const [selections, setSelections] = useState<{ qIdx: number; oIdx: number }[]>([]);
  const [selectedOption, setSelectedOption] = useState<number | null>(null);
  const [anchors, setAnchors] = useState<AnchorResult[]>([]);
  const fadeAnim = useRef(new Animated.Value(1)).current;

  const fadeTransition = (cb: () => void) => {
    Animated.timing(fadeAnim, { toValue: 0, duration: 180, useNativeDriver: true }).start(() => {
      cb();
      Animated.timing(fadeAnim, { toValue: 1, duration: 220, useNativeDriver: true }).start();
    });
  };

  const handleOptionSelect = (oIdx: number) => {
    setSelectedOption(oIdx);
  };

  const handleNext = () => {
    if (selectedOption === null) return;
    const newSelections = [...selections, { qIdx, oIdx: selectedOption }];
    setSelections(newSelections);

    if (qIdx < TOTAL - 1) {
      fadeTransition(() => {
        setQIdx(qIdx + 1);
        setSelectedOption(null);
      });
    } else {
      const results = computeAnchors(newSelections);
      setAnchors(results);
      saveAnchors(results);
      fadeTransition(() => setPhase('result'));
    }
  };

  const handleRestart = () => {
    fadeTransition(() => {
      setPhase('intro');
      setQIdx(0);
      setSelections([]);
      setSelectedOption(null);
      setAnchors([]);
    });
  };

  // ─── Intro ─────────────────────────────────────────────────────────────────
  if (phase === 'intro') {
    return (
      <SafeAreaView style={styles.safe}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Text style={styles.backText}>‹ Back</Text>
        </TouchableOpacity>
        <ScrollView contentContainerStyle={styles.introContent} showsVerticalScrollIndicator={false}>
          <Text style={styles.introArabic}>بِسْمِ اللهِ</Text>
          <Text style={styles.introTitle}>Your Names of Allah</Text>
          <Text style={styles.introSubtitle}>
            Every person has Names of Allah that speak most deeply to where they are in life.
          </Text>
          <Text style={styles.introBody}>
            Answer 6 questions honestly — there are no right answers. You'll receive 3 Names that
            are your anchors right now: the ones Allah has given you to hold onto in this season.
          </Text>

          <View style={styles.introMeta}>
            <MetaItem icon="🕐" text="About 2 minutes" />
            <MetaItem icon="🤍" text="6 questions" />
            <MetaItem icon="✦" text="3 anchor Names" />
          </View>

          <TouchableOpacity
            style={styles.startBtn}
            onPress={() => fadeTransition(() => setPhase('quiz'))}
            activeOpacity={0.85}
          >
            <Text style={styles.startBtnText}>Begin</Text>
          </TouchableOpacity>
        </ScrollView>
      </SafeAreaView>
    );
  }

  // ─── Quiz ──────────────────────────────────────────────────────────────────
  if (phase === 'quiz') {
    const question = QUIZ_QUESTIONS[qIdx];
    const progress = (qIdx + 1) / TOTAL;

    return (
      <SafeAreaView style={styles.safe}>
        <View style={styles.quizHeader}>
          <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
            <Text style={styles.backText}>‹</Text>
          </TouchableOpacity>
          <Text style={styles.quizCounter}>{qIdx + 1} of {TOTAL}</Text>
          <View style={{ width: 40 }} />
        </View>

        {/* Progress bar */}
        <View style={styles.progressTrack}>
          <View style={[styles.progressFill, { width: `${progress * 100}%` }]} />
        </View>

        <Animated.View style={[styles.flex, { opacity: fadeAnim }]}>
          <ScrollView contentContainerStyle={styles.quizContent} showsVerticalScrollIndicator={false}>
            <Text style={styles.questionText}>{question.prompt}</Text>

            <View style={styles.optionsCol}>
              {question.options.map((opt, i) => (
                <TouchableOpacity
                  key={i}
                  style={[styles.optionCard, selectedOption === i && styles.optionCardSelected]}
                  onPress={() => handleOptionSelect(i)}
                  activeOpacity={0.75}
                >
                  <View style={[styles.optionRadio, selectedOption === i && styles.optionRadioSelected]}>
                    {selectedOption === i && <View style={styles.optionRadioDot} />}
                  </View>
                  <Text style={[styles.optionText, selectedOption === i && styles.optionTextSelected]}>
                    {opt.text}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            <TouchableOpacity
              style={[styles.nextBtn, selectedOption === null && styles.nextBtnDisabled]}
              onPress={handleNext}
              disabled={selectedOption === null}
              activeOpacity={0.85}
            >
              <Text style={styles.nextBtnText}>
                {qIdx === TOTAL - 1 ? 'See my Names' : 'Next'}
              </Text>
            </TouchableOpacity>
          </ScrollView>
        </Animated.View>
      </SafeAreaView>
    );
  }

  // ─── Result ────────────────────────────────────────────────────────────────
  return (
    <SafeAreaView style={styles.safe}>
      <Animated.View style={[styles.flex, { opacity: fadeAnim }]}>
        <ScrollView contentContainerStyle={styles.resultContent} showsVerticalScrollIndicator={false}>
          <Text style={styles.resultEyebrow}>Your spiritual anchors</Text>
          <Text style={styles.resultTitle}>Names that speak to your heart</Text>
          <Text style={styles.resultSubtitle}>
            These Names of Allah resonate most with where you are right now. Return to them often.
          </Text>

          {anchors.map((anchor, i) => (
            <AnchorCard key={anchor.nameKey} anchor={anchor} rank={i + 1} />
          ))}

          <View style={styles.resultActions}>
            <TouchableOpacity style={styles.reflectBtn} onPress={() => router.push('/(tabs)/reflect')} activeOpacity={0.85}>
              <Text style={styles.reflectBtnText}>Reflect with these Names</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.retakeBtn} onPress={handleRestart} activeOpacity={0.7}>
              <Text style={styles.retakeBtnText}>Retake quiz</Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </Animated.View>
    </SafeAreaView>
  );
}

function AnchorCard({ anchor, rank }: { anchor: AnchorResult; rank: number }) {
  const [expanded, setExpanded] = useState(rank === 1);
  const rankLabels = ['Primary anchor', 'Second anchor', 'Third anchor'];

  return (
    <TouchableOpacity
      style={[styles.anchorCard, rank === 1 && styles.anchorCardPrimary]}
      onPress={() => setExpanded(v => !v)}
      activeOpacity={0.85}
    >
      <View style={styles.anchorTop}>
        <View style={styles.anchorLeft}>
          <Text style={styles.anchorRank}>{rankLabels[rank - 1]}</Text>
          <Text style={[styles.anchorArabic, rank === 1 && styles.anchorArabicPrimary]}>
            {anchor.arabic}
          </Text>
          <Text style={[styles.anchorName, rank === 1 && styles.anchorNamePrimary]}>
            {anchor.name}
          </Text>
        </View>
        <Text style={[styles.anchorChevron, rank === 1 && styles.anchorChevronPrimary]}>
          {expanded ? '▲' : '▽'}
        </Text>
      </View>

      <Text style={[styles.anchorStatement, rank === 1 && styles.anchorStatementPrimary]}>
        {anchor.anchor}
      </Text>

      {expanded && (
        <Text style={[styles.anchorDetail, rank === 1 && styles.anchorDetailPrimary]}>
          {anchor.detail}
        </Text>
      )}
    </TouchableOpacity>
  );
}

function MetaItem({ icon, text }: { icon: string; text: string }) {
  return (
    <View style={styles.metaItem}>
      <Text style={styles.metaIcon}>{icon}</Text>
      <Text style={styles.metaText}>{text}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.background },
  flex: { flex: 1 },

  backBtn: { paddingHorizontal: 24, paddingVertical: 12 },
  backText: { fontSize: 17, color: Colors.primary, fontWeight: '600' },

  // Intro
  introContent: { padding: 24, paddingTop: 12, gap: 20, paddingBottom: 48 },
  introArabic: { fontSize: 32, color: Colors.primaryDark, textAlign: 'center', lineHeight: 48 },
  introTitle: {
    fontSize: 28, fontWeight: '800', color: Colors.textPrimary,
    letterSpacing: -0.5, textAlign: 'center',
  },
  introSubtitle: {
    fontSize: 16, color: Colors.textSecondary, textAlign: 'center',
    lineHeight: 26, fontWeight: '500',
  },
  introBody: {
    fontSize: 15, color: Colors.textSecondary, textAlign: 'center',
    lineHeight: 26,
  },
  introMeta: {
    flexDirection: 'row', justifyContent: 'center', gap: 24,
    backgroundColor: Colors.white, borderRadius: 16, padding: 16,
    shadowColor: Colors.cardShadow, shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 1, shadowRadius: 8, elevation: 2,
  },
  metaItem: { alignItems: 'center', gap: 4 },
  metaIcon: { fontSize: 20 },
  metaText: { fontSize: 11, color: Colors.textMuted, fontWeight: '500' },
  startBtn: {
    backgroundColor: Colors.primary, borderRadius: 16,
    paddingVertical: 18, alignItems: 'center', marginTop: 8,
  },
  startBtnText: { color: Colors.white, fontSize: 17, fontWeight: '700' },

  // Quiz header
  quizHeader: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingHorizontal: 24, paddingTop: 8, paddingBottom: 4,
  },
  quizCounter: { fontSize: 13, color: Colors.textMuted, fontWeight: '500' },

  // Progress bar
  progressTrack: {
    height: 3, backgroundColor: Colors.border, marginHorizontal: 24, borderRadius: 2, marginBottom: 8,
  },
  progressFill: {
    height: 3, backgroundColor: Colors.primary, borderRadius: 2,
  },

  // Quiz content
  quizContent: { padding: 24, paddingTop: 20, gap: 24, paddingBottom: 48 },
  questionText: {
    fontSize: 22, fontWeight: '700', color: Colors.textPrimary,
    lineHeight: 32, letterSpacing: -0.3,
  },
  optionsCol: { gap: 12 },
  optionCard: {
    flexDirection: 'row', alignItems: 'flex-start', gap: 14,
    backgroundColor: Colors.white, borderRadius: 16, padding: 18,
    borderWidth: 1.5, borderColor: Colors.border,
    shadowColor: Colors.cardShadow, shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 1, shadowRadius: 6, elevation: 2,
  },
  optionCardSelected: {
    borderColor: Colors.primary, backgroundColor: Colors.primary + '08',
  },
  optionRadio: {
    width: 22, height: 22, borderRadius: 11, borderWidth: 2,
    borderColor: Colors.border, alignItems: 'center', justifyContent: 'center',
    marginTop: 1, flexShrink: 0,
  },
  optionRadioSelected: { borderColor: Colors.primary },
  optionRadioDot: {
    width: 10, height: 10, borderRadius: 5, backgroundColor: Colors.primary,
  },
  optionText: {
    flex: 1, fontSize: 15, color: Colors.textPrimary, lineHeight: 24,
  },
  optionTextSelected: { color: Colors.primaryDark, fontWeight: '500' },
  nextBtn: {
    backgroundColor: Colors.primary, borderRadius: 16,
    paddingVertical: 18, alignItems: 'center',
  },
  nextBtnDisabled: { opacity: 0.4 },
  nextBtnText: { color: Colors.white, fontSize: 16, fontWeight: '700' },

  // Result
  resultContent: { padding: 24, paddingTop: 20, gap: 16, paddingBottom: 48 },
  resultEyebrow: {
    fontSize: 11, fontWeight: '700', color: Colors.primary,
    letterSpacing: 1.5, textTransform: 'uppercase', textAlign: 'center',
  },
  resultTitle: {
    fontSize: 26, fontWeight: '800', color: Colors.textPrimary,
    letterSpacing: -0.5, textAlign: 'center', lineHeight: 34,
  },
  resultSubtitle: {
    fontSize: 14, color: Colors.textMuted, textAlign: 'center', lineHeight: 22,
    marginBottom: 8,
  },

  // Anchor card
  anchorCard: {
    backgroundColor: Colors.white, borderRadius: 20, padding: 20, gap: 10,
    borderWidth: 1, borderColor: Colors.border,
    shadowColor: Colors.cardShadow, shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 1, shadowRadius: 12, elevation: 4,
  },
  anchorCardPrimary: {
    backgroundColor: Colors.primaryDark, borderColor: Colors.primaryDark,
  },
  anchorTop: { flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'space-between' },
  anchorLeft: { gap: 2 },
  anchorRank: { fontSize: 10, fontWeight: '700', color: Colors.textMuted, letterSpacing: 1.2, textTransform: 'uppercase' },
  anchorArabic: { fontSize: 28, color: Colors.primaryDark, lineHeight: 40 },
  anchorArabicPrimary: { color: 'rgba(255,255,255,0.85)' },
  anchorName: { fontSize: 16, fontWeight: '700', color: Colors.textPrimary },
  anchorNamePrimary: { color: Colors.white },
  anchorChevron: { fontSize: 12, color: Colors.textMuted, marginTop: 4 },
  anchorChevronPrimary: { color: 'rgba(255,255,255,0.5)' },
  anchorStatement: { fontSize: 16, fontWeight: '600', color: Colors.textPrimary, lineHeight: 24 },
  anchorStatementPrimary: { color: Colors.white },
  anchorDetail: { fontSize: 14, color: Colors.textSecondary, lineHeight: 24, marginTop: 4 },
  anchorDetailPrimary: { color: 'rgba(255,255,255,0.75)' },

  // Result actions
  resultActions: { gap: 12, marginTop: 8 },
  reflectBtn: {
    backgroundColor: Colors.primary, borderRadius: 16,
    paddingVertical: 18, alignItems: 'center',
  },
  reflectBtnText: { color: Colors.white, fontSize: 16, fontWeight: '700' },
  retakeBtn: {
    borderRadius: 16, paddingVertical: 14, alignItems: 'center',
    borderWidth: 1, borderColor: Colors.border,
  },
  retakeBtnText: { fontSize: 14, fontWeight: '500', color: Colors.textMuted },
});

import React, { useEffect, useState, useRef, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  SafeAreaView,
  ScrollView,
  Animated,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Colors } from '@/constants/colors';
import { getTodaysName, type AllahName } from '@/constants/allahNames';
import { getStreak } from '@/lib/supabase';
import { getLocalStreak } from '@/lib/localStreak';
import { useAuth } from '@/lib/auth';
import { getJournalEntries, formatJournalDate, type JournalEntry } from '@/lib/journal';
import { getXP, type XPState } from '@/lib/xp';
import { getTodaysDailyQuestion, getTodaysDailyAnswer, type DailyQuestion } from '@/lib/dailyQuestion';
import { getDuaSuggestions, type DuaSuggestion } from '@/lib/duaSuggestions';

export default function HomeScreen() {
  const router = useRouter();
  const { user, isGuest } = useAuth();
  const [todaysName, setTodaysName] = useState<AllahName | null>(null);
  const [streak, setStreak] = useState(0);
  const [lastEntry, setLastEntry] = useState<JournalEntry | null>(null);
  const [xp, setXp] = useState<XPState | null>(null);
  const [dailyQuestion, setDailyQuestion] = useState<DailyQuestion | null>(null);
  const [dailyDone, setDailyDone] = useState(false);
  const [dailyName, setDailyName] = useState<string | null>(null);
  const [duaSuggestions, setDuaSuggestions] = useState<DuaSuggestion[]>([]);
  const fadeAnim = useRef(new Animated.Value(1)).current;

  const fadeNavigate = useCallback((path: string) => {
    Animated.timing(fadeAnim, { toValue: 0, duration: 220, useNativeDriver: true }).start(() => {
      router.push(path as any);
      // Restore opacity after navigation so screen looks right when returning
      setTimeout(() => Animated.timing(fadeAnim, { toValue: 1, duration: 300, useNativeDriver: true }).start(), 100);
    });
  }, [fadeAnim, router]);

  useEffect(() => {
    setTodaysName(getTodaysName());
    if (user) {
      getStreak(user.id).then(setStreak);
    } else {
      getLocalStreak().then(setStreak);
    }
    getJournalEntries().then(entries => {
      setLastEntry(entries[0] ?? null);
    });
    getXP().then(setXp);
    setDailyQuestion(getTodaysDailyQuestion());
    getTodaysDailyAnswer().then(ans => {
      if (ans) { setDailyDone(true); setDailyName(ans.name); }
    });
    getDuaSuggestions().then(setDuaSuggestions);
  }, [user]);

  if (!todaysName) return null;

  return (
    <SafeAreaView style={styles.safe}>
      <Animated.ScrollView style={[styles.scroll, { opacity: fadeAnim }]} contentContainerStyle={styles.container} showsVerticalScrollIndicator={false}>

        {/* Header */}
        <View style={styles.header}>
          <View style={styles.headerLeft}>
            <Text style={styles.appName}>Sakina</Text>
            {isGuest && (
              <TouchableOpacity onPress={() => router.push('/welcome')} activeOpacity={0.8}>
                <Text style={styles.signUpLink}>Sign up to save progress →</Text>
              </TouchableOpacity>
            )}
          </View>
          <TouchableOpacity style={styles.avatarBtn} onPress={() => router.push('/profile')} activeOpacity={0.7}>
            <View style={[styles.avatar, isGuest && styles.avatarGuest]}>
              <Text style={styles.avatarText}>{isGuest ? '?' : (user?.email?.[0]?.toUpperCase() ?? '?')}</Text>
            </View>
          </TouchableOpacity>
        </View>

        {/* Name of the Day */}
        <View style={styles.nameCard}>
          <Text style={styles.nameLabel}>Today's Name of Allah</Text>
          <Text style={styles.nameArabic}>{todaysName.arabic}</Text>
          <Text style={styles.nameTranslit}>{todaysName.transliteration}</Text>
          <Text style={styles.nameEnglish}>{todaysName.english}</Text>
          <View style={styles.nameDivider} />
          <Text style={styles.nameMeaning} numberOfLines={2}>{todaysName.meaning}</Text>
        </View>

        {/* Daily Question card */}
        {dailyQuestion && (
          <TouchableOpacity
            style={[styles.dailyCard, dailyDone && styles.dailyCardDone]}
            onPress={() => !dailyDone && router.push('/daily-modal')}
            activeOpacity={dailyDone ? 1 : 0.85}
          >
            <View style={styles.dailyLeft}>
              <Text style={styles.dailyEyebrow}>Daily Orientation</Text>
              {dailyDone ? (
                <Text style={styles.dailyDoneText}>
                  Today's name: <Text style={styles.dailyDoneName}>{dailyName}</Text>
                </Text>
              ) : (
                <Text style={styles.dailyQuestion} numberOfLines={2}>{dailyQuestion.question}</Text>
              )}
            </View>
            {!dailyDone && <Text style={styles.dailyArrow}>›</Text>}
            {dailyDone && <Text style={styles.dailyCheck}>✓</Text>}
          </TouchableOpacity>
        )}

        {/* Duas for You */}
        {duaSuggestions.length > 0 && (
          <View style={styles.duasForYouCard}>
            <View style={styles.duasForYouHeader}>
              <Text style={styles.duasForYouTitle}>Duas for You</Text>
              <TouchableOpacity onPress={() => fadeNavigate('/(tabs)/duas')} activeOpacity={0.7}>
                <Text style={styles.duasForYouSeeAll}>See all →</Text>
              </TouchableOpacity>
            </View>
            {duaSuggestions.map((s, i) => (
              <TouchableOpacity
                key={i}
                style={styles.duaSuggestionRow}
                onPress={() => fadeNavigate('/(tabs)/duas')}
                activeOpacity={0.8}
              >
                <View style={styles.duaSuggestionLeft}>
                  <Text style={styles.duaSuggestionReason} numberOfLines={1}>
                    {s.type === 'built' ? 'Saved dua' : s.reason.replace(/based on your reflection on /i, 'For ')}
                  </Text>
                  <Text style={styles.duaSuggestionTitle} numberOfLines={1}>
                    {s.type === 'built' ? (s.builtDua?.need ?? 'Saved dua') : (s.dua?.title ?? '')}
                  </Text>
                </View>
                <Text style={styles.duaSuggestionArabic} numberOfLines={1}>
                  {s.type === 'built'
                    ? (s.builtDua?.arabic?.split('\n')[0] ?? '')
                    : (s.dua?.arabic ?? '')}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        )}

        {/* Last reflection or quiz CTA */}
        {lastEntry ? (
          <TouchableOpacity
            style={styles.lastCard}
            onPress={() => fadeNavigate('/(tabs)/reflect')}
            activeOpacity={0.85}
          >
            <View style={styles.lastCardTop}>
              <Text style={styles.lastCardLabel}>Last Reflection</Text>
              <Text style={styles.lastCardDate}>{formatJournalDate(lastEntry.date)}</Text>
            </View>
            <View style={styles.lastCardBottom}>
              <Text style={styles.lastCardName}>{lastEntry.name}</Text>
              <Text style={styles.lastCardArabic}>{lastEntry.nameArabic}</Text>
            </View>
            <Text style={styles.lastCardPreview} numberOfLines={2}>{lastEntry.reframe}</Text>
          </TouchableOpacity>
        ) : (
          <TouchableOpacity
            style={styles.discoverCard}
            onPress={() => router.push('/discover')}
            activeOpacity={0.85}
          >
            <View style={styles.discoverLeft}>
              <Text style={styles.discoverEyebrow}>Quiz</Text>
              <Text style={styles.discoverTitle}>Find your Names of Allah</Text>
              <Text style={styles.discoverSub}>Discover the 3 Names that anchor your heart right now</Text>
            </View>
            <Text style={styles.discoverArrow}>›</Text>
          </TouchableOpacity>
        )}

        {/* Stats row */}
        <View style={styles.statsRow}>
          <View style={styles.statCard}>
            <Text style={styles.statNumber}>{streak}</Text>
            <Text style={styles.statLabel}>day streak</Text>
          </View>
          <View style={styles.statDivider} />
          <View style={styles.statCard}>
            <View style={styles.streakDots}>
              {Array.from({ length: 7 }).map((_, i) => (
                <View key={i} style={[styles.dot, i < Math.min(streak, 7) && styles.dotActive]} />
              ))}
            </View>
            <Text style={styles.statLabel}>this week</Text>
          </View>
          <View style={styles.statDivider} />
          <View style={styles.statCard}>
            <Text style={styles.statNumber}>{xp?.total ?? 0}</Text>
            <Text style={styles.statLabel}>{xp?.title ?? 'Seeker'}</Text>
          </View>
        </View>

        {/* CTA */}
        <TouchableOpacity
          style={styles.cta}
          activeOpacity={0.85}
          onPress={() => router.push('/(tabs)/reflect')}
        >
          <Text style={styles.ctaText}>Reflect</Text>
        </TouchableOpacity>

      </Animated.ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.background },
  scroll: { flex: 1 },
  container: { paddingHorizontal: 24, paddingTop: 16, paddingBottom: 24, gap: 10 },

  // Header
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  headerLeft: { gap: 2 },
  appName: { fontSize: 22, fontWeight: '800', color: Colors.textPrimary, letterSpacing: -0.5 },
  signUpLink: { fontSize: 12, color: Colors.primary, fontWeight: '500' },
  avatarBtn: {},
  avatar: { width: 36, height: 36, borderRadius: 18, backgroundColor: Colors.primary, alignItems: 'center', justifyContent: 'center' },
  avatarGuest: { backgroundColor: Colors.border },
  avatarText: { fontSize: 14, fontWeight: '700', color: Colors.white },

  // Name card
  nameCard: {
    backgroundColor: Colors.white, borderRadius: 24, padding: 20,
    alignItems: 'center',
    shadowColor: Colors.cardShadow, shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 1, shadowRadius: 16, elevation: 4,
  },
  nameLabel: { fontSize: 10, color: Colors.textMuted, letterSpacing: 1.5, textTransform: 'uppercase', fontWeight: '500', marginBottom: 8 },
  nameArabic: { fontSize: 42, color: Colors.primaryDark, lineHeight: 56 },
  nameTranslit: { fontSize: 15, color: Colors.primary, fontWeight: '600', letterSpacing: 0.4 },
  nameEnglish: { fontSize: 16, color: Colors.textPrimary, fontWeight: '700', marginTop: 2 },
  nameDivider: { width: 32, height: 1.5, backgroundColor: Colors.border, marginVertical: 10 },
  nameMeaning: { fontSize: 13, color: Colors.textSecondary, textAlign: 'center', lineHeight: 20 },

  // Daily question card
  dailyCard: {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: Colors.white, borderRadius: 18, padding: 16,
    borderLeftWidth: 3, borderLeftColor: Colors.primary,
    shadowColor: Colors.cardShadow, shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 1, shadowRadius: 8, elevation: 2,
    gap: 8,
  },
  dailyCardDone: { borderLeftColor: Colors.streakActive, opacity: 0.75 },
  dailyLeft: { flex: 1, gap: 4 },
  dailyEyebrow: { fontSize: 10, fontWeight: '700', color: Colors.primary, letterSpacing: 1.5, textTransform: 'uppercase' },
  dailyQuestion: { fontSize: 14, fontWeight: '600', color: Colors.textPrimary, lineHeight: 20 },
  dailyDoneText: { fontSize: 13, color: Colors.textSecondary },
  dailyDoneName: { fontWeight: '700', color: Colors.primaryDark },
  dailyArrow: { fontSize: 24, color: Colors.primary, fontWeight: '300' },
  dailyCheck: { fontSize: 16, color: Colors.streakActive, fontWeight: '700' },

  // Last reflection
  lastCard: {
    backgroundColor: Colors.white, borderRadius: 20, padding: 16, gap: 8,
    borderLeftWidth: 3, borderLeftColor: Colors.primary,
    shadowColor: Colors.cardShadow, shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 1, shadowRadius: 8, elevation: 2,
  },
  lastCardTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  lastCardLabel: { fontSize: 10, color: Colors.textMuted, letterSpacing: 1.5, textTransform: 'uppercase', fontWeight: '600' },
  lastCardDate: { fontSize: 11, color: Colors.textMuted },
  lastCardBottom: { flexDirection: 'row', alignItems: 'baseline', gap: 8 },
  lastCardName: { fontSize: 17, fontWeight: '700', color: Colors.primaryDark },
  lastCardArabic: { fontSize: 18, color: Colors.primary },
  lastCardPreview: { fontSize: 13, color: Colors.textSecondary, lineHeight: 20 },

  // Discover / quiz card
  discoverCard: {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: Colors.primary + '12', borderRadius: 20, padding: 18, gap: 12,
    borderWidth: 1, borderColor: Colors.primary + '25',
  },
  discoverLeft: { flex: 1, gap: 4 },
  discoverEyebrow: { fontSize: 10, fontWeight: '800', color: Colors.primary, letterSpacing: 1.5, textTransform: 'uppercase' },
  discoverTitle: { fontSize: 16, fontWeight: '700', color: Colors.primaryDark, lineHeight: 22 },
  discoverSub: { fontSize: 13, color: Colors.textSecondary, lineHeight: 19 },
  discoverArrow: { fontSize: 24, color: Colors.primary, fontWeight: '300' },

  // Stats
  statsRow: {
    flexDirection: 'row', backgroundColor: Colors.white, borderRadius: 16,
    paddingVertical: 14, paddingHorizontal: 20, alignItems: 'center',
    shadowColor: Colors.cardShadow, shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 1, shadowRadius: 8, elevation: 2,
  },
  statCard: { flex: 1, alignItems: 'center', gap: 4 },
  statDivider: { width: 1, height: 32, backgroundColor: Colors.border },
  statNumber: { fontSize: 22, fontWeight: '800', color: Colors.primary },
  statLabel: { fontSize: 10, color: Colors.textMuted, textTransform: 'uppercase', letterSpacing: 0.8 },
  streakDots: { flexDirection: 'row', gap: 4 },
  dot: { width: 8, height: 8, borderRadius: 4, backgroundColor: Colors.streakInactive },
  dotActive: { backgroundColor: Colors.streakActive },

  // Duas for You
  duasForYouCard: {
    backgroundColor: Colors.white, borderRadius: 20, padding: 16, gap: 10,
    borderLeftWidth: 3, borderLeftColor: Colors.primary,
    shadowColor: Colors.cardShadow, shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 1, shadowRadius: 8, elevation: 2,
  },
  duasForYouHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  duasForYouTitle: { fontSize: 12, fontWeight: '800', color: Colors.textMuted, letterSpacing: 1.2, textTransform: 'uppercase' },
  duasForYouSeeAll: { fontSize: 12, color: Colors.primary, fontWeight: '600' },
  duaSuggestionRow: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingVertical: 10, paddingHorizontal: 12,
    backgroundColor: Colors.background, borderRadius: 12, gap: 8,
  },
  duaSuggestionLeft: { flex: 1, gap: 2 },
  duaSuggestionReason: { fontSize: 10, color: Colors.primary, fontWeight: '600', textTransform: 'uppercase', letterSpacing: 0.8 },
  duaSuggestionTitle: { fontSize: 14, fontWeight: '600', color: Colors.textPrimary },
  duaSuggestionArabic: { fontSize: 14, color: Colors.primaryDark, maxWidth: 120, textAlign: 'right' },

  // CTA
  cta: { backgroundColor: Colors.primaryDark, borderRadius: 16, paddingVertical: 18, alignItems: 'center' },
  ctaText: { color: Colors.white, fontSize: 17, fontWeight: '700', letterSpacing: 0.3 },
});

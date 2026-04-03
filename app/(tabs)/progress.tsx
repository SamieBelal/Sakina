import React, { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  SafeAreaView,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { Colors } from '@/constants/colors';
import { getActivityLog } from '@/lib/localStreak';
import { getStreak } from '@/lib/supabase';
import { useAuth } from '@/lib/auth';
import { getSavedDuas } from '@/lib/supabase';
import { ALLAH_NAMES } from '@/constants/allahNames';
import { getJournalEntries, deleteJournalEntry, formatJournalDate, type JournalEntry } from '@/lib/journal';
import { getTopNames } from '@/lib/userProfile';
import { useFocusEffect } from 'expo-router';

function getDaysInMonth(year: number, month: number) {
  return new Date(year, month + 1, 0).getDate();
}

function getFirstDayOfMonth(year: number, month: number) {
  return new Date(year, month, 1).getDay();
}

type Tab = 'progress' | 'journal';

export default function ProgressScreen() {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState<Tab>('progress');
  const [streak, setStreak] = useState(0);
  const [savedCount, setSavedCount] = useState(0);
  const [activityLog, setActivityLog] = useState<string[]>([]);
  const [journalEntries, setJournalEntries] = useState<JournalEntry[]>([]);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [topNames, setTopNames] = useState<{ name: string; count: number }[]>([]);
  const today = new Date();

  const loadData = useCallback(() => {
    getStreak(user?.id ?? '').then(setStreak);
    getSavedDuas().then((ids) => setSavedCount(ids.length));
    getActivityLog().then(setActivityLog);
    getJournalEntries().then(setJournalEntries);
    getTopNames(6).then(setTopNames);
  }, [user]);

  useEffect(() => { loadData(); }, [loadData]);
  useFocusEffect(useCallback(() => { loadData(); }, [loadData]));

  const handleDelete = (id: string) => {
    Alert.alert('Delete reflection', 'Remove this entry from your journal?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: async () => {
          await deleteJournalEntry(id);
          setJournalEntries(prev => prev.filter(e => e.id !== id));
        },
      },
    ]);
  };

  const year = today.getFullYear();
  const month = today.getMonth();
  const daysInMonth = getDaysInMonth(year, month);
  const firstDay = getFirstDayOfMonth(year, month);
  const monthName = today.toLocaleString('default', { month: 'long' });
  const activitySet = new Set(activityLog);

  const last7 = Array.from({ length: 7 }).map((_, i) => {
    const d = new Date(Date.now() - (6 - i) * 86400000);
    return activitySet.has(d.toISOString().split('T')[0]);
  });

  const namesLearned = Math.min(
    Math.floor(activityLog.length * 1.2),
    ALLAH_NAMES.length
  );

  return (
    <SafeAreaView style={styles.safe}>
      {/* Tab toggle */}
      <View style={styles.tabRow}>
        <TouchableOpacity
          style={[styles.tabBtn, activeTab === 'progress' && styles.tabBtnActive]}
          onPress={() => setActiveTab('progress')}
          activeOpacity={0.7}
        >
          <Text style={[styles.tabBtnText, activeTab === 'progress' && styles.tabBtnTextActive]}>
            Progress
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tabBtn, activeTab === 'journal' && styles.tabBtnActive]}
          onPress={() => setActiveTab('journal')}
          activeOpacity={0.7}
        >
          <Text style={[styles.tabBtnText, activeTab === 'journal' && styles.tabBtnTextActive]}>
            Journal
          </Text>
          {journalEntries.length > 0 && (
            <View style={styles.countBadge}>
              <Text style={styles.countBadgeText}>{journalEntries.length}</Text>
            </View>
          )}
        </TouchableOpacity>
      </View>

      {activeTab === 'progress' ? (
        <ScrollView
          style={styles.scroll}
          contentContainerStyle={styles.content}
          showsVerticalScrollIndicator={false}
        >
          {/* Stats row */}
          <View style={styles.statsRow}>
            <StatCard label="Day Streak" value={streak.toString()} unit="days" />
            <StatCard label="Names Learned" value={namesLearned.toString()} unit={`/ ${ALLAH_NAMES.length}`} />
            <StatCard label="Saved Duas" value={savedCount.toString()} unit="saved" />
          </View>

          {/* Calendar */}
          <View style={styles.calendarCard}>
            <Text style={styles.sectionTitle}>{monthName} {year}</Text>
            <View style={styles.calendarDow}>
              {['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d, i) => (
                <Text key={i} style={styles.dowLabel}>{d}</Text>
              ))}
            </View>
            <View style={styles.calendarGrid}>
              {Array.from({ length: firstDay }).map((_, i) => (
                <View key={`empty-${i}`} style={styles.calDay} />
              ))}
              {Array.from({ length: daysInMonth }).map((_, i) => {
                const date = new Date(year, month, i + 1).toISOString().split('T')[0];
                const isActive = activitySet.has(date);
                const isToday = i + 1 === today.getDate();
                return (
                  <View key={i} style={[styles.calDay, isActive && styles.calDayActive, isToday && styles.calDayToday]}>
                    <Text style={[styles.calDayText, isActive && styles.calDayTextActive, isToday && styles.calDayTextToday]}>
                      {i + 1}
                    </Text>
                  </View>
                );
              })}
            </View>
          </View>

          {/* Last 7 days */}
          <View style={styles.journeyCard}>
            <Text style={styles.sectionTitle}>Last 7 Days</Text>
            <Text style={styles.sectionSubtitle}>Engagement</Text>
            <View style={styles.journeyRow}>
              {last7.map((active, i) => {
                const d = new Date(Date.now() - (6 - i) * 86400000);
                const dayLabel = d.toLocaleString('default', { weekday: 'short' }).slice(0, 1);
                return (
                  <View key={i} style={styles.journeyCol}>
                    <View style={styles.journeyBarBg}>
                      <View style={[styles.journeyBar, active ? styles.journeyBarActive : styles.journeyBarInactive]} />
                    </View>
                    <Text style={styles.journeyDayLabel}>{dayLabel}</Text>
                  </View>
                );
              })}
            </View>
          </View>

          {/* Names frequency */}
          {topNames.length > 0 && (
            <View style={styles.namesFreqCard}>
              <Text style={styles.sectionTitle}>Names of Allah sent to you</Text>
              <Text style={styles.sectionSubtitle}>From your reflections</Text>
              {topNames.map(({ name, count }) => {
                const pct = topNames[0].count > 0 ? count / topNames[0].count : 0;
                return (
                  <View key={name} style={styles.freqRow}>
                    <Text style={styles.freqLabel} numberOfLines={1}>{name}</Text>
                    <View style={styles.freqBarTrack}>
                      <View style={[styles.freqBarFill, { width: `${pct * 100}%` }]} />
                    </View>
                    <Text style={styles.freqCount}>{count}×</Text>
                  </View>
                );
              })}
            </View>
          )}

          {/* Names learned */}
          <View style={styles.namesCard}>
            <Text style={styles.sectionTitle}>Names of Allah</Text>
            <Text style={styles.sectionSubtitle}>{namesLearned} of 99 explored</Text>
            <View style={styles.namesProgress}>
              <View style={[styles.namesProgressFill, { width: `${(namesLearned / 99) * 100}%` }]} />
            </View>
            <View style={styles.namesList}>
              {ALLAH_NAMES.slice(0, namesLearned).map((n) => (
                <View key={n.id} style={styles.nameBadge}>
                  <Text style={styles.nameBadgeText}>{n.transliteration}</Text>
                </View>
              ))}
            </View>
          </View>

          <View style={{ height: 32 }} />
        </ScrollView>
      ) : (
        <ScrollView
          style={styles.scroll}
          contentContainerStyle={styles.content}
          showsVerticalScrollIndicator={false}
        >
          {journalEntries.length === 0 ? (
            <View style={styles.emptyState}>
              <Text style={styles.emptyArabic}>◎</Text>
              <Text style={styles.emptyTitle}>No reflections yet</Text>
              <Text style={styles.emptySubtitle}>
                Your reflections from the Reflect tab will appear here, along with the Name of Allah and what you were carrying.
              </Text>
            </View>
          ) : (
            journalEntries.map(entry => (
              <JournalCard
                key={entry.id}
                entry={entry}
                expanded={expandedId === entry.id}
                onToggle={() => setExpandedId(prev => prev === entry.id ? null : entry.id)}
                onDelete={() => handleDelete(entry.id)}
              />
            ))
          )}
          <View style={{ height: 32 }} />
        </ScrollView>
      )}
    </SafeAreaView>
  );
}

function JournalCard({
  entry,
  expanded,
  onToggle,
  onDelete,
}: {
  entry: JournalEntry;
  expanded: boolean;
  onToggle: () => void;
  onDelete: () => void;
}) {
  return (
    <View style={styles.journalCard}>
      <TouchableOpacity onPress={onToggle} activeOpacity={0.75} style={styles.journalCardHeader}>
        <View style={styles.journalMeta}>
          <View style={styles.journalNameRow}>
            <Text style={styles.journalNameArabic}>{entry.nameArabic}</Text>
            <Text style={styles.journalName}>{entry.name}</Text>
          </View>
          <Text style={styles.journalDate}>{formatJournalDate(entry.date)}</Text>
        </View>
        <Text style={styles.journalChevron}>{expanded ? '▲' : '▽'}</Text>
      </TouchableOpacity>

      {/* User text preview — always visible */}
      <Text style={styles.journalUserText} numberOfLines={expanded ? undefined : 2}>
        "{entry.userText}"
      </Text>

      {expanded && (
        <View style={styles.journalExpanded}>
          <View style={styles.journalDivider} />
          <Text style={styles.journalReframeLabel}>Reflection</Text>
          <Text style={styles.journalReframe}>{entry.reframe}</Text>
          <TouchableOpacity onPress={onDelete} style={styles.deleteBtn}>
            <Text style={styles.deleteBtnText}>Delete entry</Text>
          </TouchableOpacity>
        </View>
      )}
    </View>
  );
}

function StatCard({ label, value, unit }: { label: string; value: string; unit: string }) {
  return (
    <View style={styles.statCard}>
      <Text style={styles.statValue}>{value}</Text>
      <Text style={styles.statUnit}>{unit}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.background },
  scroll: { flex: 1 },
  content: { padding: 20, paddingTop: 12, gap: 16 },

  // Tab toggle
  tabRow: {
    flexDirection: 'row',
    margin: 20,
    marginBottom: 0,
    backgroundColor: Colors.white,
    borderRadius: 14,
    padding: 4,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  tabBtn: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 10,
    borderRadius: 10,
    gap: 6,
  },
  tabBtnActive: { backgroundColor: Colors.primary },
  tabBtnText: { fontSize: 14, fontWeight: '600', color: Colors.textMuted },
  tabBtnTextActive: { color: Colors.white },
  countBadge: {
    backgroundColor: Colors.primary,
    borderRadius: 10,
    paddingHorizontal: 6,
    paddingVertical: 1,
    minWidth: 18,
    alignItems: 'center',
  },
  countBadgeText: { fontSize: 11, color: Colors.white, fontWeight: '700' },

  // Stats
  statsRow: { flexDirection: 'row', gap: 10 },
  statCard: {
    flex: 1,
    backgroundColor: Colors.white,
    borderRadius: 16,
    padding: 14,
    alignItems: 'center',
    shadowColor: Colors.cardShadow,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 1,
    shadowRadius: 8,
    elevation: 2,
    gap: 1,
  },
  statValue: { fontSize: 26, fontWeight: '800', color: Colors.primary },
  statUnit: { fontSize: 11, color: Colors.textMuted },
  statLabel: { fontSize: 11, color: Colors.textSecondary, fontWeight: '500', marginTop: 2, textAlign: 'center' },

  // Calendar
  calendarCard: {
    backgroundColor: Colors.white,
    borderRadius: 20,
    padding: 20,
    shadowColor: Colors.cardShadow,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 1,
    shadowRadius: 12,
    elevation: 4,
  },
  sectionTitle: { fontSize: 16, fontWeight: '700', color: Colors.textPrimary, marginBottom: 2 },
  sectionSubtitle: { fontSize: 12, color: Colors.textMuted, marginBottom: 12 },
  calendarDow: { flexDirection: 'row', marginBottom: 6 },
  dowLabel: { flex: 1, textAlign: 'center', fontSize: 11, color: Colors.textMuted, fontWeight: '600' },
  calendarGrid: { flexDirection: 'row', flexWrap: 'wrap' },
  calDay: { width: `${100 / 7}%`, aspectRatio: 1, justifyContent: 'center', alignItems: 'center', borderRadius: 8 },
  calDayActive: { backgroundColor: Colors.primary + '22' },
  calDayToday: { backgroundColor: Colors.primary },
  calDayText: { fontSize: 12, color: Colors.textSecondary },
  calDayTextActive: { color: Colors.primary, fontWeight: '700' },
  calDayTextToday: { color: Colors.white, fontWeight: '800' },

  // Journey
  journeyCard: {
    backgroundColor: Colors.white,
    borderRadius: 20,
    padding: 20,
    shadowColor: Colors.cardShadow,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 1,
    shadowRadius: 12,
    elevation: 4,
  },
  journeyRow: { flexDirection: 'row', gap: 8, alignItems: 'flex-end', height: 80 },
  journeyCol: { flex: 1, alignItems: 'center', gap: 4, height: 80, justifyContent: 'flex-end' },
  journeyBarBg: { flex: 1, width: '100%', justifyContent: 'flex-end' },
  journeyBar: { width: '100%', borderRadius: 4 },
  journeyBarActive: { height: 52, backgroundColor: Colors.primary },
  journeyBarInactive: { height: 14, backgroundColor: Colors.border },
  journeyDayLabel: { fontSize: 10, color: Colors.textMuted, fontWeight: '600' },

  // Names frequency chart
  namesFreqCard: {
    backgroundColor: Colors.white,
    borderRadius: 20,
    padding: 20,
    gap: 10,
    shadowColor: Colors.cardShadow,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 1,
    shadowRadius: 12,
    elevation: 4,
  },
  freqRow: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  freqLabel: { width: 100, fontSize: 13, color: Colors.textPrimary, fontWeight: '500' },
  freqBarTrack: { flex: 1, height: 8, borderRadius: 4, backgroundColor: Colors.border },
  freqBarFill: { height: 8, borderRadius: 4, backgroundColor: Colors.primary },
  freqCount: { width: 24, fontSize: 12, color: Colors.textMuted, textAlign: 'right' },

  // Names
  namesCard: {
    backgroundColor: Colors.white,
    borderRadius: 20,
    padding: 20,
    shadowColor: Colors.cardShadow,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 1,
    shadowRadius: 12,
    elevation: 4,
  },
  namesProgress: { height: 6, backgroundColor: Colors.border, borderRadius: 3, overflow: 'hidden', marginBottom: 14 },
  namesProgressFill: { height: '100%', backgroundColor: Colors.primary, borderRadius: 3 },
  namesList: { flexDirection: 'row', flexWrap: 'wrap', gap: 6 },
  nameBadge: {
    backgroundColor: Colors.background,
    borderRadius: 20,
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  nameBadgeText: { fontSize: 11, color: Colors.primaryDark, fontWeight: '500' },

  // Journal
  emptyState: {
    alignItems: 'center',
    paddingTop: 60,
    paddingHorizontal: 32,
    gap: 12,
  },
  emptyArabic: { fontSize: 36, color: Colors.border },
  emptyTitle: { fontSize: 18, fontWeight: '700', color: Colors.textPrimary },
  emptySubtitle: { fontSize: 14, color: Colors.textMuted, textAlign: 'center', lineHeight: 22 },

  journalCard: {
    backgroundColor: Colors.white,
    borderRadius: 20,
    padding: 18,
    shadowColor: Colors.cardShadow,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 1,
    shadowRadius: 12,
    elevation: 4,
  },
  journalCardHeader: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    marginBottom: 10,
  },
  journalMeta: { flex: 1, gap: 4 },
  journalNameRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  journalNameArabic: { fontSize: 18, color: Colors.primaryDark },
  journalName: { fontSize: 15, fontWeight: '700', color: Colors.textPrimary },
  journalDate: { fontSize: 12, color: Colors.textMuted },
  journalChevron: { fontSize: 11, color: Colors.textMuted, marginTop: 4 },
  journalUserText: {
    fontSize: 14,
    color: Colors.textSecondary,
    lineHeight: 22,
    fontStyle: 'italic',
  },
  journalExpanded: { gap: 10, marginTop: 4 },
  journalDivider: { height: 1, backgroundColor: Colors.border, marginVertical: 6 },
  journalReframeLabel: {
    fontSize: 11,
    color: Colors.textMuted,
    letterSpacing: 1.2,
    textTransform: 'uppercase',
    fontWeight: '600',
  },
  journalReframe: {
    fontSize: 14,
    color: Colors.textPrimary,
    lineHeight: 23,
  },
  deleteBtn: { alignSelf: 'flex-start', marginTop: 4 },
  deleteBtnText: { fontSize: 12, color: '#C0392B' },
});

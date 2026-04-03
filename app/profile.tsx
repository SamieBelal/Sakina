import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  Alert,
  Switch,
  Modal,
  Platform,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Colors } from '@/constants/colors';
import { useAuth } from '@/lib/auth';
import { getStreak } from '@/lib/supabase';
import { getActivityLog } from '@/lib/localStreak';
import {
  getNotificationPrefs,
  scheduleCheckIn,
  cancelCheckIn,
  requestNotificationPermission,
} from '@/lib/notifications';
import { getAnchors } from '@/lib/userProfile';
import type { AnchorResult } from '@/constants/quiz';

export default function ProfileScreen() {
  const router = useRouter();
  const { user, isGuest, signOut } = useAuth();
  const [streak, setStreak] = useState(0);
  const [totalDays, setTotalDays] = useState(0);
  const [notifEnabled, setNotifEnabled] = useState(false);
  const [notifHour, setNotifHour] = useState(8);
  const [notifMinute, setNotifMinute] = useState(0);
  const [showTimePicker, setShowTimePicker] = useState(false);
  const [pickerHour, setPickerHour] = useState(8);
  const [pickerMinute, setPickerMinute] = useState(0);
  const [anchors, setAnchors] = useState<AnchorResult[]>([]);

  useEffect(() => {
    getStreak(user?.id ?? '').then(setStreak);
    getActivityLog().then((log) => setTotalDays(log.length));
    getNotificationPrefs().then(prefs => {
      setNotifEnabled(prefs.enabled);
      setNotifHour(prefs.hour);
      setNotifMinute(prefs.minute);
    });
    getAnchors().then(setAnchors);
  }, [user]);

  const handleNotifToggle = async (value: boolean) => {
    if (value) {
      const granted = await requestNotificationPermission();
      if (!granted) {
        Alert.alert('Permission needed', 'Please enable notifications in your device settings to use this feature.');
        return;
      }
      await scheduleCheckIn(notifHour, notifMinute);
      setNotifEnabled(true);
    } else {
      await cancelCheckIn();
      setNotifEnabled(false);
    }
  };

  const formatTime = (h: number, m: number) => {
    const period = h >= 12 ? 'PM' : 'AM';
    const displayHour = h % 12 === 0 ? 12 : h % 12;
    const displayMinute = String(m).padStart(2, '0');
    return `${displayHour}:${displayMinute} ${period}`;
  };

  const openTimePicker = () => {
    setPickerHour(notifHour);
    setPickerMinute(notifMinute);
    setShowTimePicker(true);
  };

  const saveTime = async () => {
    setNotifHour(pickerHour);
    setNotifMinute(pickerMinute);
    setShowTimePicker(false);
    if (notifEnabled) {
      await scheduleCheckIn(pickerHour, pickerMinute);
    }
  };

  const handleSignOut = () => {
    Alert.alert('Sign out', 'Are you sure?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Sign out',
        style: 'destructive',
        onPress: async () => {
          await signOut();
          router.replace('/welcome');
        },
      },
    ]);
  };

  const initial = user?.email?.[0]?.toUpperCase() ?? '?';
  const email = user?.email ?? '';

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        {/* Back */}
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Text style={styles.backText}>‹ Back</Text>
        </TouchableOpacity>

        {/* Avatar + name */}
        <View style={styles.avatarSection}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>{isGuest ? '👤' : initial}</Text>
          </View>
          <Text style={styles.displayName}>{isGuest ? 'Guest' : email}</Text>
          {isGuest && (
            <Text style={styles.guestNote}>Your progress is saved on this device only.</Text>
          )}
        </View>

        {/* Stats */}
        <View style={styles.statsRow}>
          <StatCard value={streak} label="Day streak" icon="🔥" />
          <StatCard value={totalDays} label="Total days" icon="📅" />
        </View>

        {/* Anchor Names */}
        {anchors.length > 0 && (
          <View style={styles.sectionBlock}>
            <Text style={styles.sectionTitle}>Your anchor Names</Text>
            <Text style={styles.sectionSubtitle}>From your last quiz</Text>
            <View style={styles.anchorsList}>
              {anchors.map((a, i) => (
                <View key={a.nameKey} style={styles.anchorRow}>
                  <View style={[styles.anchorRankBadge, i === 0 && styles.anchorRankBadgePrimary]}>
                    <Text style={[styles.anchorRankText, i === 0 && styles.anchorRankTextPrimary]}>
                      {i + 1}
                    </Text>
                  </View>
                  <View style={styles.anchorInfo}>
                    <Text style={styles.anchorArabic}>{a.arabic}</Text>
                    <Text style={styles.anchorName}>{a.name}</Text>
                  </View>
                  <Text style={styles.anchorStatement} numberOfLines={2}>{a.anchor}</Text>
                </View>
              ))}
            </View>
            <TouchableOpacity onPress={() => router.push('/discover')} style={styles.retakeBtn}>
              <Text style={styles.retakeBtnText}>Retake quiz</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Notifications */}
        <View style={styles.section}>
          <View style={styles.notifRow}>
            <Text style={styles.notifIcon}>🔔</Text>
            <View style={styles.actionText}>
              <Text style={styles.actionLabel}>Daily check-in</Text>
              <Text style={styles.actionSubtitle}>
                {notifEnabled ? `Reminder at ${formatTime(notifHour, notifMinute)}` : 'Get a gentle nudge to reflect'}
              </Text>
            </View>
            <Switch
              value={notifEnabled}
              onValueChange={handleNotifToggle}
              trackColor={{ false: Colors.border, true: Colors.primary }}
              thumbColor={Colors.white}
            />
          </View>
          {notifEnabled && (
            <>
              <View style={styles.divider} />
              <TouchableOpacity style={styles.actionRow} onPress={openTimePicker} activeOpacity={0.7}>
                <Text style={styles.actionIcon}>⏰</Text>
                <View style={styles.actionText}>
                  <Text style={styles.actionLabel}>Reminder time</Text>
                  <Text style={styles.actionSubtitle}>{formatTime(notifHour, notifMinute)}</Text>
                </View>
                <Text style={styles.actionChevron}>›</Text>
              </TouchableOpacity>
            </>
          )}
        </View>

        {/* Time picker modal */}
        <Modal visible={showTimePicker} transparent animationType="slide">
          <View style={styles.modalOverlay}>
            <View style={styles.modalCard}>
              <Text style={styles.modalTitle}>Set reminder time</Text>
              <View style={styles.timeRow}>
                <View style={styles.timeCol}>
                  <Text style={styles.timeLabel}>Hour</Text>
                  <TouchableOpacity onPress={() => setPickerHour(h => (h + 1) % 24)} style={styles.timeBtn}>
                    <Text style={styles.timeBtnText}>▲</Text>
                  </TouchableOpacity>
                  <Text style={styles.timeValue}>{pickerHour % 12 === 0 ? 12 : pickerHour % 12}</Text>
                  <TouchableOpacity onPress={() => setPickerHour(h => (h - 1 + 24) % 24)} style={styles.timeBtn}>
                    <Text style={styles.timeBtnText}>▼</Text>
                  </TouchableOpacity>
                </View>
                <Text style={styles.timeColon}>:</Text>
                <View style={styles.timeCol}>
                  <Text style={styles.timeLabel}>Min</Text>
                  <TouchableOpacity onPress={() => setPickerMinute(m => (m + 5) % 60)} style={styles.timeBtn}>
                    <Text style={styles.timeBtnText}>▲</Text>
                  </TouchableOpacity>
                  <Text style={styles.timeValue}>{String(pickerMinute).padStart(2, '0')}</Text>
                  <TouchableOpacity onPress={() => setPickerMinute(m => (m - 5 + 60) % 60)} style={styles.timeBtn}>
                    <Text style={styles.timeBtnText}>▼</Text>
                  </TouchableOpacity>
                </View>
                <View style={styles.timeCol}>
                  <Text style={styles.timeLabel}> </Text>
                  <TouchableOpacity onPress={() => setPickerHour(h => h < 12 ? h + 12 : h - 12)} style={styles.ampmBtn}>
                    <Text style={styles.ampmText}>{pickerHour < 12 ? 'AM' : 'PM'}</Text>
                  </TouchableOpacity>
                </View>
              </View>
              <View style={styles.modalActions}>
                <TouchableOpacity onPress={() => setShowTimePicker(false)} style={styles.modalCancel}>
                  <Text style={styles.modalCancelText}>Cancel</Text>
                </TouchableOpacity>
                <TouchableOpacity onPress={saveTime} style={styles.modalSave}>
                  <Text style={styles.modalSaveText}>Save</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        </Modal>

        {/* Actions */}
        <View style={styles.section}>
          {isGuest ? (
            <>
              <ActionRow
                icon="✨"
                label="Create account"
                subtitle="Sync your streak across devices"
                onPress={() => router.push('/welcome')}
                highlight
              />
              <Divider />
              <ActionRow
                icon="🔑"
                label="Sign in"
                subtitle="Already have an account?"
                onPress={() => router.push('/welcome')}
              />
            </>
          ) : (
            <ActionRow
              icon="🚪"
              label="Sign out"
              onPress={handleSignOut}
              destructive
            />
          )}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function StatCard({ value, label, icon }: { value: number; label: string; icon: string }) {
  return (
    <View style={styles.statCard}>
      <Text style={styles.statIcon}>{icon}</Text>
      <Text style={styles.statValue}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

function ActionRow({
  icon, label, subtitle, onPress, highlight, destructive,
}: {
  icon: string;
  label: string;
  subtitle?: string;
  onPress: () => void;
  highlight?: boolean;
  destructive?: boolean;
}) {
  return (
    <TouchableOpacity style={styles.actionRow} onPress={onPress} activeOpacity={0.7}>
      <Text style={styles.actionIcon}>{icon}</Text>
      <View style={styles.actionText}>
        <Text style={[styles.actionLabel, highlight && styles.actionLabelHighlight, destructive && styles.actionLabelDestructive]}>
          {label}
        </Text>
        {subtitle ? <Text style={styles.actionSubtitle}>{subtitle}</Text> : null}
      </View>
      <Text style={styles.actionChevron}>›</Text>
    </TouchableOpacity>
  );
}

function Divider() {
  return <View style={styles.divider} />;
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.background },
  content: { padding: 24, gap: 24, paddingBottom: 48 },

  backBtn: { marginBottom: 4 },
  backText: { fontSize: 16, color: Colors.primary, fontWeight: '600' },

  avatarSection: { alignItems: 'center', gap: 10 },
  avatar: {
    width: 88,
    height: 88,
    borderRadius: 44,
    backgroundColor: Colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: { fontSize: 36, color: Colors.white, fontWeight: '700' },
  displayName: { fontSize: 18, fontWeight: '700', color: Colors.textPrimary },
  guestNote: { fontSize: 13, color: Colors.textMuted, textAlign: 'center' },

  statsRow: { flexDirection: 'row', gap: 12 },
  statCard: {
    flex: 1,
    backgroundColor: Colors.white,
    borderRadius: 20,
    padding: 20,
    alignItems: 'center',
    gap: 4,
    shadowColor: Colors.cardShadow,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 1,
    shadowRadius: 8,
    elevation: 2,
  },
  statIcon: { fontSize: 28 },
  statValue: { fontSize: 30, fontWeight: '800', color: Colors.primary },
  statLabel: { fontSize: 12, color: Colors.textMuted, fontWeight: '500' },

  section: {
    backgroundColor: Colors.white,
    borderRadius: 20,
    overflow: 'hidden',
    shadowColor: Colors.cardShadow,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 1,
    shadowRadius: 8,
    elevation: 2,
  },
  actionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 16,
    paddingHorizontal: 20,
    gap: 14,
  },
  actionIcon: { fontSize: 20, width: 28, textAlign: 'center' },
  actionText: { flex: 1 },
  actionLabel: { fontSize: 15, fontWeight: '600', color: Colors.textPrimary },
  actionLabelHighlight: { color: Colors.primary },
  actionLabelDestructive: { color: '#C0392B' },
  actionSubtitle: { fontSize: 12, color: Colors.textMuted, marginTop: 1 },
  actionChevron: { fontSize: 20, color: Colors.textMuted },
  divider: { height: 1, backgroundColor: Colors.border, marginHorizontal: 20 },

  sectionBlock: {
    backgroundColor: Colors.white,
    borderRadius: 20,
    padding: 20,
    gap: 12,
    shadowColor: Colors.cardShadow,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 1,
    shadowRadius: 8,
    elevation: 2,
  },
  sectionTitle: { fontSize: 15, fontWeight: '700', color: Colors.textPrimary },
  sectionSubtitle: { fontSize: 12, color: Colors.textMuted, marginTop: -8 },

  anchorsList: { gap: 12 },
  anchorRow: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  anchorRankBadge: {
    width: 28, height: 28, borderRadius: 14,
    backgroundColor: Colors.border,
    alignItems: 'center', justifyContent: 'center', flexShrink: 0,
  },
  anchorRankBadgePrimary: { backgroundColor: Colors.primary },
  anchorRankText: { fontSize: 13, fontWeight: '700', color: Colors.textMuted },
  anchorRankTextPrimary: { color: Colors.white },
  anchorInfo: { width: 80 },
  anchorArabic: { fontSize: 16, color: Colors.primaryDark, lineHeight: 22 },
  anchorName: { fontSize: 11, color: Colors.textMuted, fontWeight: '500' },
  anchorStatement: { flex: 1, fontSize: 13, color: Colors.textSecondary, lineHeight: 19 },
  retakeBtn: {
    borderRadius: 12, borderWidth: 1, borderColor: Colors.border,
    paddingVertical: 10, alignItems: 'center', marginTop: 4,
  },
  retakeBtnText: { fontSize: 13, color: Colors.textMuted, fontWeight: '500' },

  notifRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 16,
    paddingHorizontal: 20,
    gap: 14,
  },
  notifIcon: { fontSize: 20, width: 28, textAlign: 'center' },

  // Modal
  modalOverlay: {
    flex: 1,
    backgroundColor: Colors.overlay,
    justifyContent: 'flex-end',
  },
  modalCard: {
    backgroundColor: Colors.white,
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    padding: 28,
    gap: 24,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: Colors.textPrimary,
    textAlign: 'center',
  },
  timeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
  },
  timeCol: { alignItems: 'center', gap: 8 },
  timeLabel: { fontSize: 12, color: Colors.textMuted, fontWeight: '500' },
  timeBtn: { padding: 8 },
  timeBtnText: { fontSize: 18, color: Colors.primary, fontWeight: '700' },
  timeValue: { fontSize: 40, fontWeight: '800', color: Colors.textPrimary, minWidth: 56, textAlign: 'center' },
  timeColon: { fontSize: 36, fontWeight: '800', color: Colors.textPrimary, marginTop: 24 },
  ampmBtn: {
    backgroundColor: Colors.primary,
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 10,
    marginTop: 8,
  },
  ampmText: { fontSize: 16, fontWeight: '700', color: Colors.white },
  modalActions: { flexDirection: 'row', gap: 12 },
  modalCancel: {
    flex: 1,
    borderRadius: 14,
    borderWidth: 1.5,
    borderColor: Colors.border,
    paddingVertical: 16,
    alignItems: 'center',
  },
  modalCancelText: { fontSize: 15, fontWeight: '600', color: Colors.textSecondary },
  modalSave: {
    flex: 1,
    borderRadius: 14,
    backgroundColor: Colors.primary,
    paddingVertical: 16,
    alignItems: 'center',
  },
  modalSaveText: { fontSize: 15, fontWeight: '700', color: Colors.white },
});

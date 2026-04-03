import React, { useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  Animated,
} from 'react-native';
import { Colors } from '@/constants/colors';
import type { XPState } from '@/lib/xp';

interface Props {
  visible: boolean;
  gained: number;
  xpState: XPState;   // the NEW state after award
  message: string;    // e.g. "Dua recited", "Reflection complete"
  onDismiss: () => void;
}

export function XPCelebration({ visible, gained, xpState, message, onDismiss }: Props) {
  const barAnim = useRef(new Animated.Value(0)).current;
  const scaleAnim = useRef(new Animated.Value(0.85)).current;
  const opacityAnim = useRef(new Animated.Value(0)).current;
  const gainedAnim = useRef(new Animated.Value(0)).current;

  // xpForNextLevel = 0 means max level — treat bar as full
  const isMaxLevel = xpState.xpForNextLevel === 0;
  const prevXpIntoLevel = Math.max(0, xpState.xpIntoCurrentLevel - gained);
  const fromFraction = isMaxLevel ? 1 : prevXpIntoLevel / xpState.xpForNextLevel;
  const toFraction = isMaxLevel ? 1 : xpState.xpIntoCurrentLevel / xpState.xpForNextLevel;

  useEffect(() => {
    if (!visible) {
      barAnim.setValue(0);
      scaleAnim.setValue(0.85);
      opacityAnim.setValue(0);
      gainedAnim.setValue(0);
      return;
    }

    barAnim.setValue(fromFraction);
    gainedAnim.setValue(0);

    Animated.parallel([
      Animated.spring(scaleAnim, { toValue: 1, tension: 120, friction: 8, useNativeDriver: true }),
      Animated.timing(opacityAnim, { toValue: 1, duration: 250, useNativeDriver: true }),
    ]).start(() => {
      Animated.parallel([
        Animated.timing(barAnim, { toValue: toFraction, duration: 900, useNativeDriver: false }),
        Animated.timing(gainedAnim, { toValue: 1, duration: 600, useNativeDriver: true }),
      ]).start();
    });
  }, [visible]);

  const barWidth = barAnim.interpolate({
    inputRange: [0, 1],
    outputRange: ['0%', '100%'],
    extrapolate: 'clamp',
  });

  return (
    <Modal transparent visible={visible} animationType="none" onRequestClose={onDismiss}>
      <TouchableOpacity style={styles.backdrop} activeOpacity={1} onPress={onDismiss}>
        <Animated.View
          style={[styles.card, { opacity: opacityAnim, transform: [{ scale: scaleAnim }] }]}
        >
          {/* Tick + message */}
          <View style={styles.iconRow}>
            <View style={styles.iconCircle}>
              <Text style={styles.iconText}>✓</Text>
            </View>
          </View>

          <Text style={styles.messageText}>{message}</Text>

          {/* XP gained badge */}
          <Animated.View style={[styles.gainedBadge, { opacity: gainedAnim }]}>
            <Text style={styles.gainedText}>+{gained} XP</Text>
          </Animated.View>

          {/* Title + level */}
          <View style={styles.titleRow}>
            <View>
              <Text style={styles.levelLabel}>Your title</Text>
              <Text style={styles.titleText}>{xpState.title}</Text>
              <Text style={styles.titleArabic}>{xpState.titleArabic}</Text>
            </View>
            <View style={styles.totalXpBox}>
              <Text style={styles.totalXpNum}>{xpState.total}</Text>
              <Text style={styles.totalXpLabel}>total XP</Text>
            </View>
          </View>

          {/* XP bar */}
          <View style={styles.barSection}>
            <View style={styles.barTrack}>
              <Animated.View style={[styles.barFill, { width: barWidth }]} />
            </View>
            {!isMaxLevel ? (
              <View style={styles.barLabels}>
                <Text style={styles.barLabelLeft}>{xpState.xpIntoCurrentLevel} XP</Text>
                <Text style={styles.barLabelRight}>{xpState.xpForNextLevel} XP to next level</Text>
              </View>
            ) : (
              <Text style={styles.barLabelMax}>Maximum level reached</Text>
            )}
          </View>

          <TouchableOpacity style={styles.continueBtn} onPress={onDismiss} activeOpacity={0.85}>
            <Text style={styles.continueBtnText}>Continue</Text>
          </TouchableOpacity>
        </Animated.View>
      </TouchableOpacity>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    flex: 1, backgroundColor: 'rgba(0,0,0,0.5)',
    alignItems: 'center', justifyContent: 'center',
    paddingHorizontal: 28,
  },
  card: {
    backgroundColor: Colors.white, borderRadius: 28,
    padding: 28, width: '100%', gap: 16,
    shadowColor: '#000', shadowOffset: { width: 0, height: 12 },
    shadowOpacity: 0.18, shadowRadius: 24, elevation: 12,
  },

  iconRow: { alignItems: 'center' },
  iconCircle: {
    width: 56, height: 56, borderRadius: 28,
    backgroundColor: Colors.primary,
    alignItems: 'center', justifyContent: 'center',
  },
  iconText: { fontSize: 24, color: Colors.white, fontWeight: '700' },

  messageText: {
    fontSize: 20, fontWeight: '800', color: Colors.primaryDark,
    textAlign: 'center', lineHeight: 28,
  },

  gainedBadge: {
    alignSelf: 'center',
    backgroundColor: Colors.primary + '18',
    borderRadius: 20, paddingHorizontal: 20, paddingVertical: 8,
  },
  gainedText: { fontSize: 22, fontWeight: '800', color: Colors.primary },

  titleRow: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start',
    backgroundColor: Colors.background, borderRadius: 16, padding: 14,
  },
  levelLabel: { fontSize: 10, color: Colors.textMuted, fontWeight: '600', letterSpacing: 1.2, textTransform: 'uppercase', marginBottom: 2 },
  titleText: { fontSize: 18, fontWeight: '800', color: Colors.primaryDark },
  titleArabic: { fontSize: 16, color: Colors.primary, marginTop: 2 },
  totalXpBox: { alignItems: 'flex-end' },
  totalXpNum: { fontSize: 26, fontWeight: '800', color: Colors.primary },
  totalXpLabel: { fontSize: 10, color: Colors.textMuted, textTransform: 'uppercase', letterSpacing: 0.8 },

  barSection: { gap: 8 },
  barTrack: {
    height: 10, backgroundColor: Colors.border,
    borderRadius: 5, overflow: 'hidden',
  },
  barFill: {
    height: '100%', backgroundColor: Colors.primary,
    borderRadius: 5,
  },
  barLabels: { flexDirection: 'row', justifyContent: 'space-between' },
  barLabelLeft: { fontSize: 11, color: Colors.textMuted },
  barLabelRight: { fontSize: 11, color: Colors.textMuted },
  barLabelMax: { fontSize: 11, color: Colors.primary, textAlign: 'center', fontWeight: '600' },

  continueBtn: {
    backgroundColor: Colors.primaryDark, borderRadius: 14,
    paddingVertical: 16, alignItems: 'center',
  },
  continueBtnText: { color: Colors.white, fontSize: 16, fontWeight: '700' },
});

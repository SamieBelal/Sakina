import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Animated,
} from 'react-native';
import { Colors } from '@/constants/colors';
import type { Dua } from '@/constants/duas';

interface DuaCardProps {
  dua: Dua;
  saved?: boolean;
  onToggleSave?: (id: string) => void;
  initiallyExpanded?: boolean;
}

export function DuaCard({ dua, saved = false, onToggleSave, initiallyExpanded = false }: DuaCardProps) {
  const [expanded, setExpanded] = useState(initiallyExpanded);

  return (
    <View style={styles.card}>
      <TouchableOpacity
        activeOpacity={0.7}
        onPress={() => setExpanded((v) => !v)}
        style={styles.header}
      >
        <Text style={styles.title}>{dua.title}</Text>
        <View style={styles.headerRight}>
          {onToggleSave ? (
            <TouchableOpacity
              onPress={() => onToggleSave(dua.id)}
              hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
              style={styles.heartBtn}
            >
              <Text style={[styles.heart, saved && styles.heartActive]}>
                {saved ? '♥' : '♡'}
              </Text>
            </TouchableOpacity>
          ) : null}
          <Text style={styles.chevron}>{expanded ? '▲' : '▽'}</Text>
        </View>
      </TouchableOpacity>

      {expanded ? (
        <View style={styles.body}>
          <Text style={styles.arabic}>{dua.arabic}</Text>
          <View style={styles.divider} />
          <Text style={styles.transliteration}>{dua.transliteration}</Text>
          <View style={styles.divider} />
          <Text style={styles.translation}>{dua.translation}</Text>
          <Text style={styles.source}>{dua.source}</Text>
          {dua.whenToRecite ? (
            <View style={styles.whenBox}>
              <Text style={styles.whenText}>🕌 {dua.whenToRecite}</Text>
            </View>
          ) : null}
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.duaCard,
    borderRadius: 16,
    marginBottom: 12,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: Colors.duaCardBorder,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 16,
  },
  title: {
    fontSize: 15,
    fontWeight: '600',
    color: Colors.textPrimary,
    flex: 1,
  },
  headerRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  heartBtn: {},
  heart: {
    fontSize: 18,
    color: Colors.heartInactive,
  },
  heartActive: {
    color: Colors.heartActive,
  },
  chevron: {
    fontSize: 11,
    color: Colors.textMuted,
  },
  body: {
    paddingHorizontal: 16,
    paddingBottom: 16,
    gap: 0,
  },
  arabic: {
    fontSize: 22,
    color: Colors.primaryDark,
    textAlign: 'right',
    lineHeight: 36,
    marginBottom: 12,
  },
  divider: {
    height: 1,
    backgroundColor: Colors.duaCardBorder,
    marginVertical: 10,
  },
  transliteration: {
    fontSize: 13,
    color: Colors.textSecondary,
    fontStyle: 'italic',
    lineHeight: 20,
    marginBottom: 2,
  },
  translation: {
    fontSize: 14,
    color: Colors.textPrimary,
    lineHeight: 22,
    marginBottom: 8,
  },
  source: {
    fontSize: 11,
    color: Colors.textMuted,
    marginTop: 4,
  },
  whenBox: {
    marginTop: 10,
    backgroundColor: Colors.background,
    borderRadius: 10,
    padding: 10,
  },
  whenText: {
    fontSize: 12,
    color: Colors.textSecondary,
    lineHeight: 18,
  },
});

import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors } from '@/constants/colors';

interface ReflectDuaCardProps {
  arabic: string;
  transliteration: string;
  translation: string;
  source: string;
}

export function ReflectDuaCard({
  arabic,
  transliteration,
  translation,
  source,
}: ReflectDuaCardProps) {
  return (
    <View style={styles.card}>
      <Text style={styles.arabic}>{arabic}</Text>
      <View style={styles.divider} />
      <Text style={styles.transliteration}>{transliteration}</Text>
      <View style={styles.divider} />
      <Text style={styles.translation}>{translation}</Text>
      <Text style={styles.source}>{source}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.duaCard,
    borderRadius: 20,
    padding: 20,
    borderWidth: 1,
    borderColor: Colors.duaCardBorder,
    gap: 0,
  },
  arabic: {
    fontSize: 28,
    color: Colors.primaryDark,
    textAlign: 'right',
    lineHeight: 44,
    marginBottom: 4,
  },
  divider: {
    height: 1,
    backgroundColor: Colors.duaCardBorder,
    marginVertical: 12,
  },
  transliteration: {
    fontSize: 14,
    color: Colors.textSecondary,
    fontStyle: 'italic',
    lineHeight: 22,
    marginBottom: 2,
  },
  translation: {
    fontSize: 15,
    color: Colors.textPrimary,
    lineHeight: 24,
    marginBottom: 10,
  },
  source: {
    fontSize: 12,
    color: Colors.textMuted,
  },
});

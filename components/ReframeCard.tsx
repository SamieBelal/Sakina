import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors } from '@/constants/colors';
import { NamePill } from './NamePill';

interface ReframeCardProps {
  name: string;
  nameArabic: string;
  reframe: string;
  story: string;
}

export function ReframeCard({ name, nameArabic, reframe, story }: ReframeCardProps) {
  return (
    <View style={styles.card}>
      <NamePill name={name} arabic={nameArabic} size="large" />
      <View style={styles.reframeBody}>
        {reframe.split('\n\n').filter(Boolean).map((para, i) => (
          <Text key={i} style={[styles.reframePara, i > 0 && styles.reframeParaSpaced]}>
            {para.trim()}
          </Text>
        ))}
      </View>
      <View style={styles.storyBlock}>
        <View style={styles.storyBorder} />
        <Text style={styles.storyText}>{story.trim()}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.white,
    borderRadius: 20,
    padding: 20,
    shadowColor: Colors.cardShadow,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 1,
    shadowRadius: 12,
    elevation: 4,
    gap: 16,
  },
  reframeBody: {
    gap: 0,
  },
  reframePara: {
    fontSize: 15,
    color: Colors.textPrimary,
    lineHeight: 24,
  },
  reframeParaSpaced: {
    marginTop: 12,
  },
  storyBlock: {
    flexDirection: 'row',
    gap: 14,
    backgroundColor: Colors.background,
    borderRadius: 12,
    padding: 14,
  },
  storyBorder: {
    width: 3,
    borderRadius: 2,
    backgroundColor: Colors.storyBorder,
  },
  storyText: {
    flex: 1,
    fontSize: 14,
    color: Colors.textSecondary,
    lineHeight: 22,
    fontStyle: 'italic',
  },
});

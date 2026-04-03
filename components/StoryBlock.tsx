import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors } from '@/constants/colors';

interface StoryBlockProps {
  text: string;
}

export function StoryBlock({ text }: StoryBlockProps) {
  return (
    <View style={styles.container}>
      <View style={styles.border} />
      <Text style={styles.text}>{text}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    gap: 12,
    backgroundColor: Colors.background,
    borderRadius: 12,
    padding: 14,
  },
  border: {
    width: 3,
    borderRadius: 2,
    backgroundColor: Colors.storyBorder,
  },
  text: {
    flex: 1,
    fontSize: 14,
    color: Colors.textSecondary,
    lineHeight: 22,
    fontStyle: 'italic',
  },
});

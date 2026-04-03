import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors } from '@/constants/colors';

interface NamePillProps {
  name: string;
  arabic?: string;
  size?: 'small' | 'medium' | 'large';
}

export function NamePill({ name, arabic, size = 'medium' }: NamePillProps) {
  return (
    <View style={[styles.pill, styles[size]]}>
      {arabic ? (
        <Text style={[styles.arabic, styles[`arabic_${size}`]]}>{arabic}</Text>
      ) : null}
      <Text style={[styles.name, styles[`name_${size}`]]}>{name}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  pill: {
    backgroundColor: Colors.primary,
    borderRadius: 100,
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    gap: 6,
  },
  small: { paddingHorizontal: 10, paddingVertical: 4 },
  medium: { paddingHorizontal: 14, paddingVertical: 6 },
  large: { paddingHorizontal: 18, paddingVertical: 8 },
  arabic: {
    color: Colors.white,
  },
  name: {
    color: Colors.white,
    fontWeight: '600',
    letterSpacing: 0.2,
  },
  arabic_small: { fontSize: 13 },
  arabic_medium: { fontSize: 16 },
  arabic_large: { fontSize: 20 },
  name_small: { fontSize: 11 },
  name_medium: { fontSize: 13 },
  name_large: { fontSize: 15 },
});

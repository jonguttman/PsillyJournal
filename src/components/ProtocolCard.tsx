import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

interface ProtocolCardProps {
  productName: string;
  currentDay: number;
  totalDays: number;
}

export function ProtocolCard({ productName, currentDay, totalDays }: ProtocolCardProps) {
  const progress = Math.min((currentDay / totalDays) * 100, 100);

  return (
    <View style={styles.card}>
      <Text style={styles.label}>CURRENT PROTOCOL</Text>
      <Text style={styles.productName}>{productName}</Text>
      <Text style={styles.dayCounter}>Day {currentDay} of {totalDays}</Text>
      <View style={styles.progressBar}>
        <View style={[styles.progressFill, { width: `${progress}%` }]} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#18181b',
    borderRadius: 16,
    padding: 20,
    marginBottom: 20,
  },
  label: {
    color: '#8b5cf6',
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 1,
    marginBottom: 8,
  },
  productName: {
    color: '#ffffff',
    fontSize: 20,
    fontWeight: '700',
    marginBottom: 4,
  },
  dayCounter: {
    color: '#a1a1aa',
    fontSize: 14,
    marginBottom: 16,
  },
  progressBar: {
    height: 8,
    backgroundColor: '#27272a',
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: '#8b5cf6',
    borderRadius: 4,
  },
});

import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';

interface EmptyProtocolCardProps {
  onScanPress: () => void;
}

export function EmptyProtocolCard({ onScanPress }: EmptyProtocolCardProps) {
  return (
    <View style={styles.card}>
      <Text style={styles.icon}>🌱</Text>
      <Text style={styles.title}>Start Your Journey</Text>
      <Text style={styles.description}>
        Scan the QR code on your Psilly bottle to begin tracking your protocol.
      </Text>
      <TouchableOpacity style={styles.button} onPress={onScanPress}>
        <Text style={styles.buttonText}>📷 Scan Bottle</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#18181b',
    borderRadius: 16,
    padding: 32,
    alignItems: 'center',
    marginBottom: 20,
  },
  icon: {
    fontSize: 48,
    marginBottom: 16,
  },
  title: {
    color: '#ffffff',
    fontSize: 20,
    fontWeight: '700',
    marginBottom: 8,
  },
  description: {
    color: '#a1a1aa',
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 24,
    lineHeight: 24,
  },
  button: {
    backgroundColor: '#8b5cf6',
    borderRadius: 12,
    paddingVertical: 14,
    paddingHorizontal: 24,
  },
  buttonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '600',
  },
});

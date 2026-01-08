import React from 'react';
import { TouchableOpacity, Text, StyleSheet, ActivityIndicator } from 'react-native';

interface DoseButtonProps {
  onPress: () => void;
  isLoading?: boolean;
  hasLoggedToday?: boolean;
}

export function DoseButton({ onPress, isLoading, hasLoggedToday }: DoseButtonProps) {
  return (
    <TouchableOpacity
      style={styles.button}
      onPress={onPress}
      disabled={isLoading}
      accessibilityLabel={hasLoggedToday ? "Log another dose" : "Log today's dose"}
      accessibilityRole="button"
    >
      {isLoading ? (
        <ActivityIndicator color="#ffffff" />
      ) : (
        <>
          <Text style={styles.icon}>💊</Text>
          <Text style={styles.text}>
            {hasLoggedToday ? 'Log Another Dose' : "Log Today's Dose"}
          </Text>
        </>
      )}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  button: {
    backgroundColor: '#8b5cf6',
    borderRadius: 12,
    padding: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
    marginBottom: 12,
  },
  icon: {
    fontSize: 24,
  },
  text: {
    color: '#ffffff',
    fontSize: 18,
    fontWeight: '600',
  },
});

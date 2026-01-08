import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Slider from '@react-native-community/slider';

interface MetricSliderProps {
  label: string;
  value: number;
  onChange: (value: number) => void;
  lowLabel?: string;
  highLabel?: string;
}

export function MetricSlider({
  label,
  value,
  onChange,
  lowLabel = 'Low',
  highLabel = 'High',
}: MetricSliderProps) {
  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.label}>{label}</Text>
        <Text style={styles.value}>{value}</Text>
      </View>
      <Slider
        style={styles.slider}
        minimumValue={1}
        maximumValue={5}
        step={1}
        value={value}
        onValueChange={onChange}
        minimumTrackTintColor="#8b5cf6"
        maximumTrackTintColor="#27272a"
        thumbTintColor="#8b5cf6"
      />
      <View style={styles.labels}>
        <Text style={styles.rangeLabel}>{lowLabel}</Text>
        <Text style={styles.rangeLabel}>{highLabel}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: 24,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  label: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '500',
  },
  value: {
    color: '#8b5cf6',
    fontSize: 18,
    fontWeight: '700',
  },
  slider: {
    width: '100%',
    height: 40,
  },
  labels: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  rangeLabel: {
    color: '#71717a',
    fontSize: 12,
  },
});

import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';

interface EntryCardProps {
  dayNumber: number;
  timestamp: number;
  content: string;
  metrics: {
    energy: number;
    clarity: number;
    mood: number;
  };
  isDoseDay: boolean;
  onPress: () => void;
}

export function EntryCard({
  dayNumber,
  timestamp,
  content,
  metrics,
  isDoseDay,
  onPress,
}: EntryCardProps) {
  const date = new Date(timestamp);
  const timeString = date.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
  const dateString = date.toLocaleDateString([], { month: 'short', day: 'numeric' });

  // Truncate content for preview
  const preview = content.length > 100 ? content.slice(0, 100) + '...' : content;

  return (
    <TouchableOpacity style={styles.card} onPress={onPress}>
      <View style={styles.header}>
        <View style={styles.dayBadge}>
          <Text style={styles.dayText}>Day {dayNumber}</Text>
          {isDoseDay && <Text style={styles.doseIndicator}>💊</Text>}
        </View>
        <Text style={styles.date}>{dateString} · {timeString}</Text>
      </View>

      {content.length > 0 && (
        <Text style={styles.preview}>{preview}</Text>
      )}

      <View style={styles.metrics}>
        <View style={styles.metric}>
          <Text style={styles.metricLabel}>Energy</Text>
          <Text style={styles.metricValue}>{metrics.energy}</Text>
        </View>
        <View style={styles.metric}>
          <Text style={styles.metricLabel}>Clarity</Text>
          <Text style={styles.metricValue}>{metrics.clarity}</Text>
        </View>
        <View style={styles.metric}>
          <Text style={styles.metricLabel}>Mood</Text>
          <Text style={styles.metricValue}>{metrics.mood}</Text>
        </View>
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#18181b',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  dayBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  dayText: {
    color: '#8b5cf6',
    fontSize: 14,
    fontWeight: '600',
  },
  doseIndicator: {
    fontSize: 12,
  },
  date: {
    color: '#71717a',
    fontSize: 12,
  },
  preview: {
    color: '#a1a1aa',
    fontSize: 14,
    lineHeight: 20,
    marginBottom: 12,
  },
  metrics: {
    flexDirection: 'row',
    gap: 16,
  },
  metric: {
    alignItems: 'center',
  },
  metricLabel: {
    color: '#71717a',
    fontSize: 11,
    marginBottom: 2,
  },
  metricValue: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '600',
  },
});

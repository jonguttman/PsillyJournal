import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  Alert,
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { getEntryById, deleteEntry } from '../../src/services/entryService';
import type Entry from '../../src/db/models/Entry';

export default function EntryDetailScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const [entry, setEntry] = useState<Entry | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (id) {
      loadEntry();
    }
  }, [id]);

  const loadEntry = async () => {
    const data = await getEntryById(id!);
    setEntry(data);
    setIsLoading(false);
  };

  const handleDelete = () => {
    Alert.alert(
      'Delete Entry',
      'Are you sure you want to delete this entry? This cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            await deleteEntry(id!);
            router.back();
          },
        },
      ]
    );
  };

  if (isLoading) {
    return (
      <View style={styles.container}>
        <Text style={styles.loadingText}>Loading...</Text>
      </View>
    );
  }

  if (!entry) {
    return (
      <View style={styles.container}>
        <Text style={styles.errorText}>Entry not found</Text>
        <TouchableOpacity style={styles.button} onPress={() => router.back()}>
          <Text style={styles.buttonText}>Go Back</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const date = new Date(entry.timestamp);
  const dateString = date.toLocaleDateString([], {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
  });
  const timeString = date.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });

  const metrics = entry.metrics;

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <Text style={styles.backText}>← Back</Text>
        </TouchableOpacity>
        <TouchableOpacity onPress={handleDelete} style={styles.deleteButton}>
          <Text style={styles.deleteText}>Delete</Text>
        </TouchableOpacity>
      </View>

      {/* Date & Day */}
      <View style={styles.meta}>
        <View style={styles.dayBadge}>
          <Text style={styles.dayText}>Day {entry.dayNumber}</Text>
          {entry.isDoseDay && <Text style={styles.doseIndicator}>💊</Text>}
        </View>
        <Text style={styles.date}>{dateString}</Text>
        <Text style={styles.time}>{timeString}</Text>
      </View>

      {/* Metrics */}
      <View style={styles.metricsCard}>
        <View style={styles.metric}>
          <Text style={styles.metricValue}>{metrics.energy}</Text>
          <Text style={styles.metricLabel}>Energy</Text>
        </View>
        <View style={styles.metricDivider} />
        <View style={styles.metric}>
          <Text style={styles.metricValue}>{metrics.clarity}</Text>
          <Text style={styles.metricLabel}>Clarity</Text>
        </View>
        <View style={styles.metricDivider} />
        <View style={styles.metric}>
          <Text style={styles.metricValue}>{metrics.mood}</Text>
          <Text style={styles.metricLabel}>Mood</Text>
        </View>
      </View>

      {/* Content */}
      {entry.content && entry.content.length > 0 && (
        <View style={styles.contentCard}>
          <Text style={styles.contentText}>{entry.content}</Text>
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0a',
  },
  content: {
    padding: 20,
    paddingTop: 60,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 24,
  },
  backButton: {
    padding: 8,
  },
  backText: {
    color: '#8b5cf6',
    fontSize: 16,
  },
  deleteButton: {
    padding: 8,
  },
  deleteText: {
    color: '#ef4444',
    fontSize: 16,
  },
  meta: {
    alignItems: 'center',
    marginBottom: 24,
  },
  dayBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 8,
  },
  dayText: {
    color: '#8b5cf6',
    fontSize: 20,
    fontWeight: '700',
  },
  doseIndicator: {
    fontSize: 18,
  },
  date: {
    color: '#ffffff',
    fontSize: 16,
    marginBottom: 4,
  },
  time: {
    color: '#71717a',
    fontSize: 14,
  },
  metricsCard: {
    backgroundColor: '#18181b',
    borderRadius: 12,
    padding: 20,
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
    marginBottom: 24,
  },
  metric: {
    alignItems: 'center',
  },
  metricValue: {
    color: '#ffffff',
    fontSize: 28,
    fontWeight: '700',
    marginBottom: 4,
  },
  metricLabel: {
    color: '#71717a',
    fontSize: 12,
  },
  metricDivider: {
    width: 1,
    height: 40,
    backgroundColor: '#27272a',
  },
  contentCard: {
    backgroundColor: '#18181b',
    borderRadius: 12,
    padding: 20,
  },
  contentText: {
    color: '#ffffff',
    fontSize: 16,
    lineHeight: 26,
  },
  loadingText: {
    color: '#a1a1aa',
    fontSize: 16,
    textAlign: 'center',
    marginTop: 100,
  },
  errorText: {
    color: '#ef4444',
    fontSize: 16,
    textAlign: 'center',
    marginTop: 100,
    marginBottom: 24,
  },
  button: {
    backgroundColor: '#8b5cf6',
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
    marginHorizontal: 32,
  },
  buttonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '600',
  },
});

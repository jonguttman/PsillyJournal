import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useActiveProtocol } from '../src/hooks';
import { getEntriesForProtocol } from '../src/services/entryService';
import { EntryCard } from '../src/components';
import type Entry from '../src/db/models/Entry';

export default function JournalScreen() {
  const router = useRouter();
  const { protocol } = useActiveProtocol();
  const [entries, setEntries] = useState<Entry[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (protocol) {
      loadEntries();
    }
  }, [protocol]);

  const loadEntries = async () => {
    if (!protocol) return;
    setIsLoading(true);
    try {
      const data = await getEntriesForProtocol(protocol.id);
      setEntries(data);
    } catch (error) {
      console.error('[Journal] Error loading entries:', error);
    } finally {
      setIsLoading(false);
    }
  };

  if (!protocol) {
    return (
      <View style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => router.back()}>
            <Text style={styles.backText}>← Back</Text>
          </TouchableOpacity>
          <Text style={styles.title}>Journal</Text>
          <View style={styles.placeholder} />
        </View>
        <View style={styles.content}>
          <Text style={styles.emptyText}>No active protocol. Please scan a bottle first.</Text>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <Text style={styles.backText}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.title}>Journal</Text>
        <TouchableOpacity onPress={() => router.push('/entry/new')}>
          <Text style={styles.newText}>+ New</Text>
        </TouchableOpacity>
      </View>

      {isLoading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#8b5cf6" />
        </View>
      ) : entries.length === 0 ? (
        <View style={styles.content}>
          <Text style={styles.emptyText}>Your journal entries will appear here.</Text>
          <TouchableOpacity style={styles.button} onPress={() => router.push('/entry/new')}>
            <Text style={styles.buttonText}>Write First Entry</Text>
          </TouchableOpacity>
        </View>
      ) : (
        <ScrollView style={styles.scroll} contentContainerStyle={styles.scrollContent}>
          {entries.map((entry) => (
            <EntryCard
              key={entry.id}
              dayNumber={entry.dayNumber}
              timestamp={entry.timestamp}
              content={entry.content}
              metrics={entry.metrics}
              isDoseDay={entry.isDoseDay}
              onPress={() => router.push(`/entry/${entry.id}`)}
            />
          ))}
        </ScrollView>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0a0a0a' },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 60,
    paddingBottom: 20,
  },
  backText: { color: '#8b5cf6', fontSize: 16 },
  title: { color: '#ffffff', fontSize: 18, fontWeight: '600' },
  newText: { color: '#8b5cf6', fontSize: 16, fontWeight: '600' },
  placeholder: { width: 50 },
  content: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 24 },
  emptyText: { color: '#a1a1aa', fontSize: 16, marginBottom: 24 },
  button: { backgroundColor: '#8b5cf6', paddingVertical: 14, paddingHorizontal: 24, borderRadius: 12 },
  buttonText: { color: '#ffffff', fontSize: 16, fontWeight: '600' },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    padding: 20,
  },
});

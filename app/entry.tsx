import { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, TextInput, ScrollView, Alert } from 'react-native';
import { useRouter } from 'expo-router';
import { useAppStore } from '../src/store/appStore';
import { createEntry } from '../src/services/entryService';

export default function EntryScreen() {
  const router = useRouter();
  const { activeProtocol } = useAppStore();
  const [content, setContent] = useState('');
  const [energy, setEnergy] = useState(3);
  const [clarity, setClarity] = useState(3);
  const [mood, setMood] = useState(3);

  const handleSave = async () => {
    // Validate that we have an active protocol
    if (!activeProtocol) {
      Alert.alert('Error', 'No active protocol found');
      return;
    }

    try {
      // Save entry to database
      await createEntry({
        protocolId: activeProtocol.id,
        dayNumber: activeProtocol.currentDay,
        content: content,
        energy: energy,
        clarity: clarity,
        mood: mood,
      });

      // Navigate back on success
      router.back();
    } catch (error) {
      console.error('[EntryScreen] Failed to save entry:', error);
      Alert.alert('Error', 'Failed to save entry. Please try again.');
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <Text style={styles.cancelText}>Cancel</Text>
        </TouchableOpacity>
        <Text style={styles.title}>New Entry</Text>
        <TouchableOpacity onPress={handleSave}>
          <Text style={styles.saveText}>Save</Text>
        </TouchableOpacity>
      </View>

      <ScrollView style={styles.content}>
        <Text style={styles.dayLabel}>
          Day {activeProtocol?.currentDay || 1} • {new Date().toLocaleDateString()}
        </Text>

        <View style={styles.metricsContainer}>
          <MetricSlider label="Energy" value={energy} onChange={setEnergy} />
          <MetricSlider label="Clarity" value={clarity} onChange={setClarity} />
          <MetricSlider label="Mood" value={mood} onChange={setMood} />
        </View>

        <Text style={styles.sectionLabel}>Reflections</Text>
        <TextInput
          style={styles.textInput}
          multiline
          placeholder="How are you feeling today?"
          placeholderTextColor="#52525b"
          value={content}
          onChangeText={setContent}
        />
      </ScrollView>
    </View>
  );
}

function MetricSlider({ label, value, onChange }: { label: string; value: number; onChange: (v: number) => void }) {
  return (
    <View style={styles.metric}>
      <Text style={styles.metricLabel}>{label}</Text>
      <View style={styles.metricButtons}>
        {[1, 2, 3, 4, 5].map((n) => (
          <TouchableOpacity
            key={n}
            style={[styles.metricButton, value === n && styles.metricButtonActive]}
            onPress={() => onChange(n)}
          >
            <Text style={[styles.metricButtonText, value === n && styles.metricButtonTextActive]}>{n}</Text>
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0a0a0a' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 20, paddingTop: 60, paddingBottom: 20 },
  cancelText: { color: '#a1a1aa', fontSize: 16 },
  title: { color: '#ffffff', fontSize: 18, fontWeight: '600' },
  saveText: { color: '#8b5cf6', fontSize: 16, fontWeight: '600' },
  content: { flex: 1, padding: 20 },
  dayLabel: { color: '#8b5cf6', fontSize: 14, fontWeight: '500', marginBottom: 24 },
  metricsContainer: { marginBottom: 32 },
  metric: { marginBottom: 20 },
  metricLabel: { color: '#ffffff', fontSize: 14, marginBottom: 12 },
  metricButtons: { flexDirection: 'row', gap: 8 },
  metricButton: { flex: 1, backgroundColor: '#18181b', paddingVertical: 12, borderRadius: 8, alignItems: 'center' },
  metricButtonActive: { backgroundColor: '#8b5cf6' },
  metricButtonText: { color: '#a1a1aa', fontSize: 16, fontWeight: '500' },
  metricButtonTextActive: { color: '#ffffff' },
  sectionLabel: { color: '#ffffff', fontSize: 16, fontWeight: '600', marginBottom: 12 },
  textInput: { backgroundColor: '#18181b', borderRadius: 12, padding: 16, color: '#ffffff', fontSize: 16, minHeight: 200, textAlignVertical: 'top' },
});

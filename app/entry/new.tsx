import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useActiveProtocol } from '../../src/hooks';
import { createEntry } from '../../src/services/entryService';
import { MetricSlider } from '../../src/components/MetricSlider';
import { promptService } from '../../src/services/promptService';
import type { ReflectionMetrics } from '../../src/types';
import type { ReflectionPrompt } from '../../src/data/prompts';

export default function NewEntryScreen() {
  const router = useRouter();
  const { protocol } = useActiveProtocol();

  const [content, setContent] = useState('');
  const [metrics, setMetrics] = useState<ReflectionMetrics>({
    energy: 3,
    clarity: 3,
    mood: 3,
  });
  const [isSaving, setIsSaving] = useState(false);
  const [currentPrompt, setCurrentPrompt] = useState<ReflectionPrompt | null>(null);

  // Load a reflection prompt when the screen mounts
  useEffect(() => {
    loadPrompt();
  }, []);

  const loadPrompt = async () => {
    const prompt = await promptService.getNextPrompt();
    setCurrentPrompt(prompt);
  };

  const refreshPrompt = async () => {
    const prompt = await promptService.getNextPrompt();
    setCurrentPrompt(prompt);
  };

  if (!protocol) {
    return (
      <View style={styles.container}>
        <Text style={styles.errorText}>No active protocol. Please scan a bottle first.</Text>
        <TouchableOpacity style={styles.button} onPress={() => router.replace('/')}>
          <Text style={styles.buttonText}>Go Home</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const handleSave = async () => {
    if (isSaving) return;
    setIsSaving(true);

    try {
      await createEntry({
        protocolId: protocol.id,
        dayNumber: protocol.currentDay,
        content: content.trim(),
        metrics,
        isDoseDay: true, // TODO: Check if dose was logged today
        tags: [],
        reflectionPromptId: currentPrompt?.id,
        reflectionPromptText: currentPrompt?.text,
      });

      // Mark prompt as seen after successfully saving
      if (currentPrompt) {
        await promptService.markSeen(currentPrompt.id);
      }

      router.back();
    } catch (error) {
      console.error('[NewEntry] Error saving:', error);
      Alert.alert('Error', 'Failed to save entry. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  const updateMetric = (key: keyof ReflectionMetrics) => (value: number) => {
    setMetrics((prev) => ({ ...prev, [key]: value }));
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView style={styles.scroll} contentContainerStyle={styles.content}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity onPress={() => router.back()} style={styles.cancelButton}>
            <Text style={styles.cancelText}>Cancel</Text>
          </TouchableOpacity>
          <Text style={styles.title}>Day {protocol.currentDay}</Text>
          <TouchableOpacity
            onPress={handleSave}
            style={[styles.saveButton, isSaving && styles.saveButtonDisabled]}
            disabled={isSaving}
          >
            <Text style={styles.saveText}>{isSaving ? 'Saving...' : 'Save'}</Text>
          </TouchableOpacity>
        </View>

        {/* Reflection Prompt */}
        {currentPrompt && (
          <View style={styles.promptContainer}>
            <View style={styles.promptHeader}>
              <Text style={styles.promptEmoji}>💭</Text>
              <Text style={styles.promptLabel}>Reflect on...</Text>
            </View>
            <Text style={styles.promptText}>{currentPrompt.text}</Text>
            <TouchableOpacity onPress={refreshPrompt} style={styles.refreshButton}>
              <Text style={styles.refreshText}>↻ Different prompt</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Journal Content */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>How are you feeling?</Text>
          <TextInput
            style={styles.textInput}
            placeholder="Write your reflection..."
            placeholderTextColor="#71717a"
            multiline
            value={content}
            onChangeText={setContent}
            textAlignVertical="top"
          />
        </View>

        {/* Metrics */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Quick Check-in</Text>

          <MetricSlider
            label="Energy"
            value={metrics.energy}
            onChange={updateMetric('energy')}
            lowLabel="Tired"
            highLabel="Energized"
          />

          <MetricSlider
            label="Clarity"
            value={metrics.clarity}
            onChange={updateMetric('clarity')}
            lowLabel="Foggy"
            highLabel="Clear"
          />

          <MetricSlider
            label="Mood"
            value={metrics.mood}
            onChange={updateMetric('mood')}
            lowLabel="Low"
            highLabel="Great"
          />
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0a',
  },
  scroll: {
    flex: 1,
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
  cancelButton: {
    padding: 8,
  },
  cancelText: {
    color: '#a1a1aa',
    fontSize: 16,
  },
  title: {
    color: '#ffffff',
    fontSize: 18,
    fontWeight: '600',
  },
  saveButton: {
    backgroundColor: '#8b5cf6',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 8,
  },
  saveButtonDisabled: {
    opacity: 0.5,
  },
  saveText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '600',
  },
  section: {
    marginBottom: 32,
  },
  sectionTitle: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 16,
  },
  textInput: {
    backgroundColor: '#18181b',
    borderRadius: 12,
    padding: 16,
    color: '#ffffff',
    fontSize: 16,
    minHeight: 150,
    lineHeight: 24,
  },
  errorText: {
    color: '#ef4444',
    fontSize: 16,
    textAlign: 'center',
    marginTop: 100,
    marginBottom: 24,
    paddingHorizontal: 32,
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
  promptContainer: {
    backgroundColor: '#18181b',
    borderRadius: 12,
    padding: 16,
    marginBottom: 24,
    borderLeftWidth: 3,
    borderLeftColor: '#8b5cf6',
  },
  promptHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  promptEmoji: {
    fontSize: 18,
    marginRight: 8,
  },
  promptLabel: {
    color: '#a1a1aa',
    fontSize: 13,
    fontWeight: '600',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  promptText: {
    color: '#ffffff',
    fontSize: 16,
    lineHeight: 24,
    fontStyle: 'italic',
    marginBottom: 12,
  },
  refreshButton: {
    alignSelf: 'flex-start',
    paddingVertical: 4,
    paddingHorizontal: 8,
  },
  refreshText: {
    color: '#8b5cf6',
    fontSize: 13,
    fontWeight: '500',
  },
});

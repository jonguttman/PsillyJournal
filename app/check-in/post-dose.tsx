import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  Alert,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { MetricSlider } from '../../src/components/MetricSlider';
import { ActivityTagSelector } from '../../src/components/ActivityTagSelector';
import {
  updatePostDoseMetrics,
  getEntryByDoseId,
  isDoseWithin24Hours,
  type PostDoseMetrics,
} from '../../src/services/entryService';
import { cancelReminderForDose } from '../../src/services/notificationService';
import { calendarService } from '../../src/services/calendarService';
import { localStorageDB } from '../../src/db/localStorageDB';

export default function PostDoseCheckInScreen() {
  const router = useRouter();
  const params = useLocalSearchParams<{
    dose_id: string;
    entry_id: string;
  }>();

  const doseId = params.dose_id;
  const entryId = params.entry_id;

  const [metrics, setMetrics] = useState<PostDoseMetrics>({
    energy: 5,
    clarity: 5,
    mood: 5,
  });
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [contextNotes, setContextNotes] = useState('');
  const [isSaving, setIsSaving] = useState(false);
  const [isExpired, setIsExpired] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    checkValidity();
  }, [doseId]);

  const checkValidity = async () => {
    setIsLoading(true);
    try {
      // Check if dose exists and is within 24h
      const dose = await localStorageDB.doses.find(doseId);

      if (!dose) {
        setIsExpired(true);
        return;
      }

      if (!isDoseWithin24Hours(dose.timestamp)) {
        setIsExpired(true);
        return;
      }

      // Check if entry exists
      const entry = await getEntryByDoseId(doseId);
      if (!entry) {
        // Entry might not exist if user skipped pre-dose
        console.log('[PostDoseCheckIn] No entry found for dose, will create on save');
      }
    } catch (error) {
      console.error('[PostDoseCheckIn] Error checking validity:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const updateMetric = (key: keyof PostDoseMetrics) => (value: number) => {
    setMetrics((prev) => ({ ...prev, [key]: value }));
  };

  const handleSave = async () => {
    if (isSaving) return;
    setIsSaving(true);

    try {
      // Find or determine the entry ID
      let targetEntryId = entryId;
      
      if (!targetEntryId) {
        // Try to find entry by dose ID
        const entry = await getEntryByDoseId(doseId);
        if (entry) {
          targetEntryId = entry.id;
        }
      }

      if (!targetEntryId) {
        Alert.alert('Error', 'Could not find the check-in entry. Please try again.');
        setIsSaving(false);
        return;
      }

      // Update entry with post-dose metrics and context
      await updatePostDoseMetrics(targetEntryId, metrics, {
        activity: selectedTags.length > 0 ? selectedTags : undefined,
        notes: contextNotes.trim() || undefined,
      });

      // Cancel both calendar and notification reminders (user completed early)
      await Promise.all([
        calendarService.cancelReminder(doseId),
        cancelReminderForDose(doseId),
      ]);

      // Show success toast
      Alert.alert(
        'Check-in saved!',
        'Your post-dose reflection has been recorded.',
        [{ text: 'OK', onPress: () => router.replace('/') }]
      );
    } catch (error) {
      console.error('[PostDoseCheckIn] Error saving:', error);
      Alert.alert('Error', 'Failed to save check-in. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  const handleBack = () => {
    Alert.alert(
      'Discard check-in?',
      'Your responses won\'t be saved.',
      [
        { text: 'Stay', style: 'cancel' },
        { text: 'Discard', style: 'destructive', onPress: () => router.back() },
      ]
    );
  };

  if (isLoading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.centered}>
          <Text style={styles.loadingText}>Loading...</Text>
        </View>
      </SafeAreaView>
    );
  }

  if (isExpired) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.centered}>
          <Text style={styles.expiredIcon}>⏰</Text>
          <Text style={styles.expiredTitle}>Check-in Expired</Text>
          <Text style={styles.expiredText}>
            This check-in is no longer available.{'\n'}
            Check-ins are valid for 24 hours after your dose.
          </Text>
          <TouchableOpacity
            style={styles.homeButton}
            onPress={() => router.replace('/')}
          >
            <Text style={styles.homeButtonText}>Go Home</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAvoidingView
        style={styles.keyboardView}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        <ScrollView
          style={styles.scroll}
          contentContainerStyle={styles.content}
          keyboardShouldPersistTaps="handled"
        >
          {/* Header */}
          <View style={styles.header}>
            <TouchableOpacity onPress={handleBack} style={styles.backButton}>
              <Text style={styles.backText}>← Back</Text>
            </TouchableOpacity>
          </View>

          {/* Title */}
          <View style={styles.titleSection}>
            <Text style={styles.icon}>✨</Text>
            <Text style={styles.title}>How was your experience?</Text>
          </View>

          {/* Sliders */}
          <View style={styles.slidersSection}>
            <MetricSlider
              label="Energy"
              value={metrics.energy}
              onChange={updateMetric('energy')}
              lowLabel="low"
              highLabel="high"
              min={0}
              max={10}
            />

            <MetricSlider
              label="Clarity"
              value={metrics.clarity}
              onChange={updateMetric('clarity')}
              lowLabel="foggy"
              highLabel="clear"
              min={0}
              max={10}
            />

            <MetricSlider
              label="Mood"
              value={metrics.mood}
              onChange={updateMetric('mood')}
              lowLabel="difficult"
              highLabel="good"
              min={0}
              max={10}
            />
          </View>

          {/* Context Capture (Optional) */}
          <View style={styles.contextSection}>
            <Text style={styles.contextLabel}>Optional: What were you doing?</Text>
            <Text style={styles.contextHint}>Helps you discover patterns later</Text>

            <ActivityTagSelector
              selectedTags={selectedTags}
              onTagsChange={setSelectedTags}
            />

            <TextInput
              style={styles.contextInput}
              value={contextNotes}
              onChangeText={(text) => setContextNotes(text.slice(0, 50))}
              placeholder="Any details? (50 char max)"
              placeholderTextColor="#71717a"
              maxLength={50}
            />
            <Text style={styles.charCount}>
              {contextNotes.length}/50
            </Text>
          </View>

          {/* Save Button */}
          <TouchableOpacity
            style={[styles.saveButton, isSaving && styles.saveButtonDisabled]}
            onPress={handleSave}
            disabled={isSaving}
          >
            <Text style={styles.saveText}>
              {isSaving ? 'Saving...' : 'Save reflection'}
            </Text>
          </TouchableOpacity>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0a',
  },
  keyboardView: {
    flex: 1,
  },
  scroll: {
    flex: 1,
  },
  content: {
    padding: 20,
    paddingTop: 10,
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 32,
  },
  loadingText: {
    color: '#a1a1aa',
    fontSize: 16,
  },
  expiredIcon: {
    fontSize: 48,
    marginBottom: 16,
  },
  expiredTitle: {
    color: '#ffffff',
    fontSize: 24,
    fontWeight: '700',
    marginBottom: 12,
  },
  expiredText: {
    color: '#a1a1aa',
    fontSize: 16,
    textAlign: 'center',
    lineHeight: 24,
    marginBottom: 32,
  },
  homeButton: {
    backgroundColor: '#8b5cf6',
    paddingHorizontal: 32,
    paddingVertical: 14,
    borderRadius: 12,
  },
  homeButtonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '600',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'flex-start',
    alignItems: 'center',
    marginBottom: 32,
  },
  backButton: {
    padding: 8,
  },
  backText: {
    color: '#a1a1aa',
    fontSize: 16,
  },
  titleSection: {
    marginBottom: 32,
    alignItems: 'center',
  },
  icon: {
    fontSize: 48,
    marginBottom: 12,
  },
  title: {
    color: '#ffffff',
    fontSize: 28,
    fontWeight: '700',
    marginBottom: 8,
    textAlign: 'center',
  },
  slidersSection: {
    marginBottom: 24,
  },
  contextSection: {
    marginBottom: 32,
    paddingTop: 16,
    borderTopWidth: 1,
    borderTopColor: '#27272a',
  },
  contextLabel: {
    color: '#a1a1aa',
    fontSize: 16,
    fontWeight: '500',
    marginBottom: 4,
  },
  contextHint: {
    color: '#71717a',
    fontSize: 12,
    marginBottom: 16,
  },
  contextInput: {
    backgroundColor: '#18181b',
    borderRadius: 12,
    padding: 14,
    color: '#ffffff',
    fontSize: 16,
    borderWidth: 1,
    borderColor: '#27272a',
    marginTop: 12,
  },
  charCount: {
    color: '#71717a',
    fontSize: 12,
    textAlign: 'right',
    marginTop: 4,
  },
  saveButton: {
    backgroundColor: '#6366f1',
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  saveButtonDisabled: {
    opacity: 0.5,
  },
  saveText: {
    color: '#ffffff',
    fontSize: 18,
    fontWeight: '600',
  },
});

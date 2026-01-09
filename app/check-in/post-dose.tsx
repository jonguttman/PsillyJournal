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
import {
  updatePostDoseMetrics,
  getEntryByDoseId,
  isDoseWithin24Hours,
  type PostDoseMetrics,
} from '../../src/services/entryService';
import { cancelReminderForDose } from '../../src/services/notificationService';
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
  const [notes, setNotes] = useState('');
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
      const dose = localStorageDB.doses.find(doseId);
      
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

      // Update entry with post-dose metrics
      await updatePostDoseMetrics(targetEntryId, metrics, notes.trim() || undefined);

      // Cancel any scheduled notification for this dose
      await cancelReminderForDose(doseId);

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
            <Text style={styles.title}>How are you feeling now?</Text>
            <Text style={styles.subtitle}>After your dose</Text>
          </View>

          {/* Sliders */}
          <View style={styles.slidersSection}>
            <MetricSlider
              label="Energy"
              value={metrics.energy}
              onChange={updateMetric('energy')}
              lowLabel="Depleted"
              highLabel="Vibrant"
              min={0}
              max={10}
            />

            <MetricSlider
              label="Clarity"
              value={metrics.clarity}
              onChange={updateMetric('clarity')}
              lowLabel="Foggy"
              highLabel="Crystal Clear"
              min={0}
              max={10}
            />

            <MetricSlider
              label="Mood"
              value={metrics.mood}
              onChange={updateMetric('mood')}
              lowLabel="Heavy"
              highLabel="Light"
              min={0}
              max={10}
            />
          </View>

          {/* Notes */}
          <View style={styles.notesSection}>
            <Text style={styles.notesLabel}>Any notes? (optional)</Text>
            <TextInput
              style={styles.notesInput}
              value={notes}
              onChangeText={setNotes}
              placeholder="How did today go..."
              placeholderTextColor="#71717a"
              multiline
              numberOfLines={2}
              textAlignVertical="top"
            />
          </View>

          {/* Save Button */}
          <TouchableOpacity
            style={[styles.saveButton, isSaving && styles.saveButtonDisabled]}
            onPress={handleSave}
            disabled={isSaving}
          >
            <Text style={styles.saveText}>
              {isSaving ? 'Saving...' : 'Save ✓'}
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
  },
  title: {
    color: '#ffffff',
    fontSize: 28,
    fontWeight: '700',
    marginBottom: 8,
  },
  subtitle: {
    color: '#a1a1aa',
    fontSize: 16,
  },
  slidersSection: {
    marginBottom: 24,
  },
  notesSection: {
    marginBottom: 32,
  },
  notesLabel: {
    color: '#a1a1aa',
    fontSize: 14,
    marginBottom: 8,
  },
  notesInput: {
    backgroundColor: '#18181b',
    borderRadius: 12,
    padding: 14,
    color: '#ffffff',
    fontSize: 16,
    minHeight: 60,
    maxHeight: 80,
    borderWidth: 1,
    borderColor: '#27272a',
  },
  saveButton: {
    backgroundColor: '#8b5cf6',
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

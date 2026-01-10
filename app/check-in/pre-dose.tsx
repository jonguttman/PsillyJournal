import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  Alert,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { createCheckInEntry } from '../../src/services/entryService';
import { schedulePostDoseReminder } from '../../src/services/notificationService';
import { useAppStore } from '../../src/store/appStore';
import { localStorageDB } from '../../src/db/localStorageDB';

const EXAMPLE_WORDS = ['Good', 'Okay', 'Low', 'Stressed', 'Excited', 'Meh'];

export default function PreDoseCheckInScreen() {
  const router = useRouter();
  const params = useLocalSearchParams<{
    dose_id: string;
    protocol_id: string;
    day_number: string;
  }>();

  const { notificationTiming } = useAppStore();
  const [preDoseState, setPreDoseState] = useState('');
  const [isSaving, setIsSaving] = useState(false);

  const doseId = params.dose_id;
  const protocolId = params.protocol_id;
  const dayNumber = parseInt(params.day_number || '1', 10);

  // Get the dose timestamp
  const getDoseTimestamp = (): number => {
    const dose = localStorageDB.doses.find(doseId);
    return dose?.timestamp || Date.now();
  };

  // Helper to show cross-platform alert
  const showJournalPrompt = async (entry: { id: string }, doseTimestamp: number) => {
    const handleYes = () => {
      router.replace({
        pathname: '/entry/new',
        params: {
          entry_id: entry.id,
          dose_id: doseId,
        },
      });
    };

    const handleNo = async () => {
      await schedulePostDoseReminder(
        doseId,
        entry.id,
        doseTimestamp,
        notificationTiming
      );
      router.replace('/');
    };

    // Use window.confirm on web, Alert.alert on native
    if (Platform.OS === 'web') {
      const wantsJournal = window.confirm('Add a journal note?\n\nYou can write more about how you\'re feeling.');
      if (wantsJournal) {
        handleYes();
      } else {
        await handleNo();
      }
    } else {
      Alert.alert(
        'Add a journal note?',
        'You can write more about how you\'re feeling.',
        [
          { text: 'No', style: 'cancel', onPress: handleNo },
          { text: 'Yes', onPress: handleYes },
        ]
      );
    }
  };

  const handleContinue = async () => {
    if (isSaving) return;
    setIsSaving(true);

    try {
      const doseTimestamp = getDoseTimestamp();
      
      // Create check-in entry
      const entry = await createCheckInEntry({
        protocolId,
        doseId,
        dayNumber,
        preDoseState: preDoseState.trim() || null,
        doseTimestamp,
      });

      // Ask about journal note (cross-platform)
      await showJournalPrompt(entry, doseTimestamp);
    } catch (error) {
      console.error('[PreDoseCheckIn] Error:', error);
      if (Platform.OS === 'web') {
        window.alert('Failed to save check-in. Please try again.');
      } else {
        Alert.alert('Error', 'Failed to save check-in. Please try again.');
      }
    } finally {
      setIsSaving(false);
    }
  };

  const handleSkip = () => {
    if (Platform.OS === 'web') {
      const shouldSkip = window.confirm('Skip check-in?\n\nYou can still add a journal note.');
      if (shouldSkip) {
        setPreDoseState('');
        handleContinueWithSkip();
      }
    } else {
      Alert.alert(
        'Skip check-in?',
        'You can still add a journal note.',
        [
          { text: 'Cancel', style: 'cancel' },
          {
            text: 'Skip',
            onPress: () => {
              setPreDoseState('');
              handleContinueWithSkip();
            },
          },
        ]
      );
    }
  };

  const handleContinueWithSkip = async () => {
    setIsSaving(true);

    try {
      const doseTimestamp = getDoseTimestamp();
      
      // Create check-in entry with null pre-dose state
      const entry = await createCheckInEntry({
        protocolId,
        doseId,
        dayNumber,
        preDoseState: null,
        doseTimestamp,
      });

      // Ask about journal note (reuse cross-platform helper)
      await showJournalPrompt(entry, doseTimestamp);
    } catch (error) {
      console.error('[PreDoseCheckIn] Skip error:', error);
      if (Platform.OS === 'web') {
        window.alert('Failed to save. Please try again.');
      } else {
        Alert.alert('Error', 'Failed to save. Please try again.');
      }
    } finally {
      setIsSaving(false);
    }
  };

  const handleChipPress = (word: string) => {
    setPreDoseState(word);
  };

  const handleBack = () => {
    if (Platform.OS === 'web') {
      const shouldLeave = window.confirm('Cancel check-in?\n\nYour dose has been logged. The check-in helps track your experience.');
      if (shouldLeave) {
        router.back();
      }
    } else {
      Alert.alert(
        'Cancel check-in?',
        'Your dose has been logged. The check-in helps track your experience.',
        [
          { text: 'Stay', style: 'cancel' },
          { 
            text: 'Go Back', 
            style: 'destructive',
            onPress: () => router.back() 
          },
        ]
      );
    }
  };

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
            <TouchableOpacity onPress={handleSkip} style={styles.skipButton}>
              <Text style={styles.skipText}>Skip</Text>
            </TouchableOpacity>
          </View>

          {/* Title */}
          <View style={styles.titleSection}>
            <Text style={styles.title}>How do you feel right now?</Text>
            <Text style={styles.subtitle}>One word to describe your current state</Text>
          </View>

          {/* Input */}
          <TextInput
            style={styles.input}
            value={preDoseState}
            onChangeText={setPreDoseState}
            placeholder="Enter a word..."
            placeholderTextColor="#71717a"
            autoCapitalize="words"
            autoFocus
            returnKeyType="done"
            onSubmitEditing={() => preDoseState.trim() && handleContinue()}
          />

          {/* Example Chips */}
          <View style={styles.chipsContainer}>
            <Text style={styles.chipsLabel}>Or tap one:</Text>
            <View style={styles.chips}>
              {EXAMPLE_WORDS.map((word) => (
                <TouchableOpacity
                  key={word}
                  style={[
                    styles.chip,
                    preDoseState === word && styles.chipSelected,
                  ]}
                  onPress={() => handleChipPress(word)}
                >
                  <Text
                    style={[
                      styles.chipText,
                      preDoseState === word && styles.chipTextSelected,
                    ]}
                  >
                    {word}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>

          {/* Continue Button */}
          <TouchableOpacity
            style={[
              styles.continueButton,
              (!preDoseState.trim() || isSaving) && styles.continueButtonDisabled,
            ]}
            onPress={handleContinue}
            disabled={!preDoseState.trim() || isSaving}
          >
            <Text style={styles.continueText}>
              {isSaving ? 'Saving...' : 'Continue →'}
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
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 40,
  },
  backButton: {
    padding: 8,
  },
  backText: {
    color: '#a1a1aa',
    fontSize: 16,
  },
  skipButton: {
    padding: 8,
  },
  skipText: {
    color: '#8b5cf6',
    fontSize: 16,
    fontWeight: '500',
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
  input: {
    backgroundColor: '#18181b',
    borderRadius: 12,
    padding: 16,
    color: '#ffffff',
    fontSize: 18,
    marginBottom: 24,
    borderWidth: 1,
    borderColor: '#27272a',
  },
  chipsContainer: {
    marginBottom: 32,
  },
  chipsLabel: {
    color: '#71717a',
    fontSize: 14,
    marginBottom: 12,
  },
  chips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  chip: {
    backgroundColor: '#18181b',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#27272a',
  },
  chipSelected: {
    backgroundColor: '#8b5cf6',
    borderColor: '#8b5cf6',
  },
  chipText: {
    color: '#a1a1aa',
    fontSize: 15,
    fontWeight: '500',
  },
  chipTextSelected: {
    color: '#ffffff',
  },
  continueButton: {
    backgroundColor: '#8b5cf6',
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
    marginTop: 'auto',
  },
  continueButtonDisabled: {
    opacity: 0.5,
  },
  continueText: {
    color: '#ffffff',
    fontSize: 18,
    fontWeight: '600',
  },
});

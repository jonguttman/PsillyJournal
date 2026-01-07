import { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, Alert } from 'react-native';
import { useRouter } from 'expo-router';
import { useAppStore } from '../src/store/appStore';
import { createBottleAndProtocol } from '../src/services/bottleService';
import { generateRecoveryKey } from '../src/utils/crypto';
import * as SecureStore from 'expo-secure-store';
import { STORAGE_KEYS } from '../src/config';

export default function OnboardingScreen() {
  const router = useRouter();
  const { pendingBottle, setPendingBottle, setActiveProtocol, setOnboardingComplete } = useAppStore();
  const [step, setStep] = useState<'welcome' | 'privacy' | 'recovery'>('welcome');
  const [recoveryKey, setRecoveryKey] = useState<string | null>(null);
  const [isCreating, setIsCreating] = useState(false);

  if (!pendingBottle) {
    return (
      <View style={styles.container}>
        <Text style={styles.errorText}>No product selected. Please scan a bottle first.</Text>
        <TouchableOpacity style={styles.button} onPress={() => router.replace('/')}>
          <Text style={styles.buttonText}>Go Back</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const handleStartProtocol = async () => {
    if (isCreating) return;
    setIsCreating(true);

    try {
      const key = await generateRecoveryKey();
      setRecoveryKey(key);
      await SecureStore.setItemAsync(STORAGE_KEYS.RECOVERY_KEY, key);

      const { protocol } = await createBottleAndProtocol(
        pendingBottle.token,
        pendingBottle.productInfo
      );

      setActiveProtocol({
        id: protocol.id,
        sessionId: protocol.sessionId,
        productId: protocol.productId,
        productName: protocol.productName,
        currentDay: protocol.currentDay,
        totalDays: protocol.totalDays,
        status: protocol.status,
      });

      setStep('recovery');
    } catch (error) {
      Alert.alert('Error', 'Failed to start protocol. Please try again.');
    } finally {
      setIsCreating(false);
    }
  };

  const handleComplete = async () => {
    await SecureStore.setItemAsync(STORAGE_KEYS.ONBOARDING_COMPLETE, 'true');
    setOnboardingComplete(true);
    setPendingBottle(null);
    router.replace('/');
  };

  if (step === 'welcome') {
    return (
      <ScrollView style={styles.container} contentContainerStyle={styles.content}>
        <View style={styles.header}>
          <Text style={styles.emoji}>🍄</Text>
          <Text style={styles.title}>Welcome to Psilly Journal</Text>
          <Text style={styles.subtitle}>Your private microdosing companion</Text>
        </View>

        <View style={styles.productCard}>
          <Text style={styles.productLabel}>YOUR PRODUCT</Text>
          <Text style={styles.productName}>{pendingBottle.productInfo.name}</Text>
          {pendingBottle.productInfo.description && (
            <Text style={styles.productDescription}>{pendingBottle.productInfo.description}</Text>
          )}
        </View>

        <TouchableOpacity style={styles.button} onPress={() => setStep('privacy')}>
          <Text style={styles.buttonText}>Continue</Text>
        </TouchableOpacity>
      </ScrollView>
    );
  }

  if (step === 'privacy') {
    return (
      <ScrollView style={styles.container} contentContainerStyle={styles.content}>
        <View style={styles.header}>
          <Text style={styles.emoji}>🔐</Text>
          <Text style={styles.title}>Your Privacy Matters</Text>
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>Stays on your device:</Text>
          <Text style={styles.cardItem}>✓ Journal entries</Text>
          <Text style={styles.cardItem}>✓ Personal notes</Text>
          <Text style={styles.cardItem}>✓ Your identity</Text>
        </View>

        <TouchableOpacity style={styles.button} onPress={handleStartProtocol} disabled={isCreating}>
          <Text style={styles.buttonText}>{isCreating ? 'Setting up...' : 'Start My Journal'}</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.linkButton} onPress={() => setStep('welcome')}>
          <Text style={styles.linkText}>← Back</Text>
        </TouchableOpacity>
      </ScrollView>
    );
  }

  if (step === 'recovery') {
    return (
      <ScrollView style={styles.container} contentContainerStyle={styles.content}>
        <View style={styles.header}>
          <Text style={styles.emoji}>🔑</Text>
          <Text style={styles.title}>Save Your Recovery Key</Text>
        </View>

        <Text style={styles.warning}>
          This is your only way to restore your journal on a new device. Save it somewhere safe.
        </Text>

        <View style={styles.keyBox}>
          <Text style={styles.recoveryKey}>{recoveryKey}</Text>
        </View>

        <TouchableOpacity style={styles.button} onPress={handleComplete}>
          <Text style={styles.buttonText}>I've Saved My Key</Text>
        </TouchableOpacity>
      </ScrollView>
    );
  }

  return null;
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0a0a0a' },
  content: { padding: 24, paddingTop: 60 },
  header: { alignItems: 'center', marginBottom: 32 },
  emoji: { fontSize: 64, marginBottom: 16 },
  title: { color: '#ffffff', fontSize: 28, fontWeight: '700', textAlign: 'center', marginBottom: 8 },
  subtitle: { color: '#a1a1aa', fontSize: 16, textAlign: 'center' },
  productCard: { backgroundColor: '#18181b', borderRadius: 16, padding: 20, marginBottom: 32, borderWidth: 1, borderColor: '#8b5cf6' },
  productLabel: { color: '#8b5cf6', fontSize: 12, fontWeight: '600', letterSpacing: 1, marginBottom: 8 },
  productName: { color: '#ffffff', fontSize: 24, fontWeight: '700', marginBottom: 8 },
  productDescription: { color: '#a1a1aa', fontSize: 14 },
  card: { backgroundColor: '#18181b', borderRadius: 12, padding: 16, marginBottom: 24 },
  cardTitle: { color: '#ffffff', fontSize: 16, fontWeight: '600', marginBottom: 12 },
  cardItem: { color: '#a1a1aa', fontSize: 14, marginBottom: 8 },
  button: { backgroundColor: '#8b5cf6', paddingVertical: 16, borderRadius: 12, alignItems: 'center', marginBottom: 16 },
  buttonText: { color: '#ffffff', fontSize: 16, fontWeight: '600' },
  linkButton: { alignItems: 'center', padding: 12 },
  linkText: { color: '#8b5cf6', fontSize: 14 },
  warning: { color: '#fbbf24', fontSize: 14, lineHeight: 22, textAlign: 'center', marginBottom: 24 },
  keyBox: { backgroundColor: '#18181b', borderRadius: 12, padding: 20, marginBottom: 32, alignItems: 'center' },
  recoveryKey: { color: '#ffffff', fontSize: 18, fontWeight: '600', fontFamily: 'monospace', letterSpacing: 2 },
  errorText: { color: '#ef4444', fontSize: 16, textAlign: 'center', marginTop: 100, marginBottom: 24, paddingHorizontal: 32 },
});

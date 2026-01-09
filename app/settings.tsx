import { View, Text, StyleSheet, TouchableOpacity, Switch, Alert, Platform, ScrollView } from 'react-native';
import { useRouter } from 'expo-router';
import { useAppStore } from '../src/store/appStore';
import * as SecureStore from 'expo-secure-store';
import { STORAGE_KEYS } from '../src/config';
import { useState, useEffect } from 'react';
import { localStorageDB } from '../src/db/localStorageDB';
import { isPinSet } from '../src/utils/lock';
import { useLockProtection } from '../src/hooks';

// Web fallback for SecureStore
const storage = {
  setItem: async (key: string, value: string) => {
    if (Platform.OS === 'web') {
      localStorage.setItem(key, value);
    } else {
      await SecureStore.setItemAsync(key, value);
    }
  },
  getItem: async (key: string): Promise<string | null> => {
    if (Platform.OS === 'web') {
      return localStorage.getItem(key);
    }
    return SecureStore.getItemAsync(key);
  },
};

export default function SettingsScreen() {
  const router = useRouter();
  useLockProtection(); // Protect this route from locked access
  const { hasOptedIn, setOptedIn, activeProtocol, setLocked } = useAppStore();
  const [recoveryKey, setRecoveryKey] = useState<string | null>(null);
  const [showKey, setShowKey] = useState(false);
  const [hasPinSet, setHasPinSet] = useState(false);

  useEffect(() => {
    loadRecoveryKey();
    checkPinStatus();
  }, []);

  const loadRecoveryKey = async () => {
    const key = await storage.getItem(STORAGE_KEYS.RECOVERY_KEY);
    console.log('[Settings] Recovery key loaded:', key ? 'exists' : 'null');
    setRecoveryKey(key);
  };

  const checkPinStatus = async () => {
    const pinExists = await isPinSet();
    setHasPinSet(pinExists);
  };

  const toggleOptIn = async (value: boolean) => {
    setOptedIn(value);
    await storage.setItem(STORAGE_KEYS.HAS_OPTED_IN, value ? 'true' : 'false');
  };

  const toggleRecoveryKey = () => {
    if (!recoveryKey) {
      Alert.alert('No Recovery Key', 'No recovery key found. Please complete onboarding first.');
      return;
    }
    setShowKey(!showKey);
  };

  const handleLockJournal = () => {
    setLocked(true);
    router.replace('/lock');
  };

  const handleRemovePin = () => {
    Alert.alert(
      'Remove PIN',
      'Are you sure you want to remove your PIN? Your journal will no longer be protected.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove PIN',
          style: 'destructive',
          onPress: async () => {
            if (Platform.OS === 'web') {
              localStorage.removeItem(STORAGE_KEYS.PIN_HASH);
            } else {
              await SecureStore.deleteItemAsync(STORAGE_KEYS.PIN_HASH);
            }
            setHasPinSet(false);
            Alert.alert('Success', 'PIN has been removed');
          },
        },
      ]
    );
  };

  const handleDeleteAllData = () => {
    Alert.alert(
      'Delete All Data',
      'This will permanently delete all your local data including protocols, entries, and bottles. This cannot be undone.\n\nMake sure you have saved your recovery key if you want to restore your data later.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete All Data',
          style: 'destructive',
          onPress: async () => {
            try {
              // Clear all database data
              localStorageDB.clearAll();

              // Clear storage keys
              if (Platform.OS === 'web') {
                localStorage.removeItem(STORAGE_KEYS.RECOVERY_KEY);
                localStorage.removeItem(STORAGE_KEYS.ONBOARDING_COMPLETE);
                localStorage.removeItem(STORAGE_KEYS.HAS_OPTED_IN);
                localStorage.removeItem(STORAGE_KEYS.DEVICE_ID);
                localStorage.removeItem(STORAGE_KEYS.SALT);
                localStorage.removeItem(STORAGE_KEYS.PIN_HASH);
              } else {
                await SecureStore.deleteItemAsync(STORAGE_KEYS.RECOVERY_KEY);
                await SecureStore.deleteItemAsync(STORAGE_KEYS.ONBOARDING_COMPLETE);
                await SecureStore.deleteItemAsync(STORAGE_KEYS.HAS_OPTED_IN);
                await SecureStore.deleteItemAsync(STORAGE_KEYS.DEVICE_ID);
                await SecureStore.deleteItemAsync(STORAGE_KEYS.SALT);
                await SecureStore.deleteItemAsync(STORAGE_KEYS.PIN_HASH);
              }

              // Clear app store state
              setOptedIn(false);
              useAppStore.setState({
                activeProtocol: null,
                hasCompletedOnboarding: false,
                hasOptedIn: false,
                isLocked: false,
              });

              console.log('[Settings] All data deleted successfully');

              // Navigate to scan screen to start fresh
              router.replace('/scan');
            } catch (error) {
              console.error('[Settings] Error deleting data:', error);
              Alert.alert('Error', 'Failed to delete data. Please try again.');
            }
          },
        },
      ]
    );
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <Text style={styles.backText}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.title}>Settings</Text>
        <View style={styles.placeholder} />
      </View>

      <View style={styles.content}>
        {activeProtocol && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Current Protocol</Text>
            <View style={styles.card}>
              <Text style={styles.productName}>{activeProtocol.productName}</Text>
              <Text style={styles.protocolInfo}>
                Day {activeProtocol.currentDay} of {activeProtocol.totalDays}
              </Text>
            </View>
          </View>
        )}

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Privacy</Text>
          <View style={styles.settingRow}>
            <View style={styles.settingInfo}>
              <Text style={styles.settingLabel}>Contribute Anonymous Data</Text>
              <Text style={styles.settingDescription}>
                Help improve microdosing research with anonymous metrics
              </Text>
            </View>
            <Switch
              value={hasOptedIn}
              onValueChange={toggleOptIn}
              trackColor={{ false: '#27272a', true: '#8b5cf6' }}
              thumbColor="#ffffff"
            />
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Account</Text>
          <TouchableOpacity style={styles.menuItem} onPress={toggleRecoveryKey}>
            <Text style={styles.menuItemText}>
              {showKey ? 'Hide Recovery Key' : 'View Recovery Key'}
            </Text>
            <Text style={styles.menuItemArrow}>{showKey ? '▼' : '→'}</Text>
          </TouchableOpacity>
          {showKey && recoveryKey && (
            <View style={styles.keyCard}>
              <Text style={styles.keyLabel}>Your Recovery Key:</Text>
              <Text style={styles.keyText}>{recoveryKey}</Text>
              <Text style={styles.keyWarning}>
                Save this key securely. You'll need it to restore your data.
              </Text>
            </View>
          )}
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Security</Text>
          <TouchableOpacity style={styles.menuItem} onPress={handleLockJournal}>
            <Text style={styles.menuItemText}>Lock Journal Now</Text>
            <Text style={styles.menuItemArrow}>→</Text>
          </TouchableOpacity>
          {hasPinSet && (
            <TouchableOpacity style={[styles.menuItem, styles.menuItemSpaced]} onPress={handleRemovePin}>
              <Text style={styles.menuItemText}>Remove PIN</Text>
              <Text style={styles.menuItemArrow}>→</Text>
            </TouchableOpacity>
          )}
          <Text style={styles.lockInfo}>
            {hasPinSet
              ? 'Your journal is secured with a PIN. Lock it to prevent unauthorized access.'
              : 'Set up a PIN when you lock your journal for the first time.'}
          </Text>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Danger Zone</Text>
          <TouchableOpacity style={styles.dangerMenuItem} onPress={handleDeleteAllData}>
            <Text style={styles.dangerMenuItemText}>Delete All Data</Text>
            <Text style={styles.menuItemArrow}>→</Text>
          </TouchableOpacity>
          <Text style={styles.dangerWarning}>
            This will permanently delete all your local data. Make sure you have your recovery key saved.
          </Text>
        </View>

        <View style={styles.footer}>
          <Text style={styles.footerText}>Psilly Journal v1.0.0</Text>
          <Text style={styles.footerText}>Your data never leaves your device</Text>
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0a0a0a' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 20, paddingTop: 60, paddingBottom: 20 },
  backText: { color: '#8b5cf6', fontSize: 16 },
  title: { color: '#ffffff', fontSize: 18, fontWeight: '600' },
  placeholder: { width: 50 },
  content: { flex: 1, padding: 20 },
  section: { marginBottom: 32 },
  sectionTitle: { color: '#a1a1aa', fontSize: 12, fontWeight: '600', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 12 },
  card: { backgroundColor: '#18181b', borderRadius: 12, padding: 16 },
  productName: { color: '#ffffff', fontSize: 18, fontWeight: '600', marginBottom: 4 },
  protocolInfo: { color: '#a1a1aa', fontSize: 14 },
  settingRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#18181b', borderRadius: 12, padding: 16 },
  settingInfo: { flex: 1, marginRight: 16 },
  settingLabel: { color: '#ffffff', fontSize: 16, marginBottom: 4 },
  settingDescription: { color: '#a1a1aa', fontSize: 13 },
  menuItem: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#18181b', borderRadius: 12, padding: 16 },
  menuItemSpaced: { marginTop: 8 },
  menuItemText: { color: '#ffffff', fontSize: 16 },
  menuItemArrow: { color: '#a1a1aa', fontSize: 18 },
  keyCard: { backgroundColor: '#18181b', borderRadius: 12, padding: 20, marginTop: 12 },
  keyLabel: { color: '#a1a1aa', fontSize: 12, marginBottom: 8, textTransform: 'uppercase', letterSpacing: 1 },
  keyText: { color: '#8b5cf6', fontSize: 18, fontWeight: '600', fontFamily: 'monospace', letterSpacing: 2, marginBottom: 12 },
  keyWarning: { color: '#71717a', fontSize: 13, lineHeight: 18 },
  lockInfo: { color: '#71717a', fontSize: 12, marginTop: 8, lineHeight: 16 },
  dangerMenuItem: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#18181b', borderRadius: 12, padding: 16, borderWidth: 1, borderColor: '#ef444420' },
  dangerMenuItemText: { color: '#ef4444', fontSize: 16, fontWeight: '500' },
  dangerWarning: { color: '#71717a', fontSize: 12, marginTop: 8, lineHeight: 16 },
  footer: { marginTop: 'auto', alignItems: 'center', paddingVertical: 24 },
  footerText: { color: '#52525b', fontSize: 12, marginBottom: 4 },
});

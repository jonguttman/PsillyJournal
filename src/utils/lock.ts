import { Platform } from 'react-native';
import { STORAGE_KEYS } from '../config';

/**
 * Storage wrapper for PIN hash (web localStorage or SecureStore for native)
 */
const storage = {
  setItem: async (key: string, value: string) => {
    if (Platform.OS === 'web') {
      localStorage.setItem(key, value);
    } else {
      // For future native support
      const SecureStore = await import('expo-secure-store');
      await SecureStore.setItemAsync(key, value);
    }
  },
  getItem: async (key: string): Promise<string | null> => {
    if (Platform.OS === 'web') {
      return localStorage.getItem(key);
    } else {
      const SecureStore = await import('expo-secure-store');
      return SecureStore.getItemAsync(key);
    }
  },
  removeItem: async (key: string) => {
    if (Platform.OS === 'web') {
      localStorage.removeItem(key);
    } else {
      const SecureStore = await import('expo-secure-store');
      await SecureStore.deleteItemAsync(key);
    }
  },
};

/**
 * Hash a PIN using SHA-256 with device ID as salt
 */
export async function hashPin(pin: string): Promise<string> {
  // Get device ID to use as salt
  const deviceId = await storage.getItem(STORAGE_KEYS.DEVICE_ID) || 'default-device';

  // Combine PIN with device ID for salting
  const salted = `${pin}-${deviceId}`;

  // Convert to buffer
  const encoder = new TextEncoder();
  const data = encoder.encode(salted);

  // Hash using SHA-256
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);

  // Convert to hex string
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

  return hashHex;
}

/**
 * Verify a PIN against stored hash
 */
export async function verifyPin(pin: string): Promise<boolean> {
  const storedHash = await storage.getItem(STORAGE_KEYS.PIN_HASH);

  if (!storedHash) {
    // No PIN set yet
    return false;
  }

  const inputHash = await hashPin(pin);
  return inputHash === storedHash;
}

/**
 * Set a new PIN (creates hash and stores it)
 */
export async function setPin(pin: string): Promise<void> {
  const hash = await hashPin(pin);
  await storage.setItem(STORAGE_KEYS.PIN_HASH, hash);
}

/**
 * Check if PIN is set
 */
export async function isPinSet(): Promise<boolean> {
  const hash = await storage.getItem(STORAGE_KEYS.PIN_HASH);
  return hash !== null;
}

/**
 * Remove PIN (for testing or reset)
 */
export async function removePin(): Promise<void> {
  await storage.removeItem(STORAGE_KEYS.PIN_HASH);
}

/**
 * Change PIN (verifies old PIN first)
 */
export async function changePin(oldPin: string, newPin: string): Promise<boolean> {
  const isValid = await verifyPin(oldPin);

  if (!isValid) {
    return false;
  }

  await setPin(newPin);
  return true;
}

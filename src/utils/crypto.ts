import * as Crypto from 'expo-crypto';
import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';
import type { SessionId, QRToken } from '../types';

const DEVICE_ID_KEY = 'psilly_device_id';
const SALT_KEY = 'psilly_salt';

// Web fallback for SecureStore (which only works on native)
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

/**
 * Get or generate a unique device ID
 * Stored in SecureStore, persists across app reinstalls on same device
 */
export async function getDeviceId(): Promise<string> {
  let deviceId = await storage.getItem(DEVICE_ID_KEY);

  if (!deviceId) {
    // Generate new device ID
    deviceId = await Crypto.digestStringAsync(
      Crypto.CryptoDigestAlgorithm.SHA256,
      `device_${Date.now()}_${Math.random()}`
    );
    await storage.setItem(DEVICE_ID_KEY, deviceId);
  }

  return deviceId;
}

/**
 * Get or generate a salt for hashing
 */
async function getSalt(): Promise<string> {
  let salt = await storage.getItem(SALT_KEY);

  if (!salt) {
    salt = await Crypto.digestStringAsync(
      Crypto.CryptoDigestAlgorithm.SHA256,
      `salt_${Date.now()}_${Math.random()}_${Math.random()}`
    );
    await storage.setItem(SALT_KEY, salt);
  }

  return salt;
}

/**
 * Generate an anonymous session ID from bottle token and device ID
 * 
 * PRIVACY CRITICAL: This is a ONE-WAY hash. Given a session_id,
 * it is computationally infeasible to recover the bottle_token.
 * 
 * This ensures:
 * - Cloud data cannot be linked back to physical bottles
 * - Even with database access, users cannot be identified
 * - PsillyOps customer data stays completely separate from our analytics
 * 
 * @param bottleToken - The QR token from the bottle (stays local)
 * @returns SessionId that can be safely sent to cloud
 */
export async function generateSessionId(bottleToken: QRToken): Promise<SessionId> {
  const deviceId = await getDeviceId();
  const salt = await getSalt();

  // Combine inputs for hashing
  const input = `${bottleToken}:${deviceId}:${salt}`;

  // SHA-256 one-way hash
  const hash = await Crypto.digestStringAsync(
    Crypto.CryptoDigestAlgorithm.SHA256,
    input
  );

  // Return first 32 chars with prefix
  return `anon_${hash.substring(0, 32)}` as SessionId;
}

/**
 * Generate a recovery key for session restoration
 * 
 * Format: mj-XXXX-XXXX-XXXX-XXXX (24 chars total)
 * This allows users to restore their session on a new device.
 */
export async function generateRecoveryKey(): Promise<string> {
  const randomBytes = await Crypto.getRandomBytesAsync(16);
  
  // Convert to base58-like string (alphanumeric, no ambiguous chars)
  const alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  let key = '';
  
  for (const byte of randomBytes) {
    key += alphabet[byte % alphabet.length];
  }

  // Format as mj-XXXX-XXXX-XXXX-XXXX
  return `mj-${key.slice(0, 4)}-${key.slice(4, 8)}-${key.slice(8, 12)}-${key.slice(12, 16)}`;
}

/**
 * Hash sensitive data for storage
 */
export async function hashData(data: string): Promise<string> {
  return Crypto.digestStringAsync(Crypto.CryptoDigestAlgorithm.SHA256, data);
}

import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';

/**
 * Cross-platform storage wrapper
 *
 * Uses AsyncStorage on native (iOS/Android), localStorage on web
 *
 * CRITICAL: All methods are async to support AsyncStorage.
 * Any code calling these methods MUST use await.
 */
export const storage = {
  /**
   * Get item from storage
   */
  async getItem(key: string): Promise<string | null> {
    if (Platform.OS === 'web') {
      // Web: use localStorage (synchronous)
      return localStorage.getItem(key);
    }
    // Native: use AsyncStorage (asynchronous)
    return AsyncStorage.getItem(key);
  },

  /**
   * Set item in storage
   */
  async setItem(key: string, value: string): Promise<void> {
    if (Platform.OS === 'web') {
      localStorage.setItem(key, value);
      return;
    }
    await AsyncStorage.setItem(key, value);
  },

  /**
   * Remove item from storage
   */
  async removeItem(key: string): Promise<void> {
    if (Platform.OS === 'web') {
      localStorage.removeItem(key);
      return;
    }
    await AsyncStorage.removeItem(key);
  },

  /**
   * Clear all storage
   */
  async clear(): Promise<void> {
    if (Platform.OS === 'web') {
      localStorage.clear();
      return;
    }
    await AsyncStorage.clear();
  },

  /**
   * Get all keys
   */
  async getAllKeys(): Promise<readonly string[]> {
    if (Platform.OS === 'web') {
      return Object.keys(localStorage);
    }
    return AsyncStorage.getAllKeys();
  },
};

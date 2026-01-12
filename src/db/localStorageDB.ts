/**
 * Cross-platform async storage database
 * Uses AsyncStorage on native (iOS/Android), localStorage on web
 * All methods are async to support AsyncStorage
 */

import { storage } from '../utils/storage';

export interface StorageRecord {
  id: string;
  _createdAt: number;
  _updatedAt: number;
}

export interface Bottle extends StorageRecord {
  bottleToken: string;
  productId: string;
  productName: string;
  batchId?: string;
  firstScannedAt: number;
  lastScannedAt: number;
  scanCount: number;
}

export interface Protocol extends StorageRecord {
  bottleId: string;
  sessionId: string;
  productId: string;
  productName: string;
  startDate: number;
  status: 'active' | 'paused' | 'completed';
  scheduleType?: string;
  totalDays: number;
  currentDay: number;
}

export interface Entry extends StorageRecord {
  protocolId: string;
  doseId?: string;
  dayNumber: number;
  timestamp: number;
  content: string;
  energy: number;
  clarity: number;
  mood: number;
  anxiety?: number;
  creativity?: number;
  tags: string;
  isDoseDay: boolean;
  doseTimestamp?: number;
  contributionStatus: string;
  preDoseState?: string;
  postDoseMetrics?: string;
  contextActivity?: string;  // JSON array of tag IDs
  contextNotes?: string;      // Free text (50 char max)
  checkInCompleted?: boolean; // Check-in completion status
  reflectionPromptId?: string;   // ID of prompt shown
  reflectionPromptText?: string; // Text of prompt shown
}

// Add metrics getter helper for Entry
export function getEntryMetrics(entry: Entry): { energy: number; clarity: number; mood: number; anxiety?: number; creativity?: number } {
  return {
    energy: entry.energy,
    clarity: entry.clarity,
    mood: entry.mood,
    ...(entry.anxiety !== undefined && { anxiety: entry.anxiety }),
    ...(entry.creativity !== undefined && { creativity: entry.creativity }),
  };
}

export interface Dose extends StorageRecord {
  protocolId: string;
  bottleId: string;
  timestamp: number;
  dayNumber: number;
  notes?: string;
}

const STORAGE_KEYS = {
  BOTTLES: 'psilly_bottles',
  PROTOCOLS: 'psilly_protocols',
  ENTRIES: 'psilly_entries',
  DOSES: 'psilly_doses',
};

function generateId(): string {
  return Math.random().toString(36).substr(2, 16);
}

// Generic collection operations (all async for cross-platform support)
class Collection<T extends StorageRecord> {
  constructor(private key: string) {}

  async getAll(): Promise<T[]> {
    const data = await storage.getItem(this.key);
    return data ? JSON.parse(data) : [];
  }

  private async saveAll(items: T[]): Promise<void> {
    await storage.setItem(this.key, JSON.stringify(items));
  }

  async find(id: string): Promise<T | null> {
    const items = await this.getAll();
    return items.find(item => item.id === id) || null;
  }

  async query(filter: (item: T) => boolean): Promise<T[]> {
    const items = await this.getAll();
    return items.filter(filter);
  }

  async create(data: Omit<T, 'id' | '_createdAt' | '_updatedAt'>): Promise<T> {
    const items = await this.getAll();
    const now = Date.now();
    const newItem = {
      ...data,
      id: generateId(),
      _createdAt: now,
      _updatedAt: now,
    } as T;
    items.push(newItem);
    await this.saveAll(items);
    console.log(`[LocalStorageDB] Created ${this.key} record:`, newItem.id);
    return newItem;
  }

  async update(id: string, updates: Partial<T>): Promise<T | null> {
    const items = await this.getAll();
    const index = items.findIndex(item => item.id === id);
    if (index === -1) return null;

    items[index] = {
      ...items[index],
      ...updates,
      _updatedAt: Date.now(),
    };
    await this.saveAll(items);
    return items[index];
  }

  async delete(id: string): Promise<boolean> {
    const items = await this.getAll();
    const filtered = items.filter(item => item.id !== id);
    if (filtered.length === items.length) return false;
    await this.saveAll(filtered);
    return true;
  }

  async clear(): Promise<void> {
    await storage.removeItem(this.key);
  }
}

// Database instance
export const localStorageDB = {
  bottles: new Collection<Bottle>(STORAGE_KEYS.BOTTLES),
  protocols: new Collection<Protocol>(STORAGE_KEYS.PROTOCOLS),
  entries: new Collection<Entry>(STORAGE_KEYS.ENTRIES),
  doses: new Collection<Dose>(STORAGE_KEYS.DOSES),

  // Clear all data
  async clearAll() {
    console.log('[LocalStorageDB] Clearing all data');
    await this.bottles.clear();
    await this.protocols.clear();
    await this.entries.clear();
    await this.doses.clear();
  },
};

/**
 * Simple localStorage-based database for web
 * Replaces WatermelonDB/LokiJS which has persistence issues on web
 */

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

// Generic collection operations
class Collection<T extends StorageRecord> {
  constructor(private key: string) {}

  getAll(): T[] {
    const data = localStorage.getItem(this.key);
    return data ? JSON.parse(data) : [];
  }

  private saveAll(items: T[]): void {
    localStorage.setItem(this.key, JSON.stringify(items));
  }

  find(id: string): T | null {
    const items = this.getAll();
    return items.find(item => item.id === id) || null;
  }

  query(filter: (item: T) => boolean): T[] {
    return this.getAll().filter(filter);
  }

  create(data: Omit<T, 'id' | '_createdAt' | '_updatedAt'>): T {
    const items = this.getAll();
    const now = Date.now();
    const newItem = {
      ...data,
      id: generateId(),
      _createdAt: now,
      _updatedAt: now,
    } as T;
    items.push(newItem);
    this.saveAll(items);
    console.log(`[LocalStorageDB] Created ${this.key} record:`, newItem.id);
    return newItem;
  }

  update(id: string, updates: Partial<T>): T | null {
    const items = this.getAll();
    const index = items.findIndex(item => item.id === id);
    if (index === -1) return null;

    items[index] = {
      ...items[index],
      ...updates,
      _updatedAt: Date.now(),
    };
    this.saveAll(items);
    return items[index];
  }

  delete(id: string): boolean {
    const items = this.getAll();
    const filtered = items.filter(item => item.id !== id);
    if (filtered.length === items.length) return false;
    this.saveAll(filtered);
    return true;
  }

  clear(): void {
    localStorage.removeItem(this.key);
  }
}

// Database instance
export const localStorageDB = {
  bottles: new Collection<Bottle>(STORAGE_KEYS.BOTTLES),
  protocols: new Collection<Protocol>(STORAGE_KEYS.PROTOCOLS),
  entries: new Collection<Entry>(STORAGE_KEYS.ENTRIES),
  doses: new Collection<Dose>(STORAGE_KEYS.DOSES),

  // Clear all data
  clearAll() {
    console.log('[LocalStorageDB] Clearing all data');
    this.bottles.clear();
    this.protocols.clear();
    this.entries.clear();
    this.doses.clear();
  },
};

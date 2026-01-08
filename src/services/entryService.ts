import { localStorageDB, type Entry } from '../db/localStorageDB';
import type { ReflectionMetrics } from '../types';

/**
 * Create a new journal entry
 */
export async function createEntry(params: {
  protocolId: string;
  dayNumber: number;
  content: string;
  metrics: ReflectionMetrics;
  isDoseDay: boolean;
  tags?: string[];
}): Promise<Entry> {
  const entry = localStorageDB.entries.create({
    protocolId: params.protocolId,
    dayNumber: params.dayNumber,
    content: params.content,
    energy: params.metrics.energy,
    clarity: params.metrics.clarity,
    mood: params.metrics.mood,
    isDoseDay: params.isDoseDay,
    tags: JSON.stringify(params.tags || []),
    timestamp: Date.now(),
    contributionStatus: 'pending',
  });

  return entry;
}

/**
 * Get all entries for a protocol, newest first
 */
export async function getEntriesForProtocol(protocolId: string): Promise<Entry[]> {
  const entries = localStorageDB.entries.query(e => e.protocolId === protocolId);
  return entries.sort((a, b) => b.timestamp - a.timestamp);
}

/**
 * Get a single entry by ID
 */
export async function getEntryById(entryId: string): Promise<Entry | null> {
  return localStorageDB.entries.find(entryId);
}

/**
 * Update an existing entry
 */
export async function updateEntry(
  entryId: string,
  updates: {
    content?: string;
    metrics?: ReflectionMetrics;
    tags?: string[];
  }
): Promise<Entry | null> {
  const updateData: Partial<Entry> = {};

  if (updates.content !== undefined) updateData.content = updates.content;
  if (updates.metrics !== undefined) {
    updateData.energy = updates.metrics.energy;
    updateData.clarity = updates.metrics.clarity;
    updateData.mood = updates.metrics.mood;
  }
  if (updates.tags !== undefined) updateData.tags = JSON.stringify(updates.tags);

  return localStorageDB.entries.update(entryId, updateData);
}

/**
 * Delete an entry
 */
export async function deleteEntry(entryId: string): Promise<void> {
  localStorageDB.entries.delete(entryId);
}

/**
 * Get entries for today
 */
export async function getEntriesToday(protocolId: string): Promise<Entry[]> {
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);

  const entries = await getEntriesForProtocol(protocolId);
  return entries.filter((e) => e.timestamp >= startOfDay.getTime());
}

/**
 * Get recent entries (last N)
 */
export async function getRecentEntries(protocolId: string, limit = 5): Promise<Entry[]> {
  const entries = await getEntriesForProtocol(protocolId);
  return entries.slice(0, limit);
}

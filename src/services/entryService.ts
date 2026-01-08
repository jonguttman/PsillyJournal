import { Q } from '@nozbe/watermelondb';
import database from '../db';
import type Entry from '../db/models/Entry';
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
  const entry = await database.write(async () => {
    return database.get<Entry>('entries').create((e) => {
      e.protocolId = params.protocolId;
      e.dayNumber = params.dayNumber;
      e.content = params.content;
      e.metrics = JSON.stringify(params.metrics);
      e.isDoseDay = params.isDoseDay;
      e.tags = JSON.stringify(params.tags || []);
      e.timestamp = Date.now();
    });
  });

  return entry;
}

/**
 * Get all entries for a protocol, newest first
 */
export async function getEntriesForProtocol(protocolId: string): Promise<Entry[]> {
  const entries = await database
    .get<Entry>('entries')
    .query(Q.where('protocol_id', protocolId))
    .fetch();

  return entries.sort((a, b) => b.timestamp - a.timestamp);
}

/**
 * Get a single entry by ID
 */
export async function getEntryById(entryId: string): Promise<Entry | null> {
  try {
    return await database.get<Entry>('entries').find(entryId);
  } catch {
    return null;
  }
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
): Promise<Entry> {
  const entry = await database.get<Entry>('entries').find(entryId);

  await database.write(async () => {
    await entry.update((e) => {
      if (updates.content !== undefined) e.content = updates.content;
      if (updates.metrics !== undefined) e.metrics = JSON.stringify(updates.metrics);
      if (updates.tags !== undefined) e.tags = JSON.stringify(updates.tags);
    });
  });

  return entry;
}

/**
 * Delete an entry
 */
export async function deleteEntry(entryId: string): Promise<void> {
  await database.write(async () => {
    const entry = await database.get<Entry>('entries').find(entryId);
    await entry.destroyPermanently();
  });
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

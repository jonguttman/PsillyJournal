import { localStorageDB, type Entry } from '../db/localStorageDB';
import type { ReflectionMetrics } from '../types';

/**
 * Post-dose metrics (0-10 scale)
 */
export interface PostDoseMetrics {
  energy: number;   // 0-10: depleted ↔ vibrant
  clarity: number;  // 0-10: foggy ↔ crystal clear
  mood: number;     // 0-10: heavy ↔ light
}

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
 * Create a check-in entry linked to a dose
 * Called after pre-dose check-in (or skip)
 */
export async function createCheckInEntry(params: {
  protocolId: string;
  doseId: string;
  dayNumber: number;
  preDoseState: string | null;  // null if skipped
  doseTimestamp: number;
}): Promise<Entry> {
  const entry = localStorageDB.entries.create({
    protocolId: params.protocolId,
    doseId: params.doseId,
    dayNumber: params.dayNumber,
    content: '',  // Will be filled if user adds journal note
    energy: 3,    // Default values
    clarity: 3,
    mood: 3,
    isDoseDay: true,
    doseTimestamp: params.doseTimestamp,
    tags: JSON.stringify([]),
    timestamp: Date.now(),
    contributionStatus: 'pending',
    preDoseState: params.preDoseState ?? undefined,
  });

  return entry;
}

/**
 * Update entry with post-dose metrics
 * Called from post-dose check-in screen
 */
export async function updatePostDoseMetrics(
  entryId: string,
  metrics: PostDoseMetrics,
  notes?: string
): Promise<Entry | null> {
  const updateData: Partial<Entry> = {
    postDoseMetrics: JSON.stringify(metrics),
  };

  if (notes !== undefined && notes.trim().length > 0) {
    // Append notes to existing content, or set as content
    const existing = localStorageDB.entries.find(entryId);
    if (existing) {
      updateData.content = existing.content 
        ? `${existing.content}\n\n[Post-dose notes]\n${notes.trim()}`
        : notes.trim();
    }
  }

  return localStorageDB.entries.update(entryId, updateData);
}

/**
 * Find entry by dose ID
 */
export async function getEntryByDoseId(doseId: string): Promise<Entry | null> {
  const entries = localStorageDB.entries.query(e => e.doseId === doseId);
  return entries.length > 0 ? entries[0] : null;
}

/**
 * Check if dose is within 24h window for post-check-in
 */
export function isDoseWithin24Hours(doseTimestamp: number): boolean {
  const twentyFourHours = 24 * 60 * 60 * 1000;
  return Date.now() - doseTimestamp < twentyFourHours;
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

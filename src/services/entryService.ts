import database from '../db';
import { Entry } from '../db/models';

/**
 * Data required to create a new journal entry
 */
export interface CreateEntryData {
  protocolId: string;
  dayNumber: number;
  content: string;
  energy: number;
  clarity: number;
  mood: number;
  anxiety?: number;
  creativity?: number;
  tags?: string[];
  isDoseDay?: boolean;
  doseId?: string;
  doseTimestamp?: number;
  preDoseState?: string;
  postDoseMetrics?: {
    energy: number;
    clarity: number;
    mood: number;
  };
}

/**
 * Create a new journal entry
 *
 * Saves entry with metrics and content to local database.
 * Content is stored locally only and never synced to cloud.
 * Metrics may be synced anonymously if user has opted in.
 *
 * @param data - Entry data including metrics and content
 * @returns The created Entry record
 */
export async function createEntry(data: CreateEntryData): Promise<Entry> {
  const entry = await database.write(async () => {
    const newEntry = await database.get<Entry>('entries').create((e) => {
      e.protocolId = data.protocolId;
      e.dayNumber = data.dayNumber;
      e.timestamp = Date.now();
      e.content = data.content;
      e.energy = data.energy;
      e.clarity = data.clarity;
      e.mood = data.mood;
      e.tags = JSON.stringify(data.tags || []);
      e.isDoseDay = data.isDoseDay || false;
      e.contributionStatus = 'pending';

      // Optional fields
      if (data.anxiety !== undefined) e.anxiety = data.anxiety;
      if (data.creativity !== undefined) e.creativity = data.creativity;
      if (data.doseId) e.doseId = data.doseId;
      if (data.doseTimestamp) e.doseTimestamp = data.doseTimestamp;
      if (data.preDoseState) e.preDoseState = data.preDoseState;
    });

    return newEntry;
  });

  console.log(`[EntryService] Created entry for day ${data.dayNumber}`);
  return entry;
}

/**
 * Get all entries for a protocol
 */
export async function getEntriesForProtocol(protocolId: string): Promise<Entry[]> {
  const { Q } = await import('@nozbe/watermelondb');
  return database
    .get<Entry>('entries')
    .query(
      Q.where('protocol_id', protocolId),
      Q.sortBy('timestamp', Q.desc)
    )
    .fetch();
}

/**
 * Get entry for a specific day in a protocol
 */
export async function getEntryForDay(
  protocolId: string,
  dayNumber: number
): Promise<Entry | null> {
  const { Q } = await import('@nozbe/watermelondb');
  const entries = await database
    .get<Entry>('entries')
    .query(
      Q.where('protocol_id', protocolId),
      Q.where('day_number', dayNumber),
      Q.take(1)
    )
    .fetch();

  return entries.length > 0 ? entries[0] : null;
}

/**
 * Update an existing entry
 */
export async function updateEntry(
  entryId: string,
  updates: Partial<CreateEntryData>
): Promise<Entry> {
  const entry = await database.get<Entry>('entries').find(entryId);

  await entry.update((e) => {
    if (updates.content !== undefined) e.content = updates.content;
    if (updates.energy !== undefined) e.energy = updates.energy;
    if (updates.clarity !== undefined) e.clarity = updates.clarity;
    if (updates.mood !== undefined) e.mood = updates.mood;
    if (updates.anxiety !== undefined) e.anxiety = updates.anxiety;
    if (updates.creativity !== undefined) e.creativity = updates.creativity;
    if (updates.tags !== undefined) e.tags = JSON.stringify(updates.tags);
    if (updates.preDoseState !== undefined) e.preDoseState = updates.preDoseState;
  });

  return entry;
}

/**
 * Delete an entry
 */
export async function deleteEntry(entryId: string): Promise<void> {
  const entry = await database.get<Entry>('entries').find(entryId);
  await database.write(async () => {
    await entry.markAsDeleted();
  });
}

import { Q } from '@nozbe/watermelondb';
import database from '../db';
import type Dose from '../db/models/Dose';
import type Protocol from '../db/models/Protocol';

/**
 * Get the start of today (midnight) in milliseconds
 */
function getStartOfToday(): number {
  const now = new Date();
  now.setHours(0, 0, 0, 0);
  return now.getTime();
}

/**
 * Get doses logged today for a protocol
 */
export async function getDosesToday(protocolId: string): Promise<Dose[]> {
  const startOfDay = getStartOfToday();

  const doses = await database
    .get<Dose>('doses')
    .query(
      Q.where('protocol_id', protocolId),
      Q.where('timestamp', Q.gte(startOfDay))
    )
    .fetch();

  return doses;
}

/**
 * Log a dose for the active protocol
 */
export async function logDose(protocol: Protocol): Promise<Dose> {
  const timestamp = Date.now();

  const dose = await database.write(async () => {
    const newDose = await database.get<Dose>('doses').create((d) => {
      d.protocolId = protocol.id;
      d.bottleId = protocol.bottleId;
      d.timestamp = timestamp;
      d.dayNumber = protocol.currentDay;
    });

    return newDose;
  });

  return dose;
}

/**
 * Delete a dose (for undo functionality)
 */
export async function deleteDose(doseId: string): Promise<void> {
  await database.write(async () => {
    const dose = await database.get<Dose>('doses').find(doseId);
    await dose.destroyPermanently();
  });
}

/**
 * Get the count of doses logged today
 */
export async function getDoseCountToday(protocolId: string): Promise<number> {
  const doses = await getDosesToday(protocolId);
  return doses.length;
}

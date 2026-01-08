import { localStorageDB, type Dose, type Protocol } from '../db/localStorageDB';

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
  const doses = localStorageDB.doses.query(
    d => d.protocolId === protocolId && d.timestamp >= startOfDay
  );
  return doses;
}

/**
 * Log a dose for the active protocol
 */
export async function logDose(protocol: Protocol): Promise<Dose> {
  const timestamp = Date.now();

  const dose = localStorageDB.doses.create({
    protocolId: protocol.id,
    bottleId: protocol.bottleId,
    timestamp: timestamp,
    dayNumber: protocol.currentDay,
  });

  return dose;
}

/**
 * Delete a dose (for undo functionality)
 */
export async function deleteDose(doseId: string): Promise<void> {
  localStorageDB.doses.delete(doseId);
}

/**
 * Get the count of doses logged today
 */
export async function getDoseCountToday(protocolId: string): Promise<number> {
  const doses = await getDosesToday(protocolId);
  return doses.length;
}

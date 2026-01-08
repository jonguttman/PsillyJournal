import { localStorageDB, type Bottle, type Protocol, type Dose } from '../db/localStorageDB';
import { fetchProductInfo } from './productApi';
import { generateSessionId } from '../utils/crypto';
import { PROTOCOL_DEFAULTS } from '../config';
import type { QRToken, ProductInfo } from '../types';

/**
 * Result of handling a QR scan
 */
export interface ScanHandlerResult {
  type: 'known_bottle' | 'new_bottle' | 'product_switch' | 'error';
  bottle?: Bottle;
  protocol?: Protocol;
  productInfo?: ProductInfo;
  error?: string;
}

/**
 * Handle a scanned QR token
 * 
 * This is the main entry point after QR scanner extracts a token.
 * Determines if bottle is known or new, and handles accordingly.
 * 
 * CRITICAL: This function does NOT open any URLs or browsers.
 */
export async function handleScannedToken(token: QRToken): Promise<ScanHandlerResult> {
  try {
    console.log('[BottleService] Handling scanned token:', token);

    // 1. Check if bottle exists in local database
    const existingBottles = localStorageDB.bottles.query(b => b.bottleToken === token);

    console.log('[BottleService] Query result:', existingBottles.length, 'bottles found');

    if (existingBottles.length > 0) {
      console.log('[BottleService] Known bottle found:', existingBottles[0].id);
      // Known bottle - handle dose logging
      return handleKnownBottle(existingBottles[0]);
    } else {
      console.log('[BottleService] New bottle - fetching product info');
      // New bottle - fetch product info and prompt
      return handleNewBottle(token);
    }
  } catch (error) {
    console.error('[BottleService] Error handling token:', error);
    return {
      type: 'error',
      error: 'Failed to process QR code. Please try again.',
    };
  }
}

/**
 * Handle a known bottle (already in database)
 */
async function handleKnownBottle(bottle: Bottle): Promise<ScanHandlerResult> {
  try {
    // Record the scan
    localStorageDB.bottles.update(bottle.id, {
      lastScannedAt: Date.now(),
      scanCount: bottle.scanCount + 1,
    });

    // Get active protocol for this bottle
    const protocols = localStorageDB.protocols.query(
      p => p.bottleId === bottle.id && p.status === 'active'
    );

    if (protocols.length > 0) {
      return {
        type: 'known_bottle',
        bottle,
        protocol: protocols[0],
      };
    }

    // No active protocol - might need to start new one
    return {
      type: 'known_bottle',
      bottle,
    };
  } catch (error) {
    console.error('[BottleService] Error handling known bottle:', error);
    return {
      type: 'error',
      error: 'Failed to load bottle data.',
    };
  }
}

/**
 * Handle a new bottle (not in database)
 */
async function handleNewBottle(token: QRToken): Promise<ScanHandlerResult> {
  try {
    // Fetch product info from PsillyOps API
    const productInfo = await fetchProductInfo(token);

    if (!productInfo) {
      return {
        type: 'error',
        error: 'Unable to verify product. Please try again.',
      };
    }

    // Check for existing active protocols
    const activeProtocols = localStorageDB.protocols.query(p => p.status === 'active');

    if (activeProtocols.length > 0) {
      // User has existing protocol - this is a product switch
      return {
        type: 'product_switch',
        productInfo,
        protocol: activeProtocols[0],
      };
    }

    // First protocol - proceed with onboarding
    return {
      type: 'new_bottle',
      productInfo,
    };
  } catch (error) {
    console.error('[BottleService] Error handling new bottle:', error);
    return {
      type: 'error',
      error: 'Failed to verify product.',
    };
  }
}

/**
 * Create a new bottle and protocol
 * 
 * Called after user confirms starting a new protocol
 */
export async function createBottleAndProtocol(
  token: QRToken,
  productInfo: ProductInfo
): Promise<{ bottle: Bottle; protocol: Protocol }> {
  console.log('[BottleService] Creating bottle and protocol for token:', token);

  // Generate anonymous session ID
  const sessionId = await generateSessionId(token);

  // Create bottle record
  const bottle = localStorageDB.bottles.create({
    bottleToken: token,
    productId: productInfo.product_id,
    productName: productInfo.name,
    batchId: productInfo.batch_id ?? undefined,
    firstScannedAt: Date.now(),
    lastScannedAt: Date.now(),
    scanCount: 1,
  });

  console.log('[BottleService] Bottle created:', bottle.id, 'with token:', bottle.bottleToken);

  // Create protocol record
  const protocol = localStorageDB.protocols.create({
    bottleId: bottle.id,
    sessionId: sessionId,
    productId: productInfo.product_id,
    productName: productInfo.name,
    startDate: Date.now(),
    status: 'active',
    scheduleType: PROTOCOL_DEFAULTS.SCHEDULE,
    totalDays: PROTOCOL_DEFAULTS.DURATION_DAYS,
    currentDay: 1,
  });

  console.log('[BottleService] Protocol created:', protocol.id);

  return { bottle, protocol };
}

/**
 * Switch to a new product (creates new protocol, preserves old)
 */
export async function switchProduct(
  token: QRToken,
  productInfo: ProductInfo,
  currentProtocol: Protocol
): Promise<{ bottle: Bottle; protocol: Protocol }> {
  // Generate new session ID for new protocol
  const sessionId = await generateSessionId(token);

  // Pause current protocol (don't delete - preserve history)
  localStorageDB.protocols.update(currentProtocol.id, { status: 'paused' });

  // Create new bottle record
  const bottle = localStorageDB.bottles.create({
    bottleToken: token,
    productId: productInfo.product_id,
    productName: productInfo.name,
    batchId: productInfo.batch_id ?? undefined,
    firstScannedAt: Date.now(),
    lastScannedAt: Date.now(),
    scanCount: 1,
  });

  // Create new protocol
  const protocol = localStorageDB.protocols.create({
    bottleId: bottle.id,
    sessionId: sessionId,
    productId: productInfo.product_id,
    productName: productInfo.name,
    startDate: Date.now(),
    status: 'active',
    scheduleType: PROTOCOL_DEFAULTS.SCHEDULE,
    totalDays: PROTOCOL_DEFAULTS.DURATION_DAYS,
    currentDay: 1,
  });

  return { bottle, protocol };
}

/**
 * Get the currently active protocol
 */
export async function getActiveProtocol(): Promise<Protocol | null> {
  const protocols = localStorageDB.protocols.query(p => p.status === 'active');
  return protocols.length > 0 ? protocols[0] : null;
}

/**
 * Get all protocols (for history view)
 */
export async function getAllProtocols(): Promise<Protocol[]> {
  const protocols = localStorageDB.protocols.getAll();
  return protocols.sort((a, b) => b.startDate - a.startDate);
}

/**
 * Log a dose for a bottle/protocol
 *
 * Creates a new Dose record with timestamp and day number.
 * Returns the created dose for linking to check-in entry.
 *
 * @param bottleId - ID of the bottle being used
 * @param protocolId - ID of the active protocol
 * @returns The created Dose record
 */
export async function logDose(bottleId: string, protocolId: string): Promise<Dose> {
  const protocol = localStorageDB.protocols.find(protocolId);
  if (!protocol) throw new Error('Protocol not found');

  const dose = localStorageDB.doses.create({
    protocolId: protocolId,
    bottleId: bottleId,
    timestamp: Date.now(),
    dayNumber: protocol.currentDay,
  });

  console.log(`[BottleService] Logged dose for day ${protocol.currentDay}`);
  return dose;
}

/**
 * Get doses for a protocol
 */
export async function getDosesForProtocol(protocolId: string): Promise<Dose[]> {
  const doses = localStorageDB.doses.query(d => d.protocolId === protocolId);
  return doses.sort((a, b) => b.timestamp - a.timestamp);
}

/**
 * Get the most recent dose for a protocol
 */
export async function getLatestDose(protocolId: string): Promise<Dose | null> {
  const doses = await getDosesForProtocol(protocolId);
  return doses.length > 0 ? doses[0] : null;
}

import { Q } from '@nozbe/watermelondb';
import database from '../db';
import { Bottle, Protocol, Dose } from '../db/models';
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
    const existingBottle = await database
      .get<Bottle>('bottles')
      .query(Q.where('bottle_token', token))
      .fetch();

    console.log('[BottleService] Query result:', existingBottle.length, 'bottles found');

    if (existingBottle.length > 0) {
      console.log('[BottleService] Known bottle found:', existingBottle[0].id);
      // Known bottle - handle dose logging
      return handleKnownBottle(existingBottle[0]);
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
    await bottle.recordScan();

    // Get active protocol for this bottle
    const protocols = await database
      .get<Protocol>('protocols')
      .query(
        Q.where('bottle_id', bottle.id),
        Q.where('status', 'active')
      )
      .fetch();

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
    const activeProtocols = await database
      .get<Protocol>('protocols')
      .query(Q.where('status', 'active'))
      .fetch();

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

  const result = await database.write(async () => {
    // Create bottle record
    const bottle = await database.get<Bottle>('bottles').create((b) => {
      b.bottleToken = token;
      b.productId = productInfo.product_id;
      b.productName = productInfo.name;
      b.batchId = productInfo.batch_id ?? undefined;
      b.firstScannedAt = Date.now();
      b.lastScannedAt = Date.now();
      b.scanCount = 1;
    });

    console.log('[BottleService] Bottle created:', bottle.id, 'with token:', bottle.bottleToken);

    // Create protocol record
    const protocol = await database.get<Protocol>('protocols').create((p) => {
      p.bottleId = bottle.id;
      p.sessionId = sessionId;
      p.productId = productInfo.product_id;
      p.productName = productInfo.name;
      p.startDate = Date.now();
      p.status = 'active';
      p.scheduleType = PROTOCOL_DEFAULTS.SCHEDULE;
      p.totalDays = PROTOCOL_DEFAULTS.DURATION_DAYS;
      p.currentDay = 1;
    });

    console.log('[BottleService] Protocol created:', protocol.id);

    return { bottle, protocol };
  });

  return result;
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

  const result = await database.write(async () => {
    // Pause current protocol (don't delete - preserve history)
    await currentProtocol.pause();

    // Create new bottle record
    const bottle = await database.get<Bottle>('bottles').create((b) => {
      b.bottleToken = token;
      b.productId = productInfo.product_id;
      b.productName = productInfo.name;
      b.batchId = productInfo.batch_id ?? undefined;
      b.firstScannedAt = Date.now();
      b.lastScannedAt = Date.now();
      b.scanCount = 1;
    });

    // Create new protocol
    const protocol = await database.get<Protocol>('protocols').create((p) => {
      p.bottleId = bottle.id;
      p.sessionId = sessionId;
      p.productId = productInfo.product_id;
      p.productName = productInfo.name;
      p.startDate = Date.now();
      p.status = 'active';
      p.scheduleType = PROTOCOL_DEFAULTS.SCHEDULE;
      p.totalDays = PROTOCOL_DEFAULTS.DURATION_DAYS;
      p.currentDay = 1;
    });

    return { bottle, protocol };
  });

  return result;
}

/**
 * Get the currently active protocol
 */
export async function getActiveProtocol(): Promise<Protocol | null> {
  const protocols = await database
    .get<Protocol>('protocols')
    .query(Q.where('status', 'active'))
    .fetch();

  return protocols.length > 0 ? protocols[0] : null;
}

/**
 * Get all protocols (for history view)
 */
export async function getAllProtocols(): Promise<Protocol[]> {
  return database
    .get<Protocol>('protocols')
    .query(Q.sortBy('start_date', Q.desc))
    .fetch();
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
  const protocol = await database.get<Protocol>('protocols').find(protocolId);
  
  const dose = await database.write(async () => {
    const newDose = await database.get<Dose>('doses').create((d) => {
      d.protocolId = protocolId;
      d.bottleId = bottleId;
      d.timestamp = Date.now();
      d.dayNumber = protocol.currentDay;
    });

    return newDose;
  });

  console.log(`[BottleService] Logged dose for day ${protocol.currentDay}`);
  return dose;
}

/**
 * Get doses for a protocol
 */
export async function getDosesForProtocol(protocolId: string): Promise<Dose[]> {
  return database
    .get<Dose>('doses')
    .query(
      Q.where('protocol_id', protocolId),
      Q.sortBy('timestamp', Q.desc)
    )
    .fetch();
}

/**
 * Get the most recent dose for a protocol
 */
export async function getLatestDose(protocolId: string): Promise<Dose | null> {
  const doses = await database
    .get<Dose>('doses')
    .query(
      Q.where('protocol_id', protocolId),
      Q.sortBy('timestamp', Q.desc),
      Q.take(1)
    )
    .fetch();

  return doses.length > 0 ? doses[0] : null;
}

import { Model } from '@nozbe/watermelondb';
import { field, date, children, readonly } from '@nozbe/watermelondb/decorators';
import type { Query } from '@nozbe/watermelondb';
import type Protocol from './Protocol';

/**
 * Bottle model - represents a physical PsillyOps bottle
 * 
 * PRIVACY NOTE: bottle_token is stored locally ONLY and NEVER transmitted to cloud.
 * This is the link between physical product and user - keeping it local
 * ensures we cannot identify users even if we wanted to.
 */
export default class Bottle extends Model {
  static table = 'bottles';

  static associations = {
    protocols: { type: 'has_many' as const, foreignKey: 'bottle_id' },
    doses: { type: 'has_many' as const, foreignKey: 'bottle_id' },
  };

  // QR token from PsillyOps (e.g., qr_yGg4unBIVbsr7ezUs40UKb)
  // ⚠️ LOCAL ONLY - Never include in API payloads
  @field('bottle_token') bottleToken!: string;

  // Product identifier (safe to sync)
  @field('product_id') productId!: string;

  // Human-readable product name
  @field('product_name') productName!: string;

  // Batch tracking (optional)
  @field('batch_id') batchId?: string;

  // Timestamps
  @field('first_scanned_at') firstScannedAt!: number;
  @field('last_scanned_at') lastScannedAt!: number;

  // Usage tracking
  @field('scan_count') scanCount!: number;

  // Relations
  @children('protocols') protocols!: Query<Protocol>;

  /**
   * Record a new scan of this bottle
   */
  async recordScan(): Promise<void> {
    await this.update((bottle) => {
      bottle.lastScannedAt = Date.now();
      bottle.scanCount += 1;
    });
  }
}

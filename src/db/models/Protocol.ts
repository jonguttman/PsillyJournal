import { Model } from '@nozbe/watermelondb';
import { field, relation, children } from '@nozbe/watermelondb/decorators';
import type { Query, Relation } from '@nozbe/watermelondb';
import type Bottle from './Bottle';
import type Entry from './Entry';
import type Dose from './Dose';

export type ProtocolStatus = 'active' | 'paused' | 'completed';
export type ScheduleType = '1-on-1-off' | '1-on-2-off' | '3x-week' | '4-on-3-off' | 'custom';

/**
 * Protocol model - represents a journaling protocol tied to a bottle
 * 
 * session_id is an anonymized hash that CAN be sent to cloud.
 * It cannot be reversed to identify the user or bottle.
 */
export default class Protocol extends Model {
  static table = 'protocols';

  static associations = {
    bottles: { type: 'belongs_to' as const, key: 'bottle_id' },
    entries: { type: 'has_many' as const, foreignKey: 'protocol_id' },
    doses: { type: 'has_many' as const, foreignKey: 'protocol_id' },
  };

  // Foreign key to bottle
  @field('bottle_id') bottleId!: string;

  // Anonymized session ID (safe to sync)
  // Format: anon_[32 hex chars] - one-way hash of bottle_token + device_id
  @field('session_id') sessionId!: string;

  // Product info (safe to sync)
  @field('product_id') productId!: string;
  @field('product_name') productName!: string;

  // Protocol timing
  @field('start_date') startDate!: number;
  @field('status') status!: ProtocolStatus;
  @field('schedule_type') scheduleType?: ScheduleType;

  // Progress tracking
  @field('total_days') totalDays!: number;
  @field('current_day') currentDay!: number;

  // Relations
  @relation('bottles', 'bottle_id') bottle!: Relation<Bottle>;
  @children('entries') entries!: Query<Entry>;
  @children('doses') doses!: Query<Dose>;

  /**
   * Check if this is the active protocol
   */
  get isActive(): boolean {
    return this.status === 'active';
  }

  /**
   * Calculate days since protocol started
   */
  get daysSinceStart(): number {
    const msPerDay = 24 * 60 * 60 * 1000;
    return Math.floor((Date.now() - this.startDate) / msPerDay);
  }

  /**
   * Get progress percentage
   */
  get progressPercent(): number {
    return Math.min(100, Math.round((this.currentDay / this.totalDays) * 100));
  }

  /**
   * Pause the protocol
   */
  async pause(): Promise<void> {
    await this.update((protocol) => {
      protocol.status = 'paused';
    });
  }

  /**
   * Resume the protocol
   */
  async resume(): Promise<void> {
    await this.update((protocol) => {
      protocol.status = 'active';
    });
  }

  /**
   * Complete the protocol
   */
  async complete(): Promise<void> {
    await this.update((protocol) => {
      protocol.status = 'completed';
    });
  }

  /**
   * Advance to next day
   */
  async advanceDay(): Promise<void> {
    await this.update((protocol) => {
      protocol.currentDay = Math.min(protocol.currentDay + 1, protocol.totalDays);
      if (protocol.currentDay >= protocol.totalDays) {
        protocol.status = 'completed';
      }
    });
  }
}

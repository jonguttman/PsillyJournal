import { Model } from '@nozbe/watermelondb';
import { field, relation } from '@nozbe/watermelondb/decorators';
import type { Relation } from '@nozbe/watermelondb';
import type Protocol from './Protocol';
import type Bottle from './Bottle';

/**
 * Dose model - tracks individual dose events
 * 
 * Timestamps can be synced (anonymous), but notes are LOCAL ONLY.
 */
export default class Dose extends Model {
  static table = 'doses';

  static associations = {
    protocols: { type: 'belongs_to' as const, key: 'protocol_id' },
    bottles: { type: 'belongs_to' as const, key: 'bottle_id' },
  };

  // Foreign keys
  @field('protocol_id') protocolId!: string;
  @field('bottle_id') bottleId!: string;

  // When dose was taken
  @field('timestamp') timestamp!: number;

  // Day within protocol
  @field('day_number') dayNumber!: number;

  // ⚠️ LOCAL ONLY - Never sync
  @field('notes') notes?: string;

  // Relations
  @relation('protocols', 'protocol_id') protocol!: Relation<Protocol>;
  @relation('bottles', 'bottle_id') bottle!: Relation<Bottle>;

  /**
   * Format timestamp for display
   */
  get formattedTime(): string {
    return new Date(this.timestamp).toLocaleTimeString([], {
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  /**
   * Format date for display
   */
  get formattedDate(): string {
    return new Date(this.timestamp).toLocaleDateString();
  }
}

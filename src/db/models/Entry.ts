import { Model } from '@nozbe/watermelondb';
import { field, relation, json } from '@nozbe/watermelondb/decorators';
import type { Relation } from '@nozbe/watermelondb';
import type Protocol from './Protocol';
import type Dose from './Dose';
import type { SyncStatus } from '../../types';

export type EntrySyncStatus = SyncStatus;

/**
 * Post-dose metrics captured 4+ hours after dosing
 */
export interface PostDoseMetrics {
  energy: number;   // 1-10: depleted ↔ vibrant
  clarity: number;  // 1-10: foggy ↔ crystal
  mood: number;     // 1-10: heavy ↔ light
}

/**
 * Entry model - journal entries
 * 
 * PRIVACY NOTE: The 'content' field contains free-form text and is
 * NEVER transmitted to the cloud. Only anonymized metrics (energy,
 * clarity, mood) are synced if user has opted in.
 */
export default class Entry extends Model {
  static table = 'entries';

  static associations = {
    protocols: { type: 'belongs_to' as const, key: 'protocol_id' },
    doses: { type: 'belongs_to' as const, key: 'dose_id' },
  };

  // Foreign key to protocol
  @field('protocol_id') protocolId!: string;

  // Foreign key to dose (optional - links check-in entries to specific dose)
  @field('dose_id') doseId?: string;

  // Day within protocol (1-30 typically)
  @field('day_number') dayNumber!: number;

  // When entry was created
  @field('timestamp') timestamp!: number;

  // ⚠️ FREE-FORM TEXT - LOCAL ONLY - Never sync to cloud
  @field('content') content!: string;

  // Metrics (1-5 scale) - can be synced if opted in
  @field('energy') energy!: number;
  @field('clarity') clarity!: number;
  @field('mood') mood!: number;
  @field('anxiety') anxiety?: number;
  @field('creativity') creativity?: number;

  // Tags as JSON string array
  @field('tags') tags!: string;

  // Dose tracking
  @field('is_dose_day') isDoseDay!: boolean;
  @field('dose_timestamp') doseTimestamp?: number;

  // Contribution sync status for metrics (renamed from syncStatus to avoid WatermelonDB conflict)
  @field('contribution_status') contributionStatus!: EntrySyncStatus;

  // ===== CHECK-IN FIELDS =====
  
  // Pre-dose state: single word describing state before dosing
  // Examples: "Calm", "Anxious", "Foggy", "Tired"
  // ⚠️ LOCAL ONLY - Never sync to cloud
  @field('pre_dose_state') preDoseState?: string;

  // Post-dose metrics: captured 4+ hours after dose (1-10 scale)
  // JSON: { energy: 1-10, clarity: 1-10, mood: 1-10 }
  @json('post_dose_metrics', (raw) => raw || null) postDoseMetrics?: PostDoseMetrics | null;

  // Relations
  @relation('protocols', 'protocol_id') protocol!: Relation<Protocol>;
  @relation('doses', 'dose_id') dose?: Relation<Dose>;

  /**
   * Get tags as array
   */
  get tagsArray(): string[] {
    try {
      return JSON.parse(this.tags) || [];
    } catch {
      return [];
    }
  }

  /**
   * Get metrics as object (for sync payload)
   * Note: Does NOT include content - that's local only
   */
  get metrics(): { energy: number; clarity: number; mood: number; anxiety?: number; creativity?: number } {
    return {
      energy: this.energy,
      clarity: this.clarity,
      mood: this.mood,
      ...(this.anxiety !== undefined && { anxiety: this.anxiety }),
      ...(this.creativity !== undefined && { creativity: this.creativity }),
    };
  }

  /**
   * Check if entry has all required metrics
   */
  get hasCompleteMetrics(): boolean {
    return (
      this.energy >= 1 && this.energy <= 5 &&
      this.clarity >= 1 && this.clarity <= 5 &&
      this.mood >= 1 && this.mood <= 5
    );
  }

  /**
   * Check if post-dose check-in is complete
   */
  get hasPostDoseMetrics(): boolean {
    return (
      this.postDoseMetrics !== null &&
      this.postDoseMetrics !== undefined &&
      typeof this.postDoseMetrics.energy === 'number' &&
      typeof this.postDoseMetrics.clarity === 'number' &&
      typeof this.postDoseMetrics.mood === 'number'
    );
  }

  /**
   * Check if pre-dose check-in is complete
   */
  get hasPreDoseState(): boolean {
    return typeof this.preDoseState === 'string' && this.preDoseState.length > 0;
  }

  /**
   * Mark as synced
   */
  async markSynced(): Promise<void> {
    await this.update((entry) => {
      entry.contributionStatus = 'synced';
    });
  }

  /**
   * Mark sync error
   */
  async markSyncError(): Promise<void> {
    await this.update((entry) => {
      entry.contributionStatus = 'error';
    });
  }
}

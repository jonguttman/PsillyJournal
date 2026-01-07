import { Model } from '@nozbe/watermelondb';
import { field } from '@nozbe/watermelondb/decorators';

/**
 * SyncQueue model - queues anonymous metrics for sync when online
 * 
 * PRIVACY NOTE: payload contains ONLY anonymized metrics.
 * Never includes bottle_token, content, or PII.
 */
export default class SyncQueue extends Model {
  static table = 'sync_queue';

  // Reference to entry being synced
  @field('entry_id') entryId!: string;

  // JSON payload to sync (anonymous metrics only)
  @field('payload') payload!: string;

  // Queue timing
  @field('created_at') createdAt!: number;

  // Retry tracking
  @field('attempts') attempts!: number;
  @field('last_error') lastError?: string;

  /**
   * Get parsed payload
   */
  get parsedPayload(): Record<string, unknown> | null {
    try {
      return JSON.parse(this.payload);
    } catch {
      return null;
    }
  }

  /**
   * Increment attempt counter
   */
  async recordAttempt(error?: string): Promise<void> {
    await this.update((item) => {
      item.attempts += 1;
      if (error) {
        item.lastError = error;
      }
    });
  }

  /**
   * Check if should retry (max 5 attempts)
   */
  get shouldRetry(): boolean {
    return this.attempts < 5;
  }
}

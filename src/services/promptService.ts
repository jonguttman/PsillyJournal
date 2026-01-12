import { REFLECTION_PROMPTS, ReflectionPrompt } from '../data/prompts';
import { storage } from '../utils/storage';

const STORAGE_KEY = 'prompt_history';
const RESET_AFTER_DAYS = 14;

interface PromptHistory {
  seen: string[];           // Array of prompt IDs
  lastReset: number;        // Timestamp
}

/**
 * Prompt Service
 *
 * Manages rotation of reflection prompts to prevent repetition
 * for 14 days. After 14 days or when all prompts are seen,
 * the history resets.
 *
 * Uses cross-platform async storage (AsyncStorage on native, localStorage on web).
 */
export class PromptService {

  /**
   * Get next unseen prompt
   */
  async getNextPrompt(): Promise<ReflectionPrompt> {
    const history = await this.getHistory();

    // Check if reset needed (14 days or all seen)
    const daysSinceReset = (Date.now() - history.lastReset) / (1000 * 60 * 60 * 24);
    if (daysSinceReset >= RESET_AFTER_DAYS || history.seen.length >= REFLECTION_PROMPTS.length) {
      await this.resetHistory();
      return this.getRandomPrompt([]);
    }

    return this.getRandomPrompt(history.seen);
  }

  /**
   * Get random prompt not in seen list
   */
  private getRandomPrompt(seenIds: string[]): ReflectionPrompt {
    const unseen = REFLECTION_PROMPTS.filter(p => !seenIds.includes(p.id));

    if (unseen.length === 0) {
      // Fallback: return any prompt
      return REFLECTION_PROMPTS[Math.floor(Math.random() * REFLECTION_PROMPTS.length)];
    }

    return unseen[Math.floor(Math.random() * unseen.length)];
  }

  /**
   * Mark prompt as seen
   */
  async markSeen(promptId: string): Promise<void> {
    const history = await this.getHistory();
    if (!history.seen.includes(promptId)) {
      history.seen.push(promptId);
      await this.saveHistory(history);
    }
  }

  /**
   * Get history from storage
   */
  private async getHistory(): Promise<PromptHistory> {
    try {
      const stored = await storage.getItem(STORAGE_KEY);
      if (stored) {
        return JSON.parse(stored);
      }
    } catch (e) {
      console.error('[PromptService] Error reading history:', e);
    }
    return { seen: [], lastReset: Date.now() };
  }

  /**
   * Save history to storage
   */
  private async saveHistory(history: PromptHistory): Promise<void> {
    await storage.setItem(STORAGE_KEY, JSON.stringify(history));
  }

  /**
   * Reset history (called automatically after 14 days or all prompts seen)
   */
  private async resetHistory(): Promise<void> {
    await this.saveHistory({ seen: [], lastReset: Date.now() });
  }

  /**
   * Manual reset for testing purposes
   */
  async manualReset(): Promise<void> {
    await this.resetHistory();
  }
}

export const promptService = new PromptService();

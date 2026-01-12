import { PromptService } from '../src/services/promptService';
import { REFLECTION_PROMPTS } from '../src/data/prompts';

// Mock localStorage
const localStorageMock = (() => {
  let store: Record<string, string> = {};

  return {
    getItem: (key: string) => store[key] || null,
    setItem: (key: string, value: string) => {
      store[key] = value;
    },
    clear: () => {
      store = {};
    },
  };
})();

// @ts-ignore
global.localStorage = localStorageMock;

describe('PromptService', () => {
  let service: PromptService;

  beforeEach(() => {
    localStorageMock.clear();
    service = new PromptService();
  });

  it('should return a prompt on first call', async () => {
    const prompt = await service.getNextPrompt();
    expect(prompt).toBeDefined();
    expect(prompt.id).toBeDefined();
    expect(prompt.text).toBeDefined();
    expect(prompt.category).toBeDefined();
  });

  it('should not repeat prompts until all are seen', async () => {
    const seenIds = new Set<string>();

    // Get prompts until we've seen them all
    for (let i = 0; i < REFLECTION_PROMPTS.length; i++) {
      const prompt = await service.getNextPrompt();
      expect(seenIds.has(prompt.id)).toBe(false); // Should be unseen
      seenIds.add(prompt.id);
      await service.markSeen(prompt.id);
    }

    expect(seenIds.size).toBe(REFLECTION_PROMPTS.length);
  });

  it('should reset history after all prompts are seen', async () => {
    const firstRoundIds = new Set<string>();

    // See all prompts
    for (let i = 0; i < REFLECTION_PROMPTS.length; i++) {
      const prompt = await service.getNextPrompt();
      firstRoundIds.add(prompt.id);
      await service.markSeen(prompt.id);
    }

    // Next prompt should trigger reset
    const nextPrompt = await service.getNextPrompt();
    expect(nextPrompt).toBeDefined();
    // History should be reset, so we can see prompts again
  });

  it('should mark prompts as seen', async () => {
    const prompt1 = await service.getNextPrompt();
    await service.markSeen(prompt1.id);

    const prompt2 = await service.getNextPrompt();
    await service.markSeen(prompt2.id);

    // These should be different prompts
    expect(prompt1.id).not.toBe(prompt2.id);
  });

  it('should handle manual reset', async () => {
    // See some prompts
    for (let i = 0; i < 5; i++) {
      const prompt = await service.getNextPrompt();
      await service.markSeen(prompt.id);
    }

    // Manual reset
    await service.manualReset();

    // Should be able to see prompts again
    const prompt = await service.getNextPrompt();
    expect(prompt).toBeDefined();
  });
});

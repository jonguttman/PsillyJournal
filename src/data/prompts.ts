/**
 * Reflection Prompt Library
 *
 * Curated prompts designed to:
 * - Encourage varied journaling angles
 * - Support pattern recognition over time
 * - Remain open-ended and non-leading
 * - Align with microdosing self-observation practices
 */

export interface ReflectionPrompt {
  id: string;
  text: string;
  category: 'awareness' | 'intention' | 'discovery' | 'pattern' | 'integration' | 'context';
}

export const REFLECTION_PROMPTS: ReflectionPrompt[] = [
  // Awareness (present-moment observation)
  { id: 'aware_1', text: 'What did you notice about your inner state today?', category: 'awareness' },
  { id: 'aware_2', text: 'Where did your attention naturally go?', category: 'awareness' },
  { id: 'aware_3', text: 'What sensations are present in your body right now?', category: 'awareness' },

  // Intention (goal-setting and purpose)
  { id: 'intent_1', text: 'How did your intentions align with your actions?', category: 'intention' },
  { id: 'intent_2', text: 'What did you set out to explore today?', category: 'intention' },

  // Discovery (insights and revelations)
  { id: 'disc_1', text: 'What surprised you about this experience?', category: 'discovery' },
  { id: 'disc_2', text: 'What became clearer today?', category: 'discovery' },
  { id: 'disc_3', text: 'What questions are alive for you?', category: 'discovery' },

  // Pattern (recognizing trends)
  { id: 'patt_1', text: 'What patterns are emerging for you?', category: 'pattern' },
  { id: 'patt_2', text: 'What feels different compared to last week?', category: 'pattern' },

  // Integration (processing and meaning-making)
  { id: 'integ_1', text: 'What feels different today?', category: 'integration' },
  { id: 'integ_2', text: 'What opened up for you?', category: 'integration' },
  { id: 'integ_3', text: 'What felt difficult or heavy?', category: 'integration' },

  // Context (supports product-activity correlation)
  { id: 'ctx_1', text: 'What were you doing during this experience?', category: 'context' },
  { id: 'ctx_2', text: 'Who were you with, if anyone?', category: 'context' },
  { id: 'ctx_3', text: 'What kind of environment were you in?', category: 'context' },
  { id: 'ctx_4', text: 'What was your body doing?', category: 'context' },
];

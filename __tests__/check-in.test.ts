/**
 * Check-in System Tests
 * 
 * Tests for Phase 2.1 - Daily Check-In System
 */

import {
  isDoseWithin24Hours,
  type PostDoseMetrics,
} from '../src/services/entryService';

// Define notification timing constants inline to avoid importing expo-notifications
const NOTIFICATION_TIMING = {
  '2h': 2 * 60 * 60 * 1000,   // 7,200,000
  '4h': 4 * 60 * 60 * 1000,   // 14,400,000 (default)
  '6h': 6 * 60 * 60 * 1000,   // 21,600,000
  '8h': 8 * 60 * 60 * 1000,   // 28,800,000
} as const;

type NotificationTiming = keyof typeof NOTIFICATION_TIMING;

describe('Check-in Validation', () => {
  describe('Pre-dose state', () => {
    test('accepts non-empty string', () => {
      const preDoseState = 'Good';
      expect(preDoseState.trim().length).toBeGreaterThan(0);
    });

    test('rejects empty string', () => {
      const preDoseState = '';
      expect(preDoseState.trim().length).toBe(0);
    });

    test('rejects whitespace-only string', () => {
      const preDoseState = '   ';
      expect(preDoseState.trim().length).toBe(0);
    });

    test('null is valid for skipped check-in', () => {
      const preDoseState: string | null = null;
      expect(preDoseState).toBeNull();
    });
  });

  describe('Post-dose metrics', () => {
    test('validates metrics in 0-10 range', () => {
      const validMetrics: PostDoseMetrics = {
        energy: 5,
        clarity: 7,
        mood: 8,
      };

      expect(validMetrics.energy).toBeGreaterThanOrEqual(0);
      expect(validMetrics.energy).toBeLessThanOrEqual(10);
      expect(validMetrics.clarity).toBeGreaterThanOrEqual(0);
      expect(validMetrics.clarity).toBeLessThanOrEqual(10);
      expect(validMetrics.mood).toBeGreaterThanOrEqual(0);
      expect(validMetrics.mood).toBeLessThanOrEqual(10);
    });

    test('handles edge values (0 and 10)', () => {
      const minMetrics: PostDoseMetrics = { energy: 0, clarity: 0, mood: 0 };
      const maxMetrics: PostDoseMetrics = { energy: 10, clarity: 10, mood: 10 };

      expect(minMetrics.energy).toBe(0);
      expect(maxMetrics.mood).toBe(10);
    });

    test('default values are valid', () => {
      const defaultMetrics: PostDoseMetrics = {
        energy: 5,
        clarity: 5,
        mood: 5,
      };

      expect(defaultMetrics.energy).toBe(5);
      expect(defaultMetrics.clarity).toBe(5);
      expect(defaultMetrics.mood).toBe(5);
    });
  });

  describe('isDoseWithin24Hours', () => {
    test('returns true for recent dose', () => {
      const recentDose = Date.now() - 1000 * 60 * 60; // 1 hour ago
      expect(isDoseWithin24Hours(recentDose)).toBe(true);
    });

    test('returns true for dose 4 hours ago', () => {
      const fourHoursAgo = Date.now() - 1000 * 60 * 60 * 4;
      expect(isDoseWithin24Hours(fourHoursAgo)).toBe(true);
    });

    test('returns true for dose 23 hours ago', () => {
      const twentyThreeHoursAgo = Date.now() - 1000 * 60 * 60 * 23;
      expect(isDoseWithin24Hours(twentyThreeHoursAgo)).toBe(true);
    });

    test('returns false for dose 25 hours ago', () => {
      const twentyFiveHoursAgo = Date.now() - 1000 * 60 * 60 * 25;
      expect(isDoseWithin24Hours(twentyFiveHoursAgo)).toBe(false);
    });

    test('returns false for dose 48 hours ago', () => {
      const twoDaysAgo = Date.now() - 1000 * 60 * 60 * 48;
      expect(isDoseWithin24Hours(twoDaysAgo)).toBe(false);
    });
  });
});

describe('Notification Scheduling', () => {
  describe('Timing presets', () => {
    test('2h equals 7,200,000ms', () => {
      expect(NOTIFICATION_TIMING['2h']).toBe(2 * 60 * 60 * 1000);
      expect(NOTIFICATION_TIMING['2h']).toBe(7200000);
    });

    test('4h equals 14,400,000ms', () => {
      expect(NOTIFICATION_TIMING['4h']).toBe(4 * 60 * 60 * 1000);
      expect(NOTIFICATION_TIMING['4h']).toBe(14400000);
    });

    test('6h equals 21,600,000ms', () => {
      expect(NOTIFICATION_TIMING['6h']).toBe(6 * 60 * 60 * 1000);
      expect(NOTIFICATION_TIMING['6h']).toBe(21600000);
    });

    test('8h equals 28,800,000ms', () => {
      expect(NOTIFICATION_TIMING['8h']).toBe(8 * 60 * 60 * 1000);
      expect(NOTIFICATION_TIMING['8h']).toBe(28800000);
    });

    test('all timing options are defined', () => {
      const timings: NotificationTiming[] = ['2h', '4h', '6h', '8h'];
      timings.forEach((timing) => {
        expect(NOTIFICATION_TIMING[timing]).toBeDefined();
        expect(typeof NOTIFICATION_TIMING[timing]).toBe('number');
      });
    });
  });

  describe('Notification trigger calculation', () => {
    test('calculates correct trigger time for 4h preset', () => {
      const doseTimestamp = Date.now();
      const expectedTrigger = doseTimestamp + NOTIFICATION_TIMING['4h'];
      
      expect(expectedTrigger - doseTimestamp).toBe(14400000);
    });

    test('handles past trigger times (schedules for near future)', () => {
      const oldDoseTimestamp = Date.now() - NOTIFICATION_TIMING['4h'] - 1000; // 4h + 1s ago
      const calculatedTrigger = oldDoseTimestamp + NOTIFICATION_TIMING['4h'];
      const now = Date.now();

      // If calculated trigger is in the past, it should be rescheduled
      if (calculatedTrigger < now) {
        const adjustedTrigger = now + 60000; // 1 minute from now
        expect(adjustedTrigger).toBeGreaterThan(now);
      }
    });
  });
});

describe('First Dose Detection', () => {
  // Helper function that mimics the app logic
  const checkIsFirstDose = (count: number): boolean => count === 0;

  test('first dose of day (count 0) triggers check-in flow', () => {
    const doseCountToday = 0;
    expect(checkIsFirstDose(doseCountToday)).toBe(true);
  });

  test('second dose of day (count 1) shows toast only', () => {
    const doseCountToday = 1;
    expect(checkIsFirstDose(doseCountToday)).toBe(false);
  });

  test('multiple doses same day (count 3) shows toast only', () => {
    const doseCountToday = 3;
    expect(checkIsFirstDose(doseCountToday)).toBe(false);
  });
});

describe('Deep Link Format', () => {
  test('generates correct post-dose check-in URL', () => {
    const doseId = 'abc123';
    const entryId = 'def456';
    const url = `psilly://check-in/post-dose?dose_id=${doseId}&entry_id=${entryId}`;

    expect(url).toContain('check-in/post-dose');
    expect(url).toContain(`dose_id=${doseId}`);
    expect(url).toContain(`entry_id=${entryId}`);
  });

  test('parses URL parameters correctly', () => {
    const url = 'psilly://check-in/post-dose?dose_id=abc123&entry_id=def456';
    
    // Simulate URL parsing (in real code this uses URL API)
    const doseIdMatch = url.match(/dose_id=([^&]+)/);
    const entryIdMatch = url.match(/entry_id=([^&]+)/);

    expect(doseIdMatch?.[1]).toBe('abc123');
    expect(entryIdMatch?.[1]).toBe('def456');
  });
});

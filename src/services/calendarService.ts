import * as Calendar from 'expo-calendar';
import { Platform } from 'react-native';
import { storage } from '../utils/storage';

const isWeb = Platform.OS === 'web';

export interface CalendarPreference {
  enabled: boolean;
  calendarId: string | null;
  promptShown?: boolean; // Track if we've shown the first-time prompt
}

interface EventMapping {
  [doseId: string]: string; // dose_id -> calendar_event_id
}

const STORAGE_KEYS = {
  PREFERENCES: 'calendar_reminders_prefs',
  EVENT_MAPPINGS: 'calendar_event_mappings',
};

const CALENDAR_CONFIG = {
  TITLE: 'Psilly Journal',
  COLOR: '#8B7355', // Earthy mushroom brown
  REMINDER_HOURS: 4,
  EVENT_DURATION_MINUTES: 15,
};

/**
 * Calendar Reminder Service
 *
 * Manages calendar-based reminders for post-dose check-ins.
 * Calendar events are more reliable than push notifications,
 * especially for time-critical reminders.
 */
export class CalendarReminderService {

  /**
   * Check if calendar is supported on this platform
   */
  isSupported(): boolean {
    return !isWeb; // Calendar API not available on web
  }

  /**
   * Request calendar permissions from the user
   */
  async requestPermissions(): Promise<boolean> {
    if (!this.isSupported()) {
      console.log('[CalendarService] Not supported on web platform');
      return false;
    }

    try {
      const { status } = await Calendar.requestCalendarPermissionsAsync();
      console.log('[CalendarService] Permission status:', status);
      return status === 'granted';
    } catch (error) {
      console.error('[CalendarService] Error requesting permissions:', error);
      return false;
    }
  }

  /**
   * Get or create the Psilly Journal calendar
   * Returns calendar ID or null if failed
   */
  async getOrCreateCalendar(): Promise<string | null> {
    if (!this.isSupported()) return null;

    try {
      // Get all calendars
      const calendars = await Calendar.getCalendarsAsync(Calendar.EntityTypes.EVENT);

      // Check if our calendar already exists
      const existing = calendars.find(cal => cal.title === CALENDAR_CONFIG.TITLE);
      if (existing) {
        console.log('[CalendarService] Found existing calendar:', existing.id);
        return existing.id;
      }

      // Need to create new calendar - requires a source
      const defaultCalendar = calendars.find(
        cal => cal.allowsModifications && cal.source.type === Calendar.SourceType.LOCAL
      ) || calendars[0];

      if (!defaultCalendar) {
        console.error('[CalendarService] No writable calendar source found');
        return null;
      }

      // Create our calendar
      const calendarId = await Calendar.createCalendarAsync({
        title: CALENDAR_CONFIG.TITLE,
        color: CALENDAR_CONFIG.COLOR,
        sourceId: defaultCalendar.source.id,
        source: defaultCalendar.source,
        name: CALENDAR_CONFIG.TITLE,
        ownerAccount: defaultCalendar.source.name || 'personal',
        accessLevel: Calendar.CalendarAccessLevel.OWNER,
      });

      console.log('[CalendarService] Created new calendar:', calendarId);
      return calendarId;
    } catch (error) {
      console.error('[CalendarService] Error getting/creating calendar:', error);
      return null;
    }
  }

  /**
   * Schedule a post-dose reminder calendar event
   * Returns event ID or null if failed/disabled
   */
  async scheduleReminder(doseId: string, doseTimestamp: number): Promise<string | null> {
    if (!this.isSupported()) {
      console.log('[CalendarService] Skipping calendar reminder (web platform)');
      return null;
    }

    const prefs = await this.getPreferences();
    if (!prefs.enabled) {
      console.log('[CalendarService] Calendar reminders disabled by user');
      return null;
    }

    const hasPermission = await this.requestPermissions();
    if (!hasPermission) {
      console.log('[CalendarService] No calendar permission');
      return null;
    }

    try {
      // Get or create our calendar
      let calendarId = prefs.calendarId;
      if (!calendarId) {
        calendarId = await this.getOrCreateCalendar();
        if (!calendarId) return null;

        // Save calendar ID for future use
        await this.setPreferences({ ...prefs, calendarId });
      }

      // Calculate reminder time (4 hours after dose)
      const reminderTime = new Date(doseTimestamp + CALENDAR_CONFIG.REMINDER_HOURS * 60 * 60 * 1000);
      const endTime = new Date(reminderTime.getTime() + CALENDAR_CONFIG.EVENT_DURATION_MINUTES * 60 * 1000);

      // Create the calendar event
      const eventId = await Calendar.createEventAsync(calendarId, {
        title: 'Reflect on your experience ✨',
        startDate: reminderTime,
        endDate: endTime,
        alarms: [{ relativeOffset: 0 }], // Alarm at event start time
        notes: 'Open Psilly Journal to complete your post-dose check-in and capture your experience.',
        timeZone: 'GMT', // Will use device timezone
      });

      console.log('[CalendarService] Created reminder event:', eventId, 'for dose:', doseId);

      // Store the mapping for later cancellation
      await this.storeEventMapping(doseId, eventId);

      return eventId;
    } catch (error) {
      console.error('[CalendarService] Error scheduling reminder:', error);
      return null;
    }
  }

  /**
   * Cancel a calendar reminder (when user completes check-in early)
   */
  async cancelReminder(doseId: string): Promise<void> {
    if (!this.isSupported()) return;

    const eventId = await this.getEventId(doseId);
    if (!eventId) {
      console.log('[CalendarService] No event found for dose:', doseId);
      return;
    }

    try {
      await Calendar.deleteEventAsync(eventId);
      await this.removeEventMapping(doseId);
      console.log('[CalendarService] Cancelled reminder for dose:', doseId);
    } catch (error) {
      console.log('[CalendarService] Event already deleted or not found:', error);
      // Clean up mapping anyway
      await this.removeEventMapping(doseId);
    }
  }

  /**
   * Get user preferences for calendar reminders
   */
  async getPreferences(): Promise<CalendarPreference> {
    try {
      const stored = await storage.getItem(STORAGE_KEYS.PREFERENCES);
      if (stored) {
        return JSON.parse(stored);
      }
    } catch (error) {
      console.error('[CalendarService] Error reading preferences:', error);
    }

    // Default preferences
    return {
      enabled: false,
      calendarId: null,
      promptShown: false,
    };
  }

  /**
   * Update user preferences for calendar reminders
   */
  async setPreferences(prefs: CalendarPreference): Promise<void> {
    try {
      await storage.setItem(STORAGE_KEYS.PREFERENCES, JSON.stringify(prefs));
      console.log('[CalendarService] Updated preferences:', prefs);
    } catch (error) {
      console.error('[CalendarService] Error saving preferences:', error);
    }
  }

  /**
   * Check if this is the first time (prompt hasn't been shown)
   */
  async shouldShowPrompt(): Promise<boolean> {
    if (!this.isSupported()) return false;

    const prefs = await this.getPreferences();
    return !prefs.promptShown;
  }

  /**
   * Mark that we've shown the first-time prompt
   */
  async markPromptShown(): Promise<void> {
    const prefs = await this.getPreferences();
    await this.setPreferences({ ...prefs, promptShown: true });
  }

  // ===== Private Methods =====

  /**
   * Store event mapping (dose_id -> event_id)
   */
  private async storeEventMapping(doseId: string, eventId: string): Promise<void> {
    const mappings = await this.getEventMappings();
    mappings[doseId] = eventId;
    try {
      await storage.setItem(STORAGE_KEYS.EVENT_MAPPINGS, JSON.stringify(mappings));
    } catch (error) {
      console.error('[CalendarService] Error storing event mapping:', error);
    }
  }

  /**
   * Get event ID for a dose
   */
  private async getEventId(doseId: string): Promise<string | null> {
    const mappings = await this.getEventMappings();
    return mappings[doseId] || null;
  }

  /**
   * Remove event mapping
   */
  private async removeEventMapping(doseId: string): Promise<void> {
    const mappings = await this.getEventMappings();
    delete mappings[doseId];
    try {
      await storage.setItem(STORAGE_KEYS.EVENT_MAPPINGS, JSON.stringify(mappings));
    } catch (error) {
      console.error('[CalendarService] Error removing event mapping:', error);
    }
  }

  /**
   * Get all event mappings
   */
  private async getEventMappings(): Promise<EventMapping> {
    try {
      const stored = await storage.getItem(STORAGE_KEYS.EVENT_MAPPINGS);
      if (stored) {
        return JSON.parse(stored);
      }
    } catch (error) {
      console.error('[CalendarService] Error reading event mappings:', error);
    }
    return {};
  }
}

// Singleton instance
export const calendarService = new CalendarReminderService();

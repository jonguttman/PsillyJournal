import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';
import { storage } from '../utils/storage';

// Check if running on web platform
const isWeb = Platform.OS === 'web';

/**
 * Notification timing presets in milliseconds
 *
 * NOTE: Calendar reminders are now the primary method (more reliable).
 * These notifications serve as a fallback for web or users who decline calendar.
 */
export const NOTIFICATION_TIMING = {
  '2h': 2 * 60 * 60 * 1000,   // 7,200,000 ms
  '4h': 4 * 60 * 60 * 1000,   // 14,400,000 ms (default)
  '6h': 6 * 60 * 60 * 1000,   // 21,600,000 ms
  '8h': 8 * 60 * 60 * 1000,   // 28,800,000 ms
} as const;

export type NotificationTiming = keyof typeof NOTIFICATION_TIMING;

// Storage for notification IDs (in-memory, persisted separately if needed)
const notificationIdMap = new Map<string, string>();

// Storage key for localStorage persistence
const NOTIFICATION_IDS_KEY = 'psilly_notification_ids';

/**
 * Load notification IDs from storage
 */
async function loadNotificationIds(): Promise<void> {
  try {
    const stored = await storage.getItem(NOTIFICATION_IDS_KEY);
    if (stored) {
      const parsed = JSON.parse(stored) as Record<string, string>;
      Object.entries(parsed).forEach(([doseId, notifId]) => {
        notificationIdMap.set(doseId, notifId);
      });
    }
  } catch (e) {
    console.warn('[NotificationService] Failed to load notification IDs:', e);
  }
}

/**
 * Save notification IDs to storage
 */
async function saveNotificationIds(): Promise<void> {
  try {
    const obj: Record<string, string> = {};
    notificationIdMap.forEach((notifId, doseId) => {
      obj[doseId] = notifId;
    });
    await storage.setItem(NOTIFICATION_IDS_KEY, JSON.stringify(obj));
  } catch (e) {
    console.warn('[NotificationService] Failed to save notification IDs:', e);
  }
}

// Load on module init (async, fire-and-forget)
loadNotificationIds().catch(console.error);

/**
 * Configure notification handler (call once on app start)
 */
export function configureNotifications(): void {
  if (isWeb) {
    console.log('[NotificationService] Web platform - notifications limited');
    return;
  }

  Notifications.setNotificationHandler({
    handleNotification: async () => ({
      shouldShowAlert: true,
      shouldPlaySound: true,
      shouldSetBadge: false,
      shouldShowBanner: true,
      shouldShowList: true,
    }),
  });
}

/**
 * Request notification permissions
 * @returns true if granted, false otherwise
 */
export async function requestNotificationPermissions(): Promise<boolean> {
  if (isWeb) {
    // Web notifications - use browser API
    if ('Notification' in window) {
      const permission = await Notification.requestPermission();
      return permission === 'granted';
    }
    return false;
  }

  const { status: existingStatus } = await Notifications.getPermissionsAsync();
  
  if (existingStatus === 'granted') {
    return true;
  }

  const { status } = await Notifications.requestPermissionsAsync();
  return status === 'granted';
}

/**
 * Schedule post-dose check-in reminder
 * 
 * @param doseId - ID of the dose record
 * @param entryId - ID of the entry record
 * @param doseTimestamp - When the dose was taken
 * @param timing - How long after dose to notify (default 4h)
 * @returns Notification identifier (or empty string on web)
 */
export async function schedulePostDoseReminder(
  doseId: string,
  entryId: string,
  doseTimestamp: number,
  timing: NotificationTiming = '4h'
): Promise<string> {
  const delayMs = NOTIFICATION_TIMING[timing];
  const triggerTime = doseTimestamp + delayMs;
  const now = Date.now();

  // If trigger time is in the past, schedule for 1 minute from now
  const actualTriggerTime = triggerTime > now ? triggerTime : now + 60000;
  const secondsFromNow = Math.ceil((actualTriggerTime - now) / 1000);

  if (isWeb) {
    // Web fallback - use setTimeout for demo (won't persist across page reload)
    console.log(`[NotificationService] Web: scheduling reminder in ${secondsFromNow}s`);
    const timeoutId = setTimeout(() => {
      if ('Notification' in window && Notification.permission === 'granted') {
        new Notification('How are you feeling?', {
          body: 'Time for your check-in',
          tag: `post-dose-${doseId}`,
        });
      }
    }, secondsFromNow * 1000);

    const webNotifId = `web-${timeoutId}`;
    await storeNotificationId(doseId, webNotifId);
    return webNotifId;
  }

  // Native notification
  const notificationId = await Notifications.scheduleNotificationAsync({
    content: {
      title: 'How are you feeling?',
      body: 'Time for your check-in',
      data: {
        type: 'post-dose-check-in',
        dose_id: doseId,
        entry_id: entryId,
        url: `psilly://check-in/post-dose?dose_id=${doseId}&entry_id=${entryId}`,
      },
      sound: true,
    },
    trigger: {
      type: Notifications.SchedulableTriggerInputTypes.TIME_INTERVAL,
      seconds: secondsFromNow,
    },
  });

  console.log(`[NotificationService] Scheduled notification ${notificationId} in ${secondsFromNow}s`);
  await storeNotificationId(doseId, notificationId);

  return notificationId;
}

/**
 * Cancel a scheduled post-dose reminder
 */
export async function cancelPostDoseReminder(notificationId: string): Promise<void> {
  if (!notificationId) return;

  if (notificationId.startsWith('web-')) {
    // Web fallback - clear timeout
    const timeoutId = parseInt(notificationId.replace('web-', ''), 10);
    clearTimeout(timeoutId);
    console.log('[NotificationService] Cancelled web notification');
    return;
  }

  try {
    await Notifications.cancelScheduledNotificationAsync(notificationId);
    console.log(`[NotificationService] Cancelled notification ${notificationId}`);
  } catch (e) {
    console.warn('[NotificationService] Failed to cancel notification:', e);
  }
}

/**
 * Cancel reminder by dose ID
 */
export async function cancelReminderForDose(doseId: string): Promise<void> {
  const notificationId = getNotificationId(doseId);
  if (notificationId) {
    await cancelPostDoseReminder(notificationId);
    notificationIdMap.delete(doseId);
    await saveNotificationIds();
  }
}

/**
 * Store notification ID for a dose
 */
export async function storeNotificationId(doseId: string, notificationId: string): Promise<void> {
  notificationIdMap.set(doseId, notificationId);
  await saveNotificationIds();
}

/**
 * Get stored notification ID for a dose
 */
export function getNotificationId(doseId: string): string | null {
  return notificationIdMap.get(doseId) || null;
}

/**
 * Setup notification response handler
 * Call this in _layout.tsx to handle notification taps
 * 
 * @param navigate - Function to navigate to a route
 */
export function setupNotificationResponseHandler(
  navigate: (pathname: string, params: Record<string, string>) => void
): () => void {
  if (isWeb) {
    return () => {}; // No-op cleanup for web
  }

  const subscription = Notifications.addNotificationResponseReceivedListener(response => {
    const data = response.notification.request.content.data;
    
    if (data?.type === 'post-dose-check-in' && data.dose_id && data.entry_id) {
      console.log('[NotificationService] Handling notification tap:', data);
      navigate('/check-in/post-dose', {
        dose_id: data.dose_id as string,
        entry_id: data.entry_id as string,
      });
    }
  });

  return () => subscription.remove();
}

/**
 * Get all scheduled notifications (for debugging)
 */
export async function getScheduledNotifications(): Promise<Notifications.NotificationRequest[]> {
  if (isWeb) {
    return [];
  }
  return Notifications.getAllScheduledNotificationsAsync();
}

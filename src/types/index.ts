// Core domain types for Psilly Journal

// Re-export API types
export * from './api';

// Import for local use
import type { ProductInfo } from './api';

// QR Token format: qr_[22 alphanumeric chars]
export type QRToken = `qr_${string}`;

// Anonymous session ID format: anon_[32 hex chars]
export type SessionId = `anon_${string}`;

// Protocol schedule types
export type ScheduleType = '1-on-1-off' | '1-on-2-off' | '3x-week' | '4-on-3-off' | 'flexible' | 'custom';

// Protocol status
export type ProtocolStatus = 'active' | 'paused' | 'completed';

// Reflection metrics (1-5 scale)
export interface ReflectionMetrics {
  energy: number;
  clarity: number;
  mood: number;
  anxiety?: number;
  creativity?: number;
}

// Journal entry (local only, never transmitted)
export interface JournalEntry {
  id: string;
  protocolId: string;
  dayNumber: number;
  timestamp: number;
  content: string; // Free-form text, encrypted at rest
  metrics: ReflectionMetrics;
  tags: string[];
  isDoseDay: boolean;
  doseTimestamp?: number;
}

// Contribution payload (opt-in anonymous metrics)
export interface ContributionPayload {
  session_id: SessionId;
  product_id: string;
  protocol_day: number;
  reflections: ReflectionMetrics;
  dose_timestamp?: number;
}

// QR scan result
export interface QRScanResult {
  success: boolean;
  token?: QRToken;
  error?: string;
}

// Deep link params
export interface DeepLinkParams {
  token: QRToken;
  source: 'deep_link' | 'qr_scan';
}

// App navigation routes
export type RootStackParamList = {
  Home: undefined;
  Scan: undefined;
  Journal: undefined;
  NewEntry: { protocolId: string; dayNumber: number };
  Settings: undefined;
  Onboarding: { productInfo: ProductInfo; token: QRToken };
  Recovery: undefined;
};

// Sync status for offline-first
export type SyncStatus = 'synced' | 'pending' | 'error' | 'offline';

// Local device info (never transmitted)
export interface DeviceInfo {
  deviceId: string; // Generated once, stored in SecureStore
  hasOptedIn: boolean;
  recoveryKeyShown: boolean;
}

import { create } from 'zustand';
import type { ProductInfo, QRToken, SyncStatus } from '../types';

/**
 * Active protocol state
 */
interface ActiveProtocol {
  id: string;
  sessionId: string;
  productId: string;
  productName: string;
  currentDay: number;
  totalDays: number;
  status: 'active' | 'paused' | 'completed';
}

/**
 * Pending bottle state (during onboarding)
 */
interface PendingBottle {
  token: QRToken;
  productInfo: ProductInfo;
  source: 'deep_link' | 'qr_scan';
}

/**
 * App state store
 */
interface AppState {
  // Initialization
  isInitialized: boolean;
  isLoading: boolean;
  error: string | null;

  // Active protocol
  activeProtocol: ActiveProtocol | null;
  
  // Onboarding flow
  pendingBottle: PendingBottle | null;
  showProductSwitch: boolean;

  // Sync status
  syncStatus: SyncStatus;
  pendingSyncCount: number;

  // User preferences
  hasOptedIn: boolean;
  hasCompletedOnboarding: boolean;

  // Lock state
  isLocked: boolean;
  lockTimestamp: number | null;

  // Actions
  setInitialized: (value: boolean) => void;
  setLoading: (value: boolean) => void;
  setError: (error: string | null) => void;
  
  setActiveProtocol: (protocol: ActiveProtocol | null) => void;
  updateProtocolDay: (day: number) => void;
  
  setPendingBottle: (bottle: PendingBottle | null) => void;
  setShowProductSwitch: (show: boolean) => void;
  
  setSyncStatus: (status: SyncStatus) => void;
  setPendingSyncCount: (count: number) => void;
  
  setOptedIn: (value: boolean) => void;
  setOnboardingComplete: (value: boolean) => void;

  setLocked: (locked: boolean) => void;

  reset: () => void;
}

const initialState = {
  isInitialized: false,
  isLoading: true,
  error: null,
  activeProtocol: null,
  pendingBottle: null,
  showProductSwitch: false,
  syncStatus: 'offline' as SyncStatus,
  pendingSyncCount: 0,
  hasOptedIn: false,
  hasCompletedOnboarding: false,
  isLocked: false,
  lockTimestamp: null,
};

export const useAppStore = create<AppState>((set) => ({
  ...initialState,

  setInitialized: (value) => set({ isInitialized: value }),
  setLoading: (value) => set({ isLoading: value }),
  setError: (error) => set({ error }),

  setActiveProtocol: (protocol) => set({ activeProtocol: protocol }),
  updateProtocolDay: (day) =>
    set((state) => ({
      activeProtocol: state.activeProtocol
        ? { ...state.activeProtocol, currentDay: day }
        : null,
    })),

  setPendingBottle: (bottle) => set({ pendingBottle: bottle }),
  setShowProductSwitch: (show) => set({ showProductSwitch: show }),

  setSyncStatus: (status) => set({ syncStatus: status }),
  setPendingSyncCount: (count) => set({ pendingSyncCount: count }),

  setOptedIn: (value) => set({ hasOptedIn: value }),
  setOnboardingComplete: (value) => set({ hasCompletedOnboarding: value }),

  setLocked: (locked) => set({
    isLocked: locked,
    lockTimestamp: locked ? Date.now() : null
  }),

  reset: () => set(initialState),
}));

/**
 * Selectors for common state access patterns
 */
export const selectIsReady = (state: AppState) =>
  state.isInitialized && !state.isLoading;

export const selectHasActiveProtocol = (state: AppState) =>
  state.activeProtocol !== null && state.activeProtocol.status === 'active';

export const selectNeedsOnboarding = (state: AppState) =>
  !state.hasCompletedOnboarding || state.activeProtocol === null;

export const selectCanSync = (state: AppState) =>
  state.hasOptedIn && state.syncStatus !== 'offline';

export const selectIsLocked = (state: AppState) =>
  state.isLocked;

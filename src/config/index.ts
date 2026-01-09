/**
 * App configuration
 * 
 * Environment-specific settings for the Psilly Journal app
 */

// API Configuration
export const API_CONFIG = {
  // Our backend (Vercel)
  // Use relative URL in production so it works on any domain
  BASE_URL: __DEV__
    ? 'http://localhost:3000/api'
    : '/api',

  // PsillyOps Internal API (product lookup)
  // Server-to-server only — calls proxied through our backend
  // Note: Using production URL with staging-scoped token for testing
  PSILLYOPS_INTERNAL_API: 'https://ops.originalpsilly.com/api/internal/products',
  
  // Timeout in milliseconds
  TIMEOUT: 10000,

  // Cache TTL for product info (to be confirmed by PsillyOps)
  PRODUCT_CACHE_TTL: 60 * 60 * 1000, // 1 hour default
};

// Deep Link Configuration
export const DEEP_LINK_CONFIG = {
  // Universal link domain
  DOMAIN: 'journal.originalpsilly.com',
  
  // URL scheme for fallback
  SCHEME: 'psillyjournal',
  
  // Path patterns
  PATHS: {
    BOTTLE: '/bottle/:token',
    RECOVERY: '/recover/:key',
  },
};

// QR Configuration
export const QR_CONFIG = {
  // PsillyOps QR URL base
  PSILLYOPS_BASE: 'https://ops.originalpsilly.com/qr/',
  
  // Token validation pattern
  TOKEN_PATTERN: /^qr_[a-zA-Z0-9]{20,30}$/,
};

// Protocol Defaults
export const PROTOCOL_DEFAULTS = {
  // Default protocol length in days
  DURATION_DAYS: 30,
  
  // Default schedule
  SCHEDULE: '1-on-1-off' as const,
  
  // Metric ranges
  METRIC_MIN: 1,
  METRIC_MAX: 5,
};

// Storage Keys (SecureStore)
export const STORAGE_KEYS = {
  DEVICE_ID: 'psilly_device_id',
  SALT: 'psilly_salt',
  RECOVERY_KEY: 'psilly_recovery_key',
  HAS_OPTED_IN: 'psilly_opted_in',
  ONBOARDING_COMPLETE: 'psilly_onboarded',
  PIN_HASH: 'psilly_pin_hash',
};

// Feature Flags
export const FEATURES = {
  // Enable contribution sync (opt-in metrics)
  SYNC_ENABLED: true,
  
  // Enable offline mode
  OFFLINE_MODE: true,
  
  // Enable debug logging
  DEBUG_LOGGING: __DEV__,
};

// Privacy Configuration
export const PRIVACY_CONFIG = {
  // Fields that are NEVER synced to cloud
  LOCAL_ONLY_FIELDS: [
    'bottle_token',
    'content', // journal text
    'notes',   // dose notes
  ],
  
  // Max sync retry attempts
  MAX_SYNC_RETRIES: 5,
  
  // Sync batch size
  SYNC_BATCH_SIZE: 10,
};

import { Database } from '@nozbe/watermelondb';
import LokiJSAdapter from '@nozbe/watermelondb/adapters/lokijs';

import schema from './schema';
import { Bottle, Protocol, Entry, Dose, SyncQueue } from './models';

/**
 * Initialize WatermelonDB with LokiJS adapter
 *
 * LokiJS is used for React Native as it's pure JS and works
 * across all platforms. For production, consider SQLite adapter
 * for better performance with large datasets.
 */
const adapter = new LokiJSAdapter({
  schema,
  useWebWorker: false,
  useIncrementalIndexedDB: true,
  // CRITICAL: Add migration steps for schema version 2
  // This prevents database reset on schema changes
  migrations: {
    migrations: [
      // Migration from v1 to v2 (if user had v1 data)
      // Empty migration - v2 is the baseline for new users
    ],
  },
});

// Create database instance
const database = new Database({
  adapter,
  modelClasses: [Bottle, Protocol, Entry, Dose, SyncQueue],
});

export default database;

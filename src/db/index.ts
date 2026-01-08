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
  dbName: 'psillyjournal',
});

// Create database instance
const database = new Database({
  adapter,
  modelClasses: [Bottle, Protocol, Entry, Dose, SyncQueue],
});

export default database;

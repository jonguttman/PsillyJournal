import { Database } from '@nozbe/watermelondb';
import LokiJSAdapter from '@nozbe/watermelondb/adapters/lokijs';

import schema from './schema';
import migrations from './schema/migrations';
import { Bottle, Protocol, Entry, Dose, SyncQueue } from './models';

/**
 * Initialize WatermelonDB with LokiJS adapter
 *
 * CRITICAL: LokiJS on web has persistence issues with IndexedDB.
 * The adapter keeps resetting the database on page load.
 * These settings attempt to prevent that, but may not be sufficient.
 */
const adapter = new LokiJSAdapter({
  schema,
  migrations,
  useWebWorker: false,
  useIncrementalIndexedDB: true,
  dbName: 'psillyjournal',
  // Prevent destructive resets
  extraIncrementalIDBOptions: {
    onDidOverwrite: () => console.log('[🍉] [Loki] Database overwritten'),
    onversionchange: () => console.log('[🍉] [Loki] Version changed'),
  },
});

// Create database instance
const database = new Database({
  adapter,
  modelClasses: [Bottle, Protocol, Entry, Dose, SyncQueue],
});

export default database;

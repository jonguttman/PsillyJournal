import { appSchema, tableSchema } from '@nozbe/watermelondb';

export const schema = appSchema({
  version: 1,
  tables: [
    // Bottles table - stores QR tokens locally (NEVER transmitted)
    tableSchema({
      name: 'bottles',
      columns: [
        { name: 'bottle_token', type: 'string', isIndexed: true }, // qr_xxx - LOCAL ONLY
        { name: 'product_id', type: 'string', isIndexed: true },
        { name: 'product_name', type: 'string' },
        { name: 'batch_id', type: 'string', isOptional: true },
        { name: 'first_scanned_at', type: 'number' },
        { name: 'last_scanned_at', type: 'number' },
        { name: 'scan_count', type: 'number' },
      ],
    }),

    // Protocols table - links bottle to journaling protocol
    tableSchema({
      name: 'protocols',
      columns: [
        { name: 'bottle_id', type: 'string', isIndexed: true }, // FK to bottles
        { name: 'session_id', type: 'string', isIndexed: true }, // Anonymized hash for cloud
        { name: 'product_id', type: 'string' },
        { name: 'product_name', type: 'string' },
        { name: 'start_date', type: 'number' },
        { name: 'status', type: 'string', isIndexed: true }, // active | paused | completed
        { name: 'schedule_type', type: 'string', isOptional: true },
        { name: 'total_days', type: 'number' }, // Protocol length (default 30)
        { name: 'current_day', type: 'number' },
      ],
    }),

    // Entries table - journal entries (content NEVER transmitted)
    tableSchema({
      name: 'entries',
      columns: [
        { name: 'protocol_id', type: 'string', isIndexed: true }, // FK to protocols
        { name: 'dose_id', type: 'string', isOptional: true, isIndexed: true }, // FK to doses
        { name: 'day_number', type: 'number', isIndexed: true },
        { name: 'timestamp', type: 'number', isIndexed: true },
        { name: 'content', type: 'string' }, // Encrypted free-form text - LOCAL ONLY
        { name: 'energy', type: 'number' },
        { name: 'clarity', type: 'number' },
        { name: 'mood', type: 'number' },
        { name: 'anxiety', type: 'number', isOptional: true },
        { name: 'creativity', type: 'number', isOptional: true },
        { name: 'tags', type: 'string' }, // JSON array as string
        { name: 'is_dose_day', type: 'boolean' },
        { name: 'dose_timestamp', type: 'number', isOptional: true },
        { name: 'contribution_status', type: 'string' }, // synced | pending | error
        // Check-in fields
        { name: 'pre_dose_state', type: 'string', isOptional: true }, // Single word - LOCAL ONLY
        { name: 'post_dose_metrics', type: 'string', isOptional: true }, // JSON: {energy, clarity, mood}
      ],
    }),

    // Doses table - tracks dose events (timestamps only, no content)
    tableSchema({
      name: 'doses',
      columns: [
        { name: 'protocol_id', type: 'string', isIndexed: true },
        { name: 'bottle_id', type: 'string', isIndexed: true },
        { name: 'timestamp', type: 'number', isIndexed: true },
        { name: 'day_number', type: 'number' },
        { name: 'notes', type: 'string', isOptional: true }, // LOCAL ONLY
      ],
    }),

    // Sync queue - tracks what needs to sync when online
    tableSchema({
      name: 'sync_queue',
      columns: [
        { name: 'entry_id', type: 'string', isIndexed: true },
        { name: 'payload', type: 'string' }, // JSON - anonymous metrics only
        { name: 'created_at', type: 'number' },
        { name: 'attempts', type: 'number' },
        { name: 'last_error', type: 'string', isOptional: true },
      ],
    }),
  ],
});

export default schema;

import { schemaMigrations, addColumns } from '@nozbe/watermelondb/Schema/migrations';

/**
 * Database migrations
 *
 * Version 1 → 2: Add context capture fields to entries table
 * Version 2 → 3: Add reflection prompt fields to entries table
 */
export default schemaMigrations({
  migrations: [
    {
      toVersion: 2,
      steps: [
        addColumns({
          table: 'entries',
          columns: [
            { name: 'context_activity', type: 'string', isOptional: true },
            { name: 'context_notes', type: 'string', isOptional: true },
            { name: 'check_in_completed', type: 'boolean', isOptional: true },
          ],
        }),
      ],
    },
    {
      toVersion: 3,
      steps: [
        addColumns({
          table: 'entries',
          columns: [
            { name: 'reflection_prompt_id', type: 'string', isOptional: true },
            { name: 'reflection_prompt_text', type: 'string', isOptional: true },
          ],
        }),
      ],
    },
  ],
});

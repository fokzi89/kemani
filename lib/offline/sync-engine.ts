import { PowerSyncDatabase, WASQLitePowerSyncDatabaseOpenFactory } from '@powersync/web';
import { AppSchema } from './schema';

export class SyncEngine {
    db: PowerSyncDatabase;

    constructor() {
        // Create a factory for the database
        const factory = new WASQLitePowerSyncDatabaseOpenFactory({
            dbFilename: 'kemani_pos.db',
            schema: AppSchema,
        });

        this.db = factory.getInstance();
    }

    async init() {
        await this.db.init(); // Initialize the DB
        await this.db.connect({
            fetchCredentials: async () => {
                // Fetch temporary credentials from your backend
                // For now, return a placeholder or implement the API call
                const response = await fetch('/api/powersync/token');
                if (!response.ok) throw new Error('Failed to fetch credentials');
                return response.json();
            },
            uploadData: async (batch: any) => {
                // Import dynamically to avoid circular dependencies or initialization issues if needed
                // But top level import is fine usually.
                // We'll use the browser client.
                const { createClient } = await import('@/lib/supabase/client');
                const supabase = createClient();

                for (const op of batch.crud) {
                    const { table, id, op: operation, data } = op;

                    try {
                        if (operation === 'PUT' || operation === 'PATCH') {
                            const { error } = await supabase.from(table).upsert({ ...data, id });
                            if (error) throw error;
                        } else if (operation === 'DELETE') {
                            const { error } = await supabase.from(table).delete().eq('id', id);
                            if (error) throw error;
                        }
                    } catch (error) {
                        console.error(`Sync error on ${table} ${id}:`, error);
                        // Throwing error causes PowerSync to retry later
                        throw error;
                    }
                }
            }
        });
    }

    getDatabase() {
        return this.db;
    }
}

export const syncEngine = new SyncEngine();

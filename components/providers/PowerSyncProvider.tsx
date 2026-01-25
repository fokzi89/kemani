'use client';

import React, { useEffect, useState } from 'react';
import { PowerSyncContext } from '@powersync/react';
import { syncEngine } from '@/lib/offline/sync-engine';
import { PowerSyncDatabase } from '@powersync/web';

export const PowerSyncProvider = ({ children }: { children: React.ReactNode }) => {
    const [db, setDb] = useState<PowerSyncDatabase | null>(null);

    useEffect(() => {
        // Initialize PowerSync
        const init = async () => {
            try {
                await syncEngine.init();
                setDb(syncEngine.db);
            } catch (e) {
                console.error('Failed to initialize PowerSync', e);
            }
        };

        init();
    }, []);

    // Render children immediately, PowerSync features will be available once db is ready
    // This prevents blocking the UI while PowerSync initializes
    return (
        <PowerSyncContext.Provider value={db}>
            {children}
        </PowerSyncContext.Provider>
    );
};

'use client';

import React, { useEffect, useState } from 'react';
import { Wifi, WifiOff, RefreshCw, CheckCircle2 } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useStatus } from '@powersync/react';

export function SyncStatus() {
    const status = useStatus();
    // status object has: connected, dataFlowStatus: { uploading, downloading }, lastSyncedAt

    const isOnline = status.connected;
    const isSyncing = status.dataFlowStatus.uploading || status.dataFlowStatus.downloading;
    const lastSynced = status.lastSyncedAt;

    return (
        <div className="fixed bottom-4 right-4 z-50 flex items-center gap-2">
            <div
                className={cn(
                    "flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-medium shadow-lg transition-all duration-300",
                    isOnline
                        ? "bg-white dark:bg-zinc-800 text-green-600 dark:text-green-400 border border-green-200 dark:border-green-800"
                        : "bg-red-50 dark:bg-red-900/30 text-red-600 dark:text-red-400 border border-red-200 dark:border-red-800"
                )}
            >
                {isOnline ? (
                    isSyncing ? (
                        <>
                            <RefreshCw className="h-3 w-3 animate-spin" />
                            <span>Syncing...</span>
                        </>
                    ) : (
                        <>
                            <Wifi className="h-3 w-3" />
                            <span>Online</span>
                            {lastSynced && (
                                <span className="text-muted-foreground ml-1 hidden sm:inline-block">
                                    • Synced {lastSynced.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                </span>
                            )}
                        </>
                    )
                ) : (
                    <>
                        <WifiOff className="h-3 w-3" />
                        <span>Offline Mode</span>
                        {/* Access pending uploads count if available, mostly via accessing 'db.getUploadQueue()' but status doesn't expose it directly yet in all versions */}
                    </>
                )}
            </div>
        </div>
    );
}

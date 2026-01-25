'use client';

import React from 'react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { RefreshCw, WifiOff } from 'lucide-react';

export function SyncQueue() {
    const pendingCount = 5; // Replace with real queue count from QueueManager

    if (pendingCount === 0) return null;

    return (
        <Card className="fixed bottom-4 left-4 w-64 shadow-lg z-50 border-orange-200 bg-orange-50 dark:bg-orange-950/20">
            <CardHeader className="p-3 pb-0">
                <CardTitle className="text-sm font-medium flex items-center gap-2 text-orange-700 dark:text-orange-400">
                    <WifiOff className="h-4 w-4" />
                    Offline Mode
                </CardTitle>
            </CardHeader>
            <CardContent className="p-3 pt-2">
                <div className="flex items-center justify-between text-xs">
                    <span>{pendingCount} item(s) pending sync</span>
                    <RefreshCw className="h-3 w-3 animate-spin text-muted-foreground" />
                </div>
            </CardContent>
        </Card>
    );
}

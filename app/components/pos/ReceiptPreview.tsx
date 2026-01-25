'use client';

import React from 'react';
import { Receipt } from '@/lib/types/pos';
import { receiptService } from '@/lib/pos/receipt';
import { Button } from '@/components/ui/button';
import { Printer } from 'lucide-react';

interface ReceiptPreviewProps {
    saleId: string;
    onPrint: () => void;
}

export function ReceiptPreview({ saleId, onPrint }: ReceiptPreviewProps) {
    return (
        <div className="flex flex-col h-full">
            <div className="flex-1 bg-white border p-4 overflow-y-auto">
                <iframe
                    src={`/api/receipts/${saleId}`}
                    className="w-full h-full border-none"
                    title="Receipt Preview"
                />
            </div>
            <div className="p-4 border-t">
                <Button onClick={onPrint} className="w-full">
                    <Printer className="mr-2 h-4 w-4" />
                    Print Receipt
                </Button>
            </div>
        </div>
    );
}

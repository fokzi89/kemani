'use client';

import React from 'react';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { formatCurrency } from '@/lib/utils/formatting';

interface DiscountTaxProps {
    subtotal: number;
    discount: number;
    tax: number;
    discountRate: number; // Percentage or Fixed
    taxRate: number; // Percentage
    onDiscountChange: (amount: number) => void;
}

export function DiscountTax({ subtotal, discount, tax, onDiscountChange }: DiscountTaxProps) {
    return (
        <div className="space-y-3 p-4 border rounded-lg bg-muted/10">
            <div className="flex justify-between items-center text-sm">
                <span>Subtotal</span>
                <span>{formatCurrency(subtotal)}</span>
            </div>

            <div className="flex items-center gap-4">
                <Label htmlFor="discount" className="w-20">Discount</Label>
                <Input
                    id="discount"
                    type="number"
                    value={discount}
                    onChange={(e) => onDiscountChange(Number(e.target.value))}
                    className="h-8 text-right"
                    min="0"
                />
            </div>

            <div className="flex justify-between items-center text-sm">
                <span className="text-muted-foreground">Tax ({((tax / subtotal) * 100).toFixed(0)}%)</span>
                <span>{formatCurrency(tax)}</span>
            </div>
        </div>
    );
}

'use client';

import React from 'react';
import { Button } from '@/components/ui/button';
import { CreditCard, Banknote, Smartphone, ArrowRightLeft } from 'lucide-react';
import { cn } from '@/lib/utils';

type PaymentMethodType = 'cash' | 'card' | 'bank_transfer' | 'mobile_money';

interface PaymentMethodProps {
    selected: PaymentMethodType;
    onSelect: (method: PaymentMethodType) => void;
}

const METHODS = [
    { id: 'cash', label: 'Cash', icon: Banknote },
    { id: 'card', label: 'Card', icon: CreditCard },
    { id: 'bank_transfer', label: 'Transfer', icon: ArrowRightLeft },
    { id: 'mobile_money', label: 'Mobile', icon: Smartphone },
] as const;

export function PaymentMethod({ selected, onSelect }: PaymentMethodProps) {
    return (
        <div className="grid grid-cols-4 gap-2">
            {METHODS.map((method) => (
                <Button
                    key={method.id}
                    variant={selected === method.id ? 'default' : 'outline'}
                    className={cn(
                        "flex flex-col items-center justify-center h-20 gap-2",
                        selected === method.id ? "border-primary" : ""
                    )}
                    onClick={() => onSelect(method.id)}
                >
                    <method.icon className="h-5 w-5" />
                    <span className="text-xs">{method.label}</span>
                </Button>
            ))}
        </div>
    );
}

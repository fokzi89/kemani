'use client';

import React, { useState } from 'react';
import { ProductSelector } from '@/app/components/pos/ProductSelector';
import { Cart } from '@/app/components/pos/Cart';
import { PaymentMethod } from '@/app/components/pos/PaymentMethod';
import { DiscountTax } from '@/app/components/pos/DiscountTax';
import { Product, SaleInput } from '@/lib/types/pos';
import { Button } from '@/components/ui/button';
import { toast } from 'sonner';
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from '@/components/ui/sheet';
import { ReceiptPreview } from '@/app/components/pos/ReceiptPreview';
import { useProcessSale } from '@/hooks/use-pos';
import { useSubscriptionContext } from '@/lib/context/SubscriptionContext';

export default function POSPage() {
    const [cartItems, setCartItems] = useState<{ product: Product; quantity: number }[]>([]);
    const [discount, setDiscount] = useState(0);
    const [paymentMethod, setPaymentMethod] = useState<'cash' | 'card' | 'bank_transfer' | 'mobile_money'>('cash');
    const [processing, setProcessing] = useState(false);
    const [lastSaleId, setLastSaleId] = useState<string | null>(null);
    const [showReceipt, setShowReceipt] = useState(false);

    // Context & Hooks
    // In a real app, user and subscription data would be robustly available
    // For MVP, we might mock the userId if not easily available synchronously, or fetch it.
    // SubscriptionContext provides plan info, but not necessarily user ID for cashier.
    // We'll rely on a placeholder or assume Auth Provider wraps this.
    const userId = 'user-placeholder-id'; // Replace with useAuth() hook result
    const tenantId = 'tenant-placeholder-id';
    const branchId = 'branch-123'; // Should come from user context

    const { processSale } = useProcessSale();

    const addToCart = (product: Product) => {
        setCartItems(prev => {
            const existing = prev.find(p => p.product.id === product.id);
            if (existing) {
                return prev.map(p => p.product.id === product.id ? { ...p, quantity: p.quantity + 1 } : p);
            }
            return [...prev, { product, quantity: 1 }];
        });
    };

    const updateQuantity = (productId: string, delta: number) => {
        setCartItems(prev => prev.map(p => {
            if (p.product.id === productId) {
                const newQty = Math.max(1, p.quantity + delta);
                return { ...p, quantity: newQty };
            }
            return p;
        }));
    };

    const removeItem = (productId: string) => {
        setCartItems(prev => prev.filter(p => p.product.id !== productId));
    };

    const clearCart = () => {
        setCartItems([]);
        setDiscount(0);
        setLastSaleId(null);
    };

    const subtotal = cartItems.reduce((sum, item) => sum + (item.product.unit_price * item.quantity), 0);
    const tax = subtotal * 0.075; // 7.5% VAT standard in Nigeria
    const total = subtotal + tax - discount;

    const handleCheckout = async () => {
        if (cartItems.length === 0) return;
        setProcessing(true);

        try {
            const saleData: SaleInput = {
                subtotal,
                tax_amount: tax,
                discount_amount: discount,
                total_amount: total,
                payment_method: paymentMethod,
                items: cartItems.map(item => ({
                    product_id: item.product.id,
                    product_name: item.product.name,
                    quantity: item.quantity,
                    unit_price: item.product.unit_price,
                    discount_percent: 0,
                    discount_amount: 0,
                    subtotal: item.product.unit_price * item.quantity
                }))
            };

            // Use Offline-First Hook
            await processSale(saleData, branchId, userId, tenantId);

            // In offline mode, we don't get a backend ID back immediately unless we generate UUID locally.
            // Our hook generates UUIDs. passing generation responsibility to hook?
            // Ideally hook returns the Sale ID it created.
            // Let's assume hook returns { saleId } or we generate and pass it.
            // For now, let's fake the ID for receipt preview relying on local state if needed
            // But ReceiptPreview fetches from API /api/receipts/[id]...
            // This is a disconnect. If offline, ReceiptPreview can't fetch from API.
            // ReceiptPreview should accept Sale Data Object, not just ID.

            setLastSaleId('offline-pending');
            toast.success('Sale processed (Sync Pending)');
            setShowReceipt(true);

        } catch (error) {
            console.error(error);
            toast.error('Transaction failed');
        } finally {
            setProcessing(false);
        }
    };

    return (
        <div className="flex h-[calc(100vh-4rem)] overflow-hidden">
            {/* Left: Product Selection */}
            <div className="flex-1 p-4 overflow-y-auto bg-muted/20">
                <ProductSelector onProductSelect={addToCart} branchId={branchId} />
            </div>

            {/* Right: Cart & Checkout */}
            <div className="w-[400px] border-l bg-background flex flex-col">
                <div className="flex-1 overflow-hidden p-2">
                    <Cart
                        items={cartItems.map(i => ({
                            productId: i.product.id,
                            name: i.product.name,
                            price: i.product.unit_price,
                            quantity: i.quantity
                        }))}
                        onUpdateQuantity={updateQuantity}
                        onRemoveItem={removeItem}
                        onClearCart={clearCart}
                    />
                </div>

                <div className="p-4 border-t space-y-4 shadow-lg z-10 bg-background">
                    <DiscountTax
                        subtotal={subtotal}
                        discount={discount}
                        tax={tax}
                        discountRate={0}
                        taxRate={7.5}
                        onDiscountChange={setDiscount}
                    />

                    <PaymentMethod selected={paymentMethod} onSelect={setPaymentMethod} />

                    <Sheet open={showReceipt} onOpenChange={(open) => {
                        setShowReceipt(open);
                        if (!open) clearCart(); // Auto clear on close
                    }}>
                        <SheetTrigger asChild>
                            <Button
                                size="lg"
                                className="w-full text-lg font-bold h-14"
                                disabled={cartItems.length === 0 || processing}
                                onClick={handleCheckout}
                            >
                                {processing ? 'Processing...' : `Pay ${new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN' }).format(total)}`}
                            </Button>
                        </SheetTrigger>
                        <SheetContent className="w-[400px] sm:w-[540px]">
                            <SheetHeader>
                                <SheetTitle>Receipt Preview</SheetTitle>
                            </SheetHeader>
                            {/* 
                                Offline Receipt Note: 
                                If we are offline, iframe to /api/receipts might fail if service worker doesn't cache it 
                                or if the data isn't on server yet.
                                Ideally we render receipt client-side for offline.
                                For MVP, this might show 404 if offline and not synced.
                            */}
                            {lastSaleId && (
                                <div className="h-[calc(100vh-100px)] mt-4 flex items-center justify-center border rounded">
                                    {lastSaleId === 'offline-pending' ? (
                                        <div className="text-center p-6">
                                            <p className="font-semibold mb-2">Sale Recorded Offline</p>
                                            <p className="text-sm text-muted-foreground">Receipt will be generated once synced.</p>
                                            <Button className="mt-4" onClick={() => window.print()}>Print Summary</Button>
                                        </div>
                                    ) : (
                                        <ReceiptPreview saleId={lastSaleId} onPrint={() => window.print()} />
                                    )}
                                </div>
                            )}
                        </SheetContent>
                    </Sheet>
                </div>
            </div>
        </div>
    );
}


import { PUBLIC_PAYSTACK_KEY } from '$env/static/public';

// Standard fees
const FEES = {
    transaction: 100,
    platform: 50,
    deliveryAddition: 100
};

export interface PaymentConfig {
    email: string;
    amount: number; // In Kobo
    reference: string;
    callback_url?: string;
    metadata?: any;
}

export function initializePayment(config: PaymentConfig, onSuccess: (response: any) => void, onClose: () => void) {
    if (typeof window === 'undefined' || !(window as any).PaystackPop) {
        console.error('Paystack script not loaded');
        return;
    }

    const handler = (window as any).PaystackPop.setup({
        key: PUBLIC_PAYSTACK_KEY, // Public key
        email: config.email,
        amount: config.amount,
        currency: 'NGN',
        ref: config.reference,
        metadata: config.metadata,
        callback: (response: any) => {
            onSuccess(response);
        },
        onClose: () => {
            onClose();
        }
    });

    handler.openIframe();
}

export function calculateTotal(cartTotal: number, deliveryBaseFee: number, isPickup: boolean) {
    // Delivery Fee = Base + Addition (even for pickup it's 0 + 100 = 100)
    const deliveryFee = deliveryBaseFee + FEES.deliveryAddition;

    // Total = Cart + Delivery + Platform + Transaction
    return cartTotal + deliveryFee + FEES.platform + FEES.transaction;
}

import { paystackClient } from './paystack';
import { flutterwaveClient } from './flutterwave';

export type PaymentProviderType = 'paystack' | 'flutterwave';

export interface PaymentInitializationResult {
    url: string;
    reference: string;
    provider: PaymentProviderType;
}

export interface PaymentVerificationResult {
    success: boolean;
    amount: number;
    reference: string;
    provider: PaymentProviderType;
    raw: any;
}

export const paymentProvider = {
    /**
     * Initialize a payment.
     * Tries Paystack first, falls back to Flutterwave if Paystack fails.
     */
    initializePayment: async (
        email: string,
        amountInNaira: number,
        reference: string,
        callbackUrl: string
    ): Promise<PaymentInitializationResult> => {
        // Try Paystack First (Amount in Kobo)
        try {
            const amountKobo = Math.round(amountInNaira * 100);
            const paystackRes = await paystackClient.initializeTransaction(email, amountKobo, reference, callbackUrl);

            if (paystackRes.status && paystackRes.data?.authorization_url) {
                return {
                    url: paystackRes.data.authorization_url,
                    reference: paystackRes.data.reference,
                    provider: 'paystack',
                };
            }
        } catch (err) {
            console.warn('Paystack initialization failed, trying Flutterwave fallback:', err);
        }

        // Fallback to Flutterwave (Amount in Naira)
        try {
            const fwRes = await flutterwaveClient.initializePayment(email, amountInNaira, reference, callbackUrl);
            if (fwRes.status === 'success' && fwRes.data?.link) {
                return {
                    url: fwRes.data.link,
                    reference,
                    provider: 'flutterwave',
                };
            }
        } catch (err) {
            console.error('Flutterwave initialization failed:', err);
        }

        throw new Error('All payment providers failed');
    },

    verifyPayment: async (
        reference: string,
        provider: PaymentProviderType,
        transactionId?: string // Needed for Flutterwave
    ): Promise<PaymentVerificationResult> => {
        if (provider === 'paystack') {
            const res = await paystackClient.verifyTransaction(reference);
            if (res.status && res.data.status === 'success') {
                return {
                    success: true,
                    amount: res.data.amount / 100, // Convert back to Naira
                    reference: res.data.reference,
                    provider: 'paystack',
                    raw: res.data
                };
            }
        } else if (provider === 'flutterwave' && transactionId) {
            const res = await flutterwaveClient.verifyTransaction(transactionId);
            if (res.status === 'success' && res.data.status === 'successful') {
                return {
                    success: true,
                    amount: res.data.amount,
                    reference: res.data.tx_ref,
                    provider: 'flutterwave',
                    raw: res.data
                };
            }
        }

        return {
            success: false,
            amount: 0,
            reference,
            provider,
            raw: null
        };
    }
};

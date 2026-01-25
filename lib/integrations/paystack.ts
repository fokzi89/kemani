import Paystack from 'paystack';

const paystack = Paystack(process.env.PAYSTACK_SECRET_KEY || '');

export interface InitializePaymentResponse {
    status: boolean;
    message: string;
    data: {
        authorization_url: string;
        access_code: string;
        reference: string;
    };
}

export interface VerifyPaymentResponse {
    status: boolean;
    message: string;
    data: {
        amount: number;
        currency: string;
        transaction_date: string;
        status: string;
        reference: string;
        gateway_response: string;
        customer: {
            email: string;
        };
    };
}

export const paystackClient = {
    initializeTransaction: async (
        email: string,
        amount: number, // in kobo
        reference: string,
        callbackUrl: string
    ): Promise<InitializePaymentResponse> => {
        try {
            const response = await paystack.transaction.initialize({
                email,
                amount: amount.toString(), // Paystack expects string for amount in JS SDK sometimes, but typically integer kobo. wrapper might differ.
                // The 'paystack' npm package (if it's the standard one) typically uses `transaction.initialize`
                reference,
                callback_url: callbackUrl,
            });
            return response as unknown as InitializePaymentResponse;
        } catch (error) {
            console.error('Paystack initialization error:', error);
            throw error;
        }
    },

    verifyTransaction: async (reference: string): Promise<VerifyPaymentResponse> => {
        try {
            const response = await paystack.transaction.verify(reference);
            return response as unknown as VerifyPaymentResponse;
        } catch (error) {
            console.error('Paystack verification error:', error);
            throw error;
        }
    }
};

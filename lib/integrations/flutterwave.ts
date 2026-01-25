const Flutterwave = require('flutterwave-node-v3');

const flw = new Flutterwave(
    process.env.FLUTTERWAVE_PUBLIC_KEY || '',
    process.env.FLUTTERWAVE_SECRET_KEY || ''
);

export interface FWInitializeResponse {
    status: string;
    message: string;
    data: {
        link: string;
    };
}

export interface FWVerifyResponse {
    status: string;
    message: string;
    data: {
        id: number;
        tx_ref: string;
        flw_ref: string;
        amount: number;
        currency: string;
        status: string;
        customer: {
            email: string;
        };
    };
}

export const flutterwaveClient = {
    initializePayment: async (
        email: string,
        amount: number,
        reference: string,
        callbackUrl: string,
        currency: string = 'NGN'
    ): Promise<FWInitializeResponse> => {
        try {
            const payload = {
                tx_ref: reference,
                amount: amount.toString(),
                currency,
                redirect_url: callbackUrl,
                customer: {
                    email,
                },
            };
            const response = await flw.Payment.standard(payload);
            return response;
        } catch (error) {
            console.error('Flutterwave initialization error:', error);
            throw error;
        }
    },

    verifyTransaction: async (transactionId: string): Promise<FWVerifyResponse> => {
        try {
            const response = await flw.Transaction.verify({ id: transactionId });
            return response;
        } catch (error) {
            console.error('Flutterwave verification error:', error);
            throw error;
        }
    }
};

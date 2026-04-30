import { PUBLIC_MONNIFY_API_KEY, PUBLIC_MONNIFY_CONTRACT_CODE } from '$env/static/public';

export interface MonnifyOptions {
    email: string;
    name: string;
    amount: number;
    ref: string;
    description?: string;
    contractCode?: string;
    onSuccess: (response: any) => void;
    onClose: () => void;
    metadata?: any;
    currency?: string;
}

export class MonnifyService {
    private static scriptId = 'monnify-sdk';
    private static scriptUrl = 'https://sdk.monnify.com/plugin/monnify.js';

    private static loadScript(): Promise<void> {
        return new Promise((resolve, reject) => {
            if (typeof window === 'undefined') return;
            if (document.getElementById(this.scriptId)) {
                resolve();
                return;
            }

            const script = document.createElement('script');
            script.id = this.scriptId;
            script.src = this.scriptUrl;
            script.async = true;
            script.onload = () => resolve();
            script.onerror = () => reject(new Error('Failed to load Monnify SDK'));
            document.body.appendChild(script);
        });
    }

    static async pay(options: MonnifyOptions) {
        try {
            await this.loadScript();

            if (!(window as any).MonnifySDK) {
                throw new Error('Monnify SDK not available');
            }

            (window as any).MonnifySDK.initialize({
                amount: options.amount,
                currency: options.currency || 'NGN',
                reference: options.ref,
                customerName: options.name || 'Customer',
                customerEmail: options.email,
                apiKey: PUBLIC_MONNIFY_API_KEY,
                contractCode: options.contractCode || PUBLIC_MONNIFY_CONTRACT_CODE, 
                paymentDescription: options.description || 'Order Payment',
                paymentMethods: ['CARD', 'ACCOUNT_TRANSFER', 'ACCOUNT', 'USSD'],
                metadata: options.metadata || {},
                onComplete: (response: any) => {
                    if (response.paymentStatus === 'PAID' || response.status === 'SUCCESS') {
                        options.onSuccess(response);
                    } else {
                        console.warn('Monnify payment not successful:', response);
                    }
                },
                onClose: (data: any) => {
                    options.onClose();
                }
            });
        } catch (error) {
            console.error('Monnify Error:', error);
            throw error;
        }
    }
}

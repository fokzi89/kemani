/**
 * SMS Provider for sending OTP codes
 * Using Termii API for Nigeria
 */

interface SendSMSParams {
    to: string; // Phone number in E.164 format
    message: string;
}

interface SendSMSResponse {
    success: boolean;
    messageId?: string;
    error?: string;
}

/**
 * Send SMS via Termii
 */
export async function sendSMS({ to, message }: SendSMSParams): Promise<SendSMSResponse> {
    const apiKey = process.env.TERMII_API_KEY;
    const senderId = process.env.TERMII_SENDER_ID || 'Kemani';

    if (!apiKey) {
        console.error('TERMII_API_KEY not configured');
        return { success: false, error: 'SMS service not configured' };
    }

    try {
        const response = await fetch('https://api.ng.termii.com/api/sms/send', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                to: to.replace('+', ''), // Termii expects without +
                from: senderId,
                sms: message,
                type: 'plain',
                channel: 'generic',
                api_key: apiKey,
            }),
        });

        const data = await response.json();

        if (response.ok && data.message_id) {
            return {
                success: true,
                messageId: data.message_id,
            };
        }

        return {
            success: false,
            error: data.message || 'Failed to send SMS',
        };
    } catch (error) {
        console.error('SMS sending error:', error);
        return {
            success: false,
            error: 'Failed to send SMS',
        };
    }
}

/**
 * Send OTP via SMS
 */
export async function sendOTPSMS(phone: string, otp: string): Promise<SendSMSResponse> {
    const message = `Your Kemani verification code is: ${otp}. Valid for 5 minutes. Do not share this code.`;

    return sendSMS({
        to: phone,
        message,
    });
}

/**
 * Send welcome SMS
 */
export async function sendWelcomeSMS(phone: string, businessName: string): Promise<SendSMSResponse> {
    const message = `Welcome to Kemani POS, ${businessName}! Your account is ready. Login at kemani.app`;

    return sendSMS({
        to: phone,
        message,
    });
}

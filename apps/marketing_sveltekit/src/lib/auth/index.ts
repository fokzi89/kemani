import { parsePhoneNumber, isValidPhoneNumber } from 'libphonenumber-js';

/**
 * Validates and formats a phone number for Nigeria
 */
export function validatePhone(phone: string): { valid: boolean; formatted?: string; error?: string } {
    try {
        // Remove all non-numeric characters except +
        const cleaned = phone.replace(/[^\d+]/g, '');

        // Check if it's a valid phone number
        if (!isValidPhoneNumber(cleaned, 'NG')) {
            return { valid: false, error: 'Invalid phone number format' };
        }

        // Parse and format
        const phoneNumber = parsePhoneNumber(cleaned, 'NG');
        return {
            valid: true,
            formatted: phoneNumber.format('E.164') // Returns +234XXXXXXXXXX
        };
    } catch (error) {
        return { valid: false, error: 'Invalid phone number' };
    }
}

/**
 * Validates email format
 */
export function validateEmail(email: string): { valid: boolean; error?: string } {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!emailRegex.test(email)) {
        return { valid: false, error: 'Invalid email format' };
    }

    return { valid: true };
}

/**
 * Generates a 6-digit OTP code
 */
export function generateOTP(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * Hash OTP for storage (simple hash, not for passwords)
 */
export async function hashOTP(otp: string): Promise<string> {
    const encoder = new TextEncoder();
    const data = encoder.encode(otp);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

/**
 * Verify OTP hash
 */
export async function verifyOTP(otp: string, hash: string): Promise<boolean> {
    const otpHash = await hashOTP(otp);
    return otpHash === hash;
}

/**
 * Format phone number for display (e.g., +234 803 123 4567)
 */
export function formatPhoneDisplay(phone: string): string {
    try {
        const phoneNumber = parsePhoneNumber(phone);
        return phoneNumber.formatInternational();
    } catch {
        return phone;
    }
}

/**
 * Check if OTP is expired (5 minutes)
 */
export function isOTPExpired(createdAt: Date): boolean {
    const now = new Date();
    const diff = now.getTime() - createdAt.getTime();
    const fiveMinutes = 5 * 60 * 1000;
    return diff > fiveMinutes;
}

/**
 * Sanitize user input
 */
export function sanitizeInput(input: string): string {
    return input.trim().toLowerCase();
}

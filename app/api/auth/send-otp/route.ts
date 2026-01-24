import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { validatePhone, validateEmail, generateOTP } from '@/lib/auth';
import { sendOTPSMS } from '@/lib/auth/sms';

// In-memory rate limiting (use Redis in production)
const otpAttempts = new Map<string, { count: number; resetAt: number }>();

function checkRateLimit(identifier: string): boolean {
    const now = Date.now();
    const attempt = otpAttempts.get(identifier);

    if (!attempt || now > attempt.resetAt) {
        otpAttempts.set(identifier, { count: 1, resetAt: now + 3600000 }); // 1 hour
        return true;
    }

    if (attempt.count >= 3) {
        return false;
    }

    attempt.count++;
    return true;
}

export async function POST(request: NextRequest) {
    try {
        const { identifier, type } = await request.json();

        if (!identifier || !type) {
            return NextResponse.json(
                { error: 'Missing required fields' },
                { status: 400 }
            );
        }

        // Validate based on type
        let formattedIdentifier = identifier;

        if (type === 'phone') {
            const phoneValidation = validatePhone(identifier);
            if (!phoneValidation.valid) {
                return NextResponse.json(
                    { error: phoneValidation.error },
                    { status: 400 }
                );
            }
            formattedIdentifier = phoneValidation.formatted!;
        } else if (type === 'email') {
            const emailValidation = validateEmail(identifier);
            if (!emailValidation.valid) {
                return NextResponse.json(
                    { error: emailValidation.error },
                    { status: 400 }
                );
            }
            formattedIdentifier = identifier.toLowerCase().trim();
        } else {
            return NextResponse.json(
                { error: 'Invalid type. Must be "phone" or "email"' },
                { status: 400 }
            );
        }

        // Check rate limit
        if (!checkRateLimit(formattedIdentifier)) {
            return NextResponse.json(
                { error: 'Too many attempts. Please try again in 1 hour.' },
                { status: 429 }
            );
        }

        // Generate OTP
        const otp = generateOTP();

        const supabase = await createClient();

        // Send OTP based on type
        if (type === 'phone') {
            const smsResult = await sendOTPSMS(formattedIdentifier, otp);

            if (!smsResult.success) {
                return NextResponse.json(
                    { error: 'Failed to send OTP. Please try again.' },
                    { status: 500 }
                );
            }

            // Use Supabase Auth for phone OTP
            const { error } = await supabase.auth.signInWithOtp({
                phone: formattedIdentifier,
                options: {
                    channel: 'sms',
                },
            });

            if (error) {
                console.error('Supabase OTP error:', error);
                return NextResponse.json(
                    { error: 'Failed to send OTP' },
                    { status: 500 }
                );
            }
        } else {
            // Use Supabase Auth for email OTP
            const { error } = await supabase.auth.signInWithOtp({
                email: formattedIdentifier,
                options: {
                    shouldCreateUser: true,
                },
            });

            if (error) {
                console.error('Supabase OTP error:', error);
                return NextResponse.json(
                    { error: error.message || 'Failed to send OTP' },
                    { status: error.status || 500 }
                );
            }
        }

        return NextResponse.json({
            success: true,
            message: `OTP sent to ${type === 'phone' ? 'your phone' : 'your email'}`,
            identifier: formattedIdentifier,
        });
    } catch (error) {
        console.error('Send OTP error:', error);
        return NextResponse.json(
            { error: 'Internal server error' },
            { status: 500 }
        );
    }
}

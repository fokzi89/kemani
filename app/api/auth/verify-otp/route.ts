import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function POST(request: NextRequest) {
    try {
        const { identifier, otp, type } = await request.json();

        if (!identifier || !otp || !type) {
            return NextResponse.json(
                { error: 'Missing required fields' },
                { status: 400 }
            );
        }

        const supabase = await createClient();

        // Verify OTP with Supabase
        const { data, error } = await supabase.auth.verifyOtp({
            [type]: identifier,
            token: otp,
            type: type === 'phone' ? 'sms' : 'email',
        });

        if (error) {
            console.error('OTP verification error:', error);
            return NextResponse.json(
                { error: 'Invalid or expired OTP' },
                { status: 400 }
            );
        }

        if (!data.user) {
            return NextResponse.json(
                { error: 'Verification failed' },
                { status: 400 }
            );
        }

        // Check if user exists in our users table
        const { data: existingUser } = await supabase
            .from('users')
            .select('*')
            .eq('id', data.user.id)
            .single();

        // If user doesn't exist, they need to complete registration
        if (!existingUser) {
            return NextResponse.json({
                success: true,
                needsRegistration: true,
                userId: data.user.id,
                identifier,
                type,
            });
        }

        // User exists, return success
        return NextResponse.json({
            success: true,
            needsRegistration: false,
            user: {
                id: existingUser.id,
                email: existingUser.email,
                phone: existingUser.phone,
                fullName: existingUser.full_name,
                role: existingUser.role,
                tenantId: existingUser.tenant_id,
            },
        });
    } catch (error) {
        console.error('Verify OTP error:', error);
        return NextResponse.json(
            { error: 'Internal server error' },
            { status: 500 }
        );
    }
}

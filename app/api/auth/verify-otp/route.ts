import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/client';

export async function POST(request: NextRequest) {
  try {
    const { identifier, otp, channel } = await request.json();

    if (!identifier || !otp || !channel) {
      return NextResponse.json(
        { error: 'Identifier, OTP, and channel are required' },
        { status: 400 }
      );
    }

    // For email OTP, Supabase Auth handles verification
    // When user enters OTP, we verify and create session
    const supabase = createClient();

    // Verify the OTP token with Supabase
    const { data: authData, error: verifyError } = await supabase.auth.verifyOtp({
      email: identifier,
      token: otp,
      type: 'email',
    });

    if (verifyError) {
      return NextResponse.json(
        { error: verifyError.message || 'Invalid or expired OTP' },
        { status: 401 }
      );
    }

    // After successful auth, check if user exists in our users table
    if (authData.session) {
      const { data: existingUser } = await supabase
        .from('users')
        .select('id, tenant_id')
        .eq('id', authData.session.user.id)
        .maybeSingle();

      if (!existingUser) {
        // New user - needs to complete registration
        return NextResponse.json({
          success: true,
          needsRegistration: true,
          message: 'OTP verified. Please complete registration.',
          session: authData.session,
        });
      }

      // Existing user - login successful
      return NextResponse.json({
        success: true,
        needsRegistration: false,
        message: 'Login successful',
        session: authData.session,
      });
    }

    return NextResponse.json(
      { error: 'Failed to create session' },
      { status: 500 }
    );
  } catch (error: any) {
    console.error('Verify OTP error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to verify OTP' },
      { status: 500 }
    );
  }
}

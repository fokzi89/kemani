import { NextRequest, NextResponse } from 'next/server';
import { verifyOTP } from '@/lib/auth/otp';
import { UserService } from '@/lib/auth/user';
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

    // Verify OTP
    const isValid = await verifyOTP(identifier, otp, channel);

    if (!isValid) {
      return NextResponse.json(
        { error: 'Invalid or expired OTP' },
        { status: 401 }
      );
    }

    // OTP is valid - sign in the user
    const supabase = createClient();

    let authData;

    if (channel === 'email') {
      const { data, error } = await supabase.auth.signInWithOtp({
        email: identifier,
        options: {
          shouldCreateUser: true, // Allow new users
        },
      });

      if (error) throw error;
      authData = data;
    } else if (channel === 'sms') {
      const { data, error } = await supabase.auth.signInWithOtp({
        phone: identifier,
        options: {
          shouldCreateUser: true,
        },
      });

      if (error) throw error;
      authData = data;
    } else {
      return NextResponse.json(
        { error: 'Invalid channel' },
        { status: 400 }
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

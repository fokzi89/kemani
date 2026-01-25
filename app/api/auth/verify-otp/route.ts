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

    if (channel === 'email') {
      const { data, error } = await supabase.auth.signInWithOtp({
        email: identifier,
        options: {
          shouldCreateUser: false, // Only allow existing users to login
        },
      });

      if (error) throw error;

      return NextResponse.json({
        success: true,
        message: 'OTP verified successfully',
        session: data.session,
      });
    } else if (channel === 'sms') {
      const { data, error } = await supabase.auth.signInWithOtp({
        phone: identifier,
        options: {
          shouldCreateUser: false,
        },
      });

      if (error) throw error;

      return NextResponse.json({
        success: true,
        message: 'OTP verified successfully',
        session: data.session,
      });
    }

    return NextResponse.json(
      { error: 'Invalid channel' },
      { status: 400 }
    );
  } catch (error: any) {
    console.error('Verify OTP error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to verify OTP' },
      { status: 500 }
    );
  }
}

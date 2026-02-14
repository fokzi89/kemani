import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function POST(request: NextRequest) {
  try {
    const { identifier, channel } = await request.json();

    if (!identifier) {
      return NextResponse.json(
        { error: 'Email identifier is required' },
        { status: 400 }
      );
    }

    // Enforce Email only
    if (channel && channel !== 'email') {
      return NextResponse.json(
        { error: 'Only email authentication is supported' },
        { status: 400 }
      );
    }

    const supabase = await createClient();

    // Send generic email OTP using Supabase
    const { error } = await supabase.auth.signInWithOtp({
      email: identifier,
      options: {
        shouldCreateUser: false, // Only allow existing users to login? Or auto-signup? 
        // Spec implies public registration via "Start Free" (which uses register page). 
        // But for Login (otp), usually we want to check existence.
        // However, standard magic link login usually supports auto-signup if configured.
        // Let's set true to be safe for now, as Registration flow might use this too.
        shouldCreateUser: true,
      },
    });

    if (error) {
      return NextResponse.json(
        { error: error.message },
        { status: 400 }
      );
    }

    return NextResponse.json({
      success: true,
      message: `OTP sent to ${identifier}`,
    });
  } catch (error: any) {
    console.error('Send OTP error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to send OTP' },
      { status: 500 }
    );
  }
}

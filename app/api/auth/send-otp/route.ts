import { NextRequest, NextResponse } from 'next/server';
import { sendOTP } from '@/lib/auth/otp';

export async function POST(request: NextRequest) {
  try {
    const { identifier, channel } = await request.json();

    if (!identifier || !channel) {
      return NextResponse.json(
        { error: 'Identifier and channel are required' },
        { status: 400 }
      );
    }

    // Validate channel
    if (!['sms', 'email'].includes(channel)) {
      return NextResponse.json(
        { error: 'Invalid channel. Must be sms or email' },
        { status: 400 }
      );
    }

    // Send OTP using the existing OTP service
    await sendOTP(identifier, channel);

    return NextResponse.json({
      success: true,
      message: `OTP sent to ${identifier} via ${channel}`,
    });
  } catch (error: any) {
    console.error('Send OTP error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to send OTP' },
      { status: 500 }
    );
  }
}

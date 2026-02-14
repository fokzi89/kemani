import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function POST(request: NextRequest) {
  try {
    const { passcode } = await request.json();

    if (!passcode) {
      return NextResponse.json(
        { error: 'Passcode is required' },
        { status: 400 }
      );
    }

    // Validate passcode format (6 digits)
    if (passcode.length !== 6 || !/^\d{6}$/.test(passcode)) {
      return NextResponse.json(
        { error: 'Passcode must be exactly 6 digits' },
        { status: 400 }
      );
    }

    const supabase = await createClient();

    // Get current user
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // Store passcode in users table
    // Note: In production, use proper hashing (bcrypt/argon2)
    // For now, storing as plain text for MVP - TODO: Add hashing
    const { error: updateError } = await supabase
      .from('users')
      .update({ passcode_hash: passcode })
      .eq('id', user.id);

    if (updateError) {
      console.error('Failed to save passcode:', updateError);
      return NextResponse.json(
        { error: 'Failed to save passcode' },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      message: 'Passcode set successfully',
    });
  } catch (error: any) {
    console.error('Setup passcode error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to set up passcode' },
      { status: 500 }
    );
  }
}

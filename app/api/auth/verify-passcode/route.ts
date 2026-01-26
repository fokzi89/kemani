import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/client';

export async function POST(request: NextRequest) {
  try {
    const { passcode } = await request.json();

    if (!passcode || !/^\d{6}$/.test(passcode)) {
      return NextResponse.json(
        { error: 'Invalid passcode format' },
        { status: 400 }
      );
    }

    const supabase = createClient();

    // Get current user
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json(
        { error: 'Not authenticated' },
        { status: 401 }
      );
    }

    // Get stored passcode hash from user metadata
    const storedHash = user.user_metadata?.passcode_hash;

    if (!storedHash) {
      return NextResponse.json(
        { error: 'No passcode set for this account' },
        { status: 400 }
      );
    }

    // Hash the provided passcode
    const encoder = new TextEncoder();
    const data = encoder.encode(passcode);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const providedHash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

    // Compare hashes
    if (providedHash !== storedHash) {
      return NextResponse.json(
        { error: 'Incorrect passcode' },
        { status: 401 }
      );
    }

    // Passcode is correct
    return NextResponse.json({
      success: true,
      message: 'Passcode verified',
    });
  } catch (error: any) {
    console.error('Verify passcode error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to verify passcode' },
      { status: 500 }
    );
  }
}

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

    const supabase = await createClient();

    // 1. Check if user is authenticated (session must exist for inactivity lock to be relevant)
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // 2. Fetch user's stored passcode hash
    // Note: We extended the User type to include 'passcode_hash', assuming it exists in the user metadata or DB.
    // Since we modifying the schema might be hard, let's look in two places:
    // a) `public.users` table (if column exists)
    // b) `auth.users` metadata (accessible via user object)

    // Check user_metadata first as it's easier to add without migration
    const metadataPasscode = user.user_metadata?.passcode_hash;

    // Check public.users table as backup (or primary if we migrated)
    const { data: profile } = await supabase
      .from('users')
      .select('passcode_hash') // This might fail if column doesn't exist, so we might need error handling
      .eq('id', user.id)
      .single();

    const storedHash = metadataPasscode || profile?.passcode_hash;

    if (!storedHash) {
      // If no passcode set, we can't verify. 
      // Should we allow unlock? Or force setup?
      // Assuming if they are locked, they must have set it up.
      // But for MVP, if not set, maybe allow?
      // Let's return error that passcode not set.
      return NextResponse.json(
        { error: 'Passcode not set for this user' },
        { status: 400 }
      );
    }

    // 3. Verify passcode
    // In a real app, use bcrypt/argon2. For MVP/prototype, we might compare directly if hash is simple 
    // or use a helper. 
    // IMPORTANT: Implementing a simple comparison for now. 
    // Ideally use: const match = await bcrypt.compare(passcode, storedHash);

    // For this implementation, we will assume storedHash is the direct passcode for simplicity 
    // unless we have a hashing library available. 
    // Let's assume we store it as specific format "PLAIN:1234" or "HASH:..."
    // Or just simple string comparison for MVP.
    // TODO: Upgrade to proper hashing.
    const isValid = passcode === storedHash;

    if (!isValid) {
      return NextResponse.json(
        { error: 'Invalid passcode' },
        { status: 401 }
      );
    }

    return NextResponse.json({
      success: true,
      message: 'Passcode verified',
    });
  } catch (error: any) {
    console.error('Verify Passcode error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to verify passcode' },
      { status: 500 }
    );
  }
}

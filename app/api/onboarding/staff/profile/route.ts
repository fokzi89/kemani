import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

/**
 * POST /api/onboarding/staff/profile
 * Save staff profile information during onboarding
 * Requires: full_name, phone_number (optional: profile_picture_url, gender)
 */
export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient();

    // Get authenticated user
    const {
      data: { user: authUser },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !authUser) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Parse request body
    const body = await request.json();
    const { fullName, phoneNumber, gender, profilePictureUrl } = body;

    // Validate required fields
    if (!fullName) {
      return NextResponse.json(
        { error: 'Full name is required' },
        { status: 400 }
      );
    }

    // Get user from DB to verify staff member
    const { data: dbUser, error: userError } = await supabase
      .from('users')
      .select('role, tenant_id, onboarding_completed_at')
      .eq('id', authUser.id)
      .single();

    if (userError || !dbUser) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    // Verify user is staff (not tenant_admin who should use owner onboarding)
    if (dbUser.role === 'tenant_admin') {
      return NextResponse.json(
        { error: 'Please use the owner onboarding flow' },
        { status: 400 }
      );
    }

    // Verify user has tenant (from invitation)
    if (!dbUser.tenant_id) {
      return NextResponse.json(
        { error: 'User not associated with a tenant' },
        { status: 400 }
      );
    }

    // Update user profile
    const updates: any = {
      full_name: fullName,
      updated_at: new Date().toISOString(),
    };

    if (phoneNumber) updates.phone_number = phoneNumber;
    if (gender) updates.gender = gender;
    if (profilePictureUrl) updates.profile_picture_url = profilePictureUrl;

    // Mark onboarding as complete for staff
    updates.onboarding_completed_at = new Date().toISOString();

    const { data, error } = await supabase
      .from('users')
      .update(updates)
      .eq('id', authUser.id)
      .select()
      .single();

    if (error) {
      console.error('Profile update error:', error);
      return NextResponse.json(
        { error: error.message || 'Failed to save profile' },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      data,
    });
  } catch (error: any) {
    console.error('Unexpected error in staff profile save:', error);
    return NextResponse.json(
      { error: error.message || 'Unexpected error saving profile' },
      { status: 500 }
    );
  }
}

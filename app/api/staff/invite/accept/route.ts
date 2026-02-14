import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/server';
import { UserInsert } from '@/lib/types/database';

export async function POST(request: NextRequest) {
  try {
    const { invitationToken, password } = await request.json();

    if (!invitationToken) {
      return NextResponse.json(
        { error: 'Invitation token is required' },
        { status: 400 }
      );
    }

    if (!password || password.length < 8) {
      return NextResponse.json(
        { error: 'Password must be at least 8 characters' },
        { status: 400 }
      );
    }

    const supabase = await createAdminClient();

    // Get the invitation
    const { data: invitation, error: fetchError } = await supabase
      .from('staff_invitations')
      .select('*')
      .eq('invitation_token', invitationToken)
      .single();

    if (fetchError || !invitation) {
      return NextResponse.json(
        { error: 'Invalid invitation token' },
        { status: 404 }
      );
    }

    // Check invitation status
    if (invitation.status !== 'pending') {
      return NextResponse.json(
        { error: `This invitation has been ${invitation.status}` },
        { status: 400 }
      );
    }

    // Check if expired
    const now = new Date();
    const expiresAt = new Date(invitation.expires_at);

    if (now > expiresAt) {
      // Mark as expired
      await supabase
        .from('staff_invitations')
        .update({ status: 'expired' })
        .eq('id', invitation.id);

      return NextResponse.json(
        { error: 'This invitation has expired' },
        { status: 400 }
      );
    }

    // Check if user already exists
    const { data: existingUsers } = await supabase.auth.admin.listUsers();
    const userExists = existingUsers?.users.some((u) => u.email === invitation.email);

    if (userExists) {
      return NextResponse.json(
        { error: 'This email is already registered' },
        { status: 400 }
      );
    }

    // Create auth user with password
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: invitation.email,
      password: password,
      email_confirm: true, // Auto-confirm email since invitation was verified
      user_metadata: {
        full_name: invitation.full_name,
        tenant_id: invitation.tenant_id,
        role: invitation.role,
      },
    });

    if (authError) {
      console.error('Auth user creation error:', authError);
      return NextResponse.json(
        { error: 'Failed to create user account' },
        { status: 500 }
      );
    }

    if (!authData.user) {
      return NextResponse.json(
        { error: 'Failed to create user account' },
        { status: 500 }
      );
    }

    const userId = authData.user.id;

    // Create user record
    const userData: UserInsert = {
      id: userId,
      full_name: invitation.full_name,
      email: invitation.email,
      role: invitation.role,
      tenant_id: invitation.tenant_id,
      branch_id: invitation.branch_id,
    };

    const { error: userError } = await supabase
      .from('users')
      .insert(userData);

    if (userError) {
      console.error('User record creation error:', userError);
      // Rollback: Delete auth user
      await supabase.auth.admin.deleteUser(userId);
      return NextResponse.json(
        { error: 'Failed to create user profile' },
        { status: 500 }
      );
    }

    // Mark invitation as accepted
    const { error: updateError } = await supabase
      .from('staff_invitations')
      .update({
        status: 'accepted',
        accepted_at: new Date().toISOString(),
      })
      .eq('id', invitation.id);

    if (updateError) {
      console.error('Invitation update error:', updateError);
      // Continue anyway - user is created
    }

    // Sign in the user automatically
    const { data: sessionData, error: signInError } = await supabase.auth.signInWithPassword({
      email: invitation.email,
      password: password,
    });

    if (signInError) {
      console.error('Auto sign-in error:', signInError);
      // User created but not signed in - redirect to login
      return NextResponse.json({
        success: true,
        message: 'Account created! Please sign in to continue.',
        redirectTo: '/login',
      });
    }

    // Success - redirect to staff profile setup
    return NextResponse.json({
      success: true,
      message: 'Account created successfully!',
      redirectTo: '/onboarding/staff/profile',
    });
  } catch (error: any) {
    console.error('Accept invitation error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to accept invitation' },
      { status: 500 }
    );
  }
}

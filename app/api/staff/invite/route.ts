import { NextRequest, NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';
import { EmailService } from '@/lib/integrations/resend';
import { UserService } from '@/lib/auth/user';
import { UserRole } from '@/lib/types/database';
import crypto from 'crypto';

// GET - Get all invitations for the current tenant
export async function GET(request: NextRequest) {
  try {
    const supabase = await createClient();

    // Get current user
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const currentUser = await UserService.getUser(user.id);
    if (!currentUser.tenant_id) {
      return NextResponse.json(
        { error: 'User not associated with a tenant' },
        { status: 403 }
      );
    }

    // Get all invitations for this tenant
    const { data: invitations, error } = await supabase
      .from('staff_invitations')
      .select('*')
      .eq('tenant_id', currentUser.tenant_id)
      .order('created_at', { ascending: false });

    if (error) throw error;

    return NextResponse.json({ invitations });
  } catch (error: any) {
    console.error('Get invitations error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to fetch invitations' },
      { status: 500 }
    );
  }
}

// POST - Create and send a new staff invitation
export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient();

    // Get current user
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const currentUser = await UserService.getUser(user.id);

    // Only tenant admins can send invitations
    if (!['tenant_admin', 'platform_admin'].includes(currentUser.role)) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      );
    }

    if (!currentUser.tenant_id) {
      return NextResponse.json(
        { error: 'User not associated with a tenant' },
        { status: 403 }
      );
    }

    const { email, fullName, role, branchId } = await request.json();

    // Validate inputs
    if (!email || !fullName || !role) {
      return NextResponse.json(
        { error: 'Email, full name, and role are required' },
        { status: 400 }
      );
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return NextResponse.json(
        { error: 'Please provide a valid email address' },
        { status: 400 }
      );
    }

    // Check if email is already registered
    const adminSupabase = await createAdminClient();
    const { data: existingUser } = await adminSupabase.auth.admin.listUsers();
    const userExists = existingUser?.users.some((u) => u.email === email);

    if (userExists) {
      return NextResponse.json(
        { error: 'This email is already registered' },
        { status: 400 }
      );
    }

    // Check if there's an active invitation for this email
    const { data: existingInvitation } = await supabase
      .from('staff_invitations')
      .select('id')
      .eq('email', email)
      .eq('tenant_id', currentUser.tenant_id)
      .eq('status', 'pending')
      .maybeSingle();

    if (existingInvitation) {
      return NextResponse.json(
        { error: 'An active invitation already exists for this email' },
        { status: 400 }
      );
    }

    // Generate unique invitation token
    const invitationToken = crypto.randomBytes(32).toString('hex');

    // Get tenant details for email
    const { data: tenant } = await supabase
      .from('tenants')
      .select('name')
      .eq('id', currentUser.tenant_id)
      .single();

    // Create invitation record
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days from now

    const { data: invitation, error: invitationError } = await supabase
      .from('staff_invitations')
      .insert({
        tenant_id: currentUser.tenant_id,
        email: email,
        full_name: fullName,
        role: role as UserRole,
        branch_id: branchId || null,
        invited_by: currentUser.id,
        invitation_token: invitationToken,
        expires_at: expiresAt.toISOString(),
      })
      .select()
      .single();

    if (invitationError) throw invitationError;

    // Send invitation email
    try {
      const invitationUrl = `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/accept-invitation/${invitationToken}`;

      await EmailService.sendStaffInvitation(email, {
        businessName: tenant?.name || 'Kemani POS',
        staffName: fullName,
        role: role,
        invitationUrl: invitationUrl,
        expiresAt: expiresAt.toISOString(),
        invitedBy: currentUser.full_name,
      });

      return NextResponse.json({
        success: true,
        message: 'Invitation sent successfully',
        invitation,
      });
    } catch (emailError) {
      console.error('Failed to send invitation email:', emailError);

      // Delete the invitation if email fails
      await supabase
        .from('staff_invitations')
        .delete()
        .eq('id', invitation.id);

      return NextResponse.json(
        { error: 'Failed to send invitation email. Please check your email configuration.' },
        { status: 500 }
      );
    }
  } catch (error: any) {
    console.error('Create invitation error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to create invitation' },
      { status: 500 }
    );
  }
}

// PUT - Resend or revoke an invitation
export async function PUT(request: NextRequest) {
  try {
    const supabase = await createClient();

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const currentUser = await UserService.getUser(user.id);

    // Only tenant admins can manage invitations
    if (!['tenant_admin', 'platform_admin'].includes(currentUser.role)) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      );
    }

    const { invitationId, action } = await request.json();

    if (!invitationId || !action) {
      return NextResponse.json(
        { error: 'Invitation ID and action are required' },
        { status: 400 }
      );
    }

    // Get the invitation
    const { data: invitation, error: fetchError } = await supabase
      .from('staff_invitations')
      .select('*, tenants(name)')
      .eq('id', invitationId)
      .eq('tenant_id', currentUser.tenant_id)
      .single();

    if (fetchError || !invitation) {
      return NextResponse.json(
        { error: 'Invitation not found' },
        { status: 404 }
      );
    }

    if (action === 'resend') {
      // Resend the invitation email
      try {
        const invitationUrl = `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/accept-invitation/${invitation.invitation_token}`;

        await EmailService.sendStaffInvitation(invitation.email, {
          businessName: (invitation.tenants as any)?.name || 'Kemani POS',
          staffName: invitation.full_name,
          role: invitation.role,
          invitationUrl: invitationUrl,
          expiresAt: invitation.expires_at,
          invitedBy: currentUser.full_name,
        });

        return NextResponse.json({
          success: true,
          message: 'Invitation resent successfully',
        });
      } catch (emailError) {
        console.error('Failed to resend invitation:', emailError);
        return NextResponse.json(
          { error: 'Failed to resend invitation email' },
          { status: 500 }
        );
      }
    } else if (action === 'revoke') {
      // Revoke the invitation
      const { error: updateError } = await supabase
        .from('staff_invitations')
        .update({ status: 'revoked' })
        .eq('id', invitationId);

      if (updateError) throw updateError;

      return NextResponse.json({
        success: true,
        message: 'Invitation revoked successfully',
      });
    } else {
      return NextResponse.json(
        { error: 'Invalid action. Use "resend" or "revoke"' },
        { status: 400 }
      );
    }
  } catch (error: any) {
    console.error('Update invitation error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to update invitation' },
      { status: 500 }
    );
  }
}

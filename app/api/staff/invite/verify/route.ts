import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/server';

/**
 * GET /api/staff/invite/verify?token=...
 * Verify an invitation token and return invitation details
 */
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const token = searchParams.get('token');

    if (!token) {
      return NextResponse.json(
        { error: 'Invitation token is required' },
        { status: 400 }
      );
    }

    const supabase = await createAdminClient();

    // Get the invitation
    const { data: invitation, error: fetchError } = await supabase
      .from('staff_invitations')
      .select('*, tenants(name)')
      .eq('invitation_token', token)
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

    // Return invitation details (without sensitive data)
    return NextResponse.json({
      email: invitation.email,
      fullName: invitation.full_name,
      role: invitation.role,
      tenantName: (invitation.tenants as any)?.name || 'Kemani POS',
    });
  } catch (error: any) {
    console.error('Verify invitation error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to verify invitation' },
      { status: 500 }
    );
  }
}

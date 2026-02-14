import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { EmailService } from '@/lib/integrations/resend';
import crypto from 'crypto';

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient();

    // Get authenticated user
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
    }

    // Get user's tenant
    const { data: currentUser } = await supabase
      .from('users')
      .select('tenant_id, full_name, tenants(name)')
      .eq('id', user.id)
      .single();

    if (!currentUser || !currentUser.tenant_id) {
      return NextResponse.json(
        { error: 'User not associated with a tenant' },
        { status: 403 }
      );
    }

    const { staffList } = await request.json();

    if (!Array.isArray(staffList) || staffList.length === 0) {
      return NextResponse.json(
        { error: 'No staff members provided' },
        { status: 400 }
      );
    }

    // Get default branch
    const { data: defaultBranch } = await supabase
      .from('branches')
      .select('id')
      .eq('tenant_id', currentUser.tenant_id)
      .limit(1)
      .single();

    const invitationResults = [];

    // Create invitations for each staff member
    for (const staff of staffList) {
      try {
        // Generate invitation token
        const invitationToken = crypto.randomBytes(32).toString('hex');
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + 7); // 7 days from now

        // Create invitation
        const { data: invitation, error: invitationError } = await supabase
          .from('staff_invitations')
          .insert({
            tenant_id: currentUser.tenant_id,
            email: staff.email,
            full_name: staff.fullName,
            role: staff.role,
            branch_id: defaultBranch?.id || null,
            invited_by: user.id,
            invitation_token: invitationToken,
            expires_at: expiresAt.toISOString(),
          })
          .select()
          .single();

        if (invitationError) {
          console.error('Invitation creation error:', invitationError);
          invitationResults.push({
            email: staff.email,
            success: false,
            error: 'Failed to create invitation',
          });
          continue;
        }

        // Send invitation email
        try {
          const invitationUrl = `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/accept-invitation/${invitationToken}`;

          await EmailService.sendStaffInvitation(staff.email, {
            businessName: (currentUser.tenants as any)?.name || 'Kemani POS',
            staffName: staff.fullName,
            role: staff.role,
            invitationUrl: invitationUrl,
            expiresAt: expiresAt.toISOString(),
            invitedBy: currentUser.full_name,
          });

          invitationResults.push({
            email: staff.email,
            success: true,
          });
        } catch (emailError) {
          console.error('Email send error:', emailError);
          // Delete the invitation if email fails
          await supabase
            .from('staff_invitations')
            .delete()
            .eq('id', invitation.id);

          invitationResults.push({
            email: staff.email,
            success: false,
            error: 'Failed to send email',
          });
        }
      } catch (error: any) {
        console.error('Staff invitation error:', error);
        invitationResults.push({
          email: staff.email,
          success: false,
          error: error.message,
        });
      }
    }

    const successCount = invitationResults.filter((r) => r.success).length;
    const failureCount = invitationResults.filter((r) => !r.success).length;

    return NextResponse.json({
      success: true,
      message: `${successCount} invitation(s) sent successfully${failureCount > 0 ? `, ${failureCount} failed` : ''}`,
      results: invitationResults,
    });
  } catch (error: any) {
    console.error('Staff setup error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to add staff' },
      { status: 500 }
    );
  }
}

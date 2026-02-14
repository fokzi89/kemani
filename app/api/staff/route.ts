import { NextRequest, NextResponse } from 'next/server';
import { UserService } from '@/lib/auth/user';
import { UserInvite, UserUpdate } from '@/lib/types/database';
import { createClient } from '@/lib/supabase/client';

// GET - Get all staff for a tenant
export async function GET(request: NextRequest) {
  try {
    const supabase = createClient();

    // Get current user to check permissions
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // Get user's tenant ID
    const currentUser = await UserService.getUser(user.id);

    if (!currentUser.tenant_id) {
      return NextResponse.json(
        { error: 'User not associated with a tenant' },
        { status: 403 }
      );
    }

    // Get all users for the tenant
    const users = await UserService.getUsersByTenant(currentUser.tenant_id);

    return NextResponse.json({ users });
  } catch (error: any) {
    console.error('Get staff error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to get staff' },
      { status: 500 }
    );
  }
}

// POST - Create new staff member
export async function POST(request: NextRequest) {
  try {
    const supabase = createClient();

    // Get current user to check permissions
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // Get user details and check role
    const currentUser = await UserService.getUser(user.id);

    if (!currentUser.tenant_id) {
      return NextResponse.json(
        { error: 'User not associated with a tenant' },
        { status: 403 }
      );
    }

    // Only tenant admins and platform admins can create staff
    if (!['tenant_admin', 'platform_admin'].includes(currentUser.role)) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      );
    }

    const invite: UserInvite = await request.json();

    // Validate required fields
    if (!invite.fullName || !invite.role) {
      return NextResponse.json(
        { error: 'Full name and role are required' },
        { status: 400 }
      );
    }

    // Verify email is provided (required for Email OTP)
    if (!invite.email) {
      return NextResponse.json(
        { error: 'Email is required for staff invitations' },
        { status: 400 }
      );
    }

    // Create user
    const result = await UserService.createUser(invite, currentUser.tenant_id);

    return NextResponse.json(result, { status: 201 });
  } catch (error: any) {
    console.error('Create staff error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to create staff' },
      { status: 500 }
    );
  }
}

// PUT - Update staff member
export async function PUT(request: NextRequest) {
  try {
    const supabase = createClient();

    // Get current user to check permissions
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    const currentUser = await UserService.getUser(user.id);

    // Only tenant admins and platform admins can update staff
    if (!['tenant_admin', 'platform_admin'].includes(currentUser.role)) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      );
    }

    const { userId, updates }: { userId: string; updates: UserUpdate } = await request.json();

    if (!userId) {
      return NextResponse.json(
        { error: 'User ID is required' },
        { status: 400 }
      );
    }

    const updatedUser = await UserService.updateUser(userId, updates);

    return NextResponse.json({ user: updatedUser });
  } catch (error: any) {
    console.error('Update staff error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to update staff' },
      { status: 500 }
    );
  }
}

// DELETE - Soft delete staff member
export async function DELETE(request: NextRequest) {
  try {
    const supabase = createClient();

    // Get current user to check permissions
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    const currentUser = await UserService.getUser(user.id);

    // Only tenant admins and platform admins can delete staff
    if (!['tenant_admin', 'platform_admin'].includes(currentUser.role)) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      );
    }

    const { searchParams } = new URL(request.url);
    const userId = searchParams.get('userId');

    if (!userId) {
      return NextResponse.json(
        { error: 'User ID is required' },
        { status: 400 }
      );
    }

    await UserService.deleteUser(userId);

    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error('Delete staff error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to delete staff' },
      { status: 500 }
    );
  }
}

import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { uploadImage, updateImage } from '@/lib/storage/image-upload';
import { UserService } from '@/lib/auth/user';

/**
 * POST - Upload Company Logo
 * Handles company logo uploads during owner onboarding
 */
export async function POST(request: NextRequest) {
  try {
    // Check authentication
    const supabase = await createClient();
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Get current user to check permissions
    const currentUser = await UserService.getUser(user.id);

    // Only tenant admins can upload company logos
    if (!['tenant_admin', 'platform_admin'].includes(currentUser.role)) {
      return NextResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      );
    }

    // Get tenant ID from request or user profile
    const formData = await request.formData();
    const file = formData.get('file') as File;
    const tenantId = (formData.get('tenantId') as string) || currentUser.tenant_id;
    const oldImagePath = formData.get('oldImagePath') as string | null;

    if (!file) {
      return NextResponse.json({ error: 'No file provided' }, { status: 400 });
    }

    if (!tenantId) {
      return NextResponse.json(
        { error: 'Tenant ID is required' },
        { status: 400 }
      );
    }

    // Validate file is an image
    if (!file.type.startsWith('image/')) {
      return NextResponse.json(
        { error: 'File must be an image' },
        { status: 400 }
      );
    }

    // Upload or update image
    let uploadResult;
    if (oldImagePath) {
      uploadResult = await updateImage(
        oldImagePath,
        file,
        'logo',
        user.id,
        tenantId
      );
    } else {
      uploadResult = await uploadImage(file, 'logo', user.id, tenantId);
    }

    // Update tenant record with new logo URL
    const { error: updateError } = await supabase
      .from('tenants')
      .update({
        logo_url: uploadResult.publicUrl,
        updated_at: new Date().toISOString(),
      })
      .eq('id', tenantId);

    if (updateError) {
      console.error('Failed to update tenant logo:', updateError);
      return NextResponse.json(
        { error: 'Failed to update company logo' },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      url: uploadResult.publicUrl,
      path: uploadResult.path,
    });
  } catch (error: any) {
    console.error('Logo upload error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to upload logo' },
      { status: 500 }
    );
  }
}

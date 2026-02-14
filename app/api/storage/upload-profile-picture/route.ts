import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { uploadImage, updateImage } from '@/lib/storage/image-upload';

/**
 * POST - Upload Profile Picture
 * Handles profile picture uploads for owners and staff during onboarding
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

    // Get form data
    const formData = await request.formData();
    const file = formData.get('file') as File;
    const oldImagePath = formData.get('oldImagePath') as string | null;

    if (!file) {
      return NextResponse.json({ error: 'No file provided' }, { status: 400 });
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
      uploadResult = await updateImage(oldImagePath, file, 'profile', user.id);
    } else {
      uploadResult = await uploadImage(file, 'profile', user.id);
    }

    // Update user record with new profile picture URL
    const { error: updateError } = await supabase
      .from('users')
      .update({
        profile_picture_url: uploadResult.publicUrl,
        updated_at: new Date().toISOString(),
      })
      .eq('id', user.id);

    if (updateError) {
      console.error('Failed to update user profile picture:', updateError);
      return NextResponse.json(
        { error: 'Failed to update profile picture' },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      url: uploadResult.publicUrl,
      path: uploadResult.path,
    });
  } catch (error: any) {
    console.error('Profile picture upload error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to upload profile picture' },
      { status: 500 }
    );
  }
}

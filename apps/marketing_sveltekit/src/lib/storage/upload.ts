import { createClient } from '@/lib/supabase/client';

export type UploadType = 'profile-picture' | 'company-logo';

interface UploadOptions {
  file: File;
  userId: string;
  type: UploadType;
  tenantId?: string;
}

interface UploadResult {
  success: boolean;
  url?: string;
  error?: string;
}

/**
 * Upload an image to Supabase Storage
 * @param options Upload options including file, userId, and type
 * @returns Upload result with public URL or error
 */
export async function uploadImage(options: UploadOptions): Promise<UploadResult> {
  const { file, userId, type, tenantId } = options;
  const supabase = createClient();

  try {
    // Validate file type
    const validTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (type === 'company-logo') {
      validTypes.push('image/svg+xml');
    }

    if (!validTypes.includes(file.type)) {
      return {
        success: false,
        error: `Invalid file type. Allowed types: ${validTypes.join(', ')}`,
      };
    }

    // Validate file size
    const maxSize = type === 'profile-picture' ? 2 * 1024 * 1024 : 5 * 1024 * 1024; // 2MB or 5MB
    if (file.size > maxSize) {
      return {
        success: false,
        error: `File size exceeds ${maxSize / 1024 / 1024}MB limit`,
      };
    }

    // Determine bucket and path
    let bucket: string;
    let filePath: string;
    const fileExt = file.name.split('.').pop();
    const timestamp = Date.now();

    if (type === 'profile-picture') {
      bucket = 'profile-pictures';
      filePath = `profiles/${userId}/${timestamp}.${fileExt}`;
    } else {
      bucket = 'company-logos';
      filePath = `logos/${tenantId || userId}/${timestamp}.${fileExt}`;
    }

    // Upload file
    const { data, error } = await supabase.storage
      .from(bucket)
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: false,
      });

    if (error) {
      console.error('Upload error:', error);
      return {
        success: false,
        error: error.message || 'Upload failed',
      };
    }

    // Get public URL
    const { data: urlData } = supabase.storage
      .from(bucket)
      .getPublicUrl(filePath);

    return {
      success: true,
      url: urlData.publicUrl,
    };
  } catch (error: any) {
    console.error('Unexpected upload error:', error);
    return {
      success: false,
      error: error.message || 'Unexpected error during upload',
    };
  }
}

/**
 * Delete an image from Supabase Storage
 * @param url Public URL of the image to delete
 * @param type Type of image (profile-picture or company-logo)
 */
export async function deleteImage(url: string, type: UploadType): Promise<boolean> {
  const supabase = createClient();

  try {
    // Extract bucket and path from URL
    const bucket = type === 'profile-picture' ? 'profile-pictures' : 'company-logos';
    const urlParts = url.split(`/${bucket}/`);
    if (urlParts.length < 2) {
      console.error('Invalid URL format');
      return false;
    }

    const filePath = urlParts[1];

    const { error } = await supabase.storage.from(bucket).remove([filePath]);

    if (error) {
      console.error('Delete error:', error);
      return false;
    }

    return true;
  } catch (error) {
    console.error('Unexpected delete error:', error);
    return false;
  }
}

/**
 * Compress and resize image before upload (client-side)
 * @param file Original image file
 * @param maxWidth Maximum width in pixels
 * @param maxHeight Maximum height in pixels
 * @param quality JPEG quality (0-1)
 */
export async function compressImage(
  file: File,
  maxWidth: number = 800,
  maxHeight: number = 800,
  quality: number = 0.8
): Promise<File> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = (e) => {
      const img = new Image();
      img.onload = () => {
        const canvas = document.createElement('canvas');
        let { width, height } = img;

        // Calculate new dimensions while maintaining aspect ratio
        if (width > height) {
          if (width > maxWidth) {
            height = (height * maxWidth) / width;
            width = maxWidth;
          }
        } else {
          if (height > maxHeight) {
            width = (width * maxHeight) / height;
            height = maxHeight;
          }
        }

        canvas.width = width;
        canvas.height = height;

        const ctx = canvas.getContext('2d');
        if (!ctx) {
          reject(new Error('Failed to get canvas context'));
          return;
        }

        ctx.drawImage(img, 0, 0, width, height);

        canvas.toBlob(
          (blob) => {
            if (!blob) {
              reject(new Error('Failed to compress image'));
              return;
            }

            const compressedFile = new File([blob], file.name, {
              type: 'image/jpeg',
              lastModified: Date.now(),
            });

            resolve(compressedFile);
          },
          'image/jpeg',
          quality
        );
      };

      img.onerror = () => reject(new Error('Failed to load image'));
      img.src = e.target?.result as string;
    };

    reader.onerror = () => reject(new Error('Failed to read file'));
    reader.readAsDataURL(file);
  });
}

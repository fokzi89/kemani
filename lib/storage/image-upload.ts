/**
 * Image Upload Service
 * Handles image uploads to Supabase Storage
 * Supports: Profile pictures, company logos
 */

import { createClient } from '@/lib/supabase/server';

// ============================================================
// Types
// ============================================================

export type ImageType = 'profile' | 'logo';

export interface ImageUploadResult {
  url: string;
  path: string;
  publicUrl: string;
}

export interface ImageUploadOptions {
  bucket?: string;
  maxSizeBytes?: number;
  allowedTypes?: string[];
  folder?: string;
}

// ============================================================
// Configuration
// ============================================================

const DEFAULT_MAX_SIZE = 5 * 1024 * 1024; // 5MB
const DEFAULT_ALLOWED_TYPES = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif'];

const BUCKET_CONFIG = {
  profile: {
    bucket: 'profile-pictures',
    maxSize: 2 * 1024 * 1024, // 2MB for profile pictures
    allowedTypes: ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'],
  },
  logo: {
    bucket: 'company-logos',
    maxSize: 5 * 1024 * 1024, // 5MB for logos
    allowedTypes: ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/svg+xml'],
  },
};

// ============================================================
// Helper Functions
// ============================================================

/**
 * Validate file size and type
 */
function validateImage(
  file: File,
  allowedTypes: string[],
  maxSize: number
): { valid: boolean; error?: string } {
  // Check file type
  if (!allowedTypes.includes(file.type)) {
    return {
      valid: false,
      error: `Invalid file type. Allowed types: ${allowedTypes.join(', ')}`,
    };
  }

  // Check file size
  if (file.size > maxSize) {
    const maxSizeMB = (maxSize / (1024 * 1024)).toFixed(1);
    return {
      valid: false,
      error: `File size exceeds ${maxSizeMB}MB limit`,
    };
  }

  return { valid: true };
}

/**
 * Generate unique file name
 */
function generateFileName(originalName: string, userId: string): string {
  const timestamp = Date.now();
  const randomStr = Math.random().toString(36).substring(2, 8);
  const extension = originalName.split('.').pop()?.toLowerCase() || 'jpg';
  return `${userId}_${timestamp}_${randomStr}.${extension}`;
}

/**
 * Get folder path based on image type and tenant
 */
function getFolderPath(
  imageType: ImageType,
  userId: string,
  tenantId?: string,
  customFolder?: string
): string {
  if (customFolder) return customFolder;

  if (imageType === 'profile') {
    return `profiles/${userId}`;
  }

  if (imageType === 'logo' && tenantId) {
    return `logos/${tenantId}`;
  }

  return userId; // Fallback
}

// ============================================================
// Main Upload Function
// ============================================================

/**
 * Upload image to Supabase Storage
 * @param file - File object to upload
 * @param imageType - Type of image (profile or logo)
 * @param userId - ID of user uploading the image
 * @param tenantId - Optional tenant ID for logos
 * @param options - Optional configuration
 */
export async function uploadImage(
  file: File,
  imageType: ImageType,
  userId: string,
  tenantId?: string,
  options?: ImageUploadOptions
): Promise<ImageUploadResult> {
  // Get configuration for image type
  const config = BUCKET_CONFIG[imageType];
  const bucket = options?.bucket || config.bucket;
  const maxSize = options?.maxSizeBytes || config.maxSize;
  const allowedTypes = options?.allowedTypes || config.allowedTypes;

  // Validate image
  const validation = validateImage(file, allowedTypes, maxSize);
  if (!validation.valid) {
    throw new Error(validation.error);
  }

  // Generate file path
  const folderPath = getFolderPath(imageType, userId, tenantId, options?.folder);
  const fileName = generateFileName(file.name, userId);
  const filePath = `${folderPath}/${fileName}`;

  // Upload to Supabase Storage
  const supabase = await createClient();

  const { data, error } = await supabase.storage
    .from(bucket)
    .upload(filePath, file, {
      cacheControl: '3600',
      upsert: false, // Don't overwrite existing files
    });

  if (error) {
    console.error('Image upload error:', error);
    throw new Error(`Failed to upload image: ${error.message}`);
  }

  // Get public URL
  const { data: urlData } = supabase.storage.from(bucket).getPublicUrl(data.path);

  return {
    url: urlData.publicUrl,
    path: data.path,
    publicUrl: urlData.publicUrl,
  };
}

// ============================================================
// Delete Image
// ============================================================

/**
 * Delete image from Supabase Storage
 * @param imagePath - Path to the image in storage
 * @param imageType - Type of image (profile or logo)
 */
export async function deleteImage(
  imagePath: string,
  imageType: ImageType
): Promise<boolean> {
  const config = BUCKET_CONFIG[imageType];
  const supabase = await createClient();

  const { error } = await supabase.storage.from(config.bucket).remove([imagePath]);

  if (error) {
    console.error('Image deletion error:', error);
    return false;
  }

  return true;
}

// ============================================================
// Update Image (Delete old, upload new)
// ============================================================

/**
 * Replace existing image with a new one
 * @param oldImagePath - Path to old image (to be deleted)
 * @param newFile - New file to upload
 * @param imageType - Type of image
 * @param userId - User ID
 * @param tenantId - Optional tenant ID
 */
export async function updateImage(
  oldImagePath: string | null,
  newFile: File,
  imageType: ImageType,
  userId: string,
  tenantId?: string
): Promise<ImageUploadResult> {
  // Upload new image
  const uploadResult = await uploadImage(newFile, imageType, userId, tenantId);

  // Delete old image if it exists
  if (oldImagePath) {
    await deleteImage(oldImagePath, imageType);
  }

  return uploadResult;
}

// ============================================================
// Get Image URL
// ============================================================

/**
 * Get public URL for an image
 * @param imagePath - Path to the image
 * @param imageType - Type of image
 */
export async function getImageUrl(
  imagePath: string,
  imageType: ImageType
): Promise<string> {
  const config = BUCKET_CONFIG[imageType];
  const supabase = await createClient();

  const { data } = supabase.storage.from(config.bucket).getPublicUrl(imagePath);

  return data.publicUrl;
}

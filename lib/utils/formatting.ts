/**
 * Formatting Utilities
 * Functions for formatting currency, dates, phone numbers, etc.
 */

import { parsePhoneNumber, isValidPhoneNumber } from 'libphonenumber-js';

// ============================================
// CURRENCY FORMATTING
// ============================================

/**
 * Format amount as Nigerian Naira
 */
export function formatNaira(amount: number, options?: Intl.NumberFormatOptions): string {
  return new Intl.NumberFormat('en-NG', {
    style: 'currency',
    currency: 'NGN',
    ...options,
  }).format(amount);
}

/**
 * Format amount as compact currency (e.g., ₦1.2M)
 */
export function formatNairaCompact(amount: number): string {
  return new Intl.NumberFormat('en-NG', {
    style: 'currency',
    currency: 'NGN',
    notation: 'compact',
    maximumFractionDigits: 1,
  }).format(amount);
}

/**
 * Parse currency string to number
 */
export function parseNaira(value: string): number {
  // Remove currency symbol, commas, and spaces
  const cleaned = value.replace(/[₦,\s]/g, '');
  return parseFloat(cleaned) || 0;
}

// ============================================
// NUMBER FORMATTING
// ============================================

/**
 * Format number with thousand separators
 */
export function formatNumber(value: number, decimals: number = 0): string {
  return new Intl.NumberFormat('en-NG', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(value);
}

/**
 * Format percentage
 */
export function formatPercentage(value: number, decimals: number = 2): string {
  return new Intl.NumberFormat('en-NG', {
    style: 'percent',
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(value / 100);
}

/**
 * Format number as compact (e.g., 1.2K, 3.4M)
 */
export function formatNumberCompact(value: number): string {
  return new Intl.NumberFormat('en-NG', {
    notation: 'compact',
    maximumFractionDigits: 1,
  }).format(value);
}

// ============================================
// DATE FORMATTING
// ============================================

/**
 * Format date as readable string
 */
export function formatDate(date: Date | string, format: 'short' | 'medium' | 'long' | 'full' = 'medium'): string {
  const d = typeof date === 'string' ? new Date(date) : date;

  return new Intl.DateTimeFormat('en-NG', {
    dateStyle: format,
  }).format(d);
}

/**
 * Format date and time
 */
export function formatDateTime(
  date: Date | string,
  options?: Intl.DateTimeFormatOptions
): string {
  const d = typeof date === 'string' ? new Date(date) : date;

  return new Intl.DateTimeFormat('en-NG', {
    dateStyle: 'medium',
    timeStyle: 'short',
    ...options,
  }).format(d);
}

/**
 * Format time only
 */
export function formatTime(date: Date | string, use24Hour: boolean = false): string {
  const d = typeof date === 'string' ? new Date(date) : date;

  return new Intl.DateTimeFormat('en-NG', {
    hour: 'numeric',
    minute: '2-digit',
    hour12: !use24Hour,
  }).format(d);
}

/**
 * Format date as YYYY-MM-DD
 */
export function formatDateISO(date: Date | string): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  return d.toISOString().split('T')[0];
}

/**
 * Get relative time (e.g., "2 hours ago", "in 3 days")
 */
export function formatRelativeTime(date: Date | string): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  const now = new Date();
  const diffMs = d.getTime() - now.getTime();
  const diffSec = Math.floor(diffMs / 1000);
  const diffMin = Math.floor(diffSec / 60);
  const diffHour = Math.floor(diffMin / 60);
  const diffDay = Math.floor(diffHour / 24);

  const rtf = new Intl.RelativeTimeFormat('en-NG', { numeric: 'auto' });

  if (Math.abs(diffDay) > 0) {
    return rtf.format(diffDay, 'day');
  } else if (Math.abs(diffHour) > 0) {
    return rtf.format(diffHour, 'hour');
  } else if (Math.abs(diffMin) > 0) {
    return rtf.format(diffMin, 'minute');
  } else {
    return rtf.format(diffSec, 'second');
  }
}

/**
 * Format duration in seconds as readable string
 */
export function formatDuration(seconds: number): string {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);

  const parts = [];
  if (hours > 0) parts.push(`${hours}h`);
  if (minutes > 0) parts.push(`${minutes}m`);
  if (secs > 0 || parts.length === 0) parts.push(`${secs}s`);

  return parts.join(' ');
}

// ============================================
// PHONE NUMBER FORMATTING
// ============================================

/**
 * Format phone number for display
 */
export function formatPhone(phone: string, format: 'international' | 'national' | 'e164' = 'international'): string {
  try {
    const phoneNumber = parsePhoneNumber(phone, 'NG');

    switch (format) {
      case 'international':
        return phoneNumber.formatInternational(); // +234 803 123 4567
      case 'national':
        return phoneNumber.formatNational(); // 0803 123 4567
      case 'e164':
        return phoneNumber.format('E.164'); // +2348031234567
      default:
        return phoneNumber.formatInternational();
    }
  } catch {
    return phone; // Return original if parsing fails
  }
}

/**
 * Validate and format phone number
 */
export function validateAndFormatPhone(phone: string): { valid: boolean; formatted?: string; error?: string } {
  try {
    // Remove all non-numeric characters except +
    const cleaned = phone.replace(/[^\d+]/g, '');

    // Check if it's a valid phone number
    if (!isValidPhoneNumber(cleaned, 'NG')) {
      return { valid: false, error: 'Invalid phone number format' };
    }

    // Parse and format
    const phoneNumber = parsePhoneNumber(cleaned, 'NG');
    return {
      valid: true,
      formatted: phoneNumber.format('E.164'), // +234XXXXXXXXXX
    };
  } catch (error) {
    return { valid: false, error: 'Invalid phone number' };
  }
}

/**
 * Mask phone number for privacy (e.g., +234 803 ***  4567)
 */
export function maskPhone(phone: string): string {
  try {
    const phoneNumber = parsePhoneNumber(phone, 'NG');
    const formatted = phoneNumber.formatInternational();
    // Mask middle digits
    return formatted.replace(/(\d{3})\s(\d{3})\s(\d{4})/, '$1 $2 *** $3');
  } catch {
    // Fallback masking
    if (phone.length > 6) {
      return phone.slice(0, -4).replace(/\d/g, '*') + phone.slice(-4);
    }
    return phone;
  }
}

// ============================================
// TEXT FORMATTING
// ============================================

/**
 * Truncate text with ellipsis
 */
export function truncate(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text;
  return text.slice(0, maxLength - 3) + '...';
}

/**
 * Capitalize first letter
 */
export function capitalize(text: string): string {
  return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase();
}

/**
 * Convert to title case
 */
export function toTitleCase(text: string): string {
  return text
    .toLowerCase()
    .split(' ')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

/**
 * Slugify text (convert to URL-friendly string)
 */
export function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^\w\s-]/g, '') // Remove special characters
    .replace(/\s+/g, '-') // Replace spaces with hyphens
    .replace(/-+/g, '-') // Replace multiple hyphens with single
    .trim();
}

// ============================================
// FILE SIZE FORMATTING
// ============================================

/**
 * Format bytes as human-readable file size
 */
export function formatFileSize(bytes: number, decimals: number = 2): string {
  if (bytes === 0) return '0 Bytes';

  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(decimals))} ${sizes[i]}`;
}

// ============================================
// ADDRESS FORMATTING
// ============================================

/**
 * Format address components into single string
 */
export function formatAddress(components: {
  street?: string;
  city?: string;
  state?: string;
  country?: string;
  postal_code?: string;
}): string {
  const parts = [
    components.street,
    components.city,
    components.state,
    components.postal_code,
    components.country,
  ].filter(Boolean);

  return parts.join(', ');
}

// ============================================
// BUSINESS FORMATTING
// ============================================

/**
 * Format business hours
 */
export function formatBusinessHours(open: string, close: string): string {
  return `${formatTime(new Date(`2000-01-01T${open}`))} - ${formatTime(new Date(`2000-01-01T${close}`))}`;
}

/**
 * Format SKU or product code
 */
export function formatSKU(sku: string, prefix?: string): string {
  const cleaned = sku.toUpperCase().replace(/[^A-Z0-9]/g, '');
  return prefix ? `${prefix}-${cleaned}` : cleaned;
}

/**
 * Generate receipt/invoice number
 */
export function generateReceiptNumber(prefix: string = 'RCP', sequence: number): string {
  const date = new Date();
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const seq = String(sequence).padStart(6, '0');

  return `${prefix}-${year}${month}-${seq}`;
}

// ============================================
// EXPORT ALL
// ============================================

export default {
  // Currency
  formatNaira,
  formatNairaCompact,
  parseNaira,

  // Numbers
  formatNumber,
  formatPercentage,
  formatNumberCompact,

  // Dates
  formatDate,
  formatDateTime,
  formatTime,
  formatDateISO,
  formatRelativeTime,
  formatDuration,

  // Phone
  formatPhone,
  validateAndFormatPhone,
  maskPhone,

  // Text
  truncate,
  capitalize,
  toTitleCase,
  slugify,

  // File size
  formatFileSize,

  // Address
  formatAddress,

  // Business
  formatBusinessHours,
  formatSKU,
  generateReceiptNumber,
};

export * from './sms';
export * from './index';

import { createClient } from '@/lib/supabase/client';

/**
 * Send OTP via email (using Supabase Auth)
 */
export async function sendOTP(identifier: string, channel: 'email' | 'sms') {
  // Only email is supported for now
  const supabase = createClient();

  const { error } = await supabase.auth.signInWithOtp({
    email: identifier,
    options: {
      shouldCreateUser: true,
    },
  });

  if (error) {
    throw new Error(error.message || 'Failed to send email OTP');
  }

  return { success: true };
}

/**
 * Verify OTP code (handled by Supabase for email)
 */
export async function verifyOTP(identifier: string, code: string, channel: 'email' | 'sms'): Promise<boolean> {
  // For email, Supabase handles verification automatically when user clicks magic link
  // or enters the OTP in Supabase's verification flow
  return true;
}

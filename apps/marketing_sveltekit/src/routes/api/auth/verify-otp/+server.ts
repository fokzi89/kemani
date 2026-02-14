import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { createClient } from '$lib/supabase/server';

export const POST: RequestHandler = async ({ request }) => {
  try {
    const { identifier, otp, channel } = await request.json();

    if (!identifier || !otp) {
      return json(
        { error: 'Identifier and OTP are required' },
        { status: 400 }
      );
    }

    if (channel && channel !== 'email') {
      return json(
        { error: 'Only email authentication is supported' },
        { status: 400 }
      );
    }

    const supabase = await createClient();

    // Verify the OTP token with Supabase
    const { data: authData, error: verifyError } = await supabase.auth.verifyOtp({
      email: identifier,
      token: otp,
      type: 'email',
    });

    if (verifyError) {
      return json(
        { error: verifyError.message || 'Invalid or expired OTP' },
        { status: 401 }
      );
    }

    // After successful auth, check if user exists in our users table
    if (authData.session) {
      const { data: existingUser } = await supabase
        .from('users')
        .select('id, tenant_id')
        .eq('id', authData.session.user.id)
        .maybeSingle();

      if (!existingUser) {
        // New user - needs to complete registration
        return json({
          success: true,
          needsRegistration: true,
          message: 'OTP verified. Please complete registration.',
          session: authData.session,
        });
      }

      // Existing user - login successful
      return json({
        success: true,
        needsRegistration: false,
        message: 'Login successful',
        session: authData.session,
      });
    }

    return json(
      { error: 'Failed to create session' },
      { status: 500 }
    );
  } catch (error: any) {
    console.error('Verify OTP error:', error);
    return json(
      { error: error.message || 'Failed to verify OTP' },
      { status: 500 }
    );
  }
};

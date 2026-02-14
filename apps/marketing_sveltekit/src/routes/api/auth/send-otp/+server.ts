import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { createClient } from '$lib/supabase/server';

export const POST: RequestHandler = async ({ request }) => {
  try {
    const { identifier, channel } = await request.json();

    if (!identifier) {
      return json(
        { error: 'Email identifier is required' },
        { status: 400 }
      );
    }

    // Enforce Email only
    if (channel && channel !== 'email') {
      return json(
        { error: 'Only email authentication is supported' },
        { status: 400 }
      );
    }

    const supabase = await createClient();

    // Send generic email OTP using Supabase
    const { error } = await supabase.auth.signInWithOtp({
      email: identifier,
      options: {
        shouldCreateUser: true,
      },
    });

    if (error) {
      return json(
        { error: error.message },
        { status: 400 }
      );
    }

    return json({
      success: true,
      message: `OTP sent to ${identifier}`,
    });
  } catch (error: any) {
    console.error('Send OTP error:', error);
    return json(
      { error: error.message || 'Failed to send OTP' },
      { status: 500 }
    );
  }
};

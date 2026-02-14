import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { createAdminClient } from '$lib/supabase/server';
import { EmailService } from '$lib/integrations/resend';

export const POST: RequestHandler = async ({ request }) => {
  try {
    const { businessName, fullName, email } = await request.json();

    // Validate inputs
    if (!businessName || !fullName || !email) {
      return json(
        { error: 'Business name, full name, and email are required' },
        { status: 400 }
      );
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return json(
        { error: 'Please provide a valid email address' },
        { status: 400 }
      );
    }

    const supabase = await createAdminClient();

    // Check if email is already registered
    const { data: existingUser } = await supabase.auth.admin.listUsers();
    const emailExists = existingUser?.users.some((user) => user.email === email);

    if (emailExists) {
      return json(
        { error: 'This email is already registered' },
        { status: 400 }
      );
    }

    // Generate slug from business name
    const slug = businessName
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');

    // Check if slug is available
    const { data: existingTenant } = await supabase
      .from('tenants')
      .select('id')
      .eq('slug', slug)
      .maybeSingle();

    const finalSlug = existingTenant ? `${slug}-${Date.now()}` : slug;

    // 1. Create auth user (company owner) with email OTP
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: email,
      email_confirm: false, // User needs to verify email via OTP
      user_metadata: {
        full_name: fullName,
      },
    });

    if (authError) {
      console.error('Auth user creation error:', authError);
      return json(
        { error: 'Failed to create user account. Please try again.' },
        { status: 500 }
      );
    }

    if (!authData.user) {
      return json(
        { error: 'Failed to create user account' },
        { status: 500 }
      );
    }

    const userId = authData.user.id;

    // 2. Create tenant
    const { data: tenant, error: tenantError } = await supabase
      .from('tenants')
      .insert({
        name: businessName,
        slug: finalSlug,
        email: email,
      })
      .select()
      .single();

    if (tenantError) {
      console.error('Tenant creation error:', tenantError);
      // Rollback: Delete auth user
      await supabase.auth.admin.deleteUser(userId);
      return json(
        { error: 'Failed to create business account. Please try again.' },
        { status: 500 }
      );
    }

    // 3. Create user record (company owner)
    const { error: userError } = await supabase
      .from('users')
      .insert({
        id: userId,
        full_name: fullName,
        email: email,
        role: 'tenant_admin',
        tenant_id: tenant.id,
      });

    if (userError) {
      console.error('User record creation error:', userError);
      // Rollback: Delete tenant and auth user
      await supabase.from('tenants').delete().eq('id', tenant.id);
      await supabase.auth.admin.deleteUser(userId);
      return json(
        { error: 'Failed to create user profile. Please try again.' },
        { status: 500 }
      );
    }

    // 4. Create default branch
    const { error: branchError } = await supabase
      .from('branches')
      .insert({
        name: `${businessName} - Main Branch`,
        tenant_id: tenant.id,
        business_type: 'retail',
      });

    if (branchError) {
      console.error('Branch creation error:', branchError);
      // Continue anyway - branch can be created later
    }

    // 5. Send registration confirmation email
    try {
      const dashboardUrl = `${import.meta.env.VITE_APP_URL || 'http://localhost:5173'}/login`;

      await EmailService.sendRegistrationConfirmation(email, {
        businessName: businessName,
        ownerName: fullName,
        dashboardUrl: dashboardUrl,
      });
    } catch (emailError) {
      console.error('Failed to send confirmation email:', emailError);
      // Don't fail the registration if email fails
      // User can still log in
    }

    // 6. Send email OTP for verification
    const { error: otpError } = await supabase.auth.signInWithOtp({
      email: email,
      options: {
        shouldCreateUser: false, // User already created
      },
    });

    if (otpError) {
      console.error('OTP send error:', otpError);
      // Don't fail registration - user can request OTP on login page
    }

    return json({
      success: true,
      message: 'Registration successful! Please check your email for verification code.',
      tenant: {
        id: tenant.id,
        name: tenant.name,
        slug: tenant.slug,
      },
      redirectTo: `/verify-otp?email=${encodeURIComponent(email)}`,
    });
  } catch (error: any) {
    console.error('Registration error:', error);
    return json(
      { error: error.message || 'Registration failed. Please try again.' },
      { status: 500 }
    );
  }
};

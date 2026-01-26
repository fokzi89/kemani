import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/client';

export async function POST(request: NextRequest) {
  try {
    const { businessName, fullName, email, passcode } = await request.json();

    // Validate inputs
    if (!businessName || !fullName || !email || !passcode) {
      return NextResponse.json(
        { error: 'Business name, full name, email, and passcode are required' },
        { status: 400 }
      );
    }

    // Validate passcode format
    if (!/^\d{6}$/.test(passcode)) {
      return NextResponse.json(
        { error: 'Passcode must be exactly 6 digits' },
        { status: 400 }
      );
    }

    // Hash the passcode using Web Crypto API
    const encoder = new TextEncoder();
    const data = encoder.encode(passcode);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const hashedPasscode = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

    const supabase = createClient();

    // Get authenticated user
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json(
        { error: 'Not authenticated' },
        { status: 401 }
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

    // Create tenant
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
      throw new Error('Failed to create business account');
    }

    // Create user record with passcode hash
    const { error: userError } = await supabase
      .from('users')
      .insert({
        id: user.id,
        full_name: fullName,
        email: email,
        role: 'tenant_admin',
        tenant_id: tenant.id,
      });

    if (!userError) {
      // Store passcode hash in user metadata (secure)
      await supabase.auth.updateUser({
        data: {
          passcode_hash: hashedPasscode,
        },
      });
    }

    if (userError) {
      console.error('User creation error:', userError);
      // Rollback tenant creation
      await supabase.from('tenants').delete().eq('id', tenant.id);
      throw new Error('Failed to create user account');
    }

    // Create default branch
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

    return NextResponse.json({
      success: true,
      tenant,
      message: 'Registration completed successfully',
    });
  } catch (error: any) {
    console.error('Registration error:', error);
    return NextResponse.json(
      { error: error.message || 'Registration failed' },
      { status: 500 }
    );
  }
}

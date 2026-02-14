import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient();

    // Get authenticated user
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
    }

    const { businessName, businessType, location, address, city, country } = await request.json();

    // Validate required fields
    if (!businessName || !businessType || !address || !city || !country) {
      return NextResponse.json(
        { error: 'All fields are required' },
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

    // Create tenant
    const { data: tenant, error: tenantError } = await supabase
      .from('tenants')
      .insert({
        name: businessName,
        slug: finalSlug,
        email: user.email,
        phone: user.user_metadata?.phone || null,
      })
      .select()
      .single();

    if (tenantError) {
      console.error('Tenant creation error:', tenantError);
      return NextResponse.json(
        { error: 'Failed to create business' },
        { status: 500 }
      );
    }

    // Create user record (company owner)
    const { error: userError } = await supabase
      .from('users')
      .insert({
        id: user.id,
        full_name: user.user_metadata?.full_name || 'Owner',
        email: user.email,
        phone: user.user_metadata?.phone || null,
        role: 'tenant_admin',
        tenant_id: tenant.id,
      });

    if (userError) {
      console.error('User record creation error:', userError);
      // Rollback: Delete tenant
      await supabase.from('tenants').delete().eq('id', tenant.id);
      return NextResponse.json(
        { error: 'Failed to create user profile' },
        { status: 500 }
      );
    }

    // Create default branch with location details
    const { error: branchError } = await supabase
      .from('branches')
      .insert({
        name: `${businessName} - Main Branch`,
        tenant_id: tenant.id,
        business_type: businessType.toLowerCase().replace(/[^a-z0-9]+/g, '_'),
        location: location || city,
        address: address,
        city: city,
        country: country,
      });

    if (branchError) {
      console.error('Branch creation error:', branchError);
      // Continue anyway - branch can be created later
    }

    return NextResponse.json({
      success: true,
      tenant,
      message: 'Business created successfully',
    });
  } catch (error: any) {
    console.error('Business setup error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to set up business' },
      { status: 500 }
    );
  }
}

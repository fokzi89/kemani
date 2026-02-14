import { NextRequest, NextResponse } from 'next/server';
import { TenantService } from '@/lib/auth/tenant';
import { TenantRegistration } from '@/lib/types/database';

// POST - Register new tenant
export async function POST(request: NextRequest) {
  try {
    const registration: TenantRegistration = await request.json();

    // Validate required fields
    if (!registration.tenantName || !registration.tenantSlug || !registration.adminName) {
      return NextResponse.json(
        { error: 'Tenant name, slug, and admin name are required' },
        { status: 400 }
      );
    }

    // Verify adminEmail is provided (required for Email OTP)
    if (!registration.adminEmail) {
      return NextResponse.json(
        { error: 'Admin email is required for authentication' },
        { status: 400 }
      );
    }

    // Check if slug is available
    const isAvailable = await TenantService.isSlugAvailable(registration.tenantSlug);
    if (!isAvailable) {
      return NextResponse.json(
        { error: 'Tenant slug is already taken' },
        { status: 409 }
      );
    }

    // Register tenant
    const result = await TenantService.registerTenant(registration);

    return NextResponse.json(result, { status: 201 });
  } catch (error: any) {
    console.error('Tenant registration error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to register tenant' },
      { status: 500 }
    );
  }
}

// GET - Get tenant information
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const tenantId = searchParams.get('id');
    const slug = searchParams.get('slug');

    if (!tenantId && !slug) {
      return NextResponse.json(
        { error: 'Tenant ID or slug is required' },
        { status: 400 }
      );
    }

    let tenant;
    if (tenantId) {
      tenant = await TenantService.getTenant(tenantId);
    } else if (slug) {
      tenant = await TenantService.getTenantBySlug(slug);
    }

    return NextResponse.json(tenant);
  } catch (error: any) {
    console.error('Get tenant error:', error);
    return NextResponse.json(
      { error: error.message || 'Failed to get tenant' },
      { status: 500 }
    );
  }
}

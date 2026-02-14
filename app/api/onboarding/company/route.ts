import { NextRequest, NextResponse } from 'next/server';
import { OnboardingService } from '@/lib/auth/onboarding';
import { createClient } from '@/lib/supabase/server';
import { OnboardingCompanyData } from '@/lib/types/onboarding';

export async function POST(req: NextRequest) {
    try {
        const supabase = await createClient();
        const { data: { user }, error: authError } = await supabase.auth.getUser();

        if (authError || !user) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        // Get user from DB to check tenant_id
        const { data: dbUser, error: userError } = await supabase
            .from('users')
            .select('role, tenant_id, full_name, phone_number, gender')
            .eq('id', user.id)
            .single();

        if (userError || !dbUser) {
            return NextResponse.json({ error: 'User not found' }, { status: 404 });
        }

        // Verify profile is complete (Step 1 must be done first)
        if (!dbUser.full_name || !dbUser.phone_number || !dbUser.gender) {
            return NextResponse.json(
                { error: 'Please complete profile setup first' },
                { status: 400 }
            );
        }

        const body = await req.json();
        const {
            businessName,
            businessType,
            address,
            country,
            city,
            officeAddress,
            logoUrl,
            latitude,
            longitude
        } = body;

        // Validation
        if (!businessType || !address || !country || !city) {
            return NextResponse.json({ error: 'Missing required company fields' }, { status: 400 });
        }

        // For new owners creating tenant, businessName is required
        if (!dbUser.tenant_id && !businessName) {
            return NextResponse.json(
                { error: 'Business name is required for new company setup' },
                { status: 400 }
            );
        }

        const companyData: OnboardingCompanyData = {
            businessName,
            businessType,
            address,
            country,
            city,
            officeAddress,
            logoUrl,
            latitude,
            longitude
        };

        // Save company (creates tenant if new owner, updates if existing tenant)
        const result = await OnboardingService.saveCompany(
            user.id,
            companyData,
            dbUser.tenant_id || undefined
        );

        // Mark onboarding as complete
        await OnboardingService.completeOnboarding(user.id);

        return NextResponse.json({
            success: true,
            data: result,
        });
    } catch (error: any) {
        console.error('API Error:', error);
        return NextResponse.json(
            { error: error.message || 'Internal Server Error' },
            { status: 500 }
        );
    }
}

import { NextRequest, NextResponse } from 'next/server';
import { OnboardingService } from '@/lib/auth/onboarding';
import { createClient } from '@/lib/supabase/server';

export async function POST(req: NextRequest) {
    try {
        const supabase = await createClient();
        const { data: { user }, error: authError } = await supabase.auth.getUser();

        if (authError || !user) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        const updatedUser = await OnboardingService.completeOnboarding(user.id);

        return NextResponse.json({ success: true, user: updatedUser });
    } catch (error: any) {
        console.error('API Error:', error);
        return NextResponse.json(
            { error: error.message || 'Internal Server Error' },
            { status: 500 }
        );
    }
}

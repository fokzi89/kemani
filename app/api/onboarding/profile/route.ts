import { NextRequest, NextResponse } from 'next/server';
import { OnboardingService } from '@/lib/auth/onboarding';
import { createClient } from '@/lib/supabase/server';
import { OnboardingProfileData } from '@/lib/types/onboarding';

export async function POST(req: NextRequest) {
    try {
        const supabase = await createClient();
        const { data: { user }, error: authError } = await supabase.auth.getUser();

        if (authError || !user) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        const body = await req.json();
        const { fullName, phoneNumber, gender, profilePictureUrl } = body;

        // Basic validation
        if (!fullName) {
            return NextResponse.json({ error: 'Full name is required' }, { status: 400 });
        }

        const profileData: OnboardingProfileData = {
            fullName,
            phoneNumber,
            gender,
            profilePictureUrl
        };

        const updatedUser = await OnboardingService.saveProfile(user.id, profileData);

        return NextResponse.json({ success: true, user: updatedUser });
    } catch (error: any) {
        console.error('API Error:', error);
        return NextResponse.json(
            { error: error.message || 'Internal Server Error' },
            { status: 500 }
        );
    }
}

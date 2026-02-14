import { BusinessType } from '@/lib/types/database';

export interface OnboardingProfileData {
    fullName: string;
    phoneNumber?: string;
    gender?: 'male' | 'female';
    profilePictureUrl?: string;
}

export interface OnboardingCompanyData {
    businessName?: string; // Optional if updating existing
    businessType: BusinessType;
    address: string;
    country: string;
    city: string;
    officeAddress?: string;
    logoUrl?: string;
    // Geolocation is handled by service or separate weak-entity/update
    latitude?: number;
    longitude?: number;
}

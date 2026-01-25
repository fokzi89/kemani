import { Database } from '@/types/database.types.generated';

// Export the main database type
export type { Database };

// Helper types for tables
export type Tables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Row'];

export type Enums<T extends keyof Database['public']['Enums']> =
  Database['public']['Enums'][T];

// Tenant types
export type Tenant = Tables<'tenants'>;
export type TenantInsert = Database['public']['Tables']['tenants']['Insert'];
export type TenantUpdate = Database['public']['Tables']['tenants']['Update'];

// User types
export type User = Tables<'users'>;
export type UserInsert = Database['public']['Tables']['users']['Insert'];
export type UserUpdate = Database['public']['Tables']['users']['Update'];
export type UserRole = Enums<'user_role'>;

// Branch types
export type Branch = Tables<'branches'>;
export type BranchInsert = Database['public']['Tables']['branches']['Insert'];
export type BranchUpdate = Database['public']['Tables']['branches']['Update'];
export type BusinessType = Enums<'business_type'>;

// OTP Verification types
export type OTPVerification = Tables<'otp_verifications'>;
export type OTPChannel = 'sms' | 'email';

// Extended User type with relationships
export interface UserWithTenant extends User {
  tenant?: Tenant;
  branch?: Branch;
}

// Tenant with subscription info
export interface TenantWithSubscription extends Tenant {
  subscription?: Tables<'subscriptions'>;
}

// Registration types
export interface TenantRegistration {
  tenantName: string;
  tenantSlug: string;
  email?: string;
  phone?: string;
  adminName: string;
  adminPhone?: string;
  adminEmail?: string;
}

export interface UserInvite {
  email?: string;
  phone?: string;
  fullName: string;
  role: UserRole;
  branchId?: string;
}

// Auth session types
export interface AuthSession {
  userId: string;
  tenantId: string;
  branchId?: string;
  role: UserRole;
  email?: string;
  phone?: string;
}

// Branding configuration
export interface BrandingConfig {
  logoUrl?: string;
  brandColor?: string;
  customDomain?: string;
  ecommerceEnabled?: boolean;
  ecommerceSettings?: {
    storeName?: string;
    storeDescription?: string;
    socialLinks?: {
      facebook?: string;
      instagram?: string;
      twitter?: string;
    };
  };
}

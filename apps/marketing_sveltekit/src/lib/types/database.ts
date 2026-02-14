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
export type User = Tables<'users'> & { passcode_hash?: string | null };
export type UserInsert = Database['public']['Tables']['users']['Insert'] & { passcode_hash?: string | null };
export type UserUpdate = Database['public']['Tables']['users']['Update'] & { passcode_hash?: string | null };
export type UserRole = Enums<'user_role'>;

// Branch types
export type Branch = Tables<'branches'>;
export type BranchInsert = Database['public']['Tables']['branches']['Insert'];
export type BranchUpdate = Database['public']['Tables']['branches']['Update'];
export type BusinessType = Enums<'business_type'>;

// Product types
export type Product = Tables<'products'>;
export type ProductInsert = Database['public']['Tables']['products']['Insert'];
export type ProductUpdate = Database['public']['Tables']['products']['Update'];

// OTP Verification types (Supabase handling)
// export type OTPVerification = Tables<'otp_verifications'>;
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
  whatsappSettings?: {
    phoneNumberId?: string;
    accessToken?: string; // Should be encrypted in DB
    businessAccountId?: string;
    isEnabled?: boolean;
  };
}

// US9: WhatsApp Communication Models

export type WhatsAppMessageStatus = 'sent' | 'delivered' | 'read' | 'failed';
export type WhatsAppDirection = 'inbound' | 'outbound';

export interface WhatsAppMessage {
  id: string;
  tenant_id: string;
  wa_id: string; // The phone number ID from WhatsApp
  recipient_phone: string;
  direction: WhatsAppDirection; // inbound or outbound
  message_type: 'text' | 'template' | 'image' | 'interactive';
  content: string; // JSON string or text content
  status: WhatsAppMessageStatus;
  template_name?: string;
  created_at: string;
  updated_at: string;
}

// US3: Customer & Marketplace Models

// Customer types
export type Customer = Tables<'customers'>;
export type CustomerInsert = Database['public']['Tables']['customers']['Insert'];
export type CustomerUpdate = Database['public']['Tables']['customers']['Update'];

// Customer Address types
export type CustomerAddress = Tables<'customer_addresses'>;
export type CustomerAddressInsert = Database['public']['Tables']['customer_addresses']['Insert'];
export type CustomerAddressUpdate = Database['public']['Tables']['customer_addresses']['Update'];

// Order types
export type Order = Tables<'orders'>;
export type OrderInsert = Database['public']['Tables']['orders']['Insert'];
export type OrderUpdate = Database['public']['Tables']['orders']['Update'];
export type OrderStatus = Enums<'order_status'>;
export type PaymentStatus = Enums<'payment_status'>;

// Order Item types
export type OrderItem = Tables<'order_items'>;
export type OrderItemInsert = Database['public']['Tables']['order_items']['Insert'];
export type OrderItemUpdate = Database['public']['Tables']['order_items']['Update'];

// Extended types for UI
export interface CustomerWithAddresses extends Customer {
  addresses?: CustomerAddress[];
}

export interface OrderWithItems extends Order {
  items: (OrderItem & { product?: Tables<'products'> })[];
  customer?: Customer;
}

// US4: Staff Management Models

// Staff Attendance types
export type StaffAttendance = Tables<'staff_attendance'>;
export type StaffAttendanceInsert = Database['public']['Tables']['staff_attendance']['Insert'];
export type StaffAttendanceUpdate = Database['public']['Tables']['staff_attendance']['Update'];

// Extended type for UI
export interface StaffAttendanceWithUser extends StaffAttendance {
  user?: User;
}


// US11: Multi-Branch Management Models

// Inter-Branch Transfer types
export type InterBranchTransfer = Tables<'inter_branch_transfers'>;
export type InterBranchTransferInsert = Database['public']['Tables']['inter_branch_transfers']['Insert'];
export type InterBranchTransferUpdate = Database['public']['Tables']['inter_branch_transfers']['Update'];
export type TransferStatus = Enums<'transfer_status'>;

// Transfer Item types
export type TransferItem = Tables<'transfer_items'>;
export type TransferItemInsert = Database['public']['Tables']['transfer_items']['Insert'];
export type TransferItemUpdate = Database['public']['Tables']['transfer_items']['Update'];

// Extended type for UI
export interface InterBranchTransferWithItems extends InterBranchTransfer {
  items: (TransferItem & { product?: Tables<'products'> })[];
  source_branch?: Branch;
  destination_branch?: Branch;
  requested_by_user?: User;
}

// US5: Delivery Management Models

// Enums
export type DeliveryType = 'local_bike' | 'local_bicycle' | 'intercity';
export type DeliveryStatus = 'pending' | 'assigned' | 'picked_up' | 'in_transit' | 'delivered' | 'failed' | 'cancelled';
export type VehicleType = 'bike' | 'bicycle' | 'van' | 'car';

export type ECommercePlatform = 'woocommerce' | 'shopify';

export interface ECommerceConnection {
  id: string;
  tenant_id: string;
  platform: ECommercePlatform;
  store_url: string;
  consumer_key: string;
  consumer_secret: string; // Encrypt this in real app, keeping simple for MVP
  is_active: boolean;
  last_sync_at?: string | null;
  created_at: string;
  updated_at: string;
}

// Rider types
// Manually defining since generated types might be missing them
export interface Rider {
  id: string;
  tenant_id: string;
  user_id: string;
  vehicle_type: VehicleType;
  license_number?: string | null;
  phone: string;
  is_available: boolean;
  total_deliveries: number;
  successful_deliveries: number;
  average_delivery_time_minutes?: number | null;
  rating?: number | null;
  created_at: string;
  updated_at: string;
  deleted_at?: string | null;
}

export interface RiderInsert {
  tenant_id: string;
  user_id: string;
  vehicle_type: VehicleType;
  license_number?: string | null;
  phone: string;
  is_available?: boolean;
}

export interface RiderUpdate {
  vehicle_type?: VehicleType;
  license_number?: string | null;
  phone?: string;
  is_available?: boolean;
  rating?: number | null;
  updated_at?: string;
}

// Delivery types
export interface Delivery {
  id: string;
  tenant_id: string;
  branch_id: string;
  order_id: string;
  tracking_number: string;
  delivery_type: DeliveryType;
  rider_id?: string | null;
  delivery_status: DeliveryStatus;
  customer_address: string;
  customer_phone: string;
  customer_latitude?: number | null;
  customer_longitude?: number | null;
  distance_km?: number | null;
  estimated_delivery_time?: string | null;
  actual_delivery_time?: string | null;
  proof_type?: 'photo' | 'signature' | 'recipient_name' | null;
  proof_data?: string | null;
  failure_reason?: string | null;
  created_at: string;
  updated_at: string;
}

export interface DeliveryInsert {
  tenant_id: string;
  branch_id: string;
  order_id: string;
  tracking_number: string;
  delivery_type: DeliveryType;
  customer_address: string;
  customer_phone: string;
  customer_latitude?: number | null;
  customer_longitude?: number | null;
  distance_km?: number | null;
}

export interface DeliveryUpdate {
  rider_id?: string | null;
  delivery_status?: DeliveryStatus;
  actual_delivery_time?: string | null;
  proof_type?: 'photo' | 'signature' | 'recipient_name' | null;
  proof_data?: string | null;
  failure_reason?: string | null;
  updated_at?: string;
}

// Extended types for UI
export interface RiderWithUser extends Rider {
  user?: User;
}

export interface DeliveryWithDetails extends Delivery {
  order?: Order;
  rider?: RiderWithUser;
}

// Chat types
export type ChatStatus = 'active' | 'completed' | 'escalated' | 'abandoned';
export type SenderType = 'customer' | 'ai_agent' | 'staff';
export type ChatMessageType = 'text' | 'image' | 'video' | 'audio' | 'file';
export type ChatActionType = 'suggest_product' | 'check_order' | 'request_human';

export interface ChatConversation {
  id: string;
  tenant_id: string;
  branch_id: string;
  customer_id: string;
  order_id?: string | null;
  status: ChatStatus;
  escalated_to_user_id?: string | null;
  started_at: string;
  ended_at?: string | null;
}

export interface ChatMessage {
  id: string;
  conversation_id: string;
  sender_type: SenderType;
  sender_id?: string | null;
  message_type: ChatMessageType;
  message_text?: string | null;
  media_url?: string | null;
  media_size_bytes?: number | null;
  media_duration_seconds?: number | null;
  thumbnail_url?: string | null;
  metadata?: Record<string, any> | null;
  action_type?: ChatActionType | null;
  action_data?: Record<string, any> | null;
  action_completed_at?: string | null;
  action_completed_by?: string | null;
  intent?: string | null;
  confidence_score?: number | null;
  created_at: string;
  updated_at: string;
}

export interface ChatConversationWithDetails extends ChatConversation {
  customer?: Customer;
  last_message?: ChatMessage;
}

// US10: Payments & Monetization Models

export type SubscriptionPlanTier = 'starter' | 'growth' | 'business' | 'enterprise';
export type SubscriptionStatus = 'active' | 'canceled' | 'past_due' | 'trialing';
export type BillingPeriod = 'monthly' | 'yearly';

export interface Subscription {
  id: string;
  tenant_id: string;
  plan_tier: SubscriptionPlanTier;
  status: SubscriptionStatus;
  billing_period: BillingPeriod;
  current_period_start: string;
  current_period_end: string;
  cancel_at_period_end: boolean;
  payment_provider_sub_id?: string | null; // e.g. Paystack sub code
  ai_addon_enabled?: boolean;
  ai_addon_price?: number;
  created_at: string;
  updated_at: string;
}

export interface Commission {
  id: string;
  tenant_id: string;
  order_id: string;
  amount: number;
  rate_percentage: number; // e.g., 2.5
  status: 'pending' | 'paid' | 'refunded';
  created_at: string;
}

export interface SubscriptionInsert {
  tenant_id: string;
  plan_tier: SubscriptionPlanTier;
  status?: SubscriptionStatus;
  current_period_start: string;
  current_period_end: string;
}

// US: Central Product Database
export interface CatalogProduct {
  id: string;
  tenant_id?: string | null; // Null for global, set for tenant-specific master
  name: string;
  description?: string | null;
  sku?: string | null;
  barcode?: string | null;
  category?: string | null;
  image_url?: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// Update Subscription interface to include AI Add-on
export interface SubscriptionWithAddons extends Subscription {
  ai_addon_enabled: boolean;
  ai_addon_price: number;
}

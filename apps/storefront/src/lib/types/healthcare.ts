// Healthcare TypeScript Types
// Feature: 003-healthcare-consultations
// Generated: 2026-02-22

import type { Database } from './database.types';

// ============================================================================
// Database Row Types (extracted from Supabase schema)
// ============================================================================

export type HealthcareProvider = Database['public']['Tables']['healthcare_providers']['Row'];
export type ProviderAvailabilityTemplate = Database['public']['Tables']['provider_availability_templates']['Row'];
export type ProviderTimeSlot = Database['public']['Tables']['provider_time_slots']['Row'];
export type Consultation = Database['public']['Tables']['consultations']['Row'];
export type ConsultationMessage = Database['public']['Tables']['consultation_messages']['Row'];
export type Prescription = Database['public']['Tables']['prescriptions']['Row'];
export type ConsultationTransaction = Database['public']['Tables']['consultation_transactions']['Row'];
export type FavoriteProvider = Database['public']['Tables']['favorite_providers']['Row'];

// Insert types (for creating new records)
export type HealthcareProviderInsert = Database['public']['Tables']['healthcare_providers']['Insert'];
export type ConsultationInsert = Database['public']['Tables']['consultations']['Insert'];
export type ConsultationMessageInsert = Database['public']['Tables']['consultation_messages']['Insert'];
export type PrescriptionInsert = Database['public']['Tables']['prescriptions']['Insert'];
export type FavoriteProviderInsert = Database['public']['Tables']['favorite_providers']['Insert'];

// Update types (for updating records)
export type HealthcareProviderUpdate = Database['public']['Tables']['healthcare_providers']['Update'];
export type ConsultationUpdate = Database['public']['Tables']['consultations']['Update'];
export type ProviderTimeSlotUpdate = Database['public']['Tables']['provider_time_slots']['Update'];

// ============================================================================
// Enums & Constants
// ============================================================================

export type ConsultationType = 'chat' | 'video' | 'audio' | 'office_visit';

export type ConsultationStatus = 'pending' | 'in_progress' | 'completed' | 'cancelled';

export type PaymentStatus = 'pending' | 'paid' | 'failed' | 'refunded';

export type SlotStatus = 'available' | 'held_for_payment' | 'booked' | 'in_progress' | 'completed' | 'cancelled';

export type PrescriptionStatus = 'active' | 'expired' | 'fulfilled' | 'cancelled';

export type ProviderType = 'doctor' | 'pharmacist' | 'diagnostician' | 'specialist';

export type PlanTier = 'free' | 'pro' | 'enterprise_custom';

// **CRITICAL: Referral Source for Commission Attribution**
export type ReferralSource = 'storefront' | 'medic_clinic' | 'direct';

export type RoutingStrategy = 'single' | 'split' | 'partial' | 'none';

export const SLOT_DURATIONS = [15, 30, 45, 60] as const;
export type SlotDuration = typeof SLOT_DURATIONS[number];

// ============================================================================
// Extended Types (with relationships and computed fields)
// ============================================================================

/**
 * Provider with availability information
 */
export interface ProviderWithAvailability extends HealthcareProvider {
  next_available?: string; // ISO timestamp
  available_slot_count?: number;
}

/**
 * Consultation with provider and patient details
 */
export interface ConsultationDetail extends Consultation {
  provider?: Pick<HealthcareProvider, 'id' | 'full_name' | 'profile_photo_url' | 'specialization' | 'credentials'>;
  messages_count?: number;
  has_prescription?: boolean;
}

/**
 * Time slot with provider info
 */
export interface TimeSlotWithProvider extends ProviderTimeSlot {
  provider?: Pick<HealthcareProvider, 'id' | 'full_name' | 'profile_photo_url'>;
}

/**
 * Prescription with medication details
 */
export interface PrescriptionMedication {
  name: string;
  generic_name?: string;
  nafdac_number?: string;
  quantity: number;
  dosage: string; // e.g., "500mg"
  frequency: string; // e.g., "3 times daily"
  duration: string; // e.g., "7 days"
  special_instructions?: string;
}

export interface PrescriptionDetail extends Prescription {
  medications: PrescriptionMedication[];
  provider?: Pick<HealthcareProvider, 'id' | 'full_name' | 'credentials'>;
  consultation?: Pick<Consultation, 'id' | 'type' | 'created_at'>;
}

/**
 * Clinic address structure
 */
export interface ClinicAddress {
  street?: string;
  city: string;
  postal_code?: string;
  country: string;
  lat?: number;
  lng?: number;
}

/**
 * Clinic settings for branding (Growth+ and Custom plans)
 */
export interface ClinicSettings {
  clinic_name?: string;
  logo_url?: string;
  primary_color?: string; // hex color
  accent_color?: string; // hex color
  is_accepting_patients?: boolean;
}

/**
 * Consultation fees by type
 */
export interface ConsultationFees {
  chat?: number;
  video?: number;
  audio?: number;
  office_visit?: number;
}

/**
 * Pharmacy routing response
 */
export interface PharmacyRoutingDetails {
  strategy: RoutingStrategy;
  primary_pharmacy_id?: string;
  matched_pharmacies?: Array<{
    pharmacy_id: string;
    pharmacy_name: string;
    distance_km: number;
    items_available: string[];
  }>;
  unavailable_items?: string[];
}

// ============================================================================
// API Request/Response Types
// ============================================================================

/**
 * Provider directory filters
 */
export interface ProviderFilters {
  specialization?: string;
  consultation_type?: ConsultationType;
  country?: string;
  page?: number;
  limit?: number;
}

/**
 * Provider directory response
 */
export interface ProviderListResponse {
  providers: ProviderWithAvailability[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

/**
 * Consultation booking request
 */
export interface ConsultationBookingRequest {
  provider_id: string;
  consultation_type: ConsultationType;
  slot_id?: string; // Required for video/audio/office_visit, null for chat
  referral_source: ReferralSource;
  referrer_entity_id?: string; // business_id or host_medic_id
}

/**
 * Consultation booking response
 */
export interface ConsultationBookingResponse {
  consultation_id: string;
  payment_url: string;
  expires_at: string; // 5-minute hold on slot
}

/**
 * Agora token response (for joining video/audio)
 */
export interface AgoraTokenResponse {
  token: string;
  channel_name: string;
  uid: number;
  expires_at: string;
  duration_warning_at: string; // 5 min before end
}

/**
 * Message send request
 */
export interface SendMessageRequest {
  consultation_id: string;
  content: string;
  attachments?: Array<{
    url: string;
    type: string;
    name: string;
  }>;
}

/**
 * Availability query request
 */
export interface AvailabilityRequest {
  provider_id: string;
  consultation_type: ConsultationType;
  start_date: string; // YYYY-MM-DD
  end_date?: string; // YYYY-MM-DD
}

/**
 * Available slot response
 */
export interface AvailableSlot {
  id: string;
  date: string; // YYYY-MM-DD
  start_time: string; // HH:MM:SS
  end_time: string; // HH:MM:SS
  slot_duration: number;
  consultation_type: ConsultationType;
  available: boolean;
}

/**
 * Availability response
 */
export interface AvailabilityResponse {
  slots: AvailableSlot[];
  timezone: string;
}

/**
 * Cancellation request
 */
export interface CancellationRequest {
  reason?: string;
}

/**
 * Cancellation response
 */
export interface CancellationResponse {
  cancelled: boolean;
  refund_status: 'full' | 'none' | 'partial';
  refund_amount?: number;
  message: string;
}

/**
 * Rating request
 */
export interface RatingRequest {
  rating: number; // 1-5
  feedback?: string;
}

// ============================================================================
// Error Types
// ============================================================================

export interface HealthcareAPIError {
  code: string;
  message: string;
  action?: string;
}

export type HealthcareErrorCode =
  | 'SLOT_UNAVAILABLE'
  | 'PAYMENT_FAILED'
  | 'CONSULTATION_NOT_READY'
  | 'PRESCRIPTION_EXPIRED'
  | 'UNAUTHORIZED'
  | 'FORBIDDEN'
  | 'NOT_FOUND'
  | 'VALIDATION_ERROR'
  | 'PLAN_REQUIRED'
  | 'BUSINESS_TYPE_RESTRICTED';

// ============================================================================
// UI State Types
// ============================================================================

/**
 * Consultation chat UI state
 */
export interface ChatState {
  consultation_id: string;
  messages: ConsultationMessage[];
  is_loading: boolean;
  is_typing: boolean;
  connection_status: 'connected' | 'disconnected' | 'reconnecting';
}

/**
 * Video room UI state
 */
export interface VideoRoomState {
  consultation_id: string;
  is_joined: boolean;
  local_audio_enabled: boolean;
  local_video_enabled: boolean;
  remote_users: string[];
  network_quality: 'excellent' | 'good' | 'poor' | 'bad';
  remaining_minutes: number;
  show_warning: boolean;
}

/**
 * Booking form state
 */
export interface BookingFormState {
  selected_provider?: HealthcareProvider;
  selected_type?: ConsultationType;
  selected_slot?: AvailableSlot;
  is_submitting: boolean;
  error?: string;
}

// ============================================================================
// Helper Types
// ============================================================================

/**
 * Pagination parameters
 */
export interface PaginationParams {
  page: number;
  limit: number;
}

/**
 * Sort parameters
 */
export interface SortParams {
  field: string;
  direction: 'asc' | 'desc';
}

/**
 * Date range filter
 */
export interface DateRangeFilter {
  start_date: string; // YYYY-MM-DD
  end_date: string; // YYYY-MM-DD
}

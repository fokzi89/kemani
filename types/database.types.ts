export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      tenants: {
        Row: {
          id: string
          name: string
          slug: string
          email: string | null
          phone: string | null
          logo_url: string | null
          brand_color: string | null
          subscription_id: string | null
          created_at: string
          updated_at: string
          deleted_at: string | null
        }
        Insert: {
          id?: string
          name: string
          slug?: string
          email?: string | null
          phone?: string | null
          logo_url?: string | null
          brand_color?: string | null
          subscription_id?: string | null
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Update: {
          id?: string
          name?: string
          slug?: string
          email?: string | null
          phone?: string | null
          logo_url?: string | null
          brand_color?: string | null
          subscription_id?: string | null
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
      }
      branches: {
        Row: {
          id: string
          tenant_id: string
          name: string
          business_type: 'retail' | 'service' | 'hybrid' | 'food' // approximating
          address: string | null
          latitude: number | null
          longitude: number | null
          phone: string | null
          tax_rate: number | null
          currency: string | null
          is_main: boolean // wait, migration didn't show is_main column?
          created_at: string
          updated_at: string
          deleted_at: string | null
        }
        Insert: {
          id?: string
          tenant_id: string
          name: string
          business_type?: 'retail' | 'service' | 'hybrid' | 'food'
          address?: string | null
          latitude?: number | null
          longitude?: number | null
          phone?: string | null
          tax_rate?: number | null
          currency?: string | null
          is_main?: boolean
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Update: {
          id?: string
          tenant_id?: string
          name?: string
          business_type?: 'retail' | 'service' | 'hybrid' | 'food'
          address?: string | null
          latitude?: number | null
          longitude?: number | null
          phone?: string | null
          tax_rate?: number | null
          currency?: string | null
          is_main?: boolean
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
      }
      users: {
        Row: {
          id: string
          tenant_id: string | null
          email: string | null
          phone: string | null
          full_name: string
          role: 'super_admin' | 'tenant_admin' | 'branch_manager' | 'staff' | 'rider'
          branch_id: string | null
          avatar_url: string | null
          last_login_at: string | null
          status: string // check migration for status 
          created_at: string
          updated_at: string
          deleted_at: string | null
        }
        Insert: {
          id: string
          tenant_id?: string | null
          email?: string | null
          phone?: string | null
          full_name: string
          role: 'super_admin' | 'tenant_admin' | 'branch_manager' | 'staff' | 'rider'
          branch_id?: string | null
          avatar_url?: string | null
          last_login_at?: string | null
          status?: string
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Update: {
          id?: string
          tenant_id?: string | null
          email?: string | null
          phone?: string | null
          full_name?: string
          role?: 'super_admin' | 'tenant_admin' | 'branch_manager' | 'staff' | 'rider'
          branch_id?: string | null
          avatar_url?: string | null
          last_login_at?: string | null
          status?: string
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
      }
      subscriptions: {
        Row: {
          id: string
          plan_tier: 'free' | 'basic' | 'pro' | 'enterprise' | 'enterprise_custom'
          monthly_fee: number
          commission_rate: number
          max_branches: number
          max_staff_users: number
          max_products: number
          monthly_transaction_quota: number
          features: Json | null
          billing_cycle_start: string
          billing_cycle_end: string
          status: 'active' | 'inactive' | 'past_due' | 'cancelled'
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          plan_tier: 'free' | 'basic' | 'pro' | 'enterprise' | 'enterprise_custom'
          monthly_fee: number
          commission_rate: number
          max_branches: number
          max_staff_users: number
          max_products: number
          monthly_transaction_quota: number
          features?: Json | null
          billing_cycle_start: string
          billing_cycle_end: string
          status?: 'active' | 'inactive' | 'past_due' | 'cancelled'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          plan_tier?: 'free' | 'basic' | 'pro' | 'enterprise' | 'enterprise_custom'
          monthly_fee?: number
          commission_rate?: number
          max_branches?: number
          max_staff_users?: number
          max_products?: number
          monthly_transaction_quota?: number
          features?: Json | null
          billing_cycle_start?: string
          billing_cycle_end?: string
          status?: 'active' | 'inactive' | 'past_due' | 'cancelled'
          created_at?: string
          updated_at?: string
        }
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      user_role: 'super_admin' | 'tenant_admin' | 'branch_manager' | 'staff' | 'rider'
      plan_tier: 'free' | 'basic' | 'pro' | 'enterprise' | 'enterprise_custom'
      subscription_status: 'active' | 'inactive' | 'past_due' | 'cancelled'
      business_type: 'retail' | 'service' | 'hybrid' | 'food'
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

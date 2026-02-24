export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.1"
  }
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      audit_logs: {
        Row: {
          action: string
          created_at: string | null
          entity_id: string | null
          entity_type: string | null
          id: string
          metadata: Json | null
          new_values: Json | null
          old_values: Json | null
          tenant_id: string | null
          user_id: string | null
          user_ip_address: unknown
          user_role: string | null
        }
        Insert: {
          action: string
          created_at?: string | null
          entity_id?: string | null
          entity_type?: string | null
          id?: string
          metadata?: Json | null
          new_values?: Json | null
          old_values?: Json | null
          tenant_id?: string | null
          user_id?: string | null
          user_ip_address?: unknown
          user_role?: string | null
        }
        Update: {
          action?: string
          created_at?: string | null
          entity_id?: string | null
          entity_type?: string | null
          id?: string
          metadata?: Json | null
          new_values?: Json | null
          old_values?: Json | null
          tenant_id?: string | null
          user_id?: string | null
          user_ip_address?: unknown
          user_role?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "audit_logs_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "audit_logs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      branches: {
        Row: {
          address: string | null
          business_type: Database["public"]["Enums"]["business_type"]
          created_at: string
          currency: string | null
          deleted_at: string | null
          id: string
          latitude: number | null
          longitude: number | null
          name: string
          phone: string | null
          tax_rate: number | null
          tenant_id: string
          updated_at: string
        }
        Insert: {
          address?: string | null
          business_type: Database["public"]["Enums"]["business_type"]
          created_at?: string
          currency?: string | null
          deleted_at?: string | null
          id?: string
          latitude?: number | null
          longitude?: number | null
          name: string
          phone?: string | null
          tax_rate?: number | null
          tenant_id: string
          updated_at?: string
        }
        Update: {
          address?: string | null
          business_type?: Database["public"]["Enums"]["business_type"]
          created_at?: string
          currency?: string | null
          deleted_at?: string | null
          id?: string
          latitude?: number | null
          longitude?: number | null
          name?: string
          phone?: string | null
          tax_rate?: number | null
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "branches_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      brands: {
        Row: {
          code: string | null
          created_at: string | null
          description: string | null
          id: string
          is_active: boolean | null
          is_house_brand: boolean | null
          logo_url: string | null
          name: string
          tenant_id: string
          tier: string | null
          updated_at: string | null
        }
        Insert: {
          code?: string | null
          created_at?: string | null
          description?: string | null
          id?: string
          is_active?: boolean | null
          is_house_brand?: boolean | null
          logo_url?: string | null
          name: string
          tenant_id: string
          tier?: string | null
          updated_at?: string | null
        }
        Update: {
          code?: string | null
          created_at?: string | null
          description?: string | null
          id?: string
          is_active?: boolean | null
          is_house_brand?: boolean | null
          logo_url?: string | null
          name?: string
          tenant_id?: string
          tier?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "brands_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      cart_items: {
        Row: {
          added_at: string
          cart_id: string
          id: string
          product_id: string
          quantity: number
          unit_price: number
          updated_at: string
          variant_id: string | null
        }
        Insert: {
          added_at?: string
          cart_id: string
          id?: string
          product_id: string
          quantity?: number
          unit_price: number
          updated_at?: string
          variant_id?: string | null
        }
        Update: {
          added_at?: string
          cart_id?: string
          id?: string
          product_id?: string
          quantity?: number
          unit_price?: number
          updated_at?: string
          variant_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "cart_items_cart_id_fkey"
            columns: ["cart_id"]
            isOneToOne: false
            referencedRelation: "shopping_carts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cart_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "storefront_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cart_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "storefront_products_with_catalog"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cart_items_variant_id_fkey"
            columns: ["variant_id"]
            isOneToOne: false
            referencedRelation: "product_variants"
            referencedColumns: ["id"]
          },
        ]
      }
      categories: {
        Row: {
          code: string | null
          created_at: string | null
          description: string | null
          id: string
          is_active: boolean | null
          level: number | null
          name: string
          parent_category_id: string | null
          path: string | null
          sort_order: number | null
          tenant_id: string
          updated_at: string | null
        }
        Insert: {
          code?: string | null
          created_at?: string | null
          description?: string | null
          id?: string
          is_active?: boolean | null
          level?: number | null
          name: string
          parent_category_id?: string | null
          path?: string | null
          sort_order?: number | null
          tenant_id: string
          updated_at?: string | null
        }
        Update: {
          code?: string | null
          created_at?: string | null
          description?: string | null
          id?: string
          is_active?: boolean | null
          level?: number | null
          name?: string
          parent_category_id?: string | null
          path?: string | null
          sort_order?: number | null
          tenant_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "categories_parent_category_id_fkey"
            columns: ["parent_category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "categories_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      chat_attachments: {
        Row: {
          file_name: string
          file_size: number
          file_type: string
          id: string
          message_id: string
          mime_type: string
          session_id: string
          storage_bucket: string
          storage_path: string
          storage_url: string
          uploaded_at: string
          uploaded_by: string
        }
        Insert: {
          file_name: string
          file_size: number
          file_type: string
          id?: string
          message_id: string
          mime_type: string
          session_id: string
          storage_bucket?: string
          storage_path: string
          storage_url: string
          uploaded_at?: string
          uploaded_by: string
        }
        Update: {
          file_name?: string
          file_size?: number
          file_type?: string
          id?: string
          message_id?: string
          mime_type?: string
          session_id?: string
          storage_bucket?: string
          storage_path?: string
          storage_url?: string
          uploaded_at?: string
          uploaded_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "chat_attachments_message_id_fkey"
            columns: ["message_id"]
            isOneToOne: false
            referencedRelation: "chat_messages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_attachments_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "chat_sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      chat_conversations: {
        Row: {
          branch_id: string
          customer_id: string
          ended_at: string | null
          escalated_to_user_id: string | null
          id: string
          order_id: string | null
          started_at: string
          status: Database["public"]["Enums"]["chat_status"] | null
          tenant_id: string
        }
        Insert: {
          branch_id: string
          customer_id: string
          ended_at?: string | null
          escalated_to_user_id?: string | null
          id?: string
          order_id?: string | null
          started_at?: string
          status?: Database["public"]["Enums"]["chat_status"] | null
          tenant_id: string
        }
        Update: {
          branch_id?: string
          customer_id?: string
          ended_at?: string | null
          escalated_to_user_id?: string | null
          id?: string
          order_id?: string | null
          started_at?: string
          status?: Database["public"]["Enums"]["chat_status"] | null
          tenant_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "chat_conversations_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_conversations_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "customers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_conversations_escalated_to_user_id_fkey"
            columns: ["escalated_to_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_conversations_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_conversations_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      chat_messages: {
        Row: {
          action_completed_at: string | null
          action_completed_by: string | null
          action_data: Json | null
          action_type: Database["public"]["Enums"]["chat_action_type"] | null
          confidence_score: number | null
          conversation_id: string
          created_at: string
          id: string
          intent: string | null
          media_duration_seconds: number | null
          media_size_bytes: number | null
          media_url: string | null
          message_text: string | null
          message_type: Database["public"]["Enums"]["chat_message_type"] | null
          metadata: Json | null
          product_id: string | null
          sender_id: string | null
          sender_type: Database["public"]["Enums"]["sender_type"]
          session_id: string | null
          tenant_id: string | null
          thumbnail_url: string | null
          updated_at: string
        }
        Insert: {
          action_completed_at?: string | null
          action_completed_by?: string | null
          action_data?: Json | null
          action_type?: Database["public"]["Enums"]["chat_action_type"] | null
          confidence_score?: number | null
          conversation_id: string
          created_at?: string
          id?: string
          intent?: string | null
          media_duration_seconds?: number | null
          media_size_bytes?: number | null
          media_url?: string | null
          message_text?: string | null
          message_type?: Database["public"]["Enums"]["chat_message_type"] | null
          metadata?: Json | null
          product_id?: string | null
          sender_id?: string | null
          sender_type: Database["public"]["Enums"]["sender_type"]
          session_id?: string | null
          tenant_id?: string | null
          thumbnail_url?: string | null
          updated_at?: string
        }
        Update: {
          action_completed_at?: string | null
          action_completed_by?: string | null
          action_data?: Json | null
          action_type?: Database["public"]["Enums"]["chat_action_type"] | null
          confidence_score?: number | null
          conversation_id?: string
          created_at?: string
          id?: string
          intent?: string | null
          media_duration_seconds?: number | null
          media_size_bytes?: number | null
          media_url?: string | null
          message_text?: string | null
          message_type?: Database["public"]["Enums"]["chat_message_type"] | null
          metadata?: Json | null
          product_id?: string | null
          sender_id?: string | null
          sender_type?: Database["public"]["Enums"]["sender_type"]
          session_id?: string | null
          tenant_id?: string | null
          thumbnail_url?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "chat_messages_action_completed_by_fkey"
            columns: ["action_completed_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_messages_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "chat_conversations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_messages_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "storefront_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_messages_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "storefront_products_with_catalog"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_messages_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_messages_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "chat_sessions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_messages_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      chat_sessions: {
        Row: {
          agent_id: string | null
          agent_type: string
          branch_id: string
          created_at: string
          customer_id: string | null
          id: string
          last_message_at: string | null
          resolved_at: string | null
          session_token: string
          status: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          agent_id?: string | null
          agent_type?: string
          branch_id: string
          created_at?: string
          customer_id?: string | null
          id?: string
          last_message_at?: string | null
          resolved_at?: string | null
          session_token: string
          status?: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          agent_id?: string | null
          agent_type?: string
          branch_id?: string
          created_at?: string
          customer_id?: string | null
          id?: string
          last_message_at?: string | null
          resolved_at?: string | null
          session_token?: string
          status?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "chat_sessions_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_sessions_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "storefront_customers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_sessions_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      commissions: {
        Row: {
          commission_amount: number
          commission_rate: number
          created_at: string
          id: string
          order_id: string
          sale_amount: number
          settlement_date: string | null
          settlement_status:
            | Database["public"]["Enums"]["settlement_status"]
            | null
          tenant_id: string
        }
        Insert: {
          commission_amount: number
          commission_rate: number
          created_at?: string
          id?: string
          order_id: string
          sale_amount: number
          settlement_date?: string | null
          settlement_status?:
            | Database["public"]["Enums"]["settlement_status"]
            | null
          tenant_id: string
        }
        Update: {
          commission_amount?: number
          commission_rate?: number
          created_at?: string
          id?: string
          order_id?: string
          sale_amount?: number
          settlement_date?: string | null
          settlement_status?:
            | Database["public"]["Enums"]["settlement_status"]
            | null
          tenant_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "commissions_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: true
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "commissions_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      consultation_messages: {
        Row: {
          attachments: Json | null
          consultation_id: string
          content: string
          created_at: string | null
          id: string
          read_at: string | null
          sender_id: string
          sender_type: string
        }
        Insert: {
          attachments?: Json | null
          consultation_id: string
          content: string
          created_at?: string | null
          id?: string
          read_at?: string | null
          sender_id: string
          sender_type: string
        }
        Update: {
          attachments?: Json | null
          consultation_id?: string
          content?: string
          created_at?: string | null
          id?: string
          read_at?: string | null
          sender_id?: string
          sender_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "consultation_messages_consultation_id_fkey"
            columns: ["consultation_id"]
            isOneToOne: false
            referencedRelation: "consultations"
            referencedColumns: ["id"]
          },
        ]
      }
      consultation_transactions: {
        Row: {
          commission_amount: number
          commission_rate: number
          commission_reversed: boolean | null
          consultation_id: string
          created_at: string | null
          gross_amount: number
          id: string
          net_provider_amount: number
          patient_id: string
          payment_method: string | null
          payment_reference: string | null
          payment_status: string | null
          payout_date: string | null
          payout_reference: string | null
          payout_status: string | null
          provider_id: string
          referral_source: string
          referrer_commission_amount: number | null
          referrer_entity_id: string | null
          refund_amount: number | null
          refund_reason: string | null
          refunded_at: string | null
          tenant_id: string
          updated_at: string | null
        }
        Insert: {
          commission_amount: number
          commission_rate: number
          commission_reversed?: boolean | null
          consultation_id: string
          created_at?: string | null
          gross_amount: number
          id?: string
          net_provider_amount: number
          patient_id: string
          payment_method?: string | null
          payment_reference?: string | null
          payment_status?: string | null
          payout_date?: string | null
          payout_reference?: string | null
          payout_status?: string | null
          provider_id: string
          referral_source: string
          referrer_commission_amount?: number | null
          referrer_entity_id?: string | null
          refund_amount?: number | null
          refund_reason?: string | null
          refunded_at?: string | null
          tenant_id: string
          updated_at?: string | null
        }
        Update: {
          commission_amount?: number
          commission_rate?: number
          commission_reversed?: boolean | null
          consultation_id?: string
          created_at?: string | null
          gross_amount?: number
          id?: string
          net_provider_amount?: number
          patient_id?: string
          payment_method?: string | null
          payment_reference?: string | null
          payment_status?: string | null
          payout_date?: string | null
          payout_reference?: string | null
          payout_status?: string | null
          provider_id?: string
          referral_source?: string
          referrer_commission_amount?: number | null
          referrer_entity_id?: string | null
          refund_amount?: number | null
          refund_reason?: string | null
          refunded_at?: string | null
          tenant_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "consultation_transactions_consultation_id_fkey"
            columns: ["consultation_id"]
            isOneToOne: true
            referencedRelation: "consultations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "consultation_transactions_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: false
            referencedRelation: "healthcare_providers"
            referencedColumns: ["id"]
          },
        ]
      }
      consultations: {
        Row: {
          agora_channel_name: string | null
          agora_token_expiry: string | null
          agora_token_patient: string | null
          agora_token_provider: string | null
          commission_calculated_at: string | null
          consultation_fee: number
          created_at: string | null
          ended_at: string | null
          id: string
          location_address: Json | null
          paid_at: string | null
          patient_id: string
          payment_reference: string | null
          payment_status: string | null
          provider_id: string
          provider_name: string
          provider_photo_url: string | null
          referral_source: string
          referrer_entity_id: string | null
          scheduled_time: string | null
          slot_duration: number | null
          started_at: string | null
          status: string | null
          tenant_id: string
          type: string
          updated_at: string | null
        }
        Insert: {
          agora_channel_name?: string | null
          agora_token_expiry?: string | null
          agora_token_patient?: string | null
          agora_token_provider?: string | null
          commission_calculated_at?: string | null
          consultation_fee: number
          created_at?: string | null
          ended_at?: string | null
          id?: string
          location_address?: Json | null
          paid_at?: string | null
          patient_id: string
          payment_reference?: string | null
          payment_status?: string | null
          provider_id: string
          provider_name: string
          provider_photo_url?: string | null
          referral_source: string
          referrer_entity_id?: string | null
          scheduled_time?: string | null
          slot_duration?: number | null
          started_at?: string | null
          status?: string | null
          tenant_id: string
          type: string
          updated_at?: string | null
        }
        Update: {
          agora_channel_name?: string | null
          agora_token_expiry?: string | null
          agora_token_patient?: string | null
          agora_token_provider?: string | null
          commission_calculated_at?: string | null
          consultation_fee?: number
          created_at?: string | null
          ended_at?: string | null
          id?: string
          location_address?: Json | null
          paid_at?: string | null
          patient_id?: string
          payment_reference?: string | null
          payment_status?: string | null
          provider_id?: string
          provider_name?: string
          provider_photo_url?: string | null
          referral_source?: string
          referrer_entity_id?: string | null
          scheduled_time?: string | null
          slot_duration?: number | null
          started_at?: string | null
          status?: string | null
          tenant_id?: string
          type?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "consultations_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: false
            referencedRelation: "healthcare_providers"
            referencedColumns: ["id"]
          },
        ]
      }
      customer_addresses: {
        Row: {
          address_line: string
          customer_id: string
          id: string
          is_default: boolean | null
          label: string | null
          latitude: number | null
          longitude: number | null
          tenant_id: string | null
        }
        Insert: {
          address_line: string
          customer_id: string
          id?: string
          is_default?: boolean | null
          label?: string | null
          latitude?: number | null
          longitude?: number | null
          tenant_id?: string | null
        }
        Update: {
          address_line?: string
          customer_id?: string
          id?: string
          is_default?: boolean | null
          label?: string | null
          latitude?: number | null
          longitude?: number | null
          tenant_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "customer_addresses_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "customers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "customer_addresses_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      customers: {
        Row: {
          _sync_client_id: string | null
          _sync_is_deleted: boolean | null
          _sync_modified_at: string | null
          _sync_version: number | null
          created_at: string
          deleted_at: string | null
          email: string | null
          full_name: string
          id: string
          last_purchase_at: string | null
          loyalty_points: number
          phone: string
          purchase_count: number | null
          tenant_id: string
          total_purchases: number | null
          updated_at: string
          whatsapp_number: string | null
        }
        Insert: {
          _sync_client_id?: string | null
          _sync_is_deleted?: boolean | null
          _sync_modified_at?: string | null
          _sync_version?: number | null
          created_at?: string
          deleted_at?: string | null
          email?: string | null
          full_name: string
          id?: string
          last_purchase_at?: string | null
          loyalty_points?: number
          phone: string
          purchase_count?: number | null
          tenant_id: string
          total_purchases?: number | null
          updated_at?: string
          whatsapp_number?: string | null
        }
        Update: {
          _sync_client_id?: string | null
          _sync_is_deleted?: boolean | null
          _sync_modified_at?: string | null
          _sync_version?: number | null
          created_at?: string
          deleted_at?: string | null
          email?: string | null
          full_name?: string
          id?: string
          last_purchase_at?: string | null
          loyalty_points?: number
          phone?: string
          purchase_count?: number | null
          tenant_id?: string
          total_purchases?: number | null
          updated_at?: string
          whatsapp_number?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "customers_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      deliveries: {
        Row: {
          _sync_modified_at: string | null
          _sync_version: number | null
          actual_delivery_time: string | null
          branch_id: string
          created_at: string
          customer_address: string
          customer_latitude: number | null
          customer_longitude: number | null
          customer_phone: string
          delivery_status: Database["public"]["Enums"]["delivery_status"] | null
          delivery_type: Database["public"]["Enums"]["delivery_type"]
          distance_km: number | null
          estimated_delivery_time: string | null
          failure_reason: string | null
          id: string
          order_id: string
          proof_data: string | null
          proof_type: Database["public"]["Enums"]["proof_type"] | null
          rider_id: string | null
          tenant_id: string
          tracking_number: string
          updated_at: string
        }
        Insert: {
          _sync_modified_at?: string | null
          _sync_version?: number | null
          actual_delivery_time?: string | null
          branch_id: string
          created_at?: string
          customer_address: string
          customer_latitude?: number | null
          customer_longitude?: number | null
          customer_phone: string
          delivery_status?:
            | Database["public"]["Enums"]["delivery_status"]
            | null
          delivery_type: Database["public"]["Enums"]["delivery_type"]
          distance_km?: number | null
          estimated_delivery_time?: string | null
          failure_reason?: string | null
          id?: string
          order_id: string
          proof_data?: string | null
          proof_type?: Database["public"]["Enums"]["proof_type"] | null
          rider_id?: string | null
          tenant_id: string
          tracking_number: string
          updated_at?: string
        }
        Update: {
          _sync_modified_at?: string | null
          _sync_version?: number | null
          actual_delivery_time?: string | null
          branch_id?: string
          created_at?: string
          customer_address?: string
          customer_latitude?: number | null
          customer_longitude?: number | null
          customer_phone?: string
          delivery_status?:
            | Database["public"]["Enums"]["delivery_status"]
            | null
          delivery_type?: Database["public"]["Enums"]["delivery_type"]
          distance_km?: number | null
          estimated_delivery_time?: string | null
          failure_reason?: string | null
          id?: string
          order_id?: string
          proof_data?: string | null
          proof_type?: Database["public"]["Enums"]["proof_type"] | null
          rider_id?: string | null
          tenant_id?: string
          tracking_number?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "deliveries_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "deliveries_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: true
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "deliveries_rider_id_fkey"
            columns: ["rider_id"]
            isOneToOne: false
            referencedRelation: "riders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "deliveries_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      dim_date: {
        Row: {
          created_at: string | null
          date_key: number
          date_value: string
          day: number
          day_of_week: number
          day_of_week_name: string
          day_of_year: number
          fiscal_month: number | null
          fiscal_quarter: number | null
          fiscal_year: number | null
          holiday_name: string | null
          is_business_day: boolean
          is_holiday: boolean | null
          is_weekend: boolean
          month: number
          month_abbr: string
          month_end_date: string
          month_name: string
          month_start_date: string
          prior_day_key: number | null
          prior_month_key: number | null
          prior_quarter_key: number | null
          prior_week_key: number | null
          prior_year_key: number | null
          quarter: number
          quarter_end_date: string
          quarter_name: string
          quarter_start_date: string
          week_end_date: string
          week_of_year: number
          week_start_date: string
          year: number
          year_end_date: string
          year_start_date: string
        }
        Insert: {
          created_at?: string | null
          date_key: number
          date_value: string
          day: number
          day_of_week: number
          day_of_week_name: string
          day_of_year: number
          fiscal_month?: number | null
          fiscal_quarter?: number | null
          fiscal_year?: number | null
          holiday_name?: string | null
          is_business_day: boolean
          is_holiday?: boolean | null
          is_weekend: boolean
          month: number
          month_abbr: string
          month_end_date: string
          month_name: string
          month_start_date: string
          prior_day_key?: number | null
          prior_month_key?: number | null
          prior_quarter_key?: number | null
          prior_week_key?: number | null
          prior_year_key?: number | null
          quarter: number
          quarter_end_date: string
          quarter_name: string
          quarter_start_date: string
          week_end_date: string
          week_of_year: number
          week_start_date: string
          year: number
          year_end_date: string
          year_start_date: string
        }
        Update: {
          created_at?: string | null
          date_key?: number
          date_value?: string
          day?: number
          day_of_week?: number
          day_of_week_name?: string
          day_of_year?: number
          fiscal_month?: number | null
          fiscal_quarter?: number | null
          fiscal_year?: number | null
          holiday_name?: string | null
          is_business_day?: boolean
          is_holiday?: boolean | null
          is_weekend?: boolean
          month?: number
          month_abbr?: string
          month_end_date?: string
          month_name?: string
          month_start_date?: string
          prior_day_key?: number | null
          prior_month_key?: number | null
          prior_quarter_key?: number | null
          prior_week_key?: number | null
          prior_year_key?: number | null
          quarter?: number
          quarter_end_date?: string
          quarter_name?: string
          quarter_start_date?: string
          week_end_date?: string
          week_of_year?: number
          week_start_date?: string
          year?: number
          year_end_date?: string
          year_start_date?: string
        }
        Relationships: []
      }
      dim_time: {
        Row: {
          am_pm: string
          business_hour: string
          created_at: string | null
          hour: number
          hour_12: number
          hour_bucket: number
          is_peak_hour: boolean | null
          minute: number
          minute_bucket: number
          second: number
          time_key: number
          time_period: string
          time_value: string
        }
        Insert: {
          am_pm: string
          business_hour: string
          created_at?: string | null
          hour: number
          hour_12: number
          hour_bucket: number
          is_peak_hour?: boolean | null
          minute: number
          minute_bucket: number
          second: number
          time_key: number
          time_period: string
          time_value: string
        }
        Update: {
          am_pm?: string
          business_hour?: string
          created_at?: string | null
          hour?: number
          hour_12?: number
          hour_bucket?: number
          is_peak_hour?: boolean | null
          minute?: number
          minute_bucket?: number
          second?: number
          time_key?: number
          time_period?: string
          time_value?: string
        }
        Relationships: []
      }
      ecommerce_connections: {
        Row: {
          api_key: string
          api_secret: string | null
          created_at: string
          id: string
          last_sync_at: string | null
          platform_name: string | null
          platform_type: Database["public"]["Enums"]["platform_type"]
          store_url: string
          sync_enabled: boolean | null
          sync_error: string | null
          sync_interval_minutes: number | null
          sync_status: Database["public"]["Enums"]["sync_status"] | null
          tenant_id: string
          updated_at: string
        }
        Insert: {
          api_key: string
          api_secret?: string | null
          created_at?: string
          id?: string
          last_sync_at?: string | null
          platform_name?: string | null
          platform_type: Database["public"]["Enums"]["platform_type"]
          store_url: string
          sync_enabled?: boolean | null
          sync_error?: string | null
          sync_interval_minutes?: number | null
          sync_status?: Database["public"]["Enums"]["sync_status"] | null
          tenant_id: string
          updated_at?: string
        }
        Update: {
          api_key?: string
          api_secret?: string | null
          created_at?: string
          id?: string
          last_sync_at?: string | null
          platform_name?: string | null
          platform_type?: Database["public"]["Enums"]["platform_type"]
          store_url?: string
          sync_enabled?: boolean | null
          sync_error?: string | null
          sync_interval_minutes?: number | null
          sync_status?: Database["public"]["Enums"]["sync_status"] | null
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "ecommerce_connections_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      fact_brand_sales: {
        Row: {
          average_profit_margin: number | null
          branch_id: string
          brand_id: string
          brand_name: string
          category_id: string | null
          category_name: string | null
          created_at: string | null
          date_key: number
          id: string | null
          quantity_sold: number | null
          sale_date: string
          tenant_id: string
          total_cost: number | null
          total_profit: number | null
          total_revenue: number | null
          transaction_count: number | null
          unique_products_sold: number | null
          updated_at: string | null
        }
        Insert: {
          average_profit_margin?: number | null
          branch_id: string
          brand_id: string
          brand_name: string
          category_id?: string | null
          category_name?: string | null
          created_at?: string | null
          date_key: number
          id?: string | null
          quantity_sold?: number | null
          sale_date: string
          tenant_id: string
          total_cost?: number | null
          total_profit?: number | null
          total_revenue?: number | null
          transaction_count?: number | null
          unique_products_sold?: number | null
          updated_at?: string | null
        }
        Update: {
          average_profit_margin?: number | null
          branch_id?: string
          brand_id?: string
          brand_name?: string
          category_id?: string | null
          category_name?: string | null
          created_at?: string | null
          date_key?: number
          id?: string | null
          quantity_sold?: number | null
          sale_date?: string
          tenant_id?: string
          total_cost?: number | null
          total_profit?: number | null
          total_revenue?: number | null
          transaction_count?: number | null
          unique_products_sold?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fact_brand_sales_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fact_brand_sales_brand_id_fkey"
            columns: ["brand_id"]
            isOneToOne: false
            referencedRelation: "brands"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fact_brand_sales_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fact_brand_sales_date_key_fkey"
            columns: ["date_key"]
            isOneToOne: false
            referencedRelation: "dim_date"
            referencedColumns: ["date_key"]
          },
          {
            foreignKeyName: "fact_brand_sales_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      fact_daily_sales: {
        Row: {
          average_profit_margin: number | null
          average_transaction_value: number | null
          branch_id: string
          card_revenue: number | null
          card_transactions: number | null
          cash_revenue: number | null
          cash_transactions: number | null
          created_at: string | null
          date_key: number
          id: string | null
          new_customers: number | null
          refund_amount: number | null
          refund_transactions: number | null
          returning_customers: number | null
          sale_date: string
          tenant_id: string
          total_cost: number | null
          total_items_sold: number | null
          total_profit: number | null
          total_revenue: number | null
          total_transactions: number | null
          transfer_revenue: number | null
          transfer_transactions: number | null
          unique_customers: number | null
          updated_at: string | null
          void_amount: number | null
          void_transactions: number | null
        }
        Insert: {
          average_profit_margin?: number | null
          average_transaction_value?: number | null
          branch_id: string
          card_revenue?: number | null
          card_transactions?: number | null
          cash_revenue?: number | null
          cash_transactions?: number | null
          created_at?: string | null
          date_key: number
          id?: string | null
          new_customers?: number | null
          refund_amount?: number | null
          refund_transactions?: number | null
          returning_customers?: number | null
          sale_date: string
          tenant_id: string
          total_cost?: number | null
          total_items_sold?: number | null
          total_profit?: number | null
          total_revenue?: number | null
          total_transactions?: number | null
          transfer_revenue?: number | null
          transfer_transactions?: number | null
          unique_customers?: number | null
          updated_at?: string | null
          void_amount?: number | null
          void_transactions?: number | null
        }
        Update: {
          average_profit_margin?: number | null
          average_transaction_value?: number | null
          branch_id?: string
          card_revenue?: number | null
          card_transactions?: number | null
          cash_revenue?: number | null
          cash_transactions?: number | null
          created_at?: string | null
          date_key?: number
          id?: string | null
          new_customers?: number | null
          refund_amount?: number | null
          refund_transactions?: number | null
          returning_customers?: number | null
          sale_date?: string
          tenant_id?: string
          total_cost?: number | null
          total_items_sold?: number | null
          total_profit?: number | null
          total_revenue?: number | null
          total_transactions?: number | null
          transfer_revenue?: number | null
          transfer_transactions?: number | null
          unique_customers?: number | null
          updated_at?: string | null
          void_amount?: number | null
          void_transactions?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "fact_daily_sales_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fact_daily_sales_date_key_fkey"
            columns: ["date_key"]
            isOneToOne: false
            referencedRelation: "dim_date"
            referencedColumns: ["date_key"]
          },
          {
            foreignKeyName: "fact_daily_sales_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      fact_hourly_sales: {
        Row: {
          average_transaction_value: number | null
          branch_id: string
          created_at: string | null
          date_key: number
          hour: number
          id: string | null
          sale_date: string
          tenant_id: string
          time_key: number
          total_revenue: number | null
          total_transactions: number | null
          updated_at: string | null
        }
        Insert: {
          average_transaction_value?: number | null
          branch_id: string
          created_at?: string | null
          date_key: number
          hour: number
          id?: string | null
          sale_date: string
          tenant_id: string
          time_key: number
          total_revenue?: number | null
          total_transactions?: number | null
          updated_at?: string | null
        }
        Update: {
          average_transaction_value?: number | null
          branch_id?: string
          created_at?: string | null
          date_key?: number
          hour?: number
          id?: string | null
          sale_date?: string
          tenant_id?: string
          time_key?: number
          total_revenue?: number | null
          total_transactions?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fact_hourly_sales_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fact_hourly_sales_date_key_fkey"
            columns: ["date_key"]
            isOneToOne: false
            referencedRelation: "dim_date"
            referencedColumns: ["date_key"]
          },
          {
            foreignKeyName: "fact_hourly_sales_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fact_hourly_sales_time_key_fkey"
            columns: ["time_key"]
            isOneToOne: false
            referencedRelation: "dim_time"
            referencedColumns: ["time_key"]
          },
        ]
      }
      fact_product_sales: {
        Row: {
          average_discount_percentage: number | null
          average_profit_margin: number | null
          average_unit_price: number | null
          branch_id: string
          brand_id: string | null
          brand_name: string | null
          category_id: string | null
          category_name: string | null
          created_at: string | null
          date_key: number
          id: string | null
          product_id: string
          product_name: string
          product_sku: string | null
          quantity_sold: number | null
          sale_date: string
          tenant_id: string
          total_cost: number | null
          total_discount_amount: number | null
          total_profit: number | null
          total_revenue: number | null
          transaction_count: number | null
          updated_at: string | null
        }
        Insert: {
          average_discount_percentage?: number | null
          average_profit_margin?: number | null
          average_unit_price?: number | null
          branch_id: string
          brand_id?: string | null
          brand_name?: string | null
          category_id?: string | null
          category_name?: string | null
          created_at?: string | null
          date_key: number
          id?: string | null
          product_id: string
          product_name: string
          product_sku?: string | null
          quantity_sold?: number | null
          sale_date: string
          tenant_id: string
          total_cost?: number | null
          total_discount_amount?: number | null
          total_profit?: number | null
          total_revenue?: number | null
          transaction_count?: number | null
          updated_at?: string | null
        }
        Update: {
          average_discount_percentage?: number | null
          average_profit_margin?: number | null
          average_unit_price?: number | null
          branch_id?: string
          brand_id?: string | null
          brand_name?: string | null
          category_id?: string | null
          category_name?: string | null
          created_at?: string | null
          date_key?: number
          id?: string | null
          product_id?: string
          product_name?: string
          product_sku?: string | null
          quantity_sold?: number | null
          sale_date?: string
          tenant_id?: string
          total_cost?: number | null
          total_discount_amount?: number | null
          total_profit?: number | null
          total_revenue?: number | null
          transaction_count?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fact_product_sales_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fact_product_sales_brand_id_fkey"
            columns: ["brand_id"]
            isOneToOne: false
            referencedRelation: "brands"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fact_product_sales_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fact_product_sales_date_key_fkey"
            columns: ["date_key"]
            isOneToOne: false
            referencedRelation: "dim_date"
            referencedColumns: ["date_key"]
          },
          {
            foreignKeyName: "fact_product_sales_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "ecommerce_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fact_product_sales_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fact_product_sales_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      fact_staff_sales: {
        Row: {
          average_transaction_time: unknown
          average_transaction_value: number | null
          branch_id: string
          commission_amount: number | null
          commission_eligible_sales: number | null
          created_at: string | null
          date_key: number
          id: string | null
          sale_date: string
          staff_id: string
          staff_name: string
          staff_role: string
          tenant_id: string
          total_items_sold: number | null
          total_profit: number | null
          total_revenue: number | null
          total_transactions: number | null
          transactions_per_hour: number | null
          updated_at: string | null
        }
        Insert: {
          average_transaction_time?: unknown
          average_transaction_value?: number | null
          branch_id: string
          commission_amount?: number | null
          commission_eligible_sales?: number | null
          created_at?: string | null
          date_key: number
          id?: string | null
          sale_date: string
          staff_id: string
          staff_name: string
          staff_role: string
          tenant_id: string
          total_items_sold?: number | null
          total_profit?: number | null
          total_revenue?: number | null
          total_transactions?: number | null
          transactions_per_hour?: number | null
          updated_at?: string | null
        }
        Update: {
          average_transaction_time?: unknown
          average_transaction_value?: number | null
          branch_id?: string
          commission_amount?: number | null
          commission_eligible_sales?: number | null
          created_at?: string | null
          date_key?: number
          id?: string | null
          sale_date?: string
          staff_id?: string
          staff_name?: string
          staff_role?: string
          tenant_id?: string
          total_items_sold?: number | null
          total_profit?: number | null
          total_revenue?: number | null
          total_transactions?: number | null
          transactions_per_hour?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fact_staff_sales_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fact_staff_sales_date_key_fkey"
            columns: ["date_key"]
            isOneToOne: false
            referencedRelation: "dim_date"
            referencedColumns: ["date_key"]
          },
          {
            foreignKeyName: "fact_staff_sales_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fact_staff_sales_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      favorite_providers: {
        Row: {
          created_at: string | null
          id: string
          notes: string | null
          patient_id: string
          provider_id: string
          tags: string[] | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          notes?: string | null
          patient_id: string
          provider_id: string
          tags?: string[] | null
        }
        Update: {
          created_at?: string | null
          id?: string
          notes?: string | null
          patient_id?: string
          provider_id?: string
          tags?: string[] | null
        }
        Relationships: [
          {
            foreignKeyName: "favorite_providers_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: false
            referencedRelation: "healthcare_providers"
            referencedColumns: ["id"]
          },
        ]
      }
      global_product_catalog: {
        Row: {
          barcode: string | null
          brand: string | null
          business_type: string
          category: string
          created_at: string
          created_by: string | null
          description: string | null
          id: string
          images: string[] | null
          is_active: boolean | null
          is_verified: boolean | null
          meta_description: string | null
          meta_title: string | null
          name: string
          primary_image: string | null
          sku_prefix: string | null
          slug: string
          specifications: Json | null
          updated_at: string
        }
        Insert: {
          barcode?: string | null
          brand?: string | null
          business_type: string
          category: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          images?: string[] | null
          is_active?: boolean | null
          is_verified?: boolean | null
          meta_description?: string | null
          meta_title?: string | null
          name: string
          primary_image?: string | null
          sku_prefix?: string | null
          slug: string
          specifications?: Json | null
          updated_at?: string
        }
        Update: {
          barcode?: string | null
          brand?: string | null
          business_type?: string
          category?: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          images?: string[] | null
          is_active?: boolean | null
          is_verified?: boolean | null
          meta_description?: string | null
          meta_title?: string | null
          name?: string
          primary_image?: string | null
          sku_prefix?: string | null
          slug?: string
          specifications?: Json | null
          updated_at?: string
        }
        Relationships: []
      }
      healthcare_providers: {
        Row: {
          average_rating: number | null
          bio: string | null
          clinic_address: Json | null
          clinic_settings: Json | null
          consultation_types: string[] | null
          country: string
          created_at: string | null
          credentials: string | null
          custom_domain: string | null
          email: string | null
          fees: Json
          full_name: string
          id: string
          is_active: boolean | null
          is_verified: boolean | null
          license_number: string | null
          phone: string | null
          plan_tier: string | null
          profile_photo_url: string | null
          region: string | null
          slug: string
          specialization: string
          total_consultations: number | null
          total_reviews: number | null
          type: string
          updated_at: string | null
          user_id: string | null
          verified_at: string | null
          years_of_experience: number | null
        }
        Insert: {
          average_rating?: number | null
          bio?: string | null
          clinic_address?: Json | null
          clinic_settings?: Json | null
          consultation_types?: string[] | null
          country: string
          created_at?: string | null
          credentials?: string | null
          custom_domain?: string | null
          email?: string | null
          fees?: Json
          full_name: string
          id?: string
          is_active?: boolean | null
          is_verified?: boolean | null
          license_number?: string | null
          phone?: string | null
          plan_tier?: string | null
          profile_photo_url?: string | null
          region?: string | null
          slug: string
          specialization: string
          total_consultations?: number | null
          total_reviews?: number | null
          type: string
          updated_at?: string | null
          user_id?: string | null
          verified_at?: string | null
          years_of_experience?: number | null
        }
        Update: {
          average_rating?: number | null
          bio?: string | null
          clinic_address?: Json | null
          clinic_settings?: Json | null
          consultation_types?: string[] | null
          country?: string
          created_at?: string | null
          credentials?: string | null
          custom_domain?: string | null
          email?: string | null
          fees?: Json
          full_name?: string
          id?: string
          is_active?: boolean | null
          is_verified?: boolean | null
          license_number?: string | null
          phone?: string | null
          plan_tier?: string | null
          profile_photo_url?: string | null
          region?: string | null
          slug?: string
          specialization?: string
          total_consultations?: number | null
          total_reviews?: number | null
          type?: string
          updated_at?: string | null
          user_id?: string | null
          verified_at?: string | null
          years_of_experience?: number | null
        }
        Relationships: []
      }
      inter_branch_transfers: {
        Row: {
          authorized_by_id: string
          created_at: string
          destination_branch_id: string
          id: string
          notes: string | null
          received_by_id: string | null
          source_branch_id: string
          status: Database["public"]["Enums"]["transfer_status"] | null
          tenant_id: string
          transfer_date: string
          updated_at: string
        }
        Insert: {
          authorized_by_id: string
          created_at?: string
          destination_branch_id: string
          id?: string
          notes?: string | null
          received_by_id?: string | null
          source_branch_id: string
          status?: Database["public"]["Enums"]["transfer_status"] | null
          tenant_id: string
          transfer_date?: string
          updated_at?: string
        }
        Update: {
          authorized_by_id?: string
          created_at?: string
          destination_branch_id?: string
          id?: string
          notes?: string | null
          received_by_id?: string | null
          source_branch_id?: string
          status?: Database["public"]["Enums"]["transfer_status"] | null
          tenant_id?: string
          transfer_date?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "inter_branch_transfers_authorized_by_id_fkey"
            columns: ["authorized_by_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inter_branch_transfers_destination_branch_id_fkey"
            columns: ["destination_branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inter_branch_transfers_received_by_id_fkey"
            columns: ["received_by_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inter_branch_transfers_source_branch_id_fkey"
            columns: ["source_branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inter_branch_transfers_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      inventory_transactions: {
        Row: {
          branch_id: string
          created_at: string
          id: string
          new_quantity: number
          notes: string | null
          previous_quantity: number
          product_id: string
          quantity_delta: number
          reference_id: string | null
          reference_type: string | null
          staff_id: string
          tenant_id: string
          transaction_type: Database["public"]["Enums"]["transaction_type"]
          unit_cost: number | null
        }
        Insert: {
          branch_id: string
          created_at?: string
          id?: string
          new_quantity: number
          notes?: string | null
          previous_quantity: number
          product_id: string
          quantity_delta: number
          reference_id?: string | null
          reference_type?: string | null
          staff_id: string
          tenant_id: string
          transaction_type: Database["public"]["Enums"]["transaction_type"]
          unit_cost?: number | null
        }
        Update: {
          branch_id?: string
          created_at?: string
          id?: string
          new_quantity?: number
          notes?: string | null
          previous_quantity?: number
          product_id?: string
          quantity_delta?: number
          reference_id?: string | null
          reference_type?: string | null
          staff_id?: string
          tenant_id?: string
          transaction_type?: Database["public"]["Enums"]["transaction_type"]
          unit_cost?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "inventory_transactions_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inventory_transactions_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "ecommerce_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inventory_transactions_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inventory_transactions_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "inventory_transactions_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      invoices: {
        Row: {
          adjustments: number | null
          billing_period_end: string
          billing_period_start: string
          commission_total: number | null
          created_at: string | null
          due_date: string
          id: string
          invoice_date: string
          invoice_number: string
          invoice_url: string | null
          paid_at: string | null
          payment_reference: string | null
          payment_status: string | null
          subscription_fee: number | null
          subtotal: number
          tax_amount: number | null
          tenant_id: string
          total_amount: number
          updated_at: string | null
        }
        Insert: {
          adjustments?: number | null
          billing_period_end: string
          billing_period_start: string
          commission_total?: number | null
          created_at?: string | null
          due_date: string
          id?: string
          invoice_date: string
          invoice_number: string
          invoice_url?: string | null
          paid_at?: string | null
          payment_reference?: string | null
          payment_status?: string | null
          subscription_fee?: number | null
          subtotal: number
          tax_amount?: number | null
          tenant_id: string
          total_amount: number
          updated_at?: string | null
        }
        Update: {
          adjustments?: number | null
          billing_period_end?: string
          billing_period_start?: string
          commission_total?: number | null
          created_at?: string | null
          due_date?: string
          id?: string
          invoice_date?: string
          invoice_number?: string
          invoice_url?: string | null
          paid_at?: string | null
          payment_reference?: string | null
          payment_status?: string | null
          subscription_fee?: number | null
          subtotal?: number
          tax_amount?: number | null
          tenant_id?: string
          total_amount?: number
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "invoices_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      order_items: {
        Row: {
          id: string
          order_id: string
          product_id: string
          product_name: string
          quantity: number
          subtotal: number
          unit_price: number
        }
        Insert: {
          id?: string
          order_id: string
          product_id: string
          product_name: string
          quantity: number
          subtotal: number
          unit_price: number
        }
        Update: {
          id?: string
          order_id?: string
          product_id?: string
          product_name?: string
          quantity?: number
          subtotal?: number
          unit_price?: number
        }
        Relationships: [
          {
            foreignKeyName: "order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "ecommerce_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      orders: {
        Row: {
          _sync_client_id: string | null
          _sync_modified_at: string | null
          _sync_version: number | null
          branch_id: string
          created_at: string
          customer_id: string
          delivery_address_id: string | null
          delivery_fee: number | null
          ecommerce_order_id: string | null
          ecommerce_platform: string | null
          fulfillment_type: Database["public"]["Enums"]["fulfillment_type"]
          id: string
          order_number: string
          order_status: Database["public"]["Enums"]["order_status"] | null
          order_type: Database["public"]["Enums"]["order_type"]
          payment_method: Database["public"]["Enums"]["payment_method"] | null
          payment_reference: string | null
          payment_status: Database["public"]["Enums"]["payment_status"] | null
          special_instructions: string | null
          subtotal: number
          tax_amount: number | null
          tenant_id: string
          total_amount: number
          updated_at: string
        }
        Insert: {
          _sync_client_id?: string | null
          _sync_modified_at?: string | null
          _sync_version?: number | null
          branch_id: string
          created_at?: string
          customer_id: string
          delivery_address_id?: string | null
          delivery_fee?: number | null
          ecommerce_order_id?: string | null
          ecommerce_platform?: string | null
          fulfillment_type: Database["public"]["Enums"]["fulfillment_type"]
          id?: string
          order_number: string
          order_status?: Database["public"]["Enums"]["order_status"] | null
          order_type: Database["public"]["Enums"]["order_type"]
          payment_method?: Database["public"]["Enums"]["payment_method"] | null
          payment_reference?: string | null
          payment_status?: Database["public"]["Enums"]["payment_status"] | null
          special_instructions?: string | null
          subtotal: number
          tax_amount?: number | null
          tenant_id: string
          total_amount: number
          updated_at?: string
        }
        Update: {
          _sync_client_id?: string | null
          _sync_modified_at?: string | null
          _sync_version?: number | null
          branch_id?: string
          created_at?: string
          customer_id?: string
          delivery_address_id?: string | null
          delivery_fee?: number | null
          ecommerce_order_id?: string | null
          ecommerce_platform?: string | null
          fulfillment_type?: Database["public"]["Enums"]["fulfillment_type"]
          id?: string
          order_number?: string
          order_status?: Database["public"]["Enums"]["order_status"] | null
          order_type?: Database["public"]["Enums"]["order_type"]
          payment_method?: Database["public"]["Enums"]["payment_method"] | null
          payment_reference?: string | null
          payment_status?: Database["public"]["Enums"]["payment_status"] | null
          special_instructions?: string | null
          subtotal?: number
          tax_amount?: number | null
          tenant_id?: string
          total_amount?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "orders_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "customers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_delivery_address_id_fkey"
            columns: ["delivery_address_id"]
            isOneToOne: false
            referencedRelation: "customer_addresses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      passkey_challenges: {
        Row: {
          challenge: string
          created_at: string
          expires_at: string
          id: string
          type: string
          user_id: string
        }
        Insert: {
          challenge: string
          created_at?: string
          expires_at: string
          id?: string
          type: string
          user_id: string
        }
        Update: {
          challenge?: string
          created_at?: string
          expires_at?: string
          id?: string
          type?: string
          user_id?: string
        }
        Relationships: []
      }
      payment_transactions: {
        Row: {
          amount: number
          created_at: string
          currency: string
          gateway_response: string | null
          id: string
          order_id: string
          payment_channel: string | null
          payment_method: string | null
          paystack_access_code: string | null
          paystack_reference: string
          paystack_transaction_id: string | null
          status: string
          updated_at: string
          verified_at: string | null
          webhook_payload: Json | null
          webhook_received_at: string | null
          webhook_signature: string | null
        }
        Insert: {
          amount: number
          created_at?: string
          currency?: string
          gateway_response?: string | null
          id?: string
          order_id: string
          payment_channel?: string | null
          payment_method?: string | null
          paystack_access_code?: string | null
          paystack_reference: string
          paystack_transaction_id?: string | null
          status: string
          updated_at?: string
          verified_at?: string | null
          webhook_payload?: Json | null
          webhook_received_at?: string | null
          webhook_signature?: string | null
        }
        Update: {
          amount?: number
          created_at?: string
          currency?: string
          gateway_response?: string | null
          id?: string
          order_id?: string
          payment_channel?: string | null
          payment_method?: string | null
          paystack_access_code?: string | null
          paystack_reference?: string
          paystack_transaction_id?: string | null
          status?: string
          updated_at?: string
          verified_at?: string | null
          webhook_payload?: Json | null
          webhook_received_at?: string | null
          webhook_signature?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "payment_transactions_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "storefront_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      prescriptions: {
        Row: {
          consultation_id: string
          created_at: string | null
          diagnosis: string | null
          dispensed_at: string | null
          expiration_date: string | null
          id: string
          issue_date: string | null
          medications: Json
          notes: string | null
          patient_id: string
          primary_pharmacy_id: string | null
          provider_credentials: string | null
          provider_id: string
          provider_name: string
          routing_details: Json | null
          routing_strategy: string | null
          status: string | null
          updated_at: string | null
        }
        Insert: {
          consultation_id: string
          created_at?: string | null
          diagnosis?: string | null
          dispensed_at?: string | null
          expiration_date?: string | null
          id?: string
          issue_date?: string | null
          medications: Json
          notes?: string | null
          patient_id: string
          primary_pharmacy_id?: string | null
          provider_credentials?: string | null
          provider_id: string
          provider_name: string
          routing_details?: Json | null
          routing_strategy?: string | null
          status?: string | null
          updated_at?: string | null
        }
        Update: {
          consultation_id?: string
          created_at?: string | null
          diagnosis?: string | null
          dispensed_at?: string | null
          expiration_date?: string | null
          id?: string
          issue_date?: string | null
          medications?: Json
          notes?: string | null
          patient_id?: string
          primary_pharmacy_id?: string | null
          provider_credentials?: string | null
          provider_id?: string
          provider_name?: string
          routing_details?: Json | null
          routing_strategy?: string | null
          status?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "prescriptions_consultation_id_fkey"
            columns: ["consultation_id"]
            isOneToOne: false
            referencedRelation: "consultations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "prescriptions_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: false
            referencedRelation: "healthcare_providers"
            referencedColumns: ["id"]
          },
        ]
      }
      product_price_history: {
        Row: {
          changed_by: string | null
          cost_price: number | null
          created_at: string | null
          id: string
          is_current: boolean | null
          price_change_reason: string | null
          product_id: string
          selling_price: number
          tenant_id: string
          valid_from: string
          valid_to: string | null
        }
        Insert: {
          changed_by?: string | null
          cost_price?: number | null
          created_at?: string | null
          id?: string
          is_current?: boolean | null
          price_change_reason?: string | null
          product_id: string
          selling_price: number
          tenant_id: string
          valid_from?: string
          valid_to?: string | null
        }
        Update: {
          changed_by?: string | null
          cost_price?: number | null
          created_at?: string | null
          id?: string
          is_current?: boolean | null
          price_change_reason?: string | null
          product_id?: string
          selling_price?: number
          tenant_id?: string
          valid_from?: string
          valid_to?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "product_price_history_changed_by_fkey"
            columns: ["changed_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_price_history_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "ecommerce_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_price_history_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_price_history_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      product_variants: {
        Row: {
          barcode: string | null
          cost_price: number | null
          created_at: string | null
          current_stock: number | null
          id: string
          image_url: string | null
          is_available: boolean
          options: Json | null
          price_adjustment: number | null
          product_id: string
          selling_price: number | null
          sku: string | null
          status: string | null
          stock_quantity: number
          tenant_id: string
          updated_at: string | null
          variant_attributes: Json
          variant_name: string
        }
        Insert: {
          barcode?: string | null
          cost_price?: number | null
          created_at?: string | null
          current_stock?: number | null
          id?: string
          image_url?: string | null
          is_available?: boolean
          options?: Json | null
          price_adjustment?: number | null
          product_id: string
          selling_price?: number | null
          sku?: string | null
          status?: string | null
          stock_quantity?: number
          tenant_id: string
          updated_at?: string | null
          variant_attributes?: Json
          variant_name: string
        }
        Update: {
          barcode?: string | null
          cost_price?: number | null
          created_at?: string | null
          current_stock?: number | null
          id?: string
          image_url?: string | null
          is_available?: boolean
          options?: Json | null
          price_adjustment?: number | null
          product_id?: string
          selling_price?: number | null
          sku?: string | null
          status?: string | null
          stock_quantity?: number
          tenant_id?: string
          updated_at?: string | null
          variant_attributes?: Json
          variant_name?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_variants_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "ecommerce_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_variants_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_variants_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      products: {
        Row: {
          _sync_client_id: string | null
          _sync_is_deleted: boolean | null
          _sync_modified_at: string | null
          _sync_version: number | null
          barcode: string | null
          branch_id: string
          brand_id: string | null
          category: string | null
          category_id: string | null
          cost_price: number | null
          created_at: string
          deleted_at: string | null
          description: string | null
          expiry_alert_days: number | null
          expiry_date: string | null
          id: string
          image_url: string | null
          is_active: boolean | null
          low_stock_threshold: number | null
          name: string
          sku: string | null
          stock_quantity: number
          tenant_id: string
          unit_of_measure: string | null
          unit_price: number
          updated_at: string
        }
        Insert: {
          _sync_client_id?: string | null
          _sync_is_deleted?: boolean | null
          _sync_modified_at?: string | null
          _sync_version?: number | null
          barcode?: string | null
          branch_id: string
          brand_id?: string | null
          category?: string | null
          category_id?: string | null
          cost_price?: number | null
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          expiry_alert_days?: number | null
          expiry_date?: string | null
          id?: string
          image_url?: string | null
          is_active?: boolean | null
          low_stock_threshold?: number | null
          name: string
          sku?: string | null
          stock_quantity?: number
          tenant_id: string
          unit_of_measure?: string | null
          unit_price: number
          updated_at?: string
        }
        Update: {
          _sync_client_id?: string | null
          _sync_is_deleted?: boolean | null
          _sync_modified_at?: string | null
          _sync_version?: number | null
          barcode?: string | null
          branch_id?: string
          brand_id?: string | null
          category?: string | null
          category_id?: string | null
          cost_price?: number | null
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          expiry_alert_days?: number | null
          expiry_date?: string | null
          id?: string
          image_url?: string | null
          is_active?: boolean | null
          low_stock_threshold?: number | null
          name?: string
          sku?: string | null
          stock_quantity?: number
          tenant_id?: string
          unit_of_measure?: string | null
          unit_price?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "products_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "products_brand_id_fkey"
            columns: ["brand_id"]
            isOneToOne: false
            referencedRelation: "brands"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "products_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "products_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      provider_availability_templates: {
        Row: {
          buffer_minutes: number | null
          consultation_types: string[] | null
          created_at: string | null
          day_of_week: number
          end_time: string
          id: string
          is_active: boolean | null
          provider_id: string
          slot_duration: number
          start_time: string
          updated_at: string | null
        }
        Insert: {
          buffer_minutes?: number | null
          consultation_types?: string[] | null
          created_at?: string | null
          day_of_week: number
          end_time: string
          id?: string
          is_active?: boolean | null
          provider_id: string
          slot_duration: number
          start_time: string
          updated_at?: string | null
        }
        Update: {
          buffer_minutes?: number | null
          consultation_types?: string[] | null
          created_at?: string | null
          day_of_week?: number
          end_time?: string
          id?: string
          is_active?: boolean | null
          provider_id?: string
          slot_duration?: number
          start_time?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "provider_availability_templates_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: false
            referencedRelation: "healthcare_providers"
            referencedColumns: ["id"]
          },
        ]
      }
      provider_time_slots: {
        Row: {
          consultation_type: string
          created_at: string | null
          date: string
          end_time: string
          held_by_user: string | null
          held_until: string | null
          id: string
          provider_id: string
          slot_duration: number
          start_time: string
          status: string | null
          template_id: string | null
          updated_at: string | null
          version: number
        }
        Insert: {
          consultation_type: string
          created_at?: string | null
          date: string
          end_time: string
          held_by_user?: string | null
          held_until?: string | null
          id?: string
          provider_id: string
          slot_duration: number
          start_time: string
          status?: string | null
          template_id?: string | null
          updated_at?: string | null
          version?: number
        }
        Update: {
          consultation_type?: string
          created_at?: string | null
          date?: string
          end_time?: string
          held_by_user?: string | null
          held_until?: string | null
          id?: string
          provider_id?: string
          slot_duration?: number
          start_time?: string
          status?: string | null
          template_id?: string | null
          updated_at?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "provider_time_slots_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: false
            referencedRelation: "healthcare_providers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "provider_time_slots_template_id_fkey"
            columns: ["template_id"]
            isOneToOne: false
            referencedRelation: "provider_availability_templates"
            referencedColumns: ["id"]
          },
        ]
      }
      receipts: {
        Row: {
          content: string | null
          created_at: string
          email_sent_at: string | null
          email_sent_to: string | null
          file_url: string | null
          format: Database["public"]["Enums"]["receipt_format"] | null
          id: string
          receipt_number: string
          sale_id: string
          tenant_id: string | null
        }
        Insert: {
          content?: string | null
          created_at?: string
          email_sent_at?: string | null
          email_sent_to?: string | null
          file_url?: string | null
          format?: Database["public"]["Enums"]["receipt_format"] | null
          id?: string
          receipt_number: string
          sale_id: string
          tenant_id?: string | null
        }
        Update: {
          content?: string | null
          created_at?: string
          email_sent_at?: string | null
          email_sent_to?: string | null
          file_url?: string | null
          format?: Database["public"]["Enums"]["receipt_format"] | null
          id?: string
          receipt_number?: string
          sale_id?: string
          tenant_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "receipts_sale_id_fkey"
            columns: ["sale_id"]
            isOneToOne: true
            referencedRelation: "sales"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "receipts_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      riders: {
        Row: {
          average_delivery_time_minutes: number | null
          created_at: string
          deleted_at: string | null
          id: string
          is_available: boolean | null
          license_number: string | null
          phone: string
          rating: number | null
          successful_deliveries: number | null
          tenant_id: string
          total_deliveries: number | null
          updated_at: string
          user_id: string
          vehicle_type: Database["public"]["Enums"]["vehicle_type"]
        }
        Insert: {
          average_delivery_time_minutes?: number | null
          created_at?: string
          deleted_at?: string | null
          id?: string
          is_available?: boolean | null
          license_number?: string | null
          phone: string
          rating?: number | null
          successful_deliveries?: number | null
          tenant_id: string
          total_deliveries?: number | null
          updated_at?: string
          user_id: string
          vehicle_type: Database["public"]["Enums"]["vehicle_type"]
        }
        Update: {
          average_delivery_time_minutes?: number | null
          created_at?: string
          deleted_at?: string | null
          id?: string
          is_available?: boolean | null
          license_number?: string | null
          phone?: string
          rating?: number | null
          successful_deliveries?: number | null
          tenant_id?: string
          total_deliveries?: number | null
          updated_at?: string
          user_id?: string
          vehicle_type?: Database["public"]["Enums"]["vehicle_type"]
        }
        Relationships: [
          {
            foreignKeyName: "riders_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "riders_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      sale_items: {
        Row: {
          brand_id: string | null
          brand_name: string | null
          category_id: string | null
          category_name: string | null
          created_at: string
          discount_amount: number | null
          discount_code: string | null
          discount_percent: number | null
          discount_percentage: number | null
          discount_type: string | null
          gross_profit: number | null
          id: string
          original_price: number | null
          product_id: string
          product_name: string
          product_sku: string | null
          profit_margin: number | null
          quantity: number
          sale_id: string
          subtotal: number
          tax_amount: number | null
          tax_percentage: number | null
          tenant_id: string
          total_cost: number | null
          unit_cost: number | null
          unit_of_measure: string | null
          unit_price: number
        }
        Insert: {
          brand_id?: string | null
          brand_name?: string | null
          category_id?: string | null
          category_name?: string | null
          created_at?: string
          discount_amount?: number | null
          discount_code?: string | null
          discount_percent?: number | null
          discount_percentage?: number | null
          discount_type?: string | null
          gross_profit?: number | null
          id?: string
          original_price?: number | null
          product_id: string
          product_name: string
          product_sku?: string | null
          profit_margin?: number | null
          quantity: number
          sale_id: string
          subtotal: number
          tax_amount?: number | null
          tax_percentage?: number | null
          tenant_id: string
          total_cost?: number | null
          unit_cost?: number | null
          unit_of_measure?: string | null
          unit_price: number
        }
        Update: {
          brand_id?: string | null
          brand_name?: string | null
          category_id?: string | null
          category_name?: string | null
          created_at?: string
          discount_amount?: number | null
          discount_code?: string | null
          discount_percent?: number | null
          discount_percentage?: number | null
          discount_type?: string | null
          gross_profit?: number | null
          id?: string
          original_price?: number | null
          product_id?: string
          product_name?: string
          product_sku?: string | null
          profit_margin?: number | null
          quantity?: number
          sale_id?: string
          subtotal?: number
          tax_amount?: number | null
          tax_percentage?: number | null
          tenant_id?: string
          total_cost?: number | null
          unit_cost?: number | null
          unit_of_measure?: string | null
          unit_price?: number
        }
        Relationships: [
          {
            foreignKeyName: "sale_items_brand_id_fkey"
            columns: ["brand_id"]
            isOneToOne: false
            referencedRelation: "brands"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sale_items_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sale_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "ecommerce_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sale_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sale_items_sale_id_fkey"
            columns: ["sale_id"]
            isOneToOne: false
            referencedRelation: "sales"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sale_items_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      sales: {
        Row: {
          _sync_client_id: string | null
          _sync_is_deleted: boolean | null
          _sync_modified_at: string | null
          _sync_version: number | null
          branch_id: string
          cashier_id: string
          channel: string | null
          completed_at: string
          created_at: string
          customer_id: string | null
          customer_type: string | null
          discount_amount: number
          id: string
          is_synced: boolean | null
          payment_method: Database["public"]["Enums"]["payment_method"]
          payment_reference: string | null
          sale_date: string
          sale_number: string
          sale_status: Database["public"]["Enums"]["sale_status"] | null
          sale_time: string
          sale_type: string | null
          sales_attendant_id: string | null
          subtotal: number
          tax_amount: number
          tenant_id: string
          total_amount: number
          updated_at: string
          void_reason: string | null
          voided_at: string | null
          voided_by: string | null
          voided_by_id: string | null
        }
        Insert: {
          _sync_client_id?: string | null
          _sync_is_deleted?: boolean | null
          _sync_modified_at?: string | null
          _sync_version?: number | null
          branch_id: string
          cashier_id: string
          channel?: string | null
          completed_at?: string
          created_at?: string
          customer_id?: string | null
          customer_type?: string | null
          discount_amount?: number
          id?: string
          is_synced?: boolean | null
          payment_method: Database["public"]["Enums"]["payment_method"]
          payment_reference?: string | null
          sale_date: string
          sale_number: string
          sale_status?: Database["public"]["Enums"]["sale_status"] | null
          sale_time: string
          sale_type?: string | null
          sales_attendant_id?: string | null
          subtotal: number
          tax_amount?: number
          tenant_id: string
          total_amount: number
          updated_at?: string
          void_reason?: string | null
          voided_at?: string | null
          voided_by?: string | null
          voided_by_id?: string | null
        }
        Update: {
          _sync_client_id?: string | null
          _sync_is_deleted?: boolean | null
          _sync_modified_at?: string | null
          _sync_version?: number | null
          branch_id?: string
          cashier_id?: string
          channel?: string | null
          completed_at?: string
          created_at?: string
          customer_id?: string | null
          customer_type?: string | null
          discount_amount?: number
          id?: string
          is_synced?: boolean | null
          payment_method?: Database["public"]["Enums"]["payment_method"]
          payment_reference?: string | null
          sale_date?: string
          sale_number?: string
          sale_status?: Database["public"]["Enums"]["sale_status"] | null
          sale_time?: string
          sale_type?: string | null
          sales_attendant_id?: string | null
          subtotal?: number
          tax_amount?: number
          tenant_id?: string
          total_amount?: number
          updated_at?: string
          void_reason?: string | null
          voided_at?: string | null
          voided_by?: string | null
          voided_by_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "sales_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sales_cashier_id_fkey"
            columns: ["cashier_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sales_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "customers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sales_sales_attendant_id_fkey"
            columns: ["sales_attendant_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sales_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sales_voided_by_fkey"
            columns: ["voided_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sales_voided_by_id_fkey"
            columns: ["voided_by_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      session_activity: {
        Row: {
          created_at: string
          id: string
          ip_address: unknown
          last_activity_at: string
          revalidated_at: string
          updated_at: string
          user_agent: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          ip_address?: unknown
          last_activity_at?: string
          revalidated_at?: string
          updated_at?: string
          user_agent?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          ip_address?: unknown
          last_activity_at?: string
          revalidated_at?: string
          updated_at?: string
          user_agent?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "session_activity_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      shopping_carts: {
        Row: {
          branch_id: string
          created_at: string
          customer_id: string | null
          expires_at: string
          id: string
          session_id: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          branch_id: string
          created_at?: string
          customer_id?: string | null
          expires_at?: string
          id?: string
          session_id: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          branch_id?: string
          created_at?: string
          customer_id?: string | null
          expires_at?: string
          id?: string
          session_id?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "shopping_carts_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "shopping_carts_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "storefront_customers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "shopping_carts_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      spatial_ref_sys: {
        Row: {
          auth_name: string | null
          auth_srid: number | null
          proj4text: string | null
          srid: number
          srtext: string | null
        }
        Insert: {
          auth_name?: string | null
          auth_srid?: number | null
          proj4text?: string | null
          srid: number
          srtext?: string | null
        }
        Update: {
          auth_name?: string | null
          auth_srid?: number | null
          proj4text?: string | null
          srid?: number
          srtext?: string | null
        }
        Relationships: []
      }
      staff_attendance: {
        Row: {
          branch_id: string
          clock_in_at: string
          clock_out_at: string | null
          created_at: string
          id: string
          notes: string | null
          shift_date: string
          staff_id: string
          tenant_id: string
          total_hours: number | null
          updated_at: string
        }
        Insert: {
          branch_id: string
          clock_in_at: string
          clock_out_at?: string | null
          created_at?: string
          id?: string
          notes?: string | null
          shift_date: string
          staff_id: string
          tenant_id: string
          total_hours?: number | null
          updated_at?: string
        }
        Update: {
          branch_id?: string
          clock_in_at?: string
          clock_out_at?: string | null
          created_at?: string
          id?: string
          notes?: string | null
          shift_date?: string
          staff_id?: string
          tenant_id?: string
          total_hours?: number | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "staff_attendance_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_attendance_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_attendance_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      staff_invitations: {
        Row: {
          accepted_at: string | null
          branch_id: string | null
          created_at: string
          email: string
          expires_at: string
          full_name: string
          id: string
          invitation_token: string
          invited_by: string
          role: Database["public"]["Enums"]["user_role"]
          status: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          accepted_at?: string | null
          branch_id?: string | null
          created_at?: string
          email: string
          expires_at?: string
          full_name: string
          id?: string
          invitation_token: string
          invited_by: string
          role: Database["public"]["Enums"]["user_role"]
          status?: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          accepted_at?: string | null
          branch_id?: string | null
          created_at?: string
          email?: string
          expires_at?: string
          full_name?: string
          id?: string
          invitation_token?: string
          invited_by?: string
          role?: Database["public"]["Enums"]["user_role"]
          status?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "staff_invitations_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_invitations_invited_by_fkey"
            columns: ["invited_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_invitations_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      storefront_customers: {
        Row: {
          created_at: string
          delivery_address: Json | null
          delivery_coordinates: unknown
          email: string | null
          id: string
          last_order_at: string | null
          name: string
          phone: string
          total_orders: number | null
          updated_at: string
          user_id: string | null
        }
        Insert: {
          created_at?: string
          delivery_address?: Json | null
          delivery_coordinates?: unknown
          email?: string | null
          id?: string
          last_order_at?: string | null
          name: string
          phone: string
          total_orders?: number | null
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          created_at?: string
          delivery_address?: Json | null
          delivery_coordinates?: unknown
          email?: string | null
          id?: string
          last_order_at?: string | null
          name?: string
          phone?: string
          total_orders?: number | null
          updated_at?: string
          user_id?: string | null
        }
        Relationships: []
      }
      storefront_order_items: {
        Row: {
          created_at: string
          id: string
          line_total: number
          order_id: string
          product_id: string
          product_name: string
          product_sku: string
          quantity: number
          unit_price: number
          variant_id: string | null
          variant_name: string | null
        }
        Insert: {
          created_at?: string
          id?: string
          line_total: number
          order_id: string
          product_id: string
          product_name: string
          product_sku: string
          quantity: number
          unit_price: number
          variant_id?: string | null
          variant_name?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          line_total?: number
          order_id?: string
          product_id?: string
          product_name?: string
          product_sku?: string
          quantity?: number
          unit_price?: number
          variant_id?: string | null
          variant_name?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "storefront_order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "storefront_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "storefront_order_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "storefront_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "storefront_order_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "storefront_products_with_catalog"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "storefront_order_items_variant_id_fkey"
            columns: ["variant_id"]
            isOneToOne: false
            referencedRelation: "product_variants"
            referencedColumns: ["id"]
          },
        ]
      }
      storefront_orders: {
        Row: {
          branch_id: string
          completed_at: string | null
          confirmed_at: string | null
          created_at: string
          customer_id: string
          delivery_address: Json | null
          delivery_base_fee: number
          delivery_coordinates: unknown
          delivery_fee_addition: number
          delivery_instructions: string | null
          delivery_method: string
          delivery_name: string
          delivery_phone: string
          id: string
          order_number: string
          order_status: string
          paid_at: string | null
          payment_method: string | null
          payment_status: string
          paystack_reference: string | null
          platform_commission: number
          subtotal: number
          tenant_id: string
          total_amount: number
          transaction_fee: number
          updated_at: string
        }
        Insert: {
          branch_id: string
          completed_at?: string | null
          confirmed_at?: string | null
          created_at?: string
          customer_id: string
          delivery_address?: Json | null
          delivery_base_fee?: number
          delivery_coordinates?: unknown
          delivery_fee_addition?: number
          delivery_instructions?: string | null
          delivery_method: string
          delivery_name: string
          delivery_phone: string
          id?: string
          order_number: string
          order_status?: string
          paid_at?: string | null
          payment_method?: string | null
          payment_status?: string
          paystack_reference?: string | null
          platform_commission?: number
          subtotal: number
          tenant_id: string
          total_amount: number
          transaction_fee?: number
          updated_at?: string
        }
        Update: {
          branch_id?: string
          completed_at?: string | null
          confirmed_at?: string | null
          created_at?: string
          customer_id?: string
          delivery_address?: Json | null
          delivery_base_fee?: number
          delivery_coordinates?: unknown
          delivery_fee_addition?: number
          delivery_instructions?: string | null
          delivery_method?: string
          delivery_name?: string
          delivery_phone?: string
          id?: string
          order_number?: string
          order_status?: string
          paid_at?: string | null
          payment_method?: string | null
          payment_status?: string
          paystack_reference?: string | null
          platform_commission?: number
          subtotal?: number
          tenant_id?: string
          total_amount?: number
          transaction_fee?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "storefront_orders_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "storefront_orders_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "storefront_customers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "storefront_orders_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      storefront_products: {
        Row: {
          branch_id: string
          catalog_product_id: string | null
          compare_at_price: number | null
          cost_price: number | null
          created_at: string
          custom_description: string | null
          custom_images: string[] | null
          custom_name: string | null
          has_variants: boolean | null
          id: string
          is_available: boolean
          low_stock_threshold: number | null
          price: number
          product_id: string | null
          sku: string
          stock_quantity: number
          synced_at: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          branch_id: string
          catalog_product_id?: string | null
          compare_at_price?: number | null
          cost_price?: number | null
          created_at?: string
          custom_description?: string | null
          custom_images?: string[] | null
          custom_name?: string | null
          has_variants?: boolean | null
          id?: string
          is_available?: boolean
          low_stock_threshold?: number | null
          price: number
          product_id?: string | null
          sku: string
          stock_quantity?: number
          synced_at?: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          branch_id?: string
          catalog_product_id?: string | null
          compare_at_price?: number | null
          cost_price?: number | null
          created_at?: string
          custom_description?: string | null
          custom_images?: string[] | null
          custom_name?: string | null
          has_variants?: boolean | null
          id?: string
          is_available?: boolean
          low_stock_threshold?: number | null
          price?: number
          product_id?: string | null
          sku?: string
          stock_quantity?: number
          synced_at?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "storefront_products_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "storefront_products_catalog_product_id_fkey"
            columns: ["catalog_product_id"]
            isOneToOne: false
            referencedRelation: "global_product_catalog"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "storefront_products_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      subscriptions: {
        Row: {
          billing_cycle_end: string
          billing_cycle_start: string
          commission_cap_amount: number | null
          commission_rate: number
          created_at: string
          features: Json | null
          id: string
          max_branches: number
          max_products: number
          max_staff_users: number
          monthly_fee: number
          monthly_transaction_quota: number
          plan_tier: string
          status: string | null
          tenant_id: string | null
          updated_at: string
        }
        Insert: {
          billing_cycle_end: string
          billing_cycle_start: string
          commission_cap_amount?: number | null
          commission_rate: number
          created_at?: string
          features?: Json | null
          id?: string
          max_branches: number
          max_products: number
          max_staff_users: number
          monthly_fee: number
          monthly_transaction_quota: number
          plan_tier: string
          status?: string | null
          tenant_id?: string | null
          updated_at?: string
        }
        Update: {
          billing_cycle_end?: string
          billing_cycle_start?: string
          commission_cap_amount?: number | null
          commission_rate?: number
          created_at?: string
          features?: Json | null
          id?: string
          max_branches?: number
          max_products?: number
          max_staff_users?: number
          monthly_fee?: number
          monthly_transaction_quota?: number
          plan_tier?: string
          status?: string | null
          tenant_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "subscriptions_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: true
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      sync_logs: {
        Row: {
          completed_at: string | null
          conflicts_detected: number | null
          connection_id: string | null
          created_at: string | null
          duration_seconds: number | null
          error_details: Json | null
          error_message: string | null
          id: string
          items_failed: number | null
          items_processed: number | null
          items_succeeded: number | null
          started_at: string
          status: string
          sync_direction: string
          sync_type: string
          tenant_id: string
          triggered_by: string | null
          triggered_by_user_id: string | null
        }
        Insert: {
          completed_at?: string | null
          conflicts_detected?: number | null
          connection_id?: string | null
          created_at?: string | null
          duration_seconds?: number | null
          error_details?: Json | null
          error_message?: string | null
          id?: string
          items_failed?: number | null
          items_processed?: number | null
          items_succeeded?: number | null
          started_at: string
          status: string
          sync_direction: string
          sync_type: string
          tenant_id: string
          triggered_by?: string | null
          triggered_by_user_id?: string | null
        }
        Update: {
          completed_at?: string | null
          conflicts_detected?: number | null
          connection_id?: string | null
          created_at?: string | null
          duration_seconds?: number | null
          error_details?: Json | null
          error_message?: string | null
          id?: string
          items_failed?: number | null
          items_processed?: number | null
          items_succeeded?: number | null
          started_at?: string
          status?: string
          sync_direction?: string
          sync_type?: string
          tenant_id?: string
          triggered_by?: string | null
          triggered_by_user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "sync_logs_connection_id_fkey"
            columns: ["connection_id"]
            isOneToOne: false
            referencedRelation: "ecommerce_connections"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sync_logs_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sync_logs_triggered_by_user_id_fkey"
            columns: ["triggered_by_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      system_config: {
        Row: {
          created_at: string | null
          description: string | null
          key: string
          updated_at: string | null
          value: string
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          key: string
          updated_at?: string | null
          value: string
        }
        Update: {
          created_at?: string | null
          description?: string | null
          key?: string
          updated_at?: string | null
          value?: string
        }
        Relationships: []
      }
      tenant_branding: {
        Row: {
          background_color: string
          branch_id: string | null
          brand_color: string
          business_name: string
          created_at: string
          id: string
          logo_url: string | null
          tenant_id: string
          updated_at: string
        }
        Insert: {
          background_color?: string
          branch_id?: string | null
          brand_color?: string
          business_name: string
          created_at?: string
          id?: string
          logo_url?: string | null
          tenant_id: string
          updated_at?: string
        }
        Update: {
          background_color?: string
          branch_id?: string | null
          brand_color?: string
          business_name?: string
          created_at?: string
          id?: string
          logo_url?: string | null
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "tenant_branding_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: true
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tenant_branding_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      tenants: {
        Row: {
          address: string | null
          brand_color: string | null
          business_type: Database["public"]["Enums"]["business_type"] | null
          city: string | null
          country: string | null
          created_at: string
          custom_domain: string | null
          custom_domain_verified: boolean | null
          deleted_at: string | null
          ecommerce_enabled: boolean | null
          ecommerce_settings: Json | null
          email: string | null
          id: string
          latitude: number | null
          logo_url: string | null
          longitude: number | null
          name: string
          office_address: string | null
          phone: string | null
          slug: string
          subscription_id: string | null
          updated_at: string
        }
        Insert: {
          address?: string | null
          brand_color?: string | null
          business_type?: Database["public"]["Enums"]["business_type"] | null
          city?: string | null
          country?: string | null
          created_at?: string
          custom_domain?: string | null
          custom_domain_verified?: boolean | null
          deleted_at?: string | null
          ecommerce_enabled?: boolean | null
          ecommerce_settings?: Json | null
          email?: string | null
          id?: string
          latitude?: number | null
          logo_url?: string | null
          longitude?: number | null
          name: string
          office_address?: string | null
          phone?: string | null
          slug: string
          subscription_id?: string | null
          updated_at?: string
        }
        Update: {
          address?: string | null
          brand_color?: string | null
          business_type?: Database["public"]["Enums"]["business_type"] | null
          city?: string | null
          country?: string | null
          created_at?: string
          custom_domain?: string | null
          custom_domain_verified?: boolean | null
          deleted_at?: string | null
          ecommerce_enabled?: boolean | null
          ecommerce_settings?: Json | null
          email?: string | null
          id?: string
          latitude?: number | null
          logo_url?: string | null
          longitude?: number | null
          name?: string
          office_address?: string | null
          phone?: string | null
          slug?: string
          subscription_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "tenants_subscription_id_fkey"
            columns: ["subscription_id"]
            isOneToOne: false
            referencedRelation: "subscriptions"
            referencedColumns: ["id"]
          },
        ]
      }
      transfer_items: {
        Row: {
          id: string
          product_id: string
          quantity: number
          tenant_id: string | null
          transfer_id: string
        }
        Insert: {
          id?: string
          product_id: string
          quantity: number
          tenant_id?: string | null
          transfer_id: string
        }
        Update: {
          id?: string
          product_id?: string
          quantity?: number
          tenant_id?: string | null
          transfer_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "transfer_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "ecommerce_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transfer_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transfer_items_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "transfer_items_transfer_id_fkey"
            columns: ["transfer_id"]
            isOneToOne: false
            referencedRelation: "inter_branch_transfers"
            referencedColumns: ["id"]
          },
        ]
      }
      user_passkeys: {
        Row: {
          backed_up: boolean | null
          counter: number
          created_at: string
          credential_id: string
          credential_public_key: string
          device_name: string | null
          device_type: string | null
          id: string
          last_used_at: string | null
          transports: Json | null
          user_id: string
        }
        Insert: {
          backed_up?: boolean | null
          counter?: number
          created_at?: string
          credential_id: string
          credential_public_key: string
          device_name?: string | null
          device_type?: string | null
          id?: string
          last_used_at?: string | null
          transports?: Json | null
          user_id: string
        }
        Update: {
          backed_up?: boolean | null
          counter?: number
          created_at?: string
          credential_id?: string
          credential_public_key?: string
          device_name?: string | null
          device_type?: string | null
          id?: string
          last_used_at?: string | null
          transports?: Json | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_passkeys_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      users: {
        Row: {
          avatar_url: string | null
          branch_id: string | null
          created_at: string
          deleted_at: string | null
          email: string | null
          full_name: string
          gender: string | null
          id: string
          last_login_at: string | null
          onboarding_completed_at: string | null
          passcode_hash: string | null
          phone: string | null
          profile_picture_url: string | null
          role: Database["public"]["Enums"]["user_role"]
          tenant_id: string | null
          updated_at: string
        }
        Insert: {
          avatar_url?: string | null
          branch_id?: string | null
          created_at?: string
          deleted_at?: string | null
          email?: string | null
          full_name: string
          gender?: string | null
          id: string
          last_login_at?: string | null
          onboarding_completed_at?: string | null
          passcode_hash?: string | null
          phone?: string | null
          profile_picture_url?: string | null
          role: Database["public"]["Enums"]["user_role"]
          tenant_id?: string | null
          updated_at?: string
        }
        Update: {
          avatar_url?: string | null
          branch_id?: string | null
          created_at?: string
          deleted_at?: string | null
          email?: string | null
          full_name?: string
          gender?: string | null
          id?: string
          last_login_at?: string | null
          onboarding_completed_at?: string | null
          passcode_hash?: string | null
          phone?: string | null
          profile_picture_url?: string | null
          role?: Database["public"]["Enums"]["user_role"]
          tenant_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "users_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "users_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      whatsapp_messages: {
        Row: {
          created_at: string
          customer_id: string
          delivery_status:
            | Database["public"]["Enums"]["whatsapp_delivery_status"]
            | null
          direction: Database["public"]["Enums"]["message_direction"]
          error_message: string | null
          id: string
          media_url: string | null
          message_content: string
          message_type: Database["public"]["Enums"]["message_type"]
          order_id: string | null
          template_name: string | null
          tenant_id: string
          whatsapp_message_id: string | null
        }
        Insert: {
          created_at?: string
          customer_id: string
          delivery_status?:
            | Database["public"]["Enums"]["whatsapp_delivery_status"]
            | null
          direction: Database["public"]["Enums"]["message_direction"]
          error_message?: string | null
          id?: string
          media_url?: string | null
          message_content: string
          message_type: Database["public"]["Enums"]["message_type"]
          order_id?: string | null
          template_name?: string | null
          tenant_id: string
          whatsapp_message_id?: string | null
        }
        Update: {
          created_at?: string
          customer_id?: string
          delivery_status?:
            | Database["public"]["Enums"]["whatsapp_delivery_status"]
            | null
          direction?: Database["public"]["Enums"]["message_direction"]
          error_message?: string | null
          id?: string
          media_url?: string | null
          message_content?: string
          message_type?: Database["public"]["Enums"]["message_type"]
          order_id?: string | null
          template_name?: string | null
          tenant_id?: string
          whatsapp_message_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "whatsapp_messages_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "customers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "whatsapp_messages_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "whatsapp_messages_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      ecommerce_products: {
        Row: {
          branch_count: number | null
          branches: Json | null
          category: string | null
          created_at: string | null
          description: string | null
          id: string | null
          image_url: string | null
          is_active: boolean | null
          max_price: number | null
          min_price: number | null
          name: string | null
          tenant_id: string | null
          total_stock: number | null
          unit_price: number | null
          updated_at: string | null
        }
        Relationships: [
          {
            foreignKeyName: "products_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      geography_columns: {
        Row: {
          coord_dimension: number | null
          f_geography_column: unknown
          f_table_catalog: unknown
          f_table_name: unknown
          f_table_schema: unknown
          srid: number | null
          type: string | null
        }
        Relationships: []
      }
      geometry_columns: {
        Row: {
          coord_dimension: number | null
          f_geometry_column: unknown
          f_table_catalog: string | null
          f_table_name: unknown
          f_table_schema: unknown
          srid: number | null
          type: string | null
        }
        Insert: {
          coord_dimension?: number | null
          f_geometry_column?: unknown
          f_table_catalog?: string | null
          f_table_name?: unknown
          f_table_schema?: unknown
          srid?: number | null
          type?: string | null
        }
        Update: {
          coord_dimension?: number | null
          f_geometry_column?: unknown
          f_table_catalog?: string | null
          f_table_name?: unknown
          f_table_schema?: unknown
          srid?: number | null
          type?: string | null
        }
        Relationships: []
      }
      storefront_products_with_catalog: {
        Row: {
          barcode: string | null
          branch_id: string | null
          brand: string | null
          business_type: string | null
          catalog_product_id: string | null
          category: string | null
          compare_at_price: number | null
          cost_price: number | null
          created_at: string | null
          description: string | null
          has_variants: boolean | null
          id: string | null
          images: string[] | null
          is_available: boolean | null
          low_stock_threshold: number | null
          name: string | null
          price: number | null
          primary_image: string | null
          sku: string | null
          specifications: Json | null
          stock_quantity: number | null
          synced_at: string | null
          tenant_id: string | null
          updated_at: string | null
        }
        Relationships: [
          {
            foreignKeyName: "storefront_products_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "storefront_products_catalog_product_id_fkey"
            columns: ["catalog_product_id"]
            isOneToOne: false
            referencedRelation: "global_product_catalog"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "storefront_products_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Functions: {
      _postgis_deprecate: {
        Args: { newname: string; oldname: string; version: string }
        Returns: undefined
      }
      _postgis_index_extent: {
        Args: { col: string; tbl: unknown }
        Returns: unknown
      }
      _postgis_pgsql_version: { Args: never; Returns: string }
      _postgis_scripts_pgsql_version: { Args: never; Returns: string }
      _postgis_selectivity: {
        Args: { att_name: string; geom: unknown; mode?: string; tbl: unknown }
        Returns: number
      }
      _postgis_stats: {
        Args: { ""?: string; att_name: string; tbl: unknown }
        Returns: string
      }
      _st_3dintersects: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_contains: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_containsproperly: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_coveredby:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _st_covers:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _st_crosses: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_dwithin: {
        Args: {
          geog1: unknown
          geog2: unknown
          tolerance: number
          use_spheroid?: boolean
        }
        Returns: boolean
      }
      _st_equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _st_intersects: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_linecrossingdirection: {
        Args: { line1: unknown; line2: unknown }
        Returns: number
      }
      _st_longestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      _st_maxdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      _st_orderingequals: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_overlaps: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_sortablehash: { Args: { geom: unknown }; Returns: number }
      _st_touches: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_voronoi: {
        Args: {
          clip?: unknown
          g1: unknown
          return_polygons?: boolean
          tolerance?: number
        }
        Returns: unknown
      }
      _st_within: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      addauth: { Args: { "": string }; Returns: boolean }
      addgeometrycolumn:
        | {
            Args: {
              catalog_name: string
              column_name: string
              new_dim: number
              new_srid_in: number
              new_type: string
              schema_name: string
              table_name: string
              use_typmod?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              column_name: string
              new_dim: number
              new_srid: number
              new_type: string
              schema_name: string
              table_name: string
              use_typmod?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              column_name: string
              new_dim: number
              new_srid: number
              new_type: string
              table_name: string
              use_typmod?: boolean
            }
            Returns: string
          }
      calculate_commission: {
        Args: { p_order_amount: number; p_tenant_id: string }
        Returns: number
      }
      calculate_storefront_order_total: {
        Args: { p_delivery_base_fee: number; p_subtotal: number }
        Returns: number
      }
      can_access_branch: { Args: { check_branch_id: string }; Returns: boolean }
      can_enable_ecommerce: { Args: { p_tenant_id: string }; Returns: boolean }
      can_manage_products: { Args: never; Returns: boolean }
      can_manage_users: { Args: never; Returns: boolean }
      can_use_custom_domain: { Args: { p_tenant_id: string }; Returns: boolean }
      can_view_reports: { Args: never; Returns: boolean }
      can_void_sales: { Args: never; Returns: boolean }
      cleanup_expired_challenges: { Args: never; Returns: undefined }
      current_tenant_id: { Args: never; Returns: string }
      current_user_branch_id: { Args: never; Returns: string }
      current_user_role: { Args: never; Returns: string }
      disablelongtransactions: { Args: never; Returns: string }
      dropgeometrycolumn:
        | {
            Args: {
              catalog_name: string
              column_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
        | {
            Args: {
              column_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
        | { Args: { column_name: string; table_name: string }; Returns: string }
      dropgeometrytable:
        | {
            Args: {
              catalog_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
        | { Args: { schema_name: string; table_name: string }; Returns: string }
        | { Args: { table_name: string }; Returns: string }
      enablelongtransactions: { Args: never; Returns: string }
      equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      generate_storefront_order_number: { Args: never; Returns: string }
      geometry: { Args: { "": string }; Returns: unknown }
      geometry_above: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_below: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_cmp: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      geometry_contained_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_contains: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_contains_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_distance_box: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      geometry_distance_centroid: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      geometry_eq: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_ge: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_gt: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_le: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_left: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_lt: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overabove: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overbelow: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overlaps: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overlaps_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overleft: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overright: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_right: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_same: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_same_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_within: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geomfromewkt: { Args: { "": string }; Returns: unknown }
      get_accessible_branches: { Args: never; Returns: string[] }
      get_ecommerce_products: {
        Args: {
          p_branch_id?: string
          p_category?: string
          p_in_stock_only?: boolean
          p_latitude?: number
          p_longitude?: number
          p_max_distance_km?: number
          p_tenant_id: string
        }
        Returns: {
          branch_count: number
          branches: Json
          category: string
          description: string
          image_url: string
          max_price: number
          min_price: number
          product_id: string
          product_name: string
          total_stock: number
          unit_price: number
        }[]
      }
      get_storefront_url: {
        Args: { p_base_url?: string; p_tenant_id: string }
        Returns: string
      }
      gettransactionid: { Args: never; Returns: unknown }
      has_chat_feature: { Args: { p_tenant_id: string }; Returns: boolean }
      has_ecommerce_chat_feature: {
        Args: { p_tenant_id: string }
        Returns: boolean
      }
      has_permission: { Args: { required_role: string }; Returns: boolean }
      is_in_tenant: { Args: { check_tenant_id: string }; Returns: boolean }
      log_audit_event: {
        Args: {
          p_new_data?: Json
          p_old_data?: Json
          p_operation: string
          p_record_id: string
          p_table_name: string
        }
        Returns: undefined
      }
      longtransactionsenabled: { Args: never; Returns: boolean }
      populate_geometry_columns:
        | { Args: { tbl_oid: unknown; use_typmod?: boolean }; Returns: number }
        | { Args: { use_typmod?: boolean }; Returns: string }
      postgis_constraint_dims: {
        Args: { geomcolumn: string; geomschema: string; geomtable: string }
        Returns: number
      }
      postgis_constraint_srid: {
        Args: { geomcolumn: string; geomschema: string; geomtable: string }
        Returns: number
      }
      postgis_constraint_type: {
        Args: { geomcolumn: string; geomschema: string; geomtable: string }
        Returns: string
      }
      postgis_extensions_upgrade: { Args: never; Returns: string }
      postgis_full_version: { Args: never; Returns: string }
      postgis_geos_version: { Args: never; Returns: string }
      postgis_lib_build_date: { Args: never; Returns: string }
      postgis_lib_revision: { Args: never; Returns: string }
      postgis_lib_version: { Args: never; Returns: string }
      postgis_libjson_version: { Args: never; Returns: string }
      postgis_liblwgeom_version: { Args: never; Returns: string }
      postgis_libprotobuf_version: { Args: never; Returns: string }
      postgis_libxml_version: { Args: never; Returns: string }
      postgis_proj_version: { Args: never; Returns: string }
      postgis_scripts_build_date: { Args: never; Returns: string }
      postgis_scripts_installed: { Args: never; Returns: string }
      postgis_scripts_released: { Args: never; Returns: string }
      postgis_svn_version: { Args: never; Returns: string }
      postgis_type_name: {
        Args: {
          coord_dimension: number
          geomname: string
          use_new_name?: boolean
        }
        Returns: string
      }
      postgis_version: { Args: never; Returns: string }
      postgis_wagyu_version: { Args: never; Returns: string }
      release_expired_slot_holds: { Args: never; Returns: undefined }
      search_catalog_for_tenant: {
        Args: {
          p_category?: string
          p_search_query?: string
          p_tenant_id: string
          p_verified_only?: boolean
        }
        Returns: {
          already_in_inventory: boolean
          barcode: string
          brand: string
          category: string
          description: string
          id: string
          is_verified: boolean
          name: string
          primary_image: string
          specifications: Json
        }[]
      }
      search_global_catalog: {
        Args: {
          p_business_type: string
          p_category?: string
          p_search_query?: string
          p_verified_only?: boolean
        }
        Returns: {
          barcode: string
          brand: string
          category: string
          description: string
          id: string
          is_verified: boolean
          name: string
          primary_image: string
          specifications: Json
        }[]
      }
      show_limit: { Args: never; Returns: number }
      show_trgm: { Args: { "": string }; Returns: string[] }
      st_3dclosestpoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_3ddistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_3dintersects: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_3dlongestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_3dmakebox: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_3dmaxdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_3dshortestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_addpoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_angle:
        | { Args: { line1: unknown; line2: unknown }; Returns: number }
        | {
            Args: { pt1: unknown; pt2: unknown; pt3: unknown; pt4?: unknown }
            Returns: number
          }
      st_area:
        | { Args: { geog: unknown; use_spheroid?: boolean }; Returns: number }
        | { Args: { "": string }; Returns: number }
      st_asencodedpolyline: {
        Args: { geom: unknown; nprecision?: number }
        Returns: string
      }
      st_asewkt: { Args: { "": string }; Returns: string }
      st_asgeojson:
        | {
            Args: { geog: unknown; maxdecimaldigits?: number; options?: number }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; options?: number }
            Returns: string
          }
        | {
            Args: {
              geom_column?: string
              maxdecimaldigits?: number
              pretty_bool?: boolean
              r: Record<string, unknown>
            }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_asgml:
        | {
            Args: {
              geog: unknown
              id?: string
              maxdecimaldigits?: number
              nprefix?: string
              options?: number
            }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; options?: number }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
        | {
            Args: {
              geog: unknown
              id?: string
              maxdecimaldigits?: number
              nprefix?: string
              options?: number
              version: number
            }
            Returns: string
          }
        | {
            Args: {
              geom: unknown
              id?: string
              maxdecimaldigits?: number
              nprefix?: string
              options?: number
              version: number
            }
            Returns: string
          }
      st_askml:
        | {
            Args: { geog: unknown; maxdecimaldigits?: number; nprefix?: string }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; nprefix?: string }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_aslatlontext: {
        Args: { geom: unknown; tmpl?: string }
        Returns: string
      }
      st_asmarc21: { Args: { format?: string; geom: unknown }; Returns: string }
      st_asmvtgeom: {
        Args: {
          bounds: unknown
          buffer?: number
          clip_geom?: boolean
          extent?: number
          geom: unknown
        }
        Returns: unknown
      }
      st_assvg:
        | {
            Args: { geog: unknown; maxdecimaldigits?: number; rel?: number }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; rel?: number }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_astext: { Args: { "": string }; Returns: string }
      st_astwkb:
        | {
            Args: {
              geom: unknown
              prec?: number
              prec_m?: number
              prec_z?: number
              with_boxes?: boolean
              with_sizes?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              geom: unknown[]
              ids: number[]
              prec?: number
              prec_m?: number
              prec_z?: number
              with_boxes?: boolean
              with_sizes?: boolean
            }
            Returns: string
          }
      st_asx3d: {
        Args: { geom: unknown; maxdecimaldigits?: number; options?: number }
        Returns: string
      }
      st_azimuth:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: number }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: number }
      st_boundingdiagonal: {
        Args: { fits?: boolean; geom: unknown }
        Returns: unknown
      }
      st_buffer:
        | {
            Args: { geom: unknown; options?: string; radius: number }
            Returns: unknown
          }
        | {
            Args: { geom: unknown; quadsegs: number; radius: number }
            Returns: unknown
          }
      st_centroid: { Args: { "": string }; Returns: unknown }
      st_clipbybox2d: {
        Args: { box: unknown; geom: unknown }
        Returns: unknown
      }
      st_closestpoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_collect: { Args: { geom1: unknown; geom2: unknown }; Returns: unknown }
      st_concavehull: {
        Args: {
          param_allow_holes?: boolean
          param_geom: unknown
          param_pctconvex: number
        }
        Returns: unknown
      }
      st_contains: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_containsproperly: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_coorddim: { Args: { geometry: unknown }; Returns: number }
      st_coveredby:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_covers:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_crosses: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_curvetoline: {
        Args: { flags?: number; geom: unknown; tol?: number; toltype?: number }
        Returns: unknown
      }
      st_delaunaytriangles: {
        Args: { flags?: number; g1: unknown; tolerance?: number }
        Returns: unknown
      }
      st_difference: {
        Args: { geom1: unknown; geom2: unknown; gridsize?: number }
        Returns: unknown
      }
      st_disjoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_distance:
        | {
            Args: { geog1: unknown; geog2: unknown; use_spheroid?: boolean }
            Returns: number
          }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: number }
      st_distancesphere:
        | { Args: { geom1: unknown; geom2: unknown }; Returns: number }
        | {
            Args: { geom1: unknown; geom2: unknown; radius: number }
            Returns: number
          }
      st_distancespheroid: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_dwithin: {
        Args: {
          geog1: unknown
          geog2: unknown
          tolerance: number
          use_spheroid?: boolean
        }
        Returns: boolean
      }
      st_equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_expand:
        | { Args: { box: unknown; dx: number; dy: number }; Returns: unknown }
        | {
            Args: { box: unknown; dx: number; dy: number; dz?: number }
            Returns: unknown
          }
        | {
            Args: {
              dm?: number
              dx: number
              dy: number
              dz?: number
              geom: unknown
            }
            Returns: unknown
          }
      st_force3d: { Args: { geom: unknown; zvalue?: number }; Returns: unknown }
      st_force3dm: {
        Args: { geom: unknown; mvalue?: number }
        Returns: unknown
      }
      st_force3dz: {
        Args: { geom: unknown; zvalue?: number }
        Returns: unknown
      }
      st_force4d: {
        Args: { geom: unknown; mvalue?: number; zvalue?: number }
        Returns: unknown
      }
      st_generatepoints:
        | { Args: { area: unknown; npoints: number }; Returns: unknown }
        | {
            Args: { area: unknown; npoints: number; seed: number }
            Returns: unknown
          }
      st_geogfromtext: { Args: { "": string }; Returns: unknown }
      st_geographyfromtext: { Args: { "": string }; Returns: unknown }
      st_geohash:
        | { Args: { geog: unknown; maxchars?: number }; Returns: string }
        | { Args: { geom: unknown; maxchars?: number }; Returns: string }
      st_geomcollfromtext: { Args: { "": string }; Returns: unknown }
      st_geometricmedian: {
        Args: {
          fail_if_not_converged?: boolean
          g: unknown
          max_iter?: number
          tolerance?: number
        }
        Returns: unknown
      }
      st_geometryfromtext: { Args: { "": string }; Returns: unknown }
      st_geomfromewkt: { Args: { "": string }; Returns: unknown }
      st_geomfromgeojson:
        | { Args: { "": Json }; Returns: unknown }
        | { Args: { "": Json }; Returns: unknown }
        | { Args: { "": string }; Returns: unknown }
      st_geomfromgml: { Args: { "": string }; Returns: unknown }
      st_geomfromkml: { Args: { "": string }; Returns: unknown }
      st_geomfrommarc21: { Args: { marc21xml: string }; Returns: unknown }
      st_geomfromtext: { Args: { "": string }; Returns: unknown }
      st_gmltosql: { Args: { "": string }; Returns: unknown }
      st_hasarc: { Args: { geometry: unknown }; Returns: boolean }
      st_hausdorffdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_hexagon: {
        Args: { cell_i: number; cell_j: number; origin?: unknown; size: number }
        Returns: unknown
      }
      st_hexagongrid: {
        Args: { bounds: unknown; size: number }
        Returns: Record<string, unknown>[]
      }
      st_interpolatepoint: {
        Args: { line: unknown; point: unknown }
        Returns: number
      }
      st_intersection: {
        Args: { geom1: unknown; geom2: unknown; gridsize?: number }
        Returns: unknown
      }
      st_intersects:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_isvaliddetail: {
        Args: { flags?: number; geom: unknown }
        Returns: Database["public"]["CompositeTypes"]["valid_detail"]
        SetofOptions: {
          from: "*"
          to: "valid_detail"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      st_length:
        | { Args: { geog: unknown; use_spheroid?: boolean }; Returns: number }
        | { Args: { "": string }; Returns: number }
      st_letters: { Args: { font?: Json; letters: string }; Returns: unknown }
      st_linecrossingdirection: {
        Args: { line1: unknown; line2: unknown }
        Returns: number
      }
      st_linefromencodedpolyline: {
        Args: { nprecision?: number; txtin: string }
        Returns: unknown
      }
      st_linefromtext: { Args: { "": string }; Returns: unknown }
      st_linelocatepoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_linetocurve: { Args: { geometry: unknown }; Returns: unknown }
      st_locatealong: {
        Args: { geometry: unknown; leftrightoffset?: number; measure: number }
        Returns: unknown
      }
      st_locatebetween: {
        Args: {
          frommeasure: number
          geometry: unknown
          leftrightoffset?: number
          tomeasure: number
        }
        Returns: unknown
      }
      st_locatebetweenelevations: {
        Args: { fromelevation: number; geometry: unknown; toelevation: number }
        Returns: unknown
      }
      st_longestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_makebox2d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_makeline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_makevalid: {
        Args: { geom: unknown; params: string }
        Returns: unknown
      }
      st_maxdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_minimumboundingcircle: {
        Args: { inputgeom: unknown; segs_per_quarter?: number }
        Returns: unknown
      }
      st_mlinefromtext: { Args: { "": string }; Returns: unknown }
      st_mpointfromtext: { Args: { "": string }; Returns: unknown }
      st_mpolyfromtext: { Args: { "": string }; Returns: unknown }
      st_multilinestringfromtext: { Args: { "": string }; Returns: unknown }
      st_multipointfromtext: { Args: { "": string }; Returns: unknown }
      st_multipolygonfromtext: { Args: { "": string }; Returns: unknown }
      st_node: { Args: { g: unknown }; Returns: unknown }
      st_normalize: { Args: { geom: unknown }; Returns: unknown }
      st_offsetcurve: {
        Args: { distance: number; line: unknown; params?: string }
        Returns: unknown
      }
      st_orderingequals: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_overlaps: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_perimeter: {
        Args: { geog: unknown; use_spheroid?: boolean }
        Returns: number
      }
      st_pointfromtext: { Args: { "": string }; Returns: unknown }
      st_pointm: {
        Args: {
          mcoordinate: number
          srid?: number
          xcoordinate: number
          ycoordinate: number
        }
        Returns: unknown
      }
      st_pointz: {
        Args: {
          srid?: number
          xcoordinate: number
          ycoordinate: number
          zcoordinate: number
        }
        Returns: unknown
      }
      st_pointzm: {
        Args: {
          mcoordinate: number
          srid?: number
          xcoordinate: number
          ycoordinate: number
          zcoordinate: number
        }
        Returns: unknown
      }
      st_polyfromtext: { Args: { "": string }; Returns: unknown }
      st_polygonfromtext: { Args: { "": string }; Returns: unknown }
      st_project: {
        Args: { azimuth: number; distance: number; geog: unknown }
        Returns: unknown
      }
      st_quantizecoordinates: {
        Args: {
          g: unknown
          prec_m?: number
          prec_x: number
          prec_y?: number
          prec_z?: number
        }
        Returns: unknown
      }
      st_reduceprecision: {
        Args: { geom: unknown; gridsize: number }
        Returns: unknown
      }
      st_relate: { Args: { geom1: unknown; geom2: unknown }; Returns: string }
      st_removerepeatedpoints: {
        Args: { geom: unknown; tolerance?: number }
        Returns: unknown
      }
      st_segmentize: {
        Args: { geog: unknown; max_segment_length: number }
        Returns: unknown
      }
      st_setsrid:
        | { Args: { geog: unknown; srid: number }; Returns: unknown }
        | { Args: { geom: unknown; srid: number }; Returns: unknown }
      st_sharedpaths: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_shortestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_simplifypolygonhull: {
        Args: { geom: unknown; is_outer?: boolean; vertex_fraction: number }
        Returns: unknown
      }
      st_split: { Args: { geom1: unknown; geom2: unknown }; Returns: unknown }
      st_square: {
        Args: { cell_i: number; cell_j: number; origin?: unknown; size: number }
        Returns: unknown
      }
      st_squaregrid: {
        Args: { bounds: unknown; size: number }
        Returns: Record<string, unknown>[]
      }
      st_srid:
        | { Args: { geog: unknown }; Returns: number }
        | { Args: { geom: unknown }; Returns: number }
      st_subdivide: {
        Args: { geom: unknown; gridsize?: number; maxvertices?: number }
        Returns: unknown[]
      }
      st_swapordinates: {
        Args: { geom: unknown; ords: unknown }
        Returns: unknown
      }
      st_symdifference: {
        Args: { geom1: unknown; geom2: unknown; gridsize?: number }
        Returns: unknown
      }
      st_symmetricdifference: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_tileenvelope: {
        Args: {
          bounds?: unknown
          margin?: number
          x: number
          y: number
          zoom: number
        }
        Returns: unknown
      }
      st_touches: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_transform:
        | {
            Args: { from_proj: string; geom: unknown; to_proj: string }
            Returns: unknown
          }
        | {
            Args: { from_proj: string; geom: unknown; to_srid: number }
            Returns: unknown
          }
        | { Args: { geom: unknown; to_proj: string }; Returns: unknown }
      st_triangulatepolygon: { Args: { g1: unknown }; Returns: unknown }
      st_union:
        | { Args: { geom1: unknown; geom2: unknown }; Returns: unknown }
        | {
            Args: { geom1: unknown; geom2: unknown; gridsize: number }
            Returns: unknown
          }
      st_voronoilines: {
        Args: { extend_to?: unknown; g1: unknown; tolerance?: number }
        Returns: unknown
      }
      st_voronoipolygons: {
        Args: { extend_to?: unknown; g1: unknown; tolerance?: number }
        Returns: unknown
      }
      st_within: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_wkbtosql: { Args: { wkb: string }; Returns: unknown }
      st_wkttosql: { Args: { "": string }; Returns: unknown }
      st_wrapx: {
        Args: { geom: unknown; move: number; wrap: number }
        Returns: unknown
      }
      unlockrows: { Args: { "": string }; Returns: number }
      updategeometrysrid: {
        Args: {
          catalogn_name: string
          column_name: string
          new_srid_in: number
          schema_name: string
          table_name: string
        }
        Returns: string
      }
    }
    Enums: {
      business_type:
        | "supermarket"
        | "pharmacy"
        | "grocery"
        | "mini_mart"
        | "restaurant"
      chat_action_type:
        | "add_to_cart"
        | "apply_discount"
        | "view_product"
        | "confirm_payment"
        | "update_delivery_address"
        | "request_human_agent"
      chat_message_type:
        | "text"
        | "image"
        | "audio"
        | "video"
        | "location"
        | "product_card"
        | "receipt"
        | "payment_confirmation"
        | "discount_applied"
        | "system_action"
      chat_status: "active" | "completed" | "escalated" | "abandoned"
      delivery_status:
        | "pending"
        | "assigned"
        | "picked_up"
        | "in_transit"
        | "delivered"
        | "failed"
        | "cancelled"
      delivery_type: "local_bike" | "local_bicycle" | "intercity"
      fulfillment_type: "pickup" | "delivery"
      message_direction: "outbound" | "inbound"
      message_type: "text" | "template" | "media"
      order_status:
        | "pending"
        | "confirmed"
        | "preparing"
        | "ready"
        | "completed"
        | "cancelled"
      order_type: "marketplace" | "ecommerce_sync" | "ai_chat"
      payment_method: "cash" | "card" | "bank_transfer" | "mobile_money"
      payment_status: "unpaid" | "paid" | "refunded"
      plan_tier: "free" | "basic" | "pro" | "enterprise" | "enterprise_custom"
      platform_type: "woocommerce" | "shopify" | "custom"
      proof_type: "photo" | "signature" | "recipient_name"
      receipt_format: "pdf" | "thermal_print" | "email"
      sale_status: "completed" | "voided" | "refunded"
      sender_type: "customer" | "ai_agent" | "staff"
      settlement_status: "pending" | "invoiced" | "paid"
      subscription_status: "active" | "suspended" | "cancelled"
      sync_status: "pending" | "syncing" | "success" | "error"
      transaction_type:
        | "sale"
        | "restock"
        | "adjustment"
        | "expiry"
        | "transfer_out"
        | "transfer_in"
      transfer_status: "pending" | "in_transit" | "completed" | "cancelled"
      user_role:
        | "platform_admin"
        | "tenant_admin"
        | "branch_manager"
        | "cashier"
        | "driver"
        | "supervisor"
        | "stock_keeper"
      vehicle_type: "bike" | "bicycle"
      whatsapp_delivery_status:
        | "pending"
        | "sent"
        | "delivered"
        | "read"
        | "failed"
    }
    CompositeTypes: {
      geometry_dump: {
        path: number[] | null
        geom: unknown
      }
      valid_detail: {
        valid: boolean | null
        reason: string | null
        location: unknown
      }
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {
      business_type: [
        "supermarket",
        "pharmacy",
        "grocery",
        "mini_mart",
        "restaurant",
      ],
      chat_action_type: [
        "add_to_cart",
        "apply_discount",
        "view_product",
        "confirm_payment",
        "update_delivery_address",
        "request_human_agent",
      ],
      chat_message_type: [
        "text",
        "image",
        "audio",
        "video",
        "location",
        "product_card",
        "receipt",
        "payment_confirmation",
        "discount_applied",
        "system_action",
      ],
      chat_status: ["active", "completed", "escalated", "abandoned"],
      delivery_status: [
        "pending",
        "assigned",
        "picked_up",
        "in_transit",
        "delivered",
        "failed",
        "cancelled",
      ],
      delivery_type: ["local_bike", "local_bicycle", "intercity"],
      fulfillment_type: ["pickup", "delivery"],
      message_direction: ["outbound", "inbound"],
      message_type: ["text", "template", "media"],
      order_status: [
        "pending",
        "confirmed",
        "preparing",
        "ready",
        "completed",
        "cancelled",
      ],
      order_type: ["marketplace", "ecommerce_sync", "ai_chat"],
      payment_method: ["cash", "card", "bank_transfer", "mobile_money"],
      payment_status: ["unpaid", "paid", "refunded"],
      plan_tier: ["free", "basic", "pro", "enterprise", "enterprise_custom"],
      platform_type: ["woocommerce", "shopify", "custom"],
      proof_type: ["photo", "signature", "recipient_name"],
      receipt_format: ["pdf", "thermal_print", "email"],
      sale_status: ["completed", "voided", "refunded"],
      sender_type: ["customer", "ai_agent", "staff"],
      settlement_status: ["pending", "invoiced", "paid"],
      subscription_status: ["active", "suspended", "cancelled"],
      sync_status: ["pending", "syncing", "success", "error"],
      transaction_type: [
        "sale",
        "restock",
        "adjustment",
        "expiry",
        "transfer_out",
        "transfer_in",
      ],
      transfer_status: ["pending", "in_transit", "completed", "cancelled"],
      user_role: [
        "platform_admin",
        "tenant_admin",
        "branch_manager",
        "cashier",
        "driver",
        "supervisor",
        "stock_keeper",
      ],
      vehicle_type: ["bike", "bicycle"],
      whatsapp_delivery_status: [
        "pending",
        "sent",
        "delivered",
        "read",
        "failed",
      ],
    },
  },
} as const

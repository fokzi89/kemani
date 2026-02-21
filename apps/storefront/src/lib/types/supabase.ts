export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  public: {
    Tables: {
      // Storefront-specific tables
      storefront_customers: {
        Row: {
          id: string
          user_id: string | null
          email: string | null
          phone: string
          name: string
          delivery_address: Json | null
          delivery_coordinates: unknown | null
          created_at: string
          updated_at: string
          last_order_at: string | null
          total_orders: number
        }
        Insert: {
          id?: string
          user_id?: string | null
          email?: string | null
          phone: string
          name: string
          delivery_address?: Json | null
          delivery_coordinates?: unknown | null
          created_at?: string
          updated_at?: string
          last_order_at?: string | null
          total_orders?: number
        }
        Update: {
          id?: string
          user_id?: string | null
          email?: string | null
          phone?: string
          name?: string
          delivery_address?: Json | null
          delivery_coordinates?: unknown | null
          created_at?: string
          updated_at?: string
          last_order_at?: string | null
          total_orders?: number
        }
        Relationships: []
      }
      
      global_product_catalog: {
        Row: {
          id: string
          business_type: string
          name: string
          description: string | null
          category: string
          brand: string | null
          barcode: string | null
          sku_prefix: string | null
          images: string[] | null
          primary_image: string | null
          specifications: Json | null
          slug: string
          meta_title: string | null
          meta_description: string | null
          is_verified: boolean
          is_active: boolean
          created_at: string
          updated_at: string
          created_by: string | null
        }
        Insert: {
          id?: string
          business_type: string
          name: string
          description?: string | null
          category: string
          brand?: string | null
          barcode?: string | null
          sku_prefix?: string | null
          images?: string[] | null
          primary_image?: string | null
          specifications?: Json | null
          slug: string
          meta_title?: string | null
          meta_description?: string | null
          is_verified?: boolean
          is_active?: boolean
          created_at?: string
          updated_at?: string
          created_by?: string | null
        }
        Update: {
          id?: string
          business_type?: string
          name?: string
          description?: string | null
          category?: string
          brand?: string | null
          barcode?: string | null
          sku_prefix?: string | null
          images?: string[] | null
          primary_image?: string | null
          specifications?: Json | null
          slug?: string
          meta_title?: string | null
          meta_description?: string | null
          is_verified?: boolean
          is_active?: boolean
          created_at?: string
          updated_at?: string
          created_by?: string | null
        }
        Relationships: []
      }
      
      storefront_products: {
        Row: {
          id: string
          catalog_product_id: string | null
          tenant_id: string
          branch_id: string
          product_id: string | null
          sku: string
          price: number
          compare_at_price: number | null
          cost_price: number | null
          stock_quantity: number
          low_stock_threshold: number
          is_available: boolean
          custom_name: string | null
          custom_description: string | null
          custom_images: string[] | null
          has_variants: boolean
          created_at: string
          updated_at: string
          synced_at: string
        }
        Insert: {
          id?: string
          catalog_product_id?: string | null
          tenant_id: string
          branch_id: string
          product_id?: string | null
          sku: string
          price: number
          compare_at_price?: number | null
          cost_price?: number | null
          stock_quantity?: number
          low_stock_threshold?: number
          is_available?: boolean
          custom_name?: string | null
          custom_description?: string | null
          custom_images?: string[] | null
          has_variants?: boolean
          created_at?: string
          updated_at?: string
          synced_at?: string
        }
        Update: {
          id?: string
          catalog_product_id?: string | null
          tenant_id?: string
          branch_id?: string
          product_id?: string | null
          sku?: string
          price?: number
          compare_at_price?: number | null
          cost_price?: number | null
          stock_quantity?: number
          low_stock_threshold?: number
          is_available?: boolean
          custom_name?: string | null
          custom_description?: string | null
          custom_images?: string[] | null
          has_variants?: boolean
          created_at?: string
          updated_at?: string
          synced_at?: string
        }
        Relationships: []
      }
      
      product_variants: {
        Row: {
          id: string
          product_id: string
          variant_name: string
          options: Json
          sku: string
          price_adjustment: number
          stock_quantity: number
          is_available: boolean
          image_url: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          product_id: string
          variant_name: string
          options: Json
          sku: string
          price_adjustment?: number
          stock_quantity?: number
          is_available?: boolean
          image_url?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          product_id?: string
          variant_name?: string
          options?: Json
          sku?: string
          price_adjustment?: number
          stock_quantity?: number
          is_available?: boolean
          image_url?: string | null
          created_at?: string
          updated_at?: string
        }
        Relationships: []
      }
      
      shopping_carts: {
        Row: {
          id: string
          customer_id: string | null
          session_id: string
          branch_id: string
          tenant_id: string
          created_at: string
          updated_at: string
          expires_at: string
        }
        Insert: {
          id?: string
          customer_id?: string | null
          session_id: string
          branch_id: string
          tenant_id: string
          created_at?: string
          updated_at?: string
          expires_at?: string
        }
        Update: {
          id?: string
          customer_id?: string | null
          session_id?: string
          branch_id?: string
          tenant_id?: string
          created_at?: string
          updated_at?: string
          expires_at?: string
        }
        Relationships: []
      }
      
      cart_items: {
        Row: {
          id: string
          cart_id: string
          product_id: string
          variant_id: string | null
          quantity: number
          unit_price: number
          added_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          cart_id: string
          product_id: string
          variant_id?: string | null
          quantity?: number
          unit_price: number
          added_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          cart_id?: string
          product_id?: string
          variant_id?: string | null
          quantity?: number
          unit_price?: number
          added_at?: string
          updated_at?: string
        }
        Relationships: []
      }
      
      storefront_orders: {
        Row: {
          id: string
          order_number: string
          customer_id: string
          branch_id: string
          tenant_id: string
          delivery_name: string
          delivery_phone: string
          delivery_address: Json | null
          delivery_coordinates: unknown | null
          delivery_method: string
          delivery_instructions: string | null
          subtotal: number
          delivery_base_fee: number
          delivery_fee_addition: number
          platform_commission: number
          transaction_fee: number
          total_amount: number
          payment_status: string
          payment_method: string | null
          paystack_reference: string | null
          order_status: string
          created_at: string
          updated_at: string
          paid_at: string | null
          confirmed_at: string | null
          completed_at: string | null
        }
        Insert: {
          id?: string
          order_number: string
          customer_id: string
          branch_id: string
          tenant_id: string
          delivery_name: string
          delivery_phone: string
          delivery_address?: Json | null
          delivery_coordinates?: unknown | null
          delivery_method: string
          delivery_instructions?: string | null
          subtotal: number
          delivery_base_fee?: number
          delivery_fee_addition?: number
          platform_commission?: number
          transaction_fee?: number
          total_amount: number
          payment_status?: string
          payment_method?: string | null
          paystack_reference?: string | null
          order_status?: string
          created_at?: string
          updated_at?: string
          paid_at?: string | null
          confirmed_at?: string | null
          completed_at?: string | null
        }
        Update: {
          id?: string
          order_number?: string
          customer_id?: string
          branch_id?: string
          tenant_id?: string
          delivery_name?: string
          delivery_phone?: string
          delivery_address?: Json | null
          delivery_coordinates?: unknown | null
          delivery_method?: string
          delivery_instructions?: string | null
          subtotal?: number
          delivery_base_fee?: number
          delivery_fee_addition?: number
          platform_commission?: number
          transaction_fee?: number
          total_amount?: number
          payment_status?: string
          payment_method?: string | null
          paystack_reference?: string | null
          order_status?: string
          created_at?: string
          updated_at?: string
          paid_at?: string | null
          confirmed_at?: string | null
          completed_at?: string | null
        }
        Relationships: []
      }
      
      storefront_order_items: {
        Row: {
          id: string
          order_id: string
          product_id: string
          variant_id: string | null
          product_name: string
          product_sku: string
          variant_name: string | null
          unit_price: number
          quantity: number
          line_total: number
          created_at: string
        }
        Insert: {
          id?: string
          order_id: string
          product_id: string
          variant_id?: string | null
          product_name: string
          product_sku: string
          variant_name?: string | null
          unit_price: number
          quantity: number
          line_total: number
          created_at?: string
        }
        Update: {
          id?: string
          order_id?: string
          product_id?: string
          variant_id?: string | null
          product_name?: string
          product_sku?: string
          variant_name?: string | null
          unit_price?: number
          quantity?: number
          line_total?: number
          created_at?: string
        }
        Relationships: []
      }
      
      payment_transactions: {
        Row: {
          id: string
          order_id: string
          paystack_reference: string
          paystack_access_code: string | null
          paystack_transaction_id: string | null
          amount: number
          currency: string
          payment_method: string | null
          payment_channel: string | null
          status: string
          gateway_response: string | null
          webhook_payload: Json | null
          webhook_signature: string | null
          webhook_received_at: string | null
          created_at: string
          updated_at: string
          verified_at: string | null
        }
        Insert: {
          id?: string
          order_id: string
          paystack_reference: string
          paystack_access_code?: string | null
          paystack_transaction_id?: string | null
          amount: number
          currency?: string
          payment_method?: string | null
          payment_channel?: string | null
          status: string
          gateway_response?: string | null
          webhook_payload?: Json | null
          webhook_signature?: string | null
          webhook_received_at?: string | null
          created_at?: string
          updated_at?: string
          verified_at?: string | null
        }
        Update: {
          id?: string
          order_id?: string
          paystack_reference?: string
          paystack_access_code?: string | null
          paystack_transaction_id?: string | null
          amount?: number
          currency?: string
          payment_method?: string | null
          payment_channel?: string | null
          status?: string
          gateway_response?: string | null
          webhook_payload?: Json | null
          webhook_signature?: string | null
          webhook_received_at?: string | null
          created_at?: string
          updated_at?: string
          verified_at?: string | null
        }
        Relationships: []
      }
      
      chat_sessions: {
        Row: {
          id: string
          customer_id: string | null
          session_token: string
          branch_id: string
          tenant_id: string
          agent_id: string | null
          agent_type: string
          status: string
          created_at: string
          updated_at: string
          last_message_at: string | null
          resolved_at: string | null
        }
        Insert: {
          id?: string
          customer_id?: string | null
          session_token: string
          branch_id: string
          tenant_id: string
          agent_id?: string | null
          agent_type?: string
          status?: string
          created_at?: string
          updated_at?: string
          last_message_at?: string | null
          resolved_at?: string | null
        }
        Update: {
          id?: string
          customer_id?: string | null
          session_token?: string
          branch_id?: string
          tenant_id?: string
          agent_id?: string | null
          agent_type?: string
          status?: string
          created_at?: string
          updated_at?: string
          last_message_at?: string | null
          resolved_at?: string | null
        }
        Relationships: []
      }
      
      chat_messages: {
        Row: {
          id: string
          session_id: string
          sender_type: string
          sender_id: string | null
          sender_name: string
          message_type: string
          content: string
          product_id: string | null
          created_at: string
          read_at: string | null
        }
        Insert: {
          id?: string
          session_id: string
          sender_type: string
          sender_id?: string | null
          sender_name: string
          message_type?: string
          content: string
          product_id?: string | null
          created_at?: string
          read_at?: string | null
        }
        Update: {
          id?: string
          session_id?: string
          sender_type?: string
          sender_id?: string | null
          sender_name?: string
          message_type?: string
          content?: string
          product_id?: string | null
          created_at?: string
          read_at?: string | null
        }
        Relationships: []
      }
      
      chat_attachments: {
        Row: {
          id: string
          message_id: string
          session_id: string
          file_type: string
          file_name: string
          file_size: number
          mime_type: string
          storage_bucket: string
          storage_path: string
          storage_url: string
          uploaded_at: string
          uploaded_by: string
        }
        Insert: {
          id?: string
          message_id: string
          session_id: string
          file_type: string
          file_name: string
          file_size: number
          mime_type: string
          storage_bucket?: string
          storage_path: string
          storage_url: string
          uploaded_at?: string
          uploaded_by: string
        }
        Update: {
          id?: string
          message_id?: string
          session_id?: string
          file_type?: string
          file_name?: string
          file_size?: number
          mime_type?: string
          storage_bucket?: string
          storage_path?: string
          storage_url?: string
          uploaded_at?: string
          uploaded_by?: string
        }
        Relationships: []
      }
      
      tenant_branding: {
        Row: {
          id: string
          tenant_id: string
          branch_id: string | null
          business_name: string
          logo_url: string | null
          brand_color: string
          background_color: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          tenant_id: string
          branch_id?: string | null
          business_name: string
          logo_url?: string | null
          brand_color?: string
          background_color?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          tenant_id?: string
          branch_id?: string | null
          business_name?: string
          logo_url?: string | null
          brand_color?: string
          background_color?: string
          created_at?: string
          updated_at?: string
        }
        Relationships: []
      }
    }
    
    Views: {
      storefront_products_with_catalog: {
        Row: {
          id: string
          tenant_id: string
          branch_id: string
          catalog_product_id: string | null
          name: string | null
          description: string | null
          images: string[] | null
          primary_image: string | null
          category: string | null
          brand: string | null
          barcode: string | null
          business_type: string | null
          specifications: Json | null
          sku: string
          price: number
          compare_at_price: number | null
          cost_price: number | null
          stock_quantity: number
          low_stock_threshold: number
          is_available: boolean
          has_variants: boolean
          created_at: string
          updated_at: string
          synced_at: string
        }
        Relationships: []
      }
    }
    
    Functions: {
      calculate_storefront_order_total: {
        Args: { p_subtotal: number; p_delivery_base_fee: number }
        Returns: number
      }
      generate_storefront_order_number: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      search_global_catalog: {
        Args: {
          p_business_type: string
          p_search_query?: string
          p_category?: string
          p_verified_only?: boolean
        }
        Returns: {
          id: string
          name: string
          description: string
          category: string
          brand: string
          barcode: string
          primary_image: string
          specifications: Json
          is_verified: boolean
        }[]
      }
      search_catalog_for_tenant: {
        Args: {
          p_tenant_id: string
          p_search_query?: string
          p_category?: string
          p_verified_only?: boolean
        }
        Returns: {
          id: string
          name: string
          description: string
          category: string
          brand: string
          barcode: string
          primary_image: string
          specifications: Json
          is_verified: boolean
          already_in_inventory: boolean
        }[]
      }
    }
    
    Enums: {
      business_type: 'pharmacy' | 'grocery' | 'fashion' | 'restaurant' | 'electronics' | 'beauty' | 'hardware' | 'bookstore' | 'general'
      payment_status: 'pending' | 'paid' | 'failed' | 'refunded'
      order_status: 'pending' | 'confirmed' | 'preparing' | 'ready' | 'dispatched' | 'delivered' | 'cancelled'
      delivery_method: 'self_pickup' | 'bicycle' | 'motorbike' | 'platform'
      chat_status: 'active' | 'resolved' | 'abandoned'
      agent_type: 'live' | 'ai' | 'owner'
      sender_type: 'customer' | 'agent' | 'ai'
      message_type: 'text' | 'image' | 'voice' | 'pdf' | 'product_card'
      file_type: 'image' | 'voice' | 'pdf'
      plan_tier: 'free' | 'basic' | 'pro' | 'enterprise' | 'enterprise_custom'
    }
    
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type PublicSchema = Database[Extract<keyof Database, "public">]

export type Tables<
  PublicTableNameOrOptions extends
    | keyof (PublicSchema["Tables"] & PublicSchema["Views"])
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
        Database[PublicTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? (Database[PublicTableNameOrOptions["schema"]]["Tables"] &
      Database[PublicTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : PublicTableNameOrOptions extends keyof (PublicSchema["Tables"] &
        PublicSchema["Views"])
    ? (PublicSchema["Tables"] &
        PublicSchema["Views"])[PublicTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  PublicTableNameOrOptions extends
    | keyof PublicSchema["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : PublicTableNameOrOptions extends keyof PublicSchema["Tables"]
    ? PublicSchema["Tables"][PublicTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  PublicTableNameOrOptions extends
    | keyof PublicSchema["Tables"]
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : PublicTableNameOrOptions extends keyof PublicSchema["Tables"]
    ? PublicSchema["Tables"][PublicTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  PublicEnumNameOrOptions extends
    | keyof PublicSchema["Enums"]
    | { schema: keyof Database },
  EnumName extends PublicEnumNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = PublicEnumNameOrOptions extends { schema: keyof Database }
  ? Database[PublicEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : PublicEnumNameOrOptions extends keyof PublicSchema["Enums"]
    ? PublicSchema["Enums"][PublicEnumNameOrOptions]
    : never

// Convenience type exports for common usage
export type StorefrontCustomer = Tables<'storefront_customers'>
export type StorefrontProduct = Tables<'storefront_products'>
export type StorefrontProductWithCatalog = Tables<'storefront_products_with_catalog'>
export type ProductVariant = Tables<'product_variants'>
export type ShoppingCart = Tables<'shopping_carts'>
export type CartItem = Tables<'cart_items'>
export type StorefrontOrder = Tables<'storefront_orders'>
export type StorefrontOrderItem = Tables<'storefront_order_items'>
export type PaymentTransaction = Tables<'payment_transactions'>
export type ChatSession = Tables<'chat_sessions'>
export type ChatMessage = Tables<'chat_messages'>
export type ChatAttachment = Tables<'chat_attachments'>
export type TenantBranding = Tables<'tenant_branding'>
export type GlobalProductCatalog = Tables<'global_product_catalog'>

// Insert types
export type StorefrontCustomerInsert = TablesInsert<'storefront_customers'>
export type StorefrontProductInsert = TablesInsert<'storefront_products'>
export type ProductVariantInsert = TablesInsert<'product_variants'>
export type ShoppingCartInsert = TablesInsert<'shopping_carts'>
export type CartItemInsert = TablesInsert<'cart_items'>
export type StorefrontOrderInsert = TablesInsert<'storefront_orders'>
export type StorefrontOrderItemInsert = TablesInsert<'storefront_order_items'>
export type PaymentTransactionInsert = TablesInsert<'payment_transactions'>
export type ChatSessionInsert = TablesInsert<'chat_sessions'>
export type ChatMessageInsert = TablesInsert<'chat_messages'>
export type ChatAttachmentInsert = TablesInsert<'chat_attachments'>
export type TenantBrandingInsert = TablesInsert<'tenant_branding'>

// Update types
export type StorefrontCustomerUpdate = TablesUpdate<'storefront_customers'>
export type StorefrontProductUpdate = TablesUpdate<'storefront_products'>
export type ProductVariantUpdate = TablesUpdate<'product_variants'>
export type ShoppingCartUpdate = TablesUpdate<'shopping_carts'>
export type CartItemUpdate = TablesUpdate<'cart_items'>
export type StorefrontOrderUpdate = TablesUpdate<'storefront_orders'>
export type StorefrontOrderItemUpdate = TablesUpdate<'storefront_order_items'>
export type PaymentTransactionUpdate = TablesUpdate<'payment_transactions'>
export type ChatSessionUpdate = TablesUpdate<'chat_sessions'>
export type ChatMessageUpdate = TablesUpdate<'chat_messages'>
export type ChatAttachmentUpdate = TablesUpdate<'chat_attachments'>
export type TenantBrandingUpdate = TablesUpdate<'tenant_branding'>

// Enum exports
export type BusinessType = Enums<'business_type'>
export type PaymentStatus = Enums<'payment_status'>
export type OrderStatus = Enums<'order_status'>
export type DeliveryMethod = Enums<'delivery_method'>
export type ChatStatus = Enums<'chat_status'>
export type AgentType = Enums<'agent_type'>
export type SenderType = Enums<'sender_type'>
export type MessageType = Enums<'message_type'>
export type FileType = Enums<'file_type'>
export type PlanTier = Enums<'plan_tier'>
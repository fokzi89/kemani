// Customer Management Service
// Feature: 001-multi-tenant-pos (User Story 3)
// Handles customer CRUD operations, authentication, and profile management

import type { SupabaseClient } from '@supabase/supabase-js';
import type {
  Customer,
  CustomerInsert,
  CustomerUpdate,
  CustomerWithStats,
  CustomerAddress,
  CustomerAddressInsert,
  CustomerAddressUpdate,
  CustomerRegistrationRequest,
  AddAddressRequest
} from '../types/ecommerce';

export class CustomerService {
  constructor(private supabase: SupabaseClient) {}

  /**
   * Register a new customer
   */
  async registerCustomer(
    data: CustomerRegistrationRequest,
    tenantId: string
  ): Promise<{ customer: Customer; error?: string }> {
    try {
      const customerData: CustomerInsert = {
        tenant_id: tenantId,
        full_name: data.full_name,
        email: data.email,
        phone: data.phone,
        loyalty_points: 0,
        total_spent: 0
      };

      const { data: customer, error } = await this.supabase
        .from('customers')
        .insert(customerData)
        .select()
        .single();

      if (error) {
        return { customer: null as any, error: error.message };
      }

      return { customer };
    } catch (error: any) {
      return {
        customer: null as any,
        error: error.message || 'Failed to register customer'
      };
    }
  }

  /**
   * Get customer by ID
   */
  async getCustomer(customerId: string): Promise<{ customer?: Customer; error?: string }> {
    try {
      const { data: customer, error } = await this.supabase
        .from('customers')
        .select('*')
        .eq('id', customerId)
        .single();

      if (error) {
        return { error: error.message };
      }

      return { customer };
    } catch (error: any) {
      return { error: error.message || 'Failed to fetch customer' };
    }
  }

  /**
   * Get customer by phone
   */
  async getCustomerByPhone(
    phone: string,
    tenantId: string
  ): Promise<{ customer?: Customer; error?: string }> {
    try {
      const { data: customer, error } = await this.supabase
        .from('customers')
        .select('*')
        .eq('phone', phone)
        .eq('tenant_id', tenantId)
        .single();

      if (error) {
        return { error: error.message };
      }

      return { customer };
    } catch (error: any) {
      return { error: error.message || 'Failed to fetch customer' };
    }
  }

  /**
   * Get customer by email
   */
  async getCustomerByEmail(
    email: string,
    tenantId: string
  ): Promise<{ customer?: Customer; error?: string }> {
    try {
      const { data: customer, error } = await this.supabase
        .from('customers')
        .select('*')
        .eq('email', email)
        .eq('tenant_id', tenantId)
        .single();

      if (error) {
        return { error: error.message };
      }

      return { customer };
    } catch (error: any) {
      return { error: error.message || 'Failed to fetch customer' };
    }
  }

  /**
   * Update customer profile
   */
  async updateCustomer(
    customerId: string,
    updates: CustomerUpdate
  ): Promise<{ customer?: Customer; error?: string }> {
    try {
      const { data: customer, error } = await this.supabase
        .from('customers')
        .update(updates)
        .eq('id', customerId)
        .select()
        .single();

      if (error) {
        return { error: error.message };
      }

      return { customer };
    } catch (error: any) {
      return { error: error.message || 'Failed to update customer' };
    }
  }

  /**
   * Get customer with stats (total orders, total spent, etc.)
   */
  async getCustomerWithStats(customerId: string): Promise<{
    customer?: CustomerWithStats;
    error?: string;
  }> {
    try {
      // Get customer
      const { data: customer, error: customerError } = await this.supabase
        .from('customers')
        .select('*')
        .eq('id', customerId)
        .single();

      if (customerError) {
        return { error: customerError.message };
      }

      // Get order stats
      const { data: stats, error: statsError } = await this.supabase
        .from('orders')
        .select('total_amount, created_at')
        .eq('customer_id', customerId)
        .eq('status', 'delivered');

      if (statsError) {
        return { error: statsError.message };
      }

      // Get addresses
      const { data: addresses } = await this.supabase
        .from('customer_addresses')
        .select('*')
        .eq('customer_id', customerId);

      const customerWithStats: CustomerWithStats = {
        ...customer,
        total_orders: stats?.length || 0,
        total_spent: stats?.reduce((sum, order) => sum + (order.total_amount || 0), 0) || 0,
        last_order_date: stats && stats.length > 0 ? stats[0].created_at : undefined,
        addresses: addresses || []
      };

      return { customer: customerWithStats };
    } catch (error: any) {
      return { error: error.message || 'Failed to fetch customer with stats' };
    }
  }

  /**
   * Search customers (for merchant use)
   */
  async searchCustomers(
    tenantId: string,
    query: string,
    limit = 20
  ): Promise<{ customers: Customer[]; error?: string }> {
    try {
      const { data: customers, error } = await this.supabase
        .from('customers')
        .select('*')
        .eq('tenant_id', tenantId)
        .or(`full_name.ilike.%${query}%,email.ilike.%${query}%,phone.ilike.%${query}%`)
        .limit(limit);

      if (error) {
        return { customers: [], error: error.message };
      }

      return { customers: customers || [] };
    } catch (error: any) {
      return { customers: [], error: error.message || 'Failed to search customers' };
    }
  }

  /**
   * List all customers for a tenant (for merchant use)
   */
  async listCustomers(
    tenantId: string,
    page = 1,
    limit = 50
  ): Promise<{ customers: Customer[]; total: number; error?: string }> {
    try {
      const offset = (page - 1) * limit;

      const { data: customers, error, count } = await this.supabase
        .from('customers')
        .select('*', { count: 'exact' })
        .eq('tenant_id', tenantId)
        .order('created_at', { ascending: false })
        .range(offset, offset + limit - 1);

      if (error) {
        return { customers: [], total: 0, error: error.message };
      }

      return { customers: customers || [], total: count || 0 };
    } catch (error: any) {
      return { customers: [], total: 0, error: error.message || 'Failed to list customers' };
    }
  }

  // ============================================================================
  // Address Management
  // ============================================================================

  /**
   * Add customer address
   */
  async addAddress(
    customerId: string,
    addressData: AddAddressRequest
  ): Promise<{ address?: CustomerAddress; error?: string }> {
    try {
      // If this is set as default, unset all other default addresses
      if (addressData.is_default) {
        await this.supabase
          .from('customer_addresses')
          .update({ is_default: false })
          .eq('customer_id', customerId);
      }

      const insertData: CustomerAddressInsert = {
        customer_id: customerId,
        ...addressData
      };

      const { data: address, error } = await this.supabase
        .from('customer_addresses')
        .insert(insertData)
        .select()
        .single();

      if (error) {
        return { error: error.message };
      }

      return { address };
    } catch (error: any) {
      return { error: error.message || 'Failed to add address' };
    }
  }

  /**
   * Get customer addresses
   */
  async getAddresses(customerId: string): Promise<{
    addresses: CustomerAddress[];
    error?: string;
  }> {
    try {
      const { data: addresses, error } = await this.supabase
        .from('customer_addresses')
        .select('*')
        .eq('customer_id', customerId)
        .order('is_default', { ascending: false });

      if (error) {
        return { addresses: [], error: error.message };
      }

      return { addresses: addresses || [] };
    } catch (error: any) {
      return { addresses: [], error: error.message || 'Failed to fetch addresses' };
    }
  }

  /**
   * Update customer address
   */
  async updateAddress(
    addressId: string,
    customerId: string,
    updates: CustomerAddressUpdate
  ): Promise<{ address?: CustomerAddress; error?: string }> {
    try {
      // If setting as default, unset all other default addresses
      if (updates.is_default) {
        await this.supabase
          .from('customer_addresses')
          .update({ is_default: false })
          .eq('customer_id', customerId);
      }

      const { data: address, error } = await this.supabase
        .from('customer_addresses')
        .update(updates)
        .eq('id', addressId)
        .eq('customer_id', customerId)
        .select()
        .single();

      if (error) {
        return { error: error.message };
      }

      return { address };
    } catch (error: any) {
      return { error: error.message || 'Failed to update address' };
    }
  }

  /**
   * Delete customer address
   */
  async deleteAddress(
    addressId: string,
    customerId: string
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const { error } = await this.supabase
        .from('customer_addresses')
        .delete()
        .eq('id', addressId)
        .eq('customer_id', customerId);

      if (error) {
        return { success: false, error: error.message };
      }

      return { success: true };
    } catch (error: any) {
      return { success: false, error: error.message || 'Failed to delete address' };
    }
  }

  /**
   * Get default address
   */
  async getDefaultAddress(customerId: string): Promise<{
    address?: CustomerAddress;
    error?: string;
  }> {
    try {
      const { data: address, error } = await this.supabase
        .from('customer_addresses')
        .select('*')
        .eq('customer_id', customerId)
        .eq('is_default', true)
        .single();

      if (error) {
        return { error: error.message };
      }

      return { address };
    } catch (error: any) {
      return { error: error.message || 'Failed to fetch default address' };
    }
  }
}

import type { SupabaseClient } from '@supabase/supabase-js';
import type { 
  Database, 
  StorefrontProduct, 
  StorefrontProductWithCatalog,
  StorefrontCustomer,
  ShoppingCart,
  CartItem,
  StorefrontOrder,
  StorefrontOrderItem
} from '$lib/types/supabase.js';
import { createPlanEnforcementService, withPlanEnforcement } from './plan-enforcement.js';

export class DatabaseService {
  constructor(private supabase: SupabaseClient<Database>) {}

  // Products
  async getProducts(branchId: string, limit = 20, offset = 0) {
    return this.supabase
      .from('storefront_products_with_catalog')
      .select('*')
      .eq('branch_id', branchId)
      .eq('is_available', true)
      .range(offset, offset + limit - 1)
      .order('name');
  }

  async getProduct(id: string) {
    return this.supabase
      .from('storefront_products_with_catalog')
      .select('*')
      .eq('id', id)
      .eq('is_available', true)
      .single();
  }

  async searchProducts(branchId: string, query: string, category?: string) {
    let queryBuilder = this.supabase
      .from('storefront_products_with_catalog')
      .select('*')
      .eq('branch_id', branchId)
      .eq('is_available', true);

    if (category) {
      queryBuilder = queryBuilder.eq('category', category);
    }

    if (query) {
      queryBuilder = queryBuilder.textSearch('name', query);
    }

    return queryBuilder.order('name');
  }

  /**
   * Enhanced product search with filters (T029)
   */
  async searchProductsWithFilters(
    branchId: string,
    filters: {
      query?: string;
      category?: string;
      minPrice?: number;
      maxPrice?: number;
      sortBy?: 'name' | 'price' | 'created_at';
      sortOrder?: 'asc' | 'desc';
      limit?: number;
      offset?: number;
    } = {}
  ) {
    const {
      query,
      category,
      minPrice,
      maxPrice,
      sortBy = 'name',
      sortOrder = 'asc',
      limit = 20,
      offset = 0
    } = filters;

    let queryBuilder = this.supabase
      .from('storefront_products_with_catalog')
      .select('*')
      .eq('branch_id', branchId)
      .eq('is_available', true);

    // Category filter
    if (category) {
      queryBuilder = queryBuilder.eq('category', category);
    }

    // Price range filter
    if (minPrice !== undefined) {
      queryBuilder = queryBuilder.gte('price', minPrice);
    }
    if (maxPrice !== undefined) {
      queryBuilder = queryBuilder.lte('price', maxPrice);
    }

    // Text search
    if (query && query.trim()) {
      // Use full-text search if available, otherwise use ilike
      queryBuilder = queryBuilder.or(`name.ilike.%${query}%,description.ilike.%${query}%,brand.ilike.%${query}%`);
    }

    // Sorting
    queryBuilder = queryBuilder.order(sortBy, { ascending: sortOrder === 'asc' });

    // Pagination
    queryBuilder = queryBuilder.range(offset, offset + limit - 1);

    return queryBuilder;
  }

  /**
   * Get available categories for a branch
   */
  async getCategories(branchId: string) {
    const { data, error } = await this.supabase
      .from('storefront_products_with_catalog')
      .select('category')
      .eq('branch_id', branchId)
      .eq('is_available', true)
      .not('category', 'is', null);

    if (error) throw error;

    // Get unique categories
    const categories = [...new Set(data?.map(item => item.category).filter(Boolean))];
    return { data: categories.sort(), error: null };
  }

  /**
   * Get price range for products in a branch
   */
  async getPriceRange(branchId: string, category?: string) {
    let queryBuilder = this.supabase
      .from('storefront_products_with_catalog')
      .select('price')
      .eq('branch_id', branchId)
      .eq('is_available', true);

    if (category) {
      queryBuilder = queryBuilder.eq('category', category);
    }

    const { data, error } = await queryBuilder;

    if (error) throw error;

    if (!data || data.length === 0) {
      return { data: { min: 0, max: 0 }, error: null };
    }

    const prices = data.map(item => item.price).filter(price => price !== null);
    const min = Math.min(...prices);
    const max = Math.max(...prices);

    return { data: { min, max }, error: null };
  }

  /**
   * Multi-branch product search (Business Plan only - T031)
   */
  async searchProductsMultiBranch(
    tenantId: string,
    filters: {
      query?: string;
      category?: string;
      minPrice?: number;
      maxPrice?: number;
      branchIds?: string[];
      sortBy?: 'name' | 'price' | 'created_at';
      sortOrder?: 'asc' | 'desc';
      limit?: number;
      offset?: number;
    } = {}
  ) {
    const {
      query,
      category,
      minPrice,
      maxPrice,
      branchIds,
      sortBy = 'name',
      sortOrder = 'asc',
      limit = 20,
      offset = 0
    } = filters;

    let queryBuilder = this.supabase
      .from('storefront_products_with_catalog')
      .select('*')
      .eq('tenant_id', tenantId)
      .eq('is_available', true);

    // Branch filter
    if (branchIds && branchIds.length > 0) {
      queryBuilder = queryBuilder.in('branch_id', branchIds);
    }

    // Category filter
    if (category) {
      queryBuilder = queryBuilder.eq('category', category);
    }

    // Price range filter
    if (minPrice !== undefined) {
      queryBuilder = queryBuilder.gte('price', minPrice);
    }
    if (maxPrice !== undefined) {
      queryBuilder = queryBuilder.lte('price', maxPrice);
    }

    // Text search
    if (query && query.trim()) {
      queryBuilder = queryBuilder.or(`name.ilike.%${query}%,description.ilike.%${query}%,brand.ilike.%${query}%`);
    }

    // Sorting
    queryBuilder = queryBuilder.order(sortBy, { ascending: sortOrder === 'asc' });

    // Pagination
    queryBuilder = queryBuilder.range(offset, offset + limit - 1);

    return queryBuilder;
  }

  /**
   * Add product with plan enforcement (T010a)
   */
  async addProduct(tenantId: string, productData: any, planTier?: any) {
    return withPlanEnforcement(
      this.supabase,
      tenantId,
      'add_product',
      async () => {
        return this.supabase
          .from('storefront_products')
          .insert(productData)
          .select()
          .single();
      },
      planTier
    );
  }

  // Cart operations
  async getCart(sessionId: string, branchId: string) {
    return this.supabase
      .from('shopping_carts')
      .select(`
        *,
        cart_items (
          *,
          storefront_products_with_catalog (*)
        )
      `)
      .eq('session_id', sessionId)
      .eq('branch_id', branchId)
      .single();
  }

  async createCart(sessionId: string, branchId: string, tenantId: string) {
    return this.supabase
      .from('shopping_carts')
      .insert({
        session_id: sessionId,
        branch_id: branchId,
        tenant_id: tenantId
      })
      .select()
      .single();
  }

  async addToCart(cartId: string, productId: string, quantity: number, unitPrice: number, variantId?: string) {
    return this.supabase
      .from('cart_items')
      .upsert({
        cart_id: cartId,
        product_id: productId,
        variant_id: variantId,
        quantity,
        unit_price: unitPrice
      }, {
        onConflict: 'cart_id,product_id,variant_id'
      })
      .select();
  }

  async updateCartItem(cartItemId: string, quantity: number) {
    return this.supabase
      .from('cart_items')
      .update({ quantity })
      .eq('id', cartItemId)
      .select();
  }

  async removeFromCart(cartItemId: string) {
    return this.supabase
      .from('cart_items')
      .delete()
      .eq('id', cartItemId);
  }

  // Customer operations
  async getCustomer(userId: string) {
    return this.supabase
      .from('storefront_customers')
      .select('*')
      .eq('user_id', userId)
      .single();
  }

  async createCustomer(data: {
    user_id?: string;
    email?: string;
    phone: string;
    name: string;
    delivery_address?: any;
  }) {
    return this.supabase
      .from('storefront_customers')
      .insert(data)
      .select()
      .single();
  }

  async updateCustomer(customerId: string, data: Partial<StorefrontCustomer>) {
    return this.supabase
      .from('storefront_customers')
      .update(data)
      .eq('id', customerId)
      .select()
      .single();
  }

  // Order operations
  async createOrder(orderData: any) {
    return this.supabase
      .from('storefront_orders')
      .insert(orderData)
      .select()
      .single();
  }

  async createOrderItems(orderItems: any[]) {
    return this.supabase
      .from('storefront_order_items')
      .insert(orderItems)
      .select();
  }

  async getOrder(orderId: string) {
    return this.supabase
      .from('storefront_orders')
      .select(`
        *,
        storefront_order_items (
          *,
          storefront_products_with_catalog (*)
        ),
        storefront_customers (*)
      `)
      .eq('id', orderId)
      .single();
  }

  async getCustomerOrders(customerId: string) {
    return this.supabase
      .from('storefront_orders')
      .select(`
        *,
        storefront_order_items (*)
      `)
      .eq('customer_id', customerId)
      .order('created_at', { ascending: false });
  }

  async updateOrderStatus(orderId: string, status: string) {
    return this.supabase
      .from('storefront_orders')
      .update({ order_status: status })
      .eq('id', orderId)
      .select()
      .single();
  }

  // Plan enforcement utilities
  async getPlanEnforcementService(tenantId: string, planTier?: any) {
    return createPlanEnforcementService(this.supabase, tenantId, planTier);
  }

  async checkProductLimit(tenantId: string, planTier?: any) {
    const service = await this.getPlanEnforcementService(tenantId, planTier);
    return service.canAddProduct();
  }

  async checkStaffLimit(tenantId: string, currentStaffCount?: number, planTier?: any) {
    const service = await this.getPlanEnforcementService(tenantId, planTier);
    return service.canAddStaff(currentStaffCount);
  }

  async getPlanStatus(tenantId: string, externalUsage?: any, planTier?: any) {
    const service = await this.getPlanEnforcementService(tenantId, planTier);
    return service.getPlanStatus(externalUsage);
  }

  // Utility functions
  async generateOrderNumber() {
    const { data, error } = await this.supabase.rpc('generate_storefront_order_number');
    if (error) throw error;
    return data;
  }

  async calculateOrderTotal(subtotal: number, deliveryBaseFee: number) {
    const { data, error } = await this.supabase.rpc('calculate_storefront_order_total', {
      p_subtotal: subtotal,
      p_delivery_base_fee: deliveryBaseFee
    });
    if (error) throw error;
    return data;
  }
}
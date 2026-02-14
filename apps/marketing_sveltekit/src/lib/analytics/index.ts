/**
 * Analytics Service
 * Provides reusable functions for sales analytics queries
 */

import { createClient } from '@/lib/supabase/server';

export type DateRange = {
  start: string; // YYYY-MM-DD
  end: string; // YYYY-MM-DD
};

export type PeriodType = 'day' | 'week' | 'month' | 'quarter' | 'year';

export type ComparisonPeriod = {
  current: DateRange;
  previous: DateRange;
};

// ============================================
// PRODUCT ANALYTICS
// ============================================

/**
 * Get sales history for a specific product
 */
export async function getProductSalesHistory(
  tenantId: string,
  productId: string,
  dateRange: DateRange,
  branchId?: string
) {
  const supabase = await createClient();

  let query = supabase
    .from('fact_product_sales')
    .select(`
      *,
      dim_date:date_key (
        date_value,
        day_of_week_name,
        week_of_year,
        month_name,
        quarter_name
      )
    `)
    .eq('tenant_id', tenantId)
    .eq('product_id', productId)
    .gte('sale_date', dateRange.start)
    .lte('sale_date', dateRange.end)
    .order('sale_date', { ascending: false });

  if (branchId) {
    query = query.eq('branch_id', branchId);
  }

  const { data, error } = await query;

  if (error) throw error;

  return data;
}

/**
 * Get top selling products
 */
export async function getTopProducts(
  tenantId: string,
  dateRange: DateRange,
  limit: number = 10,
  branchId?: string,
  orderBy: 'revenue' | 'quantity' | 'profit' = 'revenue'
) {
  const supabase = await createClient();

  let query = supabase
    .from('fact_product_sales')
    .select(`
      product_id,
      product_name,
      brand_name,
      category_name,
      quantity_sold,
      total_revenue,
      total_profit,
      average_profit_margin,
      transaction_count
    `)
    .eq('tenant_id', tenantId)
    .gte('sale_date', dateRange.start)
    .lte('sale_date', dateRange.end);

  if (branchId) {
    query = query.eq('branch_id', branchId);
  }

  const orderByColumn = orderBy === 'revenue' ? 'total_revenue' :
                        orderBy === 'quantity' ? 'quantity_sold' :
                        'total_profit';

  query = query.order(orderByColumn as string, { ascending: false }).limit(limit);

  const { data, error } = await query;

  if (error) throw error;

  return data;
}

/**
 * Get slow-moving products (low turnover)
 */
export async function getSlowMovingProducts(
  tenantId: string,
  dateRange: DateRange,
  limit: number = 20,
  branchId?: string
) {
  const supabase = await createClient();

  let query = supabase
    .from('fact_product_sales')
    .select(`
      product_id,
      product_name,
      brand_name,
      category_name,
      quantity_sold,
      total_revenue,
      transaction_count
    `)
    .eq('tenant_id', tenantId)
    .gte('sale_date', dateRange.start)
    .lte('sale_date', dateRange.end)
    .order('quantity_sold', { ascending: true })
    .limit(limit);

  if (branchId) {
    query = query.eq('branch_id', branchId);
  }

  const { data, error } = await query;

  if (error) throw error;

  return data;
}

// ============================================
// BRAND ANALYTICS
// ============================================

/**
 * Compare brands performance
 */
export async function compareBrands(
  tenantId: string,
  dateRange: DateRange,
  brandIds?: string[],
  branchId?: string
) {
  const supabase = await createClient();

  let query = supabase
    .from('fact_brand_sales')
    .select(`
      brand_id,
      brand_name,
      category_name,
      unique_products_sold,
      quantity_sold,
      total_revenue,
      total_profit,
      average_profit_margin,
      transaction_count
    `)
    .eq('tenant_id', tenantId)
    .gte('sale_date', dateRange.start)
    .lte('sale_date', dateRange.end);

  if (brandIds && brandIds.length > 0) {
    query = query.in('brand_id', brandIds);
  }

  if (branchId) {
    query = query.eq('branch_id', branchId);
  }

  query = query.order('total_revenue', { ascending: false });

  const { data, error } = await query;

  if (error) throw error;

  // Aggregate by brand (sum across dates)
  const brandMap = new Map();

  data?.forEach((row: any) => {
    const key = row.brand_id;
    if (!brandMap.has(key)) {
      brandMap.set(key, {
        brand_id: row.brand_id,
        brand_name: row.brand_name,
        unique_products_sold: 0,
        quantity_sold: 0,
        total_revenue: 0,
        total_profit: 0,
        transaction_count: 0,
        categories: new Set(),
      });
    }

    const brand = brandMap.get(key);
    brand.unique_products_sold += row.unique_products_sold || 0;
    brand.quantity_sold += parseFloat(row.quantity_sold) || 0;
    brand.total_revenue += parseFloat(row.total_revenue) || 0;
    brand.total_profit += parseFloat(row.total_profit) || 0;
    brand.transaction_count += row.transaction_count || 0;
    if (row.category_name) brand.categories.add(row.category_name);
  });

  return Array.from(brandMap.values()).map(brand => ({
    ...brand,
    category_count: brand.categories.size,
    average_profit_margin: brand.total_revenue > 0
      ? (brand.total_profit / brand.total_revenue) * 100
      : 0,
  }));
}

/**
 * Compare same product across different brands
 */
export async function compareProductAcrossBrands(
  tenantId: string,
  categoryId: string,
  dateRange: DateRange,
  branchId?: string
) {
  const supabase = await createClient();

  let query = supabase
    .from('fact_product_sales')
    .select(`
      product_id,
      product_name,
      brand_id,
      brand_name,
      quantity_sold,
      total_revenue,
      total_profit,
      average_unit_price,
      average_profit_margin,
      transaction_count
    `)
    .eq('tenant_id', tenantId)
    .eq('category_id', categoryId)
    .gte('sale_date', dateRange.start)
    .lte('sale_date', dateRange.end);

  if (branchId) {
    query = query.eq('branch_id', branchId);
  }

  query = query.order('total_revenue', { ascending: false });

  const { data, error } = await query;

  if (error) throw error;

  // Aggregate by product
  const productMap = new Map();

  data?.forEach((row: any) => {
    const key = `${row.product_id}-${row.brand_id}`;
    if (!productMap.has(key)) {
      productMap.set(key, {
        product_id: row.product_id,
        product_name: row.product_name,
        brand_id: row.brand_id,
        brand_name: row.brand_name,
        quantity_sold: 0,
        total_revenue: 0,
        total_profit: 0,
        transaction_count: 0,
        average_unit_price: 0,
      });
    }

    const product = productMap.get(key);
    product.quantity_sold += parseFloat(row.quantity_sold) || 0;
    product.total_revenue += parseFloat(row.total_revenue) || 0;
    product.total_profit += parseFloat(row.total_profit) || 0;
    product.transaction_count += row.transaction_count || 0;
  });

  return Array.from(productMap.values()).map(product => ({
    ...product,
    average_unit_price: product.quantity_sold > 0
      ? product.total_revenue / product.quantity_sold
      : 0,
    average_profit_margin: product.total_revenue > 0
      ? (product.total_profit / product.total_revenue) * 100
      : 0,
  }));
}

// ============================================
// STAFF ANALYTICS
// ============================================

/**
 * Get staff performance metrics
 */
export async function getStaffPerformance(
  tenantId: string,
  dateRange: DateRange,
  branchId?: string,
  staffRole?: 'cashier' | 'sales_attendant'
) {
  const supabase = await createClient();

  let query = supabase
    .from('fact_staff_sales')
    .select(`
      staff_id,
      staff_name,
      staff_role,
      total_transactions,
      total_items_sold,
      total_revenue,
      total_profit,
      average_transaction_value,
      commission_amount
    `)
    .eq('tenant_id', tenantId)
    .gte('sale_date', dateRange.start)
    .lte('sale_date', dateRange.end);

  if (branchId) {
    query = query.eq('branch_id', branchId);
  }

  if (staffRole) {
    query = query.eq('staff_role', staffRole);
  }

  query = query.order('total_revenue', { ascending: false });

  const { data, error } = await query;

  if (error) throw error;

  // Aggregate by staff
  const staffMap = new Map();

  data?.forEach((row: any) => {
    const key = `${row.staff_id}-${row.staff_role}`;
    if (!staffMap.has(key)) {
      staffMap.set(key, {
        staff_id: row.staff_id,
        staff_name: row.staff_name,
        staff_role: row.staff_role,
        total_transactions: 0,
        total_items_sold: 0,
        total_revenue: 0,
        total_profit: 0,
        commission_amount: 0,
      });
    }

    const staff = staffMap.get(key);
    staff.total_transactions += row.total_transactions || 0;
    staff.total_items_sold += parseFloat(row.total_items_sold) || 0;
    staff.total_revenue += parseFloat(row.total_revenue) || 0;
    staff.total_profit += parseFloat(row.total_profit) || 0;
    staff.commission_amount += parseFloat(row.commission_amount) || 0;
  });

  return Array.from(staffMap.values()).map(staff => ({
    ...staff,
    average_transaction_value: staff.total_transactions > 0
      ? staff.total_revenue / staff.total_transactions
      : 0,
  }));
}

/**
 * Get staff leaderboard
 */
export async function getStaffLeaderboard(
  tenantId: string,
  dateRange: DateRange,
  limit: number = 10,
  branchId?: string,
  orderBy: 'revenue' | 'transactions' | 'profit' = 'revenue'
) {
  const performance = await getStaffPerformance(tenantId, dateRange, branchId);

  const sorted = performance.sort((a, b) => {
    if (orderBy === 'revenue') return b.total_revenue - a.total_revenue;
    if (orderBy === 'transactions') return b.total_transactions - a.total_transactions;
    return b.total_profit - a.total_profit;
  });

  return sorted.slice(0, limit);
}

// ============================================
// PERIOD COMPARISON ANALYTICS
// ============================================

/**
 * Get period comparison data
 */
export async function comparePeriods(
  tenantId: string,
  currentPeriod: DateRange,
  previousPeriod: DateRange,
  branchId?: string
) {
  const supabase = await createClient();

  // Get current period data
  let currentQuery = supabase
    .from('fact_daily_sales')
    .select('*')
    .eq('tenant_id', tenantId)
    .gte('sale_date', currentPeriod.start)
    .lte('sale_date', currentPeriod.end);

  if (branchId) {
    currentQuery = currentQuery.eq('branch_id', branchId);
  }

  const { data: currentData, error: currentError } = await currentQuery;
  if (currentError) throw currentError;

  // Get previous period data
  let previousQuery = supabase
    .from('fact_daily_sales')
    .select('*')
    .eq('tenant_id', tenantId)
    .gte('sale_date', previousPeriod.start)
    .lte('sale_date', previousPeriod.end);

  if (branchId) {
    previousQuery = previousQuery.eq('branch_id', branchId);
  }

  const { data: previousData, error: previousError } = await previousQuery;
  if (previousError) throw previousError;

  // Aggregate current period
  const current = aggregatePeriodData(currentData || []);
  const previous = aggregatePeriodData(previousData || []);

  // Calculate changes
  return {
    current,
    previous,
    changes: {
      revenue: calculatePercentageChange(previous.total_revenue, current.total_revenue),
      transactions: calculatePercentageChange(previous.total_transactions, current.total_transactions),
      profit: calculatePercentageChange(previous.total_profit, current.total_profit),
      average_transaction_value: calculatePercentageChange(
        previous.average_transaction_value,
        current.average_transaction_value
      ),
    },
  };
}

function aggregatePeriodData(data: any[]) {
  const total_transactions = data.reduce((sum, row) => sum + (row.total_transactions || 0), 0);
  const total_revenue = data.reduce((sum, row) => sum + parseFloat(row.total_revenue || 0), 0);
  const total_profit = data.reduce((sum, row) => sum + parseFloat(row.total_profit || 0), 0);
  const total_cost = data.reduce((sum, row) => sum + parseFloat(row.total_cost || 0), 0);

  return {
    total_transactions,
    total_revenue,
    total_profit,
    total_cost,
    average_transaction_value: total_transactions > 0 ? total_revenue / total_transactions : 0,
    average_profit_margin: total_revenue > 0 ? (total_profit / total_revenue) * 100 : 0,
  };
}

function calculatePercentageChange(oldValue: number, newValue: number): number {
  if (oldValue === 0) return newValue > 0 ? 100 : 0;
  return ((newValue - oldValue) / oldValue) * 100;
}

/**
 * Compare month vs previous month
 */
export async function compareMonthVsPreviousMonth(
  tenantId: string,
  year: number,
  month: number,
  branchId?: string
) {
  const currentStart = new Date(year, month - 1, 1);
  const currentEnd = new Date(year, month, 0);

  const previousStart = new Date(year, month - 2, 1);
  const previousEnd = new Date(year, month - 1, 0);

  return comparePeriods(
    tenantId,
    {
      start: currentStart.toISOString().split('T')[0],
      end: currentEnd.toISOString().split('T')[0],
    },
    {
      start: previousStart.toISOString().split('T')[0],
      end: previousEnd.toISOString().split('T')[0],
    },
    branchId
  );
}

/**
 * Compare quarter vs previous quarter
 */
export async function compareQuarterVsPreviousQuarter(
  tenantId: string,
  year: number,
  quarter: 1 | 2 | 3 | 4,
  branchId?: string
) {
  const currentStart = new Date(year, (quarter - 1) * 3, 1);
  const currentEnd = new Date(year, quarter * 3, 0);

  const previousYear = quarter === 1 ? year - 1 : year;
  const previousQuarter = quarter === 1 ? 4 : quarter - 1;
  const previousStart = new Date(previousYear, (previousQuarter - 1) * 3, 1);
  const previousEnd = new Date(previousYear, previousQuarter * 3, 0);

  return comparePeriods(
    tenantId,
    {
      start: currentStart.toISOString().split('T')[0],
      end: currentEnd.toISOString().split('T')[0],
    },
    {
      start: previousStart.toISOString().split('T')[0],
      end: previousEnd.toISOString().split('T')[0],
    },
    branchId
  );
}

/**
 * Compare year vs previous year
 */
export async function compareYearVsPreviousYear(
  tenantId: string,
  year: number,
  branchId?: string
) {
  const currentStart = new Date(year, 0, 1);
  const currentEnd = new Date(year, 11, 31);

  const previousStart = new Date(year - 1, 0, 1);
  const previousEnd = new Date(year - 1, 11, 31);

  return comparePeriods(
    tenantId,
    {
      start: currentStart.toISOString().split('T')[0],
      end: currentEnd.toISOString().split('T')[0],
    },
    {
      start: previousStart.toISOString().split('T')[0],
      end: previousEnd.toISOString().split('T')[0],
    },
    branchId
  );
}

// ============================================
// CATEGORY ANALYTICS
// ============================================

/**
 * Get category performance
 */
export async function getCategoryPerformance(
  tenantId: string,
  dateRange: DateRange,
  branchId?: string
) {
  const supabase = await createClient();

  let query = supabase
    .from('fact_product_sales')
    .select(`
      category_id,
      category_name,
      product_id,
      quantity_sold,
      total_revenue,
      total_profit,
      transaction_count
    `)
    .eq('tenant_id', tenantId)
    .gte('sale_date', dateRange.start)
    .lte('sale_date', dateRange.end)
    .not('category_id', 'is', null);

  if (branchId) {
    query = query.eq('branch_id', branchId);
  }

  const { data, error } = await query;

  if (error) throw error;

  // Aggregate by category
  const categoryMap = new Map();

  data?.forEach((row: any) => {
    const key = row.category_id;
    if (!categoryMap.has(key)) {
      categoryMap.set(key, {
        category_id: row.category_id,
        category_name: row.category_name,
        unique_products: new Set(),
        quantity_sold: 0,
        total_revenue: 0,
        total_profit: 0,
        transaction_count: 0,
      });
    }

    const category = categoryMap.get(key);
    category.unique_products.add(row.product_id);
    category.quantity_sold += parseFloat(row.quantity_sold) || 0;
    category.total_revenue += parseFloat(row.total_revenue) || 0;
    category.total_profit += parseFloat(row.total_profit) || 0;
    category.transaction_count += row.transaction_count || 0;
  });

  return Array.from(categoryMap.values())
    .map(category => ({
      category_id: category.category_id,
      category_name: category.category_name,
      unique_products: category.unique_products.size,
      quantity_sold: category.quantity_sold,
      total_revenue: category.total_revenue,
      total_profit: category.total_profit,
      transaction_count: category.transaction_count,
      average_profit_margin: category.total_revenue > 0
        ? (category.total_profit / category.total_revenue) * 100
        : 0,
    }))
    .sort((a, b) => b.total_revenue - a.total_revenue);
}

// ============================================
// TIME PATTERN ANALYTICS
// ============================================

/**
 * Get hourly sales pattern
 */
export async function getHourlySalesPattern(
  tenantId: string,
  dateRange: DateRange,
  branchId?: string
) {
  const supabase = await createClient();

  let query = supabase
    .from('fact_hourly_sales')
    .select(`
      hour,
      total_transactions,
      total_revenue,
      average_transaction_value,
      dim_time:time_key (
        time_period,
        is_peak_hour
      )
    `)
    .eq('tenant_id', tenantId)
    .gte('sale_date', dateRange.start)
    .lte('sale_date', dateRange.end);

  if (branchId) {
    query = query.eq('branch_id', branchId);
  }

  const { data, error } = await query;

  if (error) throw error;

  // Aggregate by hour
  const hourMap = new Map();

  data?.forEach((row: any) => {
    const key = row.hour;
    if (!hourMap.has(key)) {
      hourMap.set(key, {
        hour: row.hour,
        total_transactions: 0,
        total_revenue: 0,
        count: 0,
      });
    }

    const hourData = hourMap.get(key);
    hourData.total_transactions += row.total_transactions || 0;
    hourData.total_revenue += parseFloat(row.total_revenue) || 0;
    hourData.count += 1;
  });

  return Array.from(hourMap.values())
    .map(hourData => ({
      hour: hourData.hour,
      average_transactions: hourData.count > 0 ? hourData.total_transactions / hourData.count : 0,
      average_revenue: hourData.count > 0 ? hourData.total_revenue / hourData.count : 0,
      total_transactions: hourData.total_transactions,
      total_revenue: hourData.total_revenue,
    }))
    .sort((a, b) => a.hour - b.hour);
}

/**
 * Get dashboard summary metrics
 */
export async function getDashboardSummary(
  tenantId: string,
  dateRange: DateRange,
  branchId?: string
) {
  const supabase = await createClient();

  let query = supabase
    .from('fact_daily_sales')
    .select('*')
    .eq('tenant_id', tenantId)
    .gte('sale_date', dateRange.start)
    .lte('sale_date', dateRange.end);

  if (branchId) {
    query = query.eq('branch_id', branchId);
  }

  const { data, error } = await query;

  if (error) throw error;

  return aggregatePeriodData(data || []);
}

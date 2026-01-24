import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { createSaleSchema } from '@/lib/validation/schemas';
import {
  formatErrorResponse,
  ValidationError,
  UnauthorizedError,
  ForbiddenError,
  DatabaseError,
  InternalError,
  AppError,
} from '@/lib/utils/errors';

/**
 * POST /api/sales - Create a new sale
 *
 * Creates a sale with items. Database triggers handle:
 * - Generating sale_number
 * - Populating sale_date and sale_time
 * - Updating customer loyalty points
 * - Populating sale_item product snapshots (brand, category, cost, profit)
 */
export async function POST(request: NextRequest) {
  try {
    // 1. Authenticate user
    const supabase = await createClient();
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      throw new UnauthorizedError();
    }

    // 2. Parse and validate request body
    const body = await request.json();
    const validation = createSaleSchema.safeParse(body);

    if (!validation.success) {
      throw new ValidationError('Invalid sale data', {
        errors: validation.error.flatten(),
      });
    }

    const saleData = validation.data;

    // 3. Get user's tenant and verify access
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('tenant_id, branch_id')
      .eq('id', user.id)
      .single();

    if (userError || !userData) {
      throw new ForbiddenError('User data not found');
    }

    // Verify tenant matches
    if (userData.tenant_id !== saleData.tenant_id) {
      throw new ForbiddenError('Tenant mismatch');
    }

    // 4. Create sale record
    const { data: sale, error: saleError } = await supabase
      .from('sales')
      .insert({
        tenant_id: saleData.tenant_id,
        branch_id: saleData.branch_id,
        customer_id: saleData.customer_id,
        customer_type: saleData.customer_type,
        cashier_id: saleData.cashier_id,
        sales_attendant_id: saleData.sales_attendant_id,
        subtotal: saleData.subtotal,
        discount_amount: saleData.discount_amount,
        tax_amount: saleData.tax_amount,
        delivery_fee: saleData.delivery_fee,
        total_amount: saleData.total_amount,
        amount_paid: saleData.amount_paid,
        change_amount: saleData.change_amount,
        payment_method: saleData.payment_method,
        payment_status: saleData.payment_status,
        payment_reference: saleData.payment_reference,
        sale_type: saleData.sale_type,
        channel: saleData.channel,
        sale_status: saleData.sale_status,
        receipt_number: saleData.receipt_number,
        is_synced: true, // Sale created directly in cloud
        completed_at: new Date().toISOString(),
      })
      .select(
        'id, sale_number, total_amount, payment_method, sale_status, completed_at, created_at'
      )
      .single();

    if (saleError) {
      console.error('Sale creation error:', saleError);
      throw new DatabaseError('Failed to create sale', { error: saleError.message });
    }

    // 5. Create sale items (bulk insert)
    const saleItems = saleData.items.map((item) => ({
      sale_id: sale.id,
      tenant_id: saleData.tenant_id,
      product_id: item.product_id,
      quantity: item.quantity,
      unit_price: item.unit_price,
      line_total: item.line_total,
      discount_amount: item.discount_amount,
      tax_amount: item.tax_amount,
    }));

    const { error: itemsError } = await supabase
      .from('sale_items')
      .insert(saleItems);

    if (itemsError) {
      console.error('Sale items creation error:', itemsError);

      // Try to delete the orphaned sale record
      await supabase.from('sales').delete().eq('id', sale.id);

      throw new DatabaseError('Failed to create sale items', {
        error: itemsError.message,
      });
    }

    // 6. Return success response
    return NextResponse.json(
      {
        success: true,
        data: {
          sale_id: sale.id,
          sale_number: sale.sale_number,
          total_amount: sale.total_amount,
          payment_method: sale.payment_method,
          sale_status: sale.sale_status,
          completed_at: sale.completed_at,
          created_at: sale.created_at,
        },
        message: 'Sale created successfully',
      },
      { status: 201 }
    );
  } catch (error) {
    console.error('Sales API error:', error);

    // Handle different error types
    if (error instanceof AppError) {
      return NextResponse.json(formatErrorResponse(error), {
        status: error.statusCode,
      });
    }

    // Unknown error
    const internalError = new InternalError('An unexpected error occurred');
    return NextResponse.json(formatErrorResponse(internalError), {
      status: 500,
    });
  }
}

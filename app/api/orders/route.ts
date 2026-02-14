import { NextRequest, NextResponse } from 'next/server';
import { OrderService } from '@/lib/pos/order';
import { OrderInsert, OrderItemInsert, OrderUpdate, OrderStatus, PaymentStatus } from '@/lib/types/database';
import { createClient } from '@/lib/supabase/client';
import { UserService } from '@/lib/auth/user';

// GET - List orders
export async function GET(request: NextRequest) {
    try {
        const supabase = createClient();
        const { data: { user }, error: authError } = await supabase.auth.getUser();

        if (authError || !user) {
            return NextResponse.json(
                { error: 'Unauthorized' },
                { status: 401 }
            );
        }

        const currentUser = await UserService.getUser(user.id);
        if (!currentUser.tenant_id) {
            return NextResponse.json(
                { error: 'User not associated with a tenant' },
                { status: 403 }
            );
        }

        const { searchParams } = new URL(request.url);
        const orderId = searchParams.get('id');
        const status = searchParams.get('status') as OrderStatus | undefined;
        const customerId = searchParams.get('customerId') || undefined;
        const limit = searchParams.get('limit') ? parseInt(searchParams.get('limit')!) : 20;

        if (orderId) {
            const order = await OrderService.getOrder(orderId);
            if (order.tenant_id !== currentUser.tenant_id) {
                return NextResponse.json(
                    { error: 'Order not found' },
                    { status: 404 }
                );
            }
            return NextResponse.json(order);
        } else {
            const orders = await OrderService.getOrders(currentUser.tenant_id, {
                status,
                customerId,
                limit
            });
            return NextResponse.json({ orders });
        }

    } catch (error: any) {
        console.error('Get orders error:', error);
        return NextResponse.json(
            { error: error.message || 'Failed to get orders' },
            { status: 500 }
        );
    }
}

// POST - Create new order
export async function POST(request: NextRequest) {
    try {
        const supabase = createClient();
        const { data: { user }, error: authError } = await supabase.auth.getUser();

        if (authError || !user) {
            return NextResponse.json(
                { error: 'Unauthorized' },
                { status: 401 }
            );
        }

        const currentUser = await UserService.getUser(user.id);
        if (!currentUser.tenant_id) {
            return NextResponse.json(
                { error: 'User not associated with a tenant' },
                { status: 403 }
            );
        }

        const { order, items }: { order: OrderInsert; items: OrderItemInsert[] } = await request.json();

        // Ensure tenant_id is set
        const newOrderData = {
            ...order,
            tenant_id: currentUser.tenant_id,
            // If not provided, assume created by current user? Or from POS?
            // Typically POS sends cashier_id or we set it?
            // Let's rely on payload but potentially override/ensure consistency
        };

        const createdOrder = await OrderService.createOrder(newOrderData, items);
        return NextResponse.json(createdOrder, { status: 201 });

    } catch (error: any) {
        console.error('Create order error:', error);
        return NextResponse.json(
            { error: error.message || 'Failed to create order' },
            { status: 500 }
        );
    }
}

// PUT - Update order status
export async function PUT(request: NextRequest) {
    try {
        const supabase = createClient();
        const { data: { user }, error: authError } = await supabase.auth.getUser();

        if (authError || !user) {
            return NextResponse.json(
                { error: 'Unauthorized' },
                { status: 401 }
            );
        }

        const { orderId, status, paymentStatus }: {
            orderId: string;
            status: OrderStatus;
            paymentStatus?: PaymentStatus
        } = await request.json();

        if (!orderId || !status) {
            return NextResponse.json(
                { error: 'Order ID and status are required' },
                { status: 400 }
            );
        }

        const updatedOrder = await OrderService.updateStatus(orderId, status, paymentStatus);
        return NextResponse.json(updatedOrder);

    } catch (error: any) {
        console.error('Update order error:', error);
        return NextResponse.json(
            { error: error.message || 'Failed to update order' },
            { status: 500 }
        );
    }
}

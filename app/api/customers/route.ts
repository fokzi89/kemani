import { NextRequest, NextResponse } from 'next/server';
import { CustomerService } from '@/lib/pos/customer';
import { CustomerInsert, CustomerUpdate } from '@/lib/types/database';
import { createClient } from '@/lib/supabase/client';
import { UserService } from '@/lib/auth/user';

// GET - List or search customers
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
        const query = searchParams.get('query');
        const customerId = searchParams.get('id');

        if (customerId) {
            // Get single customer
            const customer = await CustomerService.getCustomer(customerId);
            // Ensure tenant isolation (though RLS should handle, double check)
            if (customer.tenant_id !== currentUser.tenant_id) {
                return NextResponse.json(
                    { error: 'Customer not found' },
                    { status: 404 }
                );
            }
            return NextResponse.json(customer);
        } else if (query) {
            // Search customers
            const customers = await CustomerService.searchCustomers(query, currentUser.tenant_id);
            return NextResponse.json({ customers });
        } else {
            // List recent customers (default search fallback or dedicated method)
            // For now using search with empty string or implemented in service?
            // Service.searchCustomers with empty string might work or we use direct query here.
            // Let's implement a basic list in service or reuse search with a wildcard if supported.
            // For now, let's just use search with empty string which acts as list for standard usage.
            const customers = await CustomerService.searchCustomers('', currentUser.tenant_id);
            return NextResponse.json({ customers });
        }

    } catch (error: any) {
        console.error('Get customers error:', error);
        return NextResponse.json(
            { error: error.message || 'Failed to get customers' },
            { status: 500 }
        );
    }
}

// POST - Create new customer
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

        const customerData: CustomerInsert = await request.json();

        // Ensure tenant_id is set to current user's tenant
        const newCustomerData = {
            ...customerData,
            tenant_id: currentUser.tenant_id
        };

        if (!newCustomerData.full_name) {
            return NextResponse.json(
                { error: 'Full name is required' },
                { status: 400 }
            );
        }

        const customer = await CustomerService.createCustomer(newCustomerData);
        return NextResponse.json(customer, { status: 201 });
    } catch (error: any) {
        console.error('Create customer error:', error);
        return NextResponse.json(
            { error: error.message || 'Failed to create customer' },
            { status: 500 }
        );
    }
}

// PUT - Update customer
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

        const { customerId, updates }: { customerId: string; updates: CustomerUpdate } = await request.json();

        if (!customerId) {
            return NextResponse.json(
                { error: 'Customer ID is required' },
                { status: 400 }
            );
        }

        // Verify ownership via RLS handled by service? 
        // Service respects RLS via client(), so update will fail/return null if not owning.
        // However, good to verify tenant match before attempting if logic requires.
        // Relying on RLS in service for now.

        const updatedCustomer = await CustomerService.updateCustomer(customerId, updates);
        return NextResponse.json(updatedCustomer);

    } catch (error: any) {
        console.error('Update customer error:', error);
        return NextResponse.json(
            { error: error.message || 'Failed to update customer' },
            { status: 500 }
        );
    }
}

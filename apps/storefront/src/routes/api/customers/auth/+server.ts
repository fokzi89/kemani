// Customer Authentication API Endpoint
// POST /api/customers/auth - Authenticate customer with phone/email OTP

import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { createClient } from '@supabase/supabase-js';
import { CustomerService } from '$lib/services/customer';
import type { CustomerAuthRequest, CustomerAuthResponse } from '$lib/types/ecommerce';

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);

export const POST: RequestHandler = async ({ request }) => {
  try {
    const body: CustomerAuthRequest = await request.json();
    const { phone, email, otp_code } = body;

    if (!phone && !email) {
      return json({ error: 'Phone or email is required' }, { status: 400 });
    }

    const customerService = new CustomerService(supabase);

    if (otp_code) {
      // Verify OTP (Step 2)
      // TODO: Implement OTP verification with Supabase Auth or Termii
      // For now, just return mock session

      let customer;
      if (phone) {
        const result = await customerService.getCustomerByPhone(phone, body.tenant_id || '');
        customer = result.customer;
      } else if (email) {
        const result = await customerService.getCustomerByEmail(email, body.tenant_id || '');
        customer = result.customer;
      }

      if (!customer) {
        return json({ error: 'Customer not found' }, { status: 404 });
      }

      // Generate session token (in production, use proper JWT)
      const sessionToken = `session_${customer.id}_${Date.now()}`;
      const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(); // 24 hours

      const response: CustomerAuthResponse = {
        customer_id: customer.id,
        session_token: sessionToken,
        expires_at: expiresAt
      };

      return json(response);
    } else {
      // Send OTP (Step 1)
      // TODO: Implement OTP sending with Termii or Supabase Auth

      return json({
        message: 'OTP sent successfully',
        expires_in: 300 // 5 minutes
      });
    }
  } catch (error: any) {
    return json({ error: error.message || 'Authentication failed' }, { status: 500 });
  }
};

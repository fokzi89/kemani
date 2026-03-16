// Supabase Edge Function: process-referral-payment
// Feature: 004-tenant-referral-commissions
// Handles payment webhooks and commission calculation
// Supports single transactions and multi-item transaction groups (User Story 3)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};

interface PaymentWebhookPayload {
  event: string;
  data: {
    reference: string;
    amount: number;
    currency: string;
    status: string;
    customer: {
      email: string;
      id?: string;
    };
    metadata: {
      // For single transaction
      transaction_id?: string;
      transaction_type?: 'consultation' | 'product_sale' | 'diagnostic_test';
      provider_tenant_id?: string;
      customer_id: string;
      base_price?: number;

      // For transaction groups (multi-service checkout)
      group_id?: string;
    };
  };
}

interface CommissionCalculation {
  customer_pays: number;
  provider_gets: number;
  referrer_gets: number;
  platform_gets: number;
  is_self_provider?: boolean;
  has_referrer?: boolean;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Parse webhook payload
    const payload: PaymentWebhookPayload = await req.json();

    console.log('Received payment webhook:', payload.event);

    // Only process successful payments
    if (payload.event !== 'charge.success' && payload.data.status !== 'success') {
      return new Response(
        JSON.stringify({ message: 'Event ignored - not a successful charge' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200
        }
      );
    }

    const { reference, amount, metadata } = payload.data;
    const { customer_id, group_id, transaction_id } = metadata;

    // Determine if this is a single transaction or a group
    const isGroup = !!group_id;

    if (isGroup) {
      // Process transaction group (multi-service checkout)
      return await processTransactionGroup(supabase, reference, amount, group_id!, customer_id);
    } else if (transaction_id) {
      // Process single transaction (backwards compatibility)
      return await processSingleTransaction(supabase, reference, amount, metadata);
    } else {
      throw new Error('Webhook must include either group_id or transaction_id');
    }
  } catch (error) {
    console.error('Error processing payment webhook:', error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Internal server error',
        details: error
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500
      }
    );
  }
});

/**
 * Process a transaction group (multi-service checkout)
 * User Story 3: Customer purchases multiple services in one session
 */
async function processTransactionGroup(
  supabase: any,
  reference: string,
  totalAmount: number,
  groupId: string,
  customerId: string
) {
  console.log(`Processing transaction group: ${groupId}`);

  // Get all transactions in the group
  const { data: transactions, error: fetchError } = await supabase
    .from('transactions')
    .select('*')
    .eq('group_id', groupId)
    .order('created_at', { ascending: true });

  if (fetchError || !transactions || transactions.length === 0) {
    throw new Error(`Failed to fetch transactions for group ${groupId}: ${fetchError?.message}`);
  }

  console.log(`Found ${transactions.length} transactions in group`);

  // Verify all transactions have the same referring_tenant_id
  const referringTenantIds = new Set(
    transactions.map((t: any) => t.referring_tenant_id).filter((id: any) => id !== null)
  );

  if (referringTenantIds.size > 1) {
    console.warn('Group has inconsistent referrers:', Array.from(referringTenantIds));
    throw new Error('Transaction group has inconsistent referring tenants');
  }

  // Get active referral session for customer
  const { data: sessionData } = await supabase.rpc('get_active_referral_session', {
    p_customer_id: customerId
  });

  const hasReferrer = sessionData && sessionData.length > 0;
  const referringTenantId = hasReferrer ? sessionData[0].referring_tenant_id : null;

  console.log('Group referrer:', referringTenantId);

  // Process each transaction in the group
  const commissionRecords = [];
  let totalCustomerPays = 0;
  let totalReferrerGets = 0;

  for (const transaction of transactions) {
    // Check for existing commission (idempotency)
    const { data: existingCommission } = await supabase
      .from('commissions')
      .select('id')
      .eq('transaction_id', transaction.id)
      .single();

    if (existingCommission) {
      console.log(`Commission already exists for transaction ${transaction.id}`);
      commissionRecords.push(existingCommission.id);
      continue;
    }

    // Calculate commission with self-provider check
    const { data: calcData, error: calcError } = await supabase.rpc(
      'calculate_commission_with_provider_check',
      {
        p_transaction_type: transaction.type,
        p_base_price: transaction.base_price,
        p_provider_tenant_id: transaction.provider_tenant_id,
        p_referring_tenant_id: referringTenantId
      }
    );

    if (calcError || !calcData || calcData.length === 0) {
      throw new Error(`Commission calculation failed for transaction ${transaction.id}: ${calcError?.message}`);
    }

    const calculation = calcData[0];
    const isSelfProvider = calculation.is_self_provider;
    const actualHasReferrer = calculation.has_referrer;

    console.log(`Transaction ${transaction.id} commission:`, {
      ...calculation,
      is_self_provider: isSelfProvider,
      has_referrer: actualHasReferrer
    });

    // Create commission record
    const { data: commissionRecord, error: commissionError } = await supabase.rpc(
      'create_commission_record',
      {
        p_transaction_id: transaction.id,
        p_transaction_type: transaction.type,
        p_provider_tenant_id: transaction.provider_tenant_id,
        p_referrer_tenant_id: referringTenantId,
        p_customer_id: customerId,
        p_base_amount: transaction.base_price,
        p_customer_paid: calculation.customer_pays,
        p_provider_amount: calculation.provider_gets,
        p_referrer_amount: calculation.referrer_gets,
        p_platform_amount: calculation.platform_gets
      }
    );

    if (commissionError) {
      console.error(`Error creating commission for transaction ${transaction.id}:`, commissionError);
      throw commissionError;
    }

    commissionRecords.push(commissionRecord);

    // Update transaction with final price
    await supabase
      .from('transactions')
      .update({
        final_price_paid: calculation.customer_pays
      })
      .eq('id', transaction.id);

    // Accumulate totals
    totalCustomerPays += calculation.customer_pays;
    totalReferrerGets += calculation.referrer_gets;
  }

  // Update all transactions in group to completed
  const { error: updateError } = await supabase
    .from('transactions')
    .update({
      payment_status: 'completed',
      paid_at: new Date().toISOString(),
      payment_reference: reference
    })
    .eq('group_id', groupId)
    .eq('payment_status', 'pending');

  if (updateError) {
    console.error('Error updating transaction group:', updateError);
    // Don't throw - commissions already created
  }

  // Verify total amount matches
  const amountInNaira = totalAmount / 100; // Convert from kobo
  const tolerance = 0.01;

  if (Math.abs(amountInNaira - totalCustomerPays) > tolerance) {
    console.warn(
      `Payment amount mismatch: Expected ${totalCustomerPays}, got ${amountInNaira}`
    );
  }

  console.log(`Group processed: ${commissionRecords.length} commissions created`);

  return new Response(
    JSON.stringify({
      success: true,
      message: 'Transaction group processed successfully',
      group_id: groupId,
      transaction_count: transactions.length,
      commission_count: commissionRecords.length,
      totals: {
        customer_paid: totalCustomerPays,
        referrer_total_commission: totalReferrerGets,
        has_referrer: hasReferrer,
        referring_tenant_id: referringTenantId
      },
      commission_ids: commissionRecords
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200
    }
  );
}

/**
 * Process a single transaction (backwards compatibility)
 * Original implementation from Phase 4
 */
async function processSingleTransaction(supabase: any, reference: string, amount: number, metadata: any) {
  const {
    transaction_id,
    transaction_type,
    provider_tenant_id,
    customer_id,
    base_price
  } = metadata;

  console.log(`Processing single transaction: ${transaction_id}`);

  // Check for idempotency
  const { data: existingCommission } = await supabase
    .from('commissions')
    .select('id')
    .eq('transaction_id', transaction_id)
    .single();

  if (existingCommission) {
    console.log('Commission already exists for transaction:', transaction_id);
    return new Response(
      JSON.stringify({ message: 'Commission already processed', commission_id: existingCommission.id }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    );
  }

  // Get active referral session
  const { data: sessionData } = await supabase.rpc('get_active_referral_session', {
    p_customer_id: customer_id
  });

  const hasReferrer = sessionData && sessionData.length > 0;
  const referringTenantId = hasReferrer ? sessionData[0].referring_tenant_id : null;

  // Calculate commission with self-provider check
  const { data: calcData, error: calcError } = await supabase.rpc(
    'calculate_commission_with_provider_check',
    {
      p_transaction_type: transaction_type,
      p_base_price: base_price,
      p_provider_tenant_id: provider_tenant_id,
      p_referring_tenant_id: referringTenantId
    }
  );

  if (calcError || !calcData || calcData.length === 0) {
    throw new Error(`Commission calculation failed: ${calcError?.message}`);
  }

  const calculation = calcData[0];
  const isSelfProvider = calculation.is_self_provider;
  const actualHasReferrer = calculation.has_referrer;

  console.log('Commission calculated:', {
    ...calculation,
    is_self_provider: isSelfProvider,
    has_referrer: actualHasReferrer
  });

  // Create commission record
  const { data: commissionRecord, error: commissionError } = await supabase.rpc(
    'create_commission_record',
    {
      p_transaction_id: transaction_id,
      p_transaction_type: transaction_type,
      p_provider_tenant_id: provider_tenant_id,
      p_referrer_tenant_id: referringTenantId,
      p_customer_id: customer_id,
      p_base_amount: base_price,
      p_customer_paid: calculation.customer_pays,
      p_provider_amount: calculation.provider_gets,
      p_referrer_amount: calculation.referrer_gets,
      p_platform_amount: calculation.platform_gets
    }
  );

  if (commissionError) throw commissionError;

  // Update transaction
  await supabase
    .from('transactions')
    .update({
      payment_status: 'completed',
      paid_at: new Date().toISOString(),
      payment_reference: reference,
      final_price_paid: calculation.customer_pays
    })
    .eq('id', transaction_id);

  return new Response(
    JSON.stringify({
      success: true,
      message: 'Payment processed and commission calculated',
      commission_id: commissionRecord,
      breakdown: {
        customer_paid: calculation.customer_pays,
        provider_gets: calculation.provider_gets,
        referrer_gets: calculation.referrer_gets,
        platform_gets: calculation.platform_gets,
        has_referrer: actualHasReferrer,
        is_self_provider: isSelfProvider,
        referring_tenant_id: referringTenantId
      }
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200
    }
  );
}

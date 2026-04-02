import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

/**
 * Payment Initialization API
 * Feature: 004-tenant-referral-commissions
 *
 * Integrates with Paystack to initialize payment transactions
 */

// Get Paystack secret key from environment
const PAYSTACK_SECRET_KEY = process.env.PAYSTACK_SECRET_KEY;
const PAYSTACK_API_URL = 'https://api.paystack.co';

export const POST: RequestHandler = async ({ request, locals }) => {
	try {
		// Check if user is authenticated
		if (!locals.session?.user) {
			throw error(401, 'Unauthorized - Please log in');
		}

		// Parse request body
		const { amount, email, metadata } = await request.json();

		// Validate required fields
		if (!amount || !email) {
			throw error(400, 'Missing required fields: amount, email');
		}

		// Validate metadata
		if (!metadata?.customer_id) {
			throw error(400, 'Missing customer_id in metadata');
		}

		// Check if we have either group_id or transaction_id
		if (!metadata.group_id && !metadata.transaction_id) {
			throw error(400, 'Metadata must include either group_id or transaction_id');
		}

		// Check if Paystack is configured
		if (!PAYSTACK_SECRET_KEY) {
			console.error('PAYSTACK_SECRET_KEY not configured');
			throw error(500, 'Payment gateway not configured');
		}

		// Initialize payment with Paystack
		const paystackResponse = await fetch(`${PAYSTACK_API_URL}/transaction/initialize`, {
			method: 'POST',
			headers: {
				'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`,
				'Content-Type': 'application/json'
			},
			body: JSON.stringify({
				amount: Math.round(amount * 100), // Convert to kobo
				email,
				metadata: {
					...metadata,
					// Add custom fields for better tracking
					custom_fields: [
						{
							display_name: 'Customer ID',
							variable_name: 'customer_id',
							value: metadata.customer_id
						},
						{
							display_name: 'Transaction Type',
							variable_name: 'transaction_type',
							value: metadata.group_id ? 'multi-service' : 'single'
						}
					]
				},
				// Callback URL where customer returns after payment
				callback_url: `${process.env.PUBLIC_APP_URL || 'http://localhost:5173'}/payment/callback`,
				// Channels to accept payment
				channels: ['card', 'bank', 'ussd', 'qr', 'mobile_money', 'bank_transfer']
			})
		});

		const paystackData = await paystackResponse.json();

		// Check if initialization was successful
		if (!paystackData.status) {
			console.error('Paystack initialization failed:', paystackData);
			throw error(500, paystackData.message || 'Payment initialization failed');
		}

		// Log successful initialization
		console.log('Payment initialized:', {
			reference: paystackData.data.reference,
			amount,
			customer_id: metadata.customer_id,
			group_id: metadata.group_id,
			transaction_id: metadata.transaction_id
		});

		// Return success response
		return json({
			status: true,
			message: 'Payment initialized successfully',
			data: {
				authorization_url: paystackData.data.authorization_url,
				access_code: paystackData.data.access_code,
				reference: paystackData.data.reference
			}
		});
	} catch (err) {
		console.error('Payment initialization error:', err);

		// Re-throw SvelteKit errors
		if (err && typeof err === 'object' && 'status' in err) {
			throw err;
		}

		// Handle other errors
		throw error(500, err instanceof Error ? err.message : 'Internal server error');
	}
};


import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

/**
 * Payment Verification API
 * Feature: 004-tenant-referral-commissions
 *
 * Verifies payment with Paystack after customer returns
 */

const PAYSTACK_SECRET_KEY = process.env.PAYSTACK_SECRET_KEY;
const PAYSTACK_API_URL = 'https://api.paystack.co';

export const GET: RequestHandler = async ({ url, locals }) => {
	try {
		// Check if user is authenticated
		if (!locals.session?.user) {
			throw error(401, 'Unauthorized - Please log in');
		}

		// Get payment reference from query params
		const reference = url.searchParams.get('reference');

		if (!reference) {
			throw error(400, 'Payment reference is required');
		}

		// Check if Paystack is configured
		if (!PAYSTACK_SECRET_KEY) {
			console.error('PAYSTACK_SECRET_KEY not configured');
			throw error(500, 'Payment gateway not configured');
		}

		// Verify payment with Paystack
		const paystackResponse = await fetch(
			`${PAYSTACK_API_URL}/transaction/verify/${reference}`,
			{
				method: 'GET',
				headers: {
					'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`,
					'Content-Type': 'application/json'
				}
			}
		);

		const paystackData = await paystackResponse.json();

		// Check if verification was successful
		if (!paystackData.status) {
			console.error('Paystack verification failed:', paystackData);
			throw error(500, paystackData.message || 'Payment verification failed');
		}

		const paymentData = paystackData.data;

		// Check payment status
		if (paymentData.status !== 'success') {
			return json({
				status: false,
				message: `Payment ${paymentData.status}`,
				data: null
			});
		}

		// Log successful verification
		console.log('Payment verified:', {
			reference: paymentData.reference,
			amount: paymentData.amount / 100,
			status: paymentData.status,
			customer: paymentData.customer.email
		});

		// Note: The webhook (Edge Function) will handle commission creation
		// This endpoint just confirms payment for the frontend

		// Return success response
		return json({
			status: true,
			message: 'Payment verified successfully',
			data: {
				reference: paymentData.reference,
				amount: paymentData.amount,
				currency: paymentData.currency,
				status: paymentData.status,
				paid_at: paymentData.paid_at,
				customer: {
					email: paymentData.customer.email
				},
				metadata: paymentData.metadata
			}
		});
	} catch (err) {
		console.error('Payment verification error:', err);

		// Re-throw SvelteKit errors
		if (err && typeof err === 'object' && 'status' in err) {
			throw err;
		}

		// Handle other errors
		throw error(500, err instanceof Error ? err.message : 'Internal server error');
	}
};


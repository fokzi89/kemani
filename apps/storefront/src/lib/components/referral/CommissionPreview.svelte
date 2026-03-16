<script lang="ts">
	import { CommissionCalculator } from '$lib/services/commissionCalculator';
	import type { TransactionType, CommissionCalculationResponse } from '$lib/types/commission';

	/**
	 * CommissionPreview Component
	 * Displays commission breakdown before checkout
	 * Shows transparent pricing to customers
	 */

	// Props
	export let transactionType: TransactionType;
	export let basePrice: number;
	export let hasReferrer: boolean = false;
	export let referrerName: string | null = null;
	export let showDetails: boolean = true;

	// State
	let calculation: CommissionCalculationResponse | null = null;
	let loading = true;
	let error: string | null = null;

	// Format currency
	function formatCurrency(amount: number): string {
		return new Intl.NumberFormat('en-NG', {
			style: 'currency',
			currency: 'NGN',
			minimumFractionDigits: 2,
			maximumFractionDigits: 2
		}).format(amount);
	}

	// Calculate commission on mount or when props change
	$: {
		if (basePrice > 0 && transactionType) {
			loadCalculation();
		}
	}

	async function loadCalculation() {
		loading = true;
		error = null;

		try {
			const result = await CommissionCalculator.calculate({
				transaction_type: transactionType,
				base_price: basePrice,
				has_referrer: hasReferrer
			});

			if (result) {
				calculation = result;
			} else {
				error = 'Failed to calculate commission';
			}
		} catch (err) {
			console.error('Error calculating commission:', err);
			error = 'An error occurred while calculating the price';
		} finally {
			loading = false;
		}
	}

	// Get transaction type label
	function getTransactionLabel(type: TransactionType): string {
		switch (type) {
			case 'consultation':
				return 'Consultation';
			case 'product_sale':
				return 'Product Purchase';
			case 'diagnostic_test':
				return 'Diagnostic Test';
			default:
				return 'Transaction';
		}
	}
</script>

<div class="commission-preview" data-testid="commission-preview">
	{#if loading}
		<div class="loading">
			<div class="spinner"></div>
			<p>Calculating price...</p>
		</div>
	{:else if error}
		<div class="error">
			<p>{error}</p>
		</div>
	{:else if calculation}
		<div class="preview-card">
			<!-- Main price display -->
			<div class="price-section">
				<div class="price-label">Total Price</div>
				<div class="price-amount" data-testid="customer-pays">
					{formatCurrency(calculation.customer_pays)}
				</div>
			</div>

			<!-- Base price info -->
			<div class="base-info">
				<span>{getTransactionLabel(transactionType)} Base Price:</span>
				<span>{formatCurrency(calculation.base_price)}</span>
			</div>

			{#if calculation.markup_applied}
				<div class="markup-info">
					{#if calculation.markup_percentage}
						<span>Service Fee ({calculation.markup_percentage}%):</span>
						<span
							>{formatCurrency(calculation.customer_pays - calculation.base_price)}</span
						>
					{:else}
						<span>Processing Fee:</span>
						<span>{formatCurrency(100)}</span>
					{/if}
				</div>
			{/if}

			<!-- Referrer badge -->
			{#if hasReferrer && referrerName}
				<div class="referrer-badge">
					<svg
						xmlns="http://www.w3.org/2000/svg"
						width="16"
						height="16"
						viewBox="0 0 24 24"
						fill="none"
						stroke="currentColor"
						stroke-width="2"
					>
						<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
						<circle cx="9" cy="7" r="4" />
						<path d="M22 21v-2a4 4 0 0 0-3-3.87" />
						<path d="M16 3.13a4 4 0 0 1 0 7.75" />
					</svg>
					<span>Referred by {referrerName}</span>
				</div>
			{/if}

			<!-- Detailed breakdown (optional) -->
			{#if showDetails}
				<details class="breakdown-details">
					<summary>View Price Breakdown</summary>
					<div class="breakdown-content">
						<div class="breakdown-item">
							<span>Provider Receives:</span>
							<span>{formatCurrency(calculation.breakdown.provider_gets)}</span>
						</div>
						{#if hasReferrer && calculation.breakdown.referrer_gets > 0}
							<div class="breakdown-item referrer-item">
								<span>Referrer Commission:</span>
								<span>{formatCurrency(calculation.breakdown.referrer_gets)}</span>
							</div>
						{/if}
						<div class="breakdown-item">
							<span>Platform Fee:</span>
							<span>{formatCurrency(calculation.breakdown.platform_gets)}</span>
						</div>
						<div class="breakdown-divider"></div>
						<div class="breakdown-item total">
							<span>Total:</span>
							<span>{formatCurrency(calculation.customer_pays)}</span>
						</div>
					</div>
				</details>
			{/if}
		</div>
	{/if}
</div>

<style>
	.commission-preview {
		width: 100%;
		font-family: system-ui, -apple-system, sans-serif;
	}

	.loading {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		padding: 2rem;
		gap: 1rem;
	}

	.spinner {
		width: 40px;
		height: 40px;
		border: 4px solid #f3f3f3;
		border-top: 4px solid #3498db;
		border-radius: 50%;
		animation: spin 1s linear infinite;
	}

	@keyframes spin {
		0% {
			transform: rotate(0deg);
		}
		100% {
			transform: rotate(360deg);
		}
	}

	.error {
		padding: 1rem;
		background: #fee;
		border: 1px solid #fcc;
		border-radius: 8px;
		color: #c33;
	}

	.preview-card {
		border: 1px solid #e0e0e0;
		border-radius: 12px;
		padding: 1.5rem;
		background: #fff;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
	}

	.price-section {
		display: flex;
		flex-direction: column;
		align-items: center;
		padding-bottom: 1rem;
		border-bottom: 2px solid #f0f0f0;
		margin-bottom: 1rem;
	}

	.price-label {
		font-size: 0.875rem;
		color: #666;
		margin-bottom: 0.5rem;
	}

	.price-amount {
		font-size: 2rem;
		font-weight: 700;
		color: #2c3e50;
	}

	.base-info,
	.markup-info {
		display: flex;
		justify-content: space-between;
		padding: 0.5rem 0;
		font-size: 0.875rem;
		color: #555;
	}

	.markup-info {
		color: #666;
		font-style: italic;
	}

	.referrer-badge {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		padding: 0.75rem;
		background: #e3f2fd;
		border-radius: 8px;
		margin-top: 1rem;
		font-size: 0.875rem;
		color: #1976d2;
	}

	.referrer-badge svg {
		flex-shrink: 0;
	}

	.breakdown-details {
		margin-top: 1rem;
		border-top: 1px solid #f0f0f0;
		padding-top: 1rem;
	}

	.breakdown-details summary {
		cursor: pointer;
		font-size: 0.875rem;
		color: #1976d2;
		padding: 0.5rem 0;
		user-select: none;
	}

	.breakdown-details summary:hover {
		color: #1565c0;
	}

	.breakdown-content {
		margin-top: 1rem;
		font-size: 0.875rem;
	}

	.breakdown-item {
		display: flex;
		justify-content: space-between;
		padding: 0.5rem 0;
		color: #555;
	}

	.breakdown-item.referrer-item {
		background: #f1f8e9;
		padding: 0.5rem;
		margin: 0.25rem 0;
		border-radius: 4px;
		color: #558b2f;
	}

	.breakdown-item.total {
		font-weight: 700;
		color: #2c3e50;
		padding-top: 1rem;
		font-size: 1rem;
	}

	.breakdown-divider {
		height: 1px;
		background: #e0e0e0;
		margin: 0.5rem 0;
	}
</style>

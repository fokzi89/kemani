/**
 * Example usage of pricing utilities and plan enforcement
 * This file demonstrates how to use the shared utilities
 */

import { 
    calculateOrderTotals, 
    calculateOrderTotalsWithDelivery,
    calculateDeliveryFee,
    formatCurrency,
    calculateDistance,
    DELIVERY_METHODS
} from '$lib/storefront/pricing.js';

import { 
    getPlanLimits, 
    isFeatureEnabled, 
    isLimitReached,
    createPlanEnforcement,
    getPlanUpgradeSuggestions
} from '$lib/storefront/plans.js';

import type { PlanTier } from '$lib/types/supabase.js';

// Example 1: Calculate order totals with delivery
export function exampleOrderCalculation() {
    const subtotal = 5000; // ₦5,000
    const deliveryMethod = 'motorbike';
    const distanceKm = 5.2;

    // Calculate with delivery
    const orderTotals = calculateOrderTotalsWithDelivery(subtotal, deliveryMethod, distanceKm);
    
    console.log('Order Breakdown:');
    console.log(`Subtotal: ${formatCurrency(orderTotals.subtotal)}`);
    console.log(`Delivery (${orderTotals.deliveryDetails.method}): ${formatCurrency(orderTotals.deliveryDetails.totalDeliveryFee)}`);
    console.log(`  - Base fee: ${formatCurrency(orderTotals.deliveryDetails.baseFee)}`);
    console.log(`  - Distance fee: ${formatCurrency(orderTotals.deliveryDetails.distanceFee)}`);
    console.log(`Delivery addition: ${formatCurrency(orderTotals.deliveryFeeAddition)}`);
    console.log(`Platform commission: ${formatCurrency(orderTotals.platformCommission)}`);
    console.log(`Transaction fee: ${formatCurrency(orderTotals.transactionFee)}`);
    console.log(`Total: ${formatCurrency(orderTotals.totalAmount)}`);
    
    return orderTotals;
}

// Example 2: Check plan limits and features
export function examplePlanChecks(planTier: PlanTier) {
    const limits = getPlanLimits(planTier);
    
    console.log(`Plan: ${planTier.toUpperCase()}`);
    console.log(`Max Products: ${limits.maxProducts === Infinity ? 'Unlimited' : limits.maxProducts}`);
    console.log(`Max Staff: ${limits.maxStaff === Infinity ? 'Unlimited' : limits.maxStaff}`);
    console.log(`Max Branches: ${limits.maxBranches === Infinity ? 'Unlimited' : limits.maxBranches}`);
    
    // Check features
    console.log('\nFeatures:');
    console.log(`AI Chat Standard: ${isFeatureEnabled(planTier, 'aiChatStandard') ? '✓' : '✗'}`);
    console.log(`AI Chat Agent: ${isFeatureEnabled(planTier, 'aiChatAgent') ? '✓' : '✗'}`);
    console.log(`Multi-branch: ${isFeatureEnabled(planTier, 'multiBranch') ? '✓' : '✗'}`);
    console.log(`Custom Branding: ${isFeatureEnabled(planTier, 'customBranding') ? '✓' : '✗'}`);
    
    return limits;
}

// Example 3: Plan enforcement
export function examplePlanEnforcement(planTier: PlanTier, currentUsage: { products: number; staff: number; branches: number }) {
    const enforcement = createPlanEnforcement(planTier);
    
    // Check product limit (T010a)
    const productCheck = enforcement.enforceProductLimit(currentUsage.products);
    console.log('\nProduct Limit Check:');
    console.log(`Can add product: ${productCheck.allowed ? '✓' : '✗'}`);
    if (!productCheck.allowed) {
        console.log(`Reason: ${productCheck.message}`);
    }
    console.log(`Current: ${currentUsage.products}/${productCheck.limit === Infinity ? '∞' : productCheck.limit}`);
    console.log(`Remaining: ${productCheck.remaining === 'unlimited' ? '∞' : productCheck.remaining}`);
    
    // Check staff limit (T010b)
    const staffCheck = enforcement.enforceStaffLimit(currentUsage.staff);
    console.log('\nStaff Limit Check:');
    console.log(`Can add staff: ${staffCheck.allowed ? '✓' : '✗'}`);
    if (!staffCheck.allowed) {
        console.log(`Reason: ${staffCheck.message}`);
    }
    console.log(`Current: ${currentUsage.staff}/${staffCheck.limit === Infinity ? '∞' : staffCheck.limit}`);
    console.log(`Remaining: ${staffCheck.remaining === 'unlimited' ? '∞' : staffCheck.remaining}`);
    
    return { productCheck, staffCheck };
}

// Example 4: Plan upgrade suggestions
export function exampleUpgradeSuggestions(currentPlan: PlanTier, usage: { products: number; staff: number; branches: number }) {
    const suggestions = getPlanUpgradeSuggestions(currentPlan, usage);
    
    console.log('\nUpgrade Analysis:');
    console.log(`Needs upgrade: ${suggestions.needsUpgrade ? 'Yes' : 'No'}`);
    
    if (suggestions.needsUpgrade) {
        console.log('Reasons:');
        suggestions.reasons.forEach(reason => console.log(`  - ${reason}`));
        
        if (suggestions.suggestedPlan) {
            console.log(`Suggested plan: ${suggestions.suggestedPlan.toUpperCase()}`);
        }
    }
    
    return suggestions;
}

// Example 5: Distance calculation for delivery
export function exampleDistanceCalculation() {
    // Lagos coordinates (example)
    const storeLocation = { lat: 6.5244, lng: 3.3792 }; // Victoria Island
    const customerLocation = { lat: 6.4474, lng: 3.3903 }; // Ikoyi
    
    const distance = calculateDistance(
        storeLocation.lat, 
        storeLocation.lng, 
        customerLocation.lat, 
        customerLocation.lng
    );
    
    console.log(`Distance: ${distance.toFixed(2)} km`);
    
    // Calculate delivery fee for different methods
    console.log('\nDelivery Options:');
    Object.entries(DELIVERY_METHODS).forEach(([method, config]) => {
        const fee = calculateDeliveryFee(method as keyof typeof DELIVERY_METHODS, distance);
        console.log(`${config.name}: ${formatCurrency(fee.totalDeliveryFee)}`);
    });
    
    return distance;
}

// Run examples
export function runAllExamples() {
    console.log('=== PRICING EXAMPLES ===');
    exampleOrderCalculation();
    
    console.log('\n=== PLAN EXAMPLES ===');
    examplePlanChecks('free');
    examplePlanChecks('pro');
    
    console.log('\n=== ENFORCEMENT EXAMPLES ===');
    // Free plan with high usage
    examplePlanEnforcement('free', { products: 95, staff: 1, branches: 1 });
    
    // Free plan over limit
    examplePlanEnforcement('free', { products: 105, staff: 2, branches: 1 });
    
    console.log('\n=== UPGRADE SUGGESTIONS ===');
    exampleUpgradeSuggestions('free', { products: 105, staff: 2, branches: 1 });
    
    console.log('\n=== DISTANCE CALCULATION ===');
    exampleDistanceCalculation();
}
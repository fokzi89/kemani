import { z } from 'zod';

// Constants from Schema/Business Logic
export const DELIVERY_FEE_ADDITION = 100;
export const DELIVERY_BASE_FEE = DELIVERY_FEE_ADDITION; // alias
export const PLATFORM_COMMISSION = 50;
export const TRANSACTION_FEE = 100;

// Delivery method pricing
export const DELIVERY_METHODS = {
    self_pickup: { baseFee: 0, name: 'Self Pickup' },
    bicycle: { baseFee: 200, name: 'Bicycle Delivery' },
    motorbike: { baseFee: 500, name: 'Motorbike Delivery' },
    platform: { baseFee: 800, name: 'Platform Delivery' }
} as const;

export type DeliveryMethod = keyof typeof DELIVERY_METHODS;

export interface PriceBreakdown {
    subtotal: number;
    deliveryBaseFee: number;
    deliveryFeeAddition: number;
    platformCommission: number;
    transactionFee: number;
    totalAmount: number;
}

export interface DeliveryFeeCalculation {
    baseFee: number;
    distanceFee: number;
    totalDeliveryFee: number;
    method: DeliveryMethod;
}

/**
 * Calculate delivery fee based on method and distance
 */
export function calculateDeliveryFee(
    method: DeliveryMethod,
    distanceKm: number = 0
): DeliveryFeeCalculation {
    const methodConfig = DELIVERY_METHODS[method];
    let baseFee = methodConfig.baseFee;
    let distanceFee = 0;

    // Distance-based pricing for delivery methods
    if (method !== 'self_pickup' && distanceKm > 0) {
        // Additional fee per km beyond first 2km
        const extraDistance = Math.max(0, distanceKm - 2);
        distanceFee = Math.ceil(extraDistance) * 50; // ₦50 per extra km
    }

    return {
        baseFee,
        distanceFee,
        totalDeliveryFee: baseFee + distanceFee,
        method
    };
}

/**
 * Calculate total order price including all fees
 */
export function calculateOrderTotals(
    subtotal: number,
    deliveryBaseFee: number = 0
): PriceBreakdown {
    // Ensure non-negative inputs
    const safeSubtotal = Math.max(0, subtotal);
    const safeDeliveryBaseFee = Math.max(0, deliveryBaseFee);

    const totalAmount =
        safeSubtotal +
        safeDeliveryBaseFee +
        DELIVERY_FEE_ADDITION +
        PLATFORM_COMMISSION +
        TRANSACTION_FEE;

    return {
        subtotal: safeSubtotal,
        deliveryBaseFee: safeDeliveryBaseFee,
        deliveryFeeAddition: DELIVERY_FEE_ADDITION,
        platformCommission: PLATFORM_COMMISSION,
        transactionFee: TRANSACTION_FEE,
        totalAmount: Number(totalAmount.toFixed(2)), // Ensure 2 decimal places
    };
}

/**
 * Calculate order totals with delivery method
 */
export function calculateOrderTotalsWithDelivery(
    subtotal: number,
    deliveryMethod: DeliveryMethod,
    distanceKm: number = 0
): PriceBreakdown & { deliveryDetails: DeliveryFeeCalculation } {
    const deliveryDetails = calculateDeliveryFee(deliveryMethod, distanceKm);
    const breakdown = calculateOrderTotals(subtotal, deliveryDetails.totalDeliveryFee);

    return {
        ...breakdown,
        deliveryDetails
    };
}

/**
 * Format currency in Nigerian Naira (NGN)
 */
export function formatCurrency(amount: number): string {
    return new Intl.NumberFormat('en-NG', {
        style: 'currency',
        currency: 'NGN',
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
    }).format(amount);
}

/**
 * Calculate distance between two coordinates (Haversine formula)
 */
export function calculateDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number
): number {
    const R = 6371; // Earth's radius in kilometers
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = 
        Math.sin(dLat/2) * Math.sin(dLat/2) +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
        Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
}

/**
 * Validation schemas for pricing
 */
export const priceSchema = z.number().min(0, 'Price must be non-negative');
export const deliveryMethodSchema = z.enum(['self_pickup', 'bicycle', 'motorbike', 'platform']);
export const coordinatesSchema = z.object({
    lat: z.number().min(-90).max(90),
    lng: z.number().min(-180).max(180)
});

export const orderTotalsSchema = z.object({
    subtotal: priceSchema,
    deliveryMethod: deliveryMethodSchema,
    deliveryCoordinates: coordinatesSchema.optional(),
    storeCoordinates: coordinatesSchema.optional()
});

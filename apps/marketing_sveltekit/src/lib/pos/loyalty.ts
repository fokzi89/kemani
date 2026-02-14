import { CustomerService } from './customer';

export class LoyaltyService {
    private static POINTS_PER_CURRENCY_UNIT = 1; // 1 point
    private static CURRENCY_UNIT_FOR_POINTS = 100; // per 100 Naira

    /**
     * Calculate points earned for a transaction amount
     */
    static calculatePoints(amount: number): number {
        if (amount <= 0) return 0;
        return Math.floor(amount / this.CURRENCY_UNIT_FOR_POINTS) * this.POINTS_PER_CURRENCY_UNIT;
    }

    /**
     * Award points to customer for a purchase
     */
    static async awardPoints(customerId: string, amount: number) {
        const points = this.calculatePoints(amount);
        if (points > 0) {
            await CustomerService.updateLoyaltyPoints(customerId, points);
        }
        return points;
    }

    /**
     * Redeem points from customer balance
     * (Returns true if successful, false if insufficient balance)
     */
    static async redeemPoints(customerId: string, pointsToRedeem: number): Promise<boolean> {
        if (pointsToRedeem <= 0) return false;

        try {
            // Get current balance
            const customer = await CustomerService.getCustomer(customerId);
            const currentBalance = customer.loyalty_points || 0;

            if (currentBalance < pointsToRedeem) {
                return false;
            }

            // Deduct points (negative delta)
            await CustomerService.updateLoyaltyPoints(customerId, -pointsToRedeem);
            return true;
        } catch (error) {
            console.error('Redeem points error:', error);
            return false;
        }
    }

    /**
     * Calculate discount value for points (optional util)
     * Example: 1 point = 1 Naira? Or configured?
     * For now, assuming 1 point = 1 Naira discount value for simplicity, or implementation specific.
     */
    static getPointsValue(points: number): number {
        // This could be configurable per tenant in the future
        const VALUE_PER_POINT = 1;
        return points * VALUE_PER_POINT;
    }
}

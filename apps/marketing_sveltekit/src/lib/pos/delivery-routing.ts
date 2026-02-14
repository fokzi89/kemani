import { calculateDistance } from '@/lib/utils/distance';

type RoutingSuggestion = {
    deliveryType: 'local_bike' | 'local_bicycle' | 'intercity';
    estimatedCost: number;
    reason: string;
};

export class DeliveryRoutingService {
    private static LOCAL_DISTANCE_THRESHOLD_KM = 25; // As per user requirement
    private static BIKE_MAX_KM = 25;
    private static BICYCLE_MAX_KM = 5;

    /**
     * Suggests the best delivery method based on customer location relative to branch
     */
    static suggestDeliveryType(
        branchLat: number,
        branchLng: number,
        customerLat: number,
        customerLng: number
    ): RoutingSuggestion {
        const distanceKm = calculateDistance(branchLat, branchLng, customerLat, customerLng);

        if (distanceKm > this.LOCAL_DISTANCE_THRESHOLD_KM) {
            return {
                deliveryType: 'intercity',
                estimatedCost: this.calculateIntercityCost(distanceKm),
                reason: `Distance (${distanceKm.toFixed(1)}km) exceeds local delivery range of ${this.LOCAL_DISTANCE_THRESHOLD_KM}km.`
            };
        } else if (distanceKm <= this.BICYCLE_MAX_KM) {
            return {
                deliveryType: 'local_bicycle',
                estimatedCost: this.calculateLocalCost(distanceKm, 'bicycle'),
                reason: `Short distance (${distanceKm.toFixed(1)}km) suitable for bicycle courier.`
            };
        } else {
            return {
                deliveryType: 'local_bike',
                estimatedCost: this.calculateLocalCost(distanceKm, 'bike'),
                reason: `Distance (${distanceKm.toFixed(1)}km) within local bike delivery range.`
            };
        }
    }

    private static calculateLocalCost(km: number, vehicle: 'bike' | 'bicycle'): number {
        const baseFare = vehicle === 'bike' ? 500 : 300;
        const perKm = vehicle === 'bike' ? 100 : 50;
        return baseFare + (km * perKm);
    }

    private static calculateIntercityCost(km: number): number {
        // Simple mock formula: Base 2000 + 50 per km
        return 2000 + (km * 50);
    }
}

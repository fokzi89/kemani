/**
 * Distance Calculation Utility
 * Haversine formula for calculating distances between coordinates
 */

// ============================================
// TYPES
// ============================================

export interface Coordinates {
  latitude: number;
  longitude: number;
}

export interface Location extends Coordinates {
  address?: string;
  city?: string;
  state?: string;
}

export type DistanceUnit = 'km' | 'miles' | 'meters';

// ============================================
// CONSTANTS
// ============================================

const EARTH_RADIUS_KM = 6371; // Earth's radius in kilometers
const EARTH_RADIUS_MILES = 3959; // Earth's radius in miles

// Delivery thresholds for Nigeria
export const DELIVERY_THRESHOLDS = {
  LOCAL_MAX_KM: 25, // Maximum distance for local delivery
  INTERCITY_MIN_KM: 25, // Minimum distance for intercity delivery
  SAME_CITY_MAX_KM: 50, // Maximum distance within same city
};

// ============================================
// DISTANCE CALCULATIONS
// ============================================

/**
 * Convert degrees to radians
 */
function degreesToRadians(degrees: number): number {
  return degrees * (Math.PI / 180);
}

/**
 * Calculate distance between two coordinates using Haversine formula
 *
 * @param from - Starting coordinates
 * @param to - Destination coordinates
 * @param unit - Unit of measurement (default: 'km')
 * @returns Distance in specified unit
 */
export function calculateDistance(
  from: Coordinates,
  to: Coordinates,
  unit: DistanceUnit = 'km'
): number {
  const lat1 = degreesToRadians(from.latitude);
  const lat2 = degreesToRadians(to.latitude);
  const deltaLat = degreesToRadians(to.latitude - from.latitude);
  const deltaLon = degreesToRadians(to.longitude - from.longitude);

  // Haversine formula
  const a =
    Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(deltaLon / 2) * Math.sin(deltaLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  // Calculate distance
  const distanceKm = EARTH_RADIUS_KM * c;

  // Convert to requested unit
  switch (unit) {
    case 'km':
      return distanceKm;
    case 'miles':
      return distanceKm * 0.621371;
    case 'meters':
      return distanceKm * 1000;
    default:
      return distanceKm;
  }
}

/**
 * Determine delivery type based on distance
 *
 * @param distanceKm - Distance in kilometers
 * @returns 'local' or 'intercity'
 */
export function getDeliveryType(distanceKm: number): 'local' | 'intercity' {
  return distanceKm <= DELIVERY_THRESHOLDS.LOCAL_MAX_KM ? 'local' : 'intercity';
}

/**
 * Check if distance is within local delivery range
 *
 * @param distanceKm - Distance in kilometers
 * @returns true if within local delivery range
 */
export function isLocalDelivery(distanceKm: number): boolean {
  return distanceKm <= DELIVERY_THRESHOLDS.LOCAL_MAX_KM;
}

/**
 * Check if distance requires intercity delivery
 *
 * @param distanceKm - Distance in kilometers
 * @returns true if intercity delivery required
 */
export function isIntercityDelivery(distanceKm: number): boolean {
  return distanceKm > DELIVERY_THRESHOLDS.LOCAL_MAX_KM;
}

/**
 * Calculate delivery fee based on distance
 *
 * @param distanceKm - Distance in kilometers
 * @param baseRate - Base rate per km
 * @param minimumFee - Minimum delivery fee
 * @returns Calculated delivery fee
 */
export function calculateDeliveryFee(
  distanceKm: number,
  baseRate: number = 100, // ₦100 per km
  minimumFee: number = 500 // Minimum ₦500
): number {
  const calculatedFee = distanceKm * baseRate;
  return Math.max(calculatedFee, minimumFee);
}

/**
 * Calculate delivery fee with tiered pricing
 *
 * @param distanceKm - Distance in kilometers
 * @returns Delivery fee based on distance tiers
 */
export function calculateTieredDeliveryFee(distanceKm: number): number {
  if (distanceKm <= 5) {
    return 500; // ₦500 for first 5km
  } else if (distanceKm <= 10) {
    return 500 + (distanceKm - 5) * 80; // ₦80 per km for 5-10km
  } else if (distanceKm <= 25) {
    return 900 + (distanceKm - 10) * 100; // ₦100 per km for 10-25km
  } else {
    // Intercity: ₦150 per km
    return 2400 + (distanceKm - 25) * 150;
  }
}

/**
 * Estimate delivery time based on distance
 *
 * @param distanceKm - Distance in kilometers
 * @param avgSpeedKmh - Average speed in km/h (default: 30 km/h for city traffic)
 * @returns Estimated delivery time in minutes
 */
export function estimateDeliveryTime(
  distanceKm: number,
  avgSpeedKmh: number = 30
): number {
  const hours = distanceKm / avgSpeedKmh;
  const minutes = Math.ceil(hours * 60);

  // Add buffer time for local deliveries (10 minutes)
  // Add more buffer for intercity (30 minutes)
  const bufferMinutes = distanceKm <= DELIVERY_THRESHOLDS.LOCAL_MAX_KM ? 10 : 30;

  return minutes + bufferMinutes;
}

/**
 * Format delivery time estimate as readable string
 *
 * @param minutes - Time in minutes
 * @returns Formatted string (e.g., "30-45 mins" or "1-2 hours")
 */
export function formatDeliveryTime(minutes: number): string {
  if (minutes < 60) {
    const lower = Math.floor(minutes / 10) * 10;
    const upper = lower + 15;
    return `${lower}-${upper} mins`;
  } else {
    const hours = Math.ceil(minutes / 60);
    if (hours === 1) {
      return '1-1.5 hours';
    } else {
      return `${hours}-${hours + 1} hours`;
    }
  }
}

/**
 * Get nearest location from a list of locations
 *
 * @param from - Starting coordinates
 * @param locations - Array of locations to search
 * @returns Nearest location with distance
 */
export function getNearestLocation(
  from: Coordinates,
  locations: Location[]
): { location: Location; distance: number } | null {
  if (locations.length === 0) return null;

  let nearest = locations[0];
  let minDistance = calculateDistance(from, nearest);

  for (const location of locations) {
    const distance = calculateDistance(from, location);
    if (distance < minDistance) {
      minDistance = distance;
      nearest = location;
    }
  }

  return { location: nearest, distance: minDistance };
}

/**
 * Get locations within a certain radius
 *
 * @param center - Center coordinates
 * @param locations - Array of locations to filter
 * @param radiusKm - Radius in kilometers
 * @returns Locations within radius, sorted by distance
 */
export function getLocationsWithinRadius(
  center: Coordinates,
  locations: Location[],
  radiusKm: number
): Array<{ location: Location; distance: number }> {
  const result: Array<{ location: Location; distance: number }> = [];

  for (const location of locations) {
    const distance = calculateDistance(center, location);
    if (distance <= radiusKm) {
      result.push({ location, distance });
    }
  }

  // Sort by distance (nearest first)
  return result.sort((a, b) => a.distance - b.distance);
}

/**
 * Check if coordinates are valid
 *
 * @param coords - Coordinates to validate
 * @returns true if valid
 */
export function isValidCoordinates(coords: Coordinates): boolean {
  return (
    coords.latitude >= -90 &&
    coords.latitude <= 90 &&
    coords.longitude >= -180 &&
    coords.longitude <= 180
  );
}

/**
 * Parse coordinates from string (e.g., "6.5244,3.3792")
 *
 * @param coordString - Coordinates as string
 * @returns Parsed coordinates or null if invalid
 */
export function parseCoordinates(coordString: string): Coordinates | null {
  const parts = coordString.split(',').map((s) => parseFloat(s.trim()));

  if (parts.length !== 2 || parts.some(isNaN)) {
    return null;
  }

  const coords: Coordinates = {
    latitude: parts[0],
    longitude: parts[1],
  };

  return isValidCoordinates(coords) ? coords : null;
}

// ============================================
// NIGERIAN CITIES COORDINATES (Sample)
// ============================================

export const NIGERIAN_CITIES: Record<string, Coordinates> = {
  Lagos: { latitude: 6.5244, longitude: 3.3792 },
  Abuja: { latitude: 9.0765, longitude: 7.3986 },
  'Port Harcourt': { latitude: 4.8156, longitude: 7.0498 },
  Kano: { latitude: 12.0022, longitude: 8.5920 },
  Ibadan: { latitude: 7.3775, longitude: 3.9470 },
  Benin: { latitude: 6.3350, longitude: 5.6037 },
  'Jos': { latitude: 9.8965, longitude: 8.8583 },
  Calabar: { latitude: 4.9517, longitude: 8.3416 },
  Kaduna: { latitude: 10.5105, longitude: 7.4165 },
  Enugu: { latitude: 6.5244, longitude: 7.5106 },
};

/**
 * Calculate distance between two Nigerian cities
 *
 * @param cityA - Name of first city
 * @param cityB - Name of second city
 * @returns Distance in kilometers, or null if cities not found
 */
export function getDistanceBetweenCities(cityA: string, cityB: string): number | null {
  const coordsA = NIGERIAN_CITIES[cityA];
  const coordsB = NIGERIAN_CITIES[cityB];

  if (!coordsA || !coordsB) return null;

  return calculateDistance(coordsA, coordsB);
}

// ============================================
// EXPORT ALL
// ============================================

export default {
  calculateDistance,
  getDeliveryType,
  isLocalDelivery,
  isIntercityDelivery,
  calculateDeliveryFee,
  calculateTieredDeliveryFee,
  estimateDeliveryTime,
  formatDeliveryTime,
  getNearestLocation,
  getLocationsWithinRadius,
  isValidCoordinates,
  parseCoordinates,
  getDistanceBetweenCities,
  DELIVERY_THRESHOLDS,
  NIGERIAN_CITIES,
};

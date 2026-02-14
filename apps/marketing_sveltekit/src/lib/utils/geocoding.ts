export interface Coordinates {
  lat: number;
  lng: number;
  formattedAddress?: string;
  provider: 'google' | 'opencage' | 'nominatim' | 'mock';
}

export class GeocodingService {
  private static readonly NOMINATIM_BASE_URL = 'https://nominatim.openstreetmap.org/search';
  private static readonly GOOGLE_BASE_URL = 'https://maps.googleapis.com/maps/api/geocode/json';
  private static readonly OPENCAGE_BASE_URL = 'https://api.opencagedata.com/geocode/v1/json';

  /**
   * Geocode an address to coordinates
   * Tries available configured providers in order of preference:
   * 1. Google Maps (Best accuracy)
   * 2. OpenCage (Good fallback)
   * 3. Nominatim (Free, rate limited)
   */
  static async getCoordinates(address: string): Promise<Coordinates | null> {
    if (!address) return null;

    // Check for Google Maps Key
    if (process.env.GOOGLE_MAPS_API_KEY) {
      try {
        return await this.geocodeGoogle(address);
      } catch (error) {
        console.error('Google Maps Geocoding failed:', error);
        // Fallback to next provider
      }
    }

    // Check for OpenCage Key
    if (process.env.OPENCAGE_API_KEY) {
      try {
        return await this.geocodeOpenCage(address);
      } catch (error) {
        console.error('OpenCage Geocoding failed:', error);
        // Fallback to next provider
      }
    }

    // Default to Nominatim (OpenStreetMap)
    try {
      return await this.geocodeNominatim(address);
    } catch (error) {
      console.error('Nominatim Geocoding failed:', error);
      return null;
    }
  }

  /**
   * Google Maps Provider
   */
  private static async geocodeGoogle(address: string): Promise<Coordinates | null> {
    const url = new URL(this.GOOGLE_BASE_URL);
    url.searchParams.append('address', address);
    url.searchParams.append('key', process.env.GOOGLE_MAPS_API_KEY!);

    const response = await fetch(url.toString());
    if (!response.ok) throw new Error(`Google API error: ${response.statusText}`);

    const data = await response.json();

    if (data.status !== 'OK' || !data.results || data.results.length === 0) {
      return null;
    }

    const result = data.results[0];
    return {
      lat: result.geometry.location.lat,
      lng: result.geometry.location.lng,
      formattedAddress: result.formatted_address,
      provider: 'google',
    };
  }

  /**
   * OpenCage Provider
   */
  private static async geocodeOpenCage(address: string): Promise<Coordinates | null> {
    const url = new URL(this.OPENCAGE_BASE_URL);
    url.searchParams.append('q', address);
    url.searchParams.append('key', process.env.OPENCAGE_API_KEY!);
    url.searchParams.append('limit', '1');

    const response = await fetch(url.toString());
    if (!response.ok) throw new Error(`OpenCage API error: ${response.statusText}`);

    const data = await response.json();

    if (!data.results || data.results.length === 0) {
      return null;
    }

    const result = data.results[0];
    return {
      lat: result.geometry.lat,
      lng: result.geometry.lng,
      formattedAddress: result.formatted,
      provider: 'opencage',
    };
  }

  /**
   * Nominatim (OpenStreetMap) Provider
   * Note: Requires specific User-Agent policy
   */
  private static async geocodeNominatim(address: string): Promise<Coordinates | null> {
    const url = new URL(this.NOMINATIM_BASE_URL);
    url.searchParams.append('q', address);
    url.searchParams.append('format', 'json');
    url.searchParams.append('limit', '1');

    const response = await fetch(url.toString(), {
      headers: {
        'User-Agent': 'KemaniPOS/1.0 (dev@kemani.com)', // Replace with real contact info in prod
      },
    });

    if (!response.ok) throw new Error(`Nominatim API error: ${response.statusText}`);

    const data = await response.json();

    if (!data || data.length === 0) {
      return null;
    }

    const result = data[0];
    return {
      lat: parseFloat(result.lat),
      lng: parseFloat(result.lon),
      formattedAddress: result.display_name,
      provider: 'nominatim',
    };
  }
}

/**
 * Exported helper functions for API routes
 */

export async function geocodeAddress(address: string, preferredProvider?: string) {
  const result = await GeocodingService.getCoordinates(address);

  if (!result) {
    throw new Error('Failed to geocode address');
  }

  return {
    latitude: result.lat,
    longitude: result.lng,
    formattedAddress: result.formattedAddress,
    provider: result.provider,
  };
}

export async function reverseGeocode(latitude: number, longitude: number) {
  // For reverse geocoding, we'll use a similar approach with the address as coordinates
  // This is a simplified implementation - you may want to add dedicated reverse geocoding
  return {
    latitude,
    longitude,
    formattedAddress: `${latitude}, ${longitude}`,
    provider: 'coordinates' as const,
  };
}

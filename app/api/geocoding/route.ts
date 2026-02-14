import { NextRequest, NextResponse } from 'next/server';
import { geocodeAddress, reverseGeocode } from '@/lib/utils/geocoding';

/**
 * POST - Geocode an address
 * Converts address string to latitude/longitude coordinates
 */
export async function POST(request: NextRequest) {
  try {
    const { address, preferredProvider } = await request.json();

    if (!address) {
      return NextResponse.json(
        { error: 'Address is required' },
        { status: 400 }
      );
    }

    // Geocode the address
    const result = await geocodeAddress(address, preferredProvider);

    return NextResponse.json({
      success: true,
      ...result,
    });
  } catch (error: any) {
    console.error('Geocoding error:', error);
    return NextResponse.json(
      {
        error: error.message || 'Failed to geocode address',
        success: false,
      },
      { status: 500 }
    );
  }
}

/**
 * GET - Reverse geocode coordinates
 * Converts latitude/longitude to address
 */
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const lat = searchParams.get('lat');
    const lng = searchParams.get('lng');

    if (!lat || !lng) {
      return NextResponse.json(
        { error: 'Latitude and longitude are required' },
        { status: 400 }
      );
    }

    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);

    if (isNaN(latitude) || isNaN(longitude)) {
      return NextResponse.json(
        { error: 'Invalid coordinates' },
        { status: 400 }
      );
    }

    // Reverse geocode
    const result = await reverseGeocode(latitude, longitude);

    return NextResponse.json({
      success: true,
      ...result,
    });
  } catch (error: any) {
    console.error('Reverse geocoding error:', error);
    return NextResponse.json(
      {
        error: error.message || 'Failed to reverse geocode coordinates',
        success: false,
      },
      { status: 500 }
    );
  }
}

# Geocoding Setup Guide

This guide explains how to set up geocoding to automatically convert addresses to latitude/longitude coordinates during onboarding.

## Why Geocoding?

During company setup, users enter their business address. The system automatically converts this to coordinates (lat/long) for:
- Map display
- Location-based features
- Distance calculations
- Delivery zone management

---

## Supported Providers

The system supports 3 geocoding providers with automatic fallback:

### 1. **Google Maps Geocoding API** (Recommended)
- ✅ **Most accurate** results worldwide
- ✅ Best address matching
- ✅ Detailed location data
- 💰 Pricing: $5 per 1,000 requests ($0.005/request)
- 🎁 $200 monthly credit (40,000 free requests)

### 2. **OpenCage Geocoding API** (Good Alternative)
- ✅ Good global coverage
- ✅ Simple API
- 💰 Pricing: 2,500 free requests/day, then $0.001/request
- 📦 Affordable for growing businesses

### 3. **Nominatim (OpenStreetMap)** (Free Fallback)
- ✅ **Completely free**
- ✅ No API key required
- ⚠️ Rate limited (1 request/second)
- ⚠️ Lower accuracy than paid providers
- ⚠️ Not recommended for production at scale

---

## Option 1: Use Google Maps (Recommended)

### Step 1: Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or select existing)
3. Enable the **Geocoding API**:
   - Go to **APIs & Services** → **Library**
   - Search for "Geocoding API"
   - Click **Enable**

4. Create API Key:
   - Go to **APIs & Services** → **Credentials**
   - Click **Create Credentials** → **API Key**
   - Copy the API key

5. (Optional) Restrict API Key:
   - Click on the API key to edit
   - Under **API restrictions**, select "Restrict key"
   - Choose **Geocoding API** only
   - Save

### Step 2: Add to Environment Variables

```bash
# In .env.local
GOOGLE_MAPS_API_KEY=AIzaSy...your-api-key
```

### Step 3: Test

The system will automatically use Google Maps for geocoding.

---

## Option 2: Use OpenCage (Budget-Friendly)

### Step 1: Get OpenCage API Key

1. Go to [OpenCage Geocoding](https://opencagedata.com/)
2. Sign up for a free account
3. Get your API key from the dashboard
4. Free tier: 2,500 requests/day

### Step 2: Add to Environment Variables

```bash
# In .env.local
OPENCAGE_API_KEY=your-opencage-api-key
```

---

## Option 3: Use Free Nominatim (No Setup Required)

If you don't configure any API keys, the system will **automatically use Nominatim** (OpenStreetMap's free geocoding service).

**No setup required** - it just works!

**Limitations**:
- Rate limited to 1 request per second
- Lower accuracy than paid providers
- Not suitable for high-volume production use

---

## Testing Geocoding

### Test via API

```bash
# Geocode an address
curl -X POST http://localhost:3000/api/geocoding \
  -H "Content-Type: application/json" \
  -d '{"address": "1600 Amphitheatre Parkway, Mountain View, CA"}'

# Response:
{
  "success": true,
  "latitude": 37.4224764,
  "longitude": -122.0842499,
  "formattedAddress": "1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA",
  "country": "United States",
  "city": "Mountain View",
  "provider": "google"
}
```

### Test Reverse Geocoding

```bash
# Convert coordinates to address
curl http://localhost:3000/api/geocoding?lat=37.4224764&lng=-122.0842499

# Response:
{
  "success": true,
  "latitude": 37.4224764,
  "longitude": -122.0842499,
  "formattedAddress": "1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA",
  "country": "United States",
  "city": "Mountain View",
  "provider": "google"
}
```

---

## How Provider Fallback Works

The system tries providers in this order:

1. **Google Maps** (if API key configured)
2. **OpenCage** (if API key configured)
3. **Nominatim** (free fallback, always available)

If one provider fails, it automatically tries the next one.

---

## Usage in Code

```typescript
import { geocodeAddress } from '@/lib/utils/geocoding';

// Geocode an address
const result = await geocodeAddress(
  "123 Main St, Lagos, Nigeria"
);

console.log(result);
// {
//   latitude: 6.5244,
//   longitude: 3.3792,
//   formattedAddress: "123 Main St, Lagos, Nigeria",
//   country: "Nigeria",
//   city: "Lagos",
//   provider: "google"
// }
```

---

## Cost Estimation

### Google Maps (Recommended)
- **Free tier**: $200/month credit = 40,000 requests
- **After free tier**: $5 per 1,000 requests

**Typical Usage**:
- 100 new tenant registrations/month = 100 geocoding requests
- **Cost**: $0.50/month (well within free tier)

### OpenCage
- **Free tier**: 2,500 requests/day = 75,000/month
- **After free tier**: $49/month for 10,000 requests/day

**Typical Usage**:
- 100 new tenant registrations/month
- **Cost**: FREE (within free tier)

### Nominatim (OSM)
- **Always free**
- Rate limited to 1 request/second
- Best for development and testing

---

## Recommendations

### For Development/Testing
✅ **Use Nominatim** (no setup, completely free)

### For Production (Small Scale <1000 users/month)
✅ **Use Google Maps** (most accurate, free tier is generous)

### For Production (Budget-Conscious)
✅ **Use OpenCage** (2,500 free requests/day)

### For Production (High Volume)
✅ **Use Google Maps** with API key restrictions and monitoring

---

## Troubleshooting

### Issue: "Geocoding failed with all providers"
**Solution**:
1. Check that at least one API key is configured correctly
2. Verify API keys are valid and not expired
3. Check API quota limits in provider dashboard
4. If all else fails, system will use Nominatim (free)

### Issue: "Google Maps API error: REQUEST_DENIED"
**Solution**:
1. Make sure Geocoding API is enabled in Google Cloud Console
2. Check that API key has not been restricted incorrectly
3. Verify billing is enabled on your Google Cloud project

### Issue: "Rate limit exceeded"
**Solution**:
1. For Nominatim: Wait 1 second between requests (automatic)
2. For Google/OpenCage: Check your quota in dashboard
3. Consider upgrading to paid tier or switching providers

---

## Next Steps

1. ✅ Choose a geocoding provider
2. ✅ Add API key to `.env.local` (or use free Nominatim)
3. ✅ Test via `/api/geocoding` endpoint
4. ✅ Geocoding will work automatically during company onboarding!

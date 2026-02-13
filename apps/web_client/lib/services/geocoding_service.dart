import 'package:http/http.dart' as http;
import 'dart:convert';

class GeocodingService {
  // Using OpenCage Geocoding API (free tier available)
  // Alternative: Google Maps Geocoding API
  static const String _apiKey =
      'YOUR_OPENCAGE_API_KEY'; // TODO: Add to environment variables
  static const String _baseUrl = 'https://api.opencagedata.com/geocode/v1/json';

  /// Get latitude and longitude from address
  /// Returns a map with 'latitude' and 'longitude' keys
  /// Returns null if geocoding fails
  Future<Map<String, double>?> getCoordinates({
    required String address,
    required String city,
    required String country,
  }) async {
    try {
      // Construct full address
      final fullAddress = '$address, $city, $country';

      // Make API request
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {'q': fullAddress, 'key': _apiKey, 'limit': '1'},
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final result = data['results'][0];
          final geometry = result['geometry'];

          return {
            'latitude': geometry['lat'].toDouble(),
            'longitude': geometry['lng'].toDouble(),
          };
        }
      }

      return null;
    } catch (e) {
      print('Geocoding error: $e');
      return null;
    }
  }

  /// Alternative: Mock geocoding for development/testing
  /// Returns approximate coordinates for major cities
  Future<Map<String, double>?> getMockCoordinates({
    required String city,
    required String country,
  }) async {
    // Mock data for common cities
    final mockData = {
      'Lagos_Nigeria': {'latitude': 6.5244, 'longitude': 3.3792},
      'Abuja_Nigeria': {'latitude': 9.0765, 'longitude': 7.3986},
      'London_United Kingdom': {'latitude': 51.5074, 'longitude': -0.1278},
      'New York_United States': {'latitude': 40.7128, 'longitude': -74.0060},
    };

    final key = '${city}_$country';
    return mockData[key];
  }
}

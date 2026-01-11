import 'dart:convert';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class DistanceService extends GetxService {
  // Google Distance Matrix API key
  static const String apiKey = 'REMOVED_GOOGLE_API_KEY';
  static const String baseUrl = 'https://maps.googleapis.com/maps/api/distancematrix/json';

  // Calculate distance using Haversine formula (straight-line distance in miles)
  double _calculateHaversineDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadiusKm = 6371; // Earth radius in kilometers
    const double kmToMiles = 0.621371; // Conversion factor
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final double c = 2 * math.asin(math.sqrt(a));
    final double distanceInKm = earthRadiusKm * c;
    final double distanceInMiles = distanceInKm * kmToMiles;
    
    return distanceInMiles;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }

  // Calculate distance and duration between two points
  Future<Map<String, dynamic>?> calculateDistance({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      // Check if API key is configured
      if (apiKey == 'YOUR_GOOGLE_DISTANCE_MATRIX_API_KEY' || apiKey.isEmpty) {
        print('❌ [DISTANCE SERVICE] Google Distance Matrix API key not configured');
        print('   Please set your API key in lib/services/distance_service.dart');
        return null;
      }

      // Build URL with explicit mode=driving for delivery routes (using imperial units for miles)
      final url = Uri.parse(
        '$baseUrl?origins=$originLat,$originLng&destinations=$destLat,$destLng&key=$apiKey&units=imperial&mode=driving',
      );

      print('🌍 [DISTANCE SERVICE] Calculating distance...');
      print('   Origin: ($originLat, $originLng)');
      print('   Destination: ($destLat, $destLng)');
      print('   URL: $url');

      final response = await http.get(url);

      print('📡 [DISTANCE SERVICE] Response status: ${response.statusCode}');
      print('   Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check API response status
        if (data['status'] != null) {
          print('📊 [DISTANCE SERVICE] API Status: ${data['status']}');
          
          if (data['status'] == 'OK') {
            if (data['rows'] != null && data['rows'].isNotEmpty) {
              final element = data['rows'][0]['elements'][0];
              
              if (element['status'] == 'OK') {
                // Google API returns distance in feet when using imperial units
                final distanceInFeet = element['distance']['value'] as int;
                final distanceInMiles = distanceInFeet / 5280.0; // Convert feet to miles
                final durationInSeconds = element['duration']['value'] as int;
                final durationInMinutes = (durationInSeconds / 60).round();

                print('✅ [DISTANCE SERVICE] Distance calculated successfully:');
                print('   Distance: ${distanceInMiles.toStringAsFixed(2)} miles');
                print('   Duration: $durationInMinutes minutes');

                return {
                  'distance': distanceInMiles,
                  'duration': durationInMinutes,
                };
              } else {
                print('❌ [DISTANCE SERVICE] Element status: ${element['status']}');
                if (element['status'] == 'ZERO_RESULTS') {
                  print('   No route found between the locations');
                } else if (element['status'] == 'NOT_FOUND') {
                  print('   One or both locations not found');
                }
              }
            } else {
              print('❌ [DISTANCE SERVICE] No rows in response');
            }
          } else if (data['status'] == 'REQUEST_DENIED') {
            print('⚠️ [DISTANCE SERVICE] API request denied - using fallback calculation');
            print('   Error message: ${data['error_message'] ?? 'Unknown error'}');
            print('   To enable Distance Matrix API:');
            print('   1. Go to Google Cloud Console');
            print('   2. Enable "Distance Matrix API"');
            print('   3. Or use the new Routes API');
            print('   Using Haversine formula for straight-line distance...');
            
            // Fallback: Use Haversine formula for straight-line distance
            final distanceInMiles = _calculateHaversineDistance(
              lat1: originLat,
              lon1: originLng,
              lat2: destLat,
              lon2: destLng,
            );
            
            // Estimate duration: assume average speed of 30 mph in city
            final estimatedDurationMinutes = (distanceInMiles / 30 * 60).round();
            
            print('✅ [DISTANCE SERVICE] Using fallback calculation:');
            print('   Distance: ${distanceInMiles.toStringAsFixed(2)} miles (straight-line)');
            print('   Estimated Duration: $estimatedDurationMinutes minutes');
            
            return {
              'distance': distanceInMiles,
              'duration': estimatedDurationMinutes,
            };
          } else if (data['status'] == 'OVER_QUERY_LIMIT') {
            print('⚠️ [DISTANCE SERVICE] API quota exceeded - using fallback calculation');
            
            // Fallback: Use Haversine formula
            final distanceInMiles = _calculateHaversineDistance(
              lat1: originLat,
              lon1: originLng,
              lat2: destLat,
              lon2: destLng,
            );
            
            final estimatedDurationMinutes = (distanceInMiles / 30 * 60).round();
            
            return {
              'distance': distanceInMiles,
              'duration': estimatedDurationMinutes,
            };
          } else if (data['status'] == 'INVALID_REQUEST') {
            print('❌ [DISTANCE SERVICE] Invalid request');
            print('   Error message: ${data['error_message'] ?? 'Unknown error'}');
          }
        } else {
          print('❌ [DISTANCE SERVICE] No status in response');
        }
      } else {
        print('❌ [DISTANCE SERVICE] HTTP Error: ${response.statusCode}');
        print('   Response: ${response.body}');
      }
      
      // Final fallback: Use Haversine formula if API completely fails
      print('⚠️ [DISTANCE SERVICE] Using fallback Haversine calculation...');
      final distanceInMiles = _calculateHaversineDistance(
        lat1: originLat,
        lon1: originLng,
        lat2: destLat,
        lon2: destLng,
      );
      
      final estimatedDurationMinutes = (distanceInMiles / 30 * 60).round();
      
      print('✅ [DISTANCE SERVICE] Fallback calculation:');
      print('   Distance: ${distanceInMiles.toStringAsFixed(2)} miles (straight-line)');
      print('   Estimated Duration: $estimatedDurationMinutes minutes');
      
      return {
        'distance': distanceInMiles,
        'duration': estimatedDurationMinutes,
      };
    } catch (e, stackTrace) {
      print('❌ [DISTANCE SERVICE] Exception: $e');
      print('   Stack trace: $stackTrace');
      
      // Last resort fallback
      print('⚠️ [DISTANCE SERVICE] Using Haversine fallback due to exception...');
      try {
        final distanceInMiles = _calculateHaversineDistance(
          lat1: originLat,
          lon1: originLng,
          lat2: destLat,
          lon2: destLng,
        );
        
        final estimatedDurationMinutes = (distanceInMiles / 30 * 60).round();
        
        return {
          'distance': distanceInMiles,
          'duration': estimatedDurationMinutes,
        };
      } catch (fallbackError) {
        print('❌ [DISTANCE SERVICE] Fallback calculation also failed: $fallbackError');
        return null;
      }
    }
  }

  // Calculate delivery fee based on distance (distance in miles)
  // Pricing: $25 for up to 7 miles, then $3.50 per mile after (max $35)
  double calculateDeliveryFee(double distanceInMiles) {
    double fee;
    
    // If distance is within included miles (7 miles), charge base fee only
    if (distanceInMiles <= AppConstants.includedMiles) {
      fee = AppConstants.baseFee;
    } else {
      // Base fee + additional miles beyond 7 miles
      final additionalMiles = distanceInMiles - AppConstants.includedMiles;
      fee = AppConstants.baseFee + (additionalMiles * AppConstants.ratePerMile);
    }
    
    // Apply maximum fee cap
    if (fee > AppConstants.maxFee) {
      fee = AppConstants.maxFee;
    }
    
    return double.parse(fee.toStringAsFixed(2));
  }
}





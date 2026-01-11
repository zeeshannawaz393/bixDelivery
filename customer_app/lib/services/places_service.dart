import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class PlacesService extends GetxService {
  // Google Places API key
  static const String apiKey = 'REMOVED_GOOGLE_API_KEY';
  static const String baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Search places (Autocomplete)
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    try {
      if (apiKey == 'YOUR_GOOGLE_PLACES_API_KEY' || apiKey.isEmpty) {
        print('❌ [PLACES SERVICE] API key not configured');
        return [];
      }

      if (query.isEmpty || query.length < 2) {
        print('⚠️ [PLACES SERVICE] Query too short: "$query"');
        return [];
      }

      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        '$baseUrl/autocomplete/json?input=$encodedQuery&key=$apiKey&components=country:us',
      );

      print('🔍 [PLACES SERVICE] Searching for: "$query"');
      print('   URL: ${url.toString().replaceAll(apiKey, 'API_KEY_HIDDEN')}');

      final response = await http.get(url);

      print('📡 [PLACES SERVICE] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'] as String?;
        print('   API Status: $status');
        
        if (status == 'OK' && data['predictions'] != null) {
          final predictions = List<Map<String, dynamic>>.from(data['predictions']);
          print('✅ [PLACES SERVICE] Found ${predictions.length} results');
          return predictions;
        } else if (status == 'ZERO_RESULTS') {
          print('⚠️ [PLACES SERVICE] No results found for: "$query"');
          return [];
        } else if (status == 'REQUEST_DENIED') {
          print('❌ [PLACES SERVICE] Request denied. Error: ${data['error_message'] ?? 'Unknown error'}');
          print('   Check if Places API is enabled and API key is valid');
          return [];
        } else if (status == 'INVALID_REQUEST') {
          print('❌ [PLACES SERVICE] Invalid request. Error: ${data['error_message'] ?? 'Unknown error'}');
          return [];
        } else {
          print('❌ [PLACES SERVICE] API returned status: $status');
          print('   Error message: ${data['error_message'] ?? 'No error message'}');
          return [];
        }
      } else {
        print('❌ [PLACES SERVICE] HTTP error: ${response.statusCode}');
        print('   Response body: ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      print('❌ [PLACES SERVICE] Exception during search: $e');
      print('   Stack trace: $stackTrace');
      return [];
    }
  }

  // Get place details
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      if (apiKey == 'YOUR_GOOGLE_PLACES_API_KEY' || apiKey.isEmpty) {
        print('❌ [PLACES SERVICE] API key not configured for place details');
        return null;
      }

      if (placeId.isEmpty) {
        print('⚠️ [PLACES SERVICE] Place ID is empty');
        return null;
      }

      final url = Uri.parse(
        '$baseUrl/details/json?place_id=$placeId&key=$apiKey&fields=formatted_address,geometry,name',
      );

      print('📍 [PLACES SERVICE] Getting place details for: $placeId');

      final response = await http.get(url);

      print('📡 [PLACES SERVICE] Place details response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'] as String?;
        print('   API Status: $status');
        
        if (status == 'OK' && data['result'] != null) {
          print('✅ [PLACES SERVICE] Place details retrieved successfully');
          return data['result'] as Map<String, dynamic>;
        } else {
          print('❌ [PLACES SERVICE] Failed to get place details. Status: $status');
          print('   Error message: ${data['error_message'] ?? 'No error message'}');
          return null;
        }
      } else {
        print('❌ [PLACES SERVICE] HTTP error getting place details: ${response.statusCode}');
        print('   Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ [PLACES SERVICE] Exception getting place details: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }
}

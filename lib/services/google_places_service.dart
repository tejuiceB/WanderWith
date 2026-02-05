import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_env.dart';

class GooglePlacesService {
  String get _apiKey => AppEnv.googleMapsApiKey;

  Future<Map<String, dynamic>?> searchPlace(String query) async {
    // New Places API (Text Search)
    final url = Uri.parse(
        'https://places.googleapis.com/v1/places:searchText');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          // Extract ID, Name, Location, Photos, Rating + Address & Types for better descriptions
          'X-Goog-FieldMask': 'places.id,places.displayName,places.location,places.photos,places.rating,places.formattedAddress,places.primaryType'
        },
        body: jsonEncode({
          'textQuery': query,
          'maxResultCount': 1
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['places'] != null && (data['places'] as List).isNotEmpty) {
          final place = data['places'][0];
          
          // Normalize Data for PlanProvider
          String? imageUrl;
          if (place['photos'] != null && (place['photos'] as List).isNotEmpty) {
             imageUrl = getPhotoUrl(place['photos'][0]['name']);
          }

          return {
             'place_id': place['id'],
             'name': place['displayName']?['text'] ?? query,
             'location': place['location'],
             'rating': place['rating'],
             'image_url': imageUrl,
             'address': place['formattedAddress'] ?? '',
             'type': place['primaryType'] ?? ''
          };
        }
      } else {
        print('Google Places API Error: ${response.body}');
      }
    } catch (e) {
      print('Google Places Network Error: $e');
    }
    return null;
  }

  // Construct Photo URL (This doesn't make a network call, just builds string)
  String getPhotoUrl(String photoName) {
    // photoName format is "places/PLACE_ID/photos/PHOTO_ID"
    return 'https://places.googleapis.com/v1/$photoName/media?maxHeightPx=400&maxWidthPx=400&key=$_apiKey';
  }
}

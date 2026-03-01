import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_env.dart';

class GooglePlacesService {
  String get _apiKey => AppEnv.googleMapsApiKey;

  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(String query) async {
    if (query.length < 3) return [];

    final url = Uri.parse('https://places.googleapis.com/v1/places:autocomplete');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
        },
        body: jsonEncode({
          'input': query,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['suggestions'] != null) {
          return (data['suggestions'] as List).map((s) {
            final suggestion = s['placePrediction'];
            // Normalize: Use 'place' (resource name "places/ID") if available, fallback to "places/${suggestion['placeId']}"
            String? resourceName = suggestion['place'];
            if (resourceName == null && suggestion['placeId'] != null) {
              resourceName = "places/${suggestion['placeId']}";
            }
            
            return {
              'place_id': resourceName,
              'description': suggestion['text']?['text'] ?? '',
              'main_text': suggestion['structuredFormat']?['mainText']?['text'] ?? '',
            };
          }).toList();
        }
      } else {
        print('Google Places Autocomplete Error: ${response.body}');
      }
    } catch (e) {
      print('Google Places Autocomplete Network Error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    // Robust URL construction
    String resourceName = placeId;
    if (!resourceName.startsWith('places/')) {
      resourceName = 'places/$resourceName';
    }
    
    final url = Uri.parse('https://places.googleapis.com/v1/$resourceName');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'id,displayName,location,photos,rating,formattedAddress,primaryType,editorialSummary,reviews,regularOpeningHours,currentOpeningHours,priceLevel,userRatingCount,websiteUri,internationalPhoneNumber,accessibilityOptions,parkingOptions'
        },
      );

      if (response.statusCode == 200) {
        final place = jsonDecode(response.body);
        
        String? imageUrl;
        if (place['photos'] != null && (place['photos'] as List).isNotEmpty) {
           imageUrl = getPhotoUrl(place['photos'][0]['name']);
        }

        return {
           'place_id': place['id'], // This is already "places/ID"
           'name': place['displayName']?['text'] ?? '',
           'location': place['location'],
           'rating': (place['rating'] as num?)?.toDouble(),
           'user_rating_count': place['userRatingCount'],
           'image_url': imageUrl,
           'address': place['formattedAddress'] ?? '',
           'type': place['primaryType'] ?? '',
           'summary': place['editorialSummary']?['text'] ?? '',
           'price_level': place['priceLevel'],
           'opening_hours': place['currentOpeningHours'] ?? place['regularOpeningHours'],
           'reviews': place['reviews'],
           'website': place['websiteUri'],
           'phone': place['internationalPhoneNumber'],
           'accessibility': place['accessibilityOptions'],
           'parking': place['parkingOptions'],
        };
      }
    } catch (e) {
      print('Google GetPlaceDetails Error: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> searchNearby(double lat, double lng, {double radius = 1000}) async {
    final url = Uri.parse('https://places.googleapis.com/v1/places:searchNearby');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'places.id,places.displayName,places.location,places.photos,places.rating,places.primaryType'
        },
        body: jsonEncode({
          'locationRestriction': {
            'circle': {
              'center': {'latitude': lat, 'longitude': lng},
              'radius': radius,
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['places'] != null) {
          return (data['places'] as List).map((place) {
            String? imageUrl;
            if (place['photos'] != null && (place['photos'] as List).isNotEmpty) {
               imageUrl = getPhotoUrl(place['photos'][0]['name']);
            }
            return {
              'place_id': place['id'], // This is "places/ID"
              'name': place['displayName']?['text'] ?? '',
              'location': place['location'],
              'rating': (place['rating'] as num?)?.toDouble(),
              'image_url': imageUrl,
              'type': place['primaryType'] ?? ''
            };
          }).toList();
        }
      }
    } catch (e) {
      print('Google SearchNearby Error: $e');
    }
    return [];
  }

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
  String getPhotoUrl(String photoName, {int maxWidth = 800, int maxHeight = 600}) {
    // photoName format is "places/PLACE_ID/photos/PHOTO_ID"
    return 'https://places.googleapis.com/v1/$photoName/media?maxHeightPx=$maxHeight&maxWidthPx=$maxWidth&key=$_apiKey';
  }
}

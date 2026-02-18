import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../config/app_env.dart';

class DirectionsService {
  final String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  final String _apiKey = AppEnv.googleMapsApiKey;

  Future<Map<String, dynamic>?> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    final String originStr = "${origin.latitude},${origin.longitude}";
    final String destinationStr = "${destination.latitude},${destination.longitude}";
    
    String waypointsStr = '';
    if (waypoints != null && waypoints.isNotEmpty) {
      waypointsStr = 'optimize:true|' + waypoints.map((wp) => "${wp.latitude},${wp.longitude}").join('|');
    }

    final Map<String, String> queryParams = {
      'origin': originStr,
      'destination': destinationStr,
      'key': _apiKey,
      'mode': 'driving',
    };

    if (waypointsStr.isNotEmpty) {
      queryParams['waypoints'] = waypointsStr;
    }

    final Uri uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final route = data['routes'][0];
          final polyline = route['overview_polyline']['points'];
          final List<PointLatLng> points = PolylinePoints().decodePolyline(polyline);
          
          return {
            'points': points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
            'distance': route['legs'][0]['distance']['text'],
            'duration': route['legs'][0]['duration']['text'],
            'legs': route['legs'],
          };
        } else {
          print('Directions API Error Status: ${data['status']}');
        }
      } else {
        print('Directions API HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Directions Service Error: $e');
    }
    return null;
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/station.dart';

class RouteService {
  // Translating apiRoute.js
  // Using a public routing API like OSRM or GraphHopper (as seen in config.js)
  final String _baseUrl = "https://router.project-osrm.org/route/v1/driving";

  Future<List<RouteStep>> getRoute(double startLat, double startLng, double endLat, double endLng) async {
    final url = "$_baseUrl/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson&steps=true";
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List;
        if (routes.isEmpty) return [];
        
        final legs = routes[0]['legs'] as List;
        final steps = legs[0]['steps'] as List;
        
        return steps.map((step) {
          return RouteStep(
            instruction: step['maneuver']['instruction'] ?? 'Continue',
            distance: (step['distance'] as num).toDouble(),
            duration: (step['duration'] as num).toInt(),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint("Route Error: $e");
    }
    return [];
  }
}

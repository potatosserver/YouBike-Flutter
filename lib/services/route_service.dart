import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteStep {
  final String instruction;
  final double distance;
  final double duration;
  final int sign; // GraphHopper sign for icons

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.sign,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    return RouteStep(
      instruction: json['text'] ?? '',
      distance: (json['distance'] as num).toDouble(),
      duration: (json['time'] as num).toDouble(),
      sign: json['sign'] ?? 0,
    );
  }
}

class RouteService {
  // 使用 GraphHopper API (同步網頁版)
  static const String baseUrl = "https://graphhopper.com/api/1/route";
  static const String apiKey = "7cb4eb19-e0f4-40a3-a5e0-f2c039366f32"; // Synchronized from Web production

  Future<List<RouteStep>> getRoute(LatLng start, LatLng end, String lang) async {
    final locale = lang == 'en' ? 'en' : 'zh-TW';
    const profile = 'foot';
    
    final url = "${RouteService.baseUrl}?profile=$profile&locale=$locale&key=${RouteService.apiKey}&elevation=false&instructions=true&point=${start.latitude},${start.longitude}&point=${end.latitude},${end.longitude}";
    
    
    
    
    

    try {
      final response = await http.get(Uri.parse(url));
      
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['paths'] != null && (data['paths'] as List).isNotEmpty) {
          final steps = data['paths'][0]['instructions'] as List;
          
          return steps.map((s) => RouteStep.fromJson(s)).toList();
        } else {
          
        }
      } else if (response.statusCode == 401) {
        
        throw Exception("ROUTE_AUTH_FAILED");
      } else {
        
        throw Exception("ROUTE_API_ERROR");
      }
    } catch (e) {
      
    }
    return [];
  }
}

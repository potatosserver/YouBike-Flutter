import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/station.dart';

class ApiService {
  final String stationsUrl = "https://apis.youbike.com.tw/json/station-min-yb2.json";
  final String vehicleUrl = "https://apis.youbike.com.tw/json/vehicle-min-yb2.json";

  // 翻譯自 apiYoubike.js: fetchBaseStationData
  Future<List<Station>> fetchAllStations() async {
    final response = await http.get(Uri.parse(stationsUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Station.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load station base data');
    }
  }

  // 翻譯自 apiYoubike.js: queryVehicleData
  Future<Map<String, dynamic>> fetchRealtimeVehicles() async {
    final response = await http.get(Uri.parse(vehicleUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load real-time vehicle data');
    }
  }
}

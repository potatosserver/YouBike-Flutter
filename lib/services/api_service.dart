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
      
      // 使用容錯解析：過濾掉所有返回 null 的無效站牌
      return data
          .map((json) => Station.fromJson(json as Map<String, dynamic>))
          .whereType<Station>() 
          .toList();
    } else {
      throw Exception('Failed to load station base data: ${response.statusCode}');
    }
  }

  // 翻譯自 apiYoubike.js: queryVehicleData
  Future<Map<String, dynamic>> fetchRealtimeVehicles() async {
    final response = await http.get(Uri.parse(vehicleUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load real-time vehicle data: ${response.statusCode}');
    }
  }
}

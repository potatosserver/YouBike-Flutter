import 'dart:convert';
import 'dart:async';
import 'package:youbike/core/utils/log_service.dart';

import 'package:http/http.dart' as http;
import 'package:youbike/data/models/station.dart';

class ApiService {
  final String stationsUrl =
      "https://apis.youbike.com.tw/json/station-min-yb2.json";
  final String vehicleUrl =
      "https://apis.youbike.com.tw/json/vehicle-min-yb2.json";
  final http.Client? client;

  ApiService({this.client});

  http.Client get _client => client ?? http.Client();

  // 全局 API 超時設定
  static const Duration defaultTimeout = Duration(seconds: 10);
  // 基礎數據量大 (4MB+)，給予更寬裕的超時
  static const Duration baseDataTimeout = Duration(seconds: 30);

  Future<List<Station>> fetchAllStations() async {
    try {
      // 使用更長的超時時間以應對大文件下載
      final response =
          await _client.get(Uri.parse(stationsUrl)).timeout(baseDataTimeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) => Station.fromJson(json as Map<String, dynamic>))
            .whereType<Station>()
            .toList();
      } else {
        throw Exception(
            'Failed to load station base data: ${response.statusCode}');
      }
    } on TimeoutException catch (_) {
      throw TimeoutException(
          'API Request timed out while fetching stations (30s limit)');
    }
  }

  Future<Map<String, dynamic>> fetchRealtimeVehicles(
      List<String> stationIds) async {
    if (stationIds.isEmpty) return {};

    /// Each POST body should hold at most 20 station_no entries.
    /// The real reason is two-fold:
    ///  1. The /tw2/parkingInfo server paginates its `data` response at
    ///     `per_page=20` — any single call only ever returns the first 20
    ///     matching rows from its station list, even if you ask for more.
    ///  2. We've measured a hard ceiling somewhere around N=50 station_no
    ///     entries that the same endpoint rejects with HTTP 422.
    /// Slicing into 20-entry chunks upstream turns "one big silent
    /// truncation" into "N small complete pages" — every chunk lines up
    /// with the server's natural page size.
    const batchSize = 20;
    Map<String, dynamic> allVehicleData = {};

    final url = Uri.parse('https://apis.youbike.com.tw/tw2/parkingInfo');
    final headers = {
      'Accept': '*/*',
      'Content-Type': 'application/json',
      'Origin': 'https://www.youbike.com.tw',
      'Referer': 'https://www.youbike.com.tw/',
    };

    for (var i = 0; i < stationIds.length; i += batchSize) {
      final batch = stationIds.sublist(
          i,
          i + batchSize > stationIds.length
              ? stationIds.length
              : i + batchSize);

      try {
        final response = await _client
            .post(
              url,
              headers: headers,
              body: jsonEncode({'station_no': batch}),
            )
            .timeout(defaultTimeout);

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (result['retCode'] == 1 &&
              result['retVal'] != null &&
              result['retVal']['data'] != null) {
            final List<dynamic> data = result['retVal']['data'];
            for (var item in data) {
              final stationNo = item['station_no'].toString();
              final detail = item['available_spaces_detail'];
              allVehicleData[stationNo] = {
                'available_2_0': detail != null ? detail['yb2'] : null,
                'available_e': detail != null ? detail['eyb'] : null,
                'empty_spaces': item['empty_spaces'],
              };
            }
          } else {
            LogService().w('API', 'Invalid retCode from server');
          }
        } else {
          LogService().e('API', 'HTTP ${response.statusCode}');
        }
      } catch (e) {
        LogService().e('API', 'Batch request failed', error: e);
      }
    }
    return allVehicleData;
  }

  Future<List<Map<String, dynamic>>> fetchElectricBikeDetails(
      String stationId) async {
    final url = Uri.parse(
        'https://apis.youbike.com.tw/api/front/bike/lists?station_no=$stationId');
    final headers = {
      'Accept': '*/*',
      'Accept-Language': 'zh-TW,zh;q=0.9',
      'Origin': 'https://www.youbike.com.tw',
      'Referer': 'https://www.youbike.com.tw/',
    };

    try {
      final response =
          await _client.get(url, headers: headers).timeout(defaultTimeout);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['retCode'] == 1 && result['retVal'] != null) {
          return List<Map<String, dynamic>>.from(result['retVal']);
        }
      }
    } catch (e) {
      LogService().e('API', 'Electric bike request failed', error: e);
    }
    return [];
  }
}

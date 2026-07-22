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

  /// 單站即時車輛查詢（給「點圖釘自己發」）。
  /// 內部走同一條 /tw2/parkingInfo 主路，路徑與 batch 完全一致。
  /// 回 null 表示 server 該站沒回資料（retCode!=1 / 非 200 / 解析失敗 / 型別不對）。
  Future<Map<String, int>?> fetchRealtimeVehicle(String stationId) async {
    if (stationId.trim().isEmpty) return null;
    try {
      final batch = await fetchRealtimeVehicles([stationId]);
      final raw = batch[stationId];
      if (raw is! Map) return null;
      int? readInt(String key) {
        final v = raw[key];
        if (v is num) return v.toInt();
        if (v is String) return int.tryParse(v);
        return null;
      }

      final yb2 = readInt('available_2_0');
      final eyb = readInt('available_e');
      final empty = readInt('empty_spaces');
      // 三個欄位都抓不到時才回 null，避免 caller 誤判為「該站賣光」。
      if (yb2 == null && eyb == null && empty == null) return null;
      return {
        'available_2_0': yb2 ?? 0,
        'available_e': eyb ?? 0,
        'empty_spaces': empty ?? 0,
      };
    } catch (e) {
      LogService().e('API', 'Single-station realtime request failed',
          error: e);
      return null;
    }
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

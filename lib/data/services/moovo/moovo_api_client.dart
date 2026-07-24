import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:youbike/data/models/moovo_station.dart';

/// Moovo 全部 api 操作都共用同一個輕量 http client,風格與既有 `ApiService` 一致。
class MoovoApiClient {
  static const Duration _timeout = Duration(seconds: 10);

  final http.Client? client;
  final String baseUrl;

  MoovoApiClient({this.client, this.baseUrl = 'https://api.moovmobility.co'});

  http.Client get _client => client ?? http.Client();

  /// 拉某個城市底下的所有 「物理停車點」,並做「bikeCommonParkingId」聚合。
  ///
  /// **API 行為 2026-07 (user-confirmed)**:URL 必須帶
  /// `vehicleType=bike%2Cebike` 才能拿到「完整資訊」(i18n.name.en、
  /// i18n.address.zhTw 等中英文欄位)。不帶 vehicleType 或帶 `withCache=true`
  /// 仍會回 rows、但欄位不一致 — 使用者已警告過一次。
  ///
  /// **已知限制**:`i18n` 對少部份站 (例如「埤頭繪本公園」) 是 server-side null,
  /// 不論哪種 URL 都一樣;卡片 UI 端用「—」 fallback。
  /// - 同一 `commonId` 多筆:把 ebike / bike 數量各加總,`nearbyBikeCount` 同進入口、
  ///   但 server side `vehicleType=bike%2Cebike` 看起來只回 ebike row; 為
  ///   robustness 仍保留 bike branch。
  /// - i18n 「第一筆勝出」,address 採同樣規則。
  /// - `maxCapacity` 為 null 時預設 30。
  /// - 整體失敗回 null。
  Future<List<MoovoStation>?> fetchStationsForCity(int cityId) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/bike/getParkingPointByCity'
        '?cityId=$cityId&vehicleType=bike%2Cebike',
      );
      final res = await _client.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      // true 為可 debug。如需關閉刪除即可。
      if (body is Map<String, dynamic> && body['code'] != null && body['code'] != 1000) {
        return null;
      }
      if (body is! Map<String, dynamic>) return null;
      final raw = body['data'];
      if (raw is! List) return null;

      final aggregated = <String, _MutableMoovo>{};
      for (final item in raw.whereType<Map<String, dynamic>>()) {
        final commonId = item['bikeCommonParkingId'];
        final lat = item['lat'];
        final lon = item['lon'];
        final key = commonId != null
            ? 'c$commonId'
            : 'p${(item['name'] ?? '')}_${(lat as num).toDouble().toStringAsFixed(5)}_${(lon as num).toDouble().toStringAsFixed(5)}';

        var entry = aggregated[key];
        if (entry == null) {
          final parsed = _parseI18n(item['i18n']);
          entry = _MutableMoovo(
            commonId: commonId is num ? commonId.toInt() : null,
            cityId: cityId,
            name: (item['name'] as String?) ?? '',
            lat: (lat as num).toDouble(),
            lon: (lon as num).toDouble(),
            radius: (item['radius'] as num).toDouble(),
            nameZhTw: parsed['name-zhTw'] ?? (item['name'] as String?) ?? '',
            nameEn: parsed['name-en'] ?? '',
            address: parsed['address-zhTw'],
            maxCapacity: item['maxCapacity'] is num
                ? (item['maxCapacity'] as num).toInt()
                : null,
          );
          aggregated[key] = entry;
        }

        // 直接用 API 給的 `nearbyBikeCount`(該站該車型的車口數)加總成
        //  [MoovoStation.bikeCount] 作為使用者看到的「可借車輛數」總計。
        // 原因: 不在這邊按 vehicleType 區分、者不會 「該站 bike + ebike 手劰 議」 get 0。
        // 對使用者來說、 「騎 are 補的車口數」 比 「bike/ebike 分類」更實用。
        final count = (item['nearbyBikeCount'] as num?)?.toInt() ?? 0;
        entry.bikeCount += count;
      }

      return aggregated.values.map((m) {
        final cap = m.maxCapacity;
        final fallback = cap == null;
        return MoovoStation(
          id: 'mv:${m.commonId ?? '${m.lat.toStringAsFixed(5)}_${m.lon.toStringAsFixed(5)}'}',
          nameTw: m.nameZhTw.isNotEmpty ? m.nameZhTw : m.name,
          nameEn: m.nameEn.isNotEmpty ? m.nameEn : m.name,
          lat: m.lat,
          lon: m.lon,
          radius: m.radius,
          bikeCount: m.bikeCount,
          ebikeCount: m.ebikeCount,
          maxCapacity: cap ?? 30,
          maxCapacityIsFallback: fallback,
          address: m.address,
        );
      }).toList();
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _parseI18n(dynamic raw) {
    final out = <String, String>{};
    if (raw is! String || raw.isEmpty) return out;
    try {
      final decoded = jsonDecode(raw);
      // Moovo『i18n』 真實 schema 為:
      //   {"name": {"en": "...", "zhTw": "..."}, "address": {"zhTw": "640雲林縣..."}}
      // 注意 top-level API 仍給出 `address: null`(依舊不準,空殼),
      // 真實中文地址只會透過 `i18n.address.zhTw` 走進來 — 為此保留它。
      if (decoded is! Map<String, dynamic>) return out;
      final name = decoded['name'];
      if (name is Map<String, dynamic>) {
        final en = name['en'];
        if (en is String) out['name-en'] = en;
        final zhTw = name['zhTw'];
        if (zhTw is String) out['name-zhTw'] = zhTw;
      }
      final address = decoded['address'];
      if (address is Map<String, dynamic>) {
        final zhTw = address['zhTw'];
        if (zhTw is String) out['address-zhTw'] = zhTw;
      }
    } catch (_) {
      // 解析失敗就保留空 map
    }
    return out;
  }
}

class _MutableMoovo {
  final int? commonId;
  final int cityId;
  final String name;
  final double lat;
  final double lon;
  final double radius;
  final String nameZhTw;
  final String nameEn;
  final String? address;
  int? maxCapacity;

  int bikeCount = 0;
  int ebikeCount = 0;

  _MutableMoovo({
    required this.commonId,
    required this.cityId,
    required this.name,
    required this.lat,
    required this.lon,
    required this.radius,
    required this.nameZhTw,
    required this.nameEn,
    required this.address,
    required this.maxCapacity,
  });
}

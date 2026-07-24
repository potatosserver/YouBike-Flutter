import 'package:flutter/foundation.dart';
import 'package:youbike/data/models/moovo_station.dart';
import 'package:youbike/data/models/station.dart';

/// 多源自行車站點的「統一視圖」 item — 用於面板混合清單的單一資料結構。
///
/// 不污染 YouBike `Station` 或 Moovo `MoovoStation`,只在選擇/排序階段
/// 把它們裝進同一個 list。
enum StationSource { youbike, moovo }

@immutable
class BikeStationItem {
  final StationSource source;
  final String id;
  final String name;
  final String? address;
  final double lat;
  final double lng;
  final int? bikeCount;
  final int? eBikeCount;
  final int? emptySpaces;
  final double distance;

  const BikeStationItem({
    required this.source,
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.bikeCount,
    required this.eBikeCount,
    required this.emptySpaces,
    required this.distance,
  });

  /// 從 YouBike [Station] 轉換。address 依當前語系挑。
  factory BikeStationItem.fromStation(Station s, {String lang = 'zh_TW'}) {
    return BikeStationItem(
      source: StationSource.youbike,
      id: s.id,
      name: lang.startsWith('en') ? s.nameEn : s.nameTw,
      address: lang.startsWith('en') ? s.addressEn : s.addressTw,
      lat: s.lat,
      lng: s.lng,
      bikeCount: s.availableBikes,
      eBikeCount: s.availableElectricBikes,
      emptySpaces: s.emptySpaces,
      distance: s.distance,
    );
  }

  /// 從 Moovo [MoovoStation] 轉換。注意 Moovo 沒有英文 / 中文兩套，
  /// `name` 直接用該 instance 的函式,address 為 nullable。
  factory BikeStationItem.fromMoovo(MoovoStation s, {String lang = 'zh_TW'}) {
    return BikeStationItem(
      source: StationSource.moovo,
      id: s.id,
      name: s.displayName(lang),
      address: s.address,
      lat: s.lat,
      lng: s.lon,
      bikeCount: s.bikeCount,
      eBikeCount: s.ebikeCount,
      emptySpaces: s.emptySpaces,
      distance: s.distance,
    );
  }
}

/// 為何分離 `mixer` 與 YouBike 既有 `StationSorter`:
/// - `StationSorter` 專注「YouBike-only」,已跟 `CardRefreshCoordinator` 結合。
/// - `BikeStationMixer` 專注「跨源混排」,純函式、可由 search_panel 直接呼叫。
class BikeStationMixer {
  const BikeStationMixer();

  /// 距離升序排序後取前 [limit] 名。
  ///
  /// [youbike] 為可空 — 若為 null/空,則排序只跑在 [moovo] 上。
  /// [moovo] 同上。允許兩邊其一為空集合(例如使用者關掉其中一個來源)。
  List<BikeStationItem> topNByDistance({
    required List<Station> youbike,
    required List<MoovoStation> moovo,
    required int limit,
    String lang = 'zh_TW',
  }) {
    final out = <BikeStationItem>[];
    for (final s in youbike) {
      out.add(BikeStationItem.fromStation(s, lang: lang));
    }
    for (final s in moovo) {
      out.add(BikeStationItem.fromMoovo(s, lang: lang));
    }
    out.sort((a, b) => a.distance.compareTo(b.distance));
    if (out.length <= limit) return out;
    return out.sublist(0, limit);
  }

  /// 搜尋過濾 + 距離排序兩來源後取前 [limit] 名。
  ///
  /// 為何不用 `StationSorter.sortAndPick`:後者只吃 `Station`,
  /// 我們需同時對 Moovo 跑同名匹配、地址匹配,所以在「跨源」helper 內重做一次。
  /// 重複 id 自動去重(預期是 0;若 caller 傳混合 col 則保險)。
  List<BikeStationItem> searchAcross({
    required List<Station> youbike,
    required List<MoovoStation> moovo,
    required String query,
    required int limit,
    String lang = 'zh_TW',
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return topNByDistance(
        youbike: youbike,
        moovo: moovo,
        limit: limit,
        lang: lang,
      );
    }
    final out = <BikeStationItem>[];
    for (final s in youbike) {
      if (_matchStation(s, q)) {
        out.add(BikeStationItem.fromStation(s, lang: lang));
      }
    }
    for (final s in moovo) {
      if (_matchMoovo(s, q)) {
        out.add(BikeStationItem.fromMoovo(s, lang: lang));
      }
    }
    out.sort((a, b) => a.distance.compareTo(b.distance));
    if (out.length <= limit) return out;
    return out.sublist(0, limit);
  }

  bool _matchStation(Station s, String q) {
    return s.nameTw.toLowerCase().contains(q) ||
        s.nameEn.toLowerCase().contains(q) ||
        s.addressTw.toLowerCase().contains(q) ||
        s.addressEn.toLowerCase().contains(q);
  }

  bool _matchMoovo(MoovoStation s, String q) {
    if (s.nameTw.toLowerCase().contains(q)) return true;
    if (s.nameEn.toLowerCase().contains(q)) return true;
    final addr = s.address;
    if (addr != null && addr.toLowerCase().contains(q)) return true;
    return false;
  }
}

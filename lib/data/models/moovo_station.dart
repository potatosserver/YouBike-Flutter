import 'package:latlong2/latlong.dart';

/// Moovo 站點聚合後的單一筆。
///
/// 真實 API 回傳的「物理停車點」每筆只代表「虛擬圍籬內的一個車輛子集」
/// (`vehicleType` 為 `bike` 或 `ebike`),多筆共用同 `bikeCommonParkingId`
/// 屬於**同一個**站點 — 聚合後的 station 才能對外呈現。
class MoovoStation {
  /// 對外唯一 id。前綴 `mv:` 與 YouBike 區隔,方便共用 `pinnedStationIds` set。
  final String id;
  final String nameTw;
  final String nameEn;
  final double lat;
  final double lon;
  final double radius;
  final int bikeCount;
  final int ebikeCount;
  final int maxCapacity;

  /// 真實「物理最大容量」可能為 null — 此欄位已 fallback 成合理預設。
  final bool maxCapacityIsFallback;

  /// 對應 i18n.address.zhTw — 提供 view 端判斷是否顯示地址。
  /// null = API 沒給此字典(舊式 names 但無 address)。
  final String? address;

  /// 距離 (公尺)。由「地圖中心 / GPS」 ref point 在排序階段計算後注入。
  /// 型別為「輕量可變」，因為 Moovo 距離會隨 useLocation / mapMoveTrigger 改變。
  double distance;

  MoovoStation({
    required this.id,
    required this.nameTw,
    required this.nameEn,
    required this.lat,
    required this.lon,
    required this.radius,
    required this.bikeCount,
    required this.ebikeCount,
    required this.maxCapacity,
    required this.maxCapacityIsFallback,
    this.address,
    this.distance = 0.0,
  });

  LatLng get position => LatLng(lat, lon);

  int get totalBikes => bikeCount + ebikeCount;

  /// 還車空位估算 — Moovo 是電子圍籬無樁,以 maxCapacity - 現存單車估算。
  int get emptySpaces {
    final capacity = maxCapacity;
    final total = totalBikes;
    if (capacity <= total) return 0;
    return capacity - total;
  }

  bool get hasEbike => ebikeCount > 0;

  String displayName(String lang) => lang.startsWith('en') ? nameEn : nameTw;
}

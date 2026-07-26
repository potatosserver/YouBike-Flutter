import 'package:latlong2/latlong.dart';

import 'station.dart';
import 'moovo_station.dart';

/// 共用腳踏車站點介面 — 從「YouBike + Moovo 多源」屏蔽後回傳的單一視圖型別。
///
/// Step 1 設計範圍 (取最小可驗證範圍):
/// - [BikeStationSource] 你 / Moovo 的來源識別 (視覺線索、後續擴充標籤用)。
/// - [BikeStation] 共用契約欄位。
/// - [`Station.toBike()`] / [`MoovoStation.toBike()`] 的 adapter 擴充方法。
///
/// 一律**不動**:
/// - `Station` / `MoovoStation` 的既有寫入/序列化行為。
/// - `StationViewModel` / `MoovoViewModel` / 任何 VM。
/// - `BikeStationMixer` / `StationSorter` / 任何 UI 端。
///
/// 這一步只允許導入「新檔案」與「兩 model 加 toBike()」。下一步才會集中距離計算等。
enum BikeStationSource { youbike, moovo }

abstract class BikeStation {
  /// 對外唯一 id。YouBike 用 station_no;Moovo 已是 `mv:` 前綴。
  String get id;

  /// 兩語系名稱。YouBike 兩欄皆有;Moovo 兩語可能 fallback 同一字串。
  String get nameTw;
  String get nameEn;

  /// 經緯度。
  double get lat;
  double get lng;

  /// 地址。YouBike 兩語齊備;Moovo server 給中文地址,英文為 null。
  String? get addressTw;
  String? get addressEn;

  /// 即時車口數。對 YouBike 多為 server 即時;對 Moovo 為一次 fetch 帶回。
  int? get bikeCount;
  int? get eBikeCount;
  int? get emptySpaces;

  /// 距離 (公尺),由排序階段依參考點計算後回填。
  double get distance;
  set distance(double v);

  /// Marker 唯一 key 用的前綴 (為 [ClusteredMarkerLayer] 隔離兩源)。檢視端用。
  String get sourceKey;

  /// 來源識別。視覺線索與後續擴充需要。
  BikeStationSource get source;

  /// 轉回本來的 [Station]，供內層仍然需要 Station 的邏輯使用。
  /// 唯 [source] == [BikeStationSource.youbike] 時可用。
  Station? get rawStation;
}

class _StationBikeStation implements BikeStation {
  _StationBikeStation(this._s);

  final Station _s;

  @override
  String get id => _s.id;
  @override
  String get nameTw => _s.nameTw;
  @override
  String get nameEn => _s.nameEn;
  @override
  double get lat => _s.lat;
  @override
  double get lng => _s.lng;
  @override
  String? get addressTw => _s.addressTw.isEmpty ? null : _s.addressTw;
  @override
  String? get addressEn => _s.addressEn.isEmpty ? null : _s.addressEn;
  @override
  int? get bikeCount => _s.availableBikes;
  @override
  int? get eBikeCount => _s.availableElectricBikes;
  @override
  int? get emptySpaces => _s.emptySpaces;
  @override
  double get distance => _s.distance;
  @override
  set distance(double v) => _s.distance = v;
  @override
  String get sourceKey => 'st_${_s.id}';
  @override
  BikeStationSource get source => BikeStationSource.youbike;

  /// 底層寫入型別偶爾仍需要;e.g. realtime 寫入。
  Station get raw => _s;

  @override
  Station? get rawStation => _s;
}

class _MoovoBikeStation implements BikeStation {
  _MoovoBikeStation(this._s);

  final MoovoStation _s;

  @override
  String get id => _s.id;
  @override
  String get nameTw => _s.nameTw;
  @override
  String get nameEn => _s.nameEn;
  @override
  double get lat => _s.lat;
  @override
  double get lng => _s.lon;
  @override
  String? get addressTw => _s.address;
  @override
  String? get addressEn => _s.address;
  @override
  int? get bikeCount => _s.bikeCount;
  @override
  int? get eBikeCount => _s.ebikeCount;
  @override
  int? get emptySpaces => _s.emptySpaces;
  @override
  double get distance => _s.distance;
  @override
  set distance(double v) => _s.distance = v;
  @override
  String get sourceKey => 'mv_${_s.id}';
  @override
  BikeStationSource get source => BikeStationSource.moovo;

  /// 底層寫入型別偶爾仍需要。
  MoovoStation get raw => _s;

  @override
  Station? get rawStation => null;
}

// ── Adapters ──────────────────────────────────────────────

extension BikeStationFromStation on Station {
  /// 從 YouBike [Station] 轉 [BikeStation]。
  /// 不複製 — 內部直接持 `this`,因此 mutate `distance` 仍會同步到底層。
  BikeStation toBike() => _StationBikeStation(this);
}

extension BikeStationFromMoovo on MoovoStation {
  /// 從 Moovo [MoovoStation] 轉 [BikeStation]。
  /// 不複製 — 內部直接持 `this`,因此 mutate `distance` 仍會同步到底層。
  BikeStation toBike() => _MoovoBikeStation(this);
}

extension BikeStationListFromStation on Iterable<Station> {
  /// 批次轉換,給 Repository facade 用。
  List<BikeStation> toBikes() => [for (final s in this) s.toBike()];
}

extension BikeStationListFromMoovo on Iterable<MoovoStation> {
  /// 批次轉換,給 Repository facade 用。
  List<BikeStation> toBikes() => [for (final s in this) s.toBike()];
}

/// 共用 LatLng helper,避免呼叫端個別 import latlong。
LatLng bikeStationPoint(BikeStation s) => LatLng(s.lat, s.lng);

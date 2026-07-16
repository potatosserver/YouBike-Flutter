import 'package:youbike/core/utils/log_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:youbike/providers/map_view_model.dart';

/// GPS 請求與位置解析的唯一入口。
///
/// 用法：
///   final pos = await gpsRequester.request(mapVm);
///   if (pos != null) { ... }
class GpsRequester {
  const GpsRequester();

  /// 請求 GPS 權限與位置，回傳解析後的座標。
  /// GPS 不可用或被拒時回傳 null。
  /// 內部透過 [mapVm.getEffectiveLocation] 回退至區域中心，
  /// 但仍回傳 null 明確表示 GPS 失敗。
  Future<LatLng?> request(MapViewModel mapVm) async {
    try {
      await mapVm.requestAndCenterLocation();
      // requestAndCenterLocation 成功則 lastKnownLocation 已設置；仍為 null 表示 GPS 失敗，呼叫方自行決定回退
      return mapVm.lastKnownLocation;
    } catch (e) {
      LogService().e('GPS', 'Request failed', error: e);
      return null;
    }
  }

  /// 便利方法：永遠回傳 LatLng（不為 null）。
  /// GPS 可用時回 GPS，否則回退至區域中心。
  Future<LatLng> requestOrFallback(MapViewModel mapVm) async {
    final gps = await request(mapVm);
    return gps ?? mapVm.getEffectiveLocation();
  }
}

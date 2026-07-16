import 'package:latlong2/latlong.dart';
import 'package:youbike/providers/map_view_model.dart';

/// 解析參考座標。委派給 MapViewModel，
/// 內部遵循 config.useLocation 設定。
class LocationResolver {
  const LocationResolver();

  LatLng resolve(MapViewModel mapVm) => mapVm.getEffectiveLocation();
}

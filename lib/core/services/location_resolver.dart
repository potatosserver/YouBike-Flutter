import 'package:latlong2/latlong.dart';
import 'package:youbike_android/providers/map_view_model.dart';

/// Resolves the reference point: GPS → selected region center.
class LocationResolver {
  const LocationResolver();

  LatLng resolve(MapViewModel mapVm) => mapVm.getEffectiveLocation();
}
import 'package:latlong2/latlong.dart';
import 'package:youbike_android/providers/map_view_model.dart';

/// Resolves the reference point. Delegates to MapViewModel which
/// respects config.useLocation internally.
class LocationResolver {
  const LocationResolver();

  LatLng resolve(MapViewModel mapVm) => mapVm.getEffectiveLocation();
}
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Thin wrapper around MapController so the coordinator doesn't touch UI details.
class MapMoveTrigger {
  MapController? _controller;

  void attach(MapController controller) => _controller = controller;

  void fire(LatLng position, {double zoom = 18.0}) {
    _controller?.move(position, zoom);
  }
}
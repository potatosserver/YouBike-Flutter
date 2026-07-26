import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:youbike/core/services/map_animated_move.dart';

/// MapController 薄封裝 — 同時兼任「ref point 廣播」角色。
class MapMoveTrigger {
  MapController? _controller;

  /// 當前可見中心點。`attach(controller)` 之後由 `onMoveEnd` 更新。
  LatLng? refPoint;
  final List<VoidCallback> _listeners = [];

  /// Attach controller — but DO NOT touch camera here. Web FlutterMap
  /// can throw "controller not rendered yet" if you read `camera.center`
  /// before the first onMapReady event.
  void attach(MapController controller) {
    _controller = controller;
    // Hand-off camera center via postFrame to safely avoid the
    // "rendered at least once" precondition.
    Future<void>.delayed(Duration.zero, () {
      if (identical(controller, _controller)) {
        final initial = controller.camera.center;
        if (refPoint == null ||
            refPoint!.latitude != initial.latitude ||
            refPoint!.longitude != initial.longitude) {
          refPoint = initial;
        }
      }
    });
    controller.mapEventStream.listen((event) {
      if (event is MapEventMoveEnd) {
        final c = event.camera.center;
        if (refPoint == null ||
            refPoint!.latitude != c.latitude ||
            refPoint!.longitude != c.longitude) {
          refPoint = c;
          for (final l in List<VoidCallback>.from(_listeners)) {
            l();
          }
        }
      }
    });
  }

  void addListener(VoidCallback l) => _listeners.add(l);
  void removeListener(VoidCallback l) => _listeners.remove(l);

  void attachStrategy(MapMoveStrategy Function()? factory) {
    _strategy = factory?.call();
  }

  MapMoveStrategy? _strategy;

  void fire(LatLng position, {double zoom = 18.0}) {
    if (_strategy != null) {
      _strategy!.moveTo(position, zoom: zoom);
      return;
    }
    _controller?.move(position, zoom);
  }
}
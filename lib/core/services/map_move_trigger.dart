import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:youbike/core/services/map_animated_move.dart';

/// MapController 薄封裝 — 同時兼任「ref point 廣播」角色。
///
/// 任何需要在「地圖中心 / 視覺中心」改變時拿座標的 consumer
/// (例如 `MoovoViewModel`、未來其他自行車系統) 都可以訂閱 [Listener] 介面。
class MapMoveTrigger {
  MapController? _controller;

  /// 當前可見中心點。`attach(controller)` 之後由 `onMoveEnd` 更新。
  LatLng? refPoint;
  final List<VoidCallback> _listeners = [];

  void attach(MapController controller) {
    _controller = controller;

    // Boot 時主動把 refPoint 設為 controller 當前中心 —
    // 避免「開 app 第一眼距離全是 0」(要在 user 動畫地圖時才有值)。
    final initial = controller.camera.center;
    if (refPoint == null ||
        refPoint!.latitude != initial.latitude ||
        refPoint!.longitude != initial.longitude) {
      refPoint = initial;
    }

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

  /// Optional animated strategy. When set, `fire` delegates to the strategy's
  /// `moveTo`, otherwise falls back to instant `_controller?.move(...)`.
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
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

  /// Attach controller — 但完全不碰 camera。第一次 camera 讀取須由
  /// 呼叫端在 `onMapReady` 之後用 `setReady()` 觸發。
  ///
  /// 原因：FlutterMap 在 Web 平台必須先渲染至少一幀後，controller.camera
  /// 才能被讀取，否則拋 "rendered at least once" 例外。
  void attach(MapController controller) {
    _controller = controller;
    _ready = false;
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

  bool _ready = false;
  bool get ready => _ready;

  /// 應在 `FlutterMap.onMapReady` 之後呼叫 — 此時 controller.camera 才可用。
  /// 順手把當前中心設為 refPoint 並標記 ready，後續 listener 即可執行。
  void setReady() {
    if (_ready) return;
    final ctrl = _controller;
    if (ctrl == null) return;
    _ready = true;
    try {
      final c = ctrl.camera.center;
      if (refPoint == null ||
          refPoint!.latitude != c.latitude ||
          refPoint!.longitude != c.longitude) {
        refPoint = c;
      }
    } catch (_) {
      // 仍保險補一下：若 camera 尚未就緒，視為未 ready，下次可重試。
      _ready = false;
      rethrow;
    }
  }

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
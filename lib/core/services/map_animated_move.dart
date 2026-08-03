import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Abstract interface for any "move the map camera" worker.
///
/// Used by `MapMoveTrigger.fire(...)` so the actual move can either be
/// animated (via [AnimatedMapController]) or instantaneous (default).
abstract class MapMoveStrategy {
  void moveTo(LatLng position, {double zoom = 18.0});
}

/// 純函數 helper：依照兩點之間的距離，回傳 camera 動畫應該用多久。
///
/// ≤200m → 200ms（最短滑動）
/// ≥1500m → Duration.zero（直接跳，不值得動畫）
/// 200m–1500m → 線性內插 200ms → 500ms
class MapAnimatedMove {
  static const double nearMaxMeters = 200.0;
  static const double farMinMeters = 1500.0;
  static const Duration nearDuration = Duration(milliseconds: 200);
  static const Duration midDuration = Duration(milliseconds: 500);

  static double metersBetween(LatLng a, LatLng b) {
    return const Distance().as(LengthUnit.Meter, a, b);
  }

  static Duration durationForMeters(double meters) {
    if (meters <= 0 || meters.isNaN || meters.isInfinite) {
      return Duration.zero;
    }
    if (meters <= nearMaxMeters) return nearDuration;
    if (meters >= farMinMeters) return Duration.zero;
    const span = farMinMeters - nearMaxMeters;
    final over = meters - nearMaxMeters;
    final ratio = (over / span).clamp(0.0, 1.0);
    final ms = nearDuration.inMilliseconds +
        ((midDuration.inMilliseconds - nearDuration.inMilliseconds) * ratio)
            .round();
    return Duration(milliseconds: ms);
  }
}

/// AnimatedMapController — marker tap 時幫你滑過去。
///
/// 用法：
/// ```dart
/// final animated = AnimatedMapController(mapController: controller, vsync: this);
/// // 點 marker 時
/// animated.animateTo(LatLng(25.033, 121.565), 18.0);
/// // 在 FlutterMap 的 options 裡
/// tileUpdateTransformer: animated.tileUpdateTransformer,
/// ```
class AnimatedMapController implements MapMoveStrategy {
  final MapController mapController;
  final TickerProvider vsync;

  AnimatedMapController({required this.mapController, required this.vsync});

  // ── 這三個 id 與 tileUpdateTransformer 綁定 ──
  static const _startedId = 'AnimatedMapController#MoveStarted';
  static const _inProgressId = 'AnimatedMapController#MoveInProgress';
  static const _finishedId = 'AnimatedMapController#MoveFinished';

  AnimationController? _controller;

  void _disposeAnimController() {
    _controller?.dispose();
    _controller = null;
  }

  /// Move the camera to [destCenter] with a distance-aware duration.
  /// Delegates to `animateTo`; satisfies [MapMoveStrategy.moveTo].
  @override
  void moveTo(LatLng destCenter, {double zoom = 18.0}) {
    animateTo(destCenter, zoom);
  }

  /// 指定目標點與 zoom-level
  void animateTo(LatLng destCenter, double destZoom) {
    // ── Guards must run BEFORE any compute/state mutation (including
    // _disposeAndReset and fast-path `mapController.move`).  Otherwise
    // NaN/Infinity values that pass through either the zero-duration
    // fast-path or escape the animation branch land inside flutter_map's
    // `pixelBounds` → `floor()` / `toInt()` → `Unsupported operation:
    // Infinity or NaN toInt` → cascading rebuild cycle → OOM (52s jank).
    // ──────────────────────────────────────────────────────────────────
    final latFinite = destCenter.latitude.isFinite;
    final lonFinite = destCenter.longitude.isFinite;
    final zoomFinite = destZoom.isFinite;
    if (!latFinite || !lonFinite || !zoomFinite) {
      // Fall back to instant move at a sane zoom (default 16 if destZoom was
      // bad) so we never feed NaN into the camera.
      final safeLat = latFinite ? destCenter.latitude : 22.631442;
      final safeLon = lonFinite ? destCenter.longitude : 120.301890;
      final safeZoom = zoomFinite ? destZoom : 16.0;
      mapController.move(LatLng(safeLat, safeLon), safeZoom);
      return;
    }

    // ── Safe from here on ──

    final camera = mapController.camera;
    final startCenter = camera.center;
    final startZoom = camera.zoom;

    // Guard the *current* camera too — if it's somehow NaN, fall through to
    // instant move rather than building a NaN-begin tween.
    if (!startCenter.latitude.isFinite ||
        !startCenter.longitude.isFinite ||
        !startZoom.isFinite) {
      mapController.move(destCenter, destZoom);
      return;
    }

    final meters = MapAnimatedMove.metersBetween(startCenter, destCenter);
    final duration = MapAnimatedMove.durationForMeters(meters);
    if (duration == Duration.zero) {
      mapController.move(destCenter, destZoom);
      return;
    }

    _disposeAndReset();

    final latTween = Tween<double>(
        begin: startCenter.latitude, end: destCenter.latitude);
    final lngTween = Tween<double>(
        begin: startCenter.longitude, end: destCenter.longitude);
    final zoomTween = Tween<double>(begin: startZoom, end: destZoom);

    _controller = AnimationController(duration: duration, vsync: vsync);
    final animation =
        CurvedAnimation(parent: _controller!, curve: Curves.fastOutSlowIn);

    final startIdWithTarget =
        '$_startedId#${destCenter.latitude},${destCenter.longitude},$destZoom';

    var hasTriggeredMove = false;

    _controller!.addListener(() {
      final String id;
      if (animation.value == 1.0) {
        id = _finishedId;
      } else if (!hasTriggeredMove) {
        id = startIdWithTarget;
      } else {
        id = _inProgressId;
      }

      hasTriggeredMove |= mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
        id: id,
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _disposeAnimController();
      }
    });

    _controller!.forward();
  }

  void _disposeAndReset() {
    _disposeAnimController();
  }

  void dispose() {
    _disposeAnimController();
  }

  /// 掛在 TileLayer.tileUpdateTransformer 上，確保動畫期間 tile 不會白屏。
  //
  // Also defensive against upstream NaN / Infinity values: even if a stray
  // `_startedId` carries bad numbers (e.g. zoom tweens computed outside of
  // [animateTo], or `[destZoom]` being NaN because callers re-use this ID),
  // we drop the event rather than crashing flutter_map with
  // `Unsupported operation: Infinity or NaN toInt` inside
  // `DiscreteTileRange.fromPixelBounds`. The Dart `double.parse('NaN')`
  // succeeds, so plain string parsing is not enough — we must validate.
  late final TileUpdateTransformer tileUpdateTransformer =
      TileUpdateTransformer.fromHandlers(
    handleData: (updateEvent, sink) {
      final mapEvent = updateEvent.mapEvent;
      final id = mapEvent is MapEventMove ? mapEvent.id : null;
      if (id?.startsWith(_startedId) ?? false) {
        try {
          final parts = id!.split('#')[2].split(',');
          if (parts.length < 3) {
            // malformed started payload — fall through to default passthrough
            sink.add(updateEvent);
            return;
          }
          final lat = double.parse(parts[0]);
          final lon = double.parse(parts[1]);
          final zoom = double.parse(parts[2]);
          if (!lat.isFinite || !lon.isFinite || !zoom.isFinite) {
            // bad numbers in the ID — let flutter_map use the live camera
            sink.add(updateEvent);
            return;
          }
          sink.add(
            updateEvent.loadOnly(
              loadCenterOverride: LatLng(lat, lon),
              loadZoomOverride: zoom,
            ),
          );
        } catch (_) {
          // parse failure or any other unexpected error → never crash the stream
          sink.add(updateEvent);
        }
      } else if (id == _inProgressId) {
        // 不 prune 也不 load，保持既有 tile 可視
      } else if (id == _finishedId) {
        sink.add(updateEvent.pruneOnly());
      } else {
        sink.add(updateEvent);
      }
    },
  );
}
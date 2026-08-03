
// ignore_for_file: implementation_imports

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
// MoveAndRotateResult is needed to override the return type of
// `MapControllerImpl.moveAndRotate`, but is not exported from
// flutter_map's public API.
import 'package:flutter_map/src/misc/move_and_rotate_result.dart';
import 'package:latlong2/latlong.dart';

/// App-level hardening wrapper for [MapControllerImpl].
///
/// flutter_map 8.3.1's gesture handlers — notably
/// [MapInteractiveViewer._handleFlingAnimation] — compute `LatLng` /
/// zoom values from an internal `AnimationController.value` each frame. In
/// certain boundary cases (multi-touch release mid-fling, gesture
/// interruption from a marker rebuild during `_dataVersion++`, edge zoom
/// values paired with `_mapCenterStart`), the computed center resolves to
/// `(NaN, NaN)`. That `NaN` then flows through `MapControllerImpl.moveRaw`
/// into `MapCamera.value`, and on the next tile update
/// `DiscreteTileRange.fromPixelBounds` throws
/// `Unsupported operation: Infinity or NaN toInt` — which becomes a
/// rebuild cascade under load.
///
/// Without this wrapper the app has to fall back to a "snap back to
/// Kaohsiung" recovery in `MapView.onPositionChanged`, which is jarring UX.
/// Wrapping the controller in [SafeMapController] means NaN never reaches
/// the camera state, so the user sees no snap-back: the map just stops
/// animating for that frame (the next valid `moveRaw` resumes normally).
///
/// Used as a drop-in replacement for `MapController()`:
///
/// ```dart
/// final controller = SafeMapController();
/// FlutterMap(
///   mapController: controller,
///   options: MapOptions(...),
/// );
/// ```
///
/// `flutter_map` accepts any [MapController] subclass because
/// `MapController` is an abstract class whose factory returns the concrete
/// impl; `MapInteractiveViewer` holds its controller as a `MapControllerImpl`
/// reference, so any subclass of the impl works transparently.
class SafeMapController extends MapControllerImpl {
  SafeMapController() : super();

  static bool _isFinite(LatLng p, double z) =>
      p.latitude.isFinite && p.longitude.isFinite && z.isFinite;

  static void _logDropped(String tag, LatLng p, double z) {
    if (kDebugMode) {
      debugPrint(
        '[SafeMapController.$tag] dropping non-finite '
        'lat=${p.latitude} lon=${p.longitude} zoom=$z',
      );
    }
  }

  @override
  bool move(
    LatLng center,
    double zoom, {
    Offset offset = Offset.zero,
    String? id,
  }) {
    if (!_isFinite(center, zoom)) {
      _logDropped('move', center, zoom);
      return false;
    }
    return super.move(center, zoom, offset: offset, id: id);
  }

  /// Override the internal entrypoint that flutter_map's gesture handlers
  /// (`MapInteractiveViewer._handleFlingAnimation`,
  /// `_handlePinchMove`, `_handleDoubleTapZoomAnimation`,
  /// `_handleScrollWheelZoom`) call directly. These paths bypass the
  /// public [move] above and can hand us NaN values computed inside
  /// flutter_map's animation tick. Dropping them here prevents NaN
  /// from ever reaching `MapCamera.value`, so the camera state stays
  /// clean and no snap-back recovery is needed.
  @override
  bool moveRaw(
    LatLng newCenter,
    double newZoom, {
    Offset offset = Offset.zero,
    bool hasGesture = false,
    MapEventSource source = MapEventSource.mapController,
    String? id,
  }) {
    if (!_isFinite(newCenter, newZoom)) {
      _logDropped('moveRaw', newCenter, newZoom);
      return false;
    }
    return super.moveRaw(
      newCenter,
      newZoom,
      offset: offset,
      hasGesture: hasGesture,
      source: source,
      id: id,
    );
  }

  @override
  MoveAndRotateResult moveAndRotate(
    LatLng center,
    double zoom,
    double degree, {
    String? id,
  }) {
    if (!_isFinite(center, zoom)) {
      _logDropped('moveAndRotate', center, zoom);
      return const (moveSuccess: false, rotateSuccess: false);
    }
    return super.moveAndRotate(center, zoom, degree, id: id);
  }
}

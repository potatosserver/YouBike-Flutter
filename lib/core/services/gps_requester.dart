import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:youbike_android/providers/map_view_model.dart';

/// Single entry point for requesting GPS and getting a resolved position.
///
/// Usage:
///   final pos = await gpsRequester.request(mapVm);
///   if (pos != null) { ... }
class GpsRequester {
  const GpsRequester();

  /// Requests GPS permission + position, returns the resolved coordinate.
  /// Returns null if GPS is unavailable or denied.
  /// Falls back to region center via [mapVm.getEffectiveLocation] internally
  /// but still returns null to signal GPS explicitly failed.
  Future<LatLng?> request(MapViewModel mapVm) async {
    try {
      await mapVm.requestAndCenterLocation();
      // After requestAndCenterLocation, lastKnownLocation is set if GPS succeeded.
      // If it's still null, GPS failed → caller can decide fallback.
      return mapVm.lastKnownLocation;
    } catch (e) {
      debugPrint('GpsRequester error: $e');
      return null;
    }
  }

  /// Convenience: always returns a LatLng (never null).
  /// GPS if available, otherwise falls back to region center.
  Future<LatLng> requestOrFallback(MapViewModel mapVm) async {
    final gps = await request(mapVm);
    return gps ?? mapVm.getEffectiveLocation();
  }
}
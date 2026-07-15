import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:youbike_android/data/services/app_config_service.dart';
import 'package:youbike_android/providers/localized_view_model.dart';

class MapViewModel extends LocalizedViewModel {
  final AppConfigService config;
  MapViewModel(this.config);

  LatLng? center;
  LatLng? lastKnownLocation;
  bool isFollowing = true;

  void updateConfig(AppConfigService newConfig) {
    notifyListeners();
  }

  Future<void> requestAndCenterLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services are disabled.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      lastKnownLocation = LatLng(position.latitude, position.longitude);
      center = lastKnownLocation;
      notifyListeners();
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  LatLng getEffectiveLocation() {
    if (lastKnownLocation != null) return lastKnownLocation!;
    // 回退到使用者選擇的區域預設中心
    final regionData = config.regions[config.selectedRegion]!;
    return LatLng(
      (regionData['lat'] as num).toDouble(),
      (regionData['lng'] as num).toDouble(),
    );
  }
}

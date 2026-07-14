import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/app_config_service.dart';

class MapViewModel with ChangeNotifier {
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
    return lastKnownLocation ?? const LatLng(25.0330, 121.5654);
  }
}

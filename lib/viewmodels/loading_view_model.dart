import 'package:flutter/material.dart';
import 'dart:async';

class LoadingViewModel with ChangeNotifier {
  bool isLoading = false;
  double loadingProgress = 0.0;
  String currentNotice = "init_starting";

  // Now using L10n Keys instead of hardcoded text
  final List<String> notices = [
    "init_starting",
    "init_locating",
    "init_syncing",
    "init_updating",
    "notice_no_phone",
    "notice_no_sidewalk",
    "notice_no_phone",
    "notice_no_brake",
    "notice_seat_height",
    "notice_lights_work",
    "notice_insurance",
    "notice_take_belongings",
  ];

  void setLoading(bool value) {
    isLoading = value;
    if (!value) {
      loadingProgress = 0.0;
    }
    notifyListeners();
  }

  void simulatePercentage() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!isLoading) {
        timer.cancel();
        return;
      }
      if (loadingProgress < 100) {
        loadingProgress += 1.2;
        if (loadingProgress > 100) loadingProgress = 100;
        
        // Cycle through notice keys based on progress
        int noticeIndex = (loadingProgress / 8).floor() % notices.length;
        currentNotice = notices[noticeIndex];
        
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void setFinished() {
    isLoading = false;
    loadingProgress = 100.0;
    notifyListeners();
  }
}

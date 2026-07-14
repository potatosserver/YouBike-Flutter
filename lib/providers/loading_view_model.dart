import 'package:flutter/material.dart';
import 'dart:async';

class LoadingViewModel with ChangeNotifier {
  bool isLoading = false;
  double loadingProgress = 0.0;
  String currentNotice = "init_starting";
  int? statusValue; // 用於存放動態數據（如站點數量）

  // 分類管理通知
  final Map<String, String> technicalSteps = {
    "init_starting": "init_starting",
    "init_requesting_permission": "init_requesting_permission",
    "init_verifying_permission": "init_verifying_permission",
    "init_locating": "init_locating",
    "init_map_engine": "init_map_engine",
    "init_map_tiles": "init_map_tiles",
    "init_syncing": "init_syncing",
    "init_syncing_stations": "init_syncing_stations", // 新增：動態站點同步
    "init_clustering": "init_clustering",
    "init_updating": "init_updating",
    "init_success": "init_success",
  };

  final List<String> safetyTips = [
    "notice_no_phone",
    "notice_no_sidewalk",
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
      statusValue = null;
    }
    notifyListeners();
  }

  // 強化版更新狀態：支持傳入動態數值
  void updateStatus(String key, {int? value}) {
    currentNotice = key;
    statusValue = value;
    notifyListeners();
  }

  void simulatePercentage() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!isLoading) {
        timer.cancel();
        return;
      }
      
      if (loadingProgress < 100) {
        loadingProgress += 0.8;
        if (loadingProgress > 100) loadingProgress = 100;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void setFinished() {
    isLoading = false;
    loadingProgress = 100.0;
    currentNotice = "init_success";
    statusValue = null;
    notifyListeners();
  }
}

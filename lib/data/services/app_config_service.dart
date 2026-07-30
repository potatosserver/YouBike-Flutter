import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfigService with ChangeNotifier {
  String currentLang = 'zh_TW';
  String selectedRegion = 'kaohsiung';
  bool useLocation = true;
  bool useNotification = true;
  /// Moovo 自行車系統開關（位於設定 → 參數 → Beta 版 → 內含）。
  /// 儲存於 SharedPreferences (key `useMoovo`)，預設 `false`。
  /// 其他檔案可透過 Provider 取得 `useMoovo` (`listen: true/false` 都可)。
  bool useMoovo = false;
  Set<String> pinnedStationIds = {};
  SharedPreferences? _prefs;
  String _appVersion = '0.0.0+0';

  /// 已快取的應用版本字串（格式：`version+buildNumber`，從 PackageInfo 讀取）。
  /// 在 [init] 時建立；若 init 期間讀取失敗則回傳預設值。
  String get appVersion => _appVersion;

  final Map<String, Map<String, dynamic>> _regions = {
    "taipei": {"name": "region_taipei", "lat": 25.047924, "lng": 121.517081},
    "newTaipei": {"name": "region_new_taipei", "lat": 25.0215339197085, "lng": 121.4568090197085},
    "taoyuan": {"name": "region_taoyuan", "lat": 24.953671, "lng": 121.225783},
    "hsinchuCounty": {"name": "region_hsinchu_county", "lat": 24.826917615712, "lng": 121.01290295049},
    "hsinchuCity": {"name": "region_hsinchu_city", "lat": 24.801815, "lng": 120.971459},
    "sciencePark": {"name": "region_science_park", "lat": 24.781830, "lng": 121.005074},
    "miaoli": {"name": "region_miaoli", "lat": 24.5648599, "lng": 120.8185503},
    "taichung": {"name": "region_taichung", "lat": 24.154712, "lng": 120.664265},
    "chiayi": {"name": "region_chiayi", "lat": 23.4797837, "lng": 120.4397206},
    "tainan": {"name": "region_tainan", "lat": 22.99230083082, "lng": 120.18509419659},
    "kaohsiung": {"name": "region_kaohsiung", "lat": 22.631442, "lng": 120.301890},
    "pingtung": {"name": "region_pingtung", "lat": 22.683036253664, "lng": 120.48790854724},
    "taitung": {"name": "region_taitung", "lat": 22.755711056126138, "lng": 121.15035332587574},
  };
  Map<String, Map<String, dynamic>> get regions => _regions;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    currentLang = _prefs?.getString('currentLang') ?? 'zh_TW';
    selectedRegion = _prefs?.getString('selectedRegion') ?? 'kaohsiung';
    useLocation = _prefs?.getBool('useLocation') ?? true;
    useNotification = _prefs?.getBool('useNotification') ?? true;
    useMoovo = _prefs?.getBool('useMoovo') ?? false;
    final pinnedList = _prefs?.getStringList('pinnedStations') ?? [];
    pinnedStationIds = pinnedList.map((id) => id.trim()).toSet();
    // 集中讀取 PackageInfo — 取代原本散落 3 處的 PackageInfo.fromPlatform() 呼叫。
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      // 保留預設 value '0.0.0+0' 即可；AppConfigService.init 不該拋例外。
    }
    notifyListeners();
  }

  void setLanguage(String lang) {
    currentLang = lang;
    _prefs?.setString('currentLang', lang);
    notifyListeners();
  }

  void setRegion(String region) {
    selectedRegion = region;
    _prefs?.setString('selectedRegion', region);
    notifyListeners();
  }

  void setUseLocation(bool use) {
    useLocation = use;
    _prefs?.setBool('useLocation', use);
    notifyListeners();
  }

  void setUseNotification(bool use) {
    useNotification = use;
    _prefs?.setBool('useNotification', use);
    notifyListeners();
  }

  /// 設定 Moovo 自行車系統開關 — 與 `useLocation` / `useNotification` 相同的 Pattern：
  /// 寫入記憶體欄位 → 寫入 SharedPreferences → 通知監聽者。
  void setUseMoovo(bool use) {
    useMoovo = use;
    _prefs?.setBool('useMoovo', use);
    notifyListeners();
  }

  void togglePinStation(String stationId) {
    final id = stationId.trim();
    if (pinnedStationIds.contains(id)) {
      pinnedStationIds.remove(id);
    } else {
      pinnedStationIds.add(id);
    }
    _prefs?.setStringList('pinnedStations', pinnedStationIds.toList());
    notifyListeners();
  }

  SharedPreferences? get prefs => _prefs;
}

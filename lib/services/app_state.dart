import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/station.dart';
import '../services/api_service.dart';
import 'notification_service.dart';

class AppState extends ChangeNotifier {
  // --- State Properties ---
  LatLng? _center;
  LatLng? get center => _center;
  set center(LatLng? value) {
    if (_center == value) return;
    debugPrint("[STATE] 📍 center 變更: $_center -> $value");
    _center = value;
    notifyListeners();
  }

  LatLng? initialSnapPoint;
  List<Station> _fullStationList = []; 
  List<Station> allStations = [];     
  bool _isLoading = true;
  bool _isInitialLoadComplete = false;
  DateTime? _initStartTime; // 記錄啟動開始時間
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    // 如果是嘗試關閉載入狀態，檢查是否滿足保底時間 (1.5秒)
    if (value == false && _initStartTime != null) {
      final elapsed = DateTime.now().difference(_initStartTime!).inMilliseconds;
      if (elapsed < 1500) {
        // 如果時間不夠，延遲關閉，確保載入畫面不會一閃而過
        Future.delayed(Duration(milliseconds: 1500 - elapsed), () {
          _isLoading = false;
          notifyListeners();
        });
        return;
      }
    }
    if (_isInitialLoadComplete && value == true) return;
    _isLoading = value;
    debugPrint("[STATE] ⏳ isLoading = $value");
    notifyListeners();
  }
  int loadingProgress = 0;
  String currentNotice = "init_starting";
  String loadingNotice = "";
  List<String> logs = [];
  bool isFollowingUser = false;
  bool hasObtainedRealLocation = false;
  LatLng? lastKnownLocation;
  String currentLang = 'zh_TW';
  ThemeMode themeMode = ThemeMode.system;
  bool isUpdating = false; 
  int countdownRemaining = 60;
  bool isOffline = false; 
  String selectedRegion = 'kaohsiung';
  bool useLocation = true;
  Set<String> pinnedStationIds = {};
  StreamSubscription<Position>? _locationSubscription;
  SharedPreferences? _prefs;

  Map<String, Map<String, dynamic>> get regions => _regions;
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

  final Map<String, int> _anchorCounts = {};
  final Map<String, LatLng> _anchorPositions = {};

  LatLng _getVisualPosition(LatLng original) {
    const double threshold = 0.00009; 
    for (var entry in _anchorPositions.entries) {
      final anchorPos = entry.value;
      final distSq = math.pow(original.latitude - anchorPos.latitude, 2) + 
                     math.pow(original.longitude - anchorPos.longitude, 2);
      if (distSq < (threshold * threshold)) {
        final id = entry.key;
        final count = (_anchorCounts[id] ?? 0) + 1;
        _anchorCounts[id] = count;
        final angle = count * 2.399; 
        final radius = 0.00010 + (count * 0.00002);
        return LatLng(
          original.latitude + (radius * math.cos(angle)),
          original.longitude + (radius * math.sin(angle)),
        );
      }
    }
    final anchorId = "${original.latitude},${original.longitude}";
    _anchorPositions[anchorId] = original;
    _anchorCounts[anchorId] = 0;
    return original;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    final double dLat = (lat2 - lat1) * math.pi / 180;
    final double dLon = (lon2 - lon1) * math.pi / 180;
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  LatLng getEffectiveLocation() {
    if (lastKnownLocation != null) return lastKnownLocation!;
    if (center != null) return center!;
    final region = _regions[selectedRegion] ?? _regions['kaohsiung']!;
    return LatLng(region['lat'] as double, region['lng'] as double);
  }

  void startTracking() {
    if (_locationSubscription != null) return;
    stopTracking();
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      lastKnownLocation = LatLng(position.latitude, position.longitude);
      center = lastKnownLocation!;
      if (isFollowingUser) {
        notifyListeners();
      }
      for (var s in allStations) {
        final d = _calculateDistance(center!.latitude, center!.longitude, s.lat, s.lng);
        s.distance = d;
      }
      notifyListeners();
    });
    NotificationService.instance.show(message: "tracking_enabled", type: NotificationType.success);
  }

  void stopTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final themeIndex = _prefs?.getInt('themeMode') ?? 0;
    themeMode = ThemeMode.values[themeIndex];
    currentLang = _prefs?.getString('currentLang') ?? 'zh_TW';
    selectedRegion = _prefs?.getString('selectedRegion') ?? 'kaohsiung';
    useLocation = _prefs?.getBool('useLocation') ?? true;
    final pinnedList = _prefs?.getStringList('pinnedStations') ?? [];
    pinnedStationIds = pinnedList.map((id) => id.trim()).toSet();
    
    // 1. 立即初始化地圖中心 (消除轉圈)
    // 優先順序：快取位置 -> 預設區域位置
    final cachedLat = _prefs?.getDouble('last_lat');
    final cachedLng = _prefs?.getDouble('last_lng');
    if (cachedLat != null && cachedLng != null) {
      center = LatLng(cachedLat, cachedLng);
      lastKnownLocation = center;
    } else {
      center = getEffectiveLocation();
      lastKnownLocation = center;
    }

    final cachedStationsJson = _prefs?.getString('cached_stations');
    if (cachedStationsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedStationsJson);
        _fullStationList = decoded.map((item) => Station.fromJson(item as Map<String, dynamic>)).whereType<Station>().toList();
      } catch(e) { debugPrint("Cache load error: $e"); }
    }
    
    _monitorConnectivity();
    await _runOptimizedInit();
    startAutoRefreshCycle();
    isLoading = false;
    notifyListeners();
  }

  Future<void> _runOptimizedInit() async {
    _initStartTime = DateTime.now(); // 記錄啟動開始時間
    final startTime = DateTime.now().millisecondsSinceEpoch;
    debugPrint("[BOOT-TIMELINE] 🚀 App Start: $startTime");
    
    isLoading = true;
    _simulateRandomNotices();
    _simulatePercentage();
    
    try {
      // 1. 背景異步獲取精確定位 (完全不阻塞)
      _initializeLocation().then((_) {
        debugPrint("[BOOT-TIMELINE] 🎯 Precision GPS Acquired: ${DateTime.now().millisecondsSinceEpoch}");
        refreshStations(isInitial: false);
      });

      // 2. 快取優先檢查
      final cachedStationsJson = _prefs?.getString('cached_stations');
      if (cachedStationsJson != null) {
        debugPrint("[BOOT-TIMELINE] 📦 Cache Found. Loading from cache...");
        try {
          final List<dynamic> decoded = jsonDecode(cachedStationsJson);
          _fullStationList = decoded.map((item) => Station.fromJson(item as Map<String, dynamic>)).whereType<Station>().toList();
          
          currentNotice = "init_updating";
          notifyListeners();
          
          // 注意：這裡不再使用 await，直接觸發背景刷新，讓 UI 立即渲染
          refreshStations(isInitial: true);
          
          debugPrint("[BOOT-TIMELINE] 🖼️ UI Rendered (From Cache): ${DateTime.now().millisecondsSinceEpoch}");
          isLoading = false;
          _isInitialLoadComplete = true;
          loadingProgress = 100;
          currentNotice = "init_success";
          notifyListeners();

          return; 
        } catch (e) {
          debugPrint("Cache load error: $e. Falling back to network.");
        }
      }

      // 3. 無快取回退流程 (Cold Start)
      debugPrint("[BOOT-TIMELINE] ❄️ Cold Start. Fetching base data from network...");
      currentNotice = "init_syncing";
      notifyListeners();
      await fetchBaseData();
      debugPrint("[BOOT-TIMELINE] 🌐 Base Data Fetched: ${DateTime.now().millisecondsSinceEpoch}");

      currentNotice = "init_updating";
      notifyListeners();
      await refreshStations(isInitial: true);
      
    } catch (e) {
      addLog("init_error $e", isError: true);
    } finally {
      _isInitialLoadComplete = true;
      loadingProgress = 100;
      currentNotice = "init_success";
      if (isLoading) {
        isLoading = false;
        debugPrint("[BOOT-TIMELINE] 🖼️ UI Rendered (From Network): ${DateTime.now().millisecondsSinceEpoch}");
      }
      notifyListeners();
    }
  }

  Future<void> _initializeLocation() async {
    try {
      final pos = await getCurrentPosition();
      if (pos != null) {
        lastKnownLocation = LatLng(pos.latitude, pos.longitude);
        center = lastKnownLocation!;
        initialSnapPoint = center;
        _prefs?.setDouble('last_lat', lastKnownLocation!.latitude);
        _prefs?.setDouble('last_lng', lastKnownLocation!.longitude);
        hasObtainedRealLocation = true;
      } else if (lastKnownLocation != null) {
        center = lastKnownLocation!;
        initialSnapPoint = center;
      } else {
        final region = _regions[selectedRegion] ?? _regions['kaohsiung']!;
        center = LatLng(region['lat'] as double, region['lng'] as double);
        lastKnownLocation = center;
        initialSnapPoint = center;
      }
    } catch (e) {
      if (lastKnownLocation != null) {
        center = lastKnownLocation!;
        initialSnapPoint = center;
      } else {
        final region = _regions[selectedRegion] ?? _regions['kaohsiung']!;
        center = LatLng(region['lat'] as double, region['lng'] as double);
        lastKnownLocation = center;
        initialSnapPoint = center;
      }
    }
  }

  Future<void> fetchBaseData() async {
    try {
      final api = ApiService();
      final freshData = await api.fetchAllStations();
      if (freshData.isNotEmpty) {
        _fullStationList = freshData;
        final cacheData = jsonEncode(_fullStationList.map((s) => s.toJson()).toList());
        await _prefs?.setString('cached_stations', cacheData);
      } else {
        addLog("API 返回空數據，保留快取", isError: false);
      }
    } catch (e) {
      addLog("基礎數據獲取失敗: $e", isError: true);
    }
  }

  Future<void> refreshStations({bool isInitial = false}) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    debugPrint("[REFRESH-LOG] 🕒 流程開始: $startTime");

    if (!isInitial) {
      isUpdating = true;
      countdownRemaining = 60; // 立即重置倒數，提供即時反饋
      notifyListeners();
      debugPrint("[REFRESH-LOG] 🕒 isUpdating=true & countdown=60: ${DateTime.now().millisecondsSinceEpoch - startTime}ms");
    }

    try {
      final api = ApiService();
      if (_fullStationList.isEmpty) {
        _fullStationList = await api.fetchAllStations();
      }
      
      LatLng referencePoint = lastKnownLocation ?? getEffectiveLocation();
      
      // 定位請求保持非阻塞背景任務
      getCurrentPosition().then((pos) {
        if (pos != null) {
          lastKnownLocation = LatLng(pos.latitude, pos.longitude);
          hasObtainedRealLocation = true;
          for (var s in allStations) {
            s.distance = _calculateDistance(lastKnownLocation!.latitude, lastKnownLocation!.longitude, s.lat, s.lng);
          }
          notifyListeners();
          debugPrint("[REFRESH-LOG] 🕒 背景定位更新完成: ${DateTime.now().millisecondsSinceEpoch - startTime}ms");
        }
      });
      
      final sorted = List<Station>.from(_fullStationList);
      sorted.sort((a, b) {
        final distA = _calculateDistance(referencePoint.latitude, referencePoint.longitude, a.lat, a.lng);
        final distB = _calculateDistance(referencePoint.latitude, referencePoint.longitude, b.lat, b.lng);
        return distA.compareTo(distB);
      });
      
      _anchorPositions.clear();
      _anchorCounts.clear();
      
      allStations = [...sorted.where((s) => pinnedStationIds.contains(s.id.trim())), ...sorted.where((s) => !pinnedStationIds.contains(s.id.trim()))].take(10).toList();
      for (var s in allStations) {
        final d = _calculateDistance(referencePoint.latitude, referencePoint.longitude, s.lat, s.lng);
        s.distance = d;
        s.visualPosition = _getVisualPosition(LatLng(s.lat, s.lng));
      }
      
      debugPrint("[REFRESH-LOG] 🕒 站點清單排序完成: ${DateTime.now().millisecondsSinceEpoch - startTime}ms");
      
      debugPrint("[REFRESH-LOG] 🕒 開始請求實時數量 API...");
      final vehicleData = await api.fetchRealtimeVehicles(allStations.map((s) => s.id).toList());
      for (var s in allStations) {
        if (vehicleData.containsKey(s.id)) {
          final data = vehicleData[s.id] as Map<String, dynamic>;
          s.availableBikes = data['available_2_0'] ?? 0;
          s.availableElectricBikes = data['available_e'] ?? 0;
          s.emptySpaces = data['empty_spaces'] ?? 0;
        }
      }
      
      notifyListeners(); 
      debugPrint("[REFRESH-LOG] 🕒 API 數據更新完成: ${DateTime.now().millisecondsSinceEpoch - startTime}ms");
      
    } catch (e) {
      addLog("refresh_error $e", isError: true);
    } finally {
      isUpdating = false;
      notifyListeners();
      debugPrint("[REFRESH-LOG] 🕒 流程結束 (isUpdating=false): ${DateTime.now().millisecondsSinceEpoch - startTime}ms");
    }
  }

  Future<void> _simulatePercentage() async {
    int progress = 0;
    int? lockedProgress;
    while (isLoading && progress < 100) {
      if (progress < 85) {
        progress++;
      } else if (lockedProgress == null) {
        lockedProgress = 85 + math.Random().nextInt(11);
        progress = lockedProgress;
      } else {
        progress = lockedProgress;
      }
      loadingProgress = progress;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void _simulateRandomNotices() async {
    final notices = currentLang.startsWith('en') 
      ? [
        "notice_no_speed",
        "notice_no_sidewalk",
        "notice_no_phone",
        "notice_no_brake",
        "notice_seat_height",
        "notice_lights_work",
        "notice_insurance",
        "notice_take_belongings"
      ]
      : [
        "notice_no_speed",
        "notice_no_sidewalk",
        "notice_no_phone",
        "notice_no_brake",
        "notice_seat_height",
        "notice_lights_work",
        "notice_insurance",
        "notice_take_belongings"
      ];
    loadingNotice = notices[math.Random().nextInt(notices.length)];
    notifyListeners();
  }

  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      final isConnected = result.any((r) => r != ConnectivityResult.none);
      if (isOffline != !isConnected) {
        isOffline = !isConnected;
        if (isOffline) {
          NotificationService.instance.show(
            message: "網路連線已中斷", 
            type: NotificationType.info,
          );
        }
        notifyListeners();
      }
    });
  }

  void setRegion(String regionId) {
    if (!_regions.containsKey(regionId)) return;
    selectedRegion = regionId;
    final region = _regions[regionId]!;
    center = LatLng(region['lat'] as double, region['lng'] as double);
    _prefs?.setString('selectedRegion', regionId);
    addLog("切切換區域至: ${region['name']}");
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    _prefs?.setInt('themeMode', mode.index);
    notifyListeners();
  }

  void setLanguage(String lang) {
    currentLang = lang;
    _prefs?.setString('currentLang', lang);
    notifyListeners();
  }

  void setUseLocation(bool value) {
    useLocation = value;
    _prefs?.setBool('useLocation', value);
    notifyListeners();
  }

  void setFollowing(bool value) {
    if (isFollowingUser == value) return;
    isFollowingUser = value;
    if (value) {
      startTracking();
    } else {
      stopTracking();
      NotificationService.instance.show(
        message: "stop_following", 
        type: NotificationType.info
      );
    }
    notifyListeners();
  }

  void toggleFollowing() {
    isFollowingUser = !isFollowingUser;
    if (isFollowingUser) {
      startTracking();
    } else {
      stopTracking();
    }
    notifyListeners();
  }

  void togglePinStation(String id) {
    final tid = id.trim();
    if (pinnedStationIds.contains(tid)) {
      pinnedStationIds.remove(tid);
    } else {
      pinnedStationIds.add(tid);
    }
    _prefs?.setStringList('pinnedStations', pinnedStationIds.toList());
    notifyListeners();
  }

  String getDistanceLabel(double distance) {
    if (distance < 1000) {
      return "${distance.toStringAsFixed(0)} dist_m";
    }
    return "${(distance / 1000).toStringAsFixed(2)} dist_km";
  }

  Future<Position?> getCurrentPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;
      
      debugPrint("[GPS] 📡 請求精確座標...");
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      ).timeout(const Duration(seconds: 6)); 
    } catch (e) {
      debugPrint("[GPS] ❌ 獲取失敗: $e");
      return null;
    }
  }

  Future<void> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  void startAutoRefreshCycle() {
    Future.delayed(const Duration(seconds: 1), () {
      if (countdownRemaining > 0) {
        countdownRemaining--;
        notifyListeners();
        startAutoRefreshCycle();
      } else {
        refreshStations(isInitial: false); 
        startAutoRefreshCycle();
      }
    });
  }

  void searchStations(String query) async {
    try {
      final api = ApiService();
      if (_fullStationList.isEmpty) {
        _fullStationList = await api.fetchAllStations();
      }
      final filtered = _fullStationList.where((s) => 
        s.nameTw.contains(query) || 
        s.addressTw.contains(query) || 
        s.nameEn.toLowerCase().contains(query.toLowerCase()) || 
        s.addressEn.toLowerCase().contains(query.toLowerCase())
      ).toList();
      final LatLng referencePoint = getEffectiveLocation();
      filtered.sort((a, b) => 
        _calculateDistance(referencePoint.latitude, referencePoint.longitude, a.lat, a.lng)
        .compareTo(_calculateDistance(referencePoint.latitude, referencePoint.longitude, b.lat, b.lng))
      );
      final limit = query.isEmpty ? 10 : 50;
      final pinned = filtered.where((s) => pinnedStationIds.contains(s.id.trim())).toList();
      final unpinned = filtered.where((s) => !pinnedStationIds.contains(s.id.trim())).toList();
      allStations = [...pinned, ...unpinned].take(limit).toList();
      for (var s in allStations) {
        final d = _calculateDistance(referencePoint.latitude, referencePoint.longitude, s.lat, s.lng);
        s.distance = d;
        _anchorPositions.clear();
        _anchorCounts.clear();
        s.visualPosition = _getVisualPosition(LatLng(s.lat, s.lng));
      }
      notifyListeners();
    } catch (e) {
      debugPrint("[SEARCH-ERROR] $e");
    }
  }

  void addLog(String msg, {bool isError = false}) {
    logs.add("[${DateTime.now().toString().split('.').first}] $msg");
    if (logs.length > 100) logs.removeAt(0);
    if (isError) {
      NotificationService.instance.show(
        message: msg, 
        type: NotificationType.error
      );
    }
    notifyListeners();
  }
}

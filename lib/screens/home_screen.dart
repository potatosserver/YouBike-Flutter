import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/language_service.dart';
import '../services/location_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/settings_panel.dart';
import '../widgets/permission_modal.dart';
import '../widgets/route_detail_panel.dart';
import '../models/station.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  Future<void> _handleLocationToggle(bool enable) async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (enable) {
      final status = await _locationService.requestPermission();
      if (status == LocationPermissionStatus.granted) {
        await appState.toggleUserTracking(true);
      } else {
        String msg = "";
        switch (status) {
          case LocationPermissionStatus.serviceDisabled: msg = "請開啟手機的定位服務"; break;
          case LocationPermissionStatus.denied: msg = "請在設定中允許定位權限"; break;
          case LocationPermissionStatus.permanentlyDenied: msg = "權限已被永久拒絕，請至設定頁面手動開啟"; break;
          default: msg = "無法獲取位置權限";
        }
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => PermissionModal(message: msg, onConfirm: () => Navigator.pop(context)),
        );
      }
    } else {
      await appState.toggleUserTracking(false);
    }
  }

  void _onStationSelected(Station s) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.focusStation(s);
    _mapController.move(LatLng(s.lat, s.lng), 16.0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RouteDetailPanel(
        destination: s.nameTw,
        steps: ["這是模擬的路徑步驟 1: 從目前位置出發", "步驟 2: 沿著主要道路直行", "步驟 3: 到達 ${s.nameTw} 站牌"],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      drawer: const SettingsPanel(),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: appState.center,
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) appState.setFollowingUser(false);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.youbike.android',
              ),
              if (appState.isDarkMode)
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    -1,  0,  0, 0, 255,
                     0, -1,  0, 0, 255,
                     0,  0, -1, 0, 255,
                     0,  0,  0, 1, 0,
                  ]),
                  child: TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.youbike.android',
                  ),
                ),
              // 回歸穩定實作：使用 MarkerLayer 而非 ClusterLayer 以確保 100% 編譯成功
              MarkerLayer(markers: appState.stationMarkers),
            ],
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: FloatingActionButton.small(
              heroTag: 'location',
              backgroundColor: AppColors.primary,
              onPressed: () => _handleLocationToggle(true),
              child: Icon(
                Icons.my_location,
                color: appState.isFollowingUser ? Colors.white : Colors.black54,
              ),
            ),
          ),

          Positioned(
            bottom: 120,
            right: 20,
            child: Builder(
              builder: (context) => FloatingActionButton.small(
                heroTag: 'settings',
                backgroundColor: AppColors.primary,
                onPressed: () => Scaffold.of(context).openDrawer(),
                child: const Icon(Icons.settings, color: Colors.white),
              ),
            ),
          ),

          _buildBottomPanel(context, appState),
          const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, AppState appState) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.15,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: appState.isDarkMode ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, -5)),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 60, height: 6,
                decoration: BoxDecoration(
                  color: appState.isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LanguageService.getText('title', appState.currentLang),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    FilledButton.tonal(
                      onPressed: () => appState.updateRealtimeData(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        foregroundColor: AppColors.primary,
                        shape: const StadiumBorder(),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.autorenew, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "${appState.countdown} ${LanguageService.getText('update_countdown', appState.currentLang)}",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: LanguageService.getText('search_placeholder', appState.currentLang),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: appState.isDarkMode ? Colors.black26 : Colors.grey[100],
                  ),
                  onChanged: (val) => appState.searchStations(val),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: appState.searchResults.length,
                  itemBuilder: (context, index) {
                    final s = appState.searchResults[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: appState.isDarkMode ? Colors.white10 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 0.5),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.directions_bike, color: AppColors.primary, size: 20),
                        ),
                        title: Text(
                          appState.currentLang == 'en' ? s.nameEn : s.//nameTw,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        subtitle: Text(
                          appState.currentLang == 'en' ? s.addressEn : s.addressTw,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => _onStationSelected(s),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/station.dart';
import '../services/app_state.dart';
import '../services/route_service.dart';
import '../widgets/station_card.dart';
import '../widgets/route_detail_panel.dart';
import '../widgets/electric_bike_modal.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/pulse_marker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  double _panelHeight = 0.15;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.addListener(_onAppStateChanged);
      if (appState.hasObtainedRealLocation) {
        _mapController.move(appState.center, 18.0);
      }
    });
  }

  @override
  void dispose() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.hasObtainedRealLocation) {
      _mapController.move(appState.center, 18.0);
    }
  }

  void _handleLocationPress() async {
    debugPrint("[UI] 📍 定位按鈕被按下");
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.requestPermission();
    final pos = await appState.getCurrentPosition();
    if (appState.isFollowingUser) {
      appState.toggleFollowing();
    } else {
      appState.toggleFollowing();
      LatLng targetPos = pos != null 
          ? LatLng(pos.latitude, pos.longitude) 
          : appState.getEffectiveLocation();
      appState.lastKnownLocation = targetPos;
      appState.center = targetPos;
      _mapController.move(targetPos, 18.0);
    }
  }

  void _showRoutePanel(Station station) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final routeService = RouteService();
    LatLng startPoint;
    final pos = await appState.getCurrentPosition();
    if (pos != null) {
      startPoint = LatLng(pos.latitude, pos.longitude);
    } else {
      startPoint = appState.getEffectiveLocation();
    }
    if (appState.lastKnownLocation == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("使用預設位置進行導航")),
      );
    }
    try {
      final steps = await routeService.getRoute(startPoint, LatLng(station.lat, station.lng), appState.currentLang);
      if (!mounted) return;
      if (steps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("找不到路線")),
        );
        return;
      }
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) => RouteDetailPanel(
          destination: station.nameTw,
          steps: steps.map((s) => "${s.instruction} (${(s.distance / 1000).toStringAsFixed(2)} km)").toList(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      String errorMsg = "導航服務暫時不可用";
      if (e.toString().contains("ROUTE_AUTH_FAILED")) {
        errorMsg = "導航認證失效 (API Key 失效)";
      } else if (e.toString().contains("ROUTE_API_ERROR")) {
        errorMsg = "導航 API 請求錯誤";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: appState.getEffectiveLocation(),
              initialZoom: 18.0,
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.youbike.android'),
              MarkerLayer(
                markers: appState.allStations.map((s) {
                  final isPinned = appState.pinnedStationIds.contains(s.id.trim());
                  return Marker(
                    point: LatLng(s.lat, s.lng),
                    width: 40, height: 50,
                    child: _buildRoadSignPin(isPinned),
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: appState.center,
                    width: 40, height: 40,
                    child: PulseMarker(latitude: appState.center.latitude, longitude: appState.center.longitude),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 50, left: 20, right: 20,
            child: Container(
              decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
              child: TextField(
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.white, hintText: "搜尋場站...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                ),
                onSubmitted: (val) => appState.searchStations(val),
              ),
            ),
          ),
          Positioned(
            top: 110, left: 20,
            child: FloatingActionButton.small(
              heroTag: 'loc_btn',
              onPressed: _handleLocationPress,
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: appState.isFollowingUser ? const Color(0xFF007BFF) : Colors.black87),
            ),
          ),
          Positioned(
            top: 110, right: 20,
            child: FloatingActionButton.small(
              heroTag: 'settings_btn',
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              backgroundColor: const Color(0xFFFDCACB),
              child: const Icon(Icons.settings, color: Color(0xFF333333)),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: screenHeight * _panelHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, -5))],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onVerticalDragUpdate: (details) {
                      setState(() {
                        _panelHeight -= details.delta.dy / screenHeight;
                        _panelHeight = _panelHeight.clamp(0.1, 0.7);
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: StationPanel(onNavigate: _showRoutePanel),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDCACB),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${appState.countdownRemaining} 秒後更新", 
                         style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                      debugPrint("[UI] 🔄 更新按鈕被按下");
                      appState.countdownRemaining = 60;
                      appState.refreshStations();
                    },
                      child: const Icon(Icons.play_arrow, size: 20, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (appState.isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildRoadSignPin(bool isPinned) {
    final Color circleColor = isPinned ? Colors.amber : Colors.yellow;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: 0,
          child: Container(
            width: 6, height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
            ),
          ),
        ),
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
        ),
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
        ),
        const Icon(Icons.directions_bike, color: Colors.black, size: 18),
      ],
    );
  }
}

class StationPanel extends StatelessWidget {
  final Function(Station) onNavigate;
  const StationPanel({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return SizedBox(
      width: double.infinity,
      child: appState.allStations.isEmpty 
          ? Container(
              padding: const EdgeInsets.all(40),
              child: const Center(child: Text("正在載入...", style: TextStyle(color: Colors.grey))),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: appState.allStations.length,
              itemBuilder: (context, index) {
                final station = appState.allStations[index];
                return StationCard(
                  station: station,
                  onTap: () {},
                  onNavigate: () => onNavigate(station),
                  onShowElectric: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                      builder: (context) => ElectricBikeDetailsModal(stationId: station.id, stationName: station.nameTw),
                    );
                  },
                );
              },
            ),
    );
  }
}

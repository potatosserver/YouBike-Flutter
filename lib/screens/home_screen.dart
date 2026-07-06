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
import '../services/notification_service.dart';

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
    });
  }

  @override
  void dispose() {
    Provider.of<AppState>(context, listen: false).removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.isFollowingUser && appState.center != null) {
      debugPrint("[MAP-MOVE] 🛰️ 自動跟隨移動至: ${appState.center}");
      _mapController.move(appState.center!, 18.0);
    }
  }

  void _handleLocationPress() async {
    final appState = Provider.of<AppState>(context, listen: false);
    LatLng snapPos = appState.lastKnownLocation ?? appState.getEffectiveLocation();
    debugPrint("[MAP-MOVE] 🖐️ 手動觸發移動至: $snapPos");
    _mapController.move(snapPos, 18.0);
    NotificationService.instance.show(message: "已開啟位置追蹤功能", type: NotificationType.success);
    appState.setFollowing(true);
    try {
      await appState.requestPermission();
      final pos = await appState.getCurrentPosition();
      if (pos != null && mounted) {
        final target = LatLng(pos.latitude, pos.longitude);
        debugPrint("[MAP-MOVE] 📡 定位成功，精確移動至: $target");
        _mapController.move(target, 18.0);
      }
    } catch (_) {}
  }

  void _showRoutePanel(Station station) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final routeService = RouteService();
    LatLng startPoint = (await appState.getCurrentPosition()) != null 
        ? LatLng((await appState.getCurrentPosition())!.latitude, (await appState.getCurrentPosition())!.longitude)
        : appState.getEffectiveLocation();
    try {
      final steps = await routeService.getRoute(startPoint, LatLng(station.lat, station.lng), appState.currentLang);
      if (!mounted || steps.isEmpty) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) => RouteDetailPanel(
          destination: station.nameTw,
          steps: steps.map((s) => "${s.instruction} (${(s.distance / 1000).toStringAsFixed(2)} km)").toList(),
        ),
      );
    } catch (_) {
      if (mounted) NotificationService.instance.show(message: "導航服務不可用", type: NotificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          if (appState.center != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: appState.center!,
                initialZoom: 18.0,
                onPositionChanged: (pos, hasMoved) {
                  if (appState.isFollowingUser && pos.center != null && appState.center != null) {
                    if ((pos.center!.latitude - appState.center!.latitude).abs() + (pos.center!.longitude - appState.center!.longitude).abs() > 0.0001) {
                      appState.setFollowing(false);
                    }
                  }
                },
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.youbike.android'),
                MarkerLayer(
                  markers: appState.allStations.map((s) => Marker(
                    point: LatLng(s.lat, s.lng),
                    width: 40, height: 50,
                    child: _buildRoadSignPin(appState.pinnedStationIds.contains(s.id.trim())),
                  )).toList(),
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                        point: appState.center!,
                        width: 40, height: 40,
                        child: PulseMarker(latitude: appState.center!.latitude, longitude: appState.center!.longitude),
                      ),
                  ],
                ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator()),
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
                        _panelHeight = (_panelHeight - details.delta.dy / screenHeight).clamp(0.1, 0.7);
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                    ),
                  ),
                  Expanded(child: _buildStationPanel()),
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
                    Text("${appState.countdownRemaining} 秒後更新", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
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
  Widget _buildStationPanel() {
    final appState = Provider.of<AppState>(context);
    return SizedBox(
      width: double.infinity,
      child: appState.allStations.isEmpty 
          ? Container(padding: const EdgeInsets.all(40), child: const Center(child: Text("正在載入...", style: TextStyle(color: Colors.grey))))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: appState.allStations.length,
              itemBuilder: (context, index) {
                final station = appState.allStations[index];
                return StationCard(
                  station: station,
                  onTap: () {},
                  onNavigate: () => _showRoutePanel(station),
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

  Widget _buildRoadSignPin(bool isPinned) {
    final Color circleColor = isPinned ? Colors.amber : Colors.yellow;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(bottom: 0, child: Container(width: 6, height: 12, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)))),),
        Container(width: 32, height: 32, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))])),
        Container(width: 26, height: 26, decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle)),
        const Icon(Icons.directions_bike, color: Colors.black, size: 18),
      ],
    );
  }
}

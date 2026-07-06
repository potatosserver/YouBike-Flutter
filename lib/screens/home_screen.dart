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

  void _handleLocationPress() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.requestPermission();
    if (appState.isFollowingUser) {
      appState.toggleFollowing();
    } else {
      appState.toggleFollowing();
      LatLng? targetPos = appState.lastKnownLocation;
      if (targetPos == null) {
        final pos = await appState.getCurrentPosition();
        if (pos != null) {
          targetPos = LatLng(pos.latitude, pos.longitude);
        }
      }
      if (targetPos != null) {
        _mapController.move(targetPos, 18.0);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("定位權限被拒絕")),
        );
      }
    }
  }

  void _showRoutePanel(Station station) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final routeService = RouteService();
    LatLng startPoint = appState.lastKnownLocation ?? appState.center;
    if (appState.lastKnownLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("使用區域中心進行導航")),
      );
    }
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
            options: MapOptions(initialCenter: appState.center, initialZoom: 18.0),
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
              decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
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
            bottom: 10, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFFDCACB), borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${appState.countdownRemaining} 秒後更新", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () { appState.countdownRemaining = 60; appState.refreshStations(); },
                      child: const Icon(Icons.play_arrow, size: 18, color: Colors.black87),
                    ),
                  ],
                ),
              ),
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
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
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
              child: Center(child: const Text("正在載入...", style: TextStyle(color: Colors.grey))),
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

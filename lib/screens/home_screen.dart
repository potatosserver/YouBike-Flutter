import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';
import '../widgets/pulse_marker.dart';
import '../widgets/station_card.dart';
import 'settings_page.dart';
import 'debug_screen.dart';
import '../models/station.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MapController _mapController = MapController();

  void _handleLocationPress() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.requestPermission();
    if (appState.isFollowingUser) {
      appState.toggleFollowing();
    } else {
      appState.toggleFollowing();
      final pos = await appState.getCurrentPosition();
      if (pos != null) {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
      }
    }
  }

  void _showStationDetails(Station station) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(station.nameTw),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: ApiService().fetchElectricBikeDetails(station.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text("獲取電輔車資訊失敗: ${snapshot.error}");
              }
              
              final bikes = snapshot.data ?? [];
              if (bikes.isEmpty) {
                return const Text("目前無可用電輔車");
              }
              
              bikes.sort((a, b) => (b['battery_power'] as num).compareTo(a['battery_power'] as num));
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("站點資訊", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("地址：${station.addressTw}"),
                  const SizedBox(height: 10),
                  const Text("即時車輛數", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("YouBike 2.0: ${station.availableBikes} 輛"),
                  Text("YouBike 2.0E: ${station.availableElectricBikes} 輛"),
                  Text("可停空位數: ${station.emptySpaces}"),
                  const SizedBox(height: 15),
                  const Text("電輔車詳細電量", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 5),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: bikes.length,
                      itemBuilder: (context, index) {
                        final bike = bikes[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.directions_bike, size: 20),
                          title: Text("車號: ${bike['bike_no']}"),
                          subtitle: Text("車位: ${bike['pillar_no']}"),
                          trailing: Text("${bike['battery_power']}%", 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("確定")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          SlidingUpPanel(
            body: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: appState.center,
                    initialZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.youbike.finder',
                    ),
                    MarkerLayer(
                      markers: [
                        ...appState.stationMarkers.map((m) => Marker(
                          point: m.point,
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () {
                              final station = appState.allStations.firstWhere(
                                (s) => s.lat == m.point.latitude && s.lng == m.point.longitude,
                                orElse: () => Station(
                                  id: "unknown",
                                  nameTw: "未知站點",
                                  nameEn: "Unknown Station",
                                  addressTw: "未知地址",
                                  addressEn: "Unknown Address",
                                  lat: m.point.latitude,
                                  lng: m.point.longitude,
                                ),
                              );
                              _showStationDetails(station);
                            },
                            child: m.child,
                          ),
                        )),
                        Marker(
                          point: appState.center,
                          width: 40,
                          height: 40,
                          child: PulseMarker(
                            latitude: appState.center.latitude, 
                            longitude: appState.center.longitude,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            panel: _buildSearchAndRecentPanel(appState),
          ),
          Positioned(
            top: 60,
            left: 20,
            child: FloatingActionButton.small(
              heroTag: 'loc_btn',
              onPressed: _handleLocationPress,
              backgroundColor: Colors.white,
              child: Icon(
                appState.isFollowingUser ? Icons.my_location : Icons.location_on,
                color: appState.isFollowingUser ? Colors.blue : Colors.black87,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton.small(
              heroTag: 'set_btn',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.settings, color: Colors.black87),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.small(
                heroTag: 'ref_btn',
                onPressed: () => appState.refreshStations(),
                backgroundColor: Colors.white,
                child: const Icon(Icons.refresh, color: Colors.black87),
              ),
            ),
          ),
          Positioned(
            bottom: 160,
            left: 20,
            child: FloatingActionButton.small(
              heroTag: 'dbg_btn',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DebugScreen()),
                );
              },
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.bug_report, color: Colors.white),
            ),
          ),
          if (appState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndRecentPanel(AppState appState) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (val) => appState.searchStations(val),
              decoration: InputDecoration(
                hintText: "搜尋站點名稱...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: _buildResultsList(appState),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(AppState appState) {
    bool isSearching = appState.searchResults.isNotEmpty;
    List<Station> displayList = isSearching 
        ? appState.getSortedStations(appState.searchResults, appState.center)
        : appState.getSortedStations(appState.allStations, appState.center);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final s = displayList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: StationCard(
            station: s,
            onTap: () {
              _mapController.move(LatLng(s.lat, s.lng), 16.0);
            },
          ),
        );
      },
    );
  }
}

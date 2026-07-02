import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/station.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';
import '../services/route_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/station_card.dart';
import '../widgets/route_detail_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();

  void _handleLocationPress() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.requestPermission();
    
    if (appState.isFollowingUser) {
      appState.toggleFollowing();
    } else {
      appState.toggleFollowing();
      if (appState.lastKnownLocation != null) {
        _mapController.move(appState.lastKnownLocation!, 15.0);
      } else {
        final pos = await appState.getCurrentPosition();
        if (pos != null) {
          _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
        }
      }
    }
  }

  void _showRoutePanel(Station station) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final routeService = RouteService();
    
    final steps = await routeService.getRoute(
      appState.center, 
      LatLng(station.lat, station.lng), 
      appState.currentLang
    );

    if (!mounted) return;

    if (steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.routeNotFound)),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => RouteDetailPanel(
        destination: station.nameTw,
        steps: steps.map((s) => "${s.instruction} (${(s.distance / 1000).toStringAsFixed(2)} km)").toList(),
      ),
    );
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
              final appState = Provider.of<AppState>(context, listen: false);
              final l10n = AppLocalizations.of(context)!;
              if (snapshot.hasError) {
                return Text(l10n.electricBikeError.replaceFirst('{error}', snapshot.error.toString()));
              }
              
              final bikes = snapshot.data ?? [];
              if (bikes.isEmpty) {
                return Text(l10n.noElectricBikes);
              }
              
              bikes.sort((a, b) => (b['battery_power'] as num).compareTo(a['battery_power'] as num));
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: bikes.map((bike) => ListTile(
                  leading: const Icon(Icons.directions_bike),
                  title: Text("${l10n.bikeNumber} ${bike['bike_no']}"),
                  subtitle: Text("${l10n.pillarNumber} ${bike['pillar_no']}"),
                  trailing: Text("${bike['battery_power']}%", 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                )).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: appState.center,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.youbike.android',
              ),
              MarkerLayer(markers: appState.stationMarkers),
              MarkerLayer(
                markers: [
                  Marker(
                    point: appState.center,
                    width: 20,
                    height: 20,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 20),
                  ),
                ],
              ),
            ],
          ),
          
          // Search Bar
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFFFE8D6),
                hintText: l10n.searchPlaceholder,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (val) => appState.searchStations(val),
            ),
          ),
          
          // Location Button - FIXED: Moved to TOP LEFT per request
          Positioned(
            top: 110,
            left: 20,
            child: FloatingActionButton.small(
              heroTag: 'loc_btn',
              onPressed: _handleLocationPress,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.my_location,
                color: appState.isFollowingUser ? const Color(0xFF007BFF) : Colors.black87,
              ),
            ),
          ),

          // Settings Button - FIXED: Restored
          Positioned(
            top: 110,
            right: 20,
            child: FloatingActionButton.small(
              heroTag: 'settings_btn',
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              backgroundColor: const Color(0xFFFDCACB),
              child: const Icon(Icons.settings, color: Color(0xFF333333)),
            ),
          ),
          
          // Refresh Pill
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDCACB),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.updatingIn.replaceFirst('{seconds}', appState.countdownRemaining.toString()),
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        appState.countdownRemaining = 60;
                        appState.refreshStations();
                      },
                      child: const Icon(Icons.play_arrow, size: 18, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Station Card Panel - FIXED: Restored at the bottom
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Center(
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: appState.allStations.isEmpty 
                            ? const SizedBox.shrink()
                            : StationCard(
                                station: appState.allStations.first, 
                                onTap: () => _showStationDetails(appState.allStations.first),
                                onShowElectric: () => _showStationDetails(appState.allStations.first),
                                onNavigate: () => _showRoutePanel(appState.allStations.first),
                              ),
                      ),
            ),
          ),
          
          if (appState.isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/station.dart';
import '../services/app_state.dart';
import '../widgets/station_card.dart';
import '../widgets/route_detail_panel.dart';
import '../widgets/electric_bike_modal.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/pulse_marker.dart';
import '../services/notification_service.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  double? _panelHeight; // Dynamic height for draggability

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.addListener(_onAppStateChanged);
      
      // Initialize panel height to 35% of screen
      setState(() {
        _panelHeight = MediaQuery.of(context).size.height * 0.35;
      });
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
      _mapController.move(appState.center!, 18.0);
    }
  }

  void _handleLocationPress() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    LatLng snapPos = appState.lastKnownLocation ?? appState.getEffectiveLocation();
    _mapController.move(snapPos, 18.0);
    NotificationService.instance.show(
      message: l10n.locationTrackingEnabled, 
      type: NotificationType.success
    );
    appState.setFollowing(true);
    try {
      await appState.requestPermission();
      final pos = await appState.getCurrentPosition();
      if (pos != null && mounted) {
        final target = LatLng(pos.latitude, pos.longitude);
        _mapController.move(target, 18.0);
      }
    } catch (e) {
      debugPrint("[LOC-ERROR] $e");
    }
  }

  void _showRoutePanel(Station station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => RouteDetailPanel(
        destination: station.nameTw,
        destLat: station.lat,
        destLng: station.lng,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // --- Layer 1: Map with Bottom Rounding (Positioned to end exactly at the top of the panel) ---
          if (appState.center != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: (_panelHeight ?? screenHeight * 0.35), // Map ends exactly where the handle starts
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                child: FlutterMap(
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
                    TileLayer(
                      urlTemplate: theme.brightness == Brightness.dark 
                          ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png' 
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', 
                      userAgentPackageName: 'com.youbike.android',
                    ),
                    MarkerLayer(
                      markers: appState.allStations.map((s) => Marker(
                        point: s.visualPosition ?? LatLng(s.lat, s.lng),
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
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),
          // --- Layer 2: Control Overlays (M3 Square Style) ---
          
          // Settings Button: Top-Right, pure white circular button with refined size
          Positioned(
            top: 40, 
            right: 15,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/settings'),
              child: Container(
                width: 32, // Increased from 24 for better visibility
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.settings, 
                    size: 22, // Increased from 18 to match the larger white area
                    color: theme.brightness == Brightness.dark ? const Color(0xFF90CAF9) : Colors.black87
                  ),
                ),
              ),
            ),
          ),

          // Location Button: Bottom-Right of Map, restored to original Settings-style color
          Positioned(
            right: 20,
            bottom: (_panelHeight ?? screenHeight * 0.35) + 20, 
            child: Container(
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? const Color(0xFF222222) : const Color(0xFFFDCACB), // Original color palette
                borderRadius: BorderRadius.circular(12), 
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.my_location, 
                  size: 22, 
                  color: theme.brightness == Brightness.dark ? const Color(0xFF90CAF9) : Colors.black87, // Original icon color
                ),
                onPressed: _handleLocationPress,
              ),
            ),
          ),

          // --- Layer 3: Station Panel (Draggable & Separated) ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: _panelHeight,
            child: Column(
              children: [
                // Bridge-Style Drag Handle: Precision compact symmetry (Balanced for visibility)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _panelHeight = (_panelHeight ?? screenHeight * 0.35) - details.delta.dy;
                      _panelHeight = _panelHeight!.clamp(screenHeight * 0.2, screenHeight * 0.8);
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    height: 24, // Restored to a more comfortable height for visual balance
                    padding: const EdgeInsets.symmetric(vertical: 9), // (24-6)/2 = 9px symmetric gap
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.4, 
                        height: 6, 
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark ? Colors.white38 : const Color(0xFFBBBBBB), 
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 2. THE GAP: Provided by the bottom padding of the handle container
                
                // 3. THE PANEL: The rounded container holding the content
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF5F0),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1), 
                          blurRadius: 15, 
                          offset: const Offset(0, -5)
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        // Search Bar integrated into the panel top (Tighter padding to save room for cards)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: TextField(
                            decoration: InputDecoration(
                              filled: true, 
                              fillColor: theme.brightness == Brightness.dark ? const Color(0xFF2A2A2A) : const Color(0xFFFFFFFF),
                              hintText: l10n.input_placeholder,
                              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15), 
                                borderSide: BorderSide.none
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            ),
                            onSubmitted: (val) => appState.searchStations(val),
                            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                          ),
                        ),
                        Expanded(child: _buildStationPanel()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Layer 4: Floating Action Button ---
          Positioned(
            bottom: 30, left: 0, right: 0,
            child: const HomeUpdateButton(),
          ),
          if (appState.isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildStationPanel() {
    final appState = Provider.of<AppState>(context);
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: appState.allStations.isEmpty 
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noStationsFound,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
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

class HomeUpdateButton extends StatefulWidget {
  const HomeUpdateButton({super.key});
  @override
  State<HomeUpdateButton> createState() => _HomeUpdateButtonState();
}

class _HomeUpdateButtonState extends State<HomeUpdateButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _wasUpdating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      upperBound: 0.5,
    );
    
    final appState = Provider.of<AppState>(context, listen: false);
    appState.addListener(_handleUpdateAnimation);
    _wasUpdating = appState.isUpdating;
  }

  void _handleUpdateAnimation() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.isUpdating) {
      if (!_wasUpdating) {
        _controller.forward(from: 0.0);
        _wasUpdating = true;
      }
    } else {
      if (_wasUpdating) {
        _controller.stop();
        _controller.reset();
        _wasUpdating = false;
      }
    }
  }

  @override
  void dispose() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.removeListener(_handleUpdateAnimation);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: GestureDetector(
        onTap: appState.isUpdating ? null : () {
          appState.refreshStations();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark ? const Color(0xFF4A4A4A) : const Color(0xFFFDCACB),
            borderRadius: BorderRadius.circular(50),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _controller,
                child: Icon(
                  Icons.autorenew, 
                  size: 20, 
                  color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${appState.countdownRemaining}${l10n.countdown_unit}${l10n.countdown_text}",
                style: TextStyle(
                  color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
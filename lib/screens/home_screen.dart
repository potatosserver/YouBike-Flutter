import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../models/station.dart';
import '../services/app_state.dart';
import '../widgets/station_card.dart';
import '../widgets/route_detail_panel.dart';
import '../widgets/electric_bike_modal.dart';
import '../widgets/pulse_marker.dart';
import '../widgets/home_update_button.dart';
import '../services/notification_service.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final ValueNotifier<int> _repaintNotifier = ValueNotifier<int>(0);
  double? _panelHeight; 
  bool _isMapReady = false;

  AppState get _appState => Provider.of<AppState>(context, listen: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _panelHeight = MediaQuery.of(context).size.height * 0.35;
        });
      }
    });
  }

  @override
  void dispose() {
    _repaintNotifier.dispose();
    super.dispose();
  }

  void _safeMove(LatLng point, double zoom) {
    if (!_isMapReady) return;
    _mapController.move(point, zoom);
  }

  void _handleLocationPress() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    LatLng snapPos = _appState.lastKnownLocation ?? _appState.getEffectiveLocation();
    _safeMove(snapPos, 18.0);
    NotificationService.instance.show(message: l10n.locationTrackingEnabled, type: NotificationType.success);
    _appState.setFollowing(true);
    try {
      await _appState.requestPermission();
      final pos = await _appState.getCurrentPosition();
      if (pos != null && mounted) {
        _safeMove(LatLng(pos.latitude, pos.longitude), 18.0);
      }
    } catch (e) {
      debugPrint("[LOC-ERROR] $e");
    }
  }

  void _moveMapToStation(Station station) {
    if (!_isMapReady) return;
    final target = station.visualPosition ?? LatLng(station.lat, station.lng);
    _safeMove(target, 18.0);
    _appState.setFollowing(false);
  }

  void _showRoutePanel(Station station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => RouteDetailPanel(destination: station.nameTw, destLat: station.lat, destLng: station.lng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = MediaQuery.of(context).size;
          final isWide = size.width >= 600;

          return Stack(
            children: [
              Positioned(
                top: isWide ? 12 : 0,
                left: isWide ? 392 : 0,
                right: isWide ? 12 : 0,
                bottom: isWide ? 12 : (_panelHeight ?? size.height * 0.35) + 12,
                child: Selector<AppState, int>(
                  selector: (_, state) => state.fullStations.length,
                  builder: (context, count, child) {
                    return _buildMap(theme);
                  },
                ),
              ),
              Positioned(
                top: 40, right: 15,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                  child: Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Center(child: Icon(Icons.settings, size: 22, color: theme.brightness == Brightness.dark ? const Color(0xFF90CAF9) : Colors.black87)),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: isWide ? 20 : (_panelHeight ?? size.height * 0.35) + 20, 
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? const Color(0xFF4A4A4A) : const Color(0xFFFDCACB),
                    borderRadius: BorderRadius.circular(12), 
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.my_location, size: 22, color: theme.brightness == Brightness.dark ? const Color(0xFF90CAF9) : Colors.black87),
                    onPressed: _handleLocationPress,
                  ),
                ),
              ),
              if (isWide)
                Positioned(top: 12, bottom: 12, left: 12, width: 368, child: _buildResponsivePanel(context, isWide: true))
              else
                Positioned(
                  bottom: 0, 
                  left: 0, 
                  right: 0, 
                  height: _panelHeight ?? size.height * 0.35,
                  child: _buildResponsivePanel(context, isWide: false),
                ),
              Positioned(
                bottom: 30, left: isWide ? 390 : 0, right: 0,
                child: const Center(child: HomeUpdateButton()),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(ThemeData theme) {
    final allStations = _appState.fullStations;
    final initialCenter = _appState.center ?? const LatLng(25.0330, 121.5654);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 18.0,
        onMapReady: () {
          if (mounted) setState(() => _isMapReady = true);
        },
        onPositionChanged: (pos, hasMoved) {
          _repaintNotifier.value++;
        },
      ),
      children: [
        TileLayer(
          urlTemplate: theme.brightness == Brightness.dark 
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png' 
              : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png', 
          userAgentPackageName: 'com.youbike.android',
          tileProvider: CancellableNetworkTileProvider(),
        ),
        if (_isMapReady)
          ValueListenableBuilder<int>(
            valueListenable: _repaintNotifier,
            builder: (context, tick, child) {
              return MarkerLayer(
                markers: _generateMarkers(allStations),
              );
            },
          ),
        Selector<AppState, LatLng?>(
          selector: (_, state) => state.center,
          builder: (context, center, child) {
            if (center == null) return const SizedBox.shrink();
            return MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 40, height: 40,
                  child: PulseMarker(latitude: center.latitude, longitude: center.longitude),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  List<Marker> _generateMarkers(List<Station> stations) {
    final double zoom = _mapController.camera.zoom;
    final List<Marker> markers = [];

    if (zoom >= 16.0) {
      // --- 展開模式 (鏡像網頁版：Anchor 偏移) ---
      final List<_Anchor> anchors = [];
      for (var s in stations) {
        LatLng visualPos = LatLng(s.lat, s.lng);
        const double threshold = 0.00009; 
        for (var anchor in anchors) {
          final dLat = s.lat - anchor.lat;
          final dLon = s.lng - anchor.lon;
          if ((dLat * dLat + dLon * dLon) < (threshold * threshold)) {
            anchor.count++;
            const double angleStep = 2.399;
            const double baseRadius = 0.00010;
            const double radiusStep = 0.00002;
            final double radius = baseRadius + (anchor.count * radiusStep);
            final double angle = anchor.count * angleStep;
            visualPos = LatLng(anchor.lat + (radius * math.cos(angle)), anchor.lon + (radius * math.sin(angle)));
            break;
          }
        }
        if (visualPos == LatLng(s.lat, s.lng)) {
          anchors.add(_Anchor(lat: s.lat, lon: s.lng, count: 0));
        }
        markers.add(Marker(
          point: visualPos,
          width: 40, height: 40,
          child: RoadSignMarker(stationId: s.id),
        ));
      }
    } else {
      // --- 聚類模式 (輕量級格柵聚類) ---
      final double gridS = 0.01; 
      final Map<String, List<Station>> clusters = {};
      for (var s in stations) {
        final String key = "${(s.lat / gridS).floor()}_${(s.lng / gridS).floor()}";
        clusters.putIfAbsent(key, () => []).add(s);
      }
      clusters.forEach((key, cluster) {
        final first = cluster.first;
        markers.add(Marker(
          point: LatLng(first.lat, first.lng),
          width: 40, height: 40,
          child: ClusterMarker(count: cluster.length),
        ));
      });
    }
    return markers;
  }
  
  Widget _buildResponsivePanel(BuildContext context, {required bool isWide}) {
    final theme = Theme.of(context);
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final l10n = AppLocalizations.of(context);
        if (l10n == null) return const SizedBox.shrink();
        return Column(
          children: [
            if (!isWide)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  setState(() {
                    _panelHeight = (_panelHeight ?? MediaQuery.of(context).size.height * 0.35) - details.delta.dy;
                    _panelHeight = _panelHeight!.clamp(MediaQuery.of(context).size.height * 0.2, MediaQuery.of(context).size.height * 0.8);
                  });
                },
                child: Container(
                  width: double.infinity, height: 24, padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.4, height: 6, 
                      decoration: BoxDecoration(color: theme.brightness == Brightness.dark ? Colors.white38 : const Color(0xFFBBBBBB), borderRadius: BorderRadius.circular(3), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 3, offset: const Offset(0, 1) )]),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark ? const Color(0xFF222222) : const Color(0xFFFFF2EC),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1), 
                      blurRadius: 15, 
                      offset: isWide ? const Offset(2, 0) : const Offset(0, -5)
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        decoration: InputDecoration(
                          filled: true, fillColor: theme.brightness == Brightness.dark ? const Color(0xFF2A2A2A) : const Color(0xFFFFFFFF),
                          hintText: l10n.input_placeholder, prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onSubmitted: (val) => appState.searchStations(val),
                        style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                      ),
                    ),
                    Expanded(child: _buildStationPanel(appState, l10n)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildStationPanel(AppState appState, AppLocalizations l10n) =>
      SizedBox(
        width: double.infinity,
        child: appState.filteredStations.isEmpty 
            ? Center(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.noStationsFound, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: appState.filteredStations.take(10).length,
                itemBuilder: (context, index) {
                  final station = appState.filteredStations.take(10).toList()[index];
                  return StationCard(
                    station: station,
                    onTap: () => _moveMapToStation(station),
                    onNavigate: () { _moveMapToStation(station); _showRoutePanel(station); },
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

class _Anchor {
  double lat, lon;
  int count;
  _Anchor({required this.lat, required this.lon, required this.count});
}

class RoadSignMarker extends StatelessWidget {
  final String stationId;
  const RoadSignMarker({super.key, required this.stationId});

  @override
  Widget build(BuildContext context) {
    final pinnedIds = Provider.of<AppState>(context, listen: false).pinnedStationIds;
    final isPinned = pinnedIds.contains(stationId.trim());
    
    return CustomPaint(
      painter: _RoadSignPainter(isPinned: isPinned),
      child: const SizedBox(width: 40, height: 40),
    );
  }
}

class _RoadSignPainter extends CustomPainter {
  final bool isPinned;
  _RoadSignPainter({required this.isPinned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();
    paint.color = const Color(0xFF9E9E9E);
    canvas.drawRect(Rect.fromLTWH(center.dx - 3, center.dy + 16, 6, 12), paint);
    paint.color = Colors.white;
    canvas.drawCircle(center, 16, paint);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(center.dx, center.dy + 1), 16, shadowPaint);
    paint.color = isPinned ? Colors.amber : Colors.yellow;
    canvas.drawCircle(center, 13, paint);
    final tp = TextPainter(
      text: TextSpan(text: '🚲', style: const TextStyle(fontSize: 18, color: Colors.black)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2),);
  }

  @override
  bool shouldRepaint(covariant _RoadSignPainter oldDelegate) {
    return oldDelegate.isPinned != isPinned;
  }
}

class ClusterMarker extends StatelessWidget {
  final int count;
  const ClusterMarker({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: const BoxDecoration(color: Color(0xFF4285F4), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Center(
        child: Text(
          count.toString(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }
}

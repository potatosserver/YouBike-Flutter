
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import '../models/station.dart';
import '../services/app_state.dart';
import '../widgets/map_markers.dart';
import '../widgets/pulse_marker.dart';

class MapView extends StatefulWidget {
  final MapController mapController;
  final bool isMapReady;
  final Function(bool) onReady;
  final Function(LatLng, double) onMoveToStation;

  const MapView({
    super.key, 
    required this.mapController, 
    required this.isMapReady, 
    required this.onReady,
    required this.onMoveToStation,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  Timer? _mapMoveDebounceTimer;

  void _log(String tag, String message) {
    final now = DateTime.now();
    final timestamp = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}";
    debugPrint("[$timestamp] [$tag] $message");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context, listen: false);
    final initialCenter = appState.center ?? const LatLng(25.0330, 121.5654);

    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 18.0,
        onMapReady: () {
          _log("MAP-INIT", "Map initialized and ready for use");
          widget.onReady(true);
        },
        onPositionChanged: (position, hasMoved) {
          if (!hasMoved) return;
          _mapMoveDebounceTimer?.cancel();
          _mapMoveDebounceTimer = Timer(const Duration(milliseconds: 100), () {
            final center = position.center;
            final zoom = position.zoom;
            _log("MAP-POS-DEBOUNCED", "Center: ${center.latitude.toStringAsFixed(6)}, ${center.longitude.toStringAsFixed(6)}, Zoom: ${zoom.toStringAsFixed(2)}");
          });
        },
        onMapEvent: (event) {
          if (event is MapEventMoveEnd) {
            _log("PERF", "Map stable at Zoom: ${widget.mapController.camera.zoom.toStringAsFixed(2)}");
          }
        },
      ),
      children: [
        TileLayer(
          
          urlTemplate: theme.brightness == Brightness.dark 
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png' 
              : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.youbike.android',
          tileProvider: CancellableNetworkTileProvider(),
          keepBuffer: 5,
          tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 1)),
        ),
        Selector<AppState, List<Station>>(
          selector: (_, state) => state.fullStations,
          shouldRebuild: (prev, next) => prev.length != next.length,
          builder: (context, stations, child) {
            _log("DEBUG", "StationMarkerLayer updating with ${stations.length} stations");
            return StationMarkerLayer(stations: stations);
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
}

class StationMarkerLayer extends StatefulWidget {
  final List<Station> stations;
  const StationMarkerLayer({super.key, required this.stations});

  @override
  State<StationMarkerLayer> createState() => _StationMarkerLayerState();
}


class _StationMarkerLayerState extends State<StationMarkerLayer> {
  List<Marker> _cachedMarkers = [];
  MarkerClusterLayerOptions? _clusterOptions;
  int _lastProcessedCount = 0;

  void _updateMarkersAndOptions() {
    // LOCK: Only re-index if the station count actually changed
    if (widget.stations.length == _lastProcessedCount && _clusterOptions != null) {
      return; 
    }

    final stopwatch = Stopwatch()..start();
    _lastProcessedCount = widget.stations.length;

    final appState = Provider.of<AppState>(context, listen: false);
    final normalImg = appState.markerImageNormal;
    final pinnedImg = appState.markerImagePinned;

    _cachedMarkers = widget.stations.map((s) {
      final isPinned = appState.pinnedStationIds.contains(s.id.trim());
      return Marker(
        key: ValueKey("st_${s.id}"),
        point: LatLng(s.lat, s.lng),
        width: 30, height: 30,
        alignment: Alignment.topCenter,
        child: RoadSignMarker(image: isPinned ? pinnedImg : normalImg),
      );
    }).toList();

    _clusterOptions = MarkerClusterLayerOptions(
      maxClusterRadius: 80, 
      size: const Size(45, 45),
      alignment: Alignment.center,
      disableClusteringAtZoom: 16, 
      markers: _cachedMarkers,
      animationsOptions: const AnimationsOptions(
        zoom: Duration.zero,
        fitBound: Duration.zero,
        
        spiderfy: Duration.zero,
      ), 
      builder: (context, markers) {
        return ClusterMarker(count: markers.length);
      },
      showPolygon: false,
      spiderfySpiralDistanceMultiplier: 3,
      circleSpiralSwitchover: 12,
      onClusterTap: (cluster) {
        debugPrint("[CLUSTER-TAP] Tapped cluster with ${cluster.markers.length} markers");
      },
      onMarkerTap: (marker) {
        debugPrint("[MARKER-TAP] Tapped individual marker: ${marker.key}");
      },
    );
    
    stopwatch.stop();
    debugPrint("[PERF] 🚀 Index rebuilt (9338 points) in ${stopwatch.elapsedMilliseconds}ms");
  }

  @override
  void initState() {
    super.initState();
    _updateMarkersAndOptions();
  }

  @override
  void didUpdateWidget(covariant StationMarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMarkersAndOptions();
  }

  @override
  Widget build(BuildContext context) {
    _updateMarkersAndOptions(); // Guardian check

    if (_clusterOptions == null) return const SizedBox.shrink();

    // Because _clusterOptions is a persistent reference, 
    // MarkerClusterLayerWidget will NOT rebuild the index tree on move/zoom.
    return MarkerClusterLayerWidget(options: _clusterOptions!);
  }
}

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:youbike/core/utils/log_service.dart';
import 'package:youbike/data/models/station.dart';
import 'package:youbike/data/services/api_service.dart';
import 'package:youbike/providers/map_view_model.dart';
import 'package:youbike/providers/station_view_model.dart';
import 'package:youbike/ui/widgets/map_markers.dart';
import 'package:youbike/ui/widgets/pulse_marker.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/core/services/station_format_helper.dart';
import 'package:youbike/core/services/map_animated_move.dart';
import 'package:youbike/data/services/app_config_service.dart';

class MapView extends StatefulWidget {
  final MapController mapController;
  final bool isMapReady;
  final Function(bool) onReady;
  final Function(LatLng, double) onMoveToStation;

  /// Optional shared AnimatedMapController. If null, the widget will lazily
  /// create its own. Sharing an instance lets other parts of the screen
  /// (e.g. SearchPanel triggering a card tap) drive the same animation.
  final AnimatedMapController? animatedMap;

  const MapView({
    super.key,
    required this.mapController,
    required this.isMapReady,
    required this.onReady,
    required this.onMoveToStation,
    this.animatedMap,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with TickerProviderStateMixin {
  Timer? _mapMoveDebounceTimer;
  Station? _selectedStation;
  final _stationFormat = const StationFormatHelper();
  AnimatedMapController? _animatedMap;

  /// Effective animated map used inside this widget — either the one injected
  /// by the caller (`widget.animatedMap`) or a lazily-initialized one owned
  /// by this widget.
  AnimatedMapController _getAnimatedMap() {
    if (widget.animatedMap != null) return widget.animatedMap!;
    _animatedMap ??= AnimatedMapController(
      mapController: widget.mapController,
      vsync: this,
    );
    return _animatedMap!;
  }

  void _log(String tag, String message) {
    final now = DateTime.now();
    final timestamp =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}";
    debugPrint("[$timestamp] [$tag] $message");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapVm = Provider.of<MapViewModel>(context, listen: false);
    final initialCenter = mapVm.center ?? mapVm.getEffectiveLocation();

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
            _log("MAP-POS-DEBOUNCED",
                "Center: ${center.latitude.toStringAsFixed(6)}, ${center.longitude.toStringAsFixed(6)}, Zoom: ${zoom.toStringAsFixed(2)}");
          });
        },
        onMapEvent: (event) {
          if (event is MapEventMoveEnd) {
            _log("PERF",
                "Map stable at Zoom: ${widget.mapController.camera.zoom.toStringAsFixed(2)}");
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: theme.brightness == Brightness.dark
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
              : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.youbike.android',
          tileProvider: NetworkTileProvider(),
          keepBuffer: 5,
          tileDisplay:
              const TileDisplay.fadeIn(duration: Duration(milliseconds: 200)),
          tileUpdateTransformer: _animatedMoveTransformer(),
        ),
        Selector<StationViewModel, List<Station>>(
          selector: (_, vm) => vm.fullStations,
          shouldRebuild: (prev, next) => prev.length != next.length,
          builder: (context, stations, child) {
            _log("DEBUG",
                "StationMarkerLayer updating with ${stations.length} stations");
            return StationMarkerLayer(
              stations: stations,
              onStationSelected: (station) {
                _animateToStation(station);
              },
            );
          },
        ),
        Selector<MapViewModel, LatLng?>(
          selector: (_, vm) => vm.center,
          builder: (context, center, child) {
            if (center == null) return const SizedBox.shrink();
            return MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 40,
                  height: 40,
                  child: PulseMarker(
                      latitude: center.latitude, longitude: center.longitude),
                ),
              ],
            );
          },
        ),
        if (_selectedStation != null)
          _buildStationPopup(context, _selectedStation!),
      ],
    );
  }

  Widget _buildStationPopup(BuildContext context, Station station) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return MarkerLayer(
      markers: [
        Marker(
          key: ValueKey('popup_${station.id}'),
          point: LatLng(station.lat, station.lng),
          width: 260,
          height: 220,
          alignment: const Alignment(0, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 260,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _stationFormat.name(
                              station,
                              // 與全站統一，從 AppConfigService.currentLang 取得語言碼。
                              // 原本用 Localizations.localeOf(context).languageCode，
                              // 但與其他 widget 來源不同一，會造成「切換語言後 partial update」。
                              Provider.of<AppConfigService>(context)
                                  .currentLang,
                            ),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _selectedStation = null),
                          child:
                              Icon(Icons.close, size: 18, color: cs.onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoItem(
                          l10n.popupAvailableBikesLabel,
                          station.availableBikes,
                          cs,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoItem(
                          l10n.popupAvailableElectricBikesLabel,
                          station.availableElectricBikes,
                          cs,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoItem(
                          l10n.popupEmptySpacesLabel,
                          station.emptySpaces,
                          cs,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: CustomPaint(
                  painter: _PopupArrowPainter(color: cs.surface),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, int? value, ColorScheme cs) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? '--',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _animateToStation(Station station) {
    setState(() => _selectedStation = station);
    _getAnimatedMap().animateTo(LatLng(station.lat, station.lng), 18.0);
    _loadRealtimeForPopup(station);
  }

  /// 點下圖釘後的「單站即時查」。
  /// 不與 60 秒週期的 n+10 那批走同一路，而是獨立 POST /tw2/parkingInfo。
  /// _popupRealtimeToken 是「selection token」—— 用來辨認查回時使用者是否還在看同一個站。
  int _popupRealtimeToken = 0;

  Future<void> _loadRealtimeForPopup(Station station) async {
    final token = ++_popupRealtimeToken;
    final api = ApiService();
    final data = await api.fetchRealtimeVehicle(station.id);
    if (!mounted) return;
    // 使用者在併行 fetch 期間關閉 popup / 切到別站 → 捨棄此次結果，避免舊資料變現。
    if (token != _popupRealtimeToken) return;
    if (data == null) return;
    station.availableBikes = data['available_2_0'];
    station.availableElectricBikes = data['available_e'];
    station.emptySpaces = data['empty_spaces'];
    LogService().i(
      'MAP',
      'Popup realtime fetched for ${station.id}: yb2=${station.availableBikes}, '
          'eyb=${station.availableElectricBikes}, empty=${station.emptySpaces}',
    );
    setState(() {});
  }

  /// Provide a tileUpdateTransformer, sourced from the shared instance (or
  /// the lazy internal one).  Falls back to the package default when neither
  /// is initialised yet.
  TileUpdateTransformer _animatedMoveTransformer() {
    return _getAnimatedMap().tileUpdateTransformer;
  }

  @override
  void dispose() {
    // Only dispose the internal instance — widget.animatedMap is owned
    // by the caller (e.g. HomeScreen).
    if (widget.animatedMap == null) {
      _animatedMap?.dispose();
    }
    super.dispose();
  }
}

class _PopupArrowPainter extends CustomPainter {
  final Color color;

  _PopupArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StationMarkerLayer extends StatefulWidget {
  final List<Station> stations;
  final ValueChanged<Station> onStationSelected;

  const StationMarkerLayer({
    super.key,
    required this.stations,
    required this.onStationSelected,
  });

  @override
  State<StationMarkerLayer> createState() => _StationMarkerLayerState();
}

class _StationMarkerLayerState extends State<StationMarkerLayer> {
  List<Marker> _cachedMarkers = [];
  MarkerClusterLayerOptions? _clusterOptions;
  int _lastProcessedCount = 0;
  late Map<String, Station> _stationMap;

  void _updateMarkersAndOptions() {
    if (widget.stations.length == _lastProcessedCount &&
        _clusterOptions != null) {
      return;
    }

    final stopwatch = Stopwatch()..start();
    _lastProcessedCount = widget.stations.length;

    // 建立 Station 的 map，用於根據 marker key 查找
    _stationMap = {
      for (var s in widget.stations) s.id: s,
    };

    _cachedMarkers = widget.stations.map((s) {
      return Marker(
        key: ValueKey("st_${s.id}"),
        point: LatLng(s.lat, s.lng),
        width: 40,
        height: 40,
        alignment: Alignment.bottomCenter,
        child: const RoadSignMarker(),
      );
    }).toList();

    _clusterOptions = MarkerClusterLayerOptions(
      maxClusterRadius: 120,
      size: const Size(45, 45),
      alignment: Alignment.center,
      disableClusteringAtZoom: 16,
      markers: _cachedMarkers,
      animationsOptions: const AnimationsOptions(
        zoom: Duration(milliseconds: 200),
        fitBound: Duration(milliseconds: 200),
        spiderfy: Duration(milliseconds: 200),
      ),
      builder: (context, markers) {
        return ClusterMarker(count: markers.length);
      },
      showPolygon: false,
      spiderfySpiralDistanceMultiplier: 3,
      circleSpiralSwitchover: 12,
      onClusterTap: (cluster) {
        debugPrint(
            "[CLUSTER-TAP] Tapped cluster with ${cluster.markers.length} markers");
      },
      onMarkerTap: (marker) {
        _handleMarkerTap(marker);
      },
    );

    stopwatch.stop();
    debugPrint(
        "[PERF] 🚀 Index rebuilt (9338 points) in ${stopwatch.elapsedMilliseconds}ms");
  }

  void _handleMarkerTap(Marker marker) {
    final key = marker.key;
    if (key is ValueKey<String> && key.value.startsWith('st_')) {
      final stationId = key.value.substring(3);
      final station = _stationMap[stationId];
      if (station != null) {
        widget.onStationSelected(station);
      }
    }
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
    _updateMarkersAndOptions();
    if (_clusterOptions == null) return const SizedBox.shrink();
    return MarkerClusterLayerWidget(options: _clusterOptions!);
  }
}

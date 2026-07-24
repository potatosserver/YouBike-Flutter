import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:youbike/core/utils/log_service.dart';
import 'package:youbike/data/models/station.dart';
import 'package:youbike/data/services/api_service.dart';
import 'package:youbike/providers/map_view_model.dart';
import 'package:youbike/providers/station_view_model.dart';
import 'package:youbike/ui/widgets/map_markers.dart';
import 'package:youbike/ui/widgets/pulse_marker.dart';
import 'package:youbike/ui/widgets/clustered_marker_layer.dart';
import 'package:youbike/core/theme/brand_colors.dart';
import 'package:youbike/data/models/moovo_station.dart';
import 'package:youbike/providers/moovo_view_model.dart';
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

  /// 「已選中顯示彈窗」的來源。YouBike 裝 [Station],Moovo 裝 [MoovoStation]。
  /// 動畫顯示同樣的小談窗 widget,只是資料欄位來源不同。
  Object? _selected;
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
        // 禁止雙指旋轉地圖，只保留平移、縮放等單軸手勢。
        // 旋轉會讓 bearing 進入非常規值，配合瘋狂縮放時容易觸發
        // `TileRangeCalculator` 內部 `viewingZoom` 在邊界處算出 NaN，
        // 進而引爆 `Unsupported operation: Infinity or NaN toInt`。
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all - InteractiveFlag.rotate,
        ),
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
        // Moovo 圖釘層 — 與 YouBike 完全平行、不混層。
        // 由 useMoovo gate: 開關 false 時 MoovoViewModel.stations 為空,layer = SizedBox.shrink。
        Selector<MoovoViewModel, bool>(
          selector: (_, vm) => vm.isReady && vm.stations.isNotEmpty,
          builder: (context, hasMoovo, _) {
            if (!hasMoovo) return const SizedBox.shrink();
            return MoovoMapLayer(
              onStationTap: (s) {
                setState(() => _selected = s);
                _animateToMoovoStation(s);
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
        if (_selected != null)
          _buildStationPopup(context, _selected!),
      ],
    );
  }

  Widget _buildStationPopup(BuildContext context, Object selected) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    // 共用彈窗 — 從來源 (YouBike Station 或 Moovo MoovoStation) 抽出相同結構的資料。
    // (name, position, available 普通車, available 電輔車, 空位)
    final String name;
    final LatLng position;
    final int? bikes;
    final int? ebikes;
    final int? empty;
    final Key markerKey;
    final String lang = Provider.of<AppConfigService>(context).currentLang;

    if (selected is Station) {
      name = _stationFormat.name(selected, lang);
      position = LatLng(selected.lat, selected.lng);
      bikes = selected.availableBikes;
      ebikes = selected.availableElectricBikes;
      empty = selected.emptySpaces;
      markerKey = ValueKey('popup_${selected.id}');
    } else if (selected is MoovoStation) {
      name = selected.displayName(lang);
      position = LatLng(selected.lat, selected.lon);
      bikes = selected.bikeCount;
      ebikes = selected.ebikeCount;
      empty = selected.emptySpaces;
      markerKey = ValueKey('popup_${selected.id}');
    } else {
      return const SizedBox.shrink();
    }

    return MarkerLayer(
      markers: [
        Marker(
          key: markerKey,
          point: position,
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
                            name,
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
                          onTap: () => setState(() => _selected = null),
                          child:
                              Icon(Icons.close, size: 18, color: cs.onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 對齊 [BikeStationCard] 的決定:
                    // YouBike popup 來源顯示 (一般 / 電輔 / 空位)。
                    // Moovo popup 只留 (一般) — 「可借」(新 key popupRentableBikesLabel)。
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoItem(
                          selected is Station
                              ? l10n.popupAvailableBikesLabel
                              : l10n.popupRentableBikesLabel,
                          bikes,
                          cs,
                        ),
                        if (selected is Station) ...[
                          const SizedBox(width: 12),
                          _buildInfoItem(
                            l10n.popupAvailableElectricBikesLabel,
                            ebikes,
                            cs,
                          ),
                          const SizedBox(width: 12),
                          _buildInfoItem(
                            l10n.popupEmptySpacesLabel,
                            empty,
                            cs,
                          ),
                        ],
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

  void _animateToMoovoStation(MoovoStation station) {
    // 與 YouBike `_animateToStation` 同步風格:相同 `animateTo` API + 切換彈窗。
    setState(() => _selected = station);
    _getAnimatedMap().animateTo(LatLng(station.lat, station.lon), 18.0);
    _log('MOOVO', 'animate to ${station.nameTw} (${station.lat},${station.lon})');
  }

  void _animateToStation(Station station) {
    setState(() => _selected = station);
    _getAnimatedMap().animateTo(LatLng(station.lat, station.lng), 18.0);
    _loadRealtimeForPopup(station);
  }

  /// 點下圖釘後的「單站即時查」。
  /// 走 batch HTTP 入口（傳 1 個元素的 list）；解析在三欄上同時可行時才視為有資料,
  /// 全缺/不在 server 回應內 → 不寫入,亦不做 0 解讀,以免把「該站不在此次回應」誤成「無車可借」。
  /// _popupRealtimeToken 是「selection token」—— 用來辨認查回時使用者是否還在看同一個站。
  int _popupRealtimeToken = 0;

  Future<void> _loadRealtimeForPopup(Station station) async {
    final token = ++_popupRealtimeToken;
    final api = ApiService();
    Map<String, dynamic>? data;
    try {
      final batch = await api.fetchRealtimeVehicles([station.id]);
      final raw = batch[station.id];
      if (raw is Map) data = raw.cast<String, dynamic>();
    } catch (e) {
      LogService().e('MAP', 'Popup realtime request failed', error: e);
    }
    if (!mounted) return;
    // 使用者在併行 fetch 期間關閉 popup / 切到別站 → 捨棄此次結果，避免舊資料變現。
    if (token != _popupRealtimeToken) return;
    if (data == null) return;

    int pickNum(Map<String, dynamic> src, String key) {
      final v = src[key];
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? -1;
      return -1;
    }

    final yb2 = pickNum(data, 'available_2_0');
    final eyb = pickNum(data, 'available_e');
    final empty = pickNum(data, 'empty_spaces');
    // 三欄全部讀不到（sentinel -1）→ 視為 server 該站沒回資料,放棄寫入。
    if (yb2 < 0 && eyb < 0 && empty < 0) return;
    station.availableBikes = yb2 < 0 ? 0 : yb2;
    station.availableElectricBikes = eyb < 0 ? 0 : eyb;
    station.emptySpaces = empty < 0 ? 0 : empty;
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

class StationMarkerLayer extends StatelessWidget {
  final List<Station> stations;
  final ValueChanged<Station> onStationSelected;

  const StationMarkerLayer({
    super.key,
    required this.stations,
    required this.onStationSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) return const SizedBox.shrink();
    return ClusteredMarkerLayer<Station>(
      items: stations,
      pointOf: (s) => LatLng(s.lat, s.lng),
      keyOf: (s) => 'st_${s.id}',
      markerChild: (_) => const RoadSignMarker(),
      clusterBuilder: (n) => ClusterMarker(count: n),
      onMarkerTap: onStationSelected,
    );
  }
}

/// Moovo 來源的地圖圖釘層（已聚合）— 與 [StationMarkerLayer] 並列於地圖 children 內，
/// 但走同一個共用 `ClusteredMarkerLayer` helper，所以群集半徑 / spiderfy 等設定
/// 不重複、視覺風格一致。
///
/// 與 [StationMarkerLayer] 同檔，方便兩來源比對。
class MoovoMapLayer extends StatelessWidget {
  final ValueChanged<MoovoStation>? onStationTap;
  const MoovoMapLayer({super.key, this.onStationTap});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<MoovoViewModel>(context);
    final stations = vm.stations;
    if (stations.isEmpty) return const SizedBox.shrink();

    return ClusteredMarkerLayer<MoovoStation>(
      items: stations,
      pointOf: (s) => LatLng(s.lat, s.lon),
      keyOf: (s) => 'mv_${s.id}',
      markerChild: (_) => const MoovoPinMarker(),
      clusterBuilder: (n) => ClusterMarker(
        count: n,
        color: BrandColors.markerMoovoGreen,
      ),
      onMarkerTap: onStationTap,
    );
  }
}

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:youbike/core/services/realtime_status_manager.dart';
import 'package:youbike/providers/map_view_model.dart';
import 'package:youbike/ui/widgets/map_markers.dart';
import 'package:youbike/ui/widgets/pulse_marker.dart';
import 'package:youbike/ui/widgets/clustered_marker_layer.dart';
import 'package:youbike/core/theme/brand_colors.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/core/services/map_animated_move.dart';
import 'package:youbike/data/models/bike_station.dart';
import 'package:youbike/providers/bike_station_view_model.dart';
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

  /// 在 `onMapReady` 時呼叫；caller 端通常拿 shared trigger 後呼叫 `setReady()`，
  /// 用以避免 Web 平台「first camera read before rendered」例外。
  final VoidCallback? onFirstReady;

  const MapView({
    super.key,
    required this.mapController,
    required this.isMapReady,
    required this.onReady,
    required this.onMoveToStation,
    this.animatedMap,
    this.onFirstReady,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with TickerProviderStateMixin {
  Timer? _mapMoveDebounceTimer;

  BikeStation? _selected;
  AnimatedMapController? _animatedMap;
  RealtimeStatusManager? _realtimeManager;

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
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all - InteractiveFlag.rotate,
        ),
        onMapReady: () {
          _log("MAP-INIT", "Map initialized and ready for use");
          widget.onReady(true);
          // Web 上 attach 後第一次讀 camera 須等到此時；shared trigger 由 caller 注入
          widget.onFirstReady?.call();
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
            // 方案 4 — 移動/縮放結束後,把當前所有已註冊的 unclustered marker
            // 一次性 flush 出去,確保最後一次 unregister 清空時不漏單。
            _realtimeManager?.flush();
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
        Consumer<BikeStationViewModel>(
          builder: (context, bikeVm, _) {
            final all = bikeVm.allBikes;
            if (all.isEmpty) return const SizedBox.shrink();
            final yb = all
                .where((b) => b.source == BikeStationSource.youbike)
                .toList();
            final mo =
                all.where((b) => b.source == BikeStationSource.moovo).toList();

            // 方案 4 — manager lazy init (此 widget 只在 home_screen 有用到,單例 OK)
            // 用 useMapStatusMarkers 旗標決定是否啟用即時 lifecycle hook。
            // 旗標關閉時,marker 退化成純 RoadSignMarker,行為等同舊版。
            final config = Provider.of<AppConfigService>(context, listen: false);
            final useStatus = config.useMapStatusMarkers;
            _realtimeManager ??= RealtimeStatusManager(
              onBatchFetch: bikeVm.fetchRealtimeForIds,
            );

            return Stack(children: [
              if (yb.isNotEmpty)
                ClusteredMarkerLayer<BikeStation>(
                  items: yb,
                  pointOf: (b) => LatLng(b.lat, b.lng),
                  keyOf: (b) => b.sourceKey,
                  markerChild: (ctx, b) => _buildYoubikeMarker(ctx, b),
                  clusterBuilder: (n) => ClusterMarker(count: n),
                  onMarkerTap: (b) => _animateToStation(b),
                  dataVersion: bikeVm.dataVersion,
                  statusManager: useStatus ? _realtimeManager : null,
                  realtimeKeyOf: useStatus ? (b) => b.id : null,
                ),
              if (mo.isNotEmpty)
                ClusteredMarkerLayer<BikeStation>(
                  items: mo,
                  pointOf: (b) => LatLng(b.lat, b.lng),
                  keyOf: (b) => b.sourceKey,
                  markerChild: (ctx, b) => _buildMoovoMarker(ctx, b),
                  clusterBuilder: (n) => ClusterMarker(
                    count: n,
                    color: BrandColors.markerMoovoGreen,
                  ),
                  onMarkerTap: (b) => _animateToStation(b),
                  statusManager: useStatus ? _realtimeManager : null,
                  realtimeKeyOf: useStatus ? (b) => b.id : null,
                ),
            ]);
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
        if (_selected != null) _buildStationPopup(context, _selected!),
      ],
    );
  }

  Widget _buildStationPopup(BuildContext context, BikeStation selected) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final lang = Provider.of<AppConfigService>(context).currentLang;

    final isYoubike = selected.source == BikeStationSource.youbike;
    final String name;
    final LatLng position;
    final int? bikes;
    final int? ebikes;
    final int? empty;
    final Key markerKey;

    name = isYoubike
        ? (lang.startsWith('en') ? selected.nameEn : selected.nameTw)
        : selected.nameTw;
    position = LatLng(selected.lat, selected.lng);
    bikes = selected.bikeCount;
    ebikes = selected.eBikeCount;
    empty = selected.emptySpaces;
    markerKey = ValueKey('popup_${selected.id}');

    return MarkerLayer(
      markers: [
        Marker(
          key: markerKey,
          point: position,
          width: 260,
          height: 120,
          alignment: Alignment.topCenter,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoItem(
                          isYoubike
                              ? l10n.popupAvailableBikesLabel
                              : l10n.popupRentableBikesLabel,
                          bikes,
                          cs,
                        ),
                        if (isYoubike) ...[
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
              SizedBox(
                width: 20,
                height: 10,
                child: CustomPaint(
                  painter: _PopupArrowPainter(color: cs.surface),
                  size: const Size(20, 10),
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

  /// 根據站點即時數據建立帶狀態標記的 YouBike 圖釘。
  /// 狀態標記由 `useMapStatusMarkers` beta 開關控制，預設為關閉（顯示原始圖釘）。
  ///
  /// 簽名升級為 `(BuildContext, BikeStation)` — 由 [ClusteredMarkerLayer.markerChild]
  /// 在 `ListenableBuilder<BikeStationViewModel>` 的 builder 內呼叫,
  /// 保證 station 物件已是最新即時資料。
  Widget _buildYoubikeMarker(BuildContext ctx, BikeStation b) {
    final config = Provider.of<AppConfigService>(ctx, listen: false);
    if (!config.useMapStatusMarkers) return const RoadSignMarker();
    final eBikeCount = b.eBikeCount ?? 0;
    final bikes = b.bikeCount ?? 0;
    final empty = b.emptySpaces ?? 0;
    final st = b.status ?? 1;
    final parking = b.parkingSpaces; // 保持 nullable：null=尚未收到即時資料

    // 是否已收到即時資料（parkingSpaces 被寫入即為真）
    final hasRealtime = parking != null;

    // 總可借車輛數 (普通車 2.0 + 電輔車 2.0E)
    final totalBikes = bikes + eBikeCount;

    // 暫停營運判定：
    //   1) API status=2
    //   2) 已收到即時資料 且 總車輛數與空位全為 0
    final suspended = st == 2 || (hasRealtime && totalBikes == 0 && empty == 0);
    // 有電輔車
    final hasElectric = eBikeCount > 0;
    // 無位可還 (車位滿載)：無空格但仍有車可借
    final isFull = hasRealtime && !suspended && empty == 0 && totalBikes > 0;
    // 無車可借：普通車與電輔車皆為 0（兩者皆無），且有空格可還
    final noBikes = hasRealtime && !suspended && totalBikes == 0 && empty > 0;

    return BikePinMarker.youbike(
      hasElectric: hasElectric,
      isFull: isFull,
      noBikes: noBikes,
      isSuspended: suspended,
    );
  }

  /// 根據站點即時數據建立帶狀態標記的 Moovo 圖釘。
  Widget _buildMoovoMarker(BuildContext ctx, BikeStation b) {
    final config = Provider.of<AppConfigService>(ctx, listen: false);
    if (!config.useMapStatusMarkers) return const MoovoPinMarker();
    
    // 根據要求：僅依靠 bikeCount (對應 Moovo 的 nearbyBikeCount) 判斷
    final bikes = b.bikeCount ?? 0;
    
    // 只支援「無車」顯示
    final noBikes = bikes == 0;
    
    return BikePinMarker.moovo(
      hasElectric: false, // 不再判斷電輔車
      isFull: false,      // 不再判斷滿載
      noBikes: noBikes,
    );
  }

  void _animateToStation(BikeStation bs) {
    // 1. 觸發單站即時更新（beta 模式已由 RealtimeStatusManager 接管，跳過節省流量）
    final config = Provider.of<AppConfigService>(context, listen: false);
    if (!config.useMapStatusMarkers) {
      Provider.of<BikeStationViewModel>(context, listen: false).refreshStation(bs);
    }

    // 2. 原有邏輯：選中站點並移動地圖
    setState(() => _selected = bs);
    _getAnimatedMap().animateTo(LatLng(bs.lat, bs.lng), 18.0);
  }

  TileUpdateTransformer _animatedMoveTransformer() {
    return _getAnimatedMap().tileUpdateTransformer;
  }

  @override
  void dispose() {
    _realtimeManager?.dispose();
    _realtimeManager = null;
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
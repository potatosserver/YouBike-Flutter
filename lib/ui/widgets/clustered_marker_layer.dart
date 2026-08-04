import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import 'package:youbike/core/services/realtime_status_manager.dart';
import 'package:youbike/ui/widgets/realtime_binding_marker.dart';

abstract class Clusterable {
  LatLng get clusterPoint;
}

class ClusteredMarkerLayer<T> extends StatefulWidget {
  final List<T> items;
  final LatLng Function(T) pointOf;
  final String Function(T) keyOf;

  /// Marker 外觀 builder — 接收 BuildContext + 資料項目。
  /// 讓 builder 可以再 `Provider.of` 拿狀態(例如 `_buildYoubikeMarker`
  /// 從 `AppConfigService.useMapStatusMarkers` 決定要不要加狀態外觀)。
  final Widget Function(BuildContext, T) markerChild;

  final Widget Function(int) clusterBuilder;
  final ValueChanged<T>? onMarkerTap;

  /// 即時數據版本（int）。變化時觸發 markers 重建。
  final int dataVersion;

  /// 方案 4 — 把目前可見 marker 的 station id 註冊進去的 manager。
  /// 通常是單一 app-level `RealtimeStatusManager` instance,透過 Provider 注入。
  final RealtimeStatusManager? statusManager;

  /// 從 [T] 抽出 manager 用的 id。
  /// 與 [keyOf] 解耦 — keyOf 是給套件內部 marker 識別用(允許前綴如 "yb_"),
  /// realtimeKeyOf 是給後端即時資料用的純 station id(就是後端認得的字串)。
  /// 任一為 null → 不啟用 lifecycle hook。
  final String Function(T)? realtimeKeyOf;

  // 共用 cluster 設定：跟既有 StationMarkerLayer 對齊。
  final int maxClusterRadius;
  final Size size;
  final int disableClusteringAtZoom;
  final AnimationsOptions animationsOptions;
  final bool showPolygon;
  final int spiderfySpiralDistanceMultiplier;
  final int circleSpiralSwitchover;

  const ClusteredMarkerLayer({
    super.key,
    required this.items,
    required this.pointOf,
    required this.keyOf,
    required this.markerChild,
    required this.clusterBuilder,
    this.onMarkerTap,
    this.dataVersion = 0,
    this.statusManager,
    this.realtimeKeyOf,
    this.maxClusterRadius = 180,
    this.size = const Size(45, 45),
    this.disableClusteringAtZoom = 16,
    this.animationsOptions = const AnimationsOptions(
      zoom: Duration(milliseconds: 200),
      fitBound: Duration(milliseconds: 200),
      spiderfy: Duration(milliseconds: 200),
    ),
    this.showPolygon = false,
    this.spiderfySpiralDistanceMultiplier = 3,
    this.circleSpiralSwitchover = 12,
  });

  @override
  State<ClusteredMarkerLayer<T>> createState() => _ClusteredMarkerLayerState<T>();
}

class _ClusteredMarkerLayerState<T> extends State<ClusteredMarkerLayer<T>> {
  late List<Marker> _cachedMarkers;
  late Map<String, T> _itemByKey;
  late MarkerClusterLayerOptions _options;
  int _lastVersion = -1;

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  @override
  void didUpdateWidget(covariant ClusteredMarkerLayer<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 長度、statusManager、realtimeKeyOf 或 dataVersion 變化 → 重建 markers（不複製 list）
    if (oldWidget.items.length != widget.items.length ||
        oldWidget.statusManager != widget.statusManager ||
        oldWidget.realtimeKeyOf != widget.realtimeKeyOf ||
        _lastVersion == -1 ||
        _lastVersion != widget.dataVersion) {
      _rebuild();
    }
  }

  void _rebuild() {
    _lastVersion = widget.dataVersion;
    _itemByKey = {for (final t in widget.items) widget.keyOf(t): t};
    _cachedMarkers = [
      for (final t in widget.items)
        Marker(
          key: ValueKey<String>(widget.keyOf(t)),
          point: widget.pointOf(t),
          width: 40,
          height: 40,
          alignment: Alignment.bottomCenter,
          child: _wrapChild(context, t),
        ),
    ];
    _options = MarkerClusterLayerOptions(
      maxClusterRadius: widget.maxClusterRadius,
      size: widget.size,
      alignment: Alignment.center,
      disableClusteringAtZoom: widget.disableClusteringAtZoom,
      markers: _cachedMarkers,
      animationsOptions: widget.animationsOptions,
      builder: (context, markers) => widget.clusterBuilder(markers.length),
      showPolygon: widget.showPolygon,
      spiderfySpiralDistanceMultiplier: widget.spiderfySpiralDistanceMultiplier,
      circleSpiralSwitchover: widget.circleSpiralSwitchover,
      onClusterTap: (cluster) {
        debugPrint('[CLUSTER-TAP] cluster size=${cluster.markers.length}');
      },
      onMarkerTap: widget.onMarkerTap == null
          ? null
          : (marker) {
              final k = marker.key;
              if (k is ValueKey<String>) {
                final item = _itemByKey[k.value];
                if (item != null) widget.onMarkerTap!(item);
              }
            },
    );
  }

  Widget _wrapChild(BuildContext context, T item) {
    final manager = widget.statusManager;
    final keyOf = widget.realtimeKeyOf;
    // 兩者皆備 → 啟用方案 4 lifecycle hook
    if (manager != null && keyOf != null) {
      final realtimeKey = keyOf(item);
      if (realtimeKey.isEmpty) {
        return _buildMarkerChild(context, item);
      }
      return RealtimeBindingMarker(
        item: item,
        statusManager: manager,
        realtimeKey: realtimeKey,
        builder: (ctx, _) => _buildMarkerChild(ctx, item),
      );
    }
    return _buildMarkerChild(context, item);
  }

  Widget _buildMarkerChild(BuildContext context, T item) {
    return widget.markerChild(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return MarkerClusterLayerWidget(options: _options);
  }
}

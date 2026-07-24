import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

/// 共用 helper:把一群帶 (lat,lng) 的資料項目畫成「聚合 Marker Layer」。
///
/// 複用既有 `flutter_map_marker_cluster` 的群集邏輯,只把
/// `marker` 轉成 Visible Marker、把 `cluster widget` 用 Builder 指定。
///
/// 用法範例:
/// ```
/// final layer = ClusteredMarkerLayer<Station>(
///   items: stations,
///   pointOf: (s) => LatLng(s.lat, s.lng),
///   keyOf: (s) => 'st_${s.id}',
///   markerChild: (_) => const RoadSignMarker(),
///   clusterBuilder: (n) => ClusterMarker(count: n),
///   onMarkerTap: (s) => onStationTap(s),
///   maxClusterRadius: 120,
/// );
/// ```
///
/// 為什麼要這個 helper,而非讓每個來源自己寫:
/// - YouBike 是黃色 + 40px RoadSign、Moovo 是綠色 + 40px MoovoPin
/// - 但「聚合半徑、spiderfy 距離、cluster tap」這些幾乎全一致
/// - 只要 dropdown / 增加一個 BikeProvider 只要寫一個 markerChild + 一個 clusterBuilder
/// - 不用再 fork StationMarkerLayer
abstract class Clusterable {
  LatLng get clusterPoint;
}

class ClusteredMarkerLayer<T> extends StatefulWidget {
  final List<T> items;
  final LatLng Function(T) pointOf;
  final String Function(T) keyOf;
  final Widget Function(T) markerChild;
  final Widget Function(int) clusterBuilder;
  final ValueChanged<T>? onMarkerTap;

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
    this.maxClusterRadius = 120,
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
  int _lastCount = -1;

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  @override
  void didUpdateWidget(covariant ClusteredMarkerLayer<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length || _lastCount == -1) {
      _rebuild();
    }
  }

  void _rebuild() {
    _lastCount = widget.items.length;
    _itemByKey = {for (final t in widget.items) widget.keyOf(t): t};
    _cachedMarkers = [
      for (final t in widget.items)
        Marker(
          key: ValueKey<String>(widget.keyOf(t)),
          point: widget.pointOf(t),
          width: 40,
          height: 40,
          alignment: Alignment.bottomCenter,
          child: widget.markerChild(t),
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

  @override
  Widget build(BuildContext context) {
    return MarkerClusterLayerWidget(options: _options);
  }
}

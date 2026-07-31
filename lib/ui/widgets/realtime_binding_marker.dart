import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:youbike/core/services/realtime_status_manager.dart';
import 'package:youbike/providers/bike_station_view_model.dart';

/// 把一個 marker 的 Widget Lifecycle 接到 [RealtimeStatusManager] —
/// 方案 4 (Widget Lifecycle) 的實際 mount 點。
///
/// 運作流程:
/// 1. `flutter_map_marker_cluster` 在某一影格決定「這個 station 是 unclustered」並把
///    它的 [Marker.child] 渲染出來 → 本 widget 的 [State.initState] 觸發 →
///    `manager.register(realtimeKey)`。
/// 2. 同一影格內其他 marker 也 mount → register,它們都會被 manager 收集起來。
/// 3. 100ms 防抖到期 → manager 呼叫 `onBatchFetch([id1, id2, ...])` 一次 batch 抓資料。
/// 4. `BikeStationViewModel` 拿到回應後 `_dataVersion++` + `notifyListeners()`,
///    本 widget 的 [Consumer] 收到 → 重新 [builder] → 拿到最新 BikeStation 渲染外觀。
/// 5. 當 marker 被 cluster 收進去或被移出畫面,套件會把 [Marker.child] 銷毀 →
///    本 widget 的 [State.dispose] 觸發 → `manager.unregister(realtimeKey)`。
///
/// [builder] 函式與 `ClusteredMarkerLayer.markerChild` 行為對齊:
/// 你不再寫 `Marker(child: BikePinMarker.youbike(...))`,
/// 而是寫 `Marker(child: RealtimeBindingMarker(bikeStation, manager, keyOf, builder))`。
class RealtimeBindingMarker extends StatefulWidget {
  /// 原始資料項目 — 保留它是為了讓 [builder] 可以直接拿到 domain 物件。
  /// 編譯器層面以 `Object?` 接收,避免在 `ClusteredMarkerLayer<T>` 內
  /// 引入額外的泛型耦合。builder 內已知具體型別,需要時自行 cast。
  final Object? item;

  /// manager — 接受 null 以保留向後相容(無 manager → 退化成純渲染,不註冊)。
  final RealtimeStatusManager? statusManager;

  /// 對應 [RealtimeStatusManager] 註冊用的 id(通常是 stationId)。
  /// 由呼叫端提供而非從 [item] 反推 — 因為 `T` 是泛型,
  /// binding widget 不該知道 item 內部結構。
  final String realtimeKey;

  /// 實際渲染 marker 外觀的函式 — 在 [Consumer] 的 builder 中呼叫,
  /// 確保 status 變動時 widget 自動 rebuild。
  /// 接收 `Object?` 對齊 [item];builder 內已知具體型別,需要時自行 cast。
  final Widget Function(BuildContext context, Object? item) builder;

  const RealtimeBindingMarker({
    super.key,
    required this.item,
    required this.statusManager,
    required this.realtimeKey,
    required this.builder,
  });

  @override
  State<RealtimeBindingMarker> createState() => _RealtimeBindingMarkerState();
}

class _RealtimeBindingMarkerState extends State<RealtimeBindingMarker> {
  @override
  void initState() {
    super.initState();
    widget.statusManager?.register(widget.realtimeKey);
  }

  @override
  void dispose() {
    widget.statusManager?.unregister(widget.realtimeKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 訂閱 VM 的 dataVersion — 只要 VM 寫回即時資料 + notify,
    // 本 widget 就 rebuild,builder 內能拿到最新資料。
    return ListenableBuilder(
      listenable: context.read<BikeStationViewModel>(),
      builder: (ctx, _) => widget.builder(ctx, widget.item),
    );
  }
}

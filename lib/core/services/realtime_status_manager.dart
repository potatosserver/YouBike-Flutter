import 'dart:async';

import 'package:flutter/foundation.dart';

/// 「目前畫面上**未聚合**的 station id」即時註冊簿 — 方案 4 (Widget Lifecycle) 的核心。
///
/// 設計目的:
/// - `flutter_map_marker_cluster` 套件原生**沒有**提供「某 marker 是否處於聚合」的查詢介面。
/// - 但 Flutter Widget 生命週期天然提供這個信號:
///   - Marker 被解聚合、獨立顯示 → `initState` 觸發
///   - Marker 被聚合進 Cluster 圓圈,或被移出畫面 → `dispose` 觸發
/// - 所以本類別把「自行宣告自己可見」的權力交給 Marker widget 自己。
///
/// 用法:
/// 1. `ClusteredMarkerLayer` 收到 `statusManager + realtimeKeyOf` 後,
///    把 `markerChild` 換成 `RealtimeBindingMarker<T>(item, manager, realtimeKeyOf, childBuilder)`。
/// 2. `RealtimeBindingMarker.initState` → `manager.register(id)`
/// 3. `RealtimeBindingMarker.dispose` → `manager.unregister(id)`
/// 4. Manager 100ms 防抖內集滿所有當前可見 id,呼叫 [onBatchFetch] 一次性請求即時資料。
///
/// 為什麼是 ChangeNotifier?
/// - 雖然 register/unregister 已能精準反應,但 fetch 完成後,
///   `RealtimeBindingMarker` 也要一個機制被告知「該站即時資料已到」,
///   通常是直接 `Consumer<BikeStationViewModel>` 讀最新 `_dataVersion`,
///   所以本類別自身不需要 `notifyListeners`。
class RealtimeStatusManager {
  RealtimeStatusManager({required this.onBatchFetch});

  /// 100ms 防抖 — 同一影格內被解聚合的多個 marker 不會觸發多次 batch 請求。
  static const Duration _debounce = Duration(milliseconds: 100);

  /// Batch 觸發時的回呼。接收「目前所有未聚合 marker 的 station id 清單」。
  /// 由 [BikeStationViewModel.fetchRealtimeForIds] 負責實際 HTTP 請求 + TTL 過濾。
  final Future<void> Function(List<String> ids) onBatchFetch;

  final Set<String> _visibleIds = <String>{};

  /// 觀察用 — 上一批實際送出的 id 數量(用於 debug / log)。
  int get visibleCount => _visibleIds.length;
  Set<String> get visibleIdsSnapshot => Set<String>.unmodifiable(_visibleIds);

  Timer? _debounceTimer;
  bool _inflight = false;

  /// 當獨立 marker 出現在畫面上時呼叫。
  /// 100ms 內集滿所有 mount 完成的新 marker,再一次性 batch 送出。
  void register(String id) {
    if (id.isEmpty) return;
    final added = _visibleIds.add(id);
    if (!added) return;
    _schedule();
  }

  /// 當 marker 被聚合或離開畫面時呼叫。
  /// 不主動取消正在進行的 in-flight 請求 — 下一輪防抖週期會自動用新的 ID 清單。
  void unregister(String id) {
    if (id.isEmpty) return;
    if (_visibleIds.remove(id)) {
      _schedule(); // 提早觸發下一輪,讓聚合變化即時反映到下一批請求
    }
  }

  /// 強制刷新 — 例如地圖 `onMapEventMoveEnd` 後主動踢一輪,避免「最後一次 unregister
  /// 剛好清空 → 防抖永不觸發」這種邊界條件。
  void flush() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _runBatch();
  }

  /// 清空所有註冊(用於 widget tree dispose,例如切換 region)。
  void clear() {
    _visibleIds.clear();
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  void _schedule() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, _runBatch);
  }

  Future<void> _runBatch() async {
    if (_visibleIds.isEmpty) return;
    if (_inflight) return;
    _inflight = true;
    // snapshot — 避免送出後又被 register/unregister 干擾
    final snapshot = List<String>.from(_visibleIds);
    try {
      await onBatchFetch(snapshot);
    } catch (e) {
      // onBatchFetch 由 VM 自行負責錯誤處理,這裡只吞例外避免 manager 崩潰
      if (kDebugMode) {
        debugPrint('[RealtimeStatusManager] batch fetch error: $e');
      }
    } finally {
      _inflight = false;
      // 送出後可能又 register/unregister 過,補一輪防抖確保最新狀態被覆蓋
      if (_visibleIds.isNotEmpty && _debounceTimer == null) {
        _schedule();
      }
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _visibleIds.clear();
  }
}

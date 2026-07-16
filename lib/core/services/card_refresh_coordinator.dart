import 'package:latlong2/latlong.dart';
import 'package:youbike/core/services/location_resolver.dart';
import 'package:youbike/core/services/station_sorter.dart';
import 'package:youbike/core/services/realtime_updater.dart';
import 'package:youbike/core/services/map_move_trigger.dart';
import 'package:youbike/data/models/station.dart';
import 'package:youbike/providers/map_view_model.dart';

/// 一鍵完整卡片更新協調器：
///   1. 解析參考座標
///   2. 排序 + 釘選置頂 + 取前 N
///   3. 取得並填入即時車輛數據
///   4. 觸發地圖移動（若有指定）
///
/// 四個子步驟皆委派給專屬服務。
class CardRefreshCoordinator {
  final LocationResolver _location;
  final StationSorter _sorter;
  final RealtimeUpdater _updater;
  final MapMoveTrigger _mapTrigger;

  CardRefreshCoordinator({
    LocationResolver? locationResolver,
    StationSorter? stationSorter,
    RealtimeUpdater? realtimeUpdater,
    MapMoveTrigger? mapMoveTrigger,
  })  : _location = locationResolver ?? const LocationResolver(),
        _sorter = stationSorter ?? StationSorter(),
        _updater = realtimeUpdater ?? const RealtimeUpdater(),
        _mapTrigger = mapMoveTrigger ?? MapMoveTrigger();

  MapMoveTrigger get mapTrigger => _mapTrigger;

  /// 完整流程。回傳即時數據填入後的前 N 筆站點清單。
  /// 若提供 [moveTo]，刷新後地圖中心移至該位置。
  Future<List<Station>> execute({
    required List<Station> fullStations,
    required Set<String> pinnedIds,
    required MapViewModel mapVm,
    int limit = 10,
    LatLng? moveTo,
  }) async {
    final refPoint = _location.resolve(mapVm);

    final candidates =
        _sorter.sortAndPick(fullStations, refPoint, pinnedIds, limit: limit);

    await _updater.apply(candidates, refPoint);

    if (moveTo != null) _mapTrigger.fire(moveTo);

    return candidates;
  }
}

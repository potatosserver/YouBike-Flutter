import 'package:latlong2/latlong.dart';
import 'package:youbike_android/core/services/location_resolver.dart';
import 'package:youbike_android/core/services/station_sorter.dart';
import 'package:youbike_android/core/services/realtime_updater.dart';
import 'package:youbike_android/core/services/map_move_trigger.dart';
import 'package:youbike_android/data/models/station.dart';
import 'package:youbike_android/providers/map_view_model.dart';

/// Orchestrates a full card refresh in one call:
///   1. resolve reference point
///   2. sort + pin + pick top N
///   3. fetch & apply realtime vehicle data
///   4. trigger map move (if caller requests)
///
/// All four sub-steps are delegated to dedicated services.
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
        _updater = realtimeUpdater ?? RealtimeUpdater(),
        _mapTrigger = mapMoveTrigger ?? MapMoveTrigger();

  MapMoveTrigger get mapTrigger => _mapTrigger;

  /// Full pipeline. Returns the final top-N list after realtime data applied.
  /// If [moveTo] is provided, the map is centered on that position after refresh.
  Future<List<Station>> execute({
    required List<Station> fullStations,
    required Set<String> pinnedIds,
    required MapViewModel mapVm,
    int limit = 10,
    LatLng? moveTo,
  }) async {
    // 1. Resolve reference point
    final refPoint = _location.resolve(mapVm);

    // 2. Sort, pin-prioritize, pick top N
    final candidates = _sorter.sortAndPick(fullStations, refPoint, pinnedIds,
        limit: limit);

    // 3. Fetch realtime data
    await _updater.apply(candidates, refPoint);

    // 4. Move map if requested
    if (moveTo != null) _mapTrigger.fire(moveTo);

    return candidates;
  }
}
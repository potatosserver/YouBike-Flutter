import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:youbike/data/models/station.dart';
import 'package:youbike/data/models/moovo_station.dart';
import 'package:youbike/providers/station_view_model.dart';
import 'package:youbike/ui/widgets/route_detail_panel.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/core/services/station_format_helper.dart';
import 'package:youbike/ui/widgets/app_shapes.dart';
import 'package:youbike/ui/widgets/bike_station_card.dart';
import 'package:youbike/core/services/bike_station_mixer.dart';
import 'package:youbike/providers/moovo_view_model.dart';

class SearchPanel extends StatefulWidget {
  final bool isWide;
  final double? panelHeight;
  final Function(double) onHeightChanged;
  final MapController mapController;

  const SearchPanel({
    super.key,
    required this.isWide,
    this.panelHeight,
    required this.onHeightChanged,
    required this.mapController,
  });

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  static const _fmt = StationFormatHelper();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _isFocused = false;
  bool _hasText = false;
  // Running drag height inside a single gesture. Mirrors the original
  // home_screen implementation: kept here (instance state) instead of via
  // `widget.panelHeight` because the parent rebuilds only after the callback
  // returns — so the prop would lag every frame.
  double _dragBase = 0.0;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleFocusChange);
    _searchController.addListener(_handleTextChange);
    _dragBase = widget.panelHeight ?? 0.0;
  }

  /// `MediaQuery.of(context)` 不能在 `initState` 內呼叫 → 移到 didChangeDependencies。
  /// 原 line 49 違反 MountedInheritedWidget 規則,Web Chrome 上會炸。
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dragBase == 0.0 && widget.panelHeight == null) {
      _dragBase = MediaQuery.of(context).size.height * 0.35;
    }
    // 初次綁定時若有 current text,跑一次確保 VM 知道目前 query。
    _kickCrossCitySearchIfNeeded(_searchController.text.trim());
  }

  void _handleFocusChange() {
    setState(() => _isFocused = _searchFocusNode.hasFocus);
  }

  void _handleTextChange() {
    setState(() => _hasText = _searchController.text.isNotEmpty);
    _kickCrossCitySearchIfNeeded(_searchController.text.trim());
  }

  /// 監聽「搜尋 query」,在 querystring 非空時 kick 跨城搜尋 —
  /// 使「埤頭繪本公園」即使使用者位在高雄也能找到彰化埤頭鄉的站。
  String _lastCrossQuery = '';
  void _kickCrossCitySearchIfNeeded(String q) {
    final config = AppConfigService();
    if (!config.useMoovo) {
      if (_lastCrossQuery.isNotEmpty) {
        _lastCrossQuery = '';
        try {
          Provider.of<MoovoViewModel>(context, listen: false).clearCrossSearch();
        } catch (_) {
          // Provider tree 尚未就緒(MoovoVM 還沒 attach,例如首屏) → 安全忽略。
        }
      }
      return;
    }
    if (q == _lastCrossQuery) return;
    _lastCrossQuery = q;
    if (q.isEmpty) {
      try {
        Provider.of<MoovoViewModel>(context, listen: false).clearCrossSearch();
      } catch (_) {}
      return;
    }
    try {
      Provider.of<MoovoViewModel>(context, listen: false)
          .searchAcrossCities(q);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    Provider.of<StationViewModel>(context, listen: false).setQuery('');
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Consumer<StationViewModel>(
      builder: (context, stationVm, child) {
        final l10n = AppLocalizations.of(context);
        return Column(
          children: [
            if (!widget.isWide)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  // Mirrors the original home_screen implementation: the
                  // running height lives in this instance field instead of
                  // crossing the widget boundary via `widget.panelHeight`,
                  // which only refreshes on a parent build and would
                  // otherwise let the panel lag or jitter.
                  _dragBase -= details.delta.dy;
                  final newHeight = _dragBase.clamp(
                      screenHeight * 0.2, screenHeight * 0.8);
                  widget.onHeightChanged(newHeight);
                },
                child: Container(
                  width: double.infinity,
                  height: 24,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: 6,
                      decoration: BoxDecoration(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 3,
                                offset: const Offset(0, 1))
                          ]),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: widget.isWide
                            ? const Offset(1, 0)
                            : const Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: _isFocused ? 0.15 : 0.08),
                              blurRadius: _isFocused ? 6 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          textAlignVertical: TextAlignVertical.center,
                          // Show a magnifying-glass / "search" key on the
                          // soft keyboard so the user can submit by Enter.
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: l10n.input_placeholder,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0),
                            suffixIcon: SizedBox(
                              width: 64,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_hasText)
                                    GestureDetector(
                                      onTap: _clearSearch,
                                      child: Icon(Icons.clear,
                                          color: cs.onSurfaceVariant, size: 24),
                                    ),
                                  if (_hasText) const SizedBox(width: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: GestureDetector(
                                      // Tapping the trailing search icon
                                      // submits the current input — same
                                      // effect as pressing the soft-keyboard
                                      // Enter key.
                                      onTap: () => stationVm
                                          .setQuery(_searchController.text),
                                      child: Icon(Icons.search,
                                          color: cs.onSurfaceVariant, size: 24),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          onSubmitted: (val) {
                            stationVm.setQuery(val);
                            // Dismiss the keyboard so the search result
                            // is unobstructed.
                            _searchFocusNode.unfocus();
                          },
                          style: TextStyle(fontSize: 14, color: cs.onSurface),
                        ),
                      ),
                    ),
                    Expanded(child: _buildStationPanel(stationVm, l10n, cs)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStationPanel(
          StationViewModel stationVm, AppLocalizations? l10n, ColorScheme cs) =>
      SizedBox(
        width: double.infinity,
        child: Consumer2<StationViewModel, MoovoViewModel>(
          builder: (context, stationVm, moovoVm, _) {
            // 兩源混合:YouBike 全量 + Moovo 全量 → Mixer 依距離升序 → 取 N 名。
            // - 非搜尋: 30 名 (原 YouBike 預設 20 + 預留 Moovo 空間)。
            // - 搜尋: 40 名,同時匹配兩來源 name / address。
            //
            // 跨城搜尋: query 非空時從 VM 的快取取「全台命中」
            // 即使使用者地圖中心在地區之外也能看到外地站點。
            const nonSearchLimit = 30;
            const searchLimit = 40;
            const mixer = BikeStationMixer();
            final lang = Provider.of<AppConfigService>(context).currentLang;
            final useMoovo = Provider.of<AppConfigService>(context).useMoovo;
            final List<MoovoStation> moovoStations =
                useMoovo ? moovoVm.stationsWithDistance : const <MoovoStation>[];
            final List<Station> youbike = stationVm.fullStations;

            final activeQuery = stationVm.activeQuery.trim();
            // Moovo 的 `_stations` 已是全台 459 池,searchAcross 本地 where 即時命中 —
            // 不需要額外「跨城 larger 池」分支,直接傳近 Mixer 就好。
            // (舊 cycle 裡我們用 `extraMoovo` 補跨城命中,API rewrite 後行為內化。)
            final items = activeQuery.isEmpty
                ? mixer.topNByDistance(
                    youbike: youbike,
                    moovo: moovoStations,
                    limit: nonSearchLimit,
                    lang: lang,
                  )
                : mixer.searchAcross(
                    youbike: youbike,
                    moovo: moovoStations,
                    query: activeQuery,
                    limit: searchLimit,
                    lang: lang,
                  );

            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off,
                        size: 64, color: cs.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(l10n?.noStationsFound ?? 'No stations found',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 16)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return BikeStationCard(
                  item: item,
                  onTap: () {
                    // 導航地圖 / 路線 — 兩來源暫只 call YouBike 路徑 (route panel
                    // 仍吃 Station); Moovo 路線 / 路徑未來接 v2 先用 move。
                    if (item.source == StationSource.youbike) {
                      _moveMapToStationById(item.id);
                    } else {
                      // Moovo:直接呼叫 MapMoveTrigger 觸發 fanout,
                      // stationVm 內部 listener 會被動接收地圖中心變動。
                      _moveMapForMoovo(item);
                    }
                  },
                  onNavigate: () {
                    if (item.source == StationSource.youbike) {
                      _routeYoubikeItem(item);
                    } else {
                      // Moovo:目前無獨立 route panel,先導地圖。Route v2之後接。
                      _moveMapForMoovo(item);
                    }
                  },
                );
              },
            );
          },
        ),
      );

  void _moveMapToStationById(String id) {
    final stationVm = Provider.of<StationViewModel>(context, listen: false);
    final hit = stationVm.fullStations.firstWhere(
      (s) => s.id == id,
      orElse: () => stationVm.fullStations.first,
    );
    final target = hit.visualPosition ?? LatLng(hit.lat, hit.lng);
    stationVm.refreshCards(moveTo: target);
  }

  void _routeYoubikeItem(BikeStationItem item) {
    final stationVm = Provider.of<StationViewModel>(context, listen: false);
    final hit = stationVm.fullStations.firstWhere(
      (s) => s.id == item.id,
      orElse: () => stationVm.fullStations.first,
    );
    _moveMapToStationById(hit.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: AppShapes.bottomSheet,
      builder: (context) {
        final lang = Provider.of<AppConfigService>(context).currentLang;
        return RouteDetailPanel(
          destName: _fmt.name(hit, lang),
          destLat: hit.lat,
          destLng: hit.lng,
        );
      },
    );
  }

  void _moveMapForMoovo(BikeStationItem item) {
    // Moovo 來源走通用 `RouteDetailPanel`(只吃名字 + 經緯度,與 YouBike 共用)。
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: AppShapes.bottomSheet,
      builder: (context) => RouteDetailPanel(
        destName: item.name,
        destLat: item.lat,
        destLng: item.lng,
        isMoovo: true,
      ),
    );
  }
}

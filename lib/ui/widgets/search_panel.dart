import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/providers/bike_station_view_model.dart';
import 'package:youbike/ui/widgets/route_detail_panel.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/ui/widgets/app_shapes.dart';
import 'package:youbike/ui/widgets/bike_station_card.dart';
import 'package:youbike/ui/widgets/electric_bike_modal.dart';
import 'package:youbike/core/services/bike_station_mixer.dart';
import 'package:youbike/data/models/bike_station.dart';
import 'package:youbike/ui/widgets/bike_filter_dialog.dart';

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
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _isFocused = false;
  bool _hasText = false;

  // 移動橫條拖曳用的「本次手勢起點」狀態。
  // 真正的 panel 高度來自 widget.panelHeight（父層唯一真相），這裡只記錄
  // drag 開始那一瞬間的高度與指標位置，避免使用累積型 _dragBase 導致
  // 父層第一次回寫 panelHeight 後 _dragBase 沒跟上、第一次更新就瞬間跳位。
  double? _dragStartHeight;
  double? _dragStartGlobalY;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleFocusChange);
    _searchController.addListener(_handleTextChange);
  }

  void _handleFocusChange() {
    setState(() => _isFocused = _searchFocusNode.hasFocus);
  }

  void _handleTextChange() {
    setState(() => _hasText = _searchController.text.isNotEmpty);
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    final vm = Provider.of<BikeStationViewModel>(context, listen: false);
    vm.setQuery('');
    vm.resetFilter();
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Consumer<BikeStationViewModel>(
      builder: (context, bikeVm, child) {
        final l10n = AppLocalizations.of(context);
        final bool isOffline = bikeVm.isOffline;
        final bool isNarrow = !widget.isWide;
        
        return Column(
          children: [
            // 窄螢幕模式下，離線時隱藏拖曳橫條；正常模式顯示
            if (isNarrow && !isOffline)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (details) {
                  // 起點高度取「父層目前持有的 panelHeight」；第一次碰觸時若父層尚未回寫，沿用預設 35%。
                  _dragStartHeight = widget.panelHeight ??
                      MediaQuery.of(context).size.height * 0.35;
                  _dragStartGlobalY = details.globalPosition.dy;
                },
                onVerticalDragUpdate: (details) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  final startHeight = _dragStartHeight;
                  final startY = _dragStartGlobalY;
                  if (startHeight == null || startY == null) return;
                  // 正常模式：最高限制讓面板頂端留在設定按鈕(72) + 空氣(24) = 96px 之下
                  // 定位按鈕在面板頂端上方 20px，如此兩按鈕都有合理呼吸空間
                  final maxHeight = screenHeight - 96;
                  final newHeight = (startHeight -
                          (details.globalPosition.dy - startY))
                      .clamp(screenHeight * 0.2, maxHeight);
                  widget.onHeightChanged(newHeight);
                },
                onVerticalDragEnd: (_) {
                  _dragStartHeight = null;
                  _dragStartGlobalY = null;
                },
                onVerticalDragCancel: () {
                  _dragStartHeight = null;
                  _dragStartGlobalY = null;
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
            // 離線模式窄螢幕：面板移除頂部圓角、頂到螢幕最上方、內部用 Padding 推下搜尋框
            // 正常模式/寬螢幕：維持原本圓角 Container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isNarrow && isOffline ? 0 : 28),
                    topRight: Radius.circular(isNarrow && isOffline ? 0 : 28),
                    bottomLeft: const Radius.circular(28),
                    bottomRight: const Radius.circular(28),
                  ),
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
                    // 離線模式窄螢幕：頂部 72px 奶油色 Padding，推下搜尋框避開設定按鈕
                    if (isNarrow && isOffline)
                      const SizedBox(height: 72),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          16, isNarrow && isOffline ? 12 : 12, 16, 8),
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
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: l10n.input_placeholder,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0),
                            suffixIcon: SizedBox(
                              width: 84,
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
                                      onTap: () =>
                                          bikeVm.setQuery(_searchController.text),
                                      child: Icon(Icons.search,
                                          color: cs.onSurfaceVariant, size: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (Provider.of<AppConfigService>(context, listen: false).useStationFilter && !isOffline)
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => const BikeFilterDialog(),
                                        );
                                      },
                                      child: Icon(
                                        Icons.tune,
                                        color: bikeVm.isFilterActive
                                            ? cs.primary
                                            : cs.onSurfaceVariant,
                                        size: 24,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          onSubmitted: (val) {
                            bikeVm.setQuery(val);
                            _searchFocusNode.unfocus();
                          },
                          style: TextStyle(fontSize: 14, color: cs.onSurface),
                        ),
                      ),
                    ),
                    Expanded(child: _buildStationPanel(bikeVm, l10n, cs, isOffline)),
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
          BikeStationViewModel bikeVm, AppLocalizations? l10n, ColorScheme cs, bool isOffline) =>
      SizedBox(
        width: double.infinity,
        child: Consumer<BikeStationViewModel>(
          builder: (context, bikeVm, _) {
            final items = bikeVm.panelItems;

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return BikeStationCard(
                  item: item,
                  onTap: () {
                    _moveMapToStationById(item.id);
                  },
                  onNavigate: () {
                    if (item.source == StationSource.youbike) {
                      _routeYoubikeItem(item);
                    } else {
                      _moveMapForMoovo(item);
                    }
                  },
                  onShowElectric: item.source == StationSource.youbike
                      ? () => _showElectricBikeDetails(item)
                      : null,
                  isOffline: isOffline,
                );
              },
            );
          },
        ),
      );

  void _showElectricBikeDetails(BikeStationItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ElectricBikeDetailsModal(
        stationId: item.id,
        stationName: item.name,
      ),
    );
  }

  void _moveMapToStationById(String id) {
    final bikeVm = Provider.of<BikeStationViewModel>(context, listen: false);
    final hit = bikeVm.allBikes.firstWhere(
      (b) => b.id == id,
      orElse: () => bikeVm.allBikes.first,
    );
    bikeVm.focusStation(hit);
  }

  void _routeYoubikeItem(BikeStationItem item) {
    final bikeVm = Provider.of<BikeStationViewModel>(context, listen: false);
    final hit = bikeVm.allBikes.firstWhere(
      (b) => b.id == item.id,
      orElse: () => bikeVm.allBikes.first,
    );
    _moveMapToStationById(hit.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: AppShapes.bottomSheet,
      builder: (context) => RouteDetailPanel(
        destName: item.name,
        destLat: hit.lat,
        destLng: hit.lng,
      ),
    );
  }

  void _moveMapForMoovo(BikeStationItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: AppShapes.bottomSheet,
      builder: (context) => RouteDetailPanel(
        destName: item.name,
        destLat: item.lat,
        destLng: item.lng,
        source: BikeStationSource.moovo,
      ),
    );
  }
}
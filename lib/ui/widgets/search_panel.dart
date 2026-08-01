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
  double _dragBase = 0.0;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleFocusChange);
    _searchController.addListener(_handleTextChange);
    _dragBase = widget.panelHeight ?? 0.0;
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
        final config = Provider.of<AppConfigService>(context);
        return Column(
          children: [
            if (!widget.isWide)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  final screenHeight = MediaQuery.of(context).size.height;
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
                                  if (config.useStationFilter) 
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
                    Expanded(child: _buildStationPanel(bikeVm, l10n, cs)),
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
          BikeStationViewModel bikeVm, AppLocalizations? l10n, ColorScheme cs) =>
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
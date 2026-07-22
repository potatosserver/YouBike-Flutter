import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:youbike/providers/station_view_model.dart';
import 'package:youbike/data/models/station.dart';
import 'package:youbike/ui/widgets/station_card.dart';
import 'package:youbike/ui/widgets/route_detail_panel.dart';
import 'package:youbike/ui/widgets/electric_bike_modal.dart';
import 'package:youbike/core/services/station_format_helper.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/ui/widgets/app_shapes.dart';

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
    _dragBase = widget.panelHeight ??
        MediaQuery.of(context).size.height * 0.35;
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
        child: stationVm.allStations.isEmpty
            ? Center(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: cs.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(l10n?.noStationsFound ?? 'No stations found',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 16)),
                ],
              ))
            : ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: stationVm.allStations.length,
                itemBuilder: (context, index) {
                  final station = stationVm.allStations[index];
                  return StationCard(
                    station: station,
                    onTap: () => _moveMapToStation(station),
                    onNavigate: () {
                      _moveMapToStation(station);
                      _showRoutePanel(station);
                    },
                    onShowElectric: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: AppShapes.bottomSheet,
                        builder: (context) => ElectricBikeDetailsModal(
                          stationId: station.id,
                          stationName: const StationFormatHelper().name(
                              station,
                              Provider.of<AppConfigService>(context,
                                      listen: false)
                                  .currentLang),
                        ),
                      );
                    },
                  );
                },
              ),
      );

  void _moveMapToStation(Station station) {
    final target = station.visualPosition ?? LatLng(station.lat, station.lng);
    Provider.of<StationViewModel>(context, listen: false)
        .refreshCards(moveTo: target);
  }

  void _showRoutePanel(Station station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: AppShapes.bottomSheet,
      builder: (context) => RouteDetailPanel(
          station: station, destLat: station.lat, destLng: station.lng),
    );
  }
}

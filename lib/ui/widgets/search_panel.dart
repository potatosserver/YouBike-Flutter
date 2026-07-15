import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:youbike_android/providers/station_view_model.dart';
import 'package:youbike_android/data/models/station.dart';
import 'package:youbike_android/ui/widgets/station_card.dart';
import 'package:youbike_android/ui/widgets/route_detail_panel.dart';
import 'package:youbike_android/ui/widgets/electric_bike_modal.dart';
import 'package:youbike_android/core/l10n/app_localizations.dart';
import 'dart:math' as math;

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

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleFocusChange);
    _searchController.addListener(_handleTextChange);
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _searchFocusNode.hasFocus;
    });
  }

  void _handleTextChange() {
    setState(() {
      _hasText = _searchController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<StationViewModel>(
      builder: (context, stationVm, child) {
        final l10n = AppLocalizations.of(context);
        // 移除 if (l10n == null) return const SizedBox.shrink(); 
        // 確保面板結構永遠存在，避免視覺跳變
        return Column(
          children: [
            if (!widget.isWide)
              Container(
                width: double.infinity, height: 24, padding: const EdgeInsets.symmetric(vertical: 9),
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.4, height: 6, 
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark ? Colors.white38 : const Color(0xFFBBBBBB), 
                      borderRadius: BorderRadius.circular(3), 
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 3, offset: const Offset(0, 1) )]
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark ? const Color(0xFF222222) : const Color(0xFFFFF2EC),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1), 
                      blurRadius: 4, 
                      offset: widget.isWide ? const Offset(1, 0) : const Offset(0, 2)
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isFocused 
                            ? (theme.brightness == Brightness.dark ? const Color(0xFF333333) : const Color(0xFFFDE8D6))
                            : (theme.brightness == Brightness.dark ? const Color(0xFF2A2A2A) : const Color(0xFFFFE8D6)),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: _isFocused ? 0.15 : 0.08),
                              blurRadius: _isFocused ? 6 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: l10n.input_placeholder, // 提供後備文字
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            suffixIcon: SizedBox(
                              width: 64,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_hasText)
                                    GestureDetector(
                                      onTap: _clearSearch,
                                      child: const Icon(Icons.clear, color: Colors.grey, size: 24),
                                    ),
                                  if (_hasText) const SizedBox(width: 8),
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(Icons.search, color: Colors.grey, size: 24),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          onSubmitted: (val) => stationVm.searchStations(val),
                          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                        ),
                      ),
                    ),
                    Expanded(child: _buildStationPanel(stationVm, l10n)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStationPanel(StationViewModel stationVm, AppLocalizations? l10n) =>
      SizedBox(
        width: double.infinity,
        child: stationVm.allStations.isEmpty 
            ? Center(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n?.noStationsFound ?? "No stations found", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: math.min(stationVm.allStations.length, 10), 
                itemBuilder: (context, index) {
                  final station = stationVm.allStations[index];
                  return StationCard(
                    station: station,
                    onTap: () => _moveMapToStation(station),
                    onNavigate: () { _moveMapToStation(station); _showRoutePanel(station); },
                    onShowElectric: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                        builder: (context) => ElectricBikeDetailsModal(stationId: station.id, stationName: station.nameTw),
                      );
                    },
                  );
                },
              ),
        );

  void _moveMapToStation(Station station) {
    final target = station.visualPosition ?? LatLng(station.lat, station.lng);
    Provider.of<StationViewModel>(context, listen: false).refreshCards(moveTo: target);
  }

  void _showRoutePanel(Station station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => RouteDetailPanel(station: station, destLat: station.lat, destLng: station.lng),
    );
  }
}

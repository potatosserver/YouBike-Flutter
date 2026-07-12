
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/app_state.dart';
import '../models/station.dart';
import '../widgets/station_card.dart';
import '../widgets/route_detail_panel.dart';
import '../widgets/electric_bike_modal.dart';
import '../l10n/app_localizations.dart';
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final l10n = AppLocalizations.of(context);
        if (l10n == null) return const SizedBox.shrink();
        return Column(
          children: [
            if (!widget.isWide)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  double newHeight = (widget.panelHeight ?? MediaQuery.of(context).size.height * 0.35) - details.delta.dy;
                  newHeight = newHeight.clamp(MediaQuery.of(context).size.height * 0.2, MediaQuery.of(context).size.height * 0.8);
                  widget.onHeightChanged(newHeight);
                },
                child: Container(
                  width: double.infinity, height: 24, padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.4, height: 6, 
                      decoration: BoxDecoration(color: theme.brightness == Brightness.dark ? Colors.white38 : const Color(0xFFBBBBBB), borderRadius: BorderRadius.circular(3), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 3, offset: const Offset(0, 1) )]),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark ? const Color(0xFF222222) : const Color(0xFFFFF2EC),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1), 
                      blurRadius: 15, 
                      offset: widget.isWide ? const Offset(2, 0) : const Offset(0, -5)
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        decoration: InputDecoration(
                          filled: true, fillColor: theme.brightness == Brightness.dark ? const Color(0xFF2A2A2A) : const Color(0xFFFFFFFF),
                          hintText: l10n.input_placeholder, prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onSubmitted: (val) => appState.searchStations(val),
                        style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                      ),
                    ),
                    Expanded(child: _buildStationPanel(appState, l10n)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStationPanel(AppState appState, AppLocalizations l10n) =>
      SizedBox(
        width: double.infinity,
        child: appState.allStations.isEmpty 
            ? Center(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.noStationsFound, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: math.min(appState.allStations.length, 10), 
                itemBuilder: (context, index) {
                  final station = appState.allStations[index];
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
    widget.mapController.move(target, 18.0);
  }

  void _showRoutePanel(Station station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => RouteDetailPanel(destination: station.nameTw, destLat: station.lat, destLng: station.lng),
    );
  }
}

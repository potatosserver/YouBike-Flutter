import 'package:youbike/providers/map_view_model.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:youbike/data/services/app_config_service.dart';
import 'package:youbike/data/services/route_service.dart';
import 'package:youbike/core/services/route_instruction_translator.dart';
import 'package:youbike/core/l10n/app_localizations.dart';
import 'package:youbike/core/services/station_format_helper.dart';
import 'package:youbike/data/models/station.dart';
import 'package:youbike/ui/widgets/app_shapes.dart';

class RouteDetailPanel extends StatefulWidget {
  final Station station;
  final double destLat;
  final double destLng;

  const RouteDetailPanel({
    super.key,
    required this.station,
    required this.destLat,
    required this.destLng,
  });

  @override
  State<RouteDetailPanel> createState() => _RouteDetailPanelState();
}

class _RouteDetailPanelState extends State<RouteDetailPanel> {
  static const _fmt = StationFormatHelper();
  static const _translator = RouteInstructionTranslator();
  List<String>? _steps;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    final config = Provider.of<AppConfigService>(context, listen: false);
    final routeService = RouteService();

    try {
      final mapVm = Provider.of<MapViewModel>(context, listen: false);
      final startPoint =
          mapVm.lastKnownLocation ?? mapVm.getEffectiveLocation();

      final steps = await routeService.getRoute(startPoint,
          LatLng(widget.destLat, widget.destLng), config.currentLang);

      if (mounted) {
        setState(() {
          final lang =
              Provider.of<AppConfigService>(context, listen: false).currentLang;
          _steps = steps
              .map((s) =>
                  '${_translator.translate(s.instruction, lang)} (${(s.distance / 1000).toStringAsFixed(2)} km)')
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final l10n = AppLocalizations.of(context);
          _errorMessage = l10n.navigationUnavailable;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final config = Provider.of<AppConfigService>(context);

    final destinationName = _fmt.name(widget.station, config.currentLang);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -5)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DragHandle(),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.directions_walk, color: cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${l10n.go_to}$destinationName',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child:
                      Text(_errorMessage!, style: TextStyle(color: cs.error)),
                ),
              )
            else if (_steps == null || _steps!.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(l10n.routeNotFound,
                      style: TextStyle(color: cs.onSurface)),
                ),
              )
            else
              ..._steps!.asMap().entries.map((entry) {
                int idx = entry.key;
                String step = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: idx == 0
                                ? cs.primary
                                : cs.surfaceContainerHighest,
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                color: idx == 0
                                    ? cs.onPrimary
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (idx != _steps!.length - 1)
                            Container(
                                width: 2,
                                height: 20,
                                color: cs.surfaceContainerHighest),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          step,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: cs.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

import 'package:youbike_android/data/services/app_config_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youbike_android/data/models/station.dart';
import 'package:youbike_android/providers/station_view_model.dart';
import 'package:youbike_android/core/l10n/app_localizations.dart';

class StationCard extends StatelessWidget {
  final Station station;
  final VoidCallback onTap;
  final VoidCallback onNavigate;
  final VoidCallback onShowElectric;

  const StationCard({
    super.key,
    required this.station,
    required this.onTap,
    required this.onNavigate,
    required this.onShowElectric,
  });

  @override
  Widget build(BuildContext context) {
    final stationVm = Provider.of<StationViewModel>(context);
    final config = Provider.of<AppConfigService>(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isPinned = config.pinnedStationIds.contains(station.id);
    final hasElectric = (station.availableElectricBikes ?? 0) > 0;
    final double distValue = station.distance;

    String formatValue(BuildContext context, int? value) {
      final l10n = AppLocalizations.of(context);
      return value == null ? l10n.unknown : value.toString();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? const Color(0xFF444444) : const Color(0xFFFFF2EC),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1), 
              blurRadius: 4, 
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    config.currentLang == 'en' ? station.nameEn : station.nameTw,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.brightness == Brightness.dark ? const Color(0xFF90CAF9) : const Color(0xFF4A90E2),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    if (hasElectric)
                      GestureDetector(
                        onTap: onShowElectric,
                        child: const Icon(Icons.electric_bolt, color: Colors.green, size: 22),
                      ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => config.togglePinStation(station.id),
                      child: Icon(
                        isPinned ? Icons.star : Icons.star_border,
                        color: isPinned ? Colors.amber : (theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600]),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: onNavigate,
                      child: Icon(
                        Icons.navigation, 
                        color: theme.brightness == Brightness.dark ? const Color(0xFF90CAF9) : const Color(0xFF4A90E2), 
                        size: 22
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "${l10n.distance} ${stationVm.getDistanceLabel(distValue)}",
              style: TextStyle(fontSize: 15, color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "${l10n.address} ${config.currentLang == 'en' ? station.addressEn : station.addressTw}",
              style: TextStyle(fontSize: 15, color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "${l10n.availableBikes} ${formatValue(context, station.availableBikes)}",
              style: TextStyle(fontSize: 15, color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "${l10n.availableElectricBikes} ${formatValue(context, station.availableElectricBikes)}",
              style: TextStyle(fontSize: 15, color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "${l10n.emptySpaces} ${formatValue(context, station.emptySpaces)}",
              style: TextStyle(fontSize: 15, color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

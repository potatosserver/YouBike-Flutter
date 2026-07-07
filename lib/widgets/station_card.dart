import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/station.dart';
import '../services/app_state.dart';
import '../l10n/app_localizations.dart';

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
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isPinned = appState.pinnedStationIds.contains(station.id);
    final hasElectric = station.availableElectricBikes > 0;
    final double distValue = station.distance;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? const Color(0xFF444444) : const Color(0xFFFDF5E6),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
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
                    appState.currentLang == 'en' ? station.nameEn : station.nameTw,
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
                      onTap: () => appState.togglePinStation(station.id),
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
              "${l10n.distance} ${appState.getDistanceLabel(distValue)}",
              style: TextStyle(fontSize: 15, color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "${l10n.address} ${appState.currentLang == 'en' ? station.addressEn : station.addressTw}",
              style: TextStyle(fontSize: 15, color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "${l10n.availableBikes} ${station.availableBikes}",
              style: TextStyle(fontSize: 15, color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "${l10n.availableElectricBikes} ${station.availableElectricBikes}",
              style: TextStyle(fontSize: 15, color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "${l10n.emptySpaces} ${station.emptySpaces}",
              style: TextStyle(fontSize: 15, color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

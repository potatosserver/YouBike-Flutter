import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/station.dart';
import '../services/app_state.dart';

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
    final isPinned = appState.pinnedStationIds.contains(station.id);
    final hasElectric = station.availableElectricBikes > 0;

    // Safely parse distance string back to double for formatting
    final double distValue = double.tryParse(station.distance) ?? 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF5E6),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A90E2),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    if (hasElectric)
                      const Icon(Icons.electric_bolt, color: Colors.green, size: 22),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => appState.togglePinStation(station.id),
                      child: Icon(
                        isPinned ? Icons.star : Icons.star_border,
                        color: isPinned ? Colors.amber : Colors.grey[600],
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: onNavigate,
                      child: const Icon(Icons.navigation, color: Color(0xFF4A90E2), size: 22),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "距離： ${appState.getDistanceLabel(distValue)}",
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "地址: ${appState.currentLang == 'en' ? station.addressEn : station.addressTw}",
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "YouBike 2.0: ${station.availableBikes}",
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "YouBike 2.0E: ${station.availableElectricBikes}",
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "可停空位數: ${station.emptySpaces}",
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/station.dart';
import '../services/app_state.dart';
import '../widgets/app_theme.dart';

class StationCard extends StatelessWidget {
  final Station station;
  final VoidCallback onTap;
  final VoidCallback onNavigate;

  const StationCard({
    super.key, 
    required this.station, 
    required this.onTap,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: appState.isDarkMode ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  color: AppColors.primary,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                appState.currentLang == 'zh' ? station.nameTw : station.nameEn,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildActionButtons(appState),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          appState.currentLang == 'zh' ? "距離: ${station.distance} ${station.distanceUnit}" : "Distance: ${station.distance} ${station.distanceUnit}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appState.currentLang == 'zh' ? "地址: ${station.addressTw}" : "Address: ${station.addressEn}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBikeInfoRow(appState),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(AppState appState) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            appState.pinnedStationIds.contains(station.id) 
              ? Icons.star 
              : Icons.star_border, 
            size: 20, 
            color: appState.pinnedStationIds.contains(station.id) 
              ? Colors.amber 
              : Colors.grey,
          ),
          onPressed: () => appState.togglePinStation(station.id),
        ),
        IconButton(
          icon: const Icon(Icons.navigation, size: 20, color: Colors.grey),
          onPressed: onNavigate,
        ),
      ],
    );
  }

  Widget _buildBikeInfoRow(AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${appState.currentLang == 'zh' ? 'YouBike 2.0' : 'YouBike 2.0'}: ${station.availableBikes}", 
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        Text(
          "${appState.currentLang == 'zh' ? 'YouBike 2.0E' : 'YouBike 2.0E'}: ${station.availableElectricBikes}", 
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        Text(
          "${appState.currentLang == 'zh' ? '可停空位數' : 'Available Slots'}: ${station.emptySpaces}", 
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }
}

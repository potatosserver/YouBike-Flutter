import 'package:flutter/material.dart';
import '../models/station.dart';

class StationCard extends StatelessWidget {
  final Station station;
  final VoidCallback onTap;

  const StationCard({
    super.key, 
    required this.station, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    // 從 variables.css 抄來的精確參數
    const primaryColor = Color(0xFFE44D26); // --primary-color
    const borderColor = Color(0xFFE0E0E0);    // --border-color
    const bgColor = Color(0xFFFFFFFF);       // --bg-color
    const secondaryTextColor = Color(0xFF757575); // --secondary-text-color

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
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
                  color: primaryColor,
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
                                station.nameTw,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor, // 站點名稱使用主色調
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildActionButtons(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "距離: ${station.distance} ${station.distanceUnit}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "地址: ${station.addressTw}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBikeInfoRow(),
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

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.star_border, size: 20, color: Colors.grey),
          onPressed: () {
            // 收藏邏輯
          },
        ),
        IconButton(
          icon: const Icon(Icons.navigation, size: 20, color: Colors.grey),
          onPressed: () {
            // 導航邏輯
          },
        ),
      ],
    );
  }

  Widget _buildBikeInfoRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("YouBike 2.0: ${station.availableBikes}", 
          style: const TextStyle(fontSize: 14, color: Colors.black87)),
        Text("YouBike 2.0E: ${station.availableElectricBikes}", 
          style: const TextStyle(fontSize: 14, color: Colors.black87)),
        Text("可停空位數: ${station.emptySpaces}", 
          style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
  }
}

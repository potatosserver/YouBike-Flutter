import 'package:flutter/material.dart';
import 'package:youbike/core/theme/brand_colors.dart';

class RoadSignMarker extends StatelessWidget {
  const RoadSignMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 主體與邊框：Gold Standard #FFD700 + 4px 白邊
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: BrandColors.markerYellow,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4.0),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
        ),
        // 腳踏車圖示：PNG 素材渲染，100% 可靠
        Image.asset(
          'assets/icons/bike_icon.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.directions_bike,
                size: 22, color: Colors.black87);
          },
        ),
      ],
    );
  }
}

class ClusterMarker extends StatelessWidget {
  final int count;
  const ClusterMarker({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BrandColors.markerYellow, // Solid Yellow
        border: Border.all(
          color: Colors.white,
          width: 4.0, // Thick White Border
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Center(
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

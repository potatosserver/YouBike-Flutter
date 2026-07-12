import 'package:flutter/material.dart';

class RoadSignMarker extends StatelessWidget {
  const RoadSignMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Main Body & Border (Gold Standard #FFD700 + 4px White Border)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4.0),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
        ),
        // 2. Bike Icon (Direct Asset Rendering - 100% Reliable)
        Image.asset(
          'assets/icons/bike_icon.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.directions_bike, size: 22, color: Colors.black87);
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
        color: const Color(0xFFFFD700), // Solid Yellow
        border: Border.all(
          color: Colors.white, 
          width: 4.0, // Thick White Border
        ),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
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


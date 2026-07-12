import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class RoadSignMarker extends StatelessWidget {
  final ui.Image? image;
  const RoadSignMarker({super.key, this.image});

  @override
  Widget build(BuildContext context) {
    if (image == null) return const Icon(Icons.location_on, color: Colors.amber, size: 30);

    return RawImage(
      image: image,
      width: 40,
      height: 40,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
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


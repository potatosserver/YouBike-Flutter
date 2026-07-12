import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';


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
      width: 45, height: 45,
      decoration: BoxDecoration(
        color: Colors.amber,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: Center(
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

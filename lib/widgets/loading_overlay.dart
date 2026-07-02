import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class LoadingOverlay extends StatefulWidget {
  final bool isVisible;
  final int progress;
  final String notice;
  final bool isOffline;

  const LoadingOverlay({
    super.key, 
    required this.isVisible, 
    required this.progress, 
    required this.notice,
    this.isOffline = false,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Material(
      color: Colors.white,
      child: Center(
        child: widget.isOffline 
          ? _buildOfflineContent() 
          : _buildLoadingContent(),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "載入中：${widget.progress}%",
          style: const TextStyle(fontSize: 24, color: Color(0xFF007BFF), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.notice,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.wifi_off, size: 80, color: Colors.grey),
        const SizedBox(height: 20),
        const Text(
          "請連接網路後重試",
          style: TextStyle(fontSize: 24, color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        FilledButton(
          onPressed: () {
            // Note: In a real app, this would trigger a reload of AppState
            Provider.of<AppState>(context, listen: false).refreshStations();
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFDCACB),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          child: const Text("重整"),
        ),
      ],
    );
  }
}

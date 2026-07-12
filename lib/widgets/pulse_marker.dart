import 'package:flutter/material.dart';

class PulseMarker extends StatelessWidget {
  final double latitude;
  final double longitude;

  const PulseMarker({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    // 使用 RepaintBoundary 將動畫隔離在獨立圖層，防止縮放地圖時觸發全標記重繪
    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer soft pulse
          const PulseAnimation(
            color: Color(0xFF4285F4),
            targetSize: 60,
          ),
          // Inner soft pulse
          const PulseAnimation(
            color: Color(0xFF4285F4),
            targetSize: 60,
            delay: Duration(milliseconds: 500),
          ),
          // Center Dot
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: const Color(0xFF4285F4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PulseAnimation extends StatefulWidget {
  final Color color;
  final double targetSize;
  final Duration delay;

  const PulseAnimation({
    super.key,
    required this.color,
    required this.targetSize,
    this.delay = Duration.zero,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    // 處理延遲啟動，避免所有點同步跳動導致的視覺壓力
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final currentSize = 20.0 + (widget.targetSize - 20.0) * progress;
        return Container(
          width: currentSize,
          height: currentSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.3 * (1.0 - progress)),
          ),
        );
      },
    );
  }
}

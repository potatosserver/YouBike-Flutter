import 'package:flutter/material.dart';

class MapMaskOverlay extends StatelessWidget {
  final Color maskColor;
  final double panelHeight;
  final bool isWide;
  final double? leftOffset;

  const MapMaskOverlay({
    super.key, 
    required this.maskColor, 
    required this.panelHeight, 
    required this.isWide, 
    this.leftOffset,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _MapMaskPainter(maskColor, panelHeight, isWide, leftOffset),
    );
  }
}

class _MapMaskPainter extends CustomPainter {
  final Color color;
  final double panelHeight;
  final bool isWide;
  final double? leftOffset;
  _MapMaskPainter(this.color, this.panelHeight, this.isWide, this.leftOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..fillType = PathFillType.evenOdd;
    
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final double horizontalMargin = leftOffset ?? (isWide ? 20.0 : 0.0);
    final double verticalMargin = isWide ? 20.0 : 0.0;
    final double cutoutWidth = isWide ? size.width - horizontalMargin - 20.0 : size.width;
    final double cutoutHeight = isWide ? size.height - (verticalMargin * 2) : size.height - panelHeight;
    
    final cutoutRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(horizontalMargin, verticalMargin, cutoutWidth, cutoutHeight),
      topLeft: isWide ? const Radius.circular(28) : Radius.zero,
      topRight: isWide ? const Radius.circular(28) : Radius.zero,
      bottomLeft: isWide ? const Radius.circular(28) : const Radius.circular(28),
      bottomRight: isWide ? const Radius.circular(28) : const Radius.circular(28),
    );
    path.addRRect(cutoutRect);

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
    
    // Use a refined shadow based on YouBike-Web standard (approx 0 2px 4px rgba(0,0,0,0.1))
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.clipPath(path);
    
    final sharpShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1) 
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    
    canvas.drawRRect(cutoutRect, sharpShadowPaint);
    canvas.restore();
    
    // Fine highlight border for a polished finish
    final highlightPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawRRect(cutoutRect, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is _MapMaskPainter) {
      return oldDelegate.panelHeight != panelHeight || 
             oldDelegate.isWide != isWide || 
             oldDelegate.leftOffset != leftOffset;
    }
    return true;
  }
}

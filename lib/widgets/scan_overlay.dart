import 'package:flutter/material.dart';

class ScanOverlay extends StatefulWidget {
  const ScanOverlay({super.key});

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScanFramePainter(_animation),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  final Animation<double> animation;

  _ScanFramePainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    const frameWidth = 280.0;
    const frameHeight = 180.0;
    final left = (size.width - frameWidth) / 2;
    final top = (size.height - frameHeight) / 2;
    final right = left + frameWidth;
    final bottom = top + frameHeight;

    // Dim overlay
    final dimPaint = Paint()..color = Colors.black.withOpacity(0.5);
    final framePath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(left, top, right, bottom), const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(framePath, dimPaint);

    // Corner brackets
    const cornerLen = 24.0;
    const strokeW = 3.5;
    final bracketPaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void drawCorner(double x, double y, double dx, double dy) {
      canvas.drawLine(Offset(x, y + dy * cornerLen), Offset(x, y), bracketPaint);
      canvas.drawLine(Offset(x, y), Offset(x + dx * cornerLen, y), bracketPaint);
    }

    drawCorner(left, top, 1, 1);
    drawCorner(right, top, -1, 1);
    drawCorner(left, bottom, 1, -1);
    drawCorner(right, bottom, -1, -1);

    // Scan line
    final scanY = top + (frameHeight * animation.value);
    final scanPaint = Paint()
      ..color = const Color(0xFF2196F3).withOpacity(0.8)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(left + 12, scanY),
      Offset(right - 12, scanY),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(_ScanFramePainter oldDelegate) => true;
}

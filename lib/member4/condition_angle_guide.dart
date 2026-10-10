import 'package:flutter/material.dart';

/// Directional ghost overlay for the 4-angle condition capture flow (UI-02).
class ConditionAngleGuideOverlay extends StatelessWidget {
  final String angleKey;
  const ConditionAngleGuideOverlay({super.key, required this.angleKey});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _AngleGuidePainter(angleKey),
        size: Size.infinite,
      ),
    );
  }
}

class _AngleGuidePainter extends CustomPainter {
  final String angle;
  _AngleGuidePainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final fill = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.12, size.height * 0.18, size.width * 0.76, size.height * 0.55),
      const Radius.circular(18),
    );
    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, guide);

    final arrow = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height * 0.45);
    switch (angle) {
      case 'front':
        _drawArrow(canvas, center, const Offset(0, -1), arrow);
        _label(canvas, size, 'Align front face in frame', center.dy - 48);
      case 'back':
        _drawArrow(canvas, center, const Offset(0, 1), arrow);
        _label(canvas, size, 'Align back face in frame', center.dy + 48);
      case 'left':
        _drawArrow(canvas, center, const Offset(-1, 0), arrow);
        _label(canvas, size, 'Show left side profile', center.dy - 48);
      case 'right':
        _drawArrow(canvas, center, const Offset(1, 0), arrow);
        _label(canvas, size, 'Show right side profile', center.dy - 48);
      default:
        _label(canvas, size, 'Keep full item visible', center.dy - 48);
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset dir, Paint paint) {
    final tip = from + Offset(dir.dx * 36, dir.dy * 36);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - dir.dy * 10 - dir.dx * 14, tip.dy + dir.dx * 10 - dir.dy * 14)
      ..lineTo(tip.dx + dir.dy * 10 - dir.dx * 14, tip.dy - dir.dx * 10 - dir.dy * 14)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawLine(from, tip, paint..strokeWidth = 3);
  }

  void _label(Canvas canvas, Size size, String text, double y) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.85);
    tp.paint(canvas, Offset((size.width - tp.width) / 2, y));
  }

  @override
  bool shouldRepaint(covariant _AngleGuidePainter oldDelegate) =>
      oldDelegate.angle != angle;
}

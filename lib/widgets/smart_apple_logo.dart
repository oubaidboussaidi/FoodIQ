import 'package:flutter/material.dart';
import 'dart:math' as math;

class SmartAppleLogo extends StatefulWidget {
  final double size;
  final bool animate;

  const SmartAppleLogo({
    super.key, 
    this.size = 150,
    this.animate = true,
  });

  @override
  State<SmartAppleLogo> createState() => _SmartAppleLogoState();
}

class _SmartAppleLogoState extends State<SmartAppleLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.animate) _controller.repeat();
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
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ApplePainter(_controller.value),
        );
      },
    );
  }
}

class _ApplePainter extends CustomPainter {
  final double prog;
  _ApplePainter(this.prog);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    
    // 1. Define the Green Apple Body
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF4ADE80), // Vibrant Green
          const Color(0xFF16A34A), // Deep Green
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final path = Path();
    // Complex Apple Shape
    path.moveTo(w * 0.5, h * 0.25);
    // Right shoulder
    path.cubicTo(w * 0.7, h * 0.2, w * 0.95, h * 0.35, w * 0.9, h * 0.6);
    // Bottom right
    path.cubicTo(w * 0.85, h * 0.85, w * 0.6, h * 0.95, w * 0.5, h * 0.88);
    // Bottom left
    path.cubicTo(w * 0.4, h * 0.95, w * 0.15, h * 0.85, w * 0.1, h * 0.6);
    // Left shoulder
    path.cubicTo(w * 0.05, h * 0.35, w * 0.3, h * 0.2, w * 0.5, h * 0.25);
    
    canvas.drawPath(path, bodyPaint);

    // 2. Draw the AI "IQ" Leaf
    final leafPaint = Paint()
      ..color = const Color(0xFF3B82F6) // Electric Blue for Intelligence
      ..style = PaintingStyle.fill;

    final leafPath = Path();
    leafPath.moveTo(w * 0.52, h * 0.22);
    leafPath.quadraticBezierTo(w * 0.65, h * 0.05, w * 0.8, h * 0.1);
    leafPath.quadraticBezierTo(w * 0.75, h * 0.25, w * 0.52, h * 0.22);
    
    canvas.drawPath(leafPath, leafPaint);

    // 3. Draw the Brain/Core patterns (The "Intelligence")
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.3 + (math.sin(prog * 2 * math.pi) * 0.1))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Neural Grid/Connections inside apple
    final centerX = w * 0.5;
    final centerY = h * 0.58;
    
    for (int i = 0; i < 6; i++) {
      double angle = (i * 60) * math.pi / 180 + (prog * 0.5);
      double endX = centerX + math.cos(angle) * (w * 0.15);
      double endY = centerY + math.sin(angle) * (w * 0.15);
      canvas.drawLine(Offset(centerX, centerY), Offset(endX, endY), corePaint);
      
      // Node circles
      final nodePaint = Paint()..color = Colors.white.withOpacity(0.6 + (math.sin(prog * 4 * math.pi + i) * 0.2));
      canvas.drawCircle(Offset(endX, endY), 3, nodePaint);
    }

    // Centered Intelligent Core (Hexagon)
    final hexPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(centerX, centerY), 6, hexPaint);
  }

  @override
  bool shouldRepaint(covariant _ApplePainter oldDelegate) => true;
}

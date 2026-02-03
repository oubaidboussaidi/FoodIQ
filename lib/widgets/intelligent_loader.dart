import 'package:flutter/material.dart';
import 'dart:math' as math;

class IntelligentLoader extends StatefulWidget {
  const IntelligentLoader({super.key});

  @override
  State<IntelligentLoader> createState() => _IntelligentLoaderState();
}

class _IntelligentLoaderState extends State<IntelligentLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = List.generate(20, (index) => Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB), // Matches app Scaffold background
      body: Stack(
        children: [
          // 1. Subtle Paper/Soft Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF1F5F9), // Very light slate
                  Color(0xFFF8F9FB),
                ],
              ),
            ),
          ),

          // 2. Animated Neural Connections (Lighter version)
          CustomPaint(
            size: Size.infinite,
            painter: NeuralPainter(_particles, _controller),
          ),

          // 3. Central Branding
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Logo Container
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final pulse = (math.sin(_controller.value * 2 * math.pi) + 1) / 2;
                    final rotation = _controller.value * 2 * math.pi;
                    
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft Aura
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22C55E).withOpacity(0.08 * pulse),
                                blurRadius: 40 * pulse,
                                spreadRadius: 10 * pulse,
                              ),
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.05 * pulse),
                                blurRadius: 60 * pulse,
                                spreadRadius: 5 * pulse,
                              ),
                            ],
                          ),
                        ),
                        
                        // Orbital Rings (Lighter)
                        Transform.rotate(
                          angle: rotation,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                          ),
                        ),

                        // Orbital Node Ring
                        Transform.rotate(
                          angle: -rotation * 0.7,
                          child: Container(
                            width: 125,
                            height: 125,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF22C55E).withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E).withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // The Logo (with subtle shadow instead of glow)
                        Container(
                          padding: const EdgeInsets.all(16),
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 48),
                
                // Text Branding (The Fancy "Black" color - Slate 900)
                const Text(
                  'FoodIQ',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10,
                    color: Color(0xFF0F172A), // Premium Slate 900 (Fancy Black)
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Status Text
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final pulse = 0.4 + ((math.sin(_controller.value * 2 * math.pi) + 1) / 2) * 0.4;
                    return Text(
                      'PREPARING INTELLIGENT INSIGHTS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: const Color(0xFF3B82F6).withOpacity(pulse),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 4. Bottom Footer
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Oubaid Boussaidi Edition'.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A).withOpacity(0.12),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 30,
                  height: 1,
                  color: const Color(0xFF0F172A).withOpacity(0.05),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Particle {
  late double x;
  late double y;
  late double size;
  late double vx;
  late double vy;

  Particle() {
    randomize();
  }

  void randomize() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    size = math.Random().nextDouble() * 1.5 + 0.5;
    vx = (math.Random().nextDouble() - 0.5) * 0.0005;
    vy = (math.Random().nextDouble() - 0.5) * 0.0005;
  }

  void update() {
    x += vx;
    y += vy;
    if (x < 0 || x > 1) vx *= -1;
    if (y < 0 || y > 1) vy *= -1;
  }
}

class NeuralPainter extends CustomPainter {
  final List<Particle> particles;
  final Animation<double> controller;

  NeuralPainter(this.particles, this.controller) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()..strokeWidth = 0.5;

    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];
      p.update();
      
      final pos = Offset(p.x * size.width, p.y * size.height);
      
      // Draw Connections (Soft Grey/Blue)
      for (var j = i + 1; j < particles.length; j++) {
        final p2 = particles[j];
        final pos2 = Offset(p2.x * size.width, p2.y * size.height);
        final distance = (pos - pos2).distance;
        
        if (distance < 140) {
          linePaint.color = const Color(0xFF3B82F6).withOpacity((1.0 - distance / 140) * 0.08);
          canvas.drawLine(pos, pos2, linePaint);
        }
      }

      // Draw Particle
      paint.color = const Color(0xFF3B82F6).withOpacity(0.1);
      canvas.drawCircle(pos, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(NeuralPainter oldDelegate) => true;
}

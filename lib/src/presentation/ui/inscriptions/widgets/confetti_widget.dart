import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiWidget extends StatefulWidget {
  const ConfettiWidget({super.key});

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Crear partículas de confetti
    for (int i = 0; i < 100; i++) {
      _particles.add(
        ConfettiParticle(
          color: _getRandomColor(),
          startX: _random.nextDouble(),
          startY: -0.1,
          endY: 1.2,
          rotation: _random.nextDouble() * 2 * pi,
          size: _random.nextDouble() * 10 + 5,
          delay: _random.nextDouble() * 0.5,
          horizontalOffset: (_random.nextDouble() - 0.5) * 0.3,
        ),
      );
    }

    _controller.forward();
  }

  Color _getRandomColor() {
    final colors = [
      const Color(0xFF6366F1), // Púrpura
      const Color(0xFF8B5CF6), // Violeta
      const Color(0xFFEC4899), // Rosa
      const Color(0xFF10B981), // Verde
      const Color(0xFF3B82F6), // Azul
      const Color(0xFFF59E0B), // Naranja
      const Color(0xFF14B8A6), // Turquesa
    ];
    return colors[_random.nextInt(colors.length)];
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
          painter: ConfettiPainter(
            particles: _particles,
            animation: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class ConfettiParticle {
  final Color color;
  final double startX;
  final double startY;
  final double endY;
  final double rotation;
  final double size;
  final double delay;
  final double horizontalOffset;

  ConfettiParticle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.endY,
    required this.rotation,
    required this.size,
    required this.delay,
    required this.horizontalOffset,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double animation;

  ConfettiPainter({required this.particles, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final adjustedAnimation = (animation - particle.delay).clamp(0.0, 1.0);
      if (adjustedAnimation <= 0) continue;

      final x =
          size.width *
          (particle.startX + particle.horizontalOffset * adjustedAnimation);
      final y =
          size.height *
          (particle.startY +
              (particle.endY - particle.startY) * adjustedAnimation);

      final paint = Paint()
        ..color = particle.color.withValues(
          alpha: 1.0 - adjustedAnimation * 0.5,
        )
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation * adjustedAnimation * 4);

      // Dibujar formas diferentes: rectángulos, círculos, líneas
      final shapeType = particle.size % 3;
      if (shapeType < 1) {
        // Rectángulo
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          paint,
        );
      } else if (shapeType < 2) {
        // Círculo
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      } else {
        // Línea
        canvas.drawLine(
          Offset(-particle.size / 2, 0),
          Offset(particle.size / 2, 0),
          paint..strokeWidth = 3,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}

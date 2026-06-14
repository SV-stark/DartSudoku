import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants.dart';

class ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
}

/// A high-performance, self-contained confetti particle animation overlay.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();
  Size? _screenSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(_updateParticles);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _screenSize = MediaQuery.of(context).size;
        _spawnParticles();
        _controller.repeat();
      }
    });
  }

  void _spawnParticles() {
    if (_screenSize == null) return;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.amber,
      Colors.pink,
      Colors.purple,
      Colors.cyan,
      Colors.orange,
    ];
    for (int i = 0; i < GameConstants.confettiParticleCount; i++) {
      _particles.add(
        ConfettiParticle(
          x: _random.nextDouble() * _screenSize!.width,
          y: -_random.nextDouble() * 300,
          vx: (_random.nextDouble() - 0.5) * 3,
          vy: 2.0 + _random.nextDouble() * 4,
          size: 8.0 + _random.nextDouble() * 10,
          color: colors[_random.nextInt(colors.length)],
          rotation: _random.nextDouble() * pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.15,
        ),
      );
    }
  }

  void _updateParticles() {
    if (!mounted || _screenSize == null) return;
    for (var p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.rotation += p.rotationSpeed;

      // Reset particle if it falls off the bottom or sides
      if (p.y > _screenSize!.height) {
        p.y = -20;
        p.x = _random.nextDouble() * _screenSize!.width;
        p.vy = 2.0 + _random.nextDouble() * 4;
      }
    }
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
        painter: ConfettiPainter(_particles, repaint: _controller),
        size: Size.infinite,
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.particles, {required Listenable repaint})
    : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      paint.color = p.color;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.55,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

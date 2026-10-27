import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../core/theme/app_theme.dart';

class CashParticle {
  final Offset start;
  final Offset target;
  final Offset control;
  double progress = 0.0;
  final double speed;
  final double rotation;

  CashParticle({
    required this.start,
    required this.target,
    required this.control,
    required this.speed,
    required this.rotation,
  });

  Offset get currentPosition {
    double t = progress.clamp(0.0, 1.0);
    double x = pow(1 - t, 2) * start.dx + 2 * (1 - t) * t * control.dx + pow(t, 2) * target.dx;
    double y = pow(1 - t, 2) * start.dy + 2 * (1 - t) * t * control.dy + pow(t, 2) * target.dy;
    return Offset(x, y);
  }
}

class ConfettiParticle {
  Offset position;
  Offset velocity;
  final Color color;
  final double size;
  double rotation;
  final double rotationSpeed;

  ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });

  void update(double dt) {
    position += velocity * dt;
    velocity = Offset(velocity.dx * 0.98, velocity.dy + (480 * dt)); // Gravity
    rotation += rotationSpeed * dt;
  }
}

class JuiceOverlayController extends ChangeNotifier {
  double trauma = 0.0;
  final List<CashParticle> cashParticles = [];
  final List<ConfettiParticle> confettiParticles = [];
  final Random _rng = Random();

  bool get hasActiveEffects => trauma > 0.001 || cashParticles.isNotEmpty || confettiParticles.isNotEmpty;

  void addTrauma(double amount) {
    trauma = (trauma + amount).clamp(0.0, 1.0);
    notifyListeners();
  }

  void decayTrauma(double dt) {
    if (trauma > 0) {
      trauma = max(0.0, trauma - (dt * 2.5));
      if (trauma <= 0.001) trauma = 0.0;
      notifyListeners();
    }
  }

  void spawnCashFountain({required Offset from, required Offset to, int count = 20}) {
    for (int i = 0; i < count; i++) {
      double arcOffset = (_rng.nextDouble() - 0.5) * 160.0;
      Offset mid = Offset((from.dx + to.dx) / 2 + arcOffset, min(from.dy, to.dy) - 100);
      cashParticles.add(CashParticle(
        start: from,
        target: to,
        control: mid,
        speed: 1.2 + (_rng.nextDouble() * 0.8),
        rotation: (_rng.nextDouble() - 0.5) * pi,
      ));
    }
    notifyListeners();
  }

  void spawnVictoryConfetti({required Size screenSize, int count = 90}) {
    final colors = [AppTheme.gold, AppTheme.neonCyan, AppTheme.emeraldGreen, Colors.pinkAccent, Colors.white];
    for (int i = 0; i < count; i++) {
      confettiParticles.add(ConfettiParticle(
        position: Offset(screenSize.width / 2 + (_rng.nextDouble() - 0.5) * 80, screenSize.height / 2),
        velocity: Offset((_rng.nextDouble() - 0.5) * 450, -300 - (_rng.nextDouble() * 350)),
        color: colors[_rng.nextInt(colors.length)],
        size: 6.0 + (_rng.nextDouble() * 6.0),
        rotation: _rng.nextDouble() * 2 * pi,
        rotationSpeed: (_rng.nextDouble() - 0.5) * 10,
      ));
    }
    notifyListeners();
  }

  void updateParticles(double dt) {
    bool changed = false;

    if (cashParticles.isNotEmpty) {
      for (final p in cashParticles) {
        p.progress += p.speed * dt;
      }
      cashParticles.removeWhere((p) => p.progress >= 1.0);
      changed = true;
    }

    if (confettiParticles.isNotEmpty) {
      for (final c in confettiParticles) {
        c.update(dt);
      }
      confettiParticles.removeWhere((c) => c.position.dy > 1200);
      changed = true;
    }

    if (changed) notifyListeners();
  }
}

class JuiceOverlay extends StatefulWidget {
  final Widget child;
  final JuiceOverlayController controller;

  const JuiceOverlay({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<JuiceOverlay> createState() => _JuiceOverlayState();
}

class _JuiceOverlayState extends State<JuiceOverlay> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (_lastElapsed == Duration.zero) {
        _lastElapsed = elapsed;
        return;
      }
      double dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
      _lastElapsed = elapsed;
      dt = dt.clamp(0.001, 0.05);

      widget.controller.decayTrauma(dt);
      widget.controller.updateParticles(dt);

      // Stop ticker when all effects settle to save battery & CPU cycles
      if (!widget.controller.hasActiveEffects) {
        _ticker.stop();
        _lastElapsed = Duration.zero;
      }
    });

    widget.controller.addListener(_onControllerChanged);
    if (widget.controller.hasActiveEffects) {
      _ticker.start();
    }
  }

  void _onControllerChanged() {
    if (widget.controller.hasActiveEffects && !_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        double trauma = widget.controller.trauma;
        double shakeMagnitude = pow(trauma, 2) * 18.0;
        double angleMagnitude = pow(trauma, 2) * 0.05;

        double offsetX = trauma > 0 ? (_rng.nextDouble() - 0.5) * 2 * shakeMagnitude : 0.0;
        double offsetY = trauma > 0 ? (_rng.nextDouble() - 0.5) * 2 * shakeMagnitude : 0.0;
        double angle = trauma > 0 ? (_rng.nextDouble() - 0.5) * 2 * angleMagnitude : 0.0;

        Widget content = child!;

        if (offsetX != 0.0 || offsetY != 0.0 || angle != 0.0) {
          content = Transform.translate(
            offset: Offset(offsetX, offsetY),
            child: Transform.rotate(
              angle: angle,
              child: content,
            ),
          );
        }

        return Stack(
          children: [
            content,
            if (widget.controller.cashParticles.isNotEmpty || widget.controller.confettiParticles.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ParticlesPainter(
                      cashParticles: widget.controller.cashParticles,
                      confettiParticles: widget.controller.confettiParticles,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final List<CashParticle> cashParticles;
  final List<ConfettiParticle> confettiParticles;

  _ParticlesPainter({
    required this.cashParticles,
    required this.confettiParticles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final billPaint = Paint()..color = AppTheme.emeraldGreen;
    final billBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final p in cashParticles) {
      final pos = p.currentPosition;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.rotation + (p.progress * 4));
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 22, height: 12), const Radius.circular(2)),
        billPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 22, height: 12), const Radius.circular(2)),
        billBorderPaint,
      );
      canvas.restore();
    }

    for (final c in confettiParticles) {
      final p = Paint()..color = c.color;
      canvas.save();
      canvas.translate(c.position.dx, c.position.dy);
      canvas.rotate(c.rotation);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size * 0.6), p);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

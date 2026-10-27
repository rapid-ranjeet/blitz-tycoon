import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/feedback_service.dart';
import '../../core/services/audio_service.dart';

class DiceRoller3D extends StatefulWidget {
  final bool isEnabled;
  final bool isRolling;
  final int multiplier;
  final int currentDie1;
  final int currentDie2;
  final VoidCallback onRoll;

  const DiceRoller3D({
    super.key,
    required this.isEnabled,
    required this.isRolling,
    required this.multiplier,
    required this.currentDie1,
    required this.currentDie2,
    required this.onRoll,
  });

  @override
  State<DiceRoller3D> createState() => _DiceRoller3DState();
}

class _DiceRoller3DState extends State<DiceRoller3D> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final Random _rng = Random();
  int _displayDie1 = 1;
  int _displayDie2 = 1;

  @override
  void initState() {
    super.initState();
    _displayDie1 = widget.currentDie1;
    _displayDie2 = widget.currentDie2;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addListener(() {
        if (_animController.isAnimating) {
          setState(() {
            _displayDie1 = _rng.nextInt(6) + 1;
            _displayDie2 = _rng.nextInt(6) + 1;
          });
        }
      });
  }

  @override
  void didUpdateWidget(covariant DiceRoller3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      _triggerTumble();
    } else if (!widget.isRolling && oldWidget.isRolling) {
      setState(() {
        _displayDie1 = widget.currentDie1;
        _displayDie2 = widget.currentDie2;
      });
    }
  }

  void _triggerTumble() {
    FeedbackService.diceRoll();
    AudioService.instance.playSfx(GameSfx.diceRoll);
    _animController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _displayDie1 = widget.currentDie1;
          _displayDie2 = widget.currentDie2;
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int totalRoll = _displayDie1 + _displayDie2;

    return Row(
      children: [
        // 1. Interactive 3D Dice Pair Tray
        GestureDetector(
          onTap: widget.isEnabled && !widget.isRolling ? widget.onRoll : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF231810), Color(0xFF140D09)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.gold.withAlpha(160), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(160),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSingle3DDie(_displayDie1, -0.08),
                const SizedBox(width: 8),
                _buildSingle3DDie(_displayDie2, 0.08),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // 2. Large Tactile 3D Action Roll Button
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isEnabled ? AppTheme.gold : Colors.grey.shade800,
                foregroundColor: Colors.black,
                elevation: widget.isEnabled ? 6 : 0,
                shadowColor: AppTheme.gold.withAlpha(180),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: widget.isEnabled ? Colors.amber.shade200 : Colors.transparent,
                    width: 1.5,
                  ),
                ),
              ),
              onPressed: widget.isEnabled && !widget.isRolling ? widget.onRoll : null,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isRolling ? Icons.autorenew_rounded : Icons.casino_rounded,
                      color: widget.isEnabled ? Colors.black : Colors.white38,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isRolling
                          ? "ROLLING ($totalRoll)..."
                          : (widget.isEnabled ? "ROLL DICE (${widget.multiplier}X)" : "WAITING..."),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: widget.isEnabled ? Colors.black : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingle3DDie(int faceValue, double tiltAngle) {
    double animValue = _animController.value;
    double rotation = animValue * 2 * pi + tiltAngle;
    double scale = 1.0 + (sin(animValue * pi) * 0.18);

    return Transform.scale(
      scale: scale,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFE8E8E8),
                Color(0xFFC8C8C8),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFB0B0B0), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(180),
                blurRadius: 4,
                offset: const Offset(1.5, 2.5),
              ),
            ],
          ),
          child: Center(
            child: _buildDiePips(faceValue),
          ),
        ),
      ),
    );
  }

  Widget _buildDiePips(int val) {
    switch (val) {
      case 1:
        return _buildPipDot(isCenter: true, color: AppTheme.dangerRed, size: 9);
      case 2:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Align(alignment: Alignment.topLeft, child: _buildPipDot()),
            Align(alignment: Alignment.bottomRight, child: _buildPipDot()),
          ],
        );
      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Align(alignment: Alignment.topLeft, child: _buildPipDot()),
            _buildPipDot(),
            Align(alignment: Alignment.bottomRight, child: _buildPipDot()),
          ],
        );
      case 4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildPipDot(), _buildPipDot()]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildPipDot(), _buildPipDot()]),
          ],
        );
      case 5:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildPipDot(), _buildPipDot()]),
            _buildPipDot(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildPipDot(), _buildPipDot()]),
          ],
        );
      case 6:
      default:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildPipDot(), _buildPipDot()]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildPipDot(), _buildPipDot()]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildPipDot(), _buildPipDot()]),
          ],
        );
    }
  }

  Widget _buildPipDot({bool isCenter = false, Color color = const Color(0xFF1B1B1B), double size = 6.0}) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withAlpha(180),
            blurRadius: 1,
            offset: const Offset(-0.5, -0.5),
          ),
        ],
      ),
    );
  }
}

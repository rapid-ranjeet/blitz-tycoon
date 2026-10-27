import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../core/theme/app_theme.dart';

class TokenHopState {
  final int playerId;
  final Color playerColor;
  final String playerInitial;
  final String avatarEmoji;
  final String avatarAssetPath;
  bool isLeader;
  bool isCurrentTurn;
  Offset currentNormalizedPos; // (u, v) in [0.0, 1.0]
  Offset startNormalizedPos;
  Offset targetNormalizedPos;
  double hopProgress = 1.0;
  final double hopHeight;

  TokenHopState({
    required this.playerId,
    required this.playerColor,
    required this.playerInitial,
    this.avatarEmoji = "♟️",
    this.avatarAssetPath = "",
    this.isLeader = false,
    this.isCurrentTurn = false,
    required Offset initialNormalizedPos,
    this.hopHeight = 24.0,
  })  : currentNormalizedPos = initialNormalizedPos,
        startNormalizedPos = initialNormalizedPos,
        targetNormalizedPos = initialNormalizedPos;

  void hopTo(Offset newNormalizedTarget) {
    startNormalizedPos = currentNormalizedPos;
    targetNormalizedPos = newNormalizedTarget;
    hopProgress = 0.0;
  }

  void update(double dt) {
    if (hopProgress < 1.0) {
      hopProgress = min(1.0, hopProgress + (dt * 4.2)); // ~240ms smooth hop
      double t = hopProgress;
      double linearX = startNormalizedPos.dx + (targetNormalizedPos.dx - startNormalizedPos.dx) * t;
      double linearY = startNormalizedPos.dy + (targetNormalizedPos.dy - startNormalizedPos.dy) * t;
      currentNormalizedPos = Offset(linearX, linearY);
    }
  }

  bool get isHopping => hopProgress < 1.0;
}

class TokenHopperLayer extends StatefulWidget {
  final ValueNotifier<List<TokenHopState>> tokensNotifier;

  const TokenHopperLayer({
    super.key,
    required this.tokensNotifier,
  });

  @override
  State<TokenHopperLayer> createState() => _TokenHopperLayerState();
}

class _TokenHopperLayerState extends State<TokenHopperLayer> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (_lastElapsed == Duration.zero) {
        _lastElapsed = elapsed;
        return;
      }
      double dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
      _lastElapsed = elapsed;

      final tokens = widget.tokensNotifier.value;
      bool hasActiveHop = false;
      for (final t in tokens) {
        if (t.isHopping) {
          t.update(dt);
          hasActiveHop = true;
        }
      }

      if (hasActiveHop) {
        widget.tokensNotifier.value = List.of(tokens);
      }
    });

    widget.tokensNotifier.addListener(_checkTickerStatus);
    _checkTickerStatus();
  }

  void _checkTickerStatus() {
    final tokens = widget.tokensNotifier.value;
    bool needsTicker = tokens.any((t) => t.isHopping);
    if (needsTicker && !_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    } else if (!needsTicker && _ticker.isActive) {
      _ticker.stop();
      _lastElapsed = Duration.zero;
    }
  }

  @override
  void dispose() {
    widget.tokensNotifier.removeListener(_checkTickerStatus);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return ValueListenableBuilder<List<TokenHopState>>(
            valueListenable: widget.tokensNotifier,
            builder: (context, tokens, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Layer 1: Ground Contact Shadows and Active Turn Spotlights
                  CustomPaint(
                    size: Size(w, h),
                    painter: TokenGroundShadowPainter(tokens: tokens),
                  ),

                  // Layer 2: 3D Sculpted Figurine Tokens with Real CEO Portraits
                  ...tokens.map((token) {
                    double t = token.hopProgress;
                    double pxStartX = token.startNormalizedPos.dx * w;
                    double pxStartY = token.startNormalizedPos.dy * h;
                    double pxTargetX = token.targetNormalizedPos.dx * w;
                    double pxTargetY = token.targetNormalizedPos.dy * h;

                    double curX = pxStartX + (pxTargetX - pxStartX) * t;
                    double curY = pxStartY + (pxTargetY - pxStartY) * t;
                    double elevation = 4 * token.hopHeight * t * (1 - t);

                    return Positioned(
                      left: curX - 15,
                      top: curY - 24 - elevation,
                      child: _buildPawnFigurine(token, elevation),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPawnFigurine(TokenHopState token, double elevation) {
    bool isAirborne = elevation > 1.5;

    return SizedBox(
      width: 30,
      height: 38,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // 1. Leader Gold Crown
          if (token.isLeader)
            const Positioned(
              top: -6,
              child: Text(
                "👑",
                style: TextStyle(fontSize: 11),
              ),
            ),

          // 2. Sculpted Figurine Head (Gold-Rimmed 3D Medallion with CEO Portrait)
          Positioned(
            top: 4,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.35),
                  radius: 0.85,
                  colors: [
                    Colors.white.withAlpha(220),
                    token.playerColor,
                    Color.alphaBlend(Colors.black.withAlpha(160), token.playerColor),
                  ],
                ),
                border: Border.all(
                  color: token.isCurrentTurn ? Colors.amberAccent : AppTheme.gold,
                  width: token.isCurrentTurn ? 2.0 : 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(180),
                    blurRadius: isAirborne ? 6 : 3,
                    offset: Offset(0, isAirborne ? 4 : 1.5),
                  ),
                  if (token.isCurrentTurn)
                    BoxShadow(
                      color: AppTheme.gold.withAlpha(140),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: ClipOval(
                child: token.avatarAssetPath.isNotEmpty
                    ? Image.asset(
                        token.avatarAssetPath,
                        width: 26,
                        height: 26,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            token.avatarEmoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          token.avatarEmoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
              ),
            ),
          ),

          // 3. Weighted Metallic Pedestal Base Disc
          Positioned(
            bottom: 0,
            child: Container(
              width: 18,
              height: 7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.amber.shade200,
                    AppTheme.gold,
                    const Color(0xFF6A4E00),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(150),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 14,
                  height: 3.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: token.playerColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TokenGroundShadowPainter extends CustomPainter {
  final List<TokenHopState> tokens;

  TokenGroundShadowPainter({required this.tokens});

  @override
  void paint(Canvas canvas, Size size) {
    for (final token in tokens) {
      double pxStartX = token.startNormalizedPos.dx * size.width;
      double pxStartY = token.startNormalizedPos.dy * size.height;
      double pxTargetX = token.targetNormalizedPos.dx * size.width;
      double pxTargetY = token.targetNormalizedPos.dy * size.height;

      double t = token.hopProgress;
      double linearX = pxStartX + (pxTargetX - pxStartX) * t;
      double linearY = pxStartY + (pxTargetY - pxStartY) * t;
      double elevation = 4 * token.hopHeight * t * (1 - t);

      // 1. Dynamic Contact Ground Drop Shadow
      double shadowY = linearY + 5.0;
      double shadowWidth = max(7.0, 18.0 - (elevation * 0.40));
      double shadowHeight = max(3.5, 7.5 - (elevation * 0.20));
      double shadowOpacity = max(0.15, 0.60 - (elevation * 0.020));

      final shadowPaint = Paint()
        ..color = Colors.black.withAlpha((shadowOpacity * 255).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(linearX, shadowY),
          width: shadowWidth,
          height: shadowHeight,
        ),
        shadowPaint,
      );

      // 2. Active Turn Ground Spotlight
      if (token.isCurrentTurn && elevation < 2.0) {
        final spotlightPaint = Paint()
          ..color = AppTheme.gold.withAlpha(90)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);

        canvas.drawCircle(Offset(linearX, shadowY), 13.0, spotlightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TokenGroundShadowPainter oldDelegate) => true;
}

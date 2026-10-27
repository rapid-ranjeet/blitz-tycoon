import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tile_model.dart';
import '../../models/player_model.dart';
import 'board_tile_widget.dart';
import 'token_hopper_layer.dart';

class BoardCanvas extends StatefulWidget {
  final List<TileModel> tiles;
  final List<PlayerModel> players;
  final ValueNotifier<List<TokenHopState>> tokenStatesNotifier;
  final Widget centerDashboard;
  final TransformationController transformationController;

  const BoardCanvas({
    super.key,
    required this.tiles,
    required this.players,
    required this.tokenStatesNotifier,
    required this.centerDashboard,
    required this.transformationController,
  });

  @override
  State<BoardCanvas> createState() => _BoardCanvasState();
}

class _BoardCanvasState extends State<BoardCanvas> with SingleTickerProviderStateMixin {
  bool is3DView = true;
  late AnimationController _tiltController;
  late Animation<double> _tiltAnimation;

  @override
  void initState() {
    super.initState();
    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _tiltAnimation = Tween<double>(begin: 0.0, end: 0.20).animate(
      CurvedAnimation(parent: _tiltController, curve: Curves.easeOutCubic),
    );
    if (is3DView) {
      _tiltController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _tiltController.dispose();
    super.dispose();
  }

  void _toggle3DView() {
    setState(() {
      is3DView = !is3DView;
      if (is3DView) {
        _tiltController.forward();
      } else {
        _tiltController.reverse();
      }
    });
  }

  Offset _getGridCoord(int index) {
    if (index >= 0 && index <= 7) {
      return Offset(7.0 - index, 7.0);
    } else if (index >= 8 && index <= 13) {
      return Offset(0.0, 7.0 - (index - 7));
    } else if (index >= 14 && index <= 21) {
      return Offset((index - 14).toDouble(), 0.0);
    } else {
      return Offset(7.0, (index - 21).toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Interactive Panning & Zoom Viewport
        InteractiveViewer(
          transformationController: widget.transformationController,
          minScale: 0.85,
          maxScale: 2.8,
          boundaryMargin: const EdgeInsets.all(32),
          clipBehavior: Clip.none,
          child: Center(
            child: AnimatedBuilder(
              animation: _tiltAnimation,
              builder: (context, child) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0011) // 3D Perspective depth
                    ..rotateX(_tiltAnimation.value), // Realistic tabletop pitch
                  child: child,
                );
              },
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  // Luxury Tabletop Environment: Polished Mahogany Wood Frame with Deep Cast Shadow
                  padding: const EdgeInsets.all(7.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF382315), // Polished mahogany wood grain
                        Color(0xFF1E1108),
                        Color(0xFF2C1A0F),
                        Color(0xFF1A0E07),
                      ],
                      stops: [0.0, 0.35, 0.70, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.gold.withAlpha(220), width: 2.2),
                    boxShadow: [
                      // Deep physical cast shadow onto the tabletop surface
                      BoxShadow(
                        color: Colors.black.withAlpha(240),
                        blurRadius: 30,
                        spreadRadius: 4,
                        offset: const Offset(0, 18),
                      ),
                      // Ambient warm table lamp reflection
                      BoxShadow(
                        color: AppTheme.gold.withAlpha(50),
                        blurRadius: 14,
                        spreadRadius: 1,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Container(
                    // Inner Board Felt Surface (High-Roller Royal Navy / Emerald Velvet)
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        center: Alignment.center,
                        radius: 0.95,
                        colors: [
                          Color(0xFF182238), // Center luxury velvet illumination
                          Color(0xFF0D1322), // Perimeter grooved shadow
                        ],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0xFF3B4D72), width: 1.2),
                    ),
                    child: Stack(
                      children: [
                        // Layer 1: Center Board Gold Foil Brand Crest Watermark
                        Positioned.fill(
                          child: Center(
                            child: Opacity(
                              opacity: 0.07,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.workspace_premium, size: 95, color: AppTheme.gold),
                                  SizedBox(height: 4),
                                  Text(
                                    "BLITZ TYCOON",
                                    style: TextStyle(
                                      fontFamily: "serif",
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                      letterSpacing: 4.5,
                                      color: AppTheme.gold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Layer 2: Static Board Tiles (Rendered along Grid Perimeter)
                        RepaintBoundary(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              double cellSize = constraints.maxWidth / 8.0;
                              return Stack(
                                children: List.generate(widget.tiles.length, (index) {
                                  final tile = widget.tiles[index];
                                  final coord = _getGridCoord(index);
                                  return Positioned(
                                    left: coord.dx * cellSize,
                                    top: coord.dy * cellSize,
                                    width: cellSize,
                                    height: cellSize,
                                    child: BoardTileWidget(tile: tile, players: widget.players),
                                  );
                                }),
                              );
                            },
                          ),
                        ),

                        // Layer 3: Center Grand Arena (Stock Ticker & Interactive Rolling Pit)
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(42.0),
                            child: widget.centerDashboard,
                          ),
                        ),

                        // Layer 4: 120 FPS Sculpted 3D Figurine Pawns & Parabolic Hopper Layer
                        Positioned.fill(
                          child: TokenHopperLayer(
                            tokensNotifier: widget.tokenStatesNotifier,
                          ),
                        ),

                        // Layer 5: Ornamental Brass Corner Brackets (Collector's Board Finish)
                        Positioned(
                          top: 2,
                          left: 2,
                          child: _buildBrassCornerBracket(0),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: _buildBrassCornerBracket(1),
                        ),
                        Positioned(
                          bottom: 2,
                          left: 2,
                          child: _buildBrassCornerBracket(2),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: _buildBrassCornerBracket(3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 2. Floating 3D / 2D Perspective Toggle Pill
        Positioned(
          top: 10,
          right: 12,
          child: GestureDetector(
            onTap: _toggle3DView,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF101726).withAlpha(220),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.gold.withAlpha(160), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(150),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    is3DView ? Icons.view_in_ar_rounded : Icons.crop_square_rounded,
                    size: 14,
                    color: AppTheme.gold,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    is3DView ? "3D TABLETOP" : "2D FLAT",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: AppTheme.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrassCornerBracket(int cornerIndex) {
    // 0: Top-Left, 1: Top-Right, 2: Bottom-Left, 3: Bottom-Right
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: AppTheme.gold.withAlpha(40),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppTheme.gold.withAlpha(180), width: 1.2),
      ),
      child: Center(
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.amber.shade200,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(120),
                blurRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/tile_model.dart';
import '../../models/player_model.dart';
import '../../core/theme/app_theme.dart';

class BoardTileWidget extends StatelessWidget {
  final TileModel tile;
  final List<PlayerModel> players;
  final VoidCallback? onTap;

  const BoardTileWidget({
    super.key,
    required this.tile,
    required this.players,
    this.onTap,
  });

  PlayerModel? get owner {
    if (tile.ownerId == -1) return null;
    try {
      return players.firstWhere((p) => p.id == tile.ownerId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileOwner = owner;
    final isOwned = tileOwner != null;
    final isProperty = tile.type == TileType.property;
    final isCorner = tile.type != TileType.property && tile.type != TileType.marketSurge;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(1.2),
        decoration: BoxDecoration(
          // Property tiles use authentic tactile ivory linen cardstock;
          // Corner tiles use polished obsidian gold-rimmed collector plates
          gradient: isProperty
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFCFDFE),
                    Color(0xFFF1F5F9),
                    Color(0xFFE2E8F0),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isCorner
                      ? const [Color(0xFF222C3F), Color(0xFF0F1522)]
                      : const [Color(0xFF142E25), Color(0xFF0D1E18)],
                ),
          borderRadius: BorderRadius.circular(5.0),
          border: Border.all(
            color: isOwned
                ? tileOwner.color
                : (isCorner
                    ? AppTheme.gold.withAlpha(200)
                    : (tile.frozenTurns > 0 ? AppTheme.neonCyan : const Color(0xFFB0BEC5))),
            width: isOwned ? 2.2 : (isCorner ? 1.6 : 1.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(160),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
            if (isOwned)
              BoxShadow(
                color: tileOwner.color.withAlpha(100),
                blurRadius: 6,
                spreadRadius: 0.8,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: Stack(
            children: [
              // 1. Property Card Color Header Band (Tactile Monopoly Deed Look)
              if (isProperty)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 12.5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: tile.groupColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(80),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        height: 1.5,
                        width: 20,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(200),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),

              // 2. Corner Tile Deluxe Gold Ribbon Header
              if (isCorner)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 3.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getCornerAccentColor(tile.type).withAlpha(140),
                          _getCornerAccentColor(tile.type),
                          _getCornerAccentColor(tile.type).withAlpha(140),
                        ],
                      ),
                    ),
                  ),
                ),

              // 3. Tile Body Content (FittedBox to scale perfectly on all screen sizes)
              Padding(
                padding: EdgeInsets.only(
                  top: isProperty ? 13.0 : 4.0,
                  bottom: 1.5,
                  left: 1.5,
                  right: 1.5,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 44,
                    height: isProperty ? 38 : 44,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Icon / Building Visual
                        if (isProperty)
                          _buildPropertyBuildings(tile)
                        else
                          _buildCornerIcon(tile.type),

                        // Property or Tile Name (Sharp high-contrast typography)
                        Expanded(
                          child: Center(
                            child: Text(
                              _formatTileLabel(tile.name),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isCorner ? 8.5 : 8.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                                color: isProperty
                                    ? const Color(0xFF0F172A) // Crisp dark charcoal on ivory card
                                    : (isCorner ? _getCornerAccentColor(tile.type) : AppTheme.emeraldGreen),
                                height: 1.05,
                              ),
                            ),
                          ),
                        ),

                        // Price / Rent / Action Tag
                        _buildBottomTag(tile, isOwned, tileOwner),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Owner Avatar Ribbon Pin (Top-Right Pin)
              if (isOwned)
                Positioned(
                  top: 1,
                  right: 1,
                  child: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      color: tileOwner.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(180),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Text(
                      tileOwner.ceo.avatarEmoji,
                      style: const TextStyle(fontSize: 7.5),
                    ),
                  ),
                ),

              // 5. Freeze / Tax Audit Frost Overlay
              if (tile.frozenTurns > 0)
                Positioned.fill(
                  child: Container(
                    color: AppTheme.neonCyan.withAlpha(85),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00384D),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: AppTheme.neonCyan, width: 1.0),
                        ),
                        child: const Text(
                          "❄️ AUDIT",
                          style: TextStyle(
                            fontSize: 6.5,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.neonCyan,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyBuildings(TileModel tile) {
    if (tile.upgradeLevel == 0) {
      return const Icon(
        Icons.apartment_rounded,
        size: 11,
        color: Color(0xFF94A3B8), // Muted blueprint gray
      );
    }

    if (tile.upgradeLevel == 4) {
      // 3D Empire Golden Skyscraper
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.apartment_rounded, size: 12, color: Color(0xFFB45309)),
          Icon(Icons.star_rounded, size: 9, color: Color(0xFFEAB308)),
        ],
      );
    }

    // 3D Miniature Houses (1, 2, or 3)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        tile.upgradeLevel,
        (_) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 0.5),
          child: Icon(Icons.home_work_rounded, size: 10, color: Color(0xFF16A34A)),
        ),
      ),
    );
  }

  Widget _buildCornerIcon(TileType type) {
    switch (type) {
      case TileType.start:
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            'assets/images/icon_payday.png',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.teal.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flight_takeoff_rounded, size: 14, color: AppTheme.neonCyan),
            ),
          ),
        );
      case TileType.corporateHeist:
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            'assets/images/icon_heist.png',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppTheme.dangerRed.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, size: 14, color: AppTheme.dangerRed),
            ),
          ),
        );
      case TileType.taxAudit:
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            'assets/images/icon_tax.png',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_rounded, size: 14, color: Colors.amber),
            ),
          ),
        );
      case TileType.angelLab:
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            'assets/images/icon_incubator.png',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.rocket_launch_rounded, size: 14, color: Colors.purpleAccent),
          ),
        );
      case TileType.marketSurge:
        return const Icon(Icons.trending_up_rounded, size: 14, color: AppTheme.emeraldGreen);
      default:
        return const Icon(Icons.place_rounded, size: 12, color: Colors.white70);
    }
  }

  Color _getCornerAccentColor(TileType type) {
    switch (type) {
      case TileType.start:
        return AppTheme.neonCyan;
      case TileType.corporateHeist:
        return AppTheme.dangerRed;
      case TileType.taxAudit:
        return Colors.amber;
      case TileType.angelLab:
        return Colors.purpleAccent;
      case TileType.marketSurge:
        return AppTheme.emeraldGreen;
      default:
        return Colors.white70;
    }
  }

  Widget _buildBottomTag(TileModel tile, bool isOwned, PlayerModel? owner) {
    if (tile.type == TileType.property) {
      String text = isOwned
          ? "Rent ₹${_formatCompact(tile.currentRent)}"
          : "₹${_formatCompact(tile.cost)}";

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 1.0),
        decoration: BoxDecoration(
          color: isOwned
              ? owner?.color.withAlpha(220) ?? Colors.black87
              : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(2.5),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 7.2,
            fontWeight: FontWeight.w900,
            color: isOwned ? Colors.white : AppTheme.gold,
            letterSpacing: -0.2,
          ),
        ),
      );
    }

    if (tile.type == TileType.start) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 1.0),
        decoration: BoxDecoration(
          color: Colors.teal.shade800,
          borderRadius: BorderRadius.circular(2.5),
        ),
        child: const Text(
          "+₹2.0L",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 7.2,
            fontWeight: FontWeight.w900,
            color: AppTheme.neonCyan,
          ),
        ),
      );
    }

    if (tile.type == TileType.taxAudit) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 1.0),
        decoration: BoxDecoration(
          color: Colors.amber.shade900,
          borderRadius: BorderRadius.circular(2.5),
        ),
        child: const Text(
          "PAY 10%",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 6.8,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      );
    }

    if (tile.type == TileType.corporateHeist) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 1.0),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(2.5),
        ),
        child: const Text(
          "HEIST",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 6.8,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      );
    }

    if (tile.type == TileType.marketSurge) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 1.0),
        decoration: BoxDecoration(
          color: const Color(0xFF064E3B),
          borderRadius: BorderRadius.circular(2.5),
        ),
        child: const Text(
          "SURGE",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 6.8,
            fontWeight: FontWeight.w900,
            color: AppTheme.emeraldGreen,
          ),
        ),
      );
    }

    return const SizedBox(height: 2);
  }

  String _formatTileLabel(String rawName) {
    List<String> parts = rawName.split(" ");
    if (parts.length >= 2) {
      return "${parts[0]}\n${parts.sublist(1).join(" ")}";
    }
    return rawName;
  }

  String _formatCompact(int val) {
    if (val >= 10000000) return "${(val / 10000000).toStringAsFixed(1)}Cr";
    if (val >= 100000) return "${(val / 100000).toStringAsFixed(0)}L";
    if (val >= 1000) return "${(val / 1000).toStringAsFixed(0)}k";
    return val.toString();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/tile_model.dart';
import '../../models/player_model.dart';
import '../../logic/ai_engine.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/feedback_service.dart';

class AuctionDialog extends StatefulWidget {
  final TileModel tile;
  final List<PlayerModel> players;
  final List<TileModel> allTiles;
  final BotConfig botConfig;
  final Function(PlayerModel highestBidder, int winningBid) onAuctionCompleted;

  const AuctionDialog({
    super.key,
    required this.tile,
    required this.players,
    required this.allTiles,
    this.botConfig = BotConfig.founder,
    required this.onAuctionCompleted,
  });

  @override
  State<AuctionDialog> createState() => _AuctionDialogState();
}

class _AuctionDialogState extends State<AuctionDialog> with SingleTickerProviderStateMixin {
  late int currentBid;
  PlayerModel? highestBidder;
  int secondsRemaining = 7;
  Timer? timer;
  final AiEngine aiEngine = AiEngine();

  @override
  void initState() {
    super.initState();
    currentBid = (widget.tile.cost * 0.5).round();
    _startTimer();
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (secondsRemaining > 1) {
          secondsRemaining--;
          _evaluateAiBids();
        } else {
          t.cancel();
          _concludeAuction();
        }
      });
    });
  }

  void _evaluateAiBids() {
    for (final p in widget.players.where((p) => p.isAI && !p.isBankrupt)) {
      if (highestBidder?.id == p.id) continue;

      int? recommendedBid = aiEngine.evaluateAuctionBid(
        ai: p,
        tile: widget.tile,
        currentBid: currentBid,
        allTiles: widget.allTiles,
        config: widget.botConfig,
      );

      if (recommendedBid != null && recommendedBid > currentBid) {
        setState(() {
          currentBid = recommendedBid;
          highestBidder = p;
          secondsRemaining = (secondsRemaining + 2).clamp(1, 8);
        });
        FeedbackService.buttonTap();
        break;
      }
    }
  }

  void _placeHumanBid() {
    final human = widget.players.firstWhere((p) => !p.isAI);
    if (human.isBankrupt) return;

    int nextBid = currentBid + 50000;
    if (human.cash >= nextBid) {
      setState(() {
        currentBid = nextBid;
        highestBidder = human;
        secondsRemaining = (secondsRemaining + 2).clamp(1, 8);
      });
      FeedbackService.buttonTap();
    }
  }

  void _concludeAuction() {
    if (highestBidder != null) {
      widget.onAuctionCompleted(highestBidder!, currentBid);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isUrgent = secondsRemaining <= 3;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF221A12), Color(0xFF13101C)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.gold, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(220),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppTheme.gold.withAlpha(50),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header Bar: Gavel, Title & Pulsing Urgency Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.gavel_rounded, color: AppTheme.gold, size: 24),
                    SizedBox(width: 8),
                    Text(
                      "FAST AUCTION",
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isUrgent ? AppTheme.dangerRed.withAlpha(50) : const Color(0xFF202738),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUrgent ? AppTheme.dangerRed : Colors.white24,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_rounded,
                        size: 14,
                        color: isUrgent ? AppTheme.dangerRed : Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${secondsRemaining}s",
                        style: TextStyle(
                          color: isUrgent ? AppTheme.dangerRed : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 2. Property Deed Card Miniature
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF161E2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.tile.groupColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.tile.groupColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tile.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Market Valuation: ₹${_formatCompact(widget.tile.cost)}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. Current High Bid Podium
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1524),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2C3854)),
              ),
              child: Column(
                children: [
                  const Text(
                    "CURRENT HIGH BID",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹$currentBid",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.neonCyan,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (highestBidder != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: highestBidder!.color.withAlpha(50),
                            border: Border.all(color: highestBidder!.color, width: 1),
                          ),
                          child: ClipOval(
                            child: highestBidder!.ceo.avatarAssetPath.isNotEmpty
                                ? Image.asset(
                                    highestBidder!.ceo.avatarAssetPath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(
                                        highestBidder!.ceo.avatarEmoji,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      highestBidder!.ceo.avatarEmoji,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Leader: ${highestBidder!.name} (${highestBidder!.ceo.role})",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: highestBidder!.color,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      "No bids placed yet — Starting at 50% discount!",
                      style: TextStyle(fontSize: 10.5, color: Colors.white38),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 4. Live Bidder Avatars Strip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: widget.players.map((p) {
                bool isWinning = highestBidder?.id == p.id;
                return Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: p.color.withAlpha(50),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isWinning ? AppTheme.gold : p.color,
                              width: isWinning ? 2.5 : 1.2,
                            ),
                          ),
                          child: ClipOval(
                            child: p.ceo.avatarAssetPath.isNotEmpty
                                ? Image.asset(
                                    p.ceo.avatarAssetPath,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Center(
                                      child: Text(
                                        p.ceo.avatarEmoji,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      p.ceo.avatarEmoji,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                          ),
                        ),
                        if (isWinning)
                          Positioned(
                            top: -8,
                            right: -4,
                            child: const Text("👑", style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.name.split(" ").first,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isWinning ? FontWeight.w900 : FontWeight.normal,
                        color: isWinning ? AppTheme.gold : Colors.white70,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 5. Tactile 3D Raise Bid Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.black,
                  elevation: 6,
                  shadowColor: AppTheme.gold.withAlpha(160),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.amberAccent, width: 1.5),
                  ),
                ),
                onPressed: _placeHumanBid,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "RAISE BID (+₹50,000)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCompact(int val) {
    if (val >= 10000000) return "${(val / 10000000).toStringAsFixed(1)}Cr";
    if (val >= 100000) return "${(val / 100000).toStringAsFixed(0)}L";
    if (val >= 1000) return "${(val / 1000).toStringAsFixed(0)}k";
    return val.toString();
  }
}

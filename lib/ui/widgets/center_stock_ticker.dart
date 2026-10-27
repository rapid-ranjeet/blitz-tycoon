import 'package:flutter/material.dart';
import '../../models/stock_model.dart';
import '../../models/player_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/feedback_service.dart';

class CenterStockTickerWidget extends StatelessWidget {
  final StockModel stock;
  final PlayerModel humanPlayer;
  final VoidCallback onBuy;
  final VoidCallback onSell;
  final List<String> logs;
  final VoidCallback? onCenterRoll;
  final bool isRolling;
  final bool isHumanTurn;
  final int die1;
  final int die2;
  final int multiplier;

  const CenterStockTickerWidget({
    super.key,
    required this.stock,
    required this.humanPlayer,
    required this.onBuy,
    required this.onSell,
    required this.logs,
    this.onCenterRoll,
    this.isRolling = false,
    this.isHumanTurn = true,
    this.die1 = 3,
    this.die2 = 4,
    this.multiplier = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. Floating Top Brass Stock Ticker Bar
        _buildStockTickerBar(),

        // 2. Grand Central Velvet Dice Pit & Interactive Rolling Arena
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: _buildCenterVelvetArena(),
          ),
        ),

        // 3. Floating Bottom Event Highlight Marquee
        _buildBottomEventMarquee(),
      ],
    );
  }

  Widget _buildStockTickerBar() {
    final isBull = stock.isBullish;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1728).withAlpha(240),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gold.withAlpha(140), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(160),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isBull ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: isBull ? AppTheme.emeraldGreen : AppTheme.dangerRed,
              size: 15,
            ),
            const SizedBox(width: 4),
            Text(
              stock.symbol,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10.0, color: Colors.white),
            ),
            const SizedBox(width: 4),
            Text(
              "₹${stock.price} (${stock.changePercent >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(1)}%)",
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: isBull ? AppTheme.emeraldGreen : AppTheme.dangerRed,
              ),
            ),
            const SizedBox(width: 10),
            // Quick Buy / Sell Chips
            InkWell(
              onTap: () {
                FeedbackService.buttonTap();
                onBuy();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withAlpha(45),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.emeraldGreen, width: 0.8),
                ),
                child: const Text(
                  "BUY",
                  style: TextStyle(fontSize: 8.0, color: AppTheme.emeraldGreen, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                FeedbackService.buttonTap();
                onSell();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withAlpha(45),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.dangerRed, width: 0.8),
                ),
                child: const Text(
                  "SELL",
                  style: TextStyle(fontSize: 8.0, color: AppTheme.dangerRed, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterVelvetArena() {
    return Center(
      child: GestureDetector(
        onTap: (isHumanTurn && !isRolling) ? onCenterRoll : null,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 135, maxHeight: 135),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment.center,
              radius: 0.85,
              colors: [
                Color(0xFF1E2D4A), // Deep royal navy velvet center
                Color(0xFF0F1829),
                Color(0xFF0A101C),
              ],
            ),
            border: Border.all(color: AppTheme.gold, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(180),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              if (isHumanTurn && !isRolling)
                BoxShadow(
                  color: AppTheme.gold.withAlpha(100),
                  blurRadius: 12,
                  spreadRadius: 1.5,
                ),
            ],
          ),
          child: Center(
            child: isRolling
                ? _buildTumblingDiceInPit()
                : (isHumanTurn
                    ? _buildInteractiveRollPrompt()
                    : _buildOpponentTurnIndicator()),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveRollPrompt() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.amber.shade200, AppTheme.gold, const Color(0xFF7A5800)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gold.withAlpha(150),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(Icons.casino_rounded, size: 24, color: Colors.black),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(180),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.gold, width: 1.0),
          ),
          child: Text(
            "TAP TO ROLL (${multiplier}X)",
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: AppTheme.gold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTumblingDiceInPit() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMiniDie(die1),
        const SizedBox(width: 8),
        _buildMiniDie(die2),
      ],
    );
  }

  Widget _buildMiniDie(int face) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(160),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          "$face",
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  Widget _buildOpponentTurnIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation(AppTheme.gold),
          ),
        ),
        SizedBox(height: 5),
        Text(
          "OPPONENT TURN",
          style: TextStyle(
            fontSize: 8.0,
            fontWeight: FontWeight.w900,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomEventMarquee() {
    final latestLog = logs.isNotEmpty ? logs.first : "Match in Progress — Take over the board!";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1A).withAlpha(220),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12, width: 0.8),
      ),
      child: Text(
        latestLog,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: AppTheme.gold,
        ),
      ),
    );
  }
}

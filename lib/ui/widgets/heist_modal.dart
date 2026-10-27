import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/player_model.dart';
import '../../core/services/feedback_service.dart';

class HeistResult {
  final int vaultIndex; // 0, 1, 2
  final bool succeeded;
  final double lootPercentage;
  final String outcomeDescription;

  HeistResult({
    required this.vaultIndex,
    required this.succeeded,
    required this.lootPercentage,
    required this.outcomeDescription,
  });
}

class HeistModal extends StatelessWidget {
  final PlayerModel target;

  const HeistModal({super.key, required this.target});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF221216), Color(0xFF13101C)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.dangerRed, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(220),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppTheme.dangerRed.withAlpha(60),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Row(
              children: const [
                Icon(Icons.lock_open_rounded, color: AppTheme.dangerRed, size: 24),
                SizedBox(width: 8),
                Text(
                  "CORPORATE HEIST",
                  style: TextStyle(
                    color: AppTheme.dangerRed,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Infiltrated Target Medallion
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1522),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: target.color.withAlpha(120)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: target.color.withAlpha(50),
                      border: Border.all(color: target.color, width: 1.5),
                    ),
                    child: ClipOval(
                      child: target.ceo.avatarAssetPath.isNotEmpty
                          ? Image.asset(
                              target.ceo.avatarAssetPath,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Center(
                                child: Text(
                                  target.ceo.avatarEmoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                target.ceo.avatarEmoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Target: ${target.name}",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Vault Reserves: ₹${_formatCompact(target.cash)}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              "Select an infiltration vector to breach the vault:",
              style: TextStyle(color: Colors.white70, fontSize: 11.5),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Vault 1: Phishing Wiretap (90% success, 12% loot)
            _buildVaultOption(
              context,
              index: 0,
              title: "Phishing Wiretap",
              badge: "90% SAFE",
              badgeColor: AppTheme.emeraldGreen,
              lootText: "12% Liquidity Siphon",
              riskText: "Failure: ₹40,000 regulatory fine",
              icon: Icons.mark_email_read_rounded,
            ),
            const SizedBox(height: 8),

            // Vault 2: Quantum IP Decryption (65% success, 28% loot)
            _buildVaultOption(
              context,
              index: 1,
              title: "Quantum IP Decrypt",
              badge: "65% BALANCED",
              badgeColor: AppTheme.neonCyan,
              lootText: "28% Liquidity Siphon",
              riskText: "Failure: HQ frozen 1 turn + ₹100k fine",
              icon: Icons.memory_rounded,
            ),
            const SizedBox(height: 8),

            // Vault 3: Black-Hat Hostile Takeover (40% success, 50% loot)
            _buildVaultOption(
              context,
              index: 2,
              title: "Black-Hat Takeover",
              badge: "40% HIGH RISK",
              badgeColor: AppTheme.dangerRed,
              lootText: "50% Massive Heist",
              riskText: "Failure: Target counter-hacks 25% of cash",
              icon: Icons.warning_amber_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultOption(
    BuildContext context, {
    required int index,
    required String title,
    required String badge,
    required Color badgeColor,
    required String lootText,
    required String riskText,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () {
        FeedbackService.sabotageTriggered();
        Navigator.pop(context, index);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF171B28),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: badgeColor.withAlpha(90), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: badgeColor.withAlpha(45),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: badgeColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withAlpha(50),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: badgeColor, width: 0.8),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lootText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    riskText,
                    style: const TextStyle(fontSize: 8.5, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatCompact(int val) {
    if (val >= 10000000) return "${(val / 10000000).toStringAsFixed(1)}Cr";
    if (val >= 100000) return "${(val / 100000).toStringAsFixed(0)}L";
    if (val >= 1000) return "${(val / 1000).toStringAsFixed(0)}k";
    return val.toString();
  }
}

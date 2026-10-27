import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/feedback_service.dart';
import '../../core/constants/game_constants.dart';
import '../../models/ceo_model.dart';
import '../../services/persistence_service.dart';
import 'matchmaking_screen.dart';
import 'game_board_screen.dart';

class HomeEmpireScreen extends StatefulWidget {
  const HomeEmpireScreen({super.key});

  @override
  State<HomeEmpireScreen> createState() => _HomeEmpireScreenState();
}

class _HomeEmpireScreenState extends State<HomeEmpireScreen> {
  final PersistenceService ps = PersistenceService.instance;
  late CeoModel selectedCeo;

  @override
  void initState() {
    super.initState();
    selectedCeo = CeoModel.defaultRoster.firstWhere(
      (c) => c.id.index == ps.profile.selectedCeoId,
      orElse: () => CeoModel.defaultRoster.first,
    );
  }

  void _upgradeCampusBuilding(String key) {
    bool ok = ps.upgradeBuilding(key);
    if (ok) {
      FeedbackService.cashReceived();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🚀 Campus Building Upgraded Successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Not enough blueprints to upgrade.")),
      );
    }
  }

  void _showMatchHistoryDialog() {
    FeedbackService.buttonTap();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.history, color: AppTheme.gold),
            SizedBox(width: 8),
            Text("MATCH CAREER HISTORY", style: TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ps.matchHistory.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("No matches recorded yet. Complete your first Blitz battle!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: ps.matchHistory.length,
                  itemBuilder: (context, i) {
                    final rec = ps.matchHistory[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: rec.isVictory ? AppTheme.emeraldGreen.withOpacity(0.4) : Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Icon(rec.isVictory ? Icons.emoji_events : Icons.close, color: rec.isVictory ? AppTheme.gold : AppTheme.dangerRed, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rec.isVictory ? "VICTORY (Won ₹${(rec.finalNetWorth / 100000).toStringAsFixed(1)}L)" : "Defeat (Winner: ${rec.winnerName})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                                Text("${rec.lapsPlayed} Laps • +${rec.starsAwarded} Stars", style: const TextStyle(fontSize: 10, color: Colors.white54)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceLight, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CLOSE"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.apartment, color: AppTheme.gold, size: 20),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                "EMPIRE HQ",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
          ],
        ),
        actions: [
          _buildCurrencyPill(Icons.star, "${ps.profile.netWorthStars}", AppTheme.gold),
          const SizedBox(width: 6),
          _buildCurrencyPill(Icons.architecture, "${ps.profile.blueprints}", AppTheme.neonCyan),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white70),
            onPressed: _showMatchHistoryDialog,
            tooltip: "Match History",
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Resume Active Match Banner (If App Restarts Mid-Match)
            if (ps.hasSavedMatch) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.emeraldGreen),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.replay, color: AppTheme.emeraldGreen, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("ACTIVE BATTLE IN PROGRESS", style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.emeraldGreen, fontSize: 13)),
                          Text("Resume exactly where you left off", style: TextStyle(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen, foregroundColor: Colors.black),
                      onPressed: () {
                        FeedbackService.buttonTap();
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const GameBoardScreen()));
                      },
                      child: const Text("RESUME"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // League Tier Banner
            _buildLeagueBanner(),
            const SizedBox(height: 16),

            // Meta-progression City Builder Showcase (Campus)
            _buildCityBuilderCard(),
            const SizedBox(height: 20),

            // CEO Selection Carousel
            const Text(
              "ACTIVE CEO HERO",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            _buildCeoSelector(),
            const SizedBox(height: 24),

            // Launch Match CTA
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 8,
              ),
              onPressed: () {
                FeedbackService.buttonTap();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => MatchmakingScreen(selectedCeo: selectedCeo)),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.play_arrow, size: 28),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "BATTLE LOBBY / QUICK MATCH",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLeagueBanner() {
    final leagueName = GameConstants.leagueTiers[ps.profile.currentLeagueIndex.clamp(0, GameConstants.leagueTiers.length - 1)];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1F2942), AppTheme.surface],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, color: AppTheme.gold, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("CURRENT DIVISION", style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold)),
                Text(leagueName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (ps.profile.netWorthStars % 80) / 80.0,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.gold),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityBuilderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(
                child: Text(
                  "TECH DISTRICT CAMPUS (BENGALURU)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.neonCyan),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.map, color: AppTheme.neonCyan, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDistrictBuilding(
                "Garage Lab",
                "Lvl ${ps.profile.garageLabLevel}",
                Icons.computer,
                ps.profile.garageLabLevel < 5 && ps.profile.blueprints >= 2,
                () => _upgradeCampusBuilding('garage'),
              ),
              const SizedBox(width: 8),
              _buildDistrictBuilding(
                "Unicorn HQ",
                "Lvl ${ps.profile.unicornHqLevel}",
                Icons.business,
                ps.profile.unicornHqLevel < 5 && ps.profile.blueprints >= 4,
                () => _upgradeCampusBuilding('hq'),
              ),
              const SizedBox(width: 8),
              _buildDistrictBuilding(
                "AI Supercluster",
                "Lvl ${ps.profile.aiClusterLevel}",
                Icons.memory,
                ps.profile.aiClusterLevel < 5 && ps.profile.blueprints >= 6,
                () => _upgradeCampusBuilding('cluster'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictBuilding(String title, String level, IconData icon, bool canUpgrade, VoidCallback onUpgrade) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.gold, size: 24),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(level, style: const TextStyle(fontSize: 9, color: AppTheme.neonCyan)),
            const SizedBox(height: 8),
            InkWell(
              onTap: canUpgrade ? onUpgrade : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: canUpgrade ? AppTheme.gold : Colors.white12,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "UPGRADE",
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: canUpgrade ? Colors.black : Colors.white38),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCeoSelector() {
    return Column(
      children: CeoModel.defaultRoster.map((ceo) {
        final isSelected = selectedCeo.id == ceo.id;
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedCeo = ceo;
              ps.profile.selectedCeoId = ceo.id.index;
            });
            FeedbackService.buttonTap();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.surfaceLight : AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.neonCyan : Colors.white10,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ceo.avatarBgColor.withAlpha(50),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.gold : ceo.avatarBgColor.withAlpha(120),
                      width: isSelected ? 2.0 : 1.2,
                    ),
                  ),
                  child: ClipOval(
                    child: ceo.avatarAssetPath.isNotEmpty
                        ? Image.asset(
                            ceo.avatarAssetPath,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Center(
                              child: Text(
                                ceo.avatarEmoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              ceo.avatarEmoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ceo.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      Text(ceo.role, style: const TextStyle(fontSize: 10, color: AppTheme.gold, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text("Passive: ${ceo.passiveDescription}", style: const TextStyle(fontSize: 9.5, color: Colors.white60)),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: AppTheme.neonCyan, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

import 'dart:math';
import '../models/player_model.dart';
import '../models/tile_model.dart';
import '../models/ceo_model.dart';
import '../models/game_state_model.dart';

class BotConfig {
  final double cashSafetyBuffer; // % of cash to keep for emergencies
  final double aggression; // Willingness to upgrade or bid aggressively
  final double mistakeProbability; // Chance to pass an optimal move
  final bool usesStockMarket;
  final bool usesCeoSkillsAggressively;

  const BotConfig({
    required this.cashSafetyBuffer,
    required this.aggression,
    required this.mistakeProbability,
    required this.usesStockMarket,
    required this.usesCeoSkillsAggressively,
  });

  static const intern = BotConfig(
    cashSafetyBuffer: 0.15,
    aggression: 0.20,
    mistakeProbability: 0.35,
    usesStockMarket: false,
    usesCeoSkillsAggressively: false,
  );

  static const founder = BotConfig(
    cashSafetyBuffer: 0.25,
    aggression: 0.55,
    mistakeProbability: 0.12,
    usesStockMarket: true,
    usesCeoSkillsAggressively: true,
  );

  static const unicorn = BotConfig(
    cashSafetyBuffer: 0.30,
    aggression: 0.75,
    mistakeProbability: 0.04,
    usesStockMarket: true,
    usesCeoSkillsAggressively: true,
  );

  static const sharkTank = BotConfig(
    cashSafetyBuffer: 0.38,
    aggression: 0.95,
    mistakeProbability: 0.0,
    usesStockMarket: true,
    usesCeoSkillsAggressively: true,
  );

  static BotConfig fromDifficulty(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.intern:
        return intern;
      case GameDifficulty.founder:
        return founder;
      case GameDifficulty.unicorn:
        return unicorn;
      case GameDifficulty.sharkTank:
        return sharkTank;
    }
  }
}

class AiEngine {
  final Random _rng = Random();

  /// 1. Multi-Attribute Utility Theory (MAUT) Property Acquisition
  bool shouldBuyProperty({
    required PlayerModel ai,
    required TileModel tile,
    required List<TileModel> allTiles,
    required List<PlayerModel> rivals,
    required BotConfig config,
  }) {
    if (ai.cash < tile.cost) return false;

    // Check mistake probability (Intern bots make occasional errors)
    if (_rng.nextDouble() < config.mistakeProbability) {
      return false;
    }

    // Feature 1: Monopoly Set Synergy
    final groupTiles = allTiles.where((t) => t.groupColor == tile.groupColor).toList();
    int ownedCount = groupTiles.where((t) => t.ownerId == ai.id).length;
    double fSynergy = (ownedCount + 1.0) / max(1, groupTiles.length);

    // Feature 2: Monopoly Block Denial
    double fBlock = 0.0;
    for (final r in rivals.where((p) => !p.isBankrupt)) {
      int rivalCount = groupTiles.where((t) => t.ownerId == r.id).length;
      if (groupTiles.length > 1 && rivalCount == groupTiles.length - 1) {
        fBlock = 1.0;
        break;
      }
    }

    // Feature 3: Liquidity Buffer Sigmoid
    int requiredBuffer = (ai.cash * config.cashSafetyBuffer).round();
    double margin = (ai.cash - tile.cost) / max(1, requiredBuffer);
    double fBuffer = 1.0 / (1.0 + exp(-6.0 * (margin - 1.0)));

    // Combined Weighted Utility
    double utility = 0.35 * fSynergy + 0.30 * fBlock + 0.25 * fBuffer + 0.10 * 1.0;
    double threshold = 0.48 - (config.aggression * 0.22);

    return utility >= threshold;
  }

  /// 2. Dynamic HQ Upgrade Selection with Threat Radius
  TileModel? choosePropertyToUpgrade({
    required PlayerModel ai,
    required List<TileModel> allTiles,
    required List<PlayerModel> rivals,
    required BotConfig config,
  }) {
    final owned = allTiles.where((t) => t.ownerId == ai.id && !t.isMaxUpgraded).toList();
    if (owned.isEmpty) return null;

    TileModel? bestCandidate;
    double maxUtility = -1.0;

    for (final tile in owned) {
      int cost = tile.upgradeCost;
      if (ai.ceo.id == CeoId.realEstateMogul) cost = (cost * 0.8).round();
      if (ai.cash - cost < (ai.cash * config.cashSafetyBuffer)) continue;

      int deltaRent = tile.rentStages[tile.upgradeLevel + 1] - tile.currentRent;
      double deltaRoi = (deltaRent / max(1, cost)) / 2.0;

      // Opponent hit probability in next turn (distance 1..6)
      double hitChance = 0.0;
      for (final r in rivals.where((p) => !p.isBankrupt)) {
        int dist = (tile.id - r.tileIndex) % allTiles.length;
        if (dist >= 1 && dist <= 6) {
          hitChance += (1.0 - hitChance) * (1.0 / 6.0);
        }
      }

      double utility = 0.45 * deltaRoi + 0.35 * hitChance + 0.20 * config.aggression;
      if (utility > maxUtility) {
        maxUtility = utility;
        bestCandidate = tile;
      }
    }

    return maxUtility >= 0.25 ? bestCandidate : null;
  }

  /// 3. Fast Auction Bidding Valuation Ceiling
  int? evaluateAuctionBid({
    required PlayerModel ai,
    required TileModel tile,
    required int currentBid,
    required List<TileModel> allTiles,
    required BotConfig config,
  }) {
    int nextBid = currentBid + 50000;
    int safetyBuffer = (ai.cash * config.cashSafetyBuffer).round();
    if (ai.cash - nextBid < safetyBuffer) return null;

    final group = allTiles.where((t) => t.groupColor == tile.groupColor).toList();
    int ownedCount = group.where((t) => t.ownerId == ai.id).length;
    double fSynergy = (ownedCount + 1.0) / max(1, group.length);

    double intrinsicValue = tile.cost * (1.0 + 0.60 * fSynergy);
    double maxBidLimit = min(ai.cash - safetyBuffer.toDouble(), intrinsicValue * config.aggression);

    if (nextBid <= maxBidLimit) {
      return nextBid;
    }
    return null;
  }

  /// 4. CEO Active Skill Decision
  bool shouldActivateSkill({
    required PlayerModel ai,
    required List<TileModel> allTiles,
    required List<PlayerModel> rivals,
    required BotConfig config,
  }) {
    if (ai.ceo.currentCooldown > 0) return false;
    if (!config.usesCeoSkillsAggressively && _rng.nextBool()) return false;
    return true;
  }

  /// 5. Stock Market Arbitrage & Liquidity Management
  int evaluateStockAction({
    required PlayerModel ai,
    required int currentStockPrice,
    required int previousPrice,
    required BotConfig config,
  }) {
    if (!config.usesStockMarket) return 0;

    // Buy the dip if price drops under 100 and AI has comfortable cash
    if (currentStockPrice < 95 && ai.cash > 400000) {
      return 1;
    }

    // Liquidate shares when price peaks above 165
    if (currentStockPrice > 165 && ai.stockShares >= 1000) {
      return -1;
    }

    return 0;
  }
}

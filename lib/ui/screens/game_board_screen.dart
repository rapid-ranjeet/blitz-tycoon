import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/game_constants.dart';
import '../../core/services/feedback_service.dart';
import '../../core/services/audio_service.dart';
import '../../models/player_model.dart';
import '../../models/tile_model.dart';
import '../../models/stock_model.dart';
import '../../models/ceo_model.dart';
import '../../logic/ai_engine.dart';
import '../../services/multiplayer_service.dart';
import '../../services/persistence_service.dart';
import '../widgets/board_canvas.dart';
import '../widgets/center_stock_ticker.dart';
import '../widgets/heist_modal.dart';
import '../widgets/trade_bottom_sheet.dart';
import '../widgets/auction_dialog.dart';
import '../widgets/juice_overlay.dart';
import '../widgets/token_hopper_layer.dart';
import '../widgets/dice_roller_3d.dart';

class GameBoardScreen extends StatefulWidget {
  const GameBoardScreen({super.key});

  @override
  State<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen> {
  late List<TileModel> tiles;
  late List<PlayerModel> players;
  late ValueNotifier<List<TokenHopState>> tokenStatesNotifier;
  StockModel hotStock = StockModel(
    symbol: "ZOMT",
    companyName: "HyperDelivery",
    sector: "Quick Commerce",
    price: 130,
    previousPrice: 128,
  );

  int currentTurnIndex = 0;
  bool isMoving = false;
  int lastDiceRoll = 7;
  int die1 = 3;
  int die2 = 4;
  int diceMultiplier = 1;
  final List<int> multiplierOptions = [1, 2, 5, 10];
  final List<String> eventLogs = [];
  final Random random = Random();

  final AiEngine aiEngine = AiEngine();
  BotConfig botConfig = BotConfig.founder;
  final MultiplayerService mp = MultiplayerService.instance;
  final PersistenceService ps = PersistenceService.instance;

  Timer? stockTickTimer;
  StreamSubscription<int>? turnTimerSubscription;
  int turnSecondsLeft = 15;
  bool suddenDeathTriggered = false;

  final TransformationController boardTransformController = TransformationController();
  final JuiceOverlayController juiceController = JuiceOverlayController();

  @override
  void initState() {
    super.initState();
    _initBoard();
    _initPlayers();
    _initStockMarket();
    _initTokenStates();
    _initTurnClockListener();
    _restoreSnapshotIfPresent();
    _addLog("🎮 Match Started! Reach the top valuation before Sudden Death hits!");
    _startTurnTimer();
  }

  @override
  void dispose() {
    stockTickTimer?.cancel();
    turnTimerSubscription?.cancel();
    mp.stopTurnCountdown();
    boardTransformController.dispose();
    tokenStatesNotifier.dispose();
    juiceController.dispose();
    super.dispose();
  }

  void _initTurnClockListener() {
    turnTimerSubscription = mp.onTurnSecondsRemaining.listen((sec) {
      if (!mounted) return;
      setState(() {
        turnSecondsLeft = sec;
      });
    });
  }

  void _startTurnTimer() {
    mp.startTurnCountdown(
      activePlayerId: players[currentTurnIndex].id,
      onTimeoutBotTakeover: () {
        if (!mounted || isMoving) return;
        _addLog("⏱️ Turn Timed Out! Auto-Pilot executed roll.");
        _rollAndMove();
      },
    );
  }

  void _restoreSnapshotIfPresent() {
    final snap = ps.activeSnapshot;
    if (snap != null) {
      currentTurnIndex = snap.currentTurnIndex;
      diceMultiplier = snap.diceMultiplier;
      suddenDeathTriggered = snap.suddenDeathTriggered;

      for (final pState in snap.playersState) {
        final p = players.firstWhere((pl) => pl.id == pState['id']);
        p.cash = pState['cash'];
        p.tileIndex = pState['tileIndex'];
        p.lapsCompleted = pState['laps'];
        p.isBankrupt = pState['bankrupt'];
        p.hasRentShield = pState['shield'];
        p.stockShares = pState['shares'];
      }

      for (final tState in snap.tilesState) {
        final t = tiles.firstWhere((tl) => tl.id == tState['id']);
        t.ownerId = tState['owner'];
        t.upgradeLevel = tState['lvl'];
        t.frozenTurns = tState['frozen'];
      }

      hotStock.price = snap.stockPrice;
      eventLogs.addAll(snap.eventLogs);
      _addLog("🔄 Match Restored from Auto-Save Snapshot!");
    }
  }

  void _initStockMarket() {
    hotStock = StockModel(
      symbol: "ZOMT",
      companyName: "HyperDelivery",
      sector: "Quick Commerce",
      price: 130,
      previousPrice: 128,
    );

    // Ornstein-Uhlenbeck stochastic SDE simulation ticking every 5 seconds
    stockTickTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      setState(() {
        int previousPrice = hotStock.price;
        int newPrice = hotStock.tick();

        // Autonomous AI Off-Turn Stock Trading
        for (final bot in players.where((p) => p.isAI && !p.isBankrupt)) {
          int action = aiEngine.evaluateStockAction(
            ai: bot,
            currentStockPrice: newPrice,
            previousPrice: previousPrice,
            config: botConfig,
          );
          if (action == 1 && bot.cash >= hotStock.askPrice * 1000) {
            bot.cash -= hotStock.askPrice * 1000;
            bot.stockShares += 1000;
            _addLog("📈 ${bot.name} bought 1k ${hotStock.symbol} at ₹${hotStock.askPrice}/sh!");
          } else if (action == -1 && bot.stockShares >= 1000) {
            bot.stockShares -= 1000;
            bot.cash += hotStock.bidPrice * 1000;
            _addLog("📉 ${bot.name} liquidated 1k ${hotStock.symbol} at ₹${hotStock.bidPrice}/sh!");
          }
        }
      });
    });
  }

  void _initBoard() {
    tiles = [
      TileModel(id: 0, name: "PAYDAY START", city: "Govt", type: TileType.start),
      TileModel(id: 1, name: "Indiranagar 100ft", city: "Bengaluru", type: TileType.property, cost: 200000, rentStages: [20000, 60000, 160000, 400000], groupColor: GameConstants.bengaluruColor),
      TileModel(id: 2, name: "Koramangala 4th", city: "Bengaluru", type: TileType.property, cost: 240000, rentStages: [24000, 72000, 192000, 480000], groupColor: GameConstants.bengaluruColor),
      TileModel(id: 3, name: "Market Surge", city: "Stock", type: TileType.marketSurge),
      TileModel(id: 4, name: "HSR Layout Sec 1", city: "Bengaluru", type: TileType.property, cost: 280000, rentStages: [28000, 84000, 224000, 560000], groupColor: GameConstants.bengaluruColor),
      TileModel(id: 5, name: "Whitefield IT", city: "Bengaluru", type: TileType.property, cost: 320000, rentStages: [32000, 96000, 256000, 640000], groupColor: GameConstants.bengaluruColor),
      TileModel(id: 6, name: "Electronic City", city: "Bengaluru", type: TileType.property, cost: 350000, rentStages: [35000, 105000, 280000, 700000], groupColor: GameConstants.bengaluruColor),
      TileModel(id: 7, name: "ANGEL INCUBATOR", city: "Hub", type: TileType.angelLab),
      TileModel(id: 8, name: "HITEC City Phase 1", city: "Hyderabad", type: TileType.property, cost: 400000, rentStages: [40000, 120000, 320000, 800000], groupColor: GameConstants.hyderabadColor),
      TileModel(id: 9, name: "Gachibowli Circle", city: "Hyderabad", type: TileType.property, cost: 440000, rentStages: [44000, 132000, 352000, 880000], groupColor: GameConstants.hyderabadColor),
      TileModel(id: 10, name: "Corporate Heist", city: "Sabotage", type: TileType.corporateHeist),
      TileModel(id: 11, name: "Jubilee Hills 36", city: "Hyderabad", type: TileType.property, cost: 500000, rentStages: [50000, 150000, 400000, 1000000], groupColor: GameConstants.hyderabadColor),
      TileModel(id: 12, name: "Cyber Hub DLF", city: "Gurgaon", type: TileType.property, cost: 550000, rentStages: [55000, 165000, 440000, 1100000], groupColor: GameConstants.gurgaonColor),
      TileModel(id: 13, name: "Golf Course Road", city: "Gurgaon", type: TileType.property, cost: 600000, rentStages: [60000, 180000, 480000, 1200000], groupColor: GameConstants.gurgaonColor),
      TileModel(id: 14, name: "CORPORATE HEIST", city: "Espionage", type: TileType.corporateHeist),
      TileModel(id: 15, name: "Koregaon Park", city: "Pune", type: TileType.property, cost: 650000, rentStages: [65000, 195000, 520000, 1300000], groupColor: GameConstants.puneColor),
      TileModel(id: 16, name: "Hinjawadi Tech Park", city: "Pune", type: TileType.property, cost: 700000, rentStages: [70000, 210000, 560000, 1400000], groupColor: GameConstants.puneColor),
      TileModel(id: 17, name: "Market Surge", city: "Stock", type: TileType.marketSurge),
      TileModel(id: 18, name: "Bandra Kurla Complex", city: "Mumbai", type: TileType.property, cost: 850000, rentStages: [85000, 255000, 680000, 1700000], groupColor: GameConstants.mumbaiColor),
      TileModel(id: 19, name: "Worli Sea Face", city: "Mumbai", type: TileType.property, cost: 950000, rentStages: [95000, 285000, 760000, 1900000], groupColor: GameConstants.mumbaiColor),
      TileModel(id: 20, name: "Nariman Point Sky", city: "Mumbai", type: TileType.property, cost: 1100000, rentStages: [110000, 330000, 880000, 2200000], groupColor: GameConstants.mumbaiColor),
      TileModel(id: 21, name: "TAX AUDIT LAB", city: "Govt", type: TileType.taxAudit),
      TileModel(id: 22, name: "Aerocity Gateway", city: "Delhi", type: TileType.property, cost: 1200000, rentStages: [120000, 360000, 960000, 2400000], groupColor: GameConstants.delhiColor),
      TileModel(id: 23, name: "Connaught Place", city: "Delhi", type: TileType.property, cost: 1300000, rentStages: [130000, 390000, 1040000, 2600000], groupColor: GameConstants.delhiColor),
      TileModel(id: 24, name: "Corporate Heist", city: "Sabotage", type: TileType.corporateHeist),
      TileModel(id: 25, name: "Marine Drive Towers", city: "Mumbai", type: TileType.property, cost: 1450000, rentStages: [145000, 435000, 1160000, 2900000], groupColor: GameConstants.mumbaiColor),
      TileModel(id: 26, name: "Malabar Hill Apex", city: "Mumbai", type: TileType.property, cost: 1600000, rentStages: [160000, 480000, 1280000, 3200000], groupColor: GameConstants.mumbaiColor),
      TileModel(id: 27, name: "Antilia Heights", city: "Mumbai", type: TileType.property, cost: 2000000, rentStages: [200000, 600000, 1600000, 4000000], groupColor: GameConstants.mumbaiColor),
    ];
  }

  void _initPlayers() {
    final roster = CeoModel.defaultRoster;
    players = [
      PlayerModel(id: 0, name: "You (Shark)", color: AppTheme.neonCyan, isAI: false, ceo: roster[0]),
      PlayerModel(id: 1, name: "Vikram (Mogul)", color: AppTheme.gold, isAI: true, ceo: roster[1]),
      PlayerModel(id: 2, name: "Ananya (Lobbyist)", color: AppTheme.purpleAccent, isAI: true, ceo: roster[2]),
    ];
  }

  void _initTokenStates() {
    int leaderId = _getNetWorthLeaderId();
    final initialList = players.map((p) {
      Offset normalizedPos = _calculateNormalizedCoord(p.tileIndex, p.id);
      return TokenHopState(
        playerId: p.id,
        playerColor: p.color,
        playerInitial: p.name[0],
        avatarEmoji: p.ceo.avatarEmoji,
        avatarAssetPath: p.ceo.avatarAssetPath,
        isLeader: p.id == leaderId,
        isCurrentTurn: p.id == players[currentTurnIndex].id,
        initialNormalizedPos: normalizedPos,
      );
    }).toList();

    tokenStatesNotifier = ValueNotifier<List<TokenHopState>>(initialList);
  }

  int _getNetWorthLeaderId() {
    int maxNW = -1;
    int leaderId = 0;
    for (final p in players) {
      if (p.isBankrupt) continue;
      int nw = p.calculateNetWorth(tiles, hotStock.price);
      if (nw > maxNW) {
        maxNW = nw;
        leaderId = p.id;
      }
    }
    return leaderId;
  }

  void _updateTokenTurnAndLeader() {
    if (!mounted) return;
    int leaderId = _getNetWorthLeaderId();
    for (final t in tokenStatesNotifier.value) {
      t.isLeader = (t.playerId == leaderId);
      t.isCurrentTurn = (t.playerId == players[currentTurnIndex].id);
    }
    tokenStatesNotifier.value = List.of(tokenStatesNotifier.value);
  }

  Offset _calculateNormalizedCoord(int tileIndex, int playerId) {
    Offset grid = _getGridCoord(tileIndex);
    double cellWidthNorm = 1.0 / 8.0;
    double offsetNormX = ((playerId % 2) * 8.0 - 4.0) / 360.0;
    double offsetNormY = ((playerId ~/ 2) * 8.0 - 4.0) / 360.0;

    return Offset(
      (grid.dx * cellWidthNorm) + (cellWidthNorm / 2) + offsetNormX,
      (grid.dy * cellWidthNorm) + (cellWidthNorm / 2) + offsetNormY,
    );
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

  int _calculatePaydaySalary(int lap) {
    const int base = GameConstants.basePaydaySalary;
    if (lap <= 4) {
      return (base * (1.0 + 0.12 * (lap - 1))).round();
    } else if (lap <= 9) {
      return (base * (1.36 + 0.08 * (lap - 4))).round();
    } else {
      double decay = pow(0.5, lap - 9).toDouble();
      return max(50000, (base * 1.5 * decay).round());
    }
  }

  double _calculateSuddenDeathMultiplier(int maxLap) {
    if (maxLap < GameConstants.suddenDeathLapThreshold) {
      return 1.0;
    }
    return pow(2.0, maxLap - 9).toDouble();
  }

  void _addLog(String msg) {
    setState(() {
      eventLogs.insert(0, msg);
      if (eventLogs.length > 25) eventLogs.removeLast();
    });
  }

  // ==========================================
  // GAMEPLAY ENGINE & STEPPING
  // ==========================================

  Future<void> _rollAndMove() async {
    if (isMoving) return;
    final currentPlayer = players[currentTurnIndex];
    if (currentPlayer.isBankrupt) {
      _nextTurn();
      return;
    }

    setState(() {
      isMoving = true;
    });

    FeedbackService.diceRoll();
    AudioService.instance.playSfx(GameSfx.diceRoll);

    // Cryptographic Deterministic Roll (Anti-Cheat PRNG)
    int roll1 = mp.generateDeterministicDiceRoll(
      turnIndex: currentPlayer.lapsCompleted * 8 + currentPlayer.tileIndex,
      playerId: currentPlayer.id,
    );
    int roll2 = mp.generateDeterministicDiceRoll(
      turnIndex: currentPlayer.lapsCompleted * 8 + currentPlayer.tileIndex + 777,
      playerId: currentPlayer.id,
    );
    int roll = roll1 + roll2;

    setState(() {
      die1 = roll1;
      die2 = roll2;
      lastDiceRoll = roll;
    });

    _addLog("🎲 ${currentPlayer.name} rolled $roll ($roll1 + $roll2) at ${diceMultiplier}x stakes!");

    // Smooth Decoupled 120 FPS parabolic hopping (zero root setState rebuilds!)
    for (int i = 0; i < roll; i++) {
      await Future.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      FeedbackService.tokenHop();
      AudioService.instance.playSfx(GameSfx.tokenHop);

      currentPlayer.tileIndex = (currentPlayer.tileIndex + 1) % tiles.length;
      Offset nextNormPos = _calculateNormalizedCoord(currentPlayer.tileIndex, currentPlayer.id);

      tokenStatesNotifier.value[currentPlayer.id].hopTo(nextNormPos);
      tokenStatesNotifier.value = List.of(tokenStatesNotifier.value);

      if (currentPlayer.tileIndex == 0) {
        currentPlayer.lapsCompleted++;
        int salary = _calculatePaydaySalary(currentPlayer.lapsCompleted) * diceMultiplier;

        if (currentPlayer.ceo.id == CeoId.fintechShark) {
          int interest = (currentPlayer.cash * 0.05).round();
          salary += interest;
          _addLog("💰 Shark Passive: ₹${_formatCompact(interest)} interest collected!");
        }
        currentPlayer.cash += salary;
        _addLog("🏁 ${currentPlayer.name} completed Lap ${currentPlayer.lapsCompleted}! +₹${_formatCompact(salary)} Payday!");

        if (currentPlayer.lapsCompleted >= GameConstants.suddenDeathLapThreshold && !suddenDeathTriggered) {
          suddenDeathTriggered = true;
          juiceController.addTrauma(0.65);
          FeedbackService.rentImpact();
          _addLog("🔥 SUDDEN DEATH! Exponential rent inflation activated!");
        }
      }
    }

    if (currentPlayer.ceo.currentCooldown > 0) {
      currentPlayer.ceo.currentCooldown--;
    }

    await _handleLanding(currentPlayer);

    if (!mounted) return;
    setState(() {
      isMoving = false;
    });

    // Auto-Save Snapshot at End of Every Turn (Epic 5 Persistence)
    ps.autoSaveTurnSnapshot(
      currentTurnIndex: currentTurnIndex,
      diceMultiplier: diceMultiplier,
      suddenDeathTriggered: suddenDeathTriggered,
      players: players,
      tiles: tiles,
      stock: hotStock,
      eventLogs: eventLogs,
    );

    _nextTurn();
  }

  Future<void> _handleLanding(PlayerModel player) async {
    final tile = tiles[player.tileIndex];
    _addLog("📍 ${player.name} landed on ${tile.name}");

    switch (tile.type) {
      case TileType.property:
        await _handlePropertyLanding(player, tile);
        break;
      case TileType.corporateHeist:
        await _handleCorporateHeist(player);
        break;
      case TileType.taxAudit:
        _handleTaxAudit(player);
        break;
      case TileType.marketSurge:
        _handleMarketSurge(player);
        break;
      case TileType.start:
      case TileType.angelLab:
        break;
    }
  }

  Future<void> _handlePropertyLanding(PlayerModel player, TileModel tile) async {
    if (tile.ownerId == -1) {
      if (player.isAI) {
        final rivals = players.where((p) => p.id != player.id).toList();
        if (aiEngine.shouldBuyProperty(ai: player, tile: tile, allTiles: tiles, rivals: rivals, config: botConfig)) {
          player.cash -= tile.cost;
          tile.ownerId = player.id;
          FeedbackService.propertyAcquired();
          AudioService.instance.playSfx(GameSfx.cashChime);
          _addLog("🏢 ${player.name} acquired ${tile.name} for ₹${_formatCompact(tile.cost)}!");
        } else {
          _addLog("🛑 ${player.name} passed on ${tile.name}. Fast Auction triggered!");
          await _triggerFastAuction(tile);
        }
      } else {
        await _showBuyOrAuctionDialog(player, tile);
      }
    } else if (tile.ownerId == player.id) {
      if (!tile.isMaxUpgraded) {
        if (player.isAI) {
          final rivals = players.where((p) => p.id != player.id).toList();
          final toUpgrade = aiEngine.choosePropertyToUpgrade(ai: player, allTiles: tiles, rivals: rivals, config: botConfig);
          if (toUpgrade != null && toUpgrade.id == tile.id) {
            int cost = tile.upgradeCost;
            if (player.ceo.id == CeoId.realEstateMogul) cost = (cost * 0.8).round();
            player.cash -= cost;
            tile.upgradeLevel++;
            FeedbackService.propertyAcquired();
            _addLog("🏗️ ${player.name} upgraded ${tile.name} to Lvl ${tile.upgradeLevel}!");
          }
        } else {
          await _showUpgradeDialog(player, tile);
        }
      }
    } else {
      final owner = players[tile.ownerId];
      if (owner.isBankrupt) {
        _addLog("🏛️ Property in liquidation. Rent waived.");
        return;
      }

      if (tile.frozenTurns > 0) {
        tile.frozenTurns--;
        _addLog("❄️ Rent frozen under Corporate Audit for ${player.name}.");
        return;
      }

      if (player.hasRentShield) {
        player.hasRentShield = false;
        AudioService.instance.playSfx(GameSfx.shieldActivate);
        _addLog("🛡️ Rent Shield Saved ${player.name}! Paid ₹0 to ${owner.name}.");
        return;
      }

      int maxLap = players.map((p) => p.lapsCompleted).reduce(max);
      double sdMultiplier = _calculateSuddenDeathMultiplier(maxLap);
      int baseRent = tile.currentRent;
      int totalRent = (baseRent * diceMultiplier * sdMultiplier).round();

      if (totalRent > 300000) {
        juiceController.addTrauma(0.55);
        FeedbackService.rentImpact();
        AudioService.instance.playSfx(GameSfx.rentHit);
        juiceController.spawnCashFountain(
          from: const Offset(180, 200),
          to: Offset(owner.id * 100.0 + 60, 20),
          count: 22,
        );
      }

      if (player.cash >= totalRent) {
        player.cash -= totalRent;
        owner.cash += totalRent;
        _addLog("💸 ${player.name} paid ₹${_formatCompact(totalRent)} rent to ${owner.name}!");
      } else {
        // Complete Bankruptcy Liquidation
        int rem = player.cash;
        player.cash = 0;
        owner.cash += rem;
        player.isBankrupt = true;
        player.stockShares = 0;

        for (final t in tiles) {
          if (t.ownerId == player.id) {
            t.ownerId = owner.id;
          }
        }

        juiceController.addTrauma(0.95);
        FeedbackService.bankruptcyShudder();
        AudioService.instance.playSfx(GameSfx.bankruptcyBuzzer);
        _addLog("💥 BANKRUPTCY! ${player.name} eliminated! All properties transferred to ${owner.name}!");
      }
    }
  }

  Future<void> _handleCorporateHeist(PlayerModel player) async {
    juiceController.addTrauma(0.35);

    PlayerModel? richestOpponent;
    int maxCash = -1;
    for (final p in players) {
      if (p.id != player.id && !p.isBankrupt && p.cash > maxCash) {
        maxCash = p.cash;
        richestOpponent = p;
      }
    }

    if (richestOpponent == null) return;

    if (player.lapsCompleted <= 1 || richestOpponent.lapsCompleted <= 1) {
      int grant = 100000 * min(2, diceMultiplier);
      player.cash += grant;
      FeedbackService.cashReceived();
      _addLog("🛡️ Lap 1 Grace: Syndicate grant +₹${_formatCompact(grant)} awarded (₹0 stolen).");
      return;
    }

    int protectedFloor = max(250000, (richestOpponent.cash * 0.25).round());
    int vulnerableCash = max(0, richestOpponent.cash - protectedFloor);

    if (vulnerableCash <= 20000) {
      _addLog("💼 Heist Warning: ${richestOpponent.name}'s vault is below the non-strippable liquidity floor.");
      return;
    }

    double heistMultiplier = 1.0 + 0.40 * (diceMultiplier - 1);

    if (!player.isAI) {
      int? pickedIndex = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => HeistModal(target: richestOpponent!),
      );

      pickedIndex ??= 0;

      if (pickedIndex == 0) {
        if (random.nextDouble() < 0.90) {
          int loot = (vulnerableCash * 0.12 * heistMultiplier).round();
          richestOpponent.cash -= loot;
          player.cash += loot;
          juiceController.addTrauma(0.40);
          FeedbackService.sabotageTriggered();
          AudioService.instance.playSfx(GameSfx.cashChime);
          _addLog("🕵️ Phishing Success! Siphoned ₹${_formatCompact(loot)} from ${richestOpponent.name}!");
        } else {
          int fine = 40000;
          player.cash = max(0, player.cash - fine);
          _addLog("🚨 Phishing Failed! Attacker paid ₹${_formatCompact(fine)} PR penalty.");
        }
      } else if (pickedIndex == 1) {
        if (random.nextDouble() < 0.65) {
          int loot = (vulnerableCash * 0.28 * heistMultiplier).round();
          richestOpponent.cash -= loot;
          player.cash += loot;
          juiceController.addTrauma(0.50);
          FeedbackService.sabotageTriggered();
          AudioService.instance.playSfx(GameSfx.cashChime);
          _addLog("🕵️ Quantum Decrypt Success! Extracted ₹${_formatCompact(loot)} from ${richestOpponent.name}!");
        } else {
          int penalty = 100000;
          player.cash = max(0, player.cash - penalty);
          richestOpponent.cash += penalty;
          _addLog("🚨 Decryption Failed! Paid ₹${_formatCompact(penalty)} damages to ${richestOpponent.name}.");
        }
      } else {
        if (random.nextDouble() < 0.40) {
          int loot = (vulnerableCash * 0.50 * heistMultiplier).round();
          richestOpponent.cash -= loot;
          player.cash += loot;
          juiceController.addTrauma(0.70);
          FeedbackService.sabotageTriggered();
          AudioService.instance.playSfx(GameSfx.cashChime);
          _addLog("💣 BLACK-HAT JACKPOT! Extracted ₹${_formatCompact(loot)} from ${richestOpponent.name}!");
        } else {
          int counterHack = (player.cash * 0.25).round();
          player.cash -= counterHack;
          richestOpponent.cash += counterHack;
          juiceController.addTrauma(0.80);
          FeedbackService.rentImpact();
          _addLog("💥 COUNTER-HACKED! ${richestOpponent.name} detected you and counter-stole ₹${_formatCompact(counterHack)}!");
        }
      }
    } else {
      int loot = (vulnerableCash * 0.20 * heistMultiplier).round();
      richestOpponent.cash -= loot;
      player.cash += loot;
      _addLog("🕵️ ${player.name} infiltrated ${richestOpponent.name} for ₹${_formatCompact(loot)}!");
    }
  }

  void _handleTaxAudit(PlayerModel player) {
    int tax = 120000 * diceMultiplier;

    PlayerModel? lobbyist;
    for (final p in players) {
      if (p.ceo.id == CeoId.lobbyist && !p.isBankrupt) {
        lobbyist = p;
        break;
      }
    }

    if (player.ceo.id == CeoId.lobbyist) {
      _addLog("👑 Lobbyist Immunity: Ananya pays ₹0 tax.");
      return;
    }

    player.cash = max(0, player.cash - tax);
    if (lobbyist != null && lobbyist.id != player.id) {
      int kickback = (tax * 0.5).round();
      lobbyist.cash += kickback;
      _addLog("💼 Lobbyist Kickback: Ananya took ₹${_formatCompact(kickback)} of the tax penalty.");
    }
  }

  void _handleMarketSurge(PlayerModel player) {
    int dividend = (hotStock.price * 1200 * diceMultiplier);
    player.cash += dividend;
    FeedbackService.cashReceived();
    AudioService.instance.playSfx(GameSfx.cashChime);
    _addLog("📈 Market Surge: ${player.name} collected ₹${_formatCompact(dividend)} tech dividend!");
  }

  Future<void> _triggerFastAuction(TileModel tile) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AuctionDialog(
        tile: tile,
        players: players,
        allTiles: tiles,
        botConfig: botConfig,
        onAuctionCompleted: (winner, bid) {
          winner.cash -= bid;
          tile.ownerId = winner.id;
          FeedbackService.propertyAcquired();
          AudioService.instance.playSfx(GameSfx.cashChime);
          _addLog("🏆 ${winner.name} won ${tile.name} at auction for ₹${_formatCompact(bid)}!");
        },
      ),
    );
  }

  void _executeAiTurn() async {
    await Future.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;

    final ai = players[currentTurnIndex];
    final rivals = players.where((p) => p.id != ai.id).toList();

    if (ai.ceo.currentCooldown == 0 && aiEngine.shouldActivateSkill(ai: ai, allTiles: tiles, rivals: rivals, config: botConfig)) {
      if (ai.ceo.id == CeoId.realEstateMogul) {
        final toUp = aiEngine.choosePropertyToUpgrade(ai: ai, allTiles: tiles, rivals: rivals, config: botConfig);
        if (toUp != null) {
          toUp.upgradeLevel++;
          ai.ceo.currentCooldown = ai.ceo.maxCooldown;
          _addLog("⚡ Mogul Skill: Vikram auto-upgraded ${toUp.name} to Lvl ${toUp.upgradeLevel}!");
        }
      } else if (ai.ceo.id == CeoId.lobbyist) {
        var humanTiles = tiles.where((t) => t.ownerId == 0 && t.upgradeLevel > 0).toList();
        if (humanTiles.isNotEmpty) {
          humanTiles.sort((a, b) => b.currentRent.compareTo(a.currentRent));
          humanTiles.first.frozenTurns = 2;
          ai.ceo.currentCooldown = ai.ceo.maxCooldown;
          juiceController.addTrauma(0.40);
          FeedbackService.sabotageTriggered();
          _addLog("⚡ Lobbyist Skill: Ananya placed a Tax Audit on ${humanTiles.first.name}!");
        }
      }
    }

    await _rollAndMove();
  }

  void _nextTurn() {
    int active = players.where((p) => !p.isBankrupt).length;
    if (active <= 1) {
      final winner = players.firstWhere((p) => !p.isBankrupt);
      _showVictoryDialog(winner);
      return;
    }

    setState(() {
      do {
        currentTurnIndex = (currentTurnIndex + 1) % players.length;
      } while (players[currentTurnIndex].isBankrupt);
    });

    _updateTokenTurnAndLeader();

    _startTurnTimer();

    if (players[currentTurnIndex].isAI) {
      _executeAiTurn();
    }
  }

  // ==========================================
  // HUMAN DIALOGS & OFF-TURN ACTIONS
  // ==========================================

  Future<void> _showBuyOrAuctionDialog(PlayerModel player, TileModel tile) async {
    bool? bought = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: tile.groupColor, radius: 8),
                const SizedBox(width: 8),
                Text(tile.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 6),
            Text("Base Rent: ₹${_formatCompact(tile.rentStages[0])} | City: ${tile.city}", style: const TextStyle(color: Colors.white60)),
            const Divider(color: Colors.white12, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Purchase Price:", style: TextStyle(color: Colors.white70)),
                Text("₹${_formatCompact(tile.cost)}", style: const TextStyle(fontSize: 18, color: AppTheme.gold, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("PASS TO AUCTION"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: player.cash >= tile.cost ? () => Navigator.pop(ctx, true) : null,
                    child: const Text("BUY INSTANTLY"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (bought == true) {
      setState(() {
        player.cash -= tile.cost;
        tile.ownerId = player.id;
      });
      FeedbackService.propertyAcquired();
      AudioService.instance.playSfx(GameSfx.cashChime);
      _addLog("🎉 You acquired ${tile.name} for ₹${_formatCompact(tile.cost)}!");
    } else {
      _addLog("🏛️ Property passed. Starting fast public auction!");
      await _triggerFastAuction(tile);
    }
  }

  Future<void> _showUpgradeDialog(PlayerModel player, TileModel tile) async {
    int cost = tile.upgradeCost;
    if (player.cash < cost) return;

    bool? upgrade = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Upgrade ${tile.name}?", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "Level ${tile.upgradeLevel} ➔ Level ${tile.upgradeLevel + 1} (Rent jumps to ₹${_formatCompact(tile.rentStages[tile.upgradeLevel + 1])})",
              style: const TextStyle(color: AppTheme.neonCyan),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text("UPGRADE FOR ₹${_formatCompact(cost)}"),
            ),
          ],
        ),
      ),
    );

    if (upgrade == true) {
      setState(() {
        player.cash -= cost;
        tile.upgradeLevel++;
      });
      FeedbackService.propertyAcquired();
      AudioService.instance.playSfx(GameSfx.cashChime);
      _addLog("🚀 Upgraded ${tile.name} to Level ${tile.upgradeLevel}!");
    }
  }

  void _triggerHumanSkill() {
    final human = players[0];
    if (human.isBankrupt || human.ceo.currentCooldown > 0) return;
    setState(() {
      human.hasRentShield = true;
      human.ceo.currentCooldown = human.ceo.maxCooldown;
    });
    FeedbackService.sabotageTriggered();
    AudioService.instance.playSfx(GameSfx.shieldActivate);
    _addLog("🛡️ SHIELD PROTOCOL ACTIVATED! Next rent payment waived!");
  }

  void _openTradeSheet() {
    final human = players[0];
    if (human.isBankrupt) return;
    final opponents = players.where((p) => p.isAI && !p.isBankrupt).toList();
    if (opponents.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => TradeBottomSheet(
        humanPlayer: human,
        opponents: opponents,
        tiles: tiles,
        onTradeSubmitted: (opp, property, cash) {
          int totalValuation = property.cost + (property.upgradeLevel * property.upgradeCost);
          if (cash >= totalValuation * 1.25) {
            setState(() {
              human.cash -= cash;
              opp.cash += cash;
              property.ownerId = human.id;
            });
            FeedbackService.propertyAcquired();
            _addLog("🤝 DEAL ACCEPTED! ${opp.name} sold ${property.name} to you for ₹${_formatCompact(cash)}!");
          } else {
            _addLog("❌ DEAL REJECTED! ${opp.name} demands higher premium for ${property.name}.");
          }
        },
      ),
    );
  }

  void _buyStock() {
    final human = players[0];
    if (human.isBankrupt) return;

    int askCost = hotStock.askPrice * 1000;
    if (human.cash >= askCost) {
      setState(() {
        human.cash -= askCost;
        human.stockShares += 1000;
      });
      AudioService.instance.playSfx(GameSfx.cashChime);
      _addLog("📈 Bought 1k ${hotStock.symbol} at Ask Price ₹${hotStock.askPrice}/sh!");
    } else {
      _addLog("❌ Insufficient funds to buy 1k shares (Needs ₹${_formatCompact(askCost)}).");
    }
  }

  void _sellStock() {
    final human = players[0];
    if (human.isBankrupt) return;

    if (human.stockShares >= 1000) {
      int bidRevenue = hotStock.bidPrice * 1000;
      setState(() {
        human.stockShares -= 1000;
        human.cash += bidRevenue;
      });
      AudioService.instance.playSfx(GameSfx.cashChime);
      _addLog("📉 Liquidated 1k ${hotStock.symbol} at Bid Price ₹${hotStock.bidPrice}/sh (₹${_formatCompact(bidRevenue)})!");
    } else {
      _addLog("❌ No shares available to liquidate.");
    }
  }

  void _showVictoryDialog(PlayerModel winner) {
    mp.stopTurnCountdown();
    juiceController.spawnVictoryConfetti(screenSize: const Size(400, 800));
    FeedbackService.victoryFanfare();
    AudioService.instance.playSfx(GameSfx.victoryFanfare);

    int finalNetWorth = winner.calculateNetWorth(tiles, hotStock.price);
    int lapsPlayed = players.map((p) => p.lapsCompleted).reduce(max);
    bool isVictory = winner.id == 0;

    // Record match to persistent storage and advance monotonic vector clock
    ps.recordMatchCompleted(
      isVictory: isVictory,
      winnerName: winner.name,
      finalNetWorth: finalNetWorth,
      lapsPlayed: lapsPlayed,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("🏆 UNICORN CHAMPION!", style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${winner.name} achieved total market monopoly!"),
            const SizedBox(height: 10),
            Text("Final Net Worth: ₹${_formatCompact(finalNetWorth)}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonCyan)),
            Text(isVictory ? "+15 Net Worth Stars • +5 Blueprints Awarded" : "+4 Stars for participation", style: const TextStyle(color: AppTheme.gold, fontSize: 12)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("RETURN TO EMPIRE"),
          )
        ],
      ),
    );
  }

  String _formatCompact(int val) {
    if (val >= 10000000) return "${(val / 10000000).toStringAsFixed(2)} Cr";
    if (val >= 100000) return "${(val / 100000).toStringAsFixed(1)}L";
    if (val >= 1000) return "${(val / 1000).toStringAsFixed(0)}k";
    return val.toString();
  }

  // ==========================================
  // UI BUILD & RESPONSIVE LAYOUT
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final human = players[0];
    final active = players[currentTurnIndex];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.flash_on, color: AppTheme.gold),
            const SizedBox(width: 6),
            const Text("BLITZ BOARD", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const Spacer(),
            if (suddenDeathTriggered)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withAlpha(50),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.dangerRed),
                ),
                child: const Text("🔥 EXPONENTIAL SUDDEN DEATH", style: TextStyle(color: AppTheme.dangerRed, fontSize: 9.5, fontWeight: FontWeight.bold)),
              ),
            IconButton(
              icon: const Icon(Icons.handshake, color: AppTheme.gold),
              onPressed: _openTradeSheet,
              tooltip: "Trade Buyout",
            ),
          ],
        ),
      ),
      body: JuiceOverlay(
        controller: juiceController,
        child: Column(
          children: [
            // Top Status Bar
            _buildPlayerHeader(),

            // Interactive 8x8 Board Canvas with Parabolic Token Hopper & Zoom Viewport
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: BoardCanvas(
                  tiles: tiles,
                  players: players,
                  tokenStatesNotifier: tokenStatesNotifier,
                  transformationController: boardTransformController,
                  centerDashboard: CenterStockTickerWidget(
                    stock: hotStock,
                    humanPlayer: human,
                    onBuy: _buyStock,
                    onSell: _sellStock,
                    logs: eventLogs,
                    onCenterRoll: _rollAndMove,
                    isRolling: isMoving,
                    isHumanTurn: currentTurnIndex == 0 && !isMoving,
                    die1: die1,
                    die2: die2,
                    multiplier: diceMultiplier,
                  ),
                ),
              ),
            ),

            // Bottom Console: Multiplier, Skills, 15s Blitz Timer and Roll Button
            _buildBottomControls(human, active),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerHeader() {
    int leaderId = _getNetWorthLeaderId();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF101726),
        border: Border(bottom: BorderSide(color: Color(0xFF222F46), width: 1.0)),
      ),
      child: Row(
        children: players.map((p) {
          bool isCurrent = p.id == players[currentTurnIndex].id;
          bool isLeader = p.id == leaderId;
          int propCount = tiles.where((t) => t.ownerId == p.id).length;

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isCurrent
                      ? [p.color.withAlpha(50), const Color(0xFF182236)]
                      : [const Color(0xFF131A29), const Color(0xFF0F1522)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent
                      ? AppTheme.gold
                      : (isLeader ? Colors.amber.withAlpha(120) : const Color(0xFF24324A)),
                  width: isCurrent ? 2.0 : 1.0,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: p.color.withAlpha(80),
                          blurRadius: 8,
                          spreadRadius: 0.5,
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  // 3D Avatar Medallion with Leader Crown
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.color.withAlpha(45),
                          border: Border.all(
                            color: isCurrent ? AppTheme.gold : p.color,
                            width: 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child: p.ceo.avatarAssetPath.isNotEmpty
                              ? Image.asset(
                                  p.ceo.avatarAssetPath,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Center(
                                    child: Text(
                                      p.ceo.avatarEmoji,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    p.ceo.avatarEmoji,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                        ),
                      ),
                      if (isLeader)
                        Positioned(
                          top: -7,
                          right: -3,
                          child: const Text("👑", style: TextStyle(fontSize: 10)),
                        ),
                    ],
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                            color: isCurrent ? Colors.white : Colors.white70,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.isBankrupt ? "BANKRUPT" : "₹${_formatCompact(p.cash)}",
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: p.isBankrupt ? AppTheme.dangerRed : AppTheme.gold,
                                ),
                              ),
                              if (propCount > 0) ...[
                                const SizedBox(width: 3),
                                Text(
                                  "🏠$propCount",
                                  style: const TextStyle(fontSize: 8.0, color: Colors.white54),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomControls(PlayerModel human, PlayerModel active) {
    bool isHumanTurn = active.id == human.id && !isMoving;
    double timerFraction = (turnSecondsLeft / 15.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      color: AppTheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 15-Second Blitz Turn Countdown Bar
          Row(
            children: [
              Icon(Icons.timer_rounded, size: 14, color: turnSecondsLeft <= 4 ? AppTheme.dangerRed : AppTheme.neonCyan),
              const SizedBox(width: 6),
              Text(
                "${turnSecondsLeft}s BLITZ TURN",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: turnSecondsLeft <= 4 ? AppTheme.dangerRed : AppTheme.neonCyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: timerFraction,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(
                      turnSecondsLeft <= 4 ? AppTheme.dangerRed : AppTheme.neonCyan,
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("STAKES: ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white60)),
                ...multiplierOptions.map((m) {
                  bool sel = diceMultiplier == m;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () {
                        setState(() => diceMultiplier = m);
                        FeedbackService.buttonTap();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: sel
                                ? [Colors.amber.shade300, AppTheme.gold, const Color(0xFF7A5800)]
                                : [const Color(0xFF263248), const Color(0xFF172030)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel ? Colors.amberAccent : Colors.white24,
                            width: sel ? 1.5 : 1.0,
                          ),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                    color: AppTheme.gold.withAlpha(120),
                                    blurRadius: 5,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          "${m}X",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: sel ? Colors.black : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: human.hasRentShield
                        ? Colors.teal
                        : (human.ceo.currentCooldown == 0 ? AppTheme.neonCyan : Colors.grey.shade800),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: (human.ceo.currentCooldown == 0 && !human.hasRentShield) ? _triggerHumanSkill : null,
                  icon: Icon(human.ceo.icon, size: 14),
                  label: Text(
                    human.hasRentShield
                        ? "SHIELD ON"
                        : (human.ceo.currentCooldown == 0 ? "SHIELD" : "CD: ${human.ceo.currentCooldown}"),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3D Physical Dice Roller with Tumble Animation & Tactile Roll Action
          DiceRoller3D(
            isEnabled: isHumanTurn,
            isRolling: isMoving,
            multiplier: diceMultiplier,
            currentDie1: die1,
            currentDie2: die2,
            onRoll: _rollAndMove,
          ),
        ],
      ),
    );
  }
}

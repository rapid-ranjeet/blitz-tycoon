import '../models/player_model.dart';
import '../models/tile_model.dart';
import '../models/stock_model.dart';

class PlayerProfileEntity {
  String username;
  int netWorthStars;
  int blueprints;
  int currentLeagueIndex;
  int selectedCeoId;
  List<int> unlockedCeoIds;
  int garageLabLevel;
  int unicornHqLevel;
  int aiClusterLevel;
  int vectorClock; // Monotonically increasing counter for cloud reconciliation

  PlayerProfileEntity({
    this.username = "Founder",
    this.netWorthStars = 48,
    this.blueprints = 12,
    this.currentLeagueIndex = 2, // Gold Founder
    this.selectedCeoId = 0,
    List<int>? unlockedCeoIds,
    this.garageLabLevel = 3,
    this.unicornHqLevel = 2,
    this.aiClusterLevel = 1,
    this.vectorClock = 1,
  }) : unlockedCeoIds = unlockedCeoIds ?? [0, 1, 2];

  Map<String, dynamic> toJson() => {
        'username': username,
        'stars': netWorthStars,
        'blueprints': blueprints,
        'league': currentLeagueIndex,
        'selectedCeo': selectedCeoId,
        'unlockedCeos': unlockedCeoIds,
        'garageLvl': garageLabLevel,
        'hqLvl': unicornHqLevel,
        'aiLvl': aiClusterLevel,
        'clock': vectorClock,
      };

  factory PlayerProfileEntity.fromJson(Map<String, dynamic> json) {
    return PlayerProfileEntity(
      username: json['username'] as String? ?? "Founder",
      netWorthStars: json['stars'] as int? ?? 48,
      blueprints: json['blueprints'] as int? ?? 12,
      currentLeagueIndex: json['league'] as int? ?? 2,
      selectedCeoId: json['selectedCeo'] as int? ?? 0,
      unlockedCeoIds: (json['unlockedCeos'] as List<dynamic>?)?.cast<int>() ?? [0, 1, 2],
      garageLabLevel: json['garageLvl'] as int? ?? 3,
      unicornHqLevel: json['hqLvl'] as int? ?? 2,
      aiClusterLevel: json['aiLvl'] as int? ?? 1,
      vectorClock: json['clock'] as int? ?? 1,
    );
  }
}

class ActiveMatchSnapshotEntity {
  final DateTime savedAt;
  final int currentTurnIndex;
  final int diceMultiplier;
  final bool suddenDeathTriggered;
  final List<Map<String, dynamic>> playersState;
  final List<Map<String, dynamic>> tilesState;
  final int stockPrice;
  final List<String> eventLogs;

  ActiveMatchSnapshotEntity({
    required this.savedAt,
    required this.currentTurnIndex,
    required this.diceMultiplier,
    required this.suddenDeathTriggered,
    required this.playersState,
    required this.tilesState,
    required this.stockPrice,
    required this.eventLogs,
  });

  Map<String, dynamic> toJson() => {
        'ts': savedAt.toIso8601String(),
        'turn': currentTurnIndex,
        'mult': diceMultiplier,
        'sd': suddenDeathTriggered,
        'players': playersState,
        'tiles': tilesState,
        'stock': stockPrice,
        'logs': eventLogs,
      };

  factory ActiveMatchSnapshotEntity.fromJson(Map<String, dynamic> json) {
    return ActiveMatchSnapshotEntity(
      savedAt: DateTime.parse(json['ts'] as String),
      currentTurnIndex: json['turn'] as int,
      diceMultiplier: json['mult'] as int,
      suddenDeathTriggered: json['sd'] as bool,
      playersState: (json['players'] as List<dynamic>).cast<Map<String, dynamic>>(),
      tilesState: (json['tiles'] as List<dynamic>).cast<Map<String, dynamic>>(),
      stockPrice: json['stock'] as int,
      eventLogs: (json['logs'] as List<dynamic>).cast<String>(),
    );
  }
}

class MatchHistoryRecord {
  final DateTime timestamp;
  final bool isVictory;
  final String winnerName;
  final int finalNetWorth;
  final int starsAwarded;
  final int lapsPlayed;

  MatchHistoryRecord({
    required this.timestamp,
    required this.isVictory,
    required this.winnerName,
    required this.finalNetWorth,
    required this.starsAwarded,
    required this.lapsPlayed,
  });

  Map<String, dynamic> toJson() => {
        'ts': timestamp.toIso8601String(),
        'victory': isVictory,
        'winner': winnerName,
        'netWorth': finalNetWorth,
        'stars': starsAwarded,
        'laps': lapsPlayed,
      };

  factory MatchHistoryRecord.fromJson(Map<String, dynamic> json) {
    return MatchHistoryRecord(
      timestamp: DateTime.parse(json['ts'] as String),
      isVictory: json['victory'] as bool,
      winnerName: json['winner'] as String,
      finalNetWorth: json['netWorth'] as int,
      starsAwarded: json['stars'] as int,
      lapsPlayed: json['laps'] as int,
    );
  }
}

class PersistenceService {
  static final PersistenceService instance = PersistenceService._internal();
  PersistenceService._internal();

  PlayerProfileEntity profile = PlayerProfileEntity();
  ActiveMatchSnapshotEntity? activeSnapshot;
  final List<MatchHistoryRecord> matchHistory = [];

  bool get hasSavedMatch => activeSnapshot != null;

  /// 1. Auto-Save Snapshot at End of Every Turn
  void autoSaveTurnSnapshot({
    required int currentTurnIndex,
    required int diceMultiplier,
    required bool suddenDeathTriggered,
    required List<PlayerModel> players,
    required List<TileModel> tiles,
    required StockModel stock,
    required List<String> eventLogs,
  }) {
    activeSnapshot = ActiveMatchSnapshotEntity(
      savedAt: DateTime.now(),
      currentTurnIndex: currentTurnIndex,
      diceMultiplier: diceMultiplier,
      suddenDeathTriggered: suddenDeathTriggered,
      playersState: players.map((p) => {
        'id': p.id,
        'name': p.name,
        'cash': p.cash,
        'tileIndex': p.tileIndex,
        'laps': p.lapsCompleted,
        'bankrupt': p.isBankrupt,
        'shield': p.hasRentShield,
        'shares': p.stockShares,
      }).toList(),
      tilesState: tiles.map((t) => {
        'id': t.id,
        'owner': t.ownerId,
        'lvl': t.upgradeLevel,
        'frozen': t.frozenTurns,
      }).toList(),
      stockPrice: stock.price,
      eventLogs: List.from(eventLogs),
    );
  }

  /// 2. Clear Snapshot on Match Completion
  void clearActiveMatch() {
    activeSnapshot = null;
  }

  /// 3. Record Match Outcome & Monotonically Increment Progression Clock
  void recordMatchCompleted({
    required bool isVictory,
    required String winnerName,
    required int finalNetWorth,
    required int lapsPlayed,
  }) {
    int stars = isVictory ? 15 : 4;
    int blueprintsAwarded = isVictory ? 5 : 1;

    profile.netWorthStars += stars;
    profile.blueprints += blueprintsAwarded;
    profile.vectorClock++; // Monotonically increasing vector clock

    // Check League promotion
    if (profile.netWorthStars >= 80 && profile.currentLeagueIndex < 4) {
      profile.currentLeagueIndex++;
    }

    matchHistory.insert(
      0,
      MatchHistoryRecord(
        timestamp: DateTime.now(),
        isVictory: isVictory,
        winnerName: winnerName,
        finalNetWorth: finalNetWorth,
        starsAwarded: stars,
        lapsPlayed: lapsPlayed,
      ),
    );

    clearActiveMatch();
  }

  /// 4. Upgrade Campus Building
  bool upgradeBuilding(String buildingKey) {
    if (buildingKey == 'garage' && profile.blueprints >= 2) {
      profile.blueprints -= 2;
      profile.garageLabLevel++;
      profile.vectorClock++;
      return true;
    } else if (buildingKey == 'hq' && profile.blueprints >= 4) {
      profile.blueprints -= 4;
      profile.unicornHqLevel++;
      profile.vectorClock++;
      return true;
    } else if (buildingKey == 'cluster' && profile.blueprints >= 6) {
      profile.blueprints -= 6;
      profile.aiClusterLevel++;
      profile.vectorClock++;
      return true;
    }
    return false;
  }
}

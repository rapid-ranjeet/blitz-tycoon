import 'player_model.dart';
import 'tile_model.dart';
import 'stock_model.dart';

enum GameDifficulty { intern, founder, unicorn, sharkTank }

class GameStateModel {
  final List<PlayerModel> players;
  final List<TileModel> tiles;
  final StockModel stock;
  int currentTurnIndex;
  int diceMultiplier;
  bool isMoving;
  int lastDiceRoll;
  bool suddenDeathTriggered;
  GameDifficulty difficulty;
  final List<String> eventLogs;

  GameStateModel({
    required this.players,
    required this.tiles,
    required this.stock,
    this.currentTurnIndex = 0,
    this.diceMultiplier = 1,
    this.isMoving = false,
    this.lastDiceRoll = 1,
    this.suddenDeathTriggered = false,
    this.difficulty = GameDifficulty.founder,
    List<String>? eventLogs,
  }) : eventLogs = eventLogs ?? [];

  PlayerModel get activePlayer => players[currentTurnIndex];
  PlayerModel get humanPlayer => players.firstWhere((p) => !p.isAI);
}

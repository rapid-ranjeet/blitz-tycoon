import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';

enum MatchState {
  lobby,
  starting,
  turnActive,
  resolvingTile,
  suddenDeath,
  completed,
}

enum MatchActionType {
  rollDice,
  buyProperty,
  upgradeProperty,
  placeBid,
  triggerSkill,
  tradeOffer,
  surrender,
}

class MatchActionPacket {
  final int sequence;
  final int playerId;
  final MatchActionType type;
  final Map<String, dynamic> payload;
  final String stateHash;
  final DateTime timestamp;

  MatchActionPacket({
    required this.sequence,
    required this.playerId,
    required this.type,
    required this.payload,
    required this.stateHash,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'seq': sequence,
        'pid': playerId,
        'type': type.name,
        'payload': payload,
        'hash': stateHash,
        'ts': timestamp.toIso8601String(),
      };

  factory MatchActionPacket.fromJson(Map<String, dynamic> json) {
    return MatchActionPacket(
      sequence: json['seq'] as int,
      playerId: json['pid'] as int,
      type: MatchActionType.values.firstWhere((e) => e.name == json['type']),
      payload: json['payload'] as Map<String, dynamic>,
      stateHash: json['hash'] as String,
      timestamp: DateTime.parse(json['ts'] as String),
    );
  }
}

class MultiplayerPlayerSlot {
  final int slotIndex;
  final String userId;
  final String displayName;
  final int ceoId;
  bool isReady;
  bool isHost;
  bool isConnected;
  bool isBotReplaced;

  MultiplayerPlayerSlot({
    required this.slotIndex,
    required this.userId,
    required this.displayName,
    required this.ceoId,
    this.isReady = false,
    this.isHost = false,
    this.isConnected = true,
    this.isBotReplaced = false,
  });
}

class MultiplayerService {
  static final MultiplayerService instance = MultiplayerService._internal();
  MultiplayerService._internal();

  String? currentRoomCode;
  String? roomMasterSeed;
  MatchState state = MatchState.lobby;
  int currentActionSequence = 0;
  bool isOnline = false;

  final List<MultiplayerPlayerSlot> playerSlots = [];
  final StreamController<MatchActionPacket> _actionStreamController = StreamController<MatchActionPacket>.broadcast();
  final StreamController<int> _turnTimerController = StreamController<int>.broadcast();

  Stream<MatchActionPacket> get onActionReceived => _actionStreamController.stream;
  Stream<int> get onTurnSecondsRemaining => _turnTimerController.stream;

  Timer? _turnDeadlineTimer;
  int currentTurnSecondsRemaining = 15;

  /// 1. Create a 4-Player Match Room
  void createRoom({required String hostUserId, required String hostName, required int hostCeoId}) {
    isOnline = true;
    final rng = Random();
    currentRoomCode = "BLITZ-${1000 + rng.nextInt(9000)}";
    roomMasterSeed = _generateCryptographicSeed();
    state = MatchState.lobby;
    currentActionSequence = 0;

    playerSlots.clear();
    playerSlots.add(MultiplayerPlayerSlot(
      slotIndex: 0,
      userId: hostUserId,
      displayName: hostName,
      ceoId: hostCeoId,
      isHost: true,
      isReady: true,
    ));
  }

  /// 2. Join Existing Match Room with Room Code
  bool joinRoom({
    required String roomCode,
    required String userId,
    required String displayName,
    required int ceoId,
  }) {
    if (playerSlots.length >= 4) return false;

    isOnline = true;
    currentRoomCode = roomCode;
    playerSlots.add(MultiplayerPlayerSlot(
      slotIndex: playerSlots.length,
      userId: userId,
      displayName: displayName,
      ceoId: ceoId,
      isReady: true,
    ));
    return true;
  }

  /// 3. Fill Empty Slots with AI Bots for Quick Match
  void fillWithBots() {
    final botNames = ["Vikram (Mogul)", "Ananya (Lobbyist)", "Kabir (Shark)"];
    final botCeos = [1, 2, 0];

    int slot = playerSlots.length;
    for (int i = slot; i < 3; i++) {
      playerSlots.add(MultiplayerPlayerSlot(
        slotIndex: i,
        userId: "BOT-$i",
        displayName: botNames[i - 1],
        ceoId: botCeos[i - 1],
        isReady: true,
        isBotReplaced: true,
      ));
    }
  }

  /// 4. Cryptographic Anti-Cheat & Deterministic Roll
  /// Seed = 64-bit FNV-1a Hash(RoomSeed || TurnIndex || PlayerID)
  int generateDeterministicDiceRoll({required int turnIndex, required int playerId}) {
    final master = roomMasterSeed ?? "LOCAL-BLITZ-SEED";
    final message = "$master-$turnIndex-$playerId";
    final bytes = utf8.encode(message);

    // 64-bit FNV-1a hashing algorithm
    int hash = 0xcbf29ce484222325;
    const int fnvPrime = 0x100000001b3;
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * fnvPrime) & 0xFFFFFFFFFFFFFFFF;
    }

    // Extract positive 1..6 deterministic roll
    int seedNumber = hash.abs() % 6;
    return seedNumber + 1;
  }

  String _generateCryptographicSeed() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes);
  }

  /// 5. 15-Second Blitz Turn Clock with Auto-Bot Takeover
  void startTurnCountdown({required int activePlayerId, required VoidCallback onTimeoutBotTakeover}) {
    _turnDeadlineTimer?.cancel();
    currentTurnSecondsRemaining = 15;
    _turnTimerController.add(currentTurnSecondsRemaining);

    _turnDeadlineTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentTurnSecondsRemaining > 1) {
        currentTurnSecondsRemaining--;
        _turnTimerController.add(currentTurnSecondsRemaining);
      } else {
        timer.cancel();
        currentTurnSecondsRemaining = 0;
        _turnTimerController.add(0);
        // Turn timed out: trigger bot takeover
        onTimeoutBotTakeover();
      }
    });
  }

  void stopTurnCountdown() {
    _turnDeadlineTimer?.cancel();
  }

  /// 6. Broadcast Action Packet
  void broadcastAction({
    required int playerId,
    required MatchActionType type,
    required Map<String, dynamic> payload,
    required String stateHash,
  }) {
    currentActionSequence++;
    final packet = MatchActionPacket(
      sequence: currentActionSequence,
      playerId: playerId,
      type: type,
      payload: payload,
      stateHash: stateHash,
    );

    _actionStreamController.add(packet);
  }

  void dispose() {
    _turnDeadlineTimer?.cancel();
    _actionStreamController.close();
    _turnTimerController.close();
  }
}

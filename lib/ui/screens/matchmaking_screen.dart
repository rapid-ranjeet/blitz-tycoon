import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/feedback_service.dart';
import '../../services/multiplayer_service.dart';
import '../../services/persistence_service.dart';
import '../../models/ceo_model.dart';
import 'game_board_screen.dart';

class MatchmakingScreen extends StatefulWidget {
  final CeoModel selectedCeo;

  const MatchmakingScreen({super.key, required this.selectedCeo});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  final MultiplayerService mp = MultiplayerService.instance;
  final TextEditingController roomCodeController = TextEditingController();
  bool isInLobby = false;

  @override
  void dispose() {
    roomCodeController.dispose();
    super.dispose();
  }

  CeoModel? _getCeoModel(int id) {
    try {
      return CeoModel.defaultRoster.firstWhere((c) => c.id.index == id);
    } catch (_) {
      return null;
    }
  }

  void _createPrivateRoom() {
    FeedbackService.buttonTap();
    mp.createRoom(
      hostUserId: "USR-001",
      hostName: PersistenceService.instance.profile.username,
      hostCeoId: widget.selectedCeo.id.index,
    );
    setState(() {
      isInLobby = true;
    });
  }

  void _joinWithCode() {
    final code = roomCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    FeedbackService.buttonTap();
    bool joined = mp.joinRoom(
      roomCode: code,
      userId: "USR-002",
      displayName: PersistenceService.instance.profile.username,
      ceoId: widget.selectedCeo.id.index,
    );

    if (joined) {
      setState(() {
        isInLobby = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Room is full or invalid.")),
      );
    }
  }

  void _fillBotsAndStart() {
    FeedbackService.buttonTap();
    mp.fillWithBots();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (ctx) => const GameBoardScreen()),
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
            Icon(Icons.hub, color: AppTheme.neonCyan, size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                "MATCHMAKING",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isInLobby ? _buildActiveLobbyView() : _buildRoomSelectionView(),
      ),
    );
  }

  Widget _buildRoomSelectionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quick Play Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E2845), AppTheme.surface],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.gold.withAlpha(100)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.gold.withAlpha(51), shape: BoxShape.circle),
                    child: const Icon(Icons.flash_on, color: AppTheme.gold, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("QUICK 12-MIN BLITZ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white)),
                        Text("Instant Match vs AI Unicorn Bots", style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () {
                  FeedbackService.buttonTap();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (ctx) => const GameBoardScreen()),
                  );
                },
                child: const Text("PLAY INSTANT MATCH", style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Private Room Creation
        const Text("MULTIPLAYER ROOMS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 1.0)),
        const SizedBox(height: 12),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.surfaceLight,
            foregroundColor: AppTheme.neonCyan,
            side: const BorderSide(color: AppTheme.neonCyan, width: 1.5),
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: _createPrivateRoom,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text("CREATE PRIVATE ROOM", style: TextStyle(fontWeight: FontWeight.bold)),
        ),

        const SizedBox(height: 16),

        // Join With Code Input
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Join via Room Code:", style: TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: roomCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: "e.g. BLITZ-4921",
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                        filled: true,
                        fillColor: AppTheme.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
                    onPressed: _joinWithCode,
                    child: const Text("JOIN"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveLobbyView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Room Code Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.gold),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("ROOM CODE", style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold)),
                  Text(
                    mp.currentRoomCode ?? "BLITZ-ROOM",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.gold, letterSpacing: 1.5),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: AppTheme.neonCyan),
                onPressed: () {
                  FeedbackService.buttonTap();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Room Code Copied to Clipboard!")),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 4 Player Slots
        const Text("PLAYERS IN LOBBY (1-4)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white60)),
        const SizedBox(height: 8),

        Expanded(
          child: ListView.builder(
            itemCount: 4,
            itemBuilder: (ctx, i) {
              bool isFilled = i < mp.playerSlots.length;
              final slot = isFilled ? mp.playerSlots[i] : null;
              final ceo = slot != null ? _getCeoModel(slot.ceoId) : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isFilled ? AppTheme.surfaceLight : AppTheme.surface.withAlpha(128),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isFilled ? AppTheme.neonCyan : Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? AppTheme.gold.withAlpha(45) : Colors.white12,
                        border: Border.all(
                          color: isFilled ? AppTheme.gold : Colors.white24,
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: ceo != null && ceo.avatarAssetPath.isNotEmpty
                            ? Image.asset(
                                ceo.avatarAssetPath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    ceo.avatarEmoji,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  ceo?.avatarEmoji ?? "👤",
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFilled ? slot!.displayName : "Empty Slot #${i + 1}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isFilled ? Colors.white : Colors.white38,
                            ),
                          ),
                          Text(
                            isFilled ? (slot!.isHost ? "Host" : (slot.isBotReplaced ? "AI Bot" : "Player")) : "Waiting for player...",
                            style: TextStyle(fontSize: 10, color: isFilled ? AppTheme.gold : Colors.white24),
                          ),
                        ],
                      ),
                    ),
                    if (isFilled)
                      const Icon(Icons.check_circle, color: AppTheme.emeraldGreen, size: 20)
                    else
                      const Text("WAITING", style: TextStyle(fontSize: 10, color: Colors.white24, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ),

        // Start Match CTA
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.gold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _fillBotsAndStart,
          child: const Text("START MATCH (FILL WITH BOTS)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/player_model.dart';
import '../../models/tile_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/feedback_service.dart';

class TradeBottomSheet extends StatefulWidget {
  final PlayerModel humanPlayer;
  final List<PlayerModel> opponents;
  final List<TileModel> tiles;
  final void Function(PlayerModel opponent, TileModel property, int offeredCash) onTradeSubmitted;

  const TradeBottomSheet({
    super.key,
    required this.humanPlayer,
    required this.opponents,
    required this.tiles,
    required this.onTradeSubmitted,
  });

  @override
  State<TradeBottomSheet> createState() => _TradeBottomSheetState();
}

class _TradeBottomSheetState extends State<TradeBottomSheet> {
  late PlayerModel selectedOpponent;
  TileModel? selectedProperty;
  double cashOffer = 300000;

  @override
  void initState() {
    super.initState();
    selectedOpponent = widget.opponents.first;
    _updateSelectedProperty();
  }

  void _updateSelectedProperty() {
    final ownedByOpponent = widget.tiles.where((t) => t.ownerId == selectedOpponent.id).toList();
    if (ownedByOpponent.isNotEmpty) {
      selectedProperty = ownedByOpponent.first;
      cashOffer = (selectedProperty!.cost * 1.2).clamp(100000, widget.humanPlayer.cash.toDouble());
    } else {
      selectedProperty = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final opponentProperties = widget.tiles.where((t) => t.ownerId == selectedOpponent.id).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.swap_horiz, color: AppTheme.gold),
              SizedBox(width: 8),
              Text(
                "NEGOTIATE PROPERTY BUYOUT",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.gold),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Select Target Opponent
          const Text("Select Rival CEO:", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: widget.opponents.map((opp) {
              final isSel = opp.id == selectedOpponent.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(opp.name, style: TextStyle(fontSize: 11, color: isSel ? Colors.black : Colors.white)),
                  selected: isSel,
                  selectedColor: AppTheme.gold,
                  backgroundColor: AppTheme.surfaceLight,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        selectedOpponent = opp;
                        _updateSelectedProperty();
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Target Property
          if (opponentProperties.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
              child: Text(
                "${selectedOpponent.name} holds no properties to acquire.",
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            )
          else ...[
            const Text("Select Target Property:", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            DropdownButtonFormField<TileModel>(
              value: selectedProperty,
              dropdownColor: AppTheme.surfaceLight,
              items: opponentProperties.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text("${t.name} (Valued ₹${t.cost})", style: const TextStyle(fontSize: 12, color: Colors.white)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedProperty = val;
                  if (val != null) {
                    cashOffer = (val.cost * 1.2).clamp(100000, widget.humanPlayer.cash.toDouble());
                  }
                });
              },
            ),

            const SizedBox(height: 14),

            // Cash Offer Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Your Cash Offer:", style: TextStyle(fontSize: 12, color: Colors.white70)),
                Text(
                  "₹${(cashOffer / 100000).toStringAsFixed(2)} Lakh",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.neonCyan),
                ),
              ],
            ),
            Slider(
              value: cashOffer.clamp(50000, widget.humanPlayer.cash.toDouble()),
              min: 50000,
              max: widget.humanPlayer.cash > 100000 ? widget.humanPlayer.cash.toDouble() : 100000,
              divisions: 20,
              activeColor: AppTheme.neonCyan,
              onChanged: (val) {
                setState(() {
                  cashOffer = val;
                });
              },
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: selectedProperty == null
                  ? null
                  : () {
                      FeedbackService.buttonTap();
                      Navigator.pop(context);
                      widget.onTradeSubmitted(selectedOpponent, selectedProperty!, cashOffer.round());
                    },
              child: const Text("SUBMIT TAKEOVER PROPOSAL"),
            ),
          ],
        ],
      ),
    );
  }
}

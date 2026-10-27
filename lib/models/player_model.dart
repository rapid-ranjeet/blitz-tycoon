import 'package:flutter/material.dart';
import 'ceo_model.dart';
import 'tile_model.dart';

class PlayerModel {
  final int id;
  final String name;
  final Color color;
  final bool isAI;
  final CeoModel ceo;
  int cash;
  int tileIndex;
  int lapsCompleted;
  bool isBankrupt;
  bool hasRentShield;
  int stockShares;

  PlayerModel({
    required this.id,
    required this.name,
    required this.color,
    required this.isAI,
    required this.ceo,
    this.cash = 1500000,
    this.tileIndex = 0,
    this.lapsCompleted = 0,
    this.isBankrupt = false,
    this.hasRentShield = false,
    this.stockShares = 0,
  });

  int calculateNetWorth(List<TileModel> tiles, int stockPrice) {
    int propertyWorth = 0;
    for (final t in tiles) {
      if (t.ownerId == id) {
        propertyWorth += t.cost + (t.upgradeLevel * t.upgradeCost);
      }
    }
    return cash + propertyWorth + (stockShares * stockPrice);
  }
}

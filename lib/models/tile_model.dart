import 'package:flutter/material.dart';

enum TileType {
  start,
  property,
  corporateHeist,
  taxAudit,
  angelLab,
  marketSurge,
}

class TileModel {
  final int id;
  final String name;
  final String city;
  final TileType type;
  final int cost;
  final List<int> rentStages; // [0: Raw Land, 1: Office, 2: Unicorn HQ, 3: Mega Skyscraper]
  final Color groupColor;
  int ownerId; // -1 if unowned
  int upgradeLevel; // 0..3
  int frozenTurns; // Freezes rent if audited

  TileModel({
    required this.id,
    required this.name,
    required this.city,
    required this.type,
    this.cost = 0,
    this.rentStages = const [0, 0, 0, 0],
    this.groupColor = Colors.grey,
    this.ownerId = -1,
    this.upgradeLevel = 0,
    this.frozenTurns = 0,
  });

  int get currentRent {
    if (frozenTurns > 0) return 0;
    if (type != TileType.property) return 0;
    return rentStages[upgradeLevel.clamp(0, rentStages.length - 1)];
  }

  int get upgradeCost => (cost * 0.6).round();

  bool get isMaxUpgraded => upgradeLevel >= 3;
}

import 'package:flutter/material.dart';

enum CeoId { fintechShark, realEstateMogul, lobbyist }

class CeoModel {
  final CeoId id;
  final String name;
  final String role;
  final String avatarSubtitle;
  final String passiveDescription;
  final String activeDescription;
  final IconData icon;
  final String avatarEmoji;
  final String avatarAssetPath;
  final Color avatarBgColor;
  final int maxCooldown;
  int currentCooldown;

  CeoModel({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarSubtitle,
    required this.passiveDescription,
    required this.activeDescription,
    required this.icon,
    this.avatarEmoji = "👤",
    this.avatarAssetPath = "",
    this.avatarBgColor = const Color(0xFF00E5FF),
    this.maxCooldown = 5,
    this.currentCooldown = 0,
  });

  CeoModel copyWith({int? currentCooldown}) {
    return CeoModel(
      id: id,
      name: name,
      role: role,
      avatarSubtitle: avatarSubtitle,
      passiveDescription: passiveDescription,
      activeDescription: activeDescription,
      icon: icon,
      avatarEmoji: avatarEmoji,
      avatarAssetPath: avatarAssetPath,
      avatarBgColor: avatarBgColor,
      maxCooldown: maxCooldown,
      currentCooldown: currentCooldown ?? this.currentCooldown,
    );
  }

  static List<CeoModel> get defaultRoster => [
        CeoModel(
          id: CeoId.fintechShark,
          name: "Rajiv Shenoy",
          role: "The FinTech Shark",
          avatarSubtitle: "Ex-Hedge Fund Partner",
          passiveDescription: "Earns 5% interest on liquid cash every lap completed.",
          activeDescription: "Shield Protocol: Immune to the next rent payment.",
          icon: Icons.shield_rounded,
          avatarEmoji: "🦈",
          avatarAssetPath: "assets/images/avatar_shark.png",
          avatarBgColor: const Color(0xFF00E5FF),
          maxCooldown: 4,
        ),
        CeoModel(
          id: CeoId.realEstateMogul,
          name: "Vikram Singhania",
          role: "The Real Estate Mogul",
          avatarSubtitle: "Tower Tycoon",
          passiveDescription: "20% permanent discount on all HQ upgrades.",
          activeDescription: "Instant Valuation: Automatically upgrades your highest-earning property.",
          icon: Icons.apartment_rounded,
          avatarEmoji: "👑",
          avatarAssetPath: "assets/images/avatar_mogul.png",
          avatarBgColor: const Color(0xFFFFB300),
          maxCooldown: 5,
        ),
        CeoModel(
          id: CeoId.lobbyist,
          name: "Ananya Roy",
          role: "The Lobbyist",
          avatarSubtitle: "Policy Strategist",
          passiveDescription: "Immune to Tax Audit tiles; siphons 50% of taxes paid by rivals.",
          activeDescription: "Audit Strike: Freezes an opponent's top HQ rent for 2 full laps.",
          icon: Icons.balance_rounded,
          avatarEmoji: "🏛️",
          avatarAssetPath: "assets/images/avatar_lobbyist.png",
          avatarBgColor: const Color(0xFFBA68C8),
          maxCooldown: 5,
        ),
      ];
}

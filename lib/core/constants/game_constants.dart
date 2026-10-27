import 'package:flutter/material.dart';

class GameConstants {
  static const String appName = "Blitz Tycoon";
  static const String appTagline = "Unicorn Empire";

  // Board dimensions
  static const int blitzTileCount = 28;
  static const int gridSize = 8;

  // Economy & Rules
  static const int defaultStartingCash = 1500000; // ₹15 Lakhs
  static const int basePaydaySalary = 200000; // ₹2 Lakhs
  static const int suddenDeathLapThreshold = 10;
  static const int auctionTimeSeconds = 10;

  // Vibrant Board Game City Colors (Monopoly Grade Contrast)
  static const Color bengaluruColor = Color(0xFF00C853); // Emerald Mint
  static const Color hyderabadColor = Color(0xFF00B0FF); // Electric Cyan
  static const Color gurgaonColor = Color(0xFF7C4DFF);   // Royal Amethyst
  static const Color puneColor = Color(0xFFFF5722);      // Vibrant Coral
  static const Color mumbaiColor = Color(0xFFFFAB00);    // Imperial Gold
  static const Color delhiColor = Color(0xFFFF1744);     // Sovereign Crimson

  // League Tiers for Meta-progression
  static const List<String> leagueTiers = [
    "Bronze Intern",
    "Silver Manager",
    "Gold Founder",
    "Diamond Unicorn",
    "Shark Tank Legend",
  ];
}

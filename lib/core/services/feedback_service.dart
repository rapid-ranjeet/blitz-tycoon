import 'package:flutter/services.dart';

class FeedbackService {
  /// 1. Dice Launch: Accelerating rattle (light -> medium -> heavy click)
  static Future<void> diceRoll() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 40));
    HapticFeedback.heavyImpact();
  }

  /// 2. Token Hop: Crisp micro-click on each tile peg
  static void tokenHop() {
    HapticFeedback.selectionClick();
  }

  /// 3. Cash Received / Grant: Light positive affirm
  static void cashReceived() {
    HapticFeedback.lightImpact();
  }

  /// 4. Deed Stamp / Purchase: Double affirmation thud
  static Future<void> propertyAcquired() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 45));
    HapticFeedback.heavyImpact();
  }

  /// 5. Rent Slam Penalty: Dual-phase seismic shockwave
  static Future<void> rentImpact() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 25));
    HapticFeedback.heavyImpact();
  }

  /// 6. Corporate Sabotage / Heist: Hard cash extraction punch
  static Future<void> sabotageTriggered() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    HapticFeedback.heavyImpact();
  }

  /// 7. Bankruptcy Elimination: Tri-phase shudder decay
  static Future<void> bankruptcyShudder() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 40));
    HapticFeedback.lightImpact();
  }

  /// 8. Monopoly / Lap Fanfare: Ascending celebratory triplet
  static Future<void> victoryFanfare() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 70));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 70));
    HapticFeedback.heavyImpact();
  }

  /// UI Standard tap
  static void buttonTap() {
    HapticFeedback.selectionClick();
  }
}

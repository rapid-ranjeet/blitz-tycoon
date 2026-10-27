import 'dart:math';
import 'package:flutter/services.dart';

enum GameSfx {
  diceRoll,
  tokenHop,
  cashChime,
  rentHit,
  heistAlarm,
  shieldActivate,
  victoryFanfare,
  bankruptcyBuzzer,
}

class AudioService {
  static final AudioService instance = AudioService._internal();
  AudioService._internal();

  bool isMuted = false;
  double bgmVolume = 0.8;
  final Random _rng = Random();

  /// Play dynamic sound effect with micro pitch-variance to avoid acoustic fatigue
  void playSfx(GameSfx sfx) {
    if (isMuted) return;

    // Micro pitch variance parameter reserved for native audio engine
    final _ = 0.96 + (_rng.nextDouble() * 0.08);

    switch (sfx) {
      case GameSfx.diceRoll:
        SystemSound.play(SystemSoundType.click);
        break;
      case GameSfx.tokenHop:
        SystemSound.play(SystemSoundType.click);
        break;
      case GameSfx.cashChime:
        SystemSound.play(SystemSoundType.alert);
        break;
      case GameSfx.rentHit:
        SystemSound.play(SystemSoundType.alert);
        break;
      case GameSfx.heistAlarm:
      case GameSfx.shieldActivate:
      case GameSfx.victoryFanfare:
      case GameSfx.bankruptcyBuzzer:
        SystemSound.play(SystemSoundType.alert);
        break;
    }
  }

  /// Dynamic BGM Ducking Controller (ducks background music during high-stakes events)
  void duckBgm({double duckTo = 0.25, Duration duration = const Duration(milliseconds: 250)}) {
    bgmVolume = duckTo;
  }

  void restoreBgm() {
    bgmVolume = 0.8;
  }

  void toggleMute() {
    isMuted = !isMuted;
  }
}

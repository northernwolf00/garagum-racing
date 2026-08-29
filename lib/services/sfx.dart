import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

import 'app_settings.dart';

/// Small, centralized sound-effect + haptic helper.
///
/// Every call is a no-op when the player has turned SFX off (see
/// [AppSettings.sfx]) and swallows audio errors, so call sites never need to
/// guard or try/catch. Haptics are cheap and need no assets.
class Sfx {
  Sfx._();

  /// Short UI/gameplay clips worth preloading so the first play doesn't hitch.
  static const _preload = <String>[
    'sfx/button_tap.wav',
    'sfx/coin_bonus.wav',
    'sfx/coin_pickup.wav',
    'sfx/crash.wav',
    'sfx/unlock_vehicle.wav',
    'sfx/level_complete.wav',
  ];

  /// Warm the audio cache once at startup (best-effort).
  static Future<void> preload() async {
    try {
      await FlameAudio.audioCache.loadAll(_preload);
    } catch (_) {
      // Missing/again-unavailable assets must never block startup.
    }
  }

  static void _play(String file, double volume) {
    if (!AppSettings.instance.sfx.value) return;
    try {
      FlameAudio.play(file, volume: volume);
    } catch (_) {}
  }

  // ── Named effects ────────────────────────────────────────────────────────
  /// Light UI tap — buttons. Pairs with a selection haptic.
  static void tap() {
    _play('sfx/button_tap.wav', 0.6);
    HapticFeedback.selectionClick();
  }

  /// Reward / coins granted (daily gift, doubled coins, store).
  static void coins() {
    _play('sfx/coin_bonus.wav', 0.9);
    HapticFeedback.mediumImpact();
  }

  /// Crash / flip — the heaviest feedback.
  static void crash() {
    _play('sfx/crash.wav', 0.9);
    HapticFeedback.heavyImpact();
  }

  /// Vehicle purchased / unlocked.
  static void unlock() {
    _play('sfx/unlock_vehicle.wav', 0.9);
    HapticFeedback.mediumImpact();
  }

  /// Round completed.
  static void levelComplete() {
    _play('sfx/level_complete.wav', 0.9);
    HapticFeedback.mediumImpact();
  }
}

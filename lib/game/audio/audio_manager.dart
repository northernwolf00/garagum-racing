import 'package:flame_audio/flame_audio.dart';

/// Engine loop + one-shot UI sfx for the race screen.
///
/// Call [init] once when the game loads, [setEngineIntensity] every frame
/// with the current throttle (-1..1), and [dispose] when the screen is torn
/// down so the looping engine player doesn't leak.
class AudioManager {
  AudioPlayer? _enginePlayer;
  bool _audioAvailable = false;

  static const double _idleVolume = 0.25;
  static const double _fullVolume = 0.85;

  Future<void> init() async {
    try {
      _enginePlayer = await FlameAudio.loop(
        'sfx/diesel.mp3',
        volume: _idleVolume,
      ).timeout(const Duration(seconds: 10));
      _audioAvailable = true;
    } catch (e) {
      _audioAvailable = false;
      _enginePlayer = null;
    }
  }

  /// [throttle] is -1 (full brake/reverse) .. 0 (idle) .. 1 (full gas); the
  /// engine gets louder the harder either pedal is held.
  void setEngineIntensity(double throttle) {
    if (!_audioAvailable || _enginePlayer == null) return;
    try {
      final intensity = throttle.abs().clamp(0.0, 1.0);
      _enginePlayer!.setVolume(
        _idleVolume + (_fullVolume - _idleVolume) * intensity,
      );
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  Future<void> playButtonClick() async {
    if (!_audioAvailable) return;
    try {
      await FlameAudio.play('sfx/click-button.mp3', volume: 0.6);
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  Future<void> playCrashSound() async {
    if (!_audioAvailable) return;
    try {
      await FlameAudio.play('sfx/car-crash-sound.mp3', volume: 0.9);
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  Future<void> playCoinSound() async {
    if (!_audioAvailable) return;
    try {
      await FlameAudio.play('sfx/bonus-earned.mp3', volume: 0.7);
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  /// Picking up a fuel canister should feel like a reward, same as a coin.
  Future<void> playFuelSound() async {
    if (!_audioAvailable) return;
    try {
      await FlameAudio.play('sfx/bonus-earned.mp3', volume: 0.7);
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  /// Warning played once fuel drops low, ahead of the tank actually running
  /// dry — gives the player a heads-up instead of the sound only showing up
  /// once the engine has already died.
  Future<void> playLowFuelWarningSound() async {
    if (!_audioAvailable) return;
    try {
      await FlameAudio.play('sfx/out_of_fuel.mp3', volume: 0.7);
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  Future<void> playOutOfFuelSound() async {
    if (!_audioAvailable) return;
    try {
      await FlameAudio.play('sfx/out_of_fuel.mp3', volume: 0.9);
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  Future<void> stopEngine() async {
    if (_enginePlayer == null) return;
    try {
      await _enginePlayer?.stop();
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  Future<void> dispose() async {
    if (_enginePlayer == null) return;
    try {
      await _enginePlayer?.stop();
      await _enginePlayer?.dispose();
    } catch (e) {
      // Silently ignore audio errors
    }
    _enginePlayer = null;
    _audioAvailable = false;
  }
}

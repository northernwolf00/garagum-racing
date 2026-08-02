import 'package:flame_audio/flame_audio.dart';

/// Engine loop + one-shot UI sfx for the race screen.
///
/// Call [init] once when the game loads, [setEngineIntensity] every frame
/// with the current throttle (-1..1), and [dispose] when the screen is torn
/// down so the looping engine player doesn't leak.
class AudioManager {
  AudioPlayer? _enginePlayer;

  static const double _idleVolume = 0.25;
  static const double _fullVolume = 0.85;

  Future<void> init() async {
    _enginePlayer = await FlameAudio.loop(
      'sfx/diesel.mp3',
      volume: _idleVolume,
    );
  }

  /// [throttle] is -1 (full brake/reverse) .. 0 (idle) .. 1 (full gas); the
  /// engine gets louder the harder either pedal is held.
  void setEngineIntensity(double throttle) {
    final intensity = throttle.abs().clamp(0.0, 1.0);
    _enginePlayer?.setVolume(
      _idleVolume + (_fullVolume - _idleVolume) * intensity,
    );
  }

  Future<void> playButtonClick() {
    return FlameAudio.play('sfx/click-button.mp3', volume: 0.6);
  }

  Future<void> playCrashSound() {
    return FlameAudio.play('sfx/car-crash-sound.mp3', volume: 0.9);
  }

  Future<void> playCoinSound() {
    return FlameAudio.play('sfx/bonus-earned.mp3', volume: 0.7);
  }

  Future<void> playFuelSound() {
    return FlameAudio.play('sfx/out_of_fuel.mp3', volume: 0.65);
  }

  Future<void> playOutOfFuelSound() {
    return FlameAudio.play('sfx/out_of_fuel.mp3', volume: 0.9);
  }

  Future<void> stopEngine() async {
    await _enginePlayer?.stop();
  }

  Future<void> dispose() async {
    await _enginePlayer?.stop();
    await _enginePlayer?.dispose();
    _enginePlayer = null;
  }
}

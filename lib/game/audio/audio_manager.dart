import 'package:flame_audio/flame_audio.dart';

/// Engine loop + one-shot UI/gameplay sfx for the race screen.
///
/// The engine is built from two looping layers per vehicle — `engine_idle_*`
/// and `engine_rev_*` — mixed by throttle (idle = 1−throttle, rev = throttle)
/// as described in `assets/audio/OKA_MENI.md`. `playbackRate` is nudged with
/// intensity so the RPM is felt.
///
/// Call [init] once when the game loads (passing the selected vehicle id),
/// [setEngineIntensity] whenever the throttle (-1..1) changes, and [dispose]
/// when the screen is torn down so the looping players don't leak.
class AudioManager {
  AudioPlayer? _idlePlayer;
  AudioPlayer? _revPlayer;
  bool _audioAvailable = false;

  /// Vehicle ids that ship with a dedicated engine sample set. Anything else
  /// falls back to the starter buggy so the game never plays a missing file.
  static const Set<String> _engineVehicles = {'uaz', 'ak_ulag', 'pikap', 'buggy'};
  static const String _fallbackVehicle = 'buggy';

  static const double _idleLayerVolume = 0.6;
  static const double _revLayerVolume = 0.85;

  Future<void> init(String vehicleId) async {
    final vehicle =
        _engineVehicles.contains(vehicleId) ? vehicleId : _fallbackVehicle;
    try {
      // Ignition one-shot, then the two loop layers underneath it.
      FlameAudio.play('sfx/engine_start_$vehicle.wav', volume: 0.7);

      final results = await Future.wait([
        FlameAudio.loop('sfx/engine_idle_$vehicle.wav', volume: _idleLayerVolume),
        FlameAudio.loop('sfx/engine_rev_$vehicle.wav', volume: 0.0),
      ]).timeout(const Duration(seconds: 10));
      _idlePlayer = results[0];
      _revPlayer = results[1];
      _audioAvailable = true;
    } catch (e) {
      _audioAvailable = false;
      _idlePlayer = null;
      _revPlayer = null;
    }
  }

  /// [throttle] is -1 (full brake/reverse) .. 0 (idle) .. 1 (full gas). The rev
  /// layer fades in and the idle layer fades out as either pedal is pressed,
  /// and both layers speed up slightly with intensity for an RPM feel.
  void setEngineIntensity(double throttle) {
    if (!_audioAvailable) return;
    try {
      final intensity = throttle.abs().clamp(0.0, 1.0);
      _idlePlayer?.setVolume(_idleLayerVolume * (1.0 - intensity));
      _revPlayer?.setVolume(_revLayerVolume * intensity);
      final rate = 0.9 + 0.7 * intensity; // 0.9 .. 1.6
      _idlePlayer?.setPlaybackRate(rate);
      _revPlayer?.setPlaybackRate(rate);
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  Future<void> _playOneShot(String file, double volume) async {
    if (!_audioAvailable) return;
    try {
      await FlameAudio.play(file, volume: volume);
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  Future<void> playButtonClick() => _playOneShot('sfx/button_tap.wav', 0.6);

  Future<void> playCrashSound() => _playOneShot('sfx/crash.wav', 0.9);

  Future<void> playBumpSound() => _playOneShot('sfx/bump.wav', 0.6);

  Future<void> playCoinSound() => _playOneShot('sfx/coin_pickup.wav', 0.7);

  /// Picking up a fuel canister should feel like a reward.
  Future<void> playFuelSound() => _playOneShot('sfx/fuel_refill.wav', 0.7);

  /// Warning played once fuel drops low, ahead of the tank actually running
  /// dry — gives the player a heads-up instead of the sound only showing up
  /// once the engine has already died.
  Future<void> playLowFuelWarningSound() =>
      _playOneShot('sfx/fuel_low_warning.wav', 0.7);

  Future<void> playOutOfFuelSound() => _playOneShot('sfx/out_of_fuel.wav', 0.9);

  Future<void> playLevelCompleteSound() =>
      _playOneShot('sfx/level_complete.wav', 0.8);

  Future<void> playGameOverSound() => _playOneShot('sfx/game_over.wav', 0.8);

  Future<void> stopEngine() async {
    try {
      await _idlePlayer?.stop();
      await _revPlayer?.stop();
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  Future<void> dispose() async {
    try {
      await _idlePlayer?.stop();
      await _idlePlayer?.dispose();
      await _revPlayer?.stop();
      await _revPlayer?.dispose();
    } catch (e) {
      // Silently ignore audio errors
    }
    _idlePlayer = null;
    _revPlayer = null;
    _audioAvailable = false;
  }
}

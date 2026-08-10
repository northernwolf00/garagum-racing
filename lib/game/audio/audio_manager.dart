import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Engine loop + one-shot UI/gameplay sfx for the race screen.
///
/// The engine is a physical-model sample set per vehicle: three looping RPM
/// layers — `engine_idle_*` / `engine_mid_*` / `engine_rev_*` — played at once
/// and cross-faded by throttle (0→idle, 0.5→mid, 1.0→rev, linear in between),
/// with `playbackRate` swept 0.85–1.5 so the RPM sweep is continuous. See
/// `assets/audio/OKA_MENI copy.md`. Any layer whose file is missing is simply
/// skipped, so the engine still works with whatever samples are present.
///
/// Call [init] once when the game loads (passing the selected vehicle id),
/// [setEngineIntensity] whenever the throttle (-1..1) changes, and [dispose]
/// when the screen is torn down so the looping players don't leak.
class AudioManager {
  AudioPlayer? _idlePlayer;
  AudioPlayer? _midPlayer;
  AudioPlayer? _revPlayer;
  final List<AudioPlayer> _sfxPool = [];
  int _sfxPoolIndex = 0;
  bool _audioAvailable = false;
  bool _disposed = false;
  String _vehicle = _fallbackVehicle;

  /// Vehicle ids that ship with a dedicated engine sample set. Anything else
  /// falls back to the starter buggy so the game never plays a missing file.
  static const Set<String> _engineVehicles = {
    'uaz',
    'ak_ulag',
    'pikap',
    'buggy',
  };
  static const String _fallbackVehicle = 'buggy';

  static const double _idleVolume = 0.25;
  static const double _fullVolume = 0.95;
  double _lastEngineVolume = -1.0;

  Future<void> init(String vehicleId) async {
    await dispose();
    _disposed = false;
    _lastEngineVolume = -1.0;
    _vehicle = _engineVehicles.contains(vehicleId)
        ? vehicleId
        : _fallbackVehicle;

    // Initialize reusable SFX player pool (3 players to handle overlapping SFX)
    if (_sfxPool.isEmpty) {
      for (int i = 0; i < 3; i++) {
        _sfxPool.add(AudioPlayer());
      }
    }

    try {
      // Ignition one-shot
      FlameAudio.play('sfx/engine_start_$_vehicle.wav', volume: 0.7);

      // Load soud_car.mp3 for car engine sound
      _idlePlayer = await _tryLoop('soud_car.mp3', _idleVolume);
      _idlePlayer ??= await _tryLoop('sfx/soud_car.mp3', _idleVolume);
      _idlePlayer ??= await _tryLoop(
        'sfx/engine_idle_$_vehicle.wav',
        _idleVolume,
      );

      _audioAvailable = _idlePlayer != null;
      _lastEngineVolume = _idleVolume;
      debugPrint('[audio] engine init "$_vehicle" available=$_audioAvailable');
    } catch (e) {
      debugPrint('[audio] ✖ engine init failed for "$_vehicle": $e');
      _audioAvailable = false;
      _idlePlayer = null;
    }
  }

  Future<AudioPlayer?> _tryLoop(String file, double volume) async {
    if (_disposed) return null;
    try {
      return await FlameAudio.loop(
        file,
        volume: volume,
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      return null;
    }
  }

  /// [throttle] is -1 (full brake/reverse) .. 0 (idle) .. 1 (full gas).
  /// Increases engine volume smoothly from idle (0.25) to full (0.95) when gas is pressed.
  void setEngineIntensity(double throttle) {
    if (!_audioAvailable || _disposed) return;
    try {
      final intensity = throttle.abs().clamp(0.0, 1.0);
      final volume = _idleVolume + (_fullVolume - _idleVolume) * intensity;
      if ((volume - _lastEngineVolume).abs() >= 0.02) {
        _lastEngineVolume = volume;
        _idlePlayer?.setVolume(volume);
      }
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  /// Short throttle blip (e.g. on landing after a jump), using the vehicle's
  /// own blip sample.
  Future<void> playEngineBlip() async {
    if (!_audioAvailable || _disposed) return;
    try {
      await _playOneShot('sfx/engine_blip_$_vehicle.wav', 0.7);
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  /// Reusable SFX playback using pre-allocated AudioPlayer pool (zero native object allocation).
  Future<void> _playOneShot(String file, double volume) async {
    if (_disposed || _sfxPool.isEmpty) return;
    try {
      final player = _sfxPool[_sfxPoolIndex];
      _sfxPoolIndex = (_sfxPoolIndex + 1) % _sfxPool.length;
      await player.stop();
      await player.play(AssetSource('audio/$file'), volume: volume);
      debugPrint('[audio] ▶ $file (vol ${volume.toStringAsFixed(2)})');
    } catch (e) {
      debugPrint('[audio] ✖ failed to play $file: $e');
    }
  }

  Future<void> playButtonClick() => _playOneShot('tap-ui-tap-hit.wav', 0.6);

  Future<void> playCrashSound() => _playOneShot('crash.wav', 0.9);

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
    _lastEngineVolume = -1.0;
    try {
      await _idlePlayer?.stop();
      await _midPlayer?.stop();
      await _revPlayer?.stop();
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  Future<void> stopAllSfx() async {
    try {
      for (final player in _sfxPool) {
        await player.stop();
      }
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _audioAvailable = false;
    _lastEngineVolume = -1.0;
    try {
      await stopEngine();
      await stopAllSfx();
      await _idlePlayer?.dispose();
      await _midPlayer?.dispose();
      await _revPlayer?.dispose();
      for (final player in _sfxPool) {
        await player.dispose();
      }
      _sfxPool.clear();
    } catch (e) {
      // Silently ignore audio errors
    }
    _idlePlayer = null;
    _midPlayer = null;
    _revPlayer = null;
  }
}

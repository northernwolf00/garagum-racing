import 'package:flame_audio/flame_audio.dart';

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
  bool _audioAvailable = false;
  String _vehicle = _fallbackVehicle;

  /// Vehicle ids that ship with a dedicated engine sample set. Anything else
  /// falls back to the starter buggy so the game never plays a missing file.
  static const Set<String> _engineVehicles = {'uaz', 'ak_ulag', 'pikap', 'buggy'};
  static const String _fallbackVehicle = 'buggy';

  // Per-layer ceiling volumes; the throttle blend scales each of these.
  static const double _idleCeil = 0.65;
  static const double _midCeil = 0.8;
  static const double _revCeil = 0.9;

  Future<void> init(String vehicleId) async {
    _vehicle = _engineVehicles.contains(vehicleId) ? vehicleId : _fallbackVehicle;
    try {
      // Ignition one-shot, then the RPM loop layers underneath it.
      FlameAudio.play('sfx/engine_start_$_vehicle.wav', volume: 0.7);

      // Load each layer independently so a missing sample (e.g. no mid layer
      // for this vehicle yet) doesn't take the whole engine down with it.
      _idlePlayer = await _tryLoop('sfx/engine_idle_$_vehicle.wav', _idleCeil);
      _midPlayer = await _tryLoop('sfx/engine_mid_$_vehicle.wav', 0.0);
      _revPlayer = await _tryLoop('sfx/engine_rev_$_vehicle.wav', 0.0);
      _audioAvailable = _idlePlayer != null || _revPlayer != null;
    } catch (e) {
      _audioAvailable = false;
      _idlePlayer = null;
      _midPlayer = null;
      _revPlayer = null;
    }
  }

  Future<AudioPlayer?> _tryLoop(String file, double volume) async {
    try {
      return await FlameAudio.loop(file, volume: volume)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      return null;
    }
  }

  /// [throttle] is -1 (full brake/reverse) .. 0 (idle) .. 1 (full gas). Blends
  /// the three RPM layers by |throttle| and sweeps playback rate for a
  /// continuous rev feel. Falls back to a 2-layer idle↔rev blend when there is
  /// no mid layer for this vehicle.
  void setEngineIntensity(double throttle) {
    if (!_audioAvailable) return;
    try {
      final t = throttle.abs().clamp(0.0, 1.0);

      double idleW, midW, revW;
      if (_midPlayer != null) {
        // Triangular blend: idle peaks at 0, mid at 0.5, rev at 1.
        idleW = (1.0 - 2.0 * t).clamp(0.0, 1.0);
        midW = (1.0 - (2.0 * t - 1.0).abs()).clamp(0.0, 1.0);
        revW = (2.0 * t - 1.0).clamp(0.0, 1.0);
      } else {
        idleW = 1.0 - t;
        midW = 0.0;
        revW = t;
      }

      _idlePlayer?.setVolume(_idleCeil * idleW);
      _midPlayer?.setVolume(_midCeil * midW);
      _revPlayer?.setVolume(_revCeil * revW);

      final rate = 0.85 + 0.65 * t; // 0.85 .. 1.5
      _idlePlayer?.setPlaybackRate(rate);
      _midPlayer?.setPlaybackRate(rate);
      _revPlayer?.setPlaybackRate(rate);
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  /// Short throttle blip (e.g. on landing after a jump), using the vehicle's
  /// own blip sample.
  Future<void> playEngineBlip() async {
    if (!_audioAvailable) return;
    try {
      await FlameAudio.play('sfx/engine_blip_$_vehicle.wav', volume: 0.7);
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
      await _midPlayer?.stop();
      await _revPlayer?.stop();
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  Future<void> dispose() async {
    try {
      await _idlePlayer?.stop();
      await _idlePlayer?.dispose();
      await _midPlayer?.stop();
      await _midPlayer?.dispose();
      await _revPlayer?.stop();
      await _revPlayer?.dispose();
    } catch (e) {
      // Silently ignore audio errors
    }
    _idlePlayer = null;
    _midPlayer = null;
    _revPlayer = null;
    _audioAvailable = false;
  }
}

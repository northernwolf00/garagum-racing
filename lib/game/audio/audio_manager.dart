import 'package:flame_audio/flame_audio.dart';

/// Engine loop + one-shot UI sfx for the race screen.
///
/// Call [init] once when the game loads, [setEngineIntensity] every frame
/// with the current throttle (-1..1), and [dispose] when the screen is torn
/// down so the looping engine player doesn't leak.
class AudioManager {
  AudioPlayer? _enginePlayer;
  final List<AudioPlayer> _sfxPlayers = [];
  bool _audioAvailable = false;

  /// Set once the engine loop has been deliberately stopped (crash, empty
  /// tank, teardown) so a later [resumeEngine] doesn't restart it.
  bool _engineStopped = false;
  bool _enginePaused = false;

  static const double _idleVolume = 0.25;
  static const double _fullVolume = 0.85;

  /// Engine-loop playback rate at standstill and at (stat-scaled) top speed.
  /// setPlaybackRate is a platform-channel call, so [setEngineSpeed] only
  /// pushes a new rate when it moved by more than [_rateEpsilon].
  static const double _minEngineRate = 0.8;
  static const double _maxEngineRate = 1.5;
  static const double _rateEpsilon = 0.04;
  double _lastEngineRate = 1.0;

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

  /// [normalizedSpeed] is the car's road speed as a fraction of its top
  /// speed (0..1); the engine pitch rises with it so acceleration is
  /// audible instead of the loop droning at one constant tone.
  void setEngineSpeed(double normalizedSpeed) {
    if (!_audioAvailable || _enginePlayer == null || _engineStopped) return;
    final rate = _minEngineRate +
        (_maxEngineRate - _minEngineRate) * normalizedSpeed.clamp(0.0, 1.0);
    if ((rate - _lastEngineRate).abs() < _rateEpsilon) return;
    _lastEngineRate = rate;
    try {
      _enginePlayer!.setPlaybackRate(rate);
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  /// Pause/resume the looping engine sound with the game's pause menu —
  /// without this the diesel loop keeps droning behind the pause overlay.
  Future<void> pauseEngine() async {
    if (!_audioAvailable || _enginePlayer == null || _engineStopped) return;
    if (_enginePaused) return;
    _enginePaused = true;
    try {
      await _enginePlayer?.pause();
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  Future<void> resumeEngine() async {
    if (!_audioAvailable || _enginePlayer == null || _engineStopped) return;
    if (!_enginePaused) return;
    _enginePaused = false;
    try {
      await _enginePlayer?.resume();
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  Future<void> _playSfx(String file, {double volume = 1.0}) async {
    if (!_audioAvailable) return;
    try {
      final player = await FlameAudio.play(file, volume: volume);
      _sfxPlayers.add(player);
      player.onPlayerComplete.listen((_) {
        try {
          player.dispose();
        } catch (_) {}
        _sfxPlayers.remove(player);
      });
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  Future<void> playButtonClick() async {
    await _playSfx('sfx/click-button.mp3', volume: 0.6);
  }

  Future<void> playCrashSound() async {
    await _playSfx('sfx/car-crash-sound.mp3', volume: 0.9);
  }

  Future<void> playCoinSound() async {
    await _playSfx('sfx/bonus-earned.mp3', volume: 0.7);
  }

  /// Picking up a fuel canister should feel like a reward, same as a coin.
  Future<void> playFuelSound() async {
    await _playSfx('sfx/bonus-earned.mp3', volume: 0.7);
  }

  /// Warning played once fuel drops low, ahead of the tank actually running
  /// dry — gives the player a heads-up instead of the sound only showing up
  /// once the engine has already died.
  Future<void> playLowFuelWarningSound() async {
    await _playSfx('sfx/out_of_fuel.mp3', volume: 0.7);
  }

  Future<void> playOutOfFuelSound() async {
    await _playSfx('sfx/out_of_fuel.mp3', volume: 0.9);
  }

  Future<void> stopEngine() async {
    if (_enginePlayer == null) return;
    _engineStopped = true;
    try {
      await _enginePlayer?.stop();
    } catch (e) {
      // Silently ignore audio errors
    }
  }

  Future<void> stopAll() async {
    _audioAvailable = false;
    await stopEngine();
    for (final player in List<AudioPlayer>.from(_sfxPlayers)) {
      try {
        await player.stop();
        await player.dispose();
      } catch (_) {}
    }
    _sfxPlayers.clear();
  }

  Future<void> dispose() async {
    _audioAvailable = false;
    try {
      await _enginePlayer?.stop();
      await _enginePlayer?.dispose();
    } catch (e) {
      // Silently ignore audio errors
    }
    _enginePlayer = null;

    for (final player in List<AudioPlayer>.from(_sfxPlayers)) {
      try {
        await player.stop();
        await player.dispose();
      } catch (_) {}
    }
    _sfxPlayers.clear();
  }
}

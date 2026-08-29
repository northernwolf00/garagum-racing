import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent player preferences for audio. Backed by [SharedPreferences] and
/// exposed as [ValueNotifier]s so any widget (menu music, settings screen,
/// sfx call-sites) can react to changes without prop-drilling.
class AppSettings {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _musicKey = 'settings_music_on';
  static const _sfxKey = 'settings_sfx_on';

  SharedPreferences? _prefs;

  /// Whether background music should play. Defaults to on.
  final ValueNotifier<bool> music = ValueNotifier<bool>(true);

  /// Whether UI / gameplay sound effects should play. Defaults to on.
  final ValueNotifier<bool> sfx = ValueNotifier<bool>(true);

  /// Load persisted values before the first frame. Safe to call once.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    music.value = _prefs?.getBool(_musicKey) ?? true;
    sfx.value = _prefs?.getBool(_sfxKey) ?? true;
  }

  Future<void> setMusic(bool on) async {
    music.value = on;
    await _prefs?.setBool(_musicKey, on);
  }

  Future<void> setSfx(bool on) async {
    sfx.value = on;
    await _prefs?.setBool(_sfxKey, on);
  }
}

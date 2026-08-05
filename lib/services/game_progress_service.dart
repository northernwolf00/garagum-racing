import 'package:shared_preferences/shared_preferences.dart';

import '../models/map_theme.dart';
import '../models/round_config.dart';

/// Handles persistent local game progress:
/// - Total coins collected across all runs
/// - Which rounds are unlocked, per map
/// - Which rounds have been completed (passed their required coin threshold), per map
class GameProgressService {
  static const String _keyTotalCoins = 'total_coins';

  static GameProgressService? _instance;
  static GameProgressService get instance {
    _instance ??= GameProgressService._();
    return _instance!;
  }

  GameProgressService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    for (final theme in MapTheme.values) {
      final unlocked = getUnlockedRounds(theme);
      bool changed = false;
      if (!unlocked.contains(1)) {
        unlocked.add(1);
        changed = true;
      }
      if (!unlocked.contains(2)) {
        unlocked.add(2);
        changed = true;
      }
      if (changed) {
        await _prefs!
            .setString(_unlockedKey(theme), _encodeList(unlocked));
      }
    }
  }

  // ── Coins ────────────────────────────────────────────────────────────────

  int getTotalCoins() {
    return _prefs?.getInt(_keyTotalCoins) ?? 0;
  }

  Future<void> addCoins(int amount) async {
    final current = getTotalCoins();
    await _prefs?.setInt(_keyTotalCoins, current + amount);
  }

  // ── Rounds ───────────────────────────────────────────────────────────────

  /// Garagum keeps the original, pre-multi-map key names so existing
  /// players don't lose their save data. Other maps get their own
  /// namespaced keys.
  String _unlockedKey(MapTheme theme) => theme == MapTheme.garagum
      ? 'unlocked_rounds'
      : 'unlocked_rounds_${theme.name}';

  String _completedKey(MapTheme theme) => theme == MapTheme.garagum
      ? 'completed_rounds'
      : 'completed_rounds_${theme.name}';

  List<int> getUnlockedRounds(MapTheme theme) {
    final raw = _prefs?.getString(_unlockedKey(theme)) ?? '1,2';
    return _decodeList(raw);
  }

  bool isRoundUnlocked(MapTheme theme, int round) {
    return getUnlockedRounds(theme).contains(round);
  }

  List<int> getCompletedRounds(MapTheme theme) {
    final raw = _prefs?.getString(_completedKey(theme)) ?? '';
    if (raw.isEmpty) return [];
    return _decodeList(raw);
  }

  bool isRoundCompleted(MapTheme theme, int round) {
    return getCompletedRounds(theme).contains(round);
  }

  /// Marks a round as completed and unlocks the next one (if any remain on
  /// this map).
  Future<void> completeRound(MapTheme theme, int round) async {
    final completed = getCompletedRounds(theme);
    if (!completed.contains(round)) {
      completed.add(round);
      await _prefs?.setString(_completedKey(theme), _encodeList(completed));
    }

    final nextRound = round + 1;
    if (nextRound <= RoundConfig.totalRoundsFor(theme)) {
      await unlockRound(theme, nextRound);
    }
  }

  Future<void> unlockRound(MapTheme theme, int round) async {
    final unlocked = getUnlockedRounds(theme);
    if (!unlocked.contains(round)) {
      unlocked.add(round);
      await _prefs?.setString(_unlockedKey(theme), _encodeList(unlocked));
    }
  }

  // ── Internal helpers ─────────────────────────────────────────────────────

  String _encodeList(List<int> list) => list.join(',');

  List<int> _decodeList(String raw) {
    if (raw.isEmpty) return [];
    return raw.split(',').map((e) => int.tryParse(e.trim()) ?? 0).where((e) => e > 0).toList();
  }
}

import 'package:shared_preferences/shared_preferences.dart';

/// Handles persistent local game progress:
/// - Total coins collected across all runs
/// - Which rounds are unlocked
/// - Which rounds have been completed (passed their required coin threshold)
class GameProgressService {
  static const String _keyTotalCoins = 'total_coins';
  static const String _keyUnlockedRounds = 'unlocked_rounds';
  static const String _keyCompletedRounds = 'completed_rounds';

  static GameProgressService? _instance;
  static GameProgressService get instance {
    _instance ??= GameProgressService._();
    return _instance!;
  }

  GameProgressService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    // Ensure rounds 1 and 2 are always unlocked
    final unlocked = getUnlockedRounds();
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
      await _prefs!.setString(_keyUnlockedRounds, _encodeList(unlocked));
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

  List<int> getUnlockedRounds() {
    final raw = _prefs?.getString(_keyUnlockedRounds) ?? '1,2';
    return _decodeList(raw);
  }

  bool isRoundUnlocked(int round) {
    return getUnlockedRounds().contains(round);
  }

  List<int> getCompletedRounds() {
    final raw = _prefs?.getString(_keyCompletedRounds) ?? '';
    if (raw.isEmpty) return [];
    return _decodeList(raw);
  }

  bool isRoundCompleted(int round) {
    return getCompletedRounds().contains(round);
  }

  /// Marks a round as completed and unlocks the next one.
  Future<void> completeRound(int round) async {
    final completed = getCompletedRounds();
    if (!completed.contains(round)) {
      completed.add(round);
      await _prefs?.setString(_keyCompletedRounds, _encodeList(completed));
    }

    // Unlock the next round
    final nextRound = round + 1;
    if (nextRound <= 10) {
      await unlockRound(nextRound);
    }
  }

  Future<void> unlockRound(int round) async {
    final unlocked = getUnlockedRounds();
    if (!unlocked.contains(round)) {
      unlocked.add(round);
      await _prefs?.setString(_keyUnlockedRounds, _encodeList(unlocked));
    }
  }

  // ── Internal helpers ─────────────────────────────────────────────────────

  String _encodeList(List<int> list) => list.join(',');

  List<int> _decodeList(String raw) {
    if (raw.isEmpty) return [];
    return raw.split(',').map((e) => int.tryParse(e.trim()) ?? 0).where((e) => e > 0).toList();
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/gate_config.dart';
import '../models/map_theme.dart';
import '../models/round_config.dart';
import '../models/upgrade_config.dart';
import 'analytics_service.dart';

/// Handles persistent local game progress:
/// - Total coins collected across all runs (spendable)
/// - Which rounds are unlocked / completed, per map
/// - Which coin "gates" have been paid (see [isGatePaid])
/// - Which vehicles the player owns
class GameProgressService {
  static const String _keyTotalCoins = 'total_coins';
  static const String _keySelectedVehicle = 'selected_vehicle';
  static const String _keyOwnedVehicles = 'owned_vehicles';
  static const String _keyPaidGates = 'paid_gates';

  /// Vehicles the player starts with for free. Everything else must be bought.
  static const Set<String> _defaultOwnedVehicles = {'buggy'};

  static GameProgressService? _instance;
  static GameProgressService get instance {
    _instance ??= GameProgressService._();
    return _instance!;
  }

  GameProgressService._();

  SharedPreferences? _prefs;

  /// Live coin balance — lets widgets (garage, levels header) rebuild the
  /// moment coins are earned or spent without threading callbacks around.
  final ValueNotifier<int> coinsNotifier = ValueNotifier(0);

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    // Only Garagum starts with rounds 1 & 2 open. The other maps stay locked
    // until their map-unlock gate is paid (see BIZNES_MEYILNAMA_hasap_60tur.md).
    final garagum = getUnlockedRounds(MapTheme.garagum);
    bool changed = false;
    for (final r in [1, 2]) {
      if (!garagum.contains(r)) {
        garagum.add(r);
        changed = true;
      }
    }
    if (changed) {
      await _prefs!
          .setString(_unlockedKey(MapTheme.garagum), _encodeList(garagum));
    }
    coinsNotifier.value = getTotalCoins();
  }

  // ── Coins ────────────────────────────────────────────────────────────────

  int getTotalCoins() {
    return _prefs?.getInt(_keyTotalCoins) ?? 0;
  }

  Future<void> addCoins(int amount) async {
    final current = getTotalCoins();
    final next = current + amount;
    await _prefs?.setInt(_keyTotalCoins, next);
    coinsNotifier.value = next;
  }

  /// Attempts to spend [amount] coins. Returns false (and changes nothing) if
  /// the balance is insufficient.
  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return true;
    final current = getTotalCoins();
    if (current < amount) return false;
    final next = current - amount;
    await _prefs?.setInt(_keyTotalCoins, next);
    coinsNotifier.value = next;
    return true;
  }

  // ── Vehicles ──────────────────────────────────────────────────────────────

  String getSelectedVehicle() {
    return _prefs?.getString(_keySelectedVehicle) ?? 'buggy';
  }

  Future<void> setSelectedVehicle(String vehicleId) async {
    await _prefs?.setString(_keySelectedVehicle, vehicleId);
  }

  Set<String> getOwnedVehicles() {
    final raw = _prefs?.getStringList(_keyOwnedVehicles) ?? const [];
    return {..._defaultOwnedVehicles, ...raw};
  }

  bool isVehicleOwned(String vehicleId) =>
      getOwnedVehicles().contains(vehicleId);

  Future<void> ownVehicle(String vehicleId) async {
    final wasOwned = isVehicleOwned(vehicleId);
    final owned = getOwnedVehicles()..add(vehicleId);
    // Persist only the non-default ids to keep the stored list minimal.
    final toStore =
        owned.where((v) => !_defaultOwnedVehicles.contains(v)).toList();
    await _prefs?.setStringList(_keyOwnedVehicles, toStore);
    if (!wasOwned) AnalyticsService.instance.logVehicleUnlocked(vehicleId);
  }

  // ── Vehicle upgrades ──────────────────────────────────────────────────────

  String _upgradeKey(String vehicleId, UpgradeType type) =>
      'upg_${vehicleId}_${type.id}';

  int getUpgradeLevel(String vehicleId, UpgradeType type) =>
      _prefs?.getInt(_upgradeKey(vehicleId, type)) ?? 0;

  /// Buys the next upgrade level for [type] on [vehicleId]. Returns true on
  /// success; false if already maxed or the balance is insufficient.
  Future<bool> buyUpgrade(String vehicleId, UpgradeType type) async {
    final level = getUpgradeLevel(vehicleId, type);
    final cost = UpgradeConfig.costToNext(type, level);
    if (cost == null) return false; // maxed
    if (!await spendCoins(cost)) return false;
    await _prefs?.setInt(_upgradeKey(vehicleId, type), level + 1);
    return true;
  }

  /// The vehicle's effective 0..1 rating for [type] after its bought upgrades.
  double effectiveStat(String vehicleId, UpgradeType type, double baseStat) =>
      UpgradeConfig.apply(baseStat, getUpgradeLevel(vehicleId, type));

  // ── Rewarded "watch ad for coins" (coin store) ────────────────────────────

  static const int rewardAdCoins = 300;
  static const int rewardAdDailyCap = 6;
  static const String _keyRewardAdDate = 'reward_ad_date';
  static const String _keyRewardAdCount = 'reward_ad_count';

  /// How many reward-for-coins ads have been claimed today (resets each day).
  int rewardAdsUsedToday() {
    if (_prefs?.getString(_keyRewardAdDate) != _dayStamp(DateTime.now())) {
      return 0;
    }
    return _prefs?.getInt(_keyRewardAdCount) ?? 0;
  }

  int get rewardAdsRemainingToday =>
      (rewardAdDailyCap - rewardAdsUsedToday()).clamp(0, rewardAdDailyCap);

  bool get canWatchRewardForCoins => rewardAdsRemainingToday > 0;

  /// Grants the coin reward for one watched ad, subject to the daily cap.
  /// Returns the coins granted (0 if the cap is already reached).
  Future<int> claimRewardAdCoins() async {
    final today = _dayStamp(DateTime.now());
    final used = rewardAdsUsedToday();
    if (used >= rewardAdDailyCap) return 0;
    await _prefs?.setString(_keyRewardAdDate, today);
    await _prefs?.setInt(_keyRewardAdCount, used + 1);
    await addCoins(rewardAdCoins);
    AnalyticsService.instance.logRewardedEarned(rewardAdCoins);
    return rewardAdCoins;
  }

  // ── VIP daily coins & Starter pack ────────────────────────────────────────

  static const String _keyLastVipClaim = 'vip_last_claim';
  static const String _keyStarterNoAdsUntil = 'starter_no_ads_until';
  static const String _keyStarterGranted = 'starter_granted';
  static const int vipDailyCoins = 5000;

  String _todayStamp() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// Grants the VIP daily coin bonus once per calendar day while [isVip].
  /// Returns the coins granted (0 if not VIP or already claimed today).
  Future<int> claimVipDailyIfDue(bool isVip) async {
    if (!isVip) return 0;
    final today = _todayStamp();
    if (_prefs?.getString(_keyLastVipClaim) == today) return 0;
    await _prefs?.setString(_keyLastVipClaim, today);
    await addCoins(vipDailyCoins);
    return vipDailyCoins;
  }

  /// Whether the player has ever bought the starter pack (so the one-time
  /// offer isn't shown again).
  bool get starterGranted => _prefs?.getBool(_keyStarterGranted) ?? false;

  /// The 3-day ad-free window granted by the starter pack, still active?
  bool get starterNoAdsActive {
    final until = _prefs?.getInt(_keyStarterNoAdsUntil) ?? 0;
    return DateTime.now().millisecondsSinceEpoch < until;
  }

  /// Grants the starter pack: 25 000 coins, the UAZ, and a 3-day ad-free
  /// window. Idempotent — only pays out the first time.
  Future<void> grantStarterPack() async {
    if (starterGranted) return;
    await _prefs?.setBool(_keyStarterGranted, true);
    await addCoins(25000);
    await ownVehicle('uaz');
    final until = DateTime.now()
        .add(const Duration(days: 3))
        .millisecondsSinceEpoch;
    await _prefs?.setInt(_keyStarterNoAdsUntil, until);
  }

  // ── Daily reward + streak ─────────────────────────────────────────────────

  static const String _keyLastDailyClaim = 'daily_last_claim';
  static const String _keyStreakDay = 'daily_streak';
  static const int streakCap = 7;

  /// Coin reward for each streak day (1..7). Day 7 is the big payout, which is
  /// what keeps players coming back a full week.
  static const List<int> dailyRewards = [500, 800, 1200, 1600, 2200, 3000, 5000];

  String _dayStamp(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// True if today's daily reward hasn't been claimed yet.
  bool get canClaimDaily =>
      _prefs?.getString(_keyLastDailyClaim) != _dayStamp(DateTime.now());

  /// The streak day that claiming right now would land on (1..7): continues
  /// the run if yesterday was claimed, otherwise resets to 1.
  int get pendingStreakDay {
    final last = _prefs?.getString(_keyLastDailyClaim);
    final yesterday = _dayStamp(DateTime.now().subtract(const Duration(days: 1)));
    final stored = _prefs?.getInt(_keyStreakDay) ?? 0;
    if (last == yesterday) return (stored + 1).clamp(1, streakCap);
    return 1;
  }

  /// The reward the player would get by claiming now.
  int get pendingDailyReward => dailyRewards[pendingStreakDay - 1];

  /// The stored streak day (last claimed day's position, 1..7; 0 if never).
  int get currentStreakDay => _prefs?.getInt(_keyStreakDay) ?? 0;

  /// Claims today's daily reward. Returns the coins granted, or 0 if already
  /// claimed today.
  Future<int> claimDailyReward() async {
    if (!canClaimDaily) return 0;
    final day = pendingStreakDay;
    final reward = dailyRewards[day - 1];
    await _prefs?.setInt(_keyStreakDay, day);
    await _prefs?.setString(_keyLastDailyClaim, _dayStamp(DateTime.now()));
    await addCoins(reward);
    return reward;
  }

  // ── Stars (1–3 per round, best kept) ──────────────────────────────────────

  String _starsKey(MapTheme theme, int round) => 'stars_${theme.name}_$round';

  /// Best star count earned on this round so far (0 = not yet earned any).
  int getStars(MapTheme theme, int round) =>
      _prefs?.getInt(_starsKey(theme, round)) ?? 0;

  /// Records [stars] for a round if it beats the stored best, and awards a
  /// one-time coin bonus for each newly-crossed star tier (⭐⭐ = +5% of the
  /// round's road coins, ⭐⭐⭐ = a further +10%). Returns the coin bonus paid.
  Future<int> recordStars(MapTheme theme, int round, int stars, int roadCoins) async {
    final old = getStars(theme, round);
    if (stars <= old) return 0;
    await _prefs?.setInt(_starsKey(theme, round), stars);
    final bonus = _starBonus(stars, roadCoins) - _starBonus(old, roadCoins);
    if (bonus > 0) await addCoins(bonus);
    return bonus > 0 ? bonus : 0;
  }

  /// Cumulative coin bonus for reaching [stars]: 0 for ⭐, +5% at ⭐⭐,
  /// +15% total at ⭐⭐⭐.
  int _starBonus(int stars, int roadCoins) {
    if (stars >= 3) return (roadCoins * 0.15).floor();
    if (stars >= 2) return (roadCoins * 0.05).floor();
    return 0;
  }

  // ── Gates (coin walls that unlock rounds / maps) ──────────────────────────

  String _gateToken(MapTheme theme, int round) => '${theme.name}:$round';

  bool isGatePaid(MapTheme theme, int round) {
    final paid = _prefs?.getStringList(_keyPaidGates) ?? const [];
    return paid.contains(_gateToken(theme, round));
  }

  Future<void> markGatePaid(MapTheme theme, int round) async {
    final paid = _prefs?.getStringList(_keyPaidGates) ?? <String>[];
    final token = _gateToken(theme, round);
    if (!paid.contains(token)) {
      paid.add(token);
      await _prefs?.setStringList(_keyPaidGates, paid);
    }
  }

  /// The next gate the player is saving toward (first unpaid gate in global
  /// play order), or null once every gate is paid. Powers the "az galdy"
  /// progress bar on the result screen.
  GateInfo? nextUnpaidGate() {
    for (final gate in GateConfig.orderedGates) {
      if (!isGatePaid(gate.theme, gate.round)) return gate;
    }
    return null;
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
    final fallback = theme == MapTheme.garagum ? '1,2' : '';
    final raw = _prefs?.getString(_unlockedKey(theme)) ?? fallback;
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
      AnalyticsService.instance.logLevelUnlocked('${theme.name}_$round');
    }
  }

  // ── Internal helpers ─────────────────────────────────────────────────────

  String _encodeList(List<int> list) => list.join(',');

  List<int> _decodeList(String raw) {
    if (raw.isEmpty) return [];
    return raw
        .split(',')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((e) => e > 0)
        .toList();
  }
}

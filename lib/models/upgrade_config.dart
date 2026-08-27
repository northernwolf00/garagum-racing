/// The four upgradeable vehicle stats.
enum UpgradeType { engine, suspension, tires, fuel }

extension UpgradeTypeInfo on UpgradeType {
  /// Persistence key fragment — must stay stable across releases.
  String get id => name;

  String get label {
    switch (this) {
      case UpgradeType.engine:
        return 'Motor';
      case UpgradeType.suspension:
        return 'Asma';
      case UpgradeType.tires:
        return 'Tekerler';
      case UpgradeType.fuel:
        return 'Ýangyç tanky';
    }
  }
}

/// Upgrade economy: 5 buyable levels per stat per vehicle. Each level nudges
/// the stat up by [statStep] (capped at 1.0), so a stronger base vehicle still
/// ends up ahead of a fully-upgraded weaker one — upgrades improve a car, they
/// don't flatten the roster. Costs and totals follow
/// `BIZNES_MEYILNAMA_hasap_60tur.md` (~80k to fully upgrade one vehicle).
class UpgradeConfig {
  const UpgradeConfig._();

  static const int maxLevel = 5;

  /// How much one level adds to a 0..1 stat rating.
  static const double statStep = 0.06;

  /// Per-level coin cost for each stat (index 0 = cost of level 1). Sums:
  /// engine 25 000 · suspension 18 000 · tires 16 000 · fuel 22 000 ≈ 81 000.
  static const Map<UpgradeType, List<int>> _costs = {
    UpgradeType.engine: [2500, 4000, 5000, 6500, 7000],
    UpgradeType.suspension: [1500, 2500, 3500, 4500, 6000],
    UpgradeType.tires: [1300, 2200, 3200, 4300, 5000],
    UpgradeType.fuel: [2000, 3500, 4500, 5500, 6500],
  };

  /// Coin cost to go from [currentLevel] to the next level, or null if the
  /// stat is already maxed.
  static int? costToNext(UpgradeType type, int currentLevel) {
    if (currentLevel >= maxLevel) return null;
    return _costs[type]![currentLevel];
  }

  /// Applies [level] upgrade steps to a base 0..1 [baseStat], capped at 1.0.
  static double apply(double baseStat, int level) {
    final v = baseStat + level * statStep;
    return v > 1.0 ? 1.0 : v;
  }
}

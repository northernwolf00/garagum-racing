import 'map_theme.dart';

/// Configuration data for one racing round (tur).
/// Defines the distance goal, coins available, required coins to pass, and
/// the obstacle density multiplier which scales difficulty progressively.
class RoundConfig {
  const RoundConfig({
    required this.roundIndex,
    required this.distanceMeters,
    required this.totalCoins,
    required this.requiredCoins,
    required this.obstacleFrequency,
    this.theme = MapTheme.garagum,
  });

  /// 1-based round number within its map.
  final int roundIndex;

  /// Distance the player must reach to complete the round (in meters).
  final double distanceMeters;

  /// Total coins placed on the road in this round.
  final int totalCoins;

  /// Minimum coins the player must collect to count as passing the round.
  final int requiredCoins;

  /// Obstacle spawn frequency multiplier. 1.0 = base. Higher = more obstacles.
  final double obstacleFrequency;

  /// Which map/art-set this round belongs to.
  final MapTheme theme;

  String get title => 'Tur $roundIndex';
  String get subtitle =>
      '${distanceMeters.toInt()} m · $requiredCoins coin gerek';

  /// Total round count for a given map — used to cap "unlock next round"
  /// logic and to render "TUR n / total" labels.
  static int totalRoundsFor(MapTheme theme) {
    switch (theme) {
      case MapTheme.garagum:
        return all.length;
      case MapTheme.ashgabat:
        return ashgabatAll.length;
    }
  }

  static const List<RoundConfig> all = [
    RoundConfig(
      roundIndex: 1,
      distanceMeters: 150,
      totalCoins: 15,
      requiredCoins: 8,
      obstacleFrequency: 0.5,
    ),
    RoundConfig(
      roundIndex: 2,
      distanceMeters: 250,
      totalCoins: 26,
      requiredCoins: 14,
      obstacleFrequency: 0.7,
    ),
    RoundConfig(
      roundIndex: 3,
      distanceMeters: 350,
      totalCoins: 40,
      requiredCoins: 22,
      obstacleFrequency: 0.85,
    ),
    RoundConfig(
      roundIndex: 4,
      distanceMeters: 450,
      totalCoins: 55,
      requiredCoins: 30,
      obstacleFrequency: 1.0,
    ),
    RoundConfig(
      roundIndex: 5,
      distanceMeters: 550,
      totalCoins: 72,
      requiredCoins: 40,
      obstacleFrequency: 1.15,
    ),
    RoundConfig(
      roundIndex: 6,
      distanceMeters: 650,
      totalCoins: 92,
      requiredCoins: 50,
      obstacleFrequency: 1.3,
    ),
    RoundConfig(
      roundIndex: 7,
      distanceMeters: 750,
      totalCoins: 115,
      requiredCoins: 64,
      obstacleFrequency: 1.5,
    ),
    RoundConfig(
      roundIndex: 8,
      distanceMeters: 900,
      totalCoins: 142,
      requiredCoins: 78,
      obstacleFrequency: 1.7,
    ),
    RoundConfig(
      roundIndex: 9,
      distanceMeters: 1100,
      totalCoins: 175,
      requiredCoins: 96,
      obstacleFrequency: 2.0,
    ),
    RoundConfig(
      roundIndex: 10,
      distanceMeters: 1500,
      totalCoins: 220,
      requiredCoins: 120,
      obstacleFrequency: 2.5,
    ),
  ];

  /// Aşgabat şäher kartasy — 15 tur, has a longer, gentler progression than
  /// Garagum's 10 to give the extra rounds room to ramp up.
  static const List<RoundConfig> ashgabatAll = [
    RoundConfig(
      roundIndex: 1,
      distanceMeters: 150,
      totalCoins: 15,
      requiredCoins: 8,
      obstacleFrequency: 0.5,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 2,
      distanceMeters: 230,
      totalCoins: 24,
      requiredCoins: 13,
      obstacleFrequency: 0.65,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 3,
      distanceMeters: 310,
      totalCoins: 34,
      requiredCoins: 19,
      obstacleFrequency: 0.8,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 4,
      distanceMeters: 390,
      totalCoins: 45,
      requiredCoins: 25,
      obstacleFrequency: 0.95,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 5,
      distanceMeters: 470,
      totalCoins: 58,
      requiredCoins: 32,
      obstacleFrequency: 1.1,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 6,
      distanceMeters: 560,
      totalCoins: 72,
      requiredCoins: 40,
      obstacleFrequency: 1.25,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 7,
      distanceMeters: 650,
      totalCoins: 88,
      requiredCoins: 49,
      obstacleFrequency: 1.4,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 8,
      distanceMeters: 750,
      totalCoins: 106,
      requiredCoins: 59,
      obstacleFrequency: 1.55,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 9,
      distanceMeters: 860,
      totalCoins: 126,
      requiredCoins: 70,
      obstacleFrequency: 1.7,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 10,
      distanceMeters: 980,
      totalCoins: 148,
      requiredCoins: 82,
      obstacleFrequency: 1.85,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 11,
      distanceMeters: 1110,
      totalCoins: 172,
      requiredCoins: 95,
      obstacleFrequency: 2.0,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 12,
      distanceMeters: 1260,
      totalCoins: 198,
      requiredCoins: 110,
      obstacleFrequency: 2.2,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 13,
      distanceMeters: 1430,
      totalCoins: 226,
      requiredCoins: 126,
      obstacleFrequency: 2.4,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 14,
      distanceMeters: 1620,
      totalCoins: 256,
      requiredCoins: 143,
      obstacleFrequency: 2.6,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 15,
      distanceMeters: 1850,
      totalCoins: 290,
      requiredCoins: 162,
      obstacleFrequency: 2.85,
      theme: MapTheme.ashgabat,
    ),
  ];
}

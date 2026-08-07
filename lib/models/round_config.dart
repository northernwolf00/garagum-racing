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
      case MapTheme.yangykala:
        return yangykalaAll.length;
      case MapTheme.derweze:
        return derwezeAll.length;
    }
  }

  static const List<RoundConfig> all = [
    RoundConfig(
      roundIndex: 1,
      distanceMeters: 430,
      totalCoins: 43,
      requiredCoins: 22,
      obstacleFrequency: 0.5,
    ),
    RoundConfig(
      roundIndex: 2,
      distanceMeters: 720,
      totalCoins: 75,
      requiredCoins: 40,
      obstacleFrequency: 0.7,
    ),
    RoundConfig(
      roundIndex: 3,
      distanceMeters: 1010,
      totalCoins: 115,
      requiredCoins: 64,
      obstacleFrequency: 0.85,
    ),
    RoundConfig(
      roundIndex: 4,
      distanceMeters: 1300,
      totalCoins: 158,
      requiredCoins: 86,
      obstacleFrequency: 1.0,
    ),
    RoundConfig(
      roundIndex: 5,
      distanceMeters: 1580,
      totalCoins: 208,
      requiredCoins: 115,
      obstacleFrequency: 1.15,
    ),
    RoundConfig(
      roundIndex: 6,
      distanceMeters: 1870,
      totalCoins: 266,
      requiredCoins: 144,
      obstacleFrequency: 1.3,
    ),
    RoundConfig(
      roundIndex: 7,
      distanceMeters: 2160,
      totalCoins: 331,
      requiredCoins: 184,
      obstacleFrequency: 1.5,
    ),
    RoundConfig(
      roundIndex: 8,
      distanceMeters: 2590,
      totalCoins: 410,
      requiredCoins: 224,
      obstacleFrequency: 1.7,
    ),
    RoundConfig(
      roundIndex: 9,
      distanceMeters: 3170,
      totalCoins: 504,
      requiredCoins: 277,
      obstacleFrequency: 2.0,
    ),
    RoundConfig(
      roundIndex: 10,
      distanceMeters: 4320,
      totalCoins: 634,
      requiredCoins: 346,
      obstacleFrequency: 2.5,
    ),
  ];

  /// Aşgabat şäher kartasy — 15 tur, has a longer, gentler progression than
  /// Garagum's 10 to give the extra rounds room to ramp up.
  static const List<RoundConfig> ashgabatAll = [
    RoundConfig(
      roundIndex: 1,
      distanceMeters: 430,
      totalCoins: 43,
      requiredCoins: 22,
      obstacleFrequency: 0.5,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 2,
      distanceMeters: 660,
      totalCoins: 69,
      requiredCoins: 37,
      obstacleFrequency: 0.65,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 3,
      distanceMeters: 900,
      totalCoins: 98,
      requiredCoins: 54,
      obstacleFrequency: 0.8,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 4,
      distanceMeters: 1120,
      totalCoins: 130,
      requiredCoins: 72,
      obstacleFrequency: 0.95,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 5,
      distanceMeters: 1360,
      totalCoins: 166,
      requiredCoins: 93,
      obstacleFrequency: 1.1,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 6,
      distanceMeters: 1620,
      totalCoins: 208,
      requiredCoins: 115,
      obstacleFrequency: 1.25,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 7,
      distanceMeters: 1870,
      totalCoins: 253,
      requiredCoins: 141,
      obstacleFrequency: 1.4,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 8,
      distanceMeters: 2160,
      totalCoins: 306,
      requiredCoins: 170,
      obstacleFrequency: 1.55,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 9,
      distanceMeters: 2480,
      totalCoins: 363,
      requiredCoins: 202,
      obstacleFrequency: 1.7,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 10,
      distanceMeters: 2820,
      totalCoins: 426,
      requiredCoins: 237,
      obstacleFrequency: 1.85,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 11,
      distanceMeters: 3200,
      totalCoins: 496,
      requiredCoins: 274,
      obstacleFrequency: 2.0,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 12,
      distanceMeters: 3630,
      totalCoins: 570,
      requiredCoins: 317,
      obstacleFrequency: 2.2,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 13,
      distanceMeters: 4110,
      totalCoins: 651,
      requiredCoins: 363,
      obstacleFrequency: 2.4,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 14,
      distanceMeters: 4670,
      totalCoins: 738,
      requiredCoins: 411,
      obstacleFrequency: 2.6,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 15,
      distanceMeters: 5330,
      totalCoins: 835,
      requiredCoins: 467,
      obstacleFrequency: 2.85,
      theme: MapTheme.ashgabat,
    ),
  ];

  /// Ýaňňykala canyon map — 15 tur, jump ramps and cliff gap challenges.
  static const List<RoundConfig> yangykalaAll = [
    RoundConfig(
      roundIndex: 1,
      distanceMeters: 460,
      totalCoins: 46,
      requiredCoins: 26,
      obstacleFrequency: 0.5,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 2,
      distanceMeters: 690,
      totalCoins: 72,
      requiredCoins: 40,
      obstacleFrequency: 0.65,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 3,
      distanceMeters: 930,
      totalCoins: 101,
      requiredCoins: 58,
      obstacleFrequency: 0.8,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 4,
      distanceMeters: 1150,
      totalCoins: 133,
      requiredCoins: 75,
      obstacleFrequency: 0.95,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 5,
      distanceMeters: 1380,
      totalCoins: 173,
      requiredCoins: 94,
      obstacleFrequency: 1.1,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 6,
      distanceMeters: 1650,
      totalCoins: 213,
      requiredCoins: 118,
      obstacleFrequency: 1.25,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 7,
      distanceMeters: 1900,
      totalCoins: 259,
      requiredCoins: 144,
      obstacleFrequency: 1.4,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 8,
      distanceMeters: 2190,
      totalCoins: 310,
      requiredCoins: 173,
      obstacleFrequency: 1.55,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 9,
      distanceMeters: 2510,
      totalCoins: 368,
      requiredCoins: 205,
      obstacleFrequency: 1.7,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 10,
      distanceMeters: 2850,
      totalCoins: 432,
      requiredCoins: 238,
      obstacleFrequency: 1.85,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 11,
      distanceMeters: 3230,
      totalCoins: 504,
      requiredCoins: 280,
      obstacleFrequency: 2.0,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 12,
      distanceMeters: 3660,
      totalCoins: 576,
      requiredCoins: 323,
      obstacleFrequency: 2.2,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 13,
      distanceMeters: 4140,
      totalCoins: 662,
      requiredCoins: 368,
      obstacleFrequency: 2.4,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 14,
      distanceMeters: 4690,
      totalCoins: 749,
      requiredCoins: 418,
      obstacleFrequency: 2.6,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 15,
      distanceMeters: 5410,
      totalCoins: 850,
      requiredCoins: 475,
      obstacleFrequency: 2.85,
      theme: MapTheme.yangykala,
    ),
  ];

  /// Derweze gas crater map — 15 tur, night desert with glowing crater & obstacles.
  static const List<RoundConfig> derwezeAll = [
    RoundConfig(
      roundIndex: 1,
      distanceMeters: 430,
      totalCoins: 43,
      requiredCoins: 22,
      obstacleFrequency: 0.5,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 2,
      distanceMeters: 660,
      totalCoins: 69,
      requiredCoins: 37,
      obstacleFrequency: 0.65,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 3,
      distanceMeters: 900,
      totalCoins: 98,
      requiredCoins: 54,
      obstacleFrequency: 0.8,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 4,
      distanceMeters: 1120,
      totalCoins: 130,
      requiredCoins: 72,
      obstacleFrequency: 0.95,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 5,
      distanceMeters: 1360,
      totalCoins: 166,
      requiredCoins: 93,
      obstacleFrequency: 1.1,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 6,
      distanceMeters: 1620,
      totalCoins: 208,
      requiredCoins: 115,
      obstacleFrequency: 1.25,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 7,
      distanceMeters: 1870,
      totalCoins: 253,
      requiredCoins: 141,
      obstacleFrequency: 1.4,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 8,
      distanceMeters: 2160,
      totalCoins: 306,
      requiredCoins: 170,
      obstacleFrequency: 1.55,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 9,
      distanceMeters: 2480,
      totalCoins: 363,
      requiredCoins: 202,
      obstacleFrequency: 1.7,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 10,
      distanceMeters: 2820,
      totalCoins: 426,
      requiredCoins: 237,
      obstacleFrequency: 1.85,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 11,
      distanceMeters: 3200,
      totalCoins: 496,
      requiredCoins: 274,
      obstacleFrequency: 2.0,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 12,
      distanceMeters: 3630,
      totalCoins: 570,
      requiredCoins: 317,
      obstacleFrequency: 2.2,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 13,
      distanceMeters: 4110,
      totalCoins: 651,
      requiredCoins: 363,
      obstacleFrequency: 2.4,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 14,
      distanceMeters: 4670,
      totalCoins: 738,
      requiredCoins: 411,
      obstacleFrequency: 2.6,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 15,
      distanceMeters: 5330,
      totalCoins: 835,
      requiredCoins: 467,
      obstacleFrequency: 2.85,
      theme: MapTheme.derweze,
    ),
  ];
}

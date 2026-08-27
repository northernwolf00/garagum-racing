import 'map_theme.dart';

/// Configuration data for one racing round (tur).
/// Defines the distance goal, coins available, required coins to pass, and
/// the obstacle density multiplier which scales difficulty progressively.
///
/// Coin values ramp **continuously across all 60 rounds** (4 maps × 15) rather
/// than resetting each map, so later maps genuinely pay more per run and the
/// larger map-unlock gates stay reachable. See `BIZNES_MEYILNAMA_hasap_60tur.md`
/// for the full economy model behind these numbers.
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

  /// Returns the round list for a given map theme.
  static List<RoundConfig> roundsFor(MapTheme theme) {
    switch (theme) {
      case MapTheme.garagum:
        return all;
      case MapTheme.ashgabat:
        return ashgabatAll;
      case MapTheme.yangykala:
        return yangykalaAll;
      case MapTheme.derweze:
        return derwezeAll;
    }
  }

  /// Returns the RoundConfig for a specific theme and 1-based roundIndex, or null.
  static RoundConfig? getRound(MapTheme theme, int roundIndex) {
    final list = roundsFor(theme);
    final idx = roundIndex - 1;
    if (idx >= 0 && idx < list.length) {
      return list[idx];
    }
    return null;
  }

  /// Total round count for a given map — used to cap "unlock next round"
  /// logic and to render "TUR n / total" labels.
  static int totalRoundsFor(MapTheme theme) {
    return roundsFor(theme).length;
  }

  /// Garagum çöl kartasy — 15 tur (öň 10 turdy, ykdysadyýet üçin 15-e deňlendi).
  static const List<RoundConfig> all = [
    RoundConfig(
      roundIndex: 1,
      distanceMeters: 430,
      totalCoins: 140,
      requiredCoins: 77,
      obstacleFrequency: 0.5,
    ),
    RoundConfig(
      roundIndex: 2,
      distanceMeters: 720,
      totalCoins: 155,
      requiredCoins: 85,
      obstacleFrequency: 0.7,
    ),
    RoundConfig(
      roundIndex: 3,
      distanceMeters: 1010,
      totalCoins: 170,
      requiredCoins: 94,
      obstacleFrequency: 0.85,
    ),
    RoundConfig(
      roundIndex: 4,
      distanceMeters: 1300,
      totalCoins: 180,
      requiredCoins: 99,
      obstacleFrequency: 1.0,
    ),
    RoundConfig(
      roundIndex: 5,
      distanceMeters: 1580,
      totalCoins: 195,
      requiredCoins: 107,
      obstacleFrequency: 1.15,
    ),
    RoundConfig(
      roundIndex: 6,
      distanceMeters: 1870,
      totalCoins: 210,
      requiredCoins: 116,
      obstacleFrequency: 1.3,
    ),
    RoundConfig(
      roundIndex: 7,
      distanceMeters: 2160,
      totalCoins: 235,
      requiredCoins: 129,
      obstacleFrequency: 1.5,
    ),
    RoundConfig(
      roundIndex: 8,
      distanceMeters: 2590,
      totalCoins: 260,
      requiredCoins: 143,
      obstacleFrequency: 1.7,
    ),
    RoundConfig(
      roundIndex: 9,
      distanceMeters: 3170,
      totalCoins: 285,
      requiredCoins: 157,
      obstacleFrequency: 2.0,
    ),
    RoundConfig(
      roundIndex: 10,
      distanceMeters: 4320,
      totalCoins: 310,
      requiredCoins: 170,
      obstacleFrequency: 2.5,
    ),
    RoundConfig(
      roundIndex: 11,
      distanceMeters: 4700,
      totalCoins: 335,
      requiredCoins: 184,
      obstacleFrequency: 2.65,
    ),
    RoundConfig(
      roundIndex: 12,
      distanceMeters: 5100,
      totalCoins: 360,
      requiredCoins: 198,
      obstacleFrequency: 2.8,
    ),
    RoundConfig(
      roundIndex: 13,
      distanceMeters: 5550,
      totalCoins: 380,
      requiredCoins: 209,
      obstacleFrequency: 2.9,
    ),
    RoundConfig(
      roundIndex: 14,
      distanceMeters: 6050,
      totalCoins: 405,
      requiredCoins: 223,
      obstacleFrequency: 3.0,
    ),
    RoundConfig(
      roundIndex: 15,
      distanceMeters: 6600,
      totalCoins: 430,
      requiredCoins: 237,
      obstacleFrequency: 3.1,
    ),
  ];

  /// Aşgabat şäher kartasy — 15 tur (global 16–30).
  static const List<RoundConfig> ashgabatAll = [
    RoundConfig(
      roundIndex: 1,
      distanceMeters: 430,
      totalCoins: 435,
      requiredCoins: 239,
      obstacleFrequency: 0.5,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 2,
      distanceMeters: 660,
      totalCoins: 455,
      requiredCoins: 250,
      obstacleFrequency: 0.65,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 3,
      distanceMeters: 900,
      totalCoins: 475,
      requiredCoins: 261,
      obstacleFrequency: 0.8,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 4,
      distanceMeters: 1120,
      totalCoins: 500,
      requiredCoins: 275,
      obstacleFrequency: 0.95,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 5,
      distanceMeters: 1360,
      totalCoins: 520,
      requiredCoins: 286,
      obstacleFrequency: 1.1,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 6,
      distanceMeters: 1620,
      totalCoins: 540,
      requiredCoins: 297,
      obstacleFrequency: 1.25,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 7,
      distanceMeters: 1870,
      totalCoins: 560,
      requiredCoins: 308,
      obstacleFrequency: 1.4,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 8,
      distanceMeters: 2160,
      totalCoins: 580,
      requiredCoins: 319,
      obstacleFrequency: 1.55,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 9,
      distanceMeters: 2480,
      totalCoins: 605,
      requiredCoins: 333,
      obstacleFrequency: 1.7,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 10,
      distanceMeters: 2820,
      totalCoins: 625,
      requiredCoins: 344,
      obstacleFrequency: 1.85,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 11,
      distanceMeters: 3200,
      totalCoins: 645,
      requiredCoins: 355,
      obstacleFrequency: 2.0,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 12,
      distanceMeters: 3630,
      totalCoins: 665,
      requiredCoins: 366,
      obstacleFrequency: 2.2,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 13,
      distanceMeters: 4110,
      totalCoins: 690,
      requiredCoins: 380,
      obstacleFrequency: 2.4,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 14,
      distanceMeters: 4670,
      totalCoins: 710,
      requiredCoins: 391,
      obstacleFrequency: 2.6,
      theme: MapTheme.ashgabat,
    ),
    RoundConfig(
      roundIndex: 15,
      distanceMeters: 5330,
      totalCoins: 730,
      requiredCoins: 402,
      obstacleFrequency: 2.85,
      theme: MapTheme.ashgabat,
    ),
  ];

  /// Ýaňňykala kanýon kartasy — 15 tur (global 31–45).
  static const List<RoundConfig> yangykalaAll = [
    RoundConfig(
      roundIndex: 1,
      distanceMeters: 460,
      totalCoins: 760,
      requiredCoins: 418,
      obstacleFrequency: 0.5,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 2,
      distanceMeters: 690,
      totalCoins: 785,
      requiredCoins: 432,
      obstacleFrequency: 0.65,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 3,
      distanceMeters: 930,
      totalCoins: 815,
      requiredCoins: 448,
      obstacleFrequency: 0.8,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 4,
      distanceMeters: 1150,
      totalCoins: 840,
      requiredCoins: 462,
      obstacleFrequency: 0.95,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 5,
      distanceMeters: 1380,
      totalCoins: 870,
      requiredCoins: 479,
      obstacleFrequency: 1.1,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 6,
      distanceMeters: 1650,
      totalCoins: 900,
      requiredCoins: 495,
      obstacleFrequency: 1.25,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 7,
      distanceMeters: 1900,
      totalCoins: 925,
      requiredCoins: 509,
      obstacleFrequency: 1.4,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 8,
      distanceMeters: 2190,
      totalCoins: 955,
      requiredCoins: 525,
      obstacleFrequency: 1.55,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 9,
      distanceMeters: 2510,
      totalCoins: 980,
      requiredCoins: 539,
      obstacleFrequency: 1.7,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 10,
      distanceMeters: 2850,
      totalCoins: 1010,
      requiredCoins: 556,
      obstacleFrequency: 1.85,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 11,
      distanceMeters: 3230,
      totalCoins: 1040,
      requiredCoins: 572,
      obstacleFrequency: 2.0,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 12,
      distanceMeters: 3660,
      totalCoins: 1065,
      requiredCoins: 586,
      obstacleFrequency: 2.2,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 13,
      distanceMeters: 4140,
      totalCoins: 1095,
      requiredCoins: 602,
      obstacleFrequency: 2.4,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 14,
      distanceMeters: 4690,
      totalCoins: 1125,
      requiredCoins: 619,
      obstacleFrequency: 2.6,
      theme: MapTheme.yangykala,
    ),
    RoundConfig(
      roundIndex: 15,
      distanceMeters: 5410,
      totalCoins: 1150,
      requiredCoins: 632,
      obstacleFrequency: 2.85,
      theme: MapTheme.yangykala,
    ),
  ];

  /// Derweze gaz krateri kartasy — 15 tur (global 46–60).
  static const List<RoundConfig> derwezeAll = [
    RoundConfig(
      roundIndex: 1,
      distanceMeters: 430,
      totalCoins: 1180,
      requiredCoins: 649,
      obstacleFrequency: 0.5,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 2,
      distanceMeters: 660,
      totalCoins: 1220,
      requiredCoins: 671,
      obstacleFrequency: 0.65,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 3,
      distanceMeters: 900,
      totalCoins: 1255,
      requiredCoins: 690,
      obstacleFrequency: 0.8,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 4,
      distanceMeters: 1120,
      totalCoins: 1295,
      requiredCoins: 712,
      obstacleFrequency: 0.95,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 5,
      distanceMeters: 1360,
      totalCoins: 1335,
      requiredCoins: 734,
      obstacleFrequency: 1.1,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 6,
      distanceMeters: 1620,
      totalCoins: 1370,
      requiredCoins: 754,
      obstacleFrequency: 1.25,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 7,
      distanceMeters: 1870,
      totalCoins: 1410,
      requiredCoins: 776,
      obstacleFrequency: 1.4,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 8,
      distanceMeters: 2160,
      totalCoins: 1450,
      requiredCoins: 798,
      obstacleFrequency: 1.55,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 9,
      distanceMeters: 2480,
      totalCoins: 1490,
      requiredCoins: 820,
      obstacleFrequency: 1.7,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 10,
      distanceMeters: 2820,
      totalCoins: 1525,
      requiredCoins: 839,
      obstacleFrequency: 1.85,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 11,
      distanceMeters: 3200,
      totalCoins: 1565,
      requiredCoins: 861,
      obstacleFrequency: 2.0,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 12,
      distanceMeters: 3630,
      totalCoins: 1605,
      requiredCoins: 883,
      obstacleFrequency: 2.2,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 13,
      distanceMeters: 4110,
      totalCoins: 1640,
      requiredCoins: 902,
      obstacleFrequency: 2.4,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 14,
      distanceMeters: 4670,
      totalCoins: 1680,
      requiredCoins: 924,
      obstacleFrequency: 2.6,
      theme: MapTheme.derweze,
    ),
    RoundConfig(
      roundIndex: 15,
      distanceMeters: 5330,
      totalCoins: 1720,
      requiredCoins: 946,
      obstacleFrequency: 2.85,
      theme: MapTheme.derweze,
    ),
  ];
}

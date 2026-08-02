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
  });

  /// 1-based round number (1 to 10).
  final int roundIndex;

  /// Distance the player must reach to complete the round (in meters).
  final double distanceMeters;

  /// Total coins placed on the road in this round.
  final int totalCoins;

  /// Minimum coins the player must collect to count as passing the round.
  final int requiredCoins;

  /// Obstacle spawn frequency multiplier. 1.0 = base. Higher = more obstacles.
  final double obstacleFrequency;

  String get title => 'Tur $roundIndex';
  String get subtitle =>
      '${distanceMeters.toInt()} m · $requiredCoins coin gerek';

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
}

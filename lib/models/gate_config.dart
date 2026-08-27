import 'map_theme.dart';

/// Coin "gates" — the handful of rounds that cost accumulated coins to unlock,
/// as opposed to unlocking for free by completing the previous round.
///
/// Only **10** rounds are gated across the whole 60-round game (never every
/// round — that would just annoy the player). The three map-entry gates
/// (each map's round 1, except Garagum) are the big spends that unlock a whole
/// new map. See `BIZNES_MEYILNAMA_hasap_60tur.md` for the economy behind the
/// numbers.
class GateConfig {
  const GateConfig._();

  /// Gate cost keyed by (map, local round). A round not present here is free
  /// (unlocks by completing the previous round).
  static const Map<MapTheme, Map<int, int>> _gates = {
    MapTheme.garagum: {
      6: 600,
      11: 3500,
    },
    MapTheme.ashgabat: {
      1: 12000, // unlocks the Aşgabat map
      6: 26000,
      11: 48000,
    },
    MapTheme.yangykala: {
      1: 80000, // unlocks the Ýaňňykala map
      6: 120000,
      11: 165000,
    },
    MapTheme.derweze: {
      1: 230000, // unlocks the Derweze map
      6: 310000,
    },
  };

  /// The coin cost to unlock [round] on [theme], or null if the round has no
  /// gate.
  static int? costFor(MapTheme theme, int round) => _gates[theme]?[round];

  /// Whether [round] on [theme] is a paid gate at all.
  static bool isGate(MapTheme theme, int round) =>
      _gates[theme]?.containsKey(round) ?? false;

  /// True when this gate unlocks an entire map (its round 1). Used to show a
  /// bigger "unlock <map>" treatment in the UI.
  static bool isMapGate(MapTheme theme, int round) =>
      theme != MapTheme.garagum && round == 1 && isGate(theme, round);

  /// Every gate in global play order (Garagum → Aşgabat → Ýaňňykala → Derweze),
  /// used to find the next one the player is saving toward (the "az galdy"
  /// progress bar).
  static const List<MapTheme> _mapOrder = [
    MapTheme.garagum,
    MapTheme.ashgabat,
    MapTheme.yangykala,
    MapTheme.derweze,
  ];

  static List<GateInfo> get orderedGates {
    final list = <GateInfo>[];
    for (final theme in _mapOrder) {
      final gates = _gates[theme];
      if (gates == null) continue;
      final rounds = gates.keys.toList()..sort();
      for (final r in rounds) {
        list.add(GateInfo(theme: theme, round: r, cost: gates[r]!));
      }
    }
    return list;
  }
}

/// A single gate: which round it's on and what it costs.
class GateInfo {
  const GateInfo({required this.theme, required this.round, required this.cost});

  final MapTheme theme;
  final int round;
  final int cost;

  bool get isMapGate => GateConfig.isMapGate(theme, round);
}

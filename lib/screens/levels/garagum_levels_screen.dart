import 'package:flutter/material.dart';

import '../../models/map_theme.dart';
import '../../models/round_config.dart';
import 'levels_screen.dart';

/// Round-selection grid for the Garagum desert map (10 rounds).
class GaragumLevelsScreen extends StatelessWidget {
  const GaragumLevelsScreen({super.key});

  static const List<List<Color>> _palettes = [
    [Color(0xFFE8A33D), Color(0xFF8B4A1A)], // 1
    [Color(0xFFD4A017), Color(0xFF7A5500)], // 2
    [Color(0xFFD35400), Color(0xFF6E2C00)], // 3
    [Color(0xFFC0392B), Color(0xFF641E16)], // 4
    [Color(0xFF8E44AD), Color(0xFF4A235A)], // 5
    [Color(0xFF2980B9), Color(0xFF1A4A6B)], // 6
    [Color(0xFF27AE60), Color(0xFF145A32)], // 7
    [Color(0xFF16A085), Color(0xFF0A4D43)], // 8
    [Color(0xFF2C3E50), Color(0xFF1A252F)], // 9
    [Color(0xFFE74C3C), Color(0xFFC0392B)], // 10
  ];

  static List<Color> _gradientForRound(int idx) {
    final i = (idx - 1).clamp(0, _palettes.length - 1);
    return _palettes[i];
  }

  @override
  Widget build(BuildContext context) {
    return LevelsScreen(
      theme: MapTheme.garagum,
      headerTitle: 'GARAGUM ÇÖLI',
      rounds: RoundConfig.all,
      gradientForRound: _gradientForRound,
    );
  }
}

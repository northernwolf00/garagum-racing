import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/map_theme.dart';
import '../../models/round_config.dart';
import 'levels_screen.dart';

/// Round-selection grid for the Derweze Gas Crater map (15 rounds).
class DerwezeLevelsScreen extends StatelessWidget {
  const DerwezeLevelsScreen({super.key});

  // Dark night sky & fiery crater orange/crimson palette
  static const List<List<Color>> _palettes = [
    [Color(0xFFC0392B), Color(0xFF641E16)], // 1
    [Color(0xFFE74C3C), Color(0xFF78281F)], // 2
    [Color(0xFFD35400), Color(0xFF6E2C00)], // 3
    [Color(0xFF900C3F), Color(0xFF4A0620)], // 4
    [Color(0xFFC0392B), Color(0xFF511E17)], // 5
    [Color(0xFFE67E22), Color(0xFF7E3200)], // 6
    [Color(0xFF581845), Color(0xFF2C0B23)], // 7
    [Color(0xFF900C3F), Color(0xFF43051D)], // 8
    [Color(0xFFC0392B), Color(0xFF641E16)], // 9
    [Color(0xFFD35400), Color(0xFF5E2400)], // 10
    [Color(0xFFE74C3C), Color(0xFF6E1F16)], // 11
    [Color(0xFF900C3F), Color(0xFF4A0620)], // 12
    [Color(0xFFC0392B), Color(0xFF511E17)], // 13
    [Color(0xFFE67E22), Color(0xFF7E3200)], // 14
    [Color(0xFFFF5733), Color(0xFF900C3F)], // 15
  ];

  static List<Color> _gradientForRound(int idx) {
    final i = (idx - 1).clamp(0, _palettes.length - 1);
    return _palettes[i];
  }

  @override
  Widget build(BuildContext context) {
    return LevelsScreen(
      theme: MapTheme.derweze,
      headerTitle: 'header_derweze'.tr,
      rounds: RoundConfig.derwezeAll,
      gradientForRound: _gradientForRound,
    );
  }
}

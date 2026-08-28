import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/map_theme.dart';
import '../../models/round_config.dart';
import 'levels_screen.dart';

/// Round-selection grid for the Aşgabat city map (15 rounds).
class AshgabatLevelsScreen extends StatelessWidget {
  const AshgabatLevelsScreen({super.key});

  // Gold / marble / glass-blue palette echoing images_ashgabat's art pack
  // (#F7F2E7 marble, #E2B24C gold, #79BEE4 glass-blue).
  static const List<List<Color>> _palettes = [
    [Color(0xFFE2B24C), Color(0xFF8B6A1A)], // 1
    [Color(0xFF79BEE4), Color(0xFF2C6B8A)], // 2
    [Color(0xFFD4A017), Color(0xFF7A5500)], // 3
    [Color(0xFF4FA8D8), Color(0xFF1A5A78)], // 4
    [Color(0xFFE8C46A), Color(0xFF9A6E1A)], // 5
    [Color(0xFF5FBEDB), Color(0xFF1F5C73)], // 6
    [Color(0xFFF0D080), Color(0xFFA87D1E)], // 7
    [Color(0xFF3E97BE), Color(0xFF15455C)], // 8
    [Color(0xFFE2B24C), Color(0xFF6E4E12)], // 9
    [Color(0xFF79BEE4), Color(0xFF244C63)], // 10
    [Color(0xFFDDA43D), Color(0xFF7A5200)], // 11
    [Color(0xFF2E8FB8), Color(0xFF123B4E)], // 12
    [Color(0xFFF2C568), Color(0xFF8F631A)], // 13
    [Color(0xFF5AA9CC), Color(0xFF17394A)], // 14
    [Color(0xFFFFD98C), Color(0xFFB8860B)], // 15
  ];

  static List<Color> _gradientForRound(int idx) {
    final i = (idx - 1).clamp(0, _palettes.length - 1);
    return _palettes[i];
  }

  @override
  Widget build(BuildContext context) {
    return LevelsScreen(
      theme: MapTheme.ashgabat,
      headerTitle: 'header_ashgabat'.tr,
      rounds: RoundConfig.ashgabatAll,
      gradientForRound: _gradientForRound,
    );
  }
}

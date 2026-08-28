import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/map_theme.dart';
import '../../models/round_config.dart';
import 'levels_screen.dart';

/// Round-selection grid for the Ýaňňykala canyon map (15 rounds).
class YangykalaLevelsScreen extends StatelessWidget {
  const YangykalaLevelsScreen({super.key});

  // Canyon terra-cotta / orange / deep crimson palette echoing Ýaňňykala cliff layers
  static const List<List<Color>> _palettes = [
    [Color(0xFFD35400), Color(0xFF7E3200)], // 1
    [Color(0xFFE67E22), Color(0xFF8E4400)], // 2
    [Color(0xFFC0392B), Color(0xFF6E1F16)], // 3
    [Color(0xFFD9534F), Color(0xFF7A201E)], // 4
    [Color(0xFFB03A2E), Color(0xFF5C1D16)], // 5
    [Color(0xFFE59866), Color(0xFF874E28)], // 6
    [Color(0xFFCA6F1E), Color(0xFF6E3B0E)], // 7
    [Color(0xFFA93226), Color(0xFF581912)], // 8
    [Color(0xFFDC7633), Color(0xFF7E3D16)], // 9
    [Color(0xFF922B21), Color(0xFF4A140E)], // 10
    [Color(0xFFEB984E), Color(0xFF8C5323)], // 11
    [Color(0xFFB03A2E), Color(0xFF5E1E17)], // 12
    [Color(0xFFD35400), Color(0xFF6E2C00)], // 13
    [Color(0xFFC0392B), Color(0xFF641E16)], // 14
    [Color(0xFFE67E22), Color(0xFF7E3200)], // 15
  ];

  static List<Color> _gradientForRound(int idx) {
    final i = (idx - 1).clamp(0, _palettes.length - 1);
    return _palettes[i];
  }

  @override
  Widget build(BuildContext context) {
    return LevelsScreen(
      theme: MapTheme.yangykala,
      headerTitle: 'header_yangykala'.tr,
      rounds: RoundConfig.yangykalaAll,
      gradientForRound: _gradientForRound,
    );
  }
}

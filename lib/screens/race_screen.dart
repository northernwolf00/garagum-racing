import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/garagum_racing_game.dart';
import '../game/input/pedal_button.dart';

/// Phase 1 prototype screen: the physics playground itself, with a
/// gas/brake pedal HUD. No fuel, score, menus or maps yet.
class RaceScreen extends StatefulWidget {
  const RaceScreen({super.key});

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> {
  late final GaragumRacingGame _game;

  bool _gasPressed = false;
  bool _brakePressed = false;

  @override
  void initState() {
    super.initState();
    _game = GaragumRacingGame();
  }

  void _updateThrottle() {
    if (_gasPressed == _brakePressed) {
      _game.setThrottle(0);
    } else if (_gasPressed) {
      _game.setThrottle(1);
    } else {
      _game.setThrottle(-1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),
          Positioned(
            left: 24,
            bottom: 32,
            child: PedalButton(
              icon: Icons.arrow_back,
              color: Colors.redAccent,
              onPressedChanged: (pressed) {
                _brakePressed = pressed;
                _updateThrottle();
              },
            ),
          ),
          Positioned(
            right: 24,
            bottom: 32,
            child: PedalButton(
              icon: Icons.arrow_forward,
              color: Colors.green,
              onPressedChanged: (pressed) {
                _gasPressed = pressed;
                _updateThrottle();
              },
            ),
          ),
        ],
      ),
    );
  }
}

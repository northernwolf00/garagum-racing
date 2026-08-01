import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/garagum_racing_game.dart';
import '../game/input/pedal_button.dart';

/// The physics playground with the Phase 4 art pass: sprite car, textured
/// dune terrain, parallax backdrop, pedal art and engine sound. Still no
/// fuel, score or menus.
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

  @override
  void dispose() {
    _game.audio.dispose();
    super.dispose();
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
              assetPath: 'assets/images/ui/pedal_brake.png',
              pressedAssetPath: 'assets/images/ui/pedal_brake_pressed.png',
              onPressedChanged: (pressed) {
                _brakePressed = pressed;
                _updateThrottle();
                if (pressed) _game.audio.playButtonClick();
              },
            ),
          ),
          Positioned(
            right: 24,
            bottom: 32,
            child: PedalButton(
              assetPath: 'assets/images/ui/pedal_gas.png',
              pressedAssetPath: 'assets/images/ui/pedal_gas_pressed.png',
              onPressedChanged: (pressed) {
                _gasPressed = pressed;
                _updateThrottle();
                if (pressed) _game.audio.playButtonClick();
              },
            ),
          ),
        ],
      ),
    );
  }
}

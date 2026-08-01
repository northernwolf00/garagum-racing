import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import 'components/car.dart';
import 'world/terrain.dart';

/// Phase 1 prototype: a Forge2D world with procedural dune terrain and a
/// physics-driven car. No sprites, sound, fuel, or menus yet — the goal of
/// this phase is just to get the driving feel right.
class GaragumRacingGame extends Forge2DGame {
  GaragumRacingGame()
      : super(
          gravity: Vector2(0, 22),
          zoom: 28,
        );

  static const Color _skyColor = Color(0xFFFCE2A6);

  /// How quickly the camera closes the gap to the car; higher = snappier.
  static const double _cameraFollowRate = 6;

  late final Terrain terrain;
  late final Car car;

  double _throttleInput = 0;

  @override
  Color backgroundColor() => _skyColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    terrain = Terrain();
    await world.add(terrain);

    car = Car(startPosition: Vector2(6, -8));
    await world.add(car);

    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = car.position.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final viewfinder = camera.viewfinder;
    final t = 1 - exp(-_cameraFollowRate * dt);
    viewfinder.position = viewfinder.position + (car.position - viewfinder.position) * t;
  }

  void setThrottle(double value) {
    _throttleInput = value;
    car.setThrottle(value);
  }

  double get throttleInput => _throttleInput;
}

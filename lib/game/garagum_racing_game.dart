import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import 'audio/audio_manager.dart';
import 'components/car.dart';
import 'world/parallax_background.dart';
import 'world/terrain.dart';

/// Forge2D world with procedural dune terrain, a physics-driven car, a
/// parallax dune backdrop and an engine-sound loop. Fuel, coins, run-over
/// conditions and menus still belong to a later phase.
class GaragumRacingGame extends Forge2DGame {
  GaragumRacingGame()
      : super(
          gravity: Vector2(0, 22),
          zoom: 28,
        );

  static const Color _skyColor = Color(0xFFFCE2A6);

  /// How quickly the camera closes the gap to the car; higher = snappier.
  static const double _cameraFollowRate = 6;

  /// How far above the terrain surface the car spawns, so it always starts
  /// clear of the ground and falls onto it instead of starting embedded in
  /// (and possibly tunnelling through) the chain-shape collider.
  static const double _spawnClearance = 3;
  static const double _spawnX = 6;

  late final Terrain terrain;
  late final Car car;
  final AudioManager audio = AudioManager();

  double _throttleInput = 0;
  final Vector2 _lastCameraPosition = Vector2.zero();

  @override
  Color backgroundColor() => _skyColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.backdrop = await ParallaxBackground.load(size);

    terrain = Terrain();
    await world.add(terrain);

    final spawnY = -terrain.heightAt(_spawnX) - _spawnClearance;
    car = Car(startPosition: Vector2(_spawnX, spawnY));
    await world.add(car);

    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = car.position.clone();
    _lastCameraPosition.setFrom(camera.viewfinder.position);

    await audio.init();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final viewfinder = camera.viewfinder;
    final t = 1 - exp(-_cameraFollowRate * dt);
    viewfinder.position = viewfinder.position + (car.position - viewfinder.position) * t;

    if (dt > 0) {
      final dx = viewfinder.position.x - _lastCameraPosition.x;
      final background = camera.backdrop;
      if (background is ParallaxComponent) {
        background.parallax?.baseVelocity.x = (dx / dt) * viewfinder.zoom;
      }
    }
    _lastCameraPosition.setFrom(viewfinder.position);
  }

  void setThrottle(double value) {
    _throttleInput = value;
    car.setThrottle(value);
    audio.setEngineIntensity(value);
  }

  double get throttleInput => _throttleInput;
}

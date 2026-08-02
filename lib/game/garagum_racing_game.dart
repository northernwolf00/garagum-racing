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
  GaragumRacingGame() : super(gravity: Vector2(0, 22), zoom: 28);

  static const Color _skyColor = Color(0xFFFCE2A6);

  /// How quickly the camera closes the gap to the car; higher = snappier.
  static const double _cameraFollowRate = 6;

  /// How far above the terrain surface the car spawns, so it always starts
  /// clear of the ground and falls onto it instead of starting embedded in
  /// (and possibly tunnelling through) the chain-shape collider.
  static const double _spawnClearance = 3;
  static const double _spawnX = 6;

  Terrain? terrain;
  Car? car;
  final AudioManager audio = AudioManager();

  VoidCallback? onCrash;
  bool isCrashed = false;

  double _throttleInput = 0;
  final Vector2 _lastCameraPosition = Vector2.zero();

  double get distance =>
      car != null ? max(0.0, car!.position.x - _spawnX) : 0.0;

  @override
  Color backgroundColor() => _skyColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.backdrop = await ParallaxBackground.load(size);

    final tComponent = Terrain();
    await world.add(tComponent);
    terrain = tComponent;

    final spawnY = -tComponent.heightAt(_spawnX) - _spawnClearance;
    final cComponent = Car(startPosition: Vector2(_spawnX, spawnY));
    await world.add(cComponent);
    car = cComponent;

    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = cComponent.position.clone();
    _lastCameraPosition.setFrom(camera.viewfinder.position);

    await audio.init();
  }

  @override
  void update(double dt) {
    super.update(dt);

    final currentCar = car;
    final currentTerrain = terrain;
    if (currentCar == null || currentTerrain == null) return;

    if (!isCrashed && currentCar.checkCrashed(currentTerrain)) {
      isCrashed = true;
      audio.setEngineIntensity(0);
      audio.stopEngine();
      audio.playCrashSound();
      onCrash?.call();
    }

    final viewfinder = camera.viewfinder;
    final t = 1 - exp(-_cameraFollowRate * dt);
    viewfinder.position =
        viewfinder.position + (currentCar.position - viewfinder.position) * t;

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
    if (car == null || isCrashed) {
      car?.setThrottle(0);
      return;
    }
    car?.setThrottle(value);
    audio.setEngineIntensity(value);
  }

  double get throttleInput => _throttleInput;
}

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../models/round_config.dart';
import 'audio/audio_manager.dart';
import 'components/car.dart';
import 'components/coin.dart';
import 'components/fuel_canister.dart';
import 'components/obstacle.dart';
import 'world/bridge.dart';
import 'world/parallax_background.dart';
import 'world/terrain.dart';

/// Forge2D world with procedural dune terrain, bridges, road obstacles,
/// coin pickups, fuel canisters, a physics-driven car, a parallax dune
/// backdrop and an engine-sound loop.
class GaragumRacingGame extends Forge2DGame {
  GaragumRacingGame({required this.roundConfig})
      : super(gravity: Vector2(0, 22), zoom: 28);

  final RoundConfig roundConfig;

  static const Color _skyColor = Color(0xFFFCE2A6);
  static const double _cameraFollowRate = 6;
  static const double _spawnClearance = 3;
  static const double _spawnX = 6;

  /// Full tank in seconds of driving. Each round gives this much fuel.
  /// Fuel canisters are placed so you can always theoretically finish
  /// if you pick them up.
  static const double _fullFuelSeconds = 40.0;

  /// Fuel burn rate per second while the gas pedal is held.
  static const double _fuelBurnRate = 1.0; // fraction per second

  Terrain? terrain;
  Car? car;
  final AudioManager audio = AudioManager();

  VoidCallback? onCrash;
  VoidCallback? onFinish;
  VoidCallback? onOutOfFuel;
  bool isCrashed = false;
  bool _isFinished = false;
  bool _outOfFuel = false;

  int _coinsCollected = 0;
  int get coinsCollected => _coinsCollected;

  /// ValueNotifiers — the RaceScreen listens to these directly.
  /// Updating them never calls setState() during build.
  final ValueNotifier<double> fuelNotifier = ValueNotifier(1.0);
  final ValueNotifier<int> coinNotifier = ValueNotifier(0);

  double get fuel => fuelNotifier.value;

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

    final tComponent = Terrain(roundConfig: roundConfig);
    await world.add(tComponent);
    terrain = tComponent;

    // Add Canal Bridges along the route
    for (final bridgeSpan in tComponent.bridgeSpans) {
      if (bridgeSpan.startX > roundConfig.distanceMeters + _spawnX) break;
      final deckY = -tComponent.baseHeightAt(bridgeSpan.startX);
      final canalBottomY = deckY + Terrain.canalDepth;
      await world.add(BridgeComponent(
        startX: bridgeSpan.startX,
        endX: bridgeSpan.endX,
        deckY: deckY,
        canalBottomY: canalBottomY,
      ));
    }

    // Add road obstacles
    await _spawnRoadObstacles(tComponent);

    // Add coins along the route
    await _spawnCoins(tComponent);

    // Add fuel canisters at danger intervals
    await _spawnFuelCanisters(tComponent);

    final spawnY = -tComponent.heightAt(_spawnX) - _spawnClearance;
    final cComponent = Car(startPosition: Vector2(_spawnX, spawnY));
    await world.add(cComponent);
    car = cComponent;

    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = cComponent.position.clone();
    _lastCameraPosition.setFrom(camera.viewfinder.position);

    await audio.init();
  }

  // ── Obstacle spawning ────────────────────────────────────────────────────

  Future<void> _spawnRoadObstacles(Terrain tComponent) async {
    final rand = Random(roundConfig.roundIndex * 31);
    double curX = 15.0;
    final maxX = _spawnX + roundConfig.distanceMeters + 20;
    final baseStep = 10.0;
    final stepDivisor = roundConfig.obstacleFrequency;

    final obstacleTypes = [
      ObstacleType.sazak,
      ObstacleType.rockSmall,
      ObstacleType.rockBig,
      ObstacleType.sazak,
      ObstacleType.sandRamp,
      ObstacleType.rockSmall,
      ObstacleType.tyreStack,
      ObstacleType.barrel,
      ObstacleType.crate,
      ObstacleType.sazak,
      ObstacleType.sandMound,
      ObstacleType.rockBig,
      ObstacleType.signpost,
    ];
    int obsIdx = roundConfig.roundIndex;

    while (curX < maxX) {
      final step = (baseStep / stepDivisor) + rand.nextDouble() * 6.0;
      curX += step;
      if (tComponent.isInsideBridgeSpan(curX, extraMargin: 5.0)) continue;

      final type = obstacleTypes[obsIdx % obstacleTypes.length];
      obsIdx++;

      final groundH = tComponent.heightAt(curX);
      final groundY = -groundH;
      final groundAngle = tComponent.getGroundAngle(curX);
      final obsSize = ObstacleComponent.getSizeForType(type);
      final halfH = obsSize.y / 2;

      await world.add(ObstacleComponent(
        type: type,
        startPosition: Vector2(curX, groundY - halfH + 0.15),
        groundAngle: groundAngle,
      ));
    }
  }

  // ── Coin spawning ─────────────────────────────────────────────────────────

  Future<void> _spawnCoins(Terrain tComponent) async {
    final rand = Random(roundConfig.roundIndex * 17 + 3);
    final totalCoins = roundConfig.totalCoins;
    final maxX = _spawnX + roundConfig.distanceMeters;
    final usableRange = maxX - 20.0;
    final step = usableRange / totalCoins;

    for (int i = 0; i < totalCoins; i++) {
      final baseX = 18.0 + i * step;
      final jitter = (rand.nextDouble() - 0.5) * step * 0.6;
      final coinX = (baseX + jitter).clamp(18.0, usableRange);
      if (tComponent.isInsideBridgeSpan(coinX, extraMargin: 2.0)) continue;

      final groundH = tComponent.heightAt(coinX);
      final groundY = -groundH;
      final coinPos = Vector2(coinX, groundY - 1.0);

      final coin = CoinComponent(worldPosition: coinPos);
      coin.onCollected = () {
        _coinsCollected++;
        coinNotifier.value = _coinsCollected;
        audio.playCoinSound();
      };
      await world.add(coin);
    }
  }

  // ── Fuel canister spawning ────────────────────────────────────────────────

  Future<void> _spawnFuelCanisters(Terrain tComponent) async {
    // Place a canister every ~_fullFuelSeconds * speed meters.
    // Car speed ≈ 12 m/s at full throttle, so place every ~35-45 m.
    // We put the first one at 80% of a tank's range so the player
    // gets one warning before running dry.
    final double carApproxSpeed = 12.0; // m/s approx
    final double fuelRange = _fullFuelSeconds * carApproxSpeed * 0.85;

    double curX = _spawnX + fuelRange;
    final maxX = _spawnX + roundConfig.distanceMeters - 10.0;

    while (curX < maxX) {
      if (!tComponent.isInsideBridgeSpan(curX, extraMargin: 4.0)) {
        final groundH = tComponent.heightAt(curX);
        final groundY = -groundH;
        // Float canister 0.8m above terrain — slightly lower than coins
        final canisterPos = Vector2(curX, groundY - 0.9);

        final canister = FuelCanisterComponent(worldPosition: canisterPos);
        canister.onCollected = () {
          fuelNotifier.value =
              (fuelNotifier.value + 0.55).clamp(0.0, 1.0); // refill ~55%
          audio.playFuelSound();
        };
        await world.add(canister);
      }

      curX += fuelRange;
    }
  }

  // ── Game loop ─────────────────────────────────────────────────────────────

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final background = camera.backdrop;
    if (background is ParallaxComponent) {
      background.size = size.clone();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final currentCar = car;
    final currentTerrain = terrain;
    if (currentCar == null || currentTerrain == null) return;

    // Burn fuel while driving (only when gas is applied)
    if (!isCrashed && !_isFinished && !_outOfFuel) {
      final throttleAbs = _throttleInput.abs();
      if (throttleAbs > 0) {
        final newFuel = (fuelNotifier.value -
                (_fuelBurnRate / _fullFuelSeconds) * throttleAbs * dt)
            .clamp(0.0, 1.0);
        fuelNotifier.value = newFuel;
      }

      // Out of fuel check
      if (fuelNotifier.value <= 0 && !_outOfFuel) {
        _outOfFuel = true;
        audio.setEngineIntensity(0);
        audio.stopEngine();
        audio.playOutOfFuelSound();
        car?.setThrottle(0);
        onOutOfFuel?.call();
      }
    }

    if (!isCrashed && currentCar.checkCrashed(currentTerrain)) {
      isCrashed = true;
      audio.setEngineIntensity(0);
      audio.stopEngine();
      audio.playCrashSound();
      onCrash?.call();
    }

    // Check finish line
    if (!_isFinished && !isCrashed && distance >= roundConfig.distanceMeters) {
      _isFinished = true;
      audio.setEngineIntensity(0);
      audio.stopEngine();
      onFinish?.call();
    }

    final viewfinder = camera.viewfinder;
    final t = 1 - exp(-_cameraFollowRate * dt);
    viewfinder.position =
        viewfinder.position + (currentCar.position - viewfinder.position) * t;

    if (dt > 0) {
      final dx = viewfinder.position.x - _lastCameraPosition.x;
      final background = camera.backdrop;
      if (background is ParallaxComponent) {
        if (background.size != size) background.size = size.clone();
        background.parallax?.baseVelocity.x = (dx / dt) * viewfinder.zoom;
      }
    }
    _lastCameraPosition.setFrom(viewfinder.position);
  }

  void setThrottle(double value) {
    _throttleInput = value;
    if (car == null || isCrashed || _isFinished || _outOfFuel) {
      car?.setThrottle(0);
      return;
    }
    car?.setThrottle(value);
    audio.setEngineIntensity(value);
  }

  double get throttleInput => _throttleInput;
}

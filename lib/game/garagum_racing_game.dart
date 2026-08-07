import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../models/map_theme.dart';
import '../models/round_config.dart';
import '../models/vehicle_config.dart';
import '../services/game_progress_service.dart';
import 'audio/audio_manager.dart';
import 'components/car.dart';
import 'components/coin.dart';
import 'components/fuel_canister.dart';
import 'components/obstacle.dart';
import 'world/ashgabat_decor.dart';
import 'world/bridge.dart';
import 'world/derweze_decor.dart';
import 'world/desert_decor.dart';
import 'world/parallax_background.dart';
import 'world/terrain.dart';
import 'world/yangykala_decor.dart';

/// Forge2D world with procedural dune terrain, bridges, road obstacles,
/// coin pickups, fuel canisters, a physics-driven car, a parallax dune
/// backdrop and an engine-sound loop.
class GaragumRacingGame extends Forge2DGame {
  GaragumRacingGame({required this.roundConfig})
    : super(gravity: Vector2(0, 22), zoom: 28);

  final RoundConfig roundConfig;

  MapTheme get theme => roundConfig.theme;

  static const Color _skyColor = Color(0xFFFCE2A6);
  static const double _cameraFollowRate = 6;
  static const double _spawnClearance = 3;
  static const double _spawnX = 6;

  /// Upper bound on the per-frame timestep fed to the Forge2D solver.
  /// Flutter's frame ticker keeps running real wall-clock time while the
  /// app is backgrounded, so resuming (or a long stutter/hitch) can deliver
  /// one huge [dt]. Forge2D steps that in a single shot with no
  /// sub-stepping, which can tunnel the fast-spinning wheels through the
  /// thin terrain chain shape and destabilise the head-bob spring
  /// integrator in [Car]. Clamping keeps every physics step small and
  /// stable; the sim just runs a bit "slow" for one frame after a hitch
  /// instead of jumping or exploding.
  static const double _maxPhysicsDt = 1 / 30;

  /// Full tank in seconds of driving. Each round gives this much fuel.
  /// Fuel canisters are placed so you can always theoretically finish
  /// if you pick them up.
  static const double _baseFullFuelSeconds = 40.0;

  /// Effective tank size for the currently selected vehicle, set once in
  /// [onLoad] from [VehicleConfig.fuel] (0.5 reproduces the base value
  /// exactly, matching [Car]'s stat-scaling convention).
  double _fullFuelSeconds = _baseFullFuelSeconds;

  /// Continuous passive fuel burn rate per second (idle engine consumption from start).
  static const double _idleFuelBurnRate = 1.0;

  /// Additional fuel burn rate per second while throttle (gas/brake) is applied.
  static const double _activeFuelBurnRate = 0.4;

  /// Fuel fraction at which we warn the player and guarantee a canister
  /// spawns just ahead of the car — well before the tank actually empties,
  /// so nobody gets stranded between the pre-placed canisters.
  static const double _lowFuelWarningThreshold = 0.25;

  /// Fuel fraction the tank must climb back above before another low-fuel
  /// warning/emergency canister can fire later in the same round.
  static const double _lowFuelResetThreshold = 0.5;

  /// How far ahead of the car (in meters) an emergency canister spawns.
  static const double _emergencyCanisterAheadDistance = 35.0;

  bool _lowFuelWarned = false;

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

  void _safeUpdateCoinNotifier(int val) {
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        coinNotifier.value = val;
      });
    } else {
      coinNotifier.value = val;
    }
  }

  void _safeUpdateFuelNotifier(double val) {
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fuelNotifier.value = val;
      });
    } else {
      fuelNotifier.value = val;
    }
  }

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

    try {
      try {
        final bg = await ParallaxBackground.load(size, theme: theme);
        if (size.x > 0 && size.y > 0) {
          bg.size = size.clone();
          bg.parallax?.resize(size);
        }
        camera.backdrop = bg;
      } catch (e) {
        debugPrint('Error loading ParallaxBackground: $e');
      }

      final tComponent = Terrain(roundConfig: roundConfig, theme: theme);
      await world.add(tComponent);
      terrain = tComponent;

      // Add Canal Bridges along the route (Garagum only — Terrain generates
      // no bridge spans at all for the Aşgabat theme, so this loop no-ops).
      final List<Component> bridges = [];
      for (final bridgeSpan in tComponent.bridgeSpans) {
        if (bridgeSpan.startX > roundConfig.distanceMeters + _spawnX) break;
        final deckY = -tComponent.baseHeightAt(bridgeSpan.startX);
        final canalBottomY = deckY + Terrain.canalDepth;
        bridges.add(
          BridgeComponent(
            startX: bridgeSpan.startX,
            endX: bridgeSpan.endX,
            deckY: deckY,
            canalBottomY: canalBottomY,
          ),
        );
      }
      if (bridges.isNotEmpty) {
        world.addAll(bridges);
      }

      // Add roadside scenery along the route
      switch (theme) {
        case MapTheme.ashgabat:
          await world.add(
            AshgabatDecorComponent(
              terrain: tComponent,
              seed: roundConfig.roundIndex * 71 + 11,
            ),
          );
          break;
        case MapTheme.yangykala:
          await world.add(
            YangykalaDecorComponent(
              terrain: tComponent,
              seed: roundConfig.roundIndex * 71 + 11,
            ),
          );
          break;
        case MapTheme.derweze:
          await world.add(
            DerwezeDecorComponent(
              terrain: tComponent,
              seed: roundConfig.roundIndex * 71 + 11,
            ),
          );
          break;
        case MapTheme.garagum:
          await world.add(
            DesertDecorComponent(
              terrain: tComponent,
              seed: roundConfig.roundIndex * 71 + 11,
            ),
          );
          break;
      }

      // Add road obstacles
      _spawnRoadObstacles(tComponent);

      // Add coins along the route
      _spawnCoins(tComponent);

      // Add fuel canisters at danger intervals
      _spawnFuelCanisters(tComponent);

      final spawnY = -tComponent.heightAt(_spawnX) - _spawnClearance;
      final selectedVehicleId =
          GameProgressService.instance.getSelectedVehicle();
      final selectedVehicle = VehicleConfig.getById(selectedVehicleId);

      // Headlight beam is only turned on during nighttime maps (Derweze)
      final headlight = theme == MapTheme.derweze
          ? (selectedVehicle.headlightAsset ??
                'images_derweze/vehicles/headlight_beam.png')
          : null;

      final cComponent = Car(
        startPosition: Vector2(_spawnX, spawnY),
        bodyAsset: selectedVehicle.bodyAsset,
        wheelAsset: selectedVehicle.wheelAsset,
        headlightAsset: headlight,
        showDriver: selectedVehicle.showDriver,
        engineRating: selectedVehicle.engine,
        suspensionRating: selectedVehicle.suspension,
        tireRating: selectedVehicle.tires,
      );
      await world.add(cComponent);
      car = cComponent;
      _fullFuelSeconds =
          _baseFullFuelSeconds * (0.7 + selectedVehicle.fuel * 0.6);

      camera.viewfinder.anchor = Anchor.center;
      camera.viewfinder.position = cComponent.position.clone();
      _lastCameraPosition.setFrom(camera.viewfinder.position);

      try {
        await audio.init();
      } catch (e) {
        debugPrint('Error initializing AudioManager: $e');
      }
    } catch (e, st) {
      debugPrint('Error during GaragumRacingGame.onLoad: $e\n$st');
    }
  }

  // ── Obstacle spawning ────────────────────────────────────────────────────

  void _spawnRoadObstacles(Terrain tComponent) {
    final rand = Random(roundConfig.roundIndex * 31);
    double curX = 15.0;
    final maxX = _spawnX + roundConfig.distanceMeters + 20;
    final baseStep = 10.0;
    final stepDivisor = roundConfig.obstacleFrequency;

    late final List<ObstacleType> obstacleTypes;
    switch (theme) {
      case MapTheme.ashgabat:
        obstacleTypes = const [
          ObstacleType.trafficCone,
          ObstacleType.pothole,
          ObstacleType.barrier,
          ObstacleType.trafficCone,
          ObstacleType.metalRamp,
          ObstacleType.pothole,
          ObstacleType.trashBin,
          ObstacleType.concreteBlock,
          ObstacleType.constructionSign,
          ObstacleType.trafficCone,
          ObstacleType.speedBump,
          ObstacleType.barrier,
          ObstacleType.trashBin,
        ];
        break;
      case MapTheme.yangykala:
        obstacleTypes = const [
          ObstacleType.ykGayaKici,
          ObstacleType.ykGayaUly,
          ObstacleType.ykOpurylanGaya,
          ObstacleType.ykGumDepejik,
          ObstacleType.ykCukur,
          ObstacleType.ykBochka,
          ObstacleType.ykTigirUysmegi,
        ];
        break;
      case MapTheme.derweze:
        obstacleTypes = const [
          ObstacleType.dwDasKici,
          ObstacleType.dwDasUly,
          ObstacleType.dwGumTramplin,
          ObstacleType.dwGazTurbasy,
          ObstacleType.dwAgylCarcasy,
          ObstacleType.dwBochka,
          ObstacleType.dwCukur,
          ObstacleType.dwTigirUysmegi,
        ];
        break;
      case MapTheme.garagum:
        obstacleTypes = const [
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
        break;
    }
    int obsIdx = roundConfig.roundIndex;
    final List<Component> obstacles = [];

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

      final isPit =
          type == ObstacleType.pothole ||
          type == ObstacleType.ykCukur ||
          type == ObstacleType.dwCukur;
      final yOffset = isPit ? 0.02 : 0.15;

      obstacles.add(
        ObstacleComponent(
          type: type,
          startPosition: Vector2(curX, groundY - halfH + yOffset),
          groundAngle: groundAngle,
        ),
      );
    }
    if (obstacles.isNotEmpty) {
      world.addAll(obstacles);
    }
  }

  // ── Coin spawning ─────────────────────────────────────────────────────────

  void _spawnCoins(Terrain tComponent) {
    final rand = Random(roundConfig.roundIndex * 17 + 3);
    final totalCoins = roundConfig.totalCoins;
    final maxX = _spawnX + roundConfig.distanceMeters;
    final usableRange = maxX - 20.0;
    final step = usableRange / totalCoins;
    final List<Component> coins = [];

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
        _safeUpdateCoinNotifier(_coinsCollected);
        audio.playCoinSound();
      };
      coins.add(coin);
    }
    if (coins.isNotEmpty) {
      world.addAll(coins);
    }
  }

  // ── Fuel canister spawning ────────────────────────────────────────────────

  /// Target spacing between canisters, in meters. Deliberately tighter than
  /// a full tank's nominal range (~40s * 12 m/s ≈ 480 m) so canisters read
  /// as genuinely placed along the road on every round — including short
  /// ones — rather than only appearing once rounds get long enough to need
  /// them. It also leaves a comfortable buffer for hills and obstacle
  /// slowdowns, which burn more fuel per meter than the flat-road estimate.
  static const double _fuelCanisterSpacing = 220.0;

  void _spawnFuelCanisters(Terrain tComponent) {
    final usableStart = _spawnX + 60.0;
    final maxX = _spawnX + roundConfig.distanceMeters - 10.0;
    if (maxX <= usableStart) return;

    final span = maxX - usableStart;
    final count = (span / _fuelCanisterSpacing).ceil().clamp(1, 20);
    final step = span / count;
    final rand = Random(roundConfig.roundIndex * 53 + 7);
    final List<Component> canisters = [];

    for (int i = 0; i < count; i++) {
      final baseX = usableStart + step * (i + 0.5);
      final jitter = (rand.nextDouble() - 0.5) * step * 0.4;
      var curX = (baseX + jitter).clamp(usableStart, maxX);

      if (tComponent.isInsideBridgeSpan(curX, extraMargin: 4.0)) {
        final shifted = (curX + step * 0.3).clamp(usableStart, maxX);
        if (tComponent.isInsideBridgeSpan(shifted, extraMargin: 4.0)) continue;
        curX = shifted;
      }

      final groundH = tComponent.heightAt(curX);
      final groundY = -groundH;
      // Float canister 0.8m above terrain — slightly lower than coins
      final canisterPos = Vector2(curX, groundY - 0.9);

      canisters.add(_makeFuelCanister(canisterPos));
    }
    if (canisters.isNotEmpty) {
      world.addAll(canisters);
    }
  }

  FuelCanisterComponent _makeFuelCanister(Vector2 worldPosition) {
    final canister = FuelCanisterComponent(worldPosition: worldPosition);
    canister.onCollected = () {
      _safeUpdateFuelNotifier(
        (fuelNotifier.value + 0.55).clamp(0.0, 1.0),
      ); // refill ~55%
      audio.playFuelSound();
    };
    return canister;
  }

  /// Drops a canister a short way ahead of the car when fuel runs low, so a
  /// player who missed every pre-placed canister still has a shot at
  /// refuelling instead of being guaranteed to strand out on the road.
  void _spawnEmergencyFuelCanister() {
    final currentCar = car;
    final currentTerrain = terrain;
    if (currentCar == null || currentTerrain == null) return;

    final maxX = _spawnX + roundConfig.distanceMeters - 5.0;
    var curX = currentCar.position.x + _emergencyCanisterAheadDistance;
    if (curX >= maxX) return; // too close to the finish to bother

    if (currentTerrain.isInsideBridgeSpan(curX, extraMargin: 4.0)) {
      curX = (curX + 10.0).clamp(currentCar.position.x + 10.0, maxX);
      if (currentTerrain.isInsideBridgeSpan(curX, extraMargin: 4.0)) return;
    }

    final groundY = -currentTerrain.heightAt(curX);
    world.add(_makeFuelCanister(Vector2(curX, groundY - 0.9)));
  }

  // ── Game loop ─────────────────────────────────────────────────────────────

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final background = camera.backdrop;
    if (background is ParallaxComponent) {
      background.size = size.clone();
      // Setting the component's size alone doesn't re-scale the layers —
      // Parallax caches its own clip rect from whatever size it was last
      // resized to, so without this the backdrop stays clipped to
      // whatever (often smaller, pre-rotation) size it had when the race
      // screen first loaded, leaving the rest of the canvas showing the
      // plain sky-color background fill instead of the parallax art.
      background.parallax?.resize(size);
    }
  }

  @override
  void update(double dt) {
    final clampedDt = dt > _maxPhysicsDt ? _maxPhysicsDt : dt;
    super.update(clampedDt);
    dt = clampedDt;

    final currentCar = car;
    final currentTerrain = terrain;
    if (currentCar == null || currentTerrain == null) return;

    // Burn fuel continuously over time (engine running from start, burning faster with gas)
    if (!isCrashed && !_isFinished && !_outOfFuel) {
      final throttleAbs = _throttleInput.abs();
      final effectiveBurnRate =
          _idleFuelBurnRate + (_activeFuelBurnRate * throttleAbs);
      final newFuel =
          (fuelNotifier.value - (effectiveBurnRate / _fullFuelSeconds) * dt)
              .clamp(0.0, 1.0);
      _safeUpdateFuelNotifier(newFuel);

      // Low-fuel warning + emergency canister, latched so it only fires
      // once per "running low" episode (re-armed once refuelled back up).
      if (fuelNotifier.value <= _lowFuelWarningThreshold) {
        if (!_lowFuelWarned) {
          _lowFuelWarned = true;
          audio.playLowFuelWarningSound();
          _spawnEmergencyFuelCanister();
        }
      } else if (fuelNotifier.value > _lowFuelResetThreshold) {
        _lowFuelWarned = false;
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
        if (background.size != size) {
          background.size = size.clone();
          background.parallax?.resize(size);
        }
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

import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../garagum_racing_game.dart';
import 'car.dart';

/// A fuel canister pick-up sitting on the road surface.
///
/// Uses distance checking + Forge2D sensor contact to guarantee instant
/// collection when the car approaches or touches the fuel canister.
class FuelCanisterComponent extends BodyComponent with ContactCallbacks {
  FuelCanisterComponent({required this.worldPosition})
      : super(renderBody: false);

  final Vector2 worldPosition;

  static const double _radius = 0.5;
  static const double _pickupRadiusSq = 5.29; // 2.3 meters squared

  late final Sprite _sprite;
  bool _collected = false;
  bool _pendingRemoval = false;

  /// Called when the car picks up the canister.
  VoidCallback? onCollected;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = await Sprite.load('ui/fuel_can.png');
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(type: BodyType.static, position: worldPosition);
    final body = world.createBody(bodyDef);
    body.userData = this;
    body.createFixture(
      FixtureDef(
        CircleShape()..radius = _radius,
        isSensor: true,
        density: 0,
        friction: 0,
      ),
    );
    return body;
  }

  // ── Contact ──────────────────────────────────────────────────────────────

  @override
  void beginContact(Object other, Contact contact) {
    // Only the player's car may collect — see CoinComponent.beginContact.
    if (other is Car) _collect();
  }

  void _collect() {
    if (_collected) return;
    final g = game;
    if (g is GaragumRacingGame) {
      if (g.isCrashed || g.isFinished || g.isOutOfFuel || g.isNavigatingAway) return;
    }
    _collected = true;
    onCollected?.call();
    _pendingRemoval = true;
  }

  // ── Update ───────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);

    if (_pendingRemoval) {
      _pendingRemoval = false;
      removeFromParent();
      return;
    }

    if (_collected) return;

    // Distance-based pickup check against car
    final g = game;
    if (g is GaragumRacingGame) {
      if (g.isCrashed || g.isFinished || g.isOutOfFuel || g.isNavigatingAway) return;
      final car = g.car;
      if (car != null) {
        final carPos = car.chassisBody.position;
        if (carPos.distanceToSquared(worldPosition) < _pickupRadiusSq) {
          _collect();
        }
      }
    }
  }

  // ── Render ───────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (_collected) return;
    final g = game;
    if (g is GaragumRacingGame &&
        (worldPosition.x < g.visibleWorldLeft ||
            worldPosition.x > g.visibleWorldRight)) {
      return;
    }
    final d = _radius * 2;
    _sprite.render(
      canvas,
      anchor: Anchor.center,
      size: Vector2(d * 1.5, d * 1.8),
    );
  }
}

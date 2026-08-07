import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../garagum_racing_game.dart';
import 'car.dart';

/// A coin pick-up component sitting on the road surface.
///
/// Uses distance checking + Forge2D sensor contact to guarantee instant
/// collection when the car approaches or touches the coin.
/// On collection:
///  1. _collected = true immediately hides the coin from render().
///  2. [onCollected] callback fires (plays sound + increments coin counter).
///  3. Component removes itself from parent cleanly.
class CoinComponent extends BodyComponent with ContactCallbacks {
  CoinComponent({required this.worldPosition}) : super(renderBody: false);

  final Vector2 worldPosition;

  static const double _radius = 0.45;
  static const double _spinSpeed = 2.8; // radians per second
  static const double _pickupRadiusSq = 5.29; // 2.3 meters squared

  late final Sprite _sprite;
  bool _collected = false;
  bool _pendingRemoval = false;
  double _spriteAngle = 0;

  /// Called the moment the coin is collected (sound + counter).
  VoidCallback? onCollected;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = await Sprite.load('ui/coin.png');
  }

  @override
  Body createBody() {
    final shape = CircleShape()..radius = _radius;

    final bodyDef = BodyDef(
      type: BodyType.static,
      position: worldPosition,
    );

    final body = world.createBody(bodyDef);
    body.userData = this;
    body.createFixture(
      FixtureDef(
        shape,
        isSensor: true, // no physical push — only contact events
        density: 0,
        friction: 0,
      ),
    );
    return body;
  }

  // ── Contact detection ────────────────────────────────────────────────────

  @override
  void beginContact(Object other, Contact contact) {
    // Only the player's car may collect — without this check a barrel or
    // cone knocked into the coin would collect it (sound + counter) too.
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

  // ── Update loop ──────────────────────────────────────────────────────────

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
          return;
        }
      }
    }

    _spriteAngle += _spinSpeed * dt;
  }

  // ── Rendering ────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (_collected) return;
    // Skip coins outside the camera view — long rounds place 800+ of them.
    final g = game;
    if (g is GaragumRacingGame &&
        (worldPosition.x < g.visibleWorldLeft ||
            worldPosition.x > g.visibleWorldRight)) {
      return;
    }
    final d = _radius * 2;
    // Squash factor simulates 3-D coin spin (|cos(angle)|)
    final scaleX = math.cos(_spriteAngle).abs().clamp(0.12, 1.0);
    canvas.save();
    canvas.scale(scaleX, 1.0);
    _sprite.render(
      canvas,
      anchor: Anchor.center,
      size: Vector2(d, d),
    );
    canvas.restore();
  }
}

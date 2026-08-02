import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

/// A coin pick-up component sitting on the road surface.
///
/// Forge2D sensor contact is used to detect when the car overlaps the coin.
/// On contact:
///  1. The coin sprite immediately becomes invisible.
///  2. [onCollected] callback fires (plays sound + increments counter).
///  3. The Forge2D body is destroyed and the component is removed on the
///     next frame (we must not call world.destroyBody inside a contact callback).
class CoinComponent extends BodyComponent with ContactCallbacks {
  CoinComponent({required this.worldPosition}) : super(renderBody: false);

  final Vector2 worldPosition;

  static const double _radius = 0.38;
  static const double _spinSpeed = 2.8; // radians per second

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
    if (_collected) return;
    _collected = true;
    // Fire callback immediately — sound + HUD update
    onCollected?.call();
    // Schedule body removal for next frame (Forge2D restriction:
    // world.destroyBody cannot be called during a step callback)
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
    _spriteAngle += _spinSpeed * dt;
  }

  // ── Rendering ────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (_collected) return;
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

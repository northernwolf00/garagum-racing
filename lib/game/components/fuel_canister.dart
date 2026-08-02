import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

/// A fuel canister pick-up sitting on the road surface.
/// Uses a circular sensor fixture, same pattern as CoinComponent.
/// When the car overlaps it:
///  1. Sprite immediately hidden (_collected = true).
///  2. [onCollected] callback fires (refill fuel + play sound).
///  3. Body removed next frame (Forge2D step-callback restriction).
class FuelCanisterComponent extends BodyComponent with ContactCallbacks {
  FuelCanisterComponent({required this.worldPosition})
    : super(renderBody: false);

  final Vector2 worldPosition;

  static const double _radius = 0.45;

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
    if (_collected) return;
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
    }
  }

  // ── Render ───────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (_collected) return;
    final d = _radius * 2;
    _sprite.render(
      canvas,
      anchor: Anchor.center,
      size: Vector2(d * 1.5, d * 1.8), // taller aspect for a canister
    );
  }
}

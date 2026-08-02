import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

enum ObstacleType {
  sazak,
  rockBig,
  rockSmall,
  sandMound,
  sandRamp,
  tyreStack,
  barrel,
  crate,
  signpost,
}

class ObstacleComponent extends BodyComponent {
  ObstacleComponent({
    required this.type,
    required this.startPosition,
    this.groundAngle = 0.0,
  }) : super(renderBody: false);

  final ObstacleType type;
  final Vector2 startPosition;
  final double groundAngle;

  late final Sprite _sprite;

  static Vector2 getSizeForType(ObstacleType type) {
    switch (type) {
      case ObstacleType.sazak:
        return Vector2(1.6, 0.8);
      case ObstacleType.rockBig:
        return Vector2(2.0, 1.3);
      case ObstacleType.rockSmall:
        return Vector2(0.9, 0.7);
      case ObstacleType.sandMound:
        return Vector2(2.6, 0.9);
      case ObstacleType.sandRamp:
        return Vector2(3.0, 1.2);
      case ObstacleType.tyreStack:
        return Vector2(1.0, 1.4);
      case ObstacleType.barrel:
        return Vector2(0.9, 1.2);
      case ObstacleType.crate:
        return Vector2(1.0, 1.0);
      case ObstacleType.signpost:
        return Vector2(1.1, 2.0);
    }
  }

  Vector2 get size => getSizeForType(type);

  String get _assetPath {
    switch (type) {
      case ObstacleType.sazak:
        return 'obstacles/log_sazak.png';
      case ObstacleType.rockBig:
        return 'obstacles/rock_big.png';
      case ObstacleType.rockSmall:
        return 'obstacles/rock_small.png';
      case ObstacleType.sandMound:
        return 'obstacles/sand_mound.png';
      case ObstacleType.sandRamp:
        return 'obstacles/sand_ramp.png';
      case ObstacleType.tyreStack:
        return 'obstacles/tyre_stack.png';
      case ObstacleType.barrel:
        return 'obstacles/barrel.png';
      case ObstacleType.crate:
        return 'obstacles/crate.png';
      case ObstacleType.signpost:
        return 'obstacles/signpost.png';
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = await Sprite.load(_assetPath);
  }

  @override
  Body createBody() {
    final dims = size;
    final halfW = dims.x / 2;
    final halfH = dims.y / 2;

    final isStatic = type == ObstacleType.sandMound ||
        type == ObstacleType.sandRamp ||
        type == ObstacleType.rockBig ||
        type == ObstacleType.signpost;

    final bodyDef = BodyDef(
      type: isStatic ? BodyType.static : BodyType.dynamic,
      position: startPosition,
      angle: groundAngle,
      linearDamping: 0.8,
      angularDamping: 1.2,
    );

    final body = world.createBody(bodyDef);

    Shape shape;
    if (type == ObstacleType.rockSmall || type == ObstacleType.barrel) {
      shape = CircleShape()..radius = math.min(halfW, halfH);
    } else if (type == ObstacleType.sandRamp) {
      final vertices = [
        Vector2(-halfW, halfH),
        Vector2(halfW, halfH),
        Vector2(halfW, -halfH),
      ];
      shape = PolygonShape()..set(vertices);
    } else {
      shape = PolygonShape()..setAsBox(halfW, halfH, Vector2.zero(), 0);
    }

    double density = 1.0;
    double friction = 0.8;
    double restitution = 0.1;

    switch (type) {
      case ObstacleType.sazak:
        density = 1.2;
        friction = 0.9;
        restitution = 0.05;
        break;
      case ObstacleType.rockBig:
        density = 5.0;
        friction = 1.0;
        break;
      case ObstacleType.rockSmall:
        density = 2.0;
        friction = 0.8;
        restitution = 0.3;
        break;
      case ObstacleType.tyreStack:
        density = 0.9;
        friction = 0.7;
        restitution = 0.4;
        break;
      case ObstacleType.barrel:
      case ObstacleType.crate:
        density = 0.8;
        friction = 0.6;
        restitution = 0.15;
        break;
      default:
        break;
    }

    final fixtureDef = FixtureDef(
      shape,
      density: isStatic ? 0.0 : density,
      friction: friction,
      restitution: restitution,
    );

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void render(Canvas canvas) {
    // Note: Flame Forge2D BodyComponent automatically translates & rotates
    // the canvas to body.position and body.angle before calling render().
    _sprite.render(
      canvas,
      anchor: Anchor.center,
      size: size,
    );
  }
}

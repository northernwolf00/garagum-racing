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
  // Ashgabat (city) obstacle set
  trafficCone,
  barrier,
  speedBump,
  pothole,
  concreteBlock,
  constructionSign,
  metalRamp,
  trashBin,
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

  /// World-space bounding sizes tuned for smooth car traversal.
  static Vector2 getSizeForType(ObstacleType type) {
    switch (type) {
      case ObstacleType.sazak:
        return Vector2(1.3, 0.5);
      case ObstacleType.rockBig:
        return Vector2(1.5, 0.75);
      case ObstacleType.rockSmall:
        return Vector2(0.8, 0.45);
      case ObstacleType.sandMound:
        return Vector2(2.2, 0.6);
      case ObstacleType.sandRamp:
        return Vector2(2.6, 0.85);
      case ObstacleType.tyreStack:
        return Vector2(0.9, 1.1);
      case ObstacleType.barrel:
        return Vector2(0.8, 1.0);
      case ObstacleType.crate:
        return Vector2(0.85, 0.85);
      case ObstacleType.signpost:
        return Vector2(0.8, 1.5);
      case ObstacleType.trafficCone:
        return Vector2(0.5, 0.6);
      case ObstacleType.barrier:
        return Vector2(1.6, 0.9);
      case ObstacleType.speedBump:
        return Vector2(1.8, 0.35);
      case ObstacleType.pothole:
        return Vector2(1.4, 0.25);
      case ObstacleType.concreteBlock:
        return Vector2(1.4, 0.8);
      case ObstacleType.constructionSign:
        return Vector2(0.7, 1.3);
      case ObstacleType.metalRamp:
        return Vector2(2.4, 0.8);
      case ObstacleType.trashBin:
        return Vector2(0.7, 0.9);
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
      case ObstacleType.trafficCone:
        return 'images_ashgabat/obstacles/traffic_cone.png';
      case ObstacleType.barrier:
        return 'images_ashgabat/obstacles/barrier.png';
      case ObstacleType.speedBump:
        return 'images_ashgabat/obstacles/speed_bump.png';
      case ObstacleType.pothole:
        return 'images_ashgabat/obstacles/pothole.png';
      case ObstacleType.concreteBlock:
        return 'images_ashgabat/obstacles/concrete_block.png';
      case ObstacleType.constructionSign:
        return 'images_ashgabat/obstacles/construction_sign.png';
      case ObstacleType.metalRamp:
        return 'images_ashgabat/obstacles/metal_ramp.png';
      case ObstacleType.trashBin:
        return 'images_ashgabat/obstacles/trash_bin.png';
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

    // Only terrain-like features (ramps, mounds, and solid blocks the car
    // must climb rather than shove) are static.
    final isStatic = type == ObstacleType.sandMound ||
        type == ObstacleType.sandRamp ||
        type == ObstacleType.rockBig ||
        type == ObstacleType.speedBump ||
        type == ObstacleType.pothole ||
        type == ObstacleType.metalRamp ||
        type == ObstacleType.concreteBlock ||
        type == ObstacleType.barrier;

    final bodyDef = BodyDef(
      type: isStatic ? BodyType.static : BodyType.dynamic,
      position: startPosition,
      angle: groundAngle,
      linearDamping: 1.5,
      angularDamping: 2.0,
    );

    final body = world.createBody(bodyDef);
    body.userData = this;

    Shape shape;

    if (type == ObstacleType.rockBig ||
        type == ObstacleType.rockSmall ||
        type == ObstacleType.concreteBlock ||
        type == ObstacleType.barrier) {
      // Sloped trapezoid shape so car wheels can climb over smoothly instead of hitting a vertical wall
      final vertices = [
        Vector2(-halfW, halfH),
        Vector2(halfW, halfH),
        Vector2(halfW * 0.45, -halfH),
        Vector2(-halfW * 0.45, -halfH),
      ];
      shape = PolygonShape()..set(vertices);
    } else if (type == ObstacleType.sandMound ||
        type == ObstacleType.speedBump ||
        type == ObstacleType.pothole) {
      // Smooth mound trapezoid
      final vertices = [
        Vector2(-halfW, halfH),
        Vector2(halfW, halfH),
        Vector2(halfW * 0.3, -halfH),
        Vector2(-halfW * 0.3, -halfH),
      ];
      shape = PolygonShape()..set(vertices);
    } else if (type == ObstacleType.sandRamp || type == ObstacleType.metalRamp) {
      // Smooth jump ramp (slope from left to right)
      final vertices = [
        Vector2(-halfW, halfH),
        Vector2(halfW, halfH),
        Vector2(halfW, -halfH),
      ];
      shape = PolygonShape()..set(vertices);
    } else if (type == ObstacleType.barrel ||
        type == ObstacleType.sazak ||
        type == ObstacleType.trafficCone) {
      // Circle shape rolls easily when bumped
      shape = CircleShape()..radius = math.min(halfW, halfH);
    } else {
      shape = PolygonShape()..setAsBox(halfW, halfH, Vector2.zero(), 0);
    }

    double density = 0.4;
    double friction = 0.3;
    double restitution = 0.1;

    switch (type) {
      case ObstacleType.sazak:
        density = 0.3;
        friction = 0.3;
        restitution = 0.1;
        break;
      case ObstacleType.rockBig:
        density = 0;
        friction = 0.4; // smooth surface to climb
        break;
      case ObstacleType.rockSmall:
        density = 0;
        friction = 0.3;
        break;
      case ObstacleType.tyreStack:
        density = 0.3;
        friction = 0.4;
        restitution = 0.3;
        break;
      case ObstacleType.barrel:
      case ObstacleType.crate:
        density = 0.25;
        friction = 0.3;
        restitution = 0.2;
        break;
      case ObstacleType.signpost:
        density = 0.15;
        friction = 0.2;
        restitution = 0.1;
        break;
      case ObstacleType.trafficCone:
        density = 0.1;
        friction = 0.3;
        restitution = 0.15;
        break;
      case ObstacleType.barrier:
      case ObstacleType.concreteBlock:
        density = 0;
        friction = 0.4; // smooth surface to climb
        break;
      case ObstacleType.speedBump:
      case ObstacleType.pothole:
      case ObstacleType.metalRamp:
        density = 0;
        friction = 0.5;
        break;
      case ObstacleType.constructionSign:
        density = 0.15;
        friction = 0.2;
        restitution = 0.1;
        break;
      case ObstacleType.trashBin:
        density = 0.25;
        friction = 0.3;
        restitution = 0.2;
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
    final dims = size;
    _sprite.render(
      canvas,
      anchor: Anchor.center,
      size: dims,
    );
  }
}

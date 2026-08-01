import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

/// A physics-driven vehicle: a boxy chassis riding on two circular wheels,
/// connected with motorised revolute joints. This is the Phase 1 "cube car"
/// — no sprites yet, just shapes, so the driving feel can be tuned first.
///
/// Not a [BodyComponent] itself, because a car is *three* Forge2D bodies
/// (chassis + 2 wheels) rather than one. It creates and owns all three
/// bodies directly against the [Forge2DWorld] and draws them each frame
/// using their own transforms.
class Car extends Component with HasGameReference {
  Car({required Vector2 startPosition}) : _startPosition = startPosition;

  final Vector2 _startPosition;

  static const double chassisHalfWidth = 1.5;
  static const double chassisHalfHeight = 0.35;
  static const double wheelRadius = 0.45;
  static const double wheelOffsetX = 1.15;
  static const double wheelOffsetY = 0.55;
  static const double maxMotorSpeed = 32;
  static const double motorTorque = 70;

  late final Forge2DWorld _world;
  late final Body chassisBody;
  late final Body frontWheelBody;
  late final Body rearWheelBody;
  late final RevoluteJoint frontJoint;
  late final RevoluteJoint rearJoint;

  final Paint _chassisPaint = Paint()..color = const Color(0xFFE8A33D);
  final Paint _wheelPaint = Paint()..color = const Color(0xFF2B2B2B);
  final Paint _hubPaint = Paint()..color = const Color(0xFFDDDDDD);

  @override
  Future<void> onLoad() async {
    _world = game.world as Forge2DWorld;

    chassisBody = _createChassis();
    frontWheelBody = _createWheel(
      Vector2(_startPosition.x + wheelOffsetX, _startPosition.y + wheelOffsetY),
    );
    rearWheelBody = _createWheel(
      Vector2(_startPosition.x - wheelOffsetX, _startPosition.y + wheelOffsetY),
    );

    frontJoint = _attachWheel(chassisBody, frontWheelBody);
    rearJoint = _attachWheel(chassisBody, rearWheelBody);
  }

  Body _createChassis() {
    final shape = PolygonShape()
      ..setAsBox(chassisHalfWidth, chassisHalfHeight, Vector2.zero(), 0);
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: _startPosition,
      angularDamping: 1.5,
    );
    final body = _world.createBody(bodyDef);
    body.createFixture(
      FixtureDef(shape, density: 1.1, friction: 0.4, restitution: 0.05),
    );
    return body;
  }

  Body _createWheel(Vector2 position) {
    final shape = CircleShape()..radius = wheelRadius;
    final bodyDef = BodyDef(type: BodyType.dynamic, position: position);
    final body = _world.createBody(bodyDef);
    body.createFixture(
      FixtureDef(shape, density: 1.0, friction: 2.2, restitution: 0.15),
    );
    return body;
  }

  RevoluteJoint _attachWheel(Body chassis, Body wheel) {
    final jointDef = RevoluteJointDef()
      ..initialize(chassis, wheel, wheel.position)
      ..enableMotor = true
      ..maxMotorTorque = motorTorque
      ..motorSpeed = 0
      ..collideConnected = false;
    final joint = RevoluteJoint(jointDef);
    _world.createJoint(joint);
    return joint;
  }

  /// -1 (full brake / reverse) .. 0 (idle) .. 1 (full gas)
  void setThrottle(double throttle) {
    final speed = -maxMotorSpeed * throttle;
    frontJoint.motorSpeed = speed;
    rearJoint.motorSpeed = speed;
  }

  void gas() => setThrottle(1);
  void brake() => setThrottle(-1);
  void release() => setThrottle(0);

  Vector2 get position => chassisBody.position;

  @override
  void render(Canvas canvas) {
    _renderBox(canvas, chassisBody, chassisHalfWidth, chassisHalfHeight, _chassisPaint);
    _renderWheel(canvas, frontWheelBody);
    _renderWheel(canvas, rearWheelBody);
  }

  void _renderBox(Canvas canvas, Body body, double hw, double hh, Paint paint) {
    canvas.save();
    canvas.translate(body.position.x, body.position.y);
    canvas.rotate(body.angle);
    canvas.drawRect(Rect.fromLTRB(-hw, -hh, hw, hh), paint);
    canvas.restore();
  }

  void _renderWheel(Canvas canvas, Body body) {
    canvas.save();
    canvas.translate(body.position.x, body.position.y);
    canvas.rotate(body.angle);
    canvas.drawCircle(Offset.zero, wheelRadius, _wheelPaint);
    canvas.drawLine(Offset.zero, Offset(wheelRadius, 0), _hubPaint..strokeWidth = 0.05);
    canvas.restore();
  }
}

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../world/terrain.dart';

/// A physics-driven vehicle: a boxy chassis riding on two circular wheels,
/// connected with motorised revolute joints. Rendered with the Phase 4 art
/// (open-top buggy body, off-road wheels, seated driver) on top of the
/// Phase 1 physics rig — the shapes below are collision-only now.
///
/// Not a [BodyComponent] itself, because a car is *three* Forge2D bodies
/// (chassis + 2 wheels) rather than one. It creates and owns all three
/// bodies directly against the [Forge2DWorld] and draws sprites anchored to
/// each body's own transform every frame.
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

  /// car_body.png is 1024x512 with its front/rear wheel-arch centers at
  /// (252,400) and (772,400) — 260px either side of the image's horizontal
  /// midline. Scaling that 260px reference to [wheelOffsetX] (meters) gives
  /// a world-space size for the body sprite that keeps the art's wheel
  /// arches lined up with the physics wheel joints.
  static const double _artPxToMeters = wheelOffsetX / 260;
  static const double _bodyWidthM = 1024 * _artPxToMeters;
  static const double _bodyHeightM = 512 * _artPxToMeters;

  /// Driver placement inside the car_body art frame (per asset spec):
  /// body centered at (512,170), 0.62x the body art scale, head ~28px
  /// above the body.
  static const double _driverScale = 0.62;
  static const double _driverBodyOffsetYM = (170 - 256) * _artPxToMeters;
  static const double _driverHeadGapM = 28 * _artPxToMeters;
  static const double _driverBodySizeM = 320 * _artPxToMeters * _driverScale;
  static const double _driverHeadSizeM = 320 * _artPxToMeters * _driverScale;

  late final Forge2DWorld _world;
  late final Body chassisBody;
  late final Body frontWheelBody;
  late final Body rearWheelBody;
  late final RevoluteJoint frontJoint;
  late final RevoluteJoint rearJoint;

  late final Sprite _bodySprite;
  late final Sprite _wheelSprite;
  late final Sprite _driverBodySprite;
  late final Sprite _driverHeadSprite;

  @override
  Future<void> onLoad() async {
    _world = game.world as Forge2DWorld;

    _bodySprite = await Sprite.load('vehicles/car_body.png');
    _wheelSprite = await Sprite.load('vehicles/car_wheel.png');
    _driverBodySprite = await Sprite.load('vehicles/driver_body.png');
    _driverHeadSprite = await Sprite.load('vehicles/driver_head.png');

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
    // Positive throttle (gas) → negative motor speed → wheels spin forward (car moves right)
    // Negative throttle (brake) → positive motor speed → wheels spin backward (car slows/reverses)
    final speed = maxMotorSpeed * throttle;
    frontJoint.motorSpeed = speed;
    rearJoint.motorSpeed = speed;
  }

  void gas() => setThrottle(1);
  void brake() => setThrottle(-1);
  void release() => setThrottle(0);

  Vector2 get position => chassisBody.position;

  /// Checks if the driver's head hit the ground or chassis flipped upside down near ground.
  bool checkCrashed(Terrain terrain) {
    final angle = chassisBody.angle;
    // Driver head offset in local chassis coordinates (-Y is UP in local space)
    final headOffset = Vector2(0, -0.65)..rotate(angle);
    final headPos = chassisBody.position + headOffset;

    final headGroundY = -terrain.heightAt(headPos.x);

    // Head touching or below ground level (Y increases downwards in Flame Forge2D)
    if (headPos.y >= headGroundY - 0.15) {
      return true;
    }

    // Chassis inverted (angle > ~110 degrees) and close to ground level
    final chassisGroundY = -terrain.heightAt(chassisBody.position.x);
    final isUpsideDown = math.cos(angle) < -0.3;
    if (isUpsideDown && chassisBody.position.y >= chassisGroundY - 0.6) {
      return true;
    }

    return false;
  }

  @override
  void render(Canvas canvas) {
    // Wheels first so the body's wheel-arch cutouts show tire on top.
    _renderWheel(canvas, rearWheelBody);
    _renderWheel(canvas, frontWheelBody);
    _renderBody(canvas);
    _renderDriver(canvas);
  }

  void _renderWheel(Canvas canvas, Body body) {
    canvas.save();
    canvas.translate(body.position.x, body.position.y);
    canvas.rotate(body.angle);
    _wheelSprite.render(
      canvas,
      anchor: Anchor.center,
      size: Vector2.all(wheelRadius * 2),
    );
    canvas.restore();
  }

  void _renderBody(Canvas canvas) {
    canvas.save();
    canvas.translate(chassisBody.position.x, chassisBody.position.y);
    canvas.rotate(chassisBody.angle);
    _bodySprite.render(
      canvas,
      anchor: Anchor.center,
      size: Vector2(_bodyWidthM, _bodyHeightM),
    );
    canvas.restore();
  }

  void _renderDriver(Canvas canvas) {
    canvas.save();
    canvas.translate(chassisBody.position.x, chassisBody.position.y);
    canvas.rotate(chassisBody.angle);

    _driverBodySprite.render(
      canvas,
      position: Vector2(0, _driverBodyOffsetYM),
      anchor: Anchor.center,
      size: Vector2.all(_driverBodySizeM),
    );

    final headY = _driverBodyOffsetYM -
        _driverBodySizeM / 2 -
        _driverHeadGapM -
        _driverHeadSizeM / 2;
    _driverHeadSprite.render(
      canvas,
      position: Vector2(0, headY),
      anchor: Anchor.center,
      size: Vector2.all(_driverHeadSizeM),
    );

    canvas.restore();
  }
}

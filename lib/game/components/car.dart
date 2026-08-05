import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../world/terrain.dart';

/// A physics-driven vehicle: a boxy chassis riding on two circular wheels,
/// each on a motorised, spring-suspended [WheelJoint] (plus a [RopeJoint]
/// safety limit — see [_suspensionTravel]). Rendered with the Phase 4 art
/// (open-top buggy body, off-road wheels, seated driver) on top of the
/// Phase 1 physics rig — the shapes below are collision-only now.
///
/// Not a [BodyComponent] itself, because a car is *three* Forge2D bodies
/// (chassis + 2 wheels) rather than one. It creates and owns all three
/// bodies directly against the [Forge2DWorld] and draws sprites anchored to
/// each body's own transform every frame.
class Car extends Component with HasGameReference {
  Car({
    required Vector2 startPosition,
    this.bodyAsset = 'vehicles/car_body.png',
    this.wheelAsset = 'vehicles/car_wheel.png',
    this.headlightAsset,
    this.showDriver = true,
    double engineRating = 0.5,
    double suspensionRating = 0.5,
    double tireRating = 0.5,
  })  : _startPosition = startPosition,
        engineRating = engineRating.clamp(0.0, 1.0),
        suspensionRating = suspensionRating.clamp(0.0, 1.0),
        tireRating = tireRating.clamp(0.0, 1.0);

  final Vector2 _startPosition;

  /// [VehicleConfig.engine]/[suspension]/[tires] ratings in 0..1, used to
  /// scale this rig's tuned baseline constants (top speed & torque, head-bob
  /// spring comfort, tire grip) per vehicle. 0.5 reproduces the pre-stats
  /// baseline exactly, so any caller that doesn't pass these gets the
  /// original tuned feel unchanged.
  final double engineRating;
  final double suspensionRating;
  final double tireRating;

  /// Maps a 0..1 stat rating to a 0.7x..1.3x multiplier on a baseline
  /// constant, with 0.5 (the default rating) landing exactly on 1.0x.
  static double _statScale(double rating) => 0.7 + rating * 0.6;

  /// Body/wheel sprite paths. Both the Garagum buggy and Aşgabat's "ak
  /// ulag" city car share the same 1024x512 wheel-arch rig (arches at
  /// x=252/772, y=400, radius ≈110px) per the art pack notes, so swapping
  /// these two paths is enough to reskin the car — no rig math changes.
  final String bodyAsset;
  final String wheelAsset;

  /// Optional headlight beam asset path (e.g. for nighttime driving in Derweze).
  final String? headlightAsset;

  /// Whether to load/render the seated driver sprites. The Aşgabat "ak
  /// ulag" city car has no driver art of its own, so it's driven with this
  /// off. The head-based crash detection still uses a virtual head point
  /// at the same rig offset either way — this only affects rendering.
  final bool showDriver;

  static const double chassisHalfWidth = 1.5;
  static const double chassisHalfHeight = 0.35;
  static const double wheelRadius = 0.45;
  static const double wheelOffsetX = 1.15;
  static const double wheelOffsetY = 0.55;
  static const double _baseMaxMotorSpeed = 32;
  static const double _baseMotorTorque = 70;
  static const double _baseWheelFriction = 2.2;

  double get maxMotorSpeed => _baseMaxMotorSpeed * _statScale(engineRating);
  double get motorTorque => _baseMotorTorque * _statScale(engineRating);

  /// car_body.png is 1024x512 with its front/rear wheel-arch centers at
  /// (252,400) and (772,400) — 260px either side of the image's horizontal
  /// midline. Scaling that 260px reference to [wheelOffsetX] (meters) gives
  /// a world-space size for the body sprite that keeps the art's wheel
  /// arches lined up with the physics wheel joints.
  static const double _artPxToMeters = wheelOffsetX / 260;
  static const double _bodyWidthM = 1024 * _artPxToMeters;
  static const double _bodyHeightM = 512 * _artPxToMeters;

  /// Driver placement inside the car_body art frame (per asset spec):
  /// body centered at (512,170), 0.62x the body art scale.
  static const double _driverScale = 0.62;
  static const double _driverBodyOffsetYM = (170 - 256) * _artPxToMeters;
  static const double _driverBodySizeM = 320 * _artPxToMeters * _driverScale;
  static const double _driverHeadSizeM = 320 * _artPxToMeters * _driverScale;

  static const double _baseSpringStiffness = 110.0;
  static const double _baseSpringDamping = 10.0;

  double get _springStiffness =>
      _baseSpringStiffness * _statScale(suspensionRating);
  double get _springDamping => _baseSpringDamping * _statScale(suspensionRating);

  /// Real wheel suspension (as opposed to the cosmetic head-bob spring
  /// above). Each wheel rides on a [WheelJoint] — a spring-loaded
  /// point-to-line constraint — instead of being pinned rigidly to the
  /// chassis, so bumps and landings compress the suspension first instead of
  /// slamming straight into the chassis rotation. Higher [suspensionRating]
  /// softens the spring (more give) but damps it harder (less bounce-back)
  /// and allows more travel — softer *and* more controlled, like a real
  /// off-road suspension upgrade.
  static const double _baseSuspensionFrequencyHz = 4.0;
  static const double _baseSuspensionDampingRatio = 0.5;
  static const double _baseSuspensionTravel = 0.3;

  double get _suspensionFrequencyHz =>
      _baseSuspensionFrequencyHz * (1.15 - suspensionRating * 0.3);
  double get _suspensionDampingRatio =>
      _baseSuspensionDampingRatio * _statScale(suspensionRating);

  /// Hard cap on how far a wheel may stray from its rest mount, enforced by
  /// a [RopeJoint] alongside the [WheelJoint]. This forge2d version's
  /// [WheelJoint] has no built-in translation limit, so a spring alone could
  /// let a hard landing (off a ramp, say) stretch the suspension arbitrarily
  /// far for a step or two before it reels back in — the rope makes that
  /// physically impossible instead of just physically discouraged.
  double get _suspensionTravel => _baseSuspensionTravel * _statScale(suspensionRating);

  final Vector2 _lastChassisVelocity = Vector2.zero();
  final Vector2 _headDisplacement = Vector2.zero();
  final Vector2 _headVelocity = Vector2.zero();
  double _headRotation = 0.0;
  double _headRotVelocity = 0.0;

  late final Forge2DWorld _world;
  late final Body chassisBody;
  late final Body frontWheelBody;
  late final Body rearWheelBody;
  late final WheelJoint frontJoint;
  late final WheelJoint rearJoint;

  late final Sprite _bodySprite;
  late final Sprite _wheelSprite;
  Sprite? _driverBodySprite;
  Sprite? _driverHeadSprite;
  Sprite? _headlightSprite;

  @override
  Future<void> onLoad() async {
    _world = game.world as Forge2DWorld;

    _bodySprite = await Sprite.load(bodyAsset);
    _wheelSprite = await Sprite.load(wheelAsset);
    if (headlightAsset != null) {
      _headlightSprite = await Sprite.load(headlightAsset!);
    }
    if (showDriver) {
      _driverBodySprite = await Sprite.load('vehicles/driver_body.png');
      _driverHeadSprite = await Sprite.load('vehicles/driver_head.png');
    }

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

  double _upsideDownTimer = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _updateHeadPhysics(dt);

    final isUpsideDown = math.cos(chassisBody.angle) < -0.3;
    if (isUpsideDown) {
      _upsideDownTimer += dt;
    } else {
      _upsideDownTimer = 0.0;
    }
  }

  void _updateHeadPhysics(double dt) {
    if (dt <= 0) return;

    final currentVel = chassisBody.linearVelocity;
    final accel = (currentVel - _lastChassisVelocity) / dt;
    _lastChassisVelocity.setFrom(currentVel);

    final chassisAngle = chassisBody.angle;
    final cosA = math.cos(-chassisAngle);
    final sinA = math.sin(-chassisAngle);
    final localAccelX = accel.x * cosA - accel.y * sinA;
    final localAccelY = accel.x * sinA + accel.y * cosA;

    // G-force inertial displacement & tilt
    final targetDispX = (-localAccelX * 0.004).clamp(-0.08, 0.08);
    final targetDispY = (localAccelY * 0.003).clamp(-0.05, 0.05);
    final targetRot =
        (-localAccelX * 0.012 - chassisBody.angularVelocity * 0.12).clamp(
          -0.35,
          0.35,
        );

    // Spring forces toward target state
    final springForceX =
        -_springStiffness * (_headDisplacement.x - targetDispX) -
        _springDamping * _headVelocity.x;
    final springForceY =
        -_springStiffness * (_headDisplacement.y - targetDispY) -
        _springDamping * _headVelocity.y;
    final springTorque =
        -_springStiffness * (_headRotation - targetRot) -
        _springDamping * _headRotVelocity;

    _headVelocity.x += springForceX * dt;
    _headVelocity.y += springForceY * dt;
    _headRotVelocity += springTorque * dt;

    _headDisplacement.x += _headVelocity.x * dt;
    _headDisplacement.y += _headVelocity.y * dt;
    _headRotation += _headRotVelocity * dt;
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
      FixtureDef(
        shape,
        density: 1.0,
        friction: _baseWheelFriction * _statScale(tireRating),
        restitution: 0.15,
      ),
    );
    return body;
  }

  WheelJoint _attachWheel(Body chassis, Body wheel) {
    final jointDef = WheelJointDef()
      ..initialize(chassis, wheel, wheel.position, Vector2(0, 1))
      ..enableMotor = true
      ..maxMotorTorque = motorTorque
      ..motorSpeed = 0
      ..frequencyHz = _suspensionFrequencyHz
      ..dampingRatio = _suspensionDampingRatio
      ..collideConnected = false;
    final joint = WheelJoint(jointDef);
    _world.createJoint(joint);

    // Safety-net rope alongside the spring — see _suspensionTravel.
    final ropeDef = RopeJointDef()
      ..bodyA = chassis
      ..bodyB = wheel
      ..maxLength = _suspensionTravel
      ..collideConnected = false;
    ropeDef.localAnchorA.setFrom(jointDef.localAnchorA);
    ropeDef.localAnchorB.setFrom(Vector2.zero());
    _world.createJoint(RopeJoint(ropeDef));

    return joint;
  }

  /// -1 (full brake / reverse) .. 0 (idle, freewheeling) .. 1 (full gas)
  ///
  /// At throttle 0 the drive motor is disabled entirely rather than being
  /// servoed to zero speed — otherwise the revolute motor actively holds
  /// the wheels at zero angular velocity (a permanent handbrake), so the
  /// car would stop dead the instant the gas pedal is released instead of
  /// coasting on momentum and gravity like a real vehicle.
  void setThrottle(double throttle) {
    final coasting = throttle == 0;
    frontJoint.enableMotor(!coasting);
    rearJoint.enableMotor(!coasting);
    if (!coasting) {
      final speed = maxMotorSpeed * throttle;
      frontJoint.motorSpeed = speed;
      rearJoint.motorSpeed = speed;
    }
  }

  void gas() => setThrottle(1);
  void brake() => setThrottle(-1);
  void release() => setThrottle(0);

  Vector2 get position => chassisBody.position;

  /// Checks if the driver's head hit the ground/bridge or chassis flipped upside down.
  bool checkCrashed(Terrain terrain) {
    final angle = chassisBody.angle;
    final restingHeadY = _driverBodyOffsetYM - _driverBodySizeM * 0.26;
    final localHead = Vector2(
      _headDisplacement.x,
      restingHeadY + _headDisplacement.y,
    )..rotate(angle);
    final headPos = chassisBody.position + localHead;

    // Calculate effective surface Y level at head position (accounting for bridge decks)
    double effectiveHeadGroundY = -terrain.heightAt(headPos.x);
    for (final span in terrain.bridgeSpans) {
      if (headPos.x >= span.startX - 2.5 && headPos.x <= span.endX + 2.5) {
        final bridgeDeckY = -terrain.baseHeightAt(span.startX);
        effectiveHeadGroundY = math.min(effectiveHeadGroundY, bridgeDeckY);
      }
    }

    // Driver's head touching or below ground/bridge surface
    if (headPos.y >= effectiveHeadGroundY - 0.2) {
      return true;
    }

    // Calculate effective surface Y level at chassis position
    final chassisX = chassisBody.position.x;
    double effectiveChassisGroundY = -terrain.heightAt(chassisX);
    for (final span in terrain.bridgeSpans) {
      if (chassisX >= span.startX - 2.5 && chassisX <= span.endX + 2.5) {
        final bridgeDeckY = -terrain.baseHeightAt(span.startX);
        effectiveChassisGroundY = math.min(
          effectiveChassisGroundY,
          bridgeDeckY,
        );
      }
    }

    // Chassis inverted (angle > ~110 degrees) near ground or bridge deck
    final isUpsideDown = math.cos(angle) < -0.3;
    if (isUpsideDown &&
        chassisBody.position.y >= effectiveChassisGroundY - 0.75) {
      return true;
    }

    // Continuous upside-down for over 0.5 seconds anywhere
    if (_upsideDownTimer > 0.5) {
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
    if (showDriver) _renderDriver(canvas);
    if (_headlightSprite != null) _renderHeadlight(canvas);
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
    canvas.scale(-1, 1);
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
    canvas.scale(-1, 1);

    _driverBodySprite!.render(
      canvas,
      position: Vector2(0, _driverBodyOffsetYM),
      anchor: Anchor.center,
      size: Vector2.all(_driverBodySizeM),
    );

    final restingHeadY = _driverBodyOffsetYM - _driverBodySizeM * 0.26;
    final headPos = Vector2(
      _headDisplacement.x,
      restingHeadY + _headDisplacement.y,
    );

    canvas.save();
    canvas.translate(headPos.x, headPos.y);
    canvas.rotate(_headRotation);
    canvas.scale(-1, 1);

    _driverHeadSprite!.render(
      canvas,
      anchor: Anchor.center,
      size: Vector2.all(_driverHeadSizeM),
    );

    canvas.restore();
    canvas.restore();
  }

  void _renderHeadlight(Canvas canvas) {
    canvas.save();
    canvas.translate(chassisBody.position.x, chassisBody.position.y);
    canvas.rotate(chassisBody.angle);
    // Project beam forward from front bumper
    canvas.translate(1.8, -0.1);
    final paint = Paint()..blendMode = BlendMode.plus;
    _headlightSprite!.render(
      canvas,
      anchor: Anchor.centerLeft,
      size: Vector2(4.5, 1.8),
      overridePaint: paint,
    );
    canvas.restore();
  }
}

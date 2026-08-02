import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart' hide Matrix4;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

/// Represents a physical bridge span crossing a canal water channel.
/// Provides Box2D static collision for the bridge deck surface and renders
/// bridge components (pillars, deck texture, entrance/exit gates, railings,
/// canal water, and canal reeds).
class BridgeComponent extends BodyComponent {
  BridgeComponent({
    required this.startX,
    required this.endX,
    required this.deckY,
    required this.canalBottomY,
  }) : super(renderBody: false);

  final double startX;
  final double endX;

  /// Top surface Y coordinate of bridge deck in Forge2D world space.
  final double deckY;

  /// Canal bed Y coordinate in Forge2D world space.
  final double canalBottomY;

  static const double deckThickness = 0.5;
  static const double gateWidthM = 2.5;
  static const double gateHeightM = 4.0;
  static const double pillarWidthM = 1.2;
  static const double railingHeightM = 0.8;
  static const double reedSizeM = 2.0;

  late final Sprite _deckSprite;
  late final Sprite _gateSprite;
  late final Sprite _pillarSprite;
  late final Sprite _railingSprite;
  late final Sprite _rampSprite;
  late final Sprite _waterSprite;
  late final Sprite _reedSprite;

  late final Paint _waterPaint;
  bool _waterPaintReady = false;

  double get width => endX - startX;
  double get midX => (startX + endX) / 2;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _deckSprite = await Sprite.load('bridge/bridge_deck.png');
    _gateSprite = await Sprite.load('bridge/bridge_gate.png');
    _pillarSprite = await Sprite.load('bridge/bridge_pillar.png');
    _railingSprite = await Sprite.load('bridge/bridge_railing.png');
    _rampSprite = await Sprite.load('bridge/bridge_ramp_left.png');
    _waterSprite = await Sprite.load('terrain/canal_water.png');
    _reedSprite = await Sprite.load('terrain/deco_gamys.png');

    final waterImg = _waterSprite.image;
    final waterScale = 4.0 / waterImg.width;
    _waterPaint = Paint()
      ..shader = ImageShader(
        waterImg,
        TileMode.repeated,
        TileMode.repeated,
        (Matrix4.identity()..scaleByDouble(waterScale, waterScale, 1, 1)).storage,
      );
    _waterPaintReady = true;
  }

  @override
  Body createBody() {
    // Extend collision deck 2.5 meters onto land banks on left and right
    final extendedStartX = startX - 2.5;
    final extendedEndX = endX + 2.5;
    final extendedWidth = extendedEndX - extendedStartX;
    final extendedMidX = (extendedStartX + extendedEndX) / 2;

    final halfW = extendedWidth / 2;
    final halfH = deckThickness / 2;
    final centerY = deckY + halfH;

    final shape = PolygonShape()
      ..setAsBox(halfW, halfH, Vector2(extendedMidX, centerY), 0);

    final bodyDef = BodyDef(
      type: BodyType.static,
      position: Vector2.zero(),
    );

    final body = world.createBody(bodyDef);
    final fixtureDef = FixtureDef(
      shape,
      friction: 0.95,
      restitution: 0.0,
    );

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void render(Canvas canvas) {
    _renderCanalWater(canvas);
    _renderPillars(canvas);
    _renderBridgeDeck(canvas);
    _renderRailings(canvas);
    _renderGates(canvas);
    _renderReeds(canvas);
  }

  void _renderCanalWater(Canvas canvas) {
    if (!_waterPaintReady) return;

    final waterSurfaceY = deckY + 3.0;
    final waterHeight = math.max(2.0, canalBottomY - waterSurfaceY + 2.0);

    final rect = Rect.fromLTRB(
      startX - 1.0,
      waterSurfaceY,
      endX + 1.0,
      waterSurfaceY + waterHeight,
    );

    canvas.drawRect(rect, _waterPaint);
  }

  void _renderPillars(Canvas canvas) {
    // Number of pillars along span
    final pillarCount = math.max(2, (width / 7.0).round());
    final step = width / (pillarCount + 1);

    for (int i = 1; i <= pillarCount; i++) {
      final pillarX = startX + step * i;
      final pillarTopY = deckY + deckThickness;
      final pillarH = math.max(1.0, canalBottomY - pillarTopY);

      canvas.save();
      canvas.translate(pillarX, pillarTopY + pillarH / 2);
      _pillarSprite.render(
        canvas,
        anchor: Anchor.center,
        size: Vector2(pillarWidthM, pillarH),
      );
      canvas.restore();
    }
  }

  void _renderBridgeDeck(Canvas canvas) {
    final tileWidth = 3.0;
    final count = (width / tileWidth).ceil();

    // Entrance ramps
    canvas.save();
    canvas.translate(startX - 1.2, deckY + 0.2);
    _rampSprite.render(
      canvas,
      anchor: Anchor.center,
      size: Vector2(2.4, 0.8),
    );
    canvas.restore();

    canvas.save();
    canvas.translate(endX + 1.2, deckY + 0.2);
    canvas.scale(-1, 1);
    _rampSprite.render(
      canvas,
      anchor: Anchor.center,
      size: Vector2(2.4, 0.8),
    );
    canvas.restore();

    // Main bridge deck planks
    for (int i = 0; i < count; i++) {
      final curX = startX + i * tileWidth + tileWidth / 2;
      if (curX > endX) break;

      canvas.save();
      canvas.translate(curX, deckY + deckThickness / 2);
      _deckSprite.render(
        canvas,
        anchor: Anchor.center,
        size: Vector2(tileWidth + 0.05, deckThickness * 1.5),
      );
      canvas.restore();
    }
  }

  void _renderRailings(Canvas canvas) {
    final tileW = 4.0;
    final count = (width / tileW).ceil();

    for (int i = 0; i < count; i++) {
      final curX = startX + i * tileW + tileW / 2;
      if (curX > endX) break;

      canvas.save();
      canvas.translate(curX, deckY - railingHeightM / 2);
      _railingSprite.render(
        canvas,
        anchor: Anchor.center,
        size: Vector2(tileW + 0.05, railingHeightM),
      );
      canvas.restore();
    }
  }

  void _renderGates(Canvas canvas) {
    // Left entry gate
    canvas.save();
    canvas.translate(startX + gateWidthM / 2, deckY - gateHeightM / 2 + 0.2);
    _gateSprite.render(
      canvas,
      anchor: Anchor.center,
      size: Vector2(gateWidthM, gateHeightM),
    );
    canvas.restore();

    // Right exit gate
    canvas.save();
    canvas.translate(endX - gateWidthM / 2, deckY - gateHeightM / 2 + 0.2);
    _gateSprite.render(
      canvas,
      anchor: Anchor.center,
      size: Vector2(gateWidthM, gateHeightM),
    );
    canvas.restore();
  }

  void _renderReeds(Canvas canvas) {
    final waterSurfaceY = deckY + 3.0;

    // Left bank reeds
    canvas.save();
    canvas.translate(startX - 1.5, waterSurfaceY - reedSizeM / 2 + 0.3);
    _reedSprite.render(
      canvas,
      anchor: Anchor.center,
      size: Vector2.all(reedSizeM),
    );
    canvas.restore();

    // Right bank reeds
    canvas.save();
    canvas.translate(endX + 1.5, waterSurfaceY - reedSizeM / 2 + 0.3);
    canvas.scale(-1, 1);
    _reedSprite.render(
      canvas,
      anchor: Anchor.center,
      size: Vector2.all(reedSizeM),
    );
    canvas.restore();
  }
}

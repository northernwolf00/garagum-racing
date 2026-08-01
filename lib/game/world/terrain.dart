import 'dart:math';

import 'package:flame_forge2d/flame_forge2d.dart';

/// Procedural sand-dune ground built from a chain of static line segments.
///
/// The height function combines a few sine waves at different frequencies,
/// which gives the same rolling-dune silhouette as the reference art
/// without needing hand-authored terrain data yet.
class Terrain extends BodyComponent {
  Terrain({
    this.segmentWidth = 2.0,
    this.segmentCount = 400,
  });

  final double segmentWidth;
  final int segmentCount;

  late final List<Vector2> groundPoints;

  double heightAt(double x) {
    return sin(x * 0.09) * 3.0 +
        sin(x * 0.03) * 6.0 +
        sin(x * 0.005 + 1.7) * 2.5 +
        6.0;
  }

  @override
  Body createBody() {
    groundPoints = List.generate(segmentCount, (i) {
      final x = i * segmentWidth;
      return Vector2(x, -heightAt(x));
    });

    final shape = ChainShape()..createChain(groundPoints);

    final bodyDef = BodyDef(
      position: Vector2.zero(),
      type: BodyType.static,
    );

    final body = world.createBody(bodyDef);
    final fixtureDef = FixtureDef(
      shape,
      friction: 0.9,
      restitution: 0.05,
    );
    body.createFixture(fixtureDef);
    return body;
  }
}

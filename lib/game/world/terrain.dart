import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import '../../models/map_theme.dart';
import '../../models/round_config.dart';
import '../garagum_racing_game.dart';

/// Struct representing a bridge span along the x-axis.
class BridgeSpan {
  const BridgeSpan({
    required this.startX,
    required this.endX,
  });

  final double startX;
  final double endX;

  double get width => endX - startX;
}

/// Procedural sand-dune ground built from a chain of static line segments,
/// incorporating periodic canal dips where bridges span across.
class Terrain extends BodyComponent {
  Terrain({
    this.segmentWidth = 0.35,
    RoundConfig? roundConfig,
    this.theme = MapTheme.garagum,
  })  : segmentCount = roundConfig != null
            ? ((roundConfig.distanceMeters + 60.0) / 0.35).ceil().clamp(500, 16000)
            : 3000,
        super(renderBody: false) {
    // Ashgabat is a paved city street — no canals/bridges, so its span
    // list stays empty and every bridge-spawn loop naturally no-ops.
    if (theme == MapTheme.garagum) _generateBridgeSpans();
  }

  final double segmentWidth;
  final int segmentCount;
  final MapTheme theme;

  static const double canalDepth = 6.5;

  /// List of procedurally generated bridge spans.
  final List<BridgeSpan> bridgeSpans = [];

  /// How many meters of world-space one tile of each texture covers.
  static const double _fillTileMeters = 6.0;
  static const double _topStripHeightMeters = 0.8;

  /// How far below the lowest ground point the fill texture extends.
  static const double _fillDepthMeters = 60.0;

  late final List<Vector2> groundPoints;

  /// Ground render paths, split into fixed-width chunks along x so [render]
  /// can draw only the chunks inside the camera view. A single path spanning
  /// the whole round (up to ~5.5 km ≈ 16k vertices) would be re-tessellated
  /// by Skia every frame even though only ~40 m of it is ever visible.
  static const int _chunkSegments = 100;
  final List<ui.Path> _fillChunks = [];
  final List<ui.Path> _topChunks = [];
  late final double _chunkWidth;
  late final ui.Paint _fillPaint;
  late final ui.Paint _topPaint;

  void _generateBridgeSpans() {
    // Generate bridges every ~180-220 meters starting after x = 130m
    double curX = 130.0;
    final maxWorldX = segmentCount * segmentWidth;

    while (curX < maxWorldX - 40.0) {
      final spanWidth = 22.0;
      bridgeSpans.add(BridgeSpan(startX: curX, endX: curX + spanWidth));
      curX += 190.0;
    }
  }

  double baseHeightAt(double x) {
    switch (theme) {
      case MapTheme.ashgabat:
        // Flat paved street — gentle rolling only, no dune-scale relief.
        return sin(x * 0.04) * 0.35 + sin(x * 0.011 + 0.6) * 0.5 + 4.0;
      case MapTheme.yangykala:
        // Canyon mesa cliffs & steep step plateaus
        return sin(x * 0.05) * 4.5 + sin(x * 0.02) * 5.0 + sin(x * 0.12) * 2.0 + 7.0;
      case MapTheme.derweze:
        // Nighttime desert dunes & gentle crater dips
        return sin(x * 0.08) * 2.8 + sin(x * 0.025) * 5.5 + sin(x * 0.006 + 1.2) * 2.0 + 5.5;
      case MapTheme.garagum:
        return sin(x * 0.09) * 3.0 +
            sin(x * 0.03) * 6.0 +
            sin(x * 0.005 + 1.7) * 2.5 +
            6.0;
    }
  }

  /// Returns the elevation (height) of the ground surface at x.
  /// Higher return value means higher ground level (world Y = -heightAt(x)).
  double heightAt(double x) {
    final baseH = baseHeightAt(x);

    for (final span in bridgeSpans) {
      final bStart = span.startX;
      final bEnd = span.endX;
      final bridgeDeckH = baseHeightAt(bStart);
      final canalBedH = bridgeDeckH - canalDepth;

      const rampLength = 12.0; // 12m gentle slope before & after bridge

      if (x >= bStart - rampLength && x <= bEnd + rampLength) {
        if (x >= bStart + 2.5 && x <= bEnd - 2.5) {
          // Canal water bed directly underneath bridge center
          return canalBedH;
        } else if (x > bStart && x < bStart + 2.5) {
          // Slope down into canal under left side of bridge
          final t = (x - bStart) / 2.5;
          final smoothT = (1 - cos(t * pi)) / 2;
          return bridgeDeckH + (canalBedH - bridgeDeckH) * smoothT;
        } else if (x > bEnd - 2.5 && x < bEnd) {
          // Slope up out of canal under right side of bridge
          final t = (x - (bEnd - 2.5)) / 2.5;
          final smoothT = (1 - cos(t * pi)) / 2;
          return canalBedH + (bridgeDeckH - canalBedH) * smoothT;
        } else if (x >= bStart - 2.5 && x <= bEnd + 2.5) {
          // Flat approach & exit deck level
          return bridgeDeckH;
        } else if (x < bStart - 2.5) {
          // Smooth, gentle entry slope from dune terrain to bridge deck
          final t = (x - (bStart - rampLength)) / (rampLength - 2.5);
          final smoothT = (1 - cos(t.clamp(0.0, 1.0) * pi)) / 2;
          return baseH + (bridgeDeckH - baseH) * smoothT;
        } else {
          // Smooth, gentle exit slope from bridge deck back to dune terrain
          final t = (x - (bEnd + 2.5)) / (rampLength - 2.5);
          final smoothT = (1 - cos(t.clamp(0.0, 1.0) * pi)) / 2;
          final exitBaseH = baseHeightAt(bEnd + rampLength);
          return bridgeDeckH + (exitBaseH - bridgeDeckH) * smoothT;
        }
      }
    }

    return baseH;
  }

  /// Checks if x falls within any bridge deck span or its canal embankment.
  bool isInsideBridgeSpan(double x, {double extraMargin = 12.0}) {
    for (final span in bridgeSpans) {
      if (x >= span.startX - extraMargin && x <= span.endX + extraMargin) {
        return true;
      }
    }
    return false;
  }

  /// Computes ground slope angle (radians) at position x.
  double getGroundAngle(double x) {
    final dx = 0.4;
    final h1 = heightAt(x - dx);
    final h2 = heightAt(x + dx);
    return atan2(-(h2 - h1), dx * 2);
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
      restitution: 0.0,
    );

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    late final String fillPath;
    late final String topPath;

    switch (theme) {
      case MapTheme.ashgabat:
        fillPath = 'images_ashgabat/terrain/asphalt_fill.png';
        topPath = 'images_ashgabat/terrain/asphalt_top.png';
        break;
      case MapTheme.yangykala:
        fillPath = 'images_yangykala/terrain/rock_layers_fill.png';
        topPath = 'images_yangykala/terrain/rock_top.png';
        break;
      case MapTheme.derweze:
        fillPath = 'images_derweze/terrain/sand_fill.png';
        topPath = 'images_derweze/terrain/sand_top.png';
        break;
      case MapTheme.garagum:
        fillPath = 'terrain/terrain_fill.png';
        topPath = 'terrain/terrain_top.png';
        break;
    }

    final fillImg = await Flame.images.load(fillPath);
    final topImg = await Flame.images.load(topPath);

    final fillScale = _fillTileMeters / fillImg.width;
    _fillPaint = ui.Paint()
      ..shader = ui.ImageShader(
        fillImg,
        ui.TileMode.repeated,
        ui.TileMode.repeated,
        (Matrix4.identity()..scaleByDouble(fillScale, fillScale, 1, 1)).storage,
      );

    _topPaint = ui.Paint()
      ..shader = ui.ImageShader(
        topImg,
        ui.TileMode.repeated,
        ui.TileMode.clamp,
        (Matrix4.identity()..scaleByDouble(fillScale, fillScale, 1, 1)).storage,
      );

    _buildPaths();
  }

  void _buildPaths() {
    _chunkWidth = _chunkSegments * segmentWidth;
    if (groundPoints.isEmpty) return;

    // One shared bottom edge for every fill chunk, so adjacent chunks join
    // along the same horizontal line with no visible seams.
    final minY = groundPoints.map((p) => p.y).reduce(min);
    final bottomY = minY + _fillDepthMeters;

    for (int start = 0; start < groundPoints.length - 1;
        start += _chunkSegments) {
      // Overlap by one point with the next chunk so surfaces stay continuous.
      final end = min(start + _chunkSegments, groundPoints.length - 1);

      final fill = ui.Path()..moveTo(groundPoints[start].x, groundPoints[start].y);
      for (int i = start + 1; i <= end; i++) {
        fill.lineTo(groundPoints[i].x, groundPoints[i].y);
      }
      fill.lineTo(groundPoints[end].x, bottomY);
      fill.lineTo(groundPoints[start].x, bottomY);
      fill.close();
      _fillChunks.add(fill);

      final top = ui.Path()..moveTo(groundPoints[start].x, groundPoints[start].y);
      for (int i = start + 1; i <= end; i++) {
        top.lineTo(groundPoints[i].x, groundPoints[i].y);
      }
      for (int i = end; i >= start; i--) {
        top.lineTo(
          groundPoints[i].x,
          groundPoints[i].y + _topStripHeightMeters,
        );
      }
      top.close();
      _topChunks.add(top);
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (_fillChunks.isEmpty) return;

    var first = 0;
    var last = _fillChunks.length - 1;
    final g = game;
    // The visible range starts as ±infinity until the game's first full
    // update tick — floor()/ceil() on an infinite double would throw.
    if (g is GaragumRacingGame &&
        g.visibleWorldLeft.isFinite &&
        g.visibleWorldRight.isFinite) {
      first = ((g.visibleWorldLeft) / _chunkWidth)
          .floor()
          .clamp(0, _fillChunks.length - 1);
      last = ((g.visibleWorldRight) / _chunkWidth)
          .ceil()
          .clamp(0, _fillChunks.length - 1);
    }

    for (int i = first; i <= last; i++) {
      canvas.drawPath(_fillChunks[i], _fillPaint);
      canvas.drawPath(_topChunks[i], _topPaint);
    }
  }
}

import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/widgets.dart' show ImageRepeat, Alignment;

import '../../models/map_theme.dart';

/// Multi-layer scrolling backdrop, one layer set per [MapTheme]. Loaded once
/// and set as `camera.backdrop` so it renders behind the world, unaffected
/// by zoom.
///
/// Each layer's [ParallaxLayer.velocityMultiplier] is the fraction of the
/// camera's screen-space speed it scrolls at — the game drives the shared
/// `baseVelocity` from actual camera movement every frame.
class ParallaxBackground {
  static const List<(String path, double speed)> _garagumLayers = [
    ('parallax/garagum_sky.png', 0.05),
    ('parallax/garagum_far_dunes.png', 0.15),
    ('parallax/garagum_mid_dunes.png', 0.35),
    ('parallax/garagum_near_dunes.png', 0.60),
  ];

  static const List<(String path, double speed)> _ashgabatLayers = [
    ('images_ashgabat/parallax/ashgabat_sky.png', 0.05),
    ('images_ashgabat/parallax/kopetdag_far.png', 0.10),
    ('images_ashgabat/parallax/kopetdag_mid.png', 0.20),
    ('images_ashgabat/parallax/kopetdag_near.png', 0.30),
    ('images_ashgabat/parallax/city_far.png', 0.45),
    ('images_ashgabat/parallax/city_near.png', 0.65),
  ];

  static const List<(String path, double speed)> _yangykalaLayers = [
    ('images_yangykala/parallax/yangykala_sky.png', 0.05),
    ('images_yangykala/parallax/mesa_far.png', 0.15),
    ('images_yangykala/parallax/mesa_mid.png', 0.30),
    ('images_yangykala/parallax/mesa_near.png', 0.55),
  ];

  static const List<(String path, double speed)> _derwezeLayers = [
    ('images_derweze/parallax/derweze_sky.png', 0.05),
    ('images_derweze/parallax/dunes_far.png', 0.15),
    ('images_derweze/parallax/dunes_mid.png', 0.35),
    ('images_derweze/parallax/dunes_near.png', 0.60),
  ];

  static List<(String path, double speed)> _layersFor(MapTheme theme) {
    switch (theme) {
      case MapTheme.garagum:
        return _garagumLayers;
      case MapTheme.ashgabat:
        return _ashgabatLayers;
      case MapTheme.yangykala:
        return _yangykalaLayers;
      case MapTheme.derweze:
        return _derwezeLayers;
    }
  }

  static Future<ParallaxComponent> load(
    Vector2 size, {
    MapTheme theme = MapTheme.garagum,
  }) async {
    final layers = await Future.wait(
      _layersFor(theme).map(
        (layer) => ParallaxLayer.load(
          ParallaxImageData(layer.$1),
          velocityMultiplier: Vector2(layer.$2, 0),
          repeat: ImageRepeat.repeatX,
          fill: LayerFill.height,
          alignment: Alignment.bottomCenter,
        ),
      ),
    );
    return ParallaxComponent(parallax: Parallax(layers, size: size));
  }
}

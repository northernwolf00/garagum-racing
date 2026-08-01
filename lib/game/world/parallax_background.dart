import 'package:flame/components.dart';
import 'package:flame/parallax.dart';

/// Four-layer Garagum dune backdrop. Loaded once and set as
/// `camera.backdrop` so it renders behind the world, unaffected by zoom.
///
/// Each layer's [ParallaxLayer.velocityMultiplier] is the fraction of the
/// camera's screen-space speed it scrolls at (spec: sky 0.05, far dunes
/// 0.15, mid dunes 0.35, near dunes 0.60) — the game drives the shared
/// `baseVelocity` from actual camera movement every frame.
class ParallaxBackground {
  static const List<(String path, double speed)> _layers = [
    ('parallax/garagum_sky.png', 0.05),
    ('parallax/garagum_far_dunes.png', 0.15),
    ('parallax/garagum_mid_dunes.png', 0.35),
    ('parallax/garagum_near_dunes.png', 0.60),
  ];

  static Future<ParallaxComponent> load(Vector2 size) async {
    final layers = await Future.wait(
      _layers.map(
        (layer) => ParallaxLayer.load(
          ParallaxImageData(layer.$1),
          velocityMultiplier: Vector2(layer.$2, 0),
        ),
      ),
    );
    return ParallaxComponent(parallax: Parallax(layers, size: size));
  }
}

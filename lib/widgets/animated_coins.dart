import 'package:flutter/material.dart';

/// A coin/number label that smoothly counts up (or down) whenever [value]
/// changes, instead of snapping to the new amount.
///
/// Lightweight by design — it uses [TweenAnimationBuilder], so only this one
/// text widget rebuilds during the count, never the surrounding tree. The very
/// first build shows [value] directly (no distracting count-from-zero).
class AnimatedCoins extends StatelessWidget {
  const AnimatedCoins(
    this.value, {
    super.key,
    this.style,
    this.textAlign,
    this.duration = const Duration(milliseconds: 550),
  });

  final int value;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      // begin == end means the first frame shows the current value; when [value]
      // changes on a later build, TweenAnimationBuilder animates from the value
      // it is currently displaying to the new end.
      tween: IntTween(begin: value, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '$v',
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}

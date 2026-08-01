import 'package:flutter/material.dart';

/// Big thumb-friendly hold-to-drive pedal used for gas/brake, rendered with
/// the pedal_gas/pedal_brake art (normal + pressed states) instead of a
/// plain icon.
///
/// Calls [onPressedChanged] with `true` on press and `false` on release
/// (including when the finger slides off the button), matching how a real
/// pedal behaves rather than a single tap.
class PedalButton extends StatefulWidget {
  const PedalButton({
    super.key,
    required this.assetPath,
    required this.pressedAssetPath,
    required this.onPressedChanged,
    this.width = 96,
  });

  final String assetPath;
  final String pressedAssetPath;
  final ValueChanged<bool> onPressedChanged;
  final double width;

  @override
  State<PedalButton> createState() => _PedalButtonState();
}

class _PedalButtonState extends State<PedalButton> {
  // pedal_gas.png / pedal_brake.png are 256x360.
  static const double _artAspectRatio = 256 / 360;

  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
    widget.onPressedChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Image.asset(
          _pressed ? widget.pressedAssetPath : widget.assetPath,
          width: widget.width,
          height: widget.width / _artAspectRatio,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Big thumb-friendly hold-to-drive button used for gas/brake.
///
/// Calls [onPressedChanged] with `true` on press and `false` on release
/// (including when the finger slides off the button), matching how a real
/// pedal behaves rather than a single tap.
class PedalButton extends StatefulWidget {
  const PedalButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressedChanged,
  });

  final IconData icon;
  final Color color;
  final ValueChanged<bool> onPressedChanged;

  @override
  State<PedalButton> createState() => _PedalButtonState();
}

class _PedalButtonState extends State<PedalButton> {
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: _pressed ? 0.95 : 0.65),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: _pressed ? 4 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(widget.icon, color: Colors.white, size: 40),
      ),
    );
  }
}

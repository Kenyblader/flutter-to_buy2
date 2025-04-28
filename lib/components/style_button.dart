import 'package:flutter/material.dart';

class StyleButton extends StatelessWidget {
  final void Function() onPressed;
  final Widget child;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final bool enable;

  const StyleButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.borderRadius = 8.0,
    this.enable = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: enable ? onPressed : null,
      style: TextButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: child,
    );
  }
}

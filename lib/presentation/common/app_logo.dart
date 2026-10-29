import 'package:flutter/material.dart';

/// The water-drop mark shown on the splash and sign-in screens.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        Icons.water_drop_rounded,
        size: size * 0.55,
        color: colors.onPrimaryContainer,
      ),
    );
  }
}

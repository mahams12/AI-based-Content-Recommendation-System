import 'package:flutter/material.dart';

class HamburgerMenuButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color? color;
  final double? size;

  const HamburgerMenuButton({
    super.key,
    required this.onTap,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.menu_rounded,
          color: color ?? Colors.white,
          size: size ?? 24,
        ),
      ),
    );
  }
}

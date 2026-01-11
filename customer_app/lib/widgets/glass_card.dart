import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color? color;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final bool useThickMaterial;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.color,
    this.padding,
    this.margin,
    this.borderRadius,
    this.useThickMaterial = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius ?? 24),
          color: color ?? Colors.white, // White container on grey background
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

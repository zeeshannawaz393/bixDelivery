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

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.color,
    this.padding,
    this.margin,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? 20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius ?? 20),
              color: (color ?? AppColors.glassBackground),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 1.5,
              ),
            ),
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}


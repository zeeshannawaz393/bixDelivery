import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class GlassDropdown extends StatelessWidget {
  final String? label;
  final String? value;
  final String? hint;
  final VoidCallback onTap;
  final Widget? prefixIcon;

  const GlassDropdown({
    super.key,
    this.label,
    this.value,
    this.hint,
    required this.onTap,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: Row(
                children: [
                  if (prefixIcon != null) ...[
                    prefixIcon!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      value ?? hint ?? 'Select',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: value != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary.withValues(alpha: 0.7),
                        letterSpacing: -0.4,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


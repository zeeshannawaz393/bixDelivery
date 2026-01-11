import 'package:flutter/material.dart';
import '../utils/colors.dart';

class GlassInputField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;

  const GlassInputField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  State<GlassInputField> createState() => _GlassInputFieldState();
}

class _GlassInputFieldState extends State<GlassInputField> {
  final GlobalKey<FormFieldState> _fieldKey = GlobalKey<FormFieldState>();
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: BoxConstraints(
            minHeight: 56,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(
              color: _errorText != null 
                  ? AppColors.error.withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _errorText != null
                    ? AppColors.error.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
          child: TextFormField(
              key: _fieldKey,
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              validator: (value) {
                final error = widget.validator?.call(value);
                setState(() {
                  _errorText = error;
                });
                return error;
              },
              onTap: widget.onTap,
              readOnly: widget.readOnly,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              onChanged: (value) {
                if (_errorText != null) {
                  _fieldKey.currentState?.validate();
                }
                widget.onChanged?.call(value);
              },
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
              decoration: TextDecoration.none,
              decorationThickness: 0,
            ),
              textAlignVertical: widget.maxLines != null && widget.maxLines! > 1
                  ? TextAlignVertical.top
                  : TextAlignVertical.center,
            decoration: InputDecoration(
                hintText: widget.label ?? widget.hint,
              hintStyle: TextStyle(
                fontSize: 16,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
                letterSpacing: -0.3,
                decoration: TextDecoration.none,
                decorationThickness: 0,
              ),
                prefixIcon: widget.prefixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.only(left: 4, right: 8),
                        child: widget.prefixIcon,
                      )
                    : null,
                suffixIcon: widget.suffixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: widget.suffixIcon,
                      )
                    : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
                errorStyle: const TextStyle(height: 0, fontSize: 0),
                contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                  vertical: widget.maxLines != null && widget.maxLines! > 1 ? 18 : 0,
              ),
                isDense: widget.maxLines == null || widget.maxLines == 1,
                counterText: '',
                alignLabelWithHint: false,
              ),
            ),
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 14,
                  color: AppColors.error,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _errorText!,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}


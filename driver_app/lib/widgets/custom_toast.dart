import 'package:flutter/material.dart';
import '../utils/colors.dart';

enum ToastType { success, error, warning, info }

class CustomToast {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  static void show({
    required BuildContext context,
    required String message,
    required ToastType type,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    // Hide existing toast if any
    if (_isVisible) {
      hide();
    }

    try {
      // Check if context is still valid
      if (!context.mounted) {
        debugPrint('⚠️ [CUSTOM TOAST] Context is not mounted, cannot show toast: $message');
        return;
      }

      // Use rootOverlay to ensure we can always show the toast
      final overlay = Overlay.of(context, rootOverlay: true);
      _overlayEntry = _createOverlayEntry(context, message, type, icon);
      overlay.insert(_overlayEntry!);
      _isVisible = true;

      // Auto hide after duration
      Future.delayed(duration, () {
        hide();
      });
    } catch (e) {
      // If overlay is not available, just print the message
      // This can happen if context is invalid or widget tree is being disposed
      debugPrint('⚠️ [CUSTOM TOAST] Cannot show toast: $message');
      debugPrint('   Error: $e');
    }
  }

  static OverlayEntry _createOverlayEntry(
    BuildContext context,
    String message,
    ToastType type,
    IconData? icon,
  ) {
    Color backgroundColor;
    Color textColor = Colors.white;
    IconData defaultIcon;

    switch (type) {
      case ToastType.success:
        backgroundColor = AppColors.success;
        defaultIcon = Icons.check_circle_outline;
        break;
      case ToastType.error:
        backgroundColor = AppColors.error;
        defaultIcon = Icons.error_outline;
        break;
      case ToastType.warning:
        backgroundColor = AppColors.warning;
        defaultIcon = Icons.warning_amber_rounded;
        break;
      case ToastType.info:
        backgroundColor = AppColors.info;
        defaultIcon = Icons.info_outline;
        break;
    }

    return OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: backgroundColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    icon ?? defaultIcon,
                    color: textColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: hide,
                    child: Icon(
                      Icons.close,
                      color: textColor.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void hide() {
    if (_overlayEntry != null && _isVisible) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isVisible = false;
    }
  }

  // Convenience methods
  static void success(BuildContext context, String message, {Duration? duration}) {
    show(
      context: context,
      message: message,
      type: ToastType.success,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void error(BuildContext context, String message, {Duration? duration}) {
    show(
      context: context,
      message: message,
      type: ToastType.error,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  static void warning(BuildContext context, String message, {Duration? duration}) {
    show(
      context: context,
      message: message,
      type: ToastType.warning,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void info(BuildContext context, String message, {Duration? duration}) {
    show(
      context: context,
      message: message,
      type: ToastType.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
}


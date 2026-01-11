import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../utils/colors.dart';

class SlideButton extends StatefulWidget {
  final String text;
  final VoidCallback onSlideComplete;
  final Color backgroundColor;
  final Color sliderColor;
  final double height;
  final double borderRadius;

  const SlideButton({
    super.key,
    required this.text,
    required this.onSlideComplete,
    this.backgroundColor = AppColors.primaryBlue,
    this.sliderColor = Colors.white,
    this.height = 56,
    this.borderRadius = 28,
  });

  @override
  State<SlideButton> createState() => _SlideButtonState();
}

class _SlideButtonState extends State<SlideButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragPosition = 0.0;
  bool _isDragging = false;
  double _maxDragDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    HapticFeedback.selectionClick();
  }

  void _onDragUpdate(DragUpdateDetails details, double buttonWidth) {
    setState(() {
      _maxDragDistance = buttonWidth - widget.height;
      _dragPosition = math.max(0.0, math.min(_maxDragDistance, _dragPosition + details.delta.dx));
      
      // Calculate progress (0.0 to 1.0)
      final progress = _dragPosition / _maxDragDistance;
      _controller.value = progress;
      
      // If dragged more than 80%, trigger completion
      if (progress >= 0.8 && !_controller.isCompleted) {
        _completeSlide();
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final progress = _dragPosition / _maxDragDistance;
    
    if (progress >= 0.8) {
      _completeSlide();
    } else {
      // Snap back to start
      setState(() {
        _isDragging = false;
        _dragPosition = 0.0;
      });
      _controller.reverse();
    }
  }

  void _completeSlide() {
    HapticFeedback.mediumImpact();
    _controller.forward().then((_) {
      widget.onSlideComplete();
      // Reset after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isDragging = false;
            _dragPosition = 0.0;
          });
          _controller.reset();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth = constraints.maxWidth;
        _maxDragDistance = buttonWidth - widget.height;

        return GestureDetector(
          onHorizontalDragStart: (details) => _onDragStart(details),
          onHorizontalDragUpdate: (details) => _onDragUpdate(details, buttonWidth),
          onHorizontalDragEnd: _onDragEnd,
          child: Container(
            width: double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: widget.backgroundColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Text (centered, hidden behind slider when dragging)
                Center(
                  child: AnimatedOpacity(
                    opacity: _dragPosition / _maxDragDistance > 0.5 ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      widget.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                // Slider
                AnimatedPositioned(
                  duration: _isDragging
                      ? const Duration(milliseconds: 0)
                      : const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  left: math.max(4.0, math.min(_maxDragDistance, _dragPosition)),
                  top: 4,
                  child: Container(
                    width: widget.height - 8,
                    height: widget.height - 8,
                    decoration: BoxDecoration(
                      color: widget.sliderColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


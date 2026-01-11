import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/colors.dart';

class SlackBottomNavItem {
  final IconData icon;
  final IconData? filledIcon;
  final String label;
  final String semanticLabel;

  SlackBottomNavItem({
    required this.icon,
    this.filledIcon,
    required this.label,
    required this.semanticLabel,
  });
}

class SlackPrismBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<SlackBottomNavItem> items;
  final Color primaryColor;
  final double barHeight;
  final double pillHeight;

  const SlackPrismBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.primaryColor = AppColors.primaryBlue,
    this.barHeight = 64.0,
    this.pillHeight = 56.0, // 52-60 range
  });

  @override
  State<SlackPrismBottomNav> createState() => _SlackPrismBottomNavState();
}

class _SlackPrismBottomNavState extends State<SlackPrismBottomNav>
    with TickerProviderStateMixin {
  late AnimationController _springController;
  late AnimationController _scaleController;
  late Animation<double> _springAnimation;
  late List<Animation<double>> _scaleAnimations;
  
  int _previousIndex = 0;
  double _dragPosition = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;

    // Spring animation for lens movement
    _springController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _springAnimation = CurvedAnimation(
      parent: _springController,
      curve: Curves.easeOutCubic, // Spring-like curve
    );

    // Scale animation for tap feedback
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimations = List.generate(
      widget.items.length,
      (index) => Tween<double>(begin: 1.0, end: 0.9).animate(
        CurvedAnimation(
          parent: _scaleController,
          curve: Curves.easeInOut,
        ),
      ),
    );

    _springController.forward();
  }

  @override
  void didUpdateWidget(SlackPrismBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_isDragging) {
      _previousIndex = oldWidget.currentIndex;
      _springController.reset();
      _springController.forward();
    }
  }

  @override
  void dispose() {
    _springController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    HapticFeedback.selectionClick();
    
    // Scale animation
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });

    widget.onTap(index);
  }

  double _getItemCenterX(int index, double itemWidth) {
    return (index * itemWidth) + (itemWidth / 2);
  }

  int _getIndexFromPosition(double position, double itemWidth) {
    return (position / itemWidth).round().clamp(0, widget.items.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: widget.barHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.hardEdge,
            child: LayoutBuilder(
              builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / widget.items.length;
                    final pillWidth = itemWidth * 0.85; // Reduced width
                    
                    // Calculate current pill position
                    double pillCenterX;
                    if (_isDragging) {
                      pillCenterX = _dragPosition;
                    } else {
                      final previousCenterX = _getItemCenterX(_previousIndex, itemWidth);
                      final currentCenterX = _getItemCenterX(widget.currentIndex, itemWidth);
                      pillCenterX = Tween<double>(
                        begin: previousCenterX,
                        end: currentCenterX,
                      ).animate(_springAnimation).value;
                    }

                    return GestureDetector(
                      onHorizontalDragStart: (details) {
                        setState(() {
                          _isDragging = true;
                          _dragPosition = details.localPosition.dx;
                        });
                      },
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _dragPosition = details.localPosition.dx;
                          final newIndex = _getIndexFromPosition(_dragPosition, itemWidth);
                          if (newIndex != widget.currentIndex) {
                            widget.onTap(newIndex);
                          }
                        });
                      },
                      onHorizontalDragEnd: (details) {
                        // Snap to nearest item
                        final nearestIndex = _getIndexFromPosition(_dragPosition, itemWidth);
                        
                        if (nearestIndex != widget.currentIndex) {
                          widget.onTap(nearestIndex);
                        }
                        
                        setState(() {
                          _isDragging = false;
                          _previousIndex = widget.currentIndex;
                          _springController.reset();
                          _springController.forward();
                        });
                      },
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          // Glassy prism pill highlight (behind items)
                          Positioned(
                            left: (pillCenterX - pillWidth / 2).clamp(
                              0.0,
                              constraints.maxWidth - pillWidth,
                            ),
                            top: (widget.barHeight - widget.pillHeight) / 2,
                            child: _PrismPill(
                              width: pillWidth,
                              height: widget.pillHeight,
                              blurSigma: 22.0, // 18-26 range
                              whiteOpacity: 0.12, // 0.08-0.16 range
                            ),
                          ),
                          // Tab items (on top of pill)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: widget.items.asMap().entries.map((entry) {
                              int index = entry.key;
                              SlackBottomNavItem item = entry.value;
                              bool isSelected = index == widget.currentIndex;
                              bool isRequestsButton = index == 1; // Requests is at index 1

                              return Expanded(
                                child: _SlackTabItem(
                                  item: item,
                                  isSelected: isSelected,
                                  primaryColor: widget.primaryColor,
                                  onTap: () => _handleTap(index),
                                  scaleAnimation: _scaleAnimations[index],
                                  isRequestsButton: isRequestsButton,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Glassy prism pill with iridescent border
class _PrismPill extends StatelessWidget {
  final double width;
  final double height;
  final double blurSigma;
  final double whiteOpacity;

  const _PrismPill({
    required this.width,
    required this.height,
    this.blurSigma = 22.0,
    this.whiteOpacity = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999), // Very high border radius for pill shape
        boxShadow: [
          // Soft shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withValues(alpha: 0.9),
        ),
        child: Stack(
          children: [
            // Inner light highlight streak (top)
            Positioned(
              top: height * 0.1,
              left: width * 0.2,
              right: width * 0.2,
              child: Container(
                height: height * 0.15,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Individual tab item
class _SlackTabItem extends StatelessWidget {
  final SlackBottomNavItem item;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;
  final Animation<double> scaleAnimation;
  final bool isRequestsButton;

  const _SlackTabItem({
    required this.item,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
    required this.scaleAnimation,
    this.isRequestsButton = false,
  });

  @override
  Widget build(BuildContext context) {
    // Special styling for Requests button - blue rectangular button when selected
    if (isRequestsButton && isSelected) {
      return Semantics(
        label: item.semanticLabel,
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Default styling for other buttons
    return Semantics(
      label: item.semanticLabel,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          child: ScaleTransition(
            scale: scaleAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: Icon(
                      isSelected && item.filledIcon != null
                          ? item.filledIcon!
                          : item.icon,
                      key: ValueKey(isSelected),
                      color: isSelected
                          ? primaryColor
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Label
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? primaryColor
                          : AppColors.textSecondary,
                      letterSpacing: -0.2,
                      height: 1.0,
                    ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}


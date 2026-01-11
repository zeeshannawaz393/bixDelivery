import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/colors.dart';

class BottomNavItem {
  final IconData icon;
  final IconData? filledIcon; // Filled version for active state
  final String label;
  final String? earnings; // For earnings tab
  final String semanticLabel; // For accessibility

  BottomNavItem({
    required this.icon,
    this.filledIcon,
    required this.label,
    this.earnings,
    required this.semanticLabel,
  });
}

class GlassBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  final Color primaryColor;

  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.primaryColor = AppColors.primaryBlue,
  });

  @override
  State<GlassBottomNavBar> createState() => _GlassBottomNavBarState();
}

class _GlassBottomNavBarState extends State<GlassBottomNavBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _scaleAnimations;
  final Map<int, GlobalKey> _tabKeys = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimations = List.generate(
      widget.items.length,
      (index) => Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      ),
    );

    // Initialize tab keys
    for (int i = 0; i < widget.items.length; i++) {
      _tabKeys[i] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    // Haptic feedback
    HapticFeedback.selectionClick();

    // Scale animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Call the onTap callback
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 64, // ~64pt height
          decoration: BoxDecoration(
            // White background
            color: Colors.white,
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2), // Subtle border
              width: 1,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              // Soft, diffused shadow for floating depth
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / widget.items.length;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: widget.items.asMap().entries.map((entry) {
                  int index = entry.key;
                  BottomNavItem item = entry.value;
                  bool isSelected = index == widget.currentIndex;

                  return Expanded(
                    key: _tabKeys[index],
                    child: _TabItem(
                      item: item,
                      isSelected: isSelected,
                      primaryColor: widget.primaryColor,
                      onTap: () => _handleTap(index),
                      scaleAnimation: _scaleAnimations[index],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final BottomNavItem item;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;
  final Animation<double> scaleAnimation;

  const _TabItem({
    required this.item,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: item.semanticLabel,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with active state animation
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    isSelected && item.filledIcon != null
                        ? (item.filledIcon ?? item.icon)
                        : item.icon,
                    key: ValueKey(isSelected),
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                // Label or Earnings
                if (item.earnings != null)
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      letterSpacing: -0.2,
                      height: 1.0,
                    ),
                    child: Text(
                      item.earnings!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  // Label with active state styling
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
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
    );
  }
}

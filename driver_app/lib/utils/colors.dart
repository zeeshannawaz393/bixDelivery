import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Bix Brand
  static const Color black = Color(0xFF000000); // "Bix" wordmark text - Strength, clarity, professionalism
  static const Color green = Color(0xFF47C153); // Forward arrow symbol - Growth, progress, action, success
  
  // Supporting Color
  static const Color white = Color(0xFFFFFFFF); // Background / negative space - Simplicity, contrast, cleanliness
  
  // Legacy aliases for backward compatibility (mapped to new colors)
  static const Color primaryBlue = green; // Use green instead of blue
  static const Color primaryBlueDark = Color(0xFF3AA045); // Darker green
  static const Color primaryBlueLight = Color(0xFF6BD177); // Lighter green
  static const Color softCyan = Color(0xFF8FE09A); // Very light green
  
  // iOS Materials (Frosted Glass) - using white
  static Color ultraThinMaterial = white.withValues(alpha: 0.05);
  static Color thinMaterial = white.withValues(alpha: 0.1);
  static Color regularMaterial = white.withValues(alpha: 0.15);
  static Color thickMaterial = white.withValues(alpha: 0.2);
  static Color ultraThickMaterial = white.withValues(alpha: 0.3);
  
  // Glass Effects
  static Color glassBackground = white.withValues(alpha: 0.1);
  static Color glassBorder = white.withValues(alpha: 0.2);
  static Color glassBackgroundDark = black.withValues(alpha: 0.1);
  
  // Tab Colors
  static Color selectedTab = green;
  static Color unselectedTab = white.withValues(alpha: 0.5);
  
  // Text Colors
  static const Color textPrimary = black; // Primary text
  static const Color textSecondary = Color(0xFF8E8E93); // Secondary text
  static const Color textTertiary = Color(0xFFC7C7CC);
  static Color selectedText = green;
  static Color unselectedText = white.withValues(alpha: 0.5);
  
  // Background
  static const Color backgroundLight = white; // Use white background
  static const Color backgroundDark = black;
  
  // Status Colors
  static const Color success = green; // Use brand green for success
  static const Color error = Color(0xFFFF3B30); // Keep red for errors
  static const Color warning = Color(0xFFFF9500); // Keep orange for warnings
  static const Color info = green; // Use green for info
  
  // Glass Button Gradient - Green gradient
  static LinearGradient get blueGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [green, softCyan],
  );
  
  // Green gradient for buttons
  static LinearGradient get greenGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [green, softCyan],
  );
}





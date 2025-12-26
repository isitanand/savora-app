import 'package:flutter/material.dart';

class CoreTheme {
  // STRIPE-GRADE ANALYTICAL COLOR SYSTEM
  
  // Backgrounds
  static const Color analyticalBackground = Color(0xFFF7F8FA);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAFAFA);
  
  // Text
  static const Color deepInk = Color(0xFF0A0A0A);
  static const Color softGraphite = Color(0xFF6B7280);
  static const Color lightGrey = Color(0xFF9CA3AF);
  static const Color faintStone = Color(0xFFE5E7EB);
  static const Color paleGrey = Color(0xFFF3F4F6);
  
  // Analytical Accent (Stripe-like blue-purple)
  static const Color analyticalAccent = Color(0xFF6366F1);
  static const Color subtlePurple = Color(0xFF8B7FD8);
  static const Color softLavender = Color(0xFFA99BE8);
  
  // Status Colors (Restrained)
  static const Color positiveGreen = Color(0xFF10B981);
  static const Color negativeRed = Color(0xFFEF4444);
  
  // Legacy aliases
  static const Color quietBackground = analyticalBackground;
  static const Color matteSurface = pureWhite;
  static const Color primaryAccent = analyticalAccent;
  static const Color secondaryAccent = softLavender;
  
  // GRADIENTS (MINIMAL USE)
  static const LinearGradient premiumBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [analyticalBackground, pureWhite],
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [analyticalAccent, Color(0xFF8B5CF6)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [analyticalAccent, Color(0xFF8B5CF6)],
  );

  static const LinearGradient atmosphericGradient = premiumBackgroundGradient;
  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [pureWhite, offWhite],
  );

  // SHADOWS (SOFT ELEVATION)
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 2),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 8,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> premiumShadow = cardShadow;
  static final List<BoxShadow> softShadow = cardShadow;
  static final List<BoxShadow> floatingShadow = cardShadow;

  // TYPOGRAPHY (ANALYTICAL)
  static final TextTheme textTheme = TextTheme(
    displayLarge: const TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      color: deepInk,
      letterSpacing: -1.5,
      height: 1.1,
    ),
    displayMedium: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: deepInk,
      letterSpacing: -0.5,
    ),
    headlineSmall: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: deepInk,
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: deepInk,
      height: 1.5,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: softGraphite,
      height: 1.5,
    ),
    labelMedium: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: lightGrey,
      letterSpacing: 0.8,
    ),
    labelSmall: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: lightGrey,
    ),
  );

  // SHAPE
  static final ShapeBorder premiumShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16.0),
  );
  
  static final ShapeBorder quietShape = premiumShape;

  static const EdgeInsets cardPadding = EdgeInsets.all(20);
  static const double spacingWrapper = 24.0;
  static const double spacingSection = 32.0;
  static const double spacingItem = 16.0;

  // THEME DATA
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: analyticalBackground,
      colorScheme: const ColorScheme.light(
        primary: deepInk,
        onPrimary: pureWhite,
        secondary: analyticalAccent,
        background: analyticalBackground,
        surface: pureWhite,
        onSurface: deepInk,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: deepInk,
        ),
        iconTheme: IconThemeData(color: deepInk, size: 24),
      ),
      cardTheme: CardThemeData(
        color: pureWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: premiumShape,
      ),
      iconTheme: const IconThemeData(
        color: deepInk,
        size: 22,
      ),
      dividerTheme: DividerThemeData(
        color: paleGrey,
        thickness: 1,
      ),
    );
  }
  // MOOD COLORS
  static Color getMoodColor(String mood) {
    if (mood == 'Productive' || mood == 'Energetic' || mood == 'Focused') {
      return const Color(0xFF10B981); // Green
    } else if (mood == 'Calm' || mood == 'Balanced' || mood == 'Flow') {
      return const Color(0xFF06B6D4); // Cyan
    } else if (mood == 'Stressed' || mood == 'Regretful' || mood == 'Tired') {
      return const Color(0xFFF59E0B); // Amber
    } else if (mood == 'Drained' || mood == 'Overwhelmed') {
      return const Color(0xFFEF4444); // Red
    } else {
      return const Color(0xFF8B5CF6); // Purple default
    }
  }
}

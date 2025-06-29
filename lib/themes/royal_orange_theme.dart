import 'package:flutter/material.dart';

class RoyalOrangeTheme {
  // Color palette
  static const Color _primaryOrange = Color(0xFFFF9800); // Main royal orange
  static const Color _secondaryBlue = Color(0xFF1976D2); // Accent blue (triadic)
  static const Color _accentGreen = Color(0xFF43A047); // Accent green (triadic)
  static const Color _darkOrange = Color(0xFFE65100); // Dark orange for text
  static const Color _lightOrange = Color(0xFFFFF3E0); // Light background
  static const Color _surfaceOrange = Color(0xFFFFE0B2); // Card surfaces
  static const Color _mintOrange = Color(0xFFFFCC80); // Subtle accents

  static final ThemeData theme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: _lightOrange,
    primaryColor: _primaryOrange,
    colorScheme: const ColorScheme.light(
      primary: _primaryOrange,
      secondary: _secondaryBlue,
      tertiary: _accentGreen,
      surface: _surfaceOrange,
      background: _lightOrange,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _darkOrange,
      onBackground: _darkOrange,
      outline: Color(0xFFFFB300),
      outlineVariant: Color(0xFFFFE0B2),
      error: Color(0xFFD32F2F),
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryOrange,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white, 
        fontSize: 20, 
        fontWeight: FontWeight.w600
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryOrange,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: _primaryOrange.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryOrange,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _darkOrange, 
        fontSize: 32, 
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: _darkOrange, 
        fontSize: 28, 
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        color: _darkOrange, 
        fontSize: 24, 
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: _darkOrange, 
        fontSize: 22, 
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: _darkOrange, 
        fontSize: 18, 
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: _darkOrange, 
        fontSize: 16, 
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: _darkOrange, 
        fontSize: 16, 
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: _darkOrange, 
        fontSize: 14, 
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: Color(0xFFFF9800), 
        fontSize: 12, 
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: Colors.white, 
        fontSize: 14, 
        fontWeight: FontWeight.w600,
      ),
    ),
    iconTheme: const IconThemeData(
      color: _primaryOrange,
      size: 24,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryOrange,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    cardTheme: CardThemeData(
      color: _surfaceOrange,
      elevation: 2,
      shadowColor: _primaryOrange.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _surfaceOrange,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _primaryOrange, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFFFB300), width: 1),
      ),
      labelStyle: TextStyle(color: _darkOrange),
      hintStyle: TextStyle(color: Color(0xFFFFB300)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surfaceOrange,
      selectedItemColor: _primaryOrange,
      unselectedItemColor: Color(0xFFFFB300),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    dividerColor: const Color(0xFFFFE0B2),
    shadowColor: _primaryOrange.withOpacity(0.1),
    dialogTheme: const DialogThemeData(
      backgroundColor: _surfaceOrange,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      elevation: 8,
      titleTextStyle: TextStyle(
        color: _darkOrange,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _secondaryBlue,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _mintOrange,
      selectedColor: _primaryOrange,
      labelStyle: const TextStyle(color: _darkOrange),
      brightness: Brightness.light,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: _primaryOrange,
      inactiveTrackColor: _mintOrange,
      thumbColor: _secondaryBlue,
      overlayColor: _primaryOrange.withOpacity(0.2),
      valueIndicatorColor: _darkOrange,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryOrange,
      linearTrackColor: Color(0xFFFFE0B2),
      circularTrackColor: Color(0xFFFFE0B2),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: _primaryOrange,
      unselectedLabelColor: Color(0xFFFFB300),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: _primaryOrange, width: 2),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryOrange;
        }
        return const Color(0xFF9E9E9E);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryOrange.withOpacity(0.5);
        }
        return const Color(0xFFE0E0E0);
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryOrange;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: Color(0xFFFFB300), width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryOrange;
        }
        return const Color(0xFF9E9E9E);
      }),
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: _surfaceOrange,
      selectedTileColor: Color(0xFFFFCC80),
      iconColor: _primaryOrange,
      textColor: _darkOrange,
      selectedColor: _darkOrange,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: _secondaryBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      preferBelow: false,
    ),
  );
}
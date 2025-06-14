import 'package:flutter/material.dart';

class SunsetPeachTheme {
  // Color palette
  static const Color _primaryPeach = Color(0xFFFFB74D); // Main peach
  static const Color _secondaryPeach = Color(0xFFFB8C00); // Accent peach
  static const Color _darkPeach = Color(0xFFE65100); // Dark peach for text
  static const Color _lightPeach = Color(0xFFFFF3E0); // Light background
  static const Color _surfacePeach = Color(0xFFFFE0B2); // Card surfaces
  static const Color _mintPeach = Color(0xFFFFCC80); // Subtle accents
  
  static final ThemeData theme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: _lightPeach,
    primaryColor: _primaryPeach,
    
    colorScheme: const ColorScheme.light(
      primary: _primaryPeach,
      secondary: _secondaryPeach,
      tertiary: _mintPeach,
      surface: _surfacePeach,
      background: _lightPeach,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _darkPeach,
      onBackground: _darkPeach,
      outline: Color(0xFFFFAB40),
      outlineVariant: Color(0xFFFFE0B2),
      error: Color(0xFFE57373),
      onError: Colors.white,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryPeach,
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
        backgroundColor: _primaryPeach,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: _primaryPeach.withOpacity(0.3),
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
        foregroundColor: _primaryPeach,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _darkPeach, 
        fontSize: 32, 
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: _darkPeach, 
        fontSize: 28, 
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        color: _darkPeach, 
        fontSize: 24, 
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: _darkPeach, 
        fontSize: 22, 
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: _darkPeach, 
        fontSize: 18, 
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: _darkPeach, 
        fontSize: 16, 
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: _darkPeach, 
        fontSize: 16, 
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: _darkPeach, 
        fontSize: 14, 
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: Color(0xFFFF8F00), 
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
      color: _primaryPeach,
      size: 24,
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryPeach,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    cardTheme: CardThemeData(
      color: _surfacePeach,
      elevation: 2,
      shadowColor: _primaryPeach.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),
    
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _surfacePeach,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _primaryPeach, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFFFE0B2), width: 1),
      ),
      labelStyle: TextStyle(color: _darkPeach),
      hintStyle: TextStyle(color: Color(0xFFFF8F00)),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surfacePeach,
      selectedItemColor: _primaryPeach,
      unselectedItemColor: Color(0xFFFF8F00),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    
    dividerColor: const Color(0xFFFFE0B2),
    shadowColor: _primaryPeach.withOpacity(0.1),
    
    dialogTheme: DialogThemeData(
      backgroundColor: _surfacePeach,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      elevation: 8,
      titleTextStyle: const TextStyle(
        color: _darkPeach,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkPeach,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    
    // Enhanced additional theme properties
    chipTheme: ChipThemeData(
      backgroundColor: _mintPeach,
      selectedColor: _primaryPeach,
      labelStyle: const TextStyle(color: _darkPeach),
      brightness: Brightness.light,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    
    sliderTheme: SliderThemeData(
      activeTrackColor: _primaryPeach,
      inactiveTrackColor: _mintPeach,
      thumbColor: _secondaryPeach,
      overlayColor: _primaryPeach.withOpacity(0.2),
      valueIndicatorColor: _darkPeach,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),
    
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryPeach,
      linearTrackColor: Color(0xFFFFE0B2),
      circularTrackColor: Color(0xFFFFE0B2),
    ),
    
    tabBarTheme: const TabBarThemeData(
      labelColor: _primaryPeach,
      unselectedLabelColor: Color(0xFFFF8F00),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: _primaryPeach, width: 2),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
    ),
    
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryPeach;
        }
        return const Color(0xFF9E9E9E);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryPeach.withOpacity(0.5);
        }
        return const Color(0xFFE0E0E0);
      }),
    ),
    
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryPeach;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: Color(0xFFFFAB40), width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryPeach;
        }
        return const Color(0xFF9E9E9E);
      }),
    ),
    
    listTileTheme: const ListTileThemeData(
      tileColor: _surfacePeach,
      selectedTileColor: Color(0xFFFFCC80),
      iconColor: _primaryPeach,
      textColor: _darkPeach,
      selectedColor: _darkPeach,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: _darkPeach,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      preferBelow: false,
    ),
  );
}
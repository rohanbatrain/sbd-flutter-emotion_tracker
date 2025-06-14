import 'package:flutter/material.dart';

class BlushRoseTheme {
  // Color palette
  static const Color _primaryRose = Color(0xFFF48FB1); // Main rose
  static const Color _secondaryRose = Color(0xFFD81B60); // Accent rose
  static const Color _darkRose = Color(0xFF880E4F); // Dark rose for text
  static const Color _lightRose = Color(0xFFFFEBEE); // Light background
  static const Color _surfaceRose = Color(0xFFFCE4EC); // Card surfaces
  static const Color _mintRose = Color(0xFFF8BBD9); // Subtle accents
  
  static final ThemeData theme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: _lightRose,
    primaryColor: _primaryRose,
    
    colorScheme: const ColorScheme.light(
      primary: _primaryRose,
      secondary: _secondaryRose,
      tertiary: _mintRose,
      surface: _surfaceRose,
      background: _lightRose,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _darkRose,
      onBackground: _darkRose,
      outline: Color(0xFFE1BEE7),
      outlineVariant: Color(0xFFF3E5F5),
      error: Color(0xFFE57373),
      onError: Colors.white,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryRose,
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
        backgroundColor: _primaryRose,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: _primaryRose.withOpacity(0.3),
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
        foregroundColor: _primaryRose,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _darkRose, 
        fontSize: 32, 
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: _darkRose, 
        fontSize: 28, 
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        color: _darkRose, 
        fontSize: 24, 
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: _darkRose, 
        fontSize: 22, 
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: _darkRose, 
        fontSize: 18, 
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: _darkRose, 
        fontSize: 16, 
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: _darkRose, 
        fontSize: 16, 
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: _darkRose, 
        fontSize: 14, 
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: Color(0xFFAD1457), 
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
      color: _primaryRose,
      size: 24,
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryRose,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    cardTheme: CardThemeData(
      color: _surfaceRose,
      elevation: 2,
      shadowColor: _primaryRose.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),
    
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _surfaceRose,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _primaryRose, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFF3E5F5), width: 1),
      ),
      labelStyle: TextStyle(color: _darkRose),
      hintStyle: TextStyle(color: Color(0xFFAD1457)),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surfaceRose,
      selectedItemColor: _primaryRose,
      unselectedItemColor: Color(0xFFAD1457),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    
    dividerColor: const Color(0xFFF3E5F5),
    shadowColor: _primaryRose.withOpacity(0.1),
    
    dialogTheme: const DialogThemeData(
      backgroundColor: _surfaceRose,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      elevation: 8,
      titleTextStyle: TextStyle(
        color: _darkRose,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkRose,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    
    // Enhanced additional theme properties
    chipTheme: ChipThemeData(
      backgroundColor: _mintRose,
      selectedColor: _primaryRose,
      labelStyle: const TextStyle(color: _darkRose),
      brightness: Brightness.light,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    
    sliderTheme: SliderThemeData(
      activeTrackColor: _primaryRose,
      inactiveTrackColor: _mintRose,
      thumbColor: _secondaryRose,
      overlayColor: _primaryRose.withOpacity(0.2),
      valueIndicatorColor: _darkRose,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),
    
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryRose,
      linearTrackColor: Color(0xFFF3E5F5),
      circularTrackColor: Color(0xFFF3E5F5),
    ),
    
    tabBarTheme: const TabBarThemeData(
      labelColor: _primaryRose,
      unselectedLabelColor: Color(0xFFAD1457),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: _primaryRose, width: 2),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
    ),
    
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryRose;
        }
        return const Color(0xFF9E9E9E);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryRose.withOpacity(0.5);
        }
        return const Color(0xFFE0E0E0);
      }),
    ),
    
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryRose;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: Color(0xFFE1BEE7), width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryRose;
        }
        return const Color(0xFF9E9E9E);
      }),
    ),
    
    listTileTheme: const ListTileThemeData(
      tileColor: _surfaceRose,
      selectedTileColor: Color(0xFFF8BBD9),
      iconColor: _primaryRose,
      textColor: _darkRose,
      selectedColor: _darkRose,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: _darkRose,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      preferBelow: false,
    ),
  );
}
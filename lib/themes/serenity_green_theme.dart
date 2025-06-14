import 'package:flutter/material.dart';

class SerenityGreenTheme {
  // Color palette
  static const Color _primaryGreen = Color(0xFF66BB6A); // Main green
  static const Color _secondaryGreen = Color(0xFF4CAF50); // Accent green
  static const Color _darkGreen = Color(0xFF1B5E20); // Dark green for text
  static const Color _lightGreen = Color(0xFFE8F5E8); // Light background
  static const Color _surfaceGreen = Color(0xFFF1F8E9); // Card surfaces
  static const Color _mintGreen = Color(0xFFA5D6A7); // Subtle accents
  
  static final ThemeData theme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: _lightGreen,
    primaryColor: _primaryGreen,
    
    colorScheme: const ColorScheme.light(
      primary: _primaryGreen,
      secondary: _secondaryGreen,
      tertiary: _mintGreen,
      surface: _surfaceGreen,
      background: _lightGreen,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _darkGreen,
      onBackground: _darkGreen,
      outline: Color(0xFF81C784),
      outlineVariant: Color(0xFFCCE5CC),
      error: Color(0xFFE57373),
      onError: Colors.white,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryGreen,
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
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: _primaryGreen.withOpacity(0.3),
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
        foregroundColor: _primaryGreen,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _darkGreen, 
        fontSize: 32, 
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: _darkGreen, 
        fontSize: 28, 
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        color: _darkGreen, 
        fontSize: 24, 
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: _darkGreen, 
        fontSize: 22, 
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: _darkGreen, 
        fontSize: 18, 
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: _darkGreen, 
        fontSize: 16, 
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: _darkGreen, 
        fontSize: 16, 
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: _darkGreen, 
        fontSize: 14, 
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: Color(0xFF4A7C59), 
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
      color: _primaryGreen,
      size: 24,
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryGreen,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    cardTheme: CardThemeData(
      color: _surfaceGreen,
      elevation: 2,
      shadowColor: _primaryGreen.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),
    
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _surfaceGreen,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _primaryGreen, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFCCE5CC), width: 1),
      ),
      labelStyle: TextStyle(color: _darkGreen),
      hintStyle: TextStyle(color: Color(0xFF4A7C59)),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surfaceGreen,
      selectedItemColor: _primaryGreen,
      unselectedItemColor: Color(0xFF4A7C59),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    
    dividerColor: const Color(0xFFCCE5CC),
    shadowColor: _primaryGreen.withOpacity(0.1),
    
    dialogTheme: const DialogThemeData(
      backgroundColor: _surfaceGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      elevation: 8,
      titleTextStyle: TextStyle(
        color: _darkGreen,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkGreen,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    
    // Enhanced additional theme properties
    chipTheme: ChipThemeData(
      backgroundColor: _mintGreen,
      selectedColor: _primaryGreen,
      labelStyle: const TextStyle(color: _darkGreen),
      brightness: Brightness.light,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    
    sliderTheme: SliderThemeData(
      activeTrackColor: _primaryGreen,
      inactiveTrackColor: _mintGreen,
      thumbColor: _secondaryGreen,
      overlayColor: _primaryGreen.withOpacity(0.2),
      valueIndicatorColor: _darkGreen,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),
    
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryGreen,
      linearTrackColor: Color(0xFFCCE5CC),
      circularTrackColor: Color(0xFFCCE5CC),
    ),
    
    tabBarTheme: TabBarThemeData(
      labelColor: _primaryGreen,
      unselectedLabelColor: const Color(0xFF4A7C59),
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: _primaryGreen, width: 2),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
    ),
    
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryGreen;
        }
        return const Color(0xFF9E9E9E);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryGreen.withOpacity(0.5);
        }
        return const Color(0xFFE0E0E0);
      }),
    ),
    
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryGreen;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: Color(0xFF81C784), width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryGreen;
        }
        return const Color(0xFF9E9E9E);
      }),
    ),
    
    listTileTheme: const ListTileThemeData(
      tileColor: _surfaceGreen,
      selectedTileColor: Color(0xFFE0F2E0),
      iconColor: _primaryGreen,
      textColor: _darkGreen,
      selectedColor: _darkGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    bannerTheme: const MaterialBannerThemeData(
      backgroundColor: _surfaceGreen,
      contentTextStyle: TextStyle(color: _darkGreen),
      elevation: 2,
    ),
    
    dividerTheme: const DividerThemeData(
      color: Color(0xFFCCE5CC),
      thickness: 1,
      space: 16,
    ),
    
    expansionTileTheme: const ExpansionTileThemeData(
      backgroundColor: _surfaceGreen,
      collapsedBackgroundColor: _surfaceGreen,
      iconColor: _primaryGreen,
      collapsedIconColor: Color(0xFF4A7C59),
      textColor: _darkGreen,
      collapsedTextColor: _darkGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: _darkGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      preferBelow: false,
    ),
  );
}
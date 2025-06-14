import 'package:flutter/material.dart';

class MidnightLavenderTheme {
  // Color palette
  static const Color _primaryLavender = Color(0xFF9575CD); // Main lavender
  static const Color _secondaryLavender = Color(0xFF7E57C2); // Accent lavender
  static const Color _darkLavender = Color(0xFF4A148C); // Dark lavender for text
  static const Color _darkBackground = Color(0xFF1E1B2E); // Dark background
  static const Color _darkSurface = Color(0xFF2E2B3E); // Card surfaces
  static const Color _lightLavender = Color(0xFFEDE7F6); // Light accents
  
  static final ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: _darkBackground,
    primaryColor: _primaryLavender,
    
    colorScheme: const ColorScheme.dark(
      primary: _primaryLavender,
      secondary: _secondaryLavender,
      tertiary: _lightLavender,
      surface: _darkSurface,
      background: _darkBackground,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _lightLavender,
      onBackground: _lightLavender,
      outline: Color(0xFF6A4C93),
      outlineVariant: Color(0xFF4A148C),
      error: Color(0xFFE57373),
      onError: Colors.white,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryLavender,
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
        backgroundColor: _primaryLavender,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: _primaryLavender.withOpacity(0.3),
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
        foregroundColor: _primaryLavender,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _lightLavender, 
        fontSize: 32, 
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: _lightLavender, 
        fontSize: 28, 
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        color: _lightLavender, 
        fontSize: 24, 
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: _lightLavender, 
        fontSize: 22, 
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: _lightLavender, 
        fontSize: 18, 
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: _lightLavender, 
        fontSize: 16, 
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: _lightLavender, 
        fontSize: 16, 
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: Color(0xFFD1C4E9), 
        fontSize: 14, 
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: Color(0xFFB39DDB), 
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
      color: _primaryLavender,
      size: 24,
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryLavender,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    cardTheme: CardThemeData(
      color: _darkSurface,
      elevation: 2,
      shadowColor: _primaryLavender.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),
    
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _primaryLavender, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF6A4C93), width: 1),
      ),
      labelStyle: TextStyle(color: _lightLavender),
      hintStyle: TextStyle(color: Color(0xFFB39DDB)),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _darkSurface,
      selectedItemColor: _primaryLavender,
      unselectedItemColor: Color(0xFFB39DDB),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    
    dividerColor: const Color(0xFF6A4C93),
    shadowColor: _primaryLavender.withOpacity(0.1),
    
    dialogTheme: const DialogThemeData(
      backgroundColor: _darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      elevation: 8,
      titleTextStyle: TextStyle(
        color: _lightLavender,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkLavender,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    
    // Enhanced additional theme properties
    chipTheme: ChipThemeData(
      backgroundColor: _darkSurface,
      selectedColor: _primaryLavender,
      labelStyle: const TextStyle(color: _lightLavender),
      brightness: Brightness.dark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    
    sliderTheme: SliderThemeData(
      activeTrackColor: _primaryLavender,
      inactiveTrackColor: Color(0xFF6A4C93),
      thumbColor: _secondaryLavender,
      overlayColor: _primaryLavender.withOpacity(0.2),
      valueIndicatorColor: _darkLavender,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),
    
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryLavender,
      linearTrackColor: Color(0xFF6A4C93),
      circularTrackColor: Color(0xFF6A4C93),
    ),
    
    tabBarTheme: const TabBarThemeData(
      labelColor: _primaryLavender,
      unselectedLabelColor: Color(0xFFB39DDB),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: _primaryLavender, width: 2),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
    ),
    
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryLavender;
        }
        return const Color(0xFF9E9E9E);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryLavender.withOpacity(0.5);
        }
        return const Color(0xFF424242);
      }),
    ),
    
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryLavender;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: Color(0xFF6A4C93), width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryLavender;
        }
        return const Color(0xFF9E9E9E);
      }),
    ),
    
    listTileTheme: const ListTileThemeData(
      tileColor: _darkSurface,
      selectedTileColor: Color(0xFF4A3E5E),
      iconColor: _primaryLavender,
      textColor: _lightLavender,
      selectedColor: _lightLavender,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: _darkLavender,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      preferBelow: false,
    ),
  );
}
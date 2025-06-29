import 'package:flutter/material.dart';

class DeepPurpleDarkTheme {
  // Color palette
  static const Color _primaryPurple   = Color(0xFF7E57C2); // Main deep purple
  static const Color _secondaryPurple = Color(0xFF673AB7); // Accent purple
  static const Color _lightTextPurple = Color(0xFFEDE7F6); // Light text on dark
  static const Color _darkBasePurple  = Color(0xFF121212); // Dark background
  static const Color _surfacePurple   = Color(0xFF1F1A2B); // Card surfaces
  static const Color _mintPurple      = Color(0xFF9C64A6); // Subtle accents
  
  static final ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: _darkBasePurple,
    primaryColor: _primaryPurple,
    
    colorScheme: const ColorScheme.dark(
      primary: _primaryPurple,
      secondary: _secondaryPurple,
      tertiary: _mintPurple,
      surface: _surfacePurple,
      background: _darkBasePurple,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _lightTextPurple,
      onBackground: _lightTextPurple,
      outline: Color(0xFF7E57C2),
      outlineVariant: Color(0xFF4527A0),
      error: Color(0xFFEF9A9A),
      onError: Colors.black,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryPurple,
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
        backgroundColor: _primaryPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: _primaryPurple.withOpacity(0.4),
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
        foregroundColor: _primaryPurple,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _lightTextPurple, 
        fontSize: 32, 
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: _lightTextPurple, 
        fontSize: 28, 
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        color: _lightTextPurple, 
        fontSize: 24, 
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: _lightTextPurple, 
        fontSize: 22, 
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: _lightTextPurple, 
        fontSize: 18, 
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: _lightTextPurple, 
        fontSize: 16, 
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: _lightTextPurple, 
        fontSize: 16, 
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: _lightTextPurple, 
        fontSize: 14, 
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: _secondaryPurple, 
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
      color: _primaryPurple,
      size: 24,
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryPurple,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    cardTheme: CardThemeData(
      color: _surfacePurple,
      elevation: 2,
      shadowColor: _primaryPurple.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),
    
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _surfacePurple,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _primaryPurple, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF4527A0), width: 1),
      ),
      labelStyle: TextStyle(color: _lightTextPurple),
      hintStyle: TextStyle(color: Color(0xFFB39DDB)),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surfacePurple,
      selectedItemColor: _primaryPurple,
      unselectedItemColor: Color(0xFFB39DDB),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    
    dividerColor: const Color(0xFF4527A0),
    shadowColor: _primaryPurple.withOpacity(0.2),
    
    dialogTheme: const DialogThemeData(
      backgroundColor: _surfacePurple,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      elevation: 8,
      titleTextStyle: TextStyle(
        color: _lightTextPurple,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _secondaryPurple,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: _mintPurple,
      selectedColor: _primaryPurple,
      labelStyle: const TextStyle(color: Colors.white),
      brightness: Brightness.dark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    
    sliderTheme: SliderThemeData(
      activeTrackColor: _primaryPurple,
      inactiveTrackColor: _mintPurple,
      thumbColor: _secondaryPurple,
      overlayColor: _primaryPurple.withOpacity(0.2),
      valueIndicatorColor: _lightTextPurple,
      valueIndicatorTextStyle: const TextStyle(color: Colors.black),
    ),
    
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryPurple,
      linearTrackColor: Color(0xFF4527A0),
      circularTrackColor: Color(0xFF4527A0),
    ),
    
    tabBarTheme: const TabBarThemeData(
      labelColor: _primaryPurple,
      unselectedLabelColor: Color(0xFFB39DDB),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: _primaryPurple, width: 2),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
    ),
    
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryPurple;
        }
        return const Color(0xFF757575);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryPurple.withOpacity(0.5);
        }
        return const Color(0xFF424242);
      }),
    ),
    
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryPurple;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: Color(0xFF7E57C2), width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryPurple;
        }
        return const Color(0xFF757575);
      }),
    ),
    
    listTileTheme: const ListTileThemeData(
      tileColor: _surfacePurple,
      selectedTileColor: Color(0xFF6A1B9A),
      iconColor: _primaryPurple,
      textColor: _lightTextPurple,
      selectedColor: _lightTextPurple,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: _secondaryPurple,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      preferBelow: false,
    ),
  );
}

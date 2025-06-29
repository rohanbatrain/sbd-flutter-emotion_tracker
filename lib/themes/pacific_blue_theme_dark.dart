import 'package:flutter/material.dart';

class PacificBlueDarkTheme {
  // Color palette
  static const Color _primaryBlue   = Color(0xFF4DD0E1); // Main pacific blue
  static const Color _secondaryBlue = Color(0xFF00BCD4); // Accent blue
  static const Color _lightTextBlue = Color(0xFFE0F7FA); // Light text on dark
  static const Color _darkBaseBlue  = Color(0xFF121212); // Dark background
  static const Color _surfaceBlue   = Color(0xFF102A2B); // Card surfaces
  static const Color _mintBlue      = Color(0xFF80DEEA); // Subtle accents
  
  static final ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: _darkBaseBlue,
    primaryColor: _primaryBlue,
    
    colorScheme: const ColorScheme.dark(
      primary: _primaryBlue,
      secondary: _secondaryBlue,
      tertiary: _mintBlue,
      surface: _surfaceBlue,
      background: _darkBaseBlue,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: _lightTextBlue,
      onBackground: _lightTextBlue,
      outline: Color(0xFF4DD0E1),
      outlineVariant: Color(0xFF006064),
      error: Color(0xFFEF9A9A),
      onError: Colors.black,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryBlue,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black, 
        fontSize: 20, 
        fontWeight: FontWeight.w600
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.black,
        elevation: 2,
        shadowColor: _primaryBlue.withOpacity(0.4),
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
        foregroundColor: _primaryBlue,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _lightTextBlue, 
        fontSize: 32, 
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: _lightTextBlue, 
        fontSize: 28, 
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        color: _lightTextBlue, 
        fontSize: 24, 
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: _lightTextBlue, 
        fontSize: 22, 
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: _lightTextBlue, 
        fontSize: 18, 
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: _lightTextBlue, 
        fontSize: 16, 
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: _lightTextBlue, 
        fontSize: 16, 
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: _lightTextBlue, 
        fontSize: 14, 
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: Color(0xFF4DD0E1), 
        fontSize: 12, 
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: Colors.black, 
        fontSize: 14, 
        fontWeight: FontWeight.w600,
      ),
    ),
    
    iconTheme: const IconThemeData(
      color: _primaryBlue,
      size: 24,
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryBlue,
      foregroundColor: Colors.black,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    cardTheme: CardThemeData(
      color: _surfaceBlue,
      elevation: 2,
      shadowColor: _primaryBlue.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),
    
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _surfaceBlue,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _primaryBlue, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF006064), width: 1),
      ),
      labelStyle: TextStyle(color: _lightTextBlue),
      hintStyle: TextStyle(color: Color(0xFF80DEEA)),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surfaceBlue,
      selectedItemColor: _primaryBlue,
      unselectedItemColor: Color(0xFF80DEEA),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    
    dividerColor: const Color(0xFF006064),
    shadowColor: _primaryBlue.withOpacity(0.2),
    
    dialogTheme: const DialogThemeData(
      backgroundColor: _surfaceBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      elevation: 8,
      titleTextStyle: TextStyle(
        color: _lightTextBlue,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _secondaryBlue,
      contentTextStyle: const TextStyle(color: Colors.black),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: _mintBlue,
      selectedColor: _primaryBlue,
      labelStyle: const TextStyle(color: Colors.black),
      brightness: Brightness.dark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    
    sliderTheme: SliderThemeData(
      activeTrackColor: _primaryBlue,
      inactiveTrackColor: _mintBlue,
      thumbColor: _secondaryBlue,
      overlayColor: _primaryBlue.withOpacity(0.2),
      valueIndicatorColor: _lightTextBlue,
      valueIndicatorTextStyle: const TextStyle(color: Colors.black),
    ),
    
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryBlue,
      linearTrackColor: Color(0xFF006064),
      circularTrackColor: Color(0xFF006064),
    ),
    
    tabBarTheme: const TabBarThemeData(
      labelColor: _primaryBlue,
      unselectedLabelColor: Color(0xFF80DEEA),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: _primaryBlue, width: 2),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
    ),
    
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryBlue;
        }
        return const Color(0xFF757575);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryBlue.withOpacity(0.5);
        }
        return const Color(0xFF424242);
      }),
    ),
    
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryBlue;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.black),
      side: const BorderSide(color: Color(0xFF4DD0E1), width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryBlue;
        }
        return const Color(0xFF757575);
      }),
    ),
    
    listTileTheme: const ListTileThemeData(
      tileColor: _surfaceBlue,
      selectedTileColor: Color(0xFF004D51),
      iconColor: _primaryBlue,
      textColor: _lightTextBlue,
      selectedColor: _lightTextBlue,
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
      textStyle: const TextStyle(color: Colors.black, fontSize: 12),
      preferBelow: false,
    ),
  );
}

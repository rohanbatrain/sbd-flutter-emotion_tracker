import 'package:flutter/material.dart';

class RoyalOrangeDarkTheme {
  // Color palette
  static const Color _primaryOrange   = Color(0xFFFF9800); // Main royal orange
  static const Color _secondaryBlue   = Color(0xFF1976D2); // Accent blue (triadic)
  static const Color _accentGreen     = Color(0xFF43A047); // Accent green (triadic)
  static const Color _lightTextOrange = Color(0xFFFFF3E0); // Light text on dark
  static const Color _darkBaseOrange  = Color(0xFF121212); // Dark background
  static const Color _surfaceOrange   = Color(0xFF2E1A00); // Card surfaces
  static const Color _mintOrange      = Color(0xFFFFCC80); // Subtle accents

  static final ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: _darkBaseOrange,
    primaryColor: _primaryOrange,
    
    colorScheme: const ColorScheme.dark(
      primary: _primaryOrange,
      secondary: _secondaryBlue,
      tertiary: _accentGreen,
      surface: _surfaceOrange,
      background: _darkBaseOrange,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: _lightTextOrange,
      onBackground: _lightTextOrange,
      outline: Color(0xFFFF9800),
      outlineVariant: Color(0xFF2E1A00),
      error: Color(0xFFD32F2F),
      onError: Colors.black,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryOrange,
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
        backgroundColor: _primaryOrange,
        foregroundColor: Colors.black,
        elevation: 2,
        shadowColor: _primaryOrange.withOpacity(0.4),
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
        color: _lightTextOrange, 
        fontSize: 32, 
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: _lightTextOrange, 
        fontSize: 28, 
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        color: _lightTextOrange, 
        fontSize: 24, 
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: _lightTextOrange, 
        fontSize: 22, 
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: _lightTextOrange, 
        fontSize: 18, 
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: _lightTextOrange, 
        fontSize: 16, 
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: _lightTextOrange, 
        fontSize: 16, 
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: _lightTextOrange, 
        fontSize: 14, 
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: Color(0xFFFF9800), 
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
      color: _primaryOrange,
      size: 24,
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryOrange,
      foregroundColor: Colors.black,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    cardTheme: CardThemeData(
      color: _surfaceOrange,
      elevation: 2,
      shadowColor: _primaryOrange.withOpacity(0.2),
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
        borderSide: BorderSide(color: Color(0xFFFF9800), width: 1),
      ),
      labelStyle: TextStyle(color: _lightTextOrange),
      hintStyle: TextStyle(color: Color(0xFFFFCC80)),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surfaceOrange,
      selectedItemColor: _primaryOrange,
      unselectedItemColor: Color(0xFFFFCC80),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    
    dividerColor: const Color(0xFF2E1A00),
    shadowColor: _primaryOrange.withOpacity(0.2),
    
    dialogTheme: const DialogThemeData(
      backgroundColor: _surfaceOrange,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      elevation: 8,
      titleTextStyle: TextStyle(
        color: _lightTextOrange,
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
      backgroundColor: _mintOrange,
      selectedColor: _primaryOrange,
      labelStyle: const TextStyle(color: _lightTextOrange),
      brightness: Brightness.dark,
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
      valueIndicatorColor: _lightTextOrange,
      valueIndicatorTextStyle: const TextStyle(color: Colors.black),
    ),
    
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryOrange,
      linearTrackColor: Color(0xFF2E1A00),
      circularTrackColor: Color(0xFF2E1A00),
    ),
    
    tabBarTheme: const TabBarThemeData(
      labelColor: _primaryOrange,
      unselectedLabelColor: Color(0xFFFFCC80),
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
        return const Color(0xFF757575);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryOrange.withOpacity(0.5);
        }
        return const Color(0xFF424242);
      }),
    ),
    
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryOrange;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.black),
      side: const BorderSide(color: Color(0xFFFF9800), width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryOrange;
        }
        return const Color(0xFF757575);
      }),
    ),
    
    listTileTheme: const ListTileThemeData(
      tileColor: _surfaceOrange,
      selectedTileColor: Color(0xFFFFCC80),
      iconColor: _primaryOrange,
      textColor: _lightTextOrange,
      selectedColor: _lightTextOrange,
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

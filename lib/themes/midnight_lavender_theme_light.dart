import 'package:flutter/material.dart';

class MidnightLavenderLightTheme {
  // Color palette
  static const Color _primaryLavender   = Color(0xFF9575CD); // Main lavender
  static const Color _secondaryLavender = Color(0xFF7E57C2); // Accent lavender
  static const Color _darkLavender      = Color(0xFF4A148C); // Headings/text
  static const Color _lightLavender     = Color(0xFFEDE7F6); // Scaffold background
  static const Color _surfaceLavender   = Color(0xFFD1C4E9); // Cards/surfaces
  static const Color _mintLavender      = Color(0xFFB39DDB); // Subtle accents
  
  static final ThemeData theme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: _lightLavender,
    primaryColor: _primaryLavender,
    
    colorScheme: const ColorScheme.light(
      primary: _primaryLavender,
      secondary: _secondaryLavender,
      tertiary: _mintLavender,
      surface: _surfaceLavender,
      background: _lightLavender,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _darkLavender,
      onBackground: _darkLavender,
      outline: Color(0xFF6A4C93),
      outlineVariant: Color(0xFFD1C4E9),
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
        fontWeight: FontWeight.w600,
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryLavender,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: _primaryLavender.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryLavender,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),
    
    textTheme: const TextTheme(
      headlineLarge:  TextStyle(color: _darkLavender, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
      headlineMedium: TextStyle(color: _darkLavender, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
      headlineSmall: TextStyle(color: _darkLavender, fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge:    TextStyle(color: _darkLavender, fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium:   TextStyle(color: _darkLavender, fontSize: 18, fontWeight: FontWeight.w600),
      titleSmall:    TextStyle(color: _darkLavender, fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge:     TextStyle(color: _darkLavender, fontSize: 16),
      bodyMedium:    TextStyle(color: _darkLavender, fontSize: 14),
      bodySmall:     TextStyle(color: _mintLavender, fontSize: 12),
      labelLarge:    TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
    ),
    
    iconTheme: const IconThemeData(color: _primaryLavender, size: 24),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryLavender,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    
    cardTheme: CardThemeData(
      color: _surfaceLavender,
      elevation: 2,
      shadowColor: _primaryLavender.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
    ),
    
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _surfaceLavender,
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
      labelStyle: TextStyle(color: _darkLavender),
      hintStyle: TextStyle(color: _mintLavender),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surfaceLavender,
      selectedItemColor: _primaryLavender,
      unselectedItemColor: _mintLavender,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    
    dividerColor: const Color(0xFF6A4C93),
    shadowColor: _primaryLavender.withOpacity(0.1),
    
    dialogTheme: const DialogThemeData(
      backgroundColor: _surfaceLavender,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      elevation: 8,
      titleTextStyle: TextStyle(color: _darkLavender, fontSize: 20, fontWeight: FontWeight.w600),
    ),
    
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _secondaryLavender,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: _mintLavender,
      selectedColor: _primaryLavender,
      labelStyle: const TextStyle(color: _darkLavender),
      brightness: Brightness.light,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    
    sliderTheme: SliderThemeData(
      activeTrackColor: _primaryLavender,
      inactiveTrackColor: _mintLavender,
      thumbColor: _secondaryLavender,
      overlayColor: _primaryLavender.withOpacity(0.2),
      valueIndicatorColor: _darkLavender,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),
    
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryLavender,
      linearTrackColor: Color(0xFFD1C4E9),
      circularTrackColor: Color(0xFFD1C4E9),
    ),
    
    tabBarTheme: const TabBarThemeData(
      labelColor: _primaryLavender,
      unselectedLabelColor: _mintLavender,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: _primaryLavender, width: 2),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
    ),
    
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? _primaryLavender : const Color(0xFF9E9E9E)),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? _primaryLavender.withOpacity(0.5) : const Color(0xFFE0E0E0)),
    ),
    
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? _primaryLavender : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: Color(0xFF6A4C93), width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? _primaryLavender : const Color(0xFF9E9E9E)),
    ),
    
    listTileTheme: const ListTileThemeData(
      tileColor: _surfaceLavender,
      selectedTileColor: Color(0xFFCEC0E2),
      iconColor: _primaryLavender,
      textColor: _darkLavender,
      selectedColor: _darkLavender,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: _secondaryLavender,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      preferBelow: false,
    ),
  );
}

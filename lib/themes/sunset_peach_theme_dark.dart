import 'package:flutter/material.dart';

class SunsetPeachDarkTheme {
  // Dark color palette
  static const Color _primaryPeach = Color(0xFFFFB74D);
  static const Color _secondaryPeach = Color(0xFFFB8C00);
  static const Color _darkBase = Color(0xFF121212); // Scaffold background
  static const Color _surfacePeach = Color(0xFF2E1A00); // Cards
  static const Color _mintPeach = Color(0xFFFFCC80);
  static const Color _lightTextPeach = Color(0xFFFFE0B2); // For text

  static final ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: _darkBase,
    primaryColor: _primaryPeach,

    colorScheme: const ColorScheme.dark(
      primary: _primaryPeach,
      secondary: _secondaryPeach,
      tertiary: _mintPeach,
      surface: _surfacePeach,
      background: _darkBase,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: _lightTextPeach,
      onBackground: _lightTextPeach,
      outline: Color(0xFFFFAB40),
      outlineVariant: Color(0xFF4A2C00),
      error: Color(0xFFEF9A9A),
      onError: Colors.black,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryPeach,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryPeach,
        foregroundColor: Colors.black,
        elevation: 2,
        shadowColor: _primaryPeach.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryPeach,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: _lightTextPeach, fontSize: 32, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: _lightTextPeach, fontSize: 28, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: _lightTextPeach, fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: _lightTextPeach, fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: _lightTextPeach, fontSize: 18, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: _lightTextPeach, fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: _lightTextPeach, fontSize: 16),
      bodyMedium: TextStyle(color: _lightTextPeach, fontSize: 14),
      bodySmall: TextStyle(color: _mintPeach, fontSize: 12),
      labelLarge: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
    ),

    iconTheme: const IconThemeData(color: _primaryPeach, size: 24),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryPeach,
      foregroundColor: Colors.black,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),

    cardTheme: CardThemeData(
      color: _surfacePeach,
      elevation: 2,
      shadowColor: _primaryPeach.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        borderSide: BorderSide(color: Color(0xFFFFAB40), width: 1),
      ),
      labelStyle: TextStyle(color: _lightTextPeach),
      hintStyle: TextStyle(color: _mintPeach),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surfacePeach,
      selectedItemColor: _primaryPeach,
      unselectedItemColor: _mintPeach,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),

    dividerColor: const Color(0xFFFFAB40),
    shadowColor: _primaryPeach.withOpacity(0.1),

    dialogTheme: const DialogThemeData(
      backgroundColor: _surfacePeach,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      elevation: 8,
      titleTextStyle: TextStyle(color: _lightTextPeach, fontSize: 20, fontWeight: FontWeight.w600),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: _secondaryPeach,
      contentTextStyle: const TextStyle(color: Colors.black),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: _mintPeach,
      selectedColor: _primaryPeach,
      labelStyle: const TextStyle(color: Colors.black),
      brightness: Brightness.dark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: _primaryPeach,
      inactiveTrackColor: _mintPeach,
      thumbColor: _secondaryPeach,
      overlayColor: _primaryPeach.withOpacity(0.2),
      valueIndicatorColor: _lightTextPeach,
      valueIndicatorTextStyle: const TextStyle(color: Colors.black),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryPeach,
      linearTrackColor: Color(0xFF4A2C00),
      circularTrackColor: Color(0xFF4A2C00),
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor: _primaryPeach,
      unselectedLabelColor: _mintPeach,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: _primaryPeach, width: 2),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? _primaryPeach : const Color(0xFF757575)),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? _primaryPeach.withOpacity(0.5) : const Color(0xFF424242)),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? _primaryPeach : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.black),
      side: const BorderSide(color: Color(0xFFFFAB40), width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? _primaryPeach : const Color(0xFF757575)),
    ),

    listTileTheme: const ListTileThemeData(
      tileColor: _surfacePeach,
      selectedTileColor: Color(0xFF5E3B0A),
      iconColor: _primaryPeach,
      textColor: _lightTextPeach,
      selectedColor: _lightTextPeach,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: _secondaryPeach,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.black, fontSize: 12),
      preferBelow: false,
    ),
  );
}

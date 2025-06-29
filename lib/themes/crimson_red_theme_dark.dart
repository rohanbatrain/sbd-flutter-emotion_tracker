import 'package:flutter/material.dart';

class CrimsonRedDarkTheme {
  static const Color _primaryRed = Color(0xFFE57373); // Main crimson red
  static const Color _secondaryRed = Color(0xFFD32F2F); // Accent red
  static const Color _darkRed = Color(0xFFFFEBEE); // Light text on dark red
  static const Color _darkBase = Color(0xFF1A1A1A); // Dark background
  static const Color _surfaceRed = Color(0xFF2C1B1B); // Card surfaces
  static const Color _mintRed = Color(0xFFB71C1C); // Subtle red accent

  static final ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: _darkBase,
    primaryColor: _primaryRed,

    colorScheme: const ColorScheme.dark(
      primary: _primaryRed,
      secondary: _secondaryRed,
      tertiary: _mintRed,
      surface: _surfaceRed,
      background: _darkBase,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _darkRed,
      onBackground: _darkRed,
      outline: Color(0xFFEF9A9A),
      outlineVariant: Color(0xFF5D1A1A),
      error: Color(0xFFE57373),
      onError: Colors.black,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryRed,
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
        backgroundColor: _primaryRed,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: _primaryRed.withOpacity(0.3),
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
        foregroundColor: _primaryRed,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _darkRed,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: _darkRed,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        color: _darkRed,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: _darkRed,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: _darkRed,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: _darkRed,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: _darkRed,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: _darkRed,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: _secondaryRed,
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
      color: _primaryRed,
      size: 24,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryRed,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    cardTheme: CardThemeData(
      color: _surfaceRed,
      elevation: 2,
      shadowColor: _primaryRed.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),

    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _surfaceRed,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _primaryRed, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF5D1A1A), width: 1),
      ),
      labelStyle: TextStyle(color: _darkRed),
      hintStyle: TextStyle(color: Color(0xFFEF9A9A)),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surfaceRed,
      selectedItemColor: _primaryRed,
      unselectedItemColor: _mintRed,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),

    dividerColor: const Color(0xFF5D1A1A),
    shadowColor: _primaryRed.withOpacity(0.1),

    dialogTheme: const DialogThemeData(
      backgroundColor: _surfaceRed,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      elevation: 8,
      titleTextStyle: TextStyle(
        color: _darkRed,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: _secondaryRed,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: _mintRed,
      selectedColor: _primaryRed,
      labelStyle: const TextStyle(color: Colors.white),
      brightness: Brightness.dark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: _primaryRed,
      inactiveTrackColor: _mintRed,
      thumbColor: _secondaryRed,
      overlayColor: _primaryRed.withOpacity(0.2),
      valueIndicatorColor: _darkRed,
      valueIndicatorTextStyle: const TextStyle(color: Colors.black),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryRed,
      linearTrackColor: Color(0xFF5D1A1A),
      circularTrackColor: Color(0xFF5D1A1A),
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor: _primaryRed,
      unselectedLabelColor: _mintRed,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: _primaryRed, width: 2),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryRed;
        }
        return const Color(0xFF757575);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryRed.withOpacity(0.5);
        }
        return const Color(0xFF424242);
      }),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryRed;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: Color(0xFFEF9A9A), width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryRed;
        }
        return const Color(0xFF757575);
      }),
    ),

    listTileTheme: const ListTileThemeData(
      tileColor: _surfaceRed,
      selectedTileColor: Color(0xFF7F1D1D),
      iconColor: _primaryRed,
      textColor: _darkRed,
      selectedColor: _darkRed,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: _secondaryRed,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      preferBelow: false,
    ),
  );
}

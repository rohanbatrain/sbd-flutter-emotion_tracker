import 'package:flutter/material.dart';

class GoldenYellowDarkTheme {
  // Color palette
  static const Color _primaryYellow = Color(0xFFFFD54F); // Main golden yellow
  static const Color _secondaryYellow = Color(0xFFFFC107); // Accent yellow
  static const Color _darkYellow = Color(0xFFFF8F00); // Used for highlights
  static const Color _darkBase = Color(0xFF121212); // Background
  static const Color _surfaceYellow = Color(0xFF1F1F1F); // Cards
  static const Color _mintYellow = Color(0xFFFFE082); // Subtle highlights

  static final ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: _darkBase,
    primaryColor: _primaryYellow,

    colorScheme: const ColorScheme.dark(
      primary: _primaryYellow,
      secondary: _secondaryYellow,
      tertiary: _mintYellow,
      surface: _surfaceYellow,
      background: _darkBase,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
      outline: Color(0xFFFFC107),
      outlineVariant: Color(0xFF333333),
      error: Color(0xFFEF9A9A),
      onError: Colors.black,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryYellow,
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
        backgroundColor: _primaryYellow,
        foregroundColor: Colors.black,
        elevation: 2,
        shadowColor: _primaryYellow.withOpacity(0.3),
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
        foregroundColor: _mintYellow,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _primaryYellow,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: _primaryYellow,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        color: _mintYellow,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: _mintYellow,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: _mintYellow,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: _mintYellow,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: _primaryYellow,
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
      color: _primaryYellow,
      size: 24,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryYellow,
      foregroundColor: Colors.black,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    cardTheme: CardThemeData(
      color: _surfaceYellow,
      elevation: 2,
      shadowColor: _primaryYellow.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),

    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _surfaceYellow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _primaryYellow, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFFFC107), width: 1),
      ),
      labelStyle: TextStyle(color: _mintYellow),
      hintStyle: TextStyle(color: _secondaryYellow),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surfaceYellow,
      selectedItemColor: _primaryYellow,
      unselectedItemColor: _mintYellow,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),

    dividerColor: const Color(0xFFFFC107),
    shadowColor: _primaryYellow.withOpacity(0.1),

    dialogTheme: const DialogThemeData(
      backgroundColor: _surfaceYellow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      elevation: 8,
      titleTextStyle: TextStyle(
        color: _mintYellow,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: _secondaryYellow,
      contentTextStyle: const TextStyle(color: Colors.black),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: _mintYellow,
      selectedColor: _primaryYellow,
      labelStyle: const TextStyle(color: Colors.black),
      brightness: Brightness.dark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: _primaryYellow,
      inactiveTrackColor: _mintYellow,
      thumbColor: _secondaryYellow,
      overlayColor: _primaryYellow.withOpacity(0.2),
      valueIndicatorColor: _primaryYellow,
      valueIndicatorTextStyle: const TextStyle(color: Colors.black),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryYellow,
      linearTrackColor: Color(0xFF333333),
      circularTrackColor: Color(0xFF333333),
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor: _primaryYellow,
      unselectedLabelColor: Color(0xFFFFE082),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: _primaryYellow, width: 2),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryYellow;
        }
        return const Color(0xFF757575);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryYellow.withOpacity(0.5);
        }
        return const Color(0xFF424242);
      }),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryYellow;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.black),
      side: const BorderSide(color: Color(0xFFFFC107), width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryYellow;
        }
        return const Color(0xFF757575);
      }),
    ),

    listTileTheme: const ListTileThemeData(
      tileColor: _surfaceYellow,
      selectedTileColor: Color(0xFFFFE082),
      iconColor: _mintYellow,
      textColor: Colors.white,
      selectedColor: _primaryYellow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: _primaryYellow,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.black, fontSize: 12),
      preferBelow: false,
    ),
  );
}

import 'package:flutter/material.dart';

class BlushRoseDarkTheme {
  static const Color _primaryRose = Color(0xFFE91E63); // Darker main rose
  static const Color _secondaryRose = Color(0xFFC2185B); // Slightly deeper accent
  static const Color _darkRose = Color(0xFFFFC1E3); // For light text on dark bg
  static const Color _darkBaseRose = Color(0xFF121212); // Very dark background
  static const Color _deepSurfaceRose = Color(0xFF1E1B1D); // For cards/surfaces
  static const Color _mintRose = Color(0xFFBA6B8D); // Muted mint-like blush

  static final ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: _darkBaseRose,
    primaryColor: _primaryRose,

    colorScheme: const ColorScheme.dark(
      primary: _primaryRose,
      secondary: _secondaryRose,
      tertiary: _mintRose,
      surface: _deepSurfaceRose,
      background: _darkBaseRose,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _darkRose,
      onBackground: _darkRose,
      outline: Color(0xFF6A1B9A),
      outlineVariant: Color(0xFF4A148C),
      error: Color(0xFFEF9A9A),
      onError: Colors.black,
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
        fontWeight: FontWeight.w600,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryRose,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: _primaryRose.withOpacity(0.4),
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
        color: Color(0xFFFFC1E3),
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
      color: _deepSurfaceRose,
      elevation: 2,
      shadowColor: _primaryRose.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),

    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _deepSurfaceRose,
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
        borderSide: BorderSide(color: Color(0xFF6A1B9A), width: 1),
      ),
      labelStyle: TextStyle(color: _darkRose),
      hintStyle: TextStyle(color: Color(0xFFFFC1E3)),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _deepSurfaceRose,
      selectedItemColor: _primaryRose,
      unselectedItemColor: Color(0xFFFFC1E3),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),

    dividerColor: const Color(0xFF6A1B9A),
    shadowColor: _primaryRose.withOpacity(0.2),

    dialogTheme: const DialogThemeData(
      backgroundColor: _deepSurfaceRose,
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
      backgroundColor: _secondaryRose,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: _mintRose,
      selectedColor: _primaryRose,
      labelStyle: const TextStyle(color: Colors.white),
      brightness: Brightness.dark,
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
      valueIndicatorTextStyle: const TextStyle(color: Colors.black),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryRose,
      linearTrackColor: Color(0xFF6A1B9A),
      circularTrackColor: Color(0xFF6A1B9A),
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor: _primaryRose,
      unselectedLabelColor: Color(0xFFFFC1E3),
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
        return const Color(0xFF757575);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryRose.withOpacity(0.5);
        }
        return const Color(0xFF424242);
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
      side: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryRose;
        }
        return const Color(0xFF757575);
      }),
    ),

    listTileTheme: const ListTileThemeData(
      tileColor: _deepSurfaceRose,
      selectedTileColor: Color(0xFF4A154B),
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
        color: _secondaryRose,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      preferBelow: false,
    ),
  );
}
import 'package:flutter/material.dart';

class CloudGrayDarkTheme {
  static const Color _primaryGray = Color(0xFF90A4AE); // Darker main gray
  static const Color _secondaryGray = Color(0xFF455A64); // Deep accent gray
  static const Color _darkGray = Color(0xFFECEFF1); // For light text on dark bg
  static const Color _darkBaseGray = Color(0xFF121212); // Dark base background
  static const Color _deepSurfaceGray = Color(0xFF1C1F22); // Surface/card
  static const Color _mintGray = Color(0xFF78909C); // Subtle dark accent

  static final ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: _darkBaseGray,
    primaryColor: _primaryGray,

    colorScheme: const ColorScheme.dark(
      primary: _primaryGray,
      secondary: _secondaryGray,
      tertiary: _mintGray,
      surface: _deepSurfaceGray,
      background: _darkBaseGray,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _darkGray,
      onBackground: _darkGray,
      outline: Color(0xFF546E7A),
      outlineVariant: Color(0xFF263238),
      error: Color(0xFFEF9A9A),
      onError: Colors.black,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryGray,
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
        backgroundColor: _primaryGray,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: _primaryGray.withOpacity(0.4),
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
        foregroundColor: _primaryGray,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _darkGray,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: _darkGray,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        color: _darkGray,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: _darkGray,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: _darkGray,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: _darkGray,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: _darkGray,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: _darkGray,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: Color(0xFFB0BEC5),
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
      color: _primaryGray,
      size: 24,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryGray,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    cardTheme: CardThemeData(
      color: _deepSurfaceGray,
      elevation: 2,
      shadowColor: _primaryGray.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),

    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _deepSurfaceGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _primaryGray, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF263238), width: 1),
      ),
      labelStyle: TextStyle(color: _darkGray),
      hintStyle: TextStyle(color: Color(0xFFB0BEC5)),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _deepSurfaceGray,
      selectedItemColor: _primaryGray,
      unselectedItemColor: Color(0xFFB0BEC5),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),

    dividerColor: const Color(0xFF37474F),
    shadowColor: _primaryGray.withOpacity(0.2),

    dialogTheme: const DialogThemeData(
      backgroundColor: _deepSurfaceGray,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      elevation: 8,
      titleTextStyle: TextStyle(
        color: _darkGray,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: _secondaryGray,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: _mintGray,
      selectedColor: _primaryGray,
      labelStyle: const TextStyle(color: Colors.white),
      brightness: Brightness.dark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: _primaryGray,
      inactiveTrackColor: _mintGray,
      thumbColor: _secondaryGray,
      overlayColor: _primaryGray.withOpacity(0.2),
      valueIndicatorColor: _darkGray,
      valueIndicatorTextStyle: const TextStyle(color: Colors.black),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryGray,
      linearTrackColor: Color(0xFF263238),
      circularTrackColor: Color(0xFF263238),
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor: _primaryGray,
      unselectedLabelColor: Color(0xFFB0BEC5),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: _primaryGray, width: 2),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryGray;
        }
        return const Color(0xFF757575);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryGray.withOpacity(0.5);
        }
        return const Color(0xFF424242);
      }),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryGray;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: Color(0xFF546E7A), width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryGray;
        }
        return const Color(0xFF757575);
      }),
    ),

    listTileTheme: const ListTileThemeData(
      tileColor: _deepSurfaceGray,
      selectedTileColor: Color(0xFF37474F),
      iconColor: _primaryGray,
      textColor: _darkGray,
      selectedColor: _darkGray,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: _secondaryGray,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      preferBelow: false,
    ),
  );
}

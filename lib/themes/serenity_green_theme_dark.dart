import 'package:flutter/material.dart';

class SerenityGreenDarkTheme {
  // Dark color palette
  static const Color _primaryGreen = Color(0xFF66BB6A); // Main green
  static const Color _secondaryGreen = Color(0xFF4CAF50); // Accent green
  static const Color _lightTextGreen = Color(0xFFE8F5E9); // Light text
  static const Color _darkBaseGreen = Color(0xFF121212); // Background
  static const Color _surfaceGreen = Color(0xFF1E2B1F); // Cards/surfaces
  static const Color _mintGreen = Color(0xFFA5D6A7); // Subtle accent

  static final ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: _darkBaseGreen,
    primaryColor: _primaryGreen,

    colorScheme: const ColorScheme.dark(
      primary: _primaryGreen,
      secondary: _secondaryGreen,
      tertiary: _mintGreen,
      surface: _surfaceGreen,
      background: _darkBaseGreen,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: _lightTextGreen,
      onBackground: _lightTextGreen,
      outline: Color(0xFF81C784),
      outlineVariant: Color(0xFF4A7C59),
      error: Color(0xFFEF9A9A),
      onError: Colors.black,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryGreen,
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
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.black,
        elevation: 2,
        shadowColor: _primaryGreen.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryGreen,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: _lightTextGreen, fontSize: 32, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: _lightTextGreen, fontSize: 28, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: _lightTextGreen, fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: _lightTextGreen, fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: _lightTextGreen, fontSize: 18, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: _lightTextGreen, fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: _lightTextGreen, fontSize: 16),
      bodyMedium: TextStyle(color: _lightTextGreen, fontSize: 14),
      bodySmall: TextStyle(color: _mintGreen, fontSize: 12),
      labelLarge: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
    ),

    iconTheme: const IconThemeData(color: _primaryGreen, size: 24),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryGreen,
      foregroundColor: Colors.black,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),

    cardTheme: CardThemeData(
      color: _surfaceGreen,
      elevation: 2,
      shadowColor: _primaryGreen.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
    ),

    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _surfaceGreen,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _primaryGreen, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF4A7C59), width: 1),
      ),
      labelStyle: TextStyle(color: _lightTextGreen),
      hintStyle: TextStyle(color: _mintGreen),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surfaceGreen,
      selectedItemColor: _primaryGreen,
      unselectedItemColor: _mintGreen,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),

    dividerColor: const Color(0xFF4A7C59),
    shadowColor: _primaryGreen.withOpacity(0.1),

    dialogTheme: const DialogThemeData(
      backgroundColor: _surfaceGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      elevation: 8,
      titleTextStyle: TextStyle(color: _lightTextGreen, fontSize: 20, fontWeight: FontWeight.w600),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: _secondaryGreen,
      contentTextStyle: const TextStyle(color: Colors.black),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: _mintGreen,
      selectedColor: _primaryGreen,
      labelStyle: const TextStyle(color: Colors.black),
      brightness: Brightness.dark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: _primaryGreen,
      inactiveTrackColor: _mintGreen,
      thumbColor: _secondaryGreen,
      overlayColor: _primaryGreen.withOpacity(0.2),
      valueIndicatorColor: _lightTextGreen,
      valueIndicatorTextStyle: const TextStyle(color: Colors.black),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryGreen,
      linearTrackColor: Color(0xFF4A7C59),
      circularTrackColor: Color(0xFF4A7C59),
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor: _primaryGreen,
      unselectedLabelColor: _mintGreen,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: _primaryGreen, width: 2),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? _primaryGreen : const Color(0xFF757575)),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? _primaryGreen.withOpacity(0.5) : const Color(0xFF424242)),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? _primaryGreen : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.black),
      side: const BorderSide(color: Color(0xFF81C784), width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? _primaryGreen : const Color(0xFF757575)),
    ),

    listTileTheme: const ListTileThemeData(
      tileColor: _surfaceGreen,
      selectedTileColor: Color(0xFF2E4731),
      iconColor: _primaryGreen,
      textColor: _lightTextGreen,
      selectedColor: _lightTextGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    bannerTheme: const MaterialBannerThemeData(
      backgroundColor: _surfaceGreen,
      contentTextStyle: TextStyle(color: _lightTextGreen),
      elevation: 2,
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0xFF4A7C59),
      thickness: 1,
      space: 16,
    ),

    expansionTileTheme: const ExpansionTileThemeData(
      backgroundColor: _surfaceGreen,
      collapsedBackgroundColor: _surfaceGreen,
      iconColor: _primaryGreen,
      collapsedIconColor: _mintGreen,
      textColor: _lightTextGreen,
      collapsedTextColor: _lightTextGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: _secondaryGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.black, fontSize: 12),
      preferBelow: false,
    ),
  );
}

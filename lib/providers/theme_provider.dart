import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:emotion_tracker/themes/light_theme.dart';
import 'package:emotion_tracker/themes/dark_theme.dart';
import 'package:emotion_tracker/themes/serenity_green_theme.dart';
import 'package:emotion_tracker/themes/pacific_blue_theme.dart';
import 'package:emotion_tracker/themes/blush_rose_theme.dart';
import 'package:emotion_tracker/themes/cloud_gray_theme.dart';
import 'package:emotion_tracker/themes/sunset_peach_theme.dart';
import 'package:emotion_tracker/themes/midnight_lavender_theme.dart';
import 'package:emotion_tracker/themes/crimson_red_theme.dart';
import 'package:emotion_tracker/themes/forest_green_theme.dart';
import 'package:emotion_tracker/themes/golden_yellow_theme.dart';
import 'package:emotion_tracker/themes/deep_purple_theme.dart';
import 'package:emotion_tracker/themes/blush_rose_theme_dark.dart';
import 'package:emotion_tracker/themes/deep_purple_theme_dark.dart';
import 'package:emotion_tracker/themes/forest_green_theme_dark.dart';
import 'package:emotion_tracker/themes/golden_yellow_theme_dark.dart';
import 'package:emotion_tracker/themes/midnight_lavender_theme_light.dart';
import 'package:emotion_tracker/themes/pacific_blue_theme_dark.dart';
import 'package:emotion_tracker/themes/serenity_green_theme_dark.dart';
import 'package:emotion_tracker/themes/sunset_peach_theme_dark.dart';
import 'package:emotion_tracker/themes/royal_orange_theme.dart';
import 'package:emotion_tracker/themes/royal_orange_theme_dark.dart';
import 'package:emotion_tracker/themes/cloud_gray_theme_dark.dart';
import 'package:emotion_tracker/themes/crimson_red_theme_dark.dart';

class AppThemes {
  static final Map<String, ThemeData> allThemes = {
    'lightTheme': LightTheme.theme,
    'darkTheme': DarkTheme.theme,
    'serenityGreen': SerenityGreenTheme.theme,
    'serenityGreenDark': SerenityGreenDarkTheme.theme,
    'pacificBlue': PacificBlueTheme.theme,
    'pacificBlueDark': PacificBlueDarkTheme.theme,
    'blushRose': BlushRoseTheme.theme,
    'blushRoseDark': BlushRoseDarkTheme.theme,
    'cloudGray': CloudGrayTheme.theme,
    'cloudGrayDark': CloudGrayDarkTheme.theme,
    'sunsetPeach': SunsetPeachTheme.theme,
    'sunsetPeachDark': SunsetPeachDarkTheme.theme,
    'midnightLavender': MidnightLavenderTheme.theme,
    'midnightLavenderLight': MidnightLavenderLightTheme.theme,
    'crimsonRed': CrimsonRedTheme.theme,
    'crimsonRedDark': CrimsonRedDarkTheme.theme,
    'forestGreen': ForestGreenTheme.theme,
    'forestGreenDark': ForestGreenDarkTheme.theme,
    'goldenYellow': GoldenYellowTheme.theme,
    'goldenYellowDark': GoldenYellowDarkTheme.theme,
    'deepPurple': DeepPurpleTheme.theme,
    'deepPurpleDark': DeepPurpleDarkTheme.theme,
    'royalOrange': RoyalOrangeTheme.theme,
    'royalOrangeDark': RoyalOrangeDarkTheme.theme,
  };

  static final Map<String, String> themeNames = {
    'lightTheme': 'Light Theme',
    'darkTheme': 'Dark Theme',
    'serenityGreen': 'Serenity Green',
    'serenityGreenDark': 'Serenity Green Dark',
    'pacificBlue': 'Pacific Blue',
    'pacificBlueDark': 'Pacific Blue Dark',
    'blushRose': 'Blush Rose',
    'blushRoseDark': 'Blush Rose Dark',
    'cloudGray': 'Cloud Gray',
    'cloudGrayDark': 'Cloud Gray Dark',
    'sunsetPeach': 'Sunset Peach',
    'sunsetPeachDark': 'Sunset Peach Dark',
    'midnightLavender': 'Midnight Lavender (Dark)',
    'midnightLavenderLight': 'Midnight Lavender (Light)',
    'crimsonRed': 'Crimson Red',
    'crimsonRedDark': 'Crimson Red Dark',
    'forestGreen': 'Forest Green',
    'forestGreenDark': 'Forest Green Dark',
    'goldenYellow': 'Golden Yellow',
    'goldenYellowDark': 'Golden Yellow Dark',
    'deepPurple': 'Deep Purple',
    'deepPurpleDark': 'Deep Purple Dark',
    'royalOrange': 'Royal Orange',
    'royalOrangeDark': 'Royal Orange Dark',
  };

  static final Map<String, int> themePrices = {
    'lightTheme': 0,
    'darkTheme': 0,
    'serenityGreen': 100,
    'serenityGreenDark': 100,
    'pacificBlue': 100,
    'pacificBlueDark': 100,
    'blushRose': 100,
    'blushRoseDark': 100,
    'cloudGray': 100,
    'cloudGrayDark': 100,
    'sunsetPeach': 100,
    'sunsetPeachDark': 100,
    'midnightLavender': 100,
    'midnightLavenderLight': 100,
    'crimsonRed': 100,
    'crimsonRedDark': 100,
    'forestGreen': 100,
    'forestGreenDark': 100,
    'goldenYellow': 100,
    'goldenYellowDark': 100,
    'deepPurple': 100,
    'deepPurpleDark': 100,
    'royalOrange': 100,
    'royalOrangeDark': 100,
  };

  static final List<String> lightThemeKeys = [
    'lightTheme',
    'serenityGreen',
    'pacificBlue',
    'blushRose',
    'cloudGray',
    'sunsetPeach',
    'goldenYellow',
    'forestGreen',
    'midnightLavenderLight',
    'royalOrange',
    'crimsonRed',
    'deepPurple',
  ];

  static final List<String> darkThemeKeys = [
    'darkTheme',
    'serenityGreenDark',
    'pacificBlueDark',
    'blushRoseDark',
    'cloudGrayDark',
    'sunsetPeachDark',
    'goldenYellowDark',
    'forestGreenDark',
    'midnightLavender',
    'crimsonRedDark',
    'deepPurpleDark',
    'royalOrangeDark',
  ];
}

// Storage provider
final storageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Theme state notifier
class ThemeNotifier extends StateNotifier<String> {
  final FlutterSecureStorage _storage;

  ThemeNotifier(this._storage) : super('lightTheme') {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final savedTheme = await _storage.read(key: 'activeTheme');
    if (savedTheme != null && AppThemes.allThemes.containsKey(savedTheme)) {
      state = savedTheme;
    }
  }

  Future<void> setTheme(String themeKey) async {
    if (AppThemes.allThemes.containsKey(themeKey)) {
      state = themeKey;
      await _storage.write(key: 'activeTheme', value: themeKey);
    }
  }
}

// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, String>((ref) {
  final storage = ref.read(storageProvider);
  return ThemeNotifier(storage);
});

// Current theme data provider
final currentThemeProvider = Provider<ThemeData>((ref) {
  final currentThemeKey = ref.watch(themeProvider);
  return AppThemes.allThemes[currentThemeKey] ?? AppThemes.allThemes['lightTheme']!;
});



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
    'midnightLavenderLight': MidnightLavenderLightTheme.theme, 
    'midnightLavender': MidnightLavenderTheme.theme,
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
    'midnightLavenderLight': 'Midnight Lavender',
    'midnightLavender': 'Midnight Lavender Dark',
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
    'serenityGreen': 250,
    'serenityGreenDark': 250,
    'pacificBlue': 250,
    'pacificBlueDark': 250,
    'blushRose': 250,
    'blushRoseDark': 250,
    'cloudGray': 250,
    'cloudGrayDark': 250,
    'sunsetPeach': 250,
    'sunsetPeachDark': 250,
    'midnightLavender': 250,
    'midnightLavenderLight': 250,
    'crimsonRed': 250,
    'crimsonRedDark': 250,
    'forestGreen': 250,
    'forestGreenDark': 250,
    'goldenYellow': 250,
    'goldenYellowDark': 250,
    'deepPurple': 250,
    'deepPurpleDark': 250,
    'royalOrange': 250,
    'royalOrangeDark': 250,
  };

  static final Map<String, String> themeAdUnitIds = {
    'serenityGreen': 'ca-app-pub-2845453539708646/3160625543',
    'serenityGreenDark': 'ca-app-pub-2845453539708646/5649141791',
    'pacificBlue': 'ca-app-pub-2845453539708646/5004459756',
    'pacificBlueDark': 'ca-app-pub-2845453539708646/3326230785',
    'blushRose': 'ca-app-pub-2845453539708646/3086557633',
    'blushRoseDark': 'ca-app-pub-2845453539708646/8558090752',
    'cloudGray': 'ca-app-pub-2845453539708646/7245009088',
    'cloudGrayDark': 'ca-app-pub-2845453539708646/9221555291',
    'sunsetPeach': 'ca-app-pub-2845453539708646/4618845740',
    'sunsetPeachDark': 'ca-app-pub-2845453539708646/4447740765',
    'midnightLavenderLight': 'ca-app-pub-2845453539708646/1518325094',
    'midnightLavender': 'ca-app-pub-2845453539708646/3134659097',
    'crimsonRed': 'ca-app-pub-2845453539708646/8814361181',
    'crimsonRedDark': 'ca-app-pub-2845453539708646/5282310282',
    'forestGreen': 'ca-app-pub-2845453539708646/4427274050',
    'forestGreenDark': 'ca-app-pub-2845453539708646/6065425839',
    'goldenYellow': 'ca-app-pub-2845453539708646/4416499916',
    'goldenYellowDark': 'ca-app-pub-2845453539708646/8195414088',
    'deepPurple': 'ca-app-pub-2845453539708646/3439262492',
    'deepPurpleDark': 'ca-app-pub-2845453539708646/5314099872',
    'royalOrange': 'ca-app-pub-2845453539708646/4256169075',
    'royalOrangeDark': 'ca-app-pub-2845453539708646/8632745390',
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



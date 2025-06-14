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

class AppThemes {
  static final Map<String, ThemeData> allThemes = {
    'lightTheme': LightTheme.theme,
    'darkTheme': DarkTheme.theme,
    'serenityGreen': SerenityGreenTheme.theme,
    'pacificBlue': PacificBlueTheme.theme,
    'blushRose': BlushRoseTheme.theme,
    'cloudGray': CloudGrayTheme.theme,
    'sunsetPeach': SunsetPeachTheme.theme,
    'midnightLavender': MidnightLavenderTheme.theme,
  };

  static final Map<String, String> themeNames = {
    'lightTheme': 'Light Blue',
    'darkTheme': 'Dark Blue',
    'serenityGreen': 'Serenity Green',
    'pacificBlue': 'Pacific Blue',
    'blushRose': 'Blush Rose',
    'cloudGray': 'Cloud Gray',
    'sunsetPeach': 'Sunset Peach',
    'midnightLavender': 'Midnight Lavender',
  };
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
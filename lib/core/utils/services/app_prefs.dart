// lib/core/services/app_prefs.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AppPrefs {
  static const _keyThemeMode = 'theme_mode'; // 'light' | 'dark' | 'system'
  static const _keyLocale = 'locale';       // 'ar' | 'en'

  final SharedPreferences _prefs;
  AppPrefs(this._prefs);

  // Theme
  ThemeMode getThemeMode() {
    final v = _prefs.getString(_keyThemeMode) ?? 'light';
    switch (v) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final v = mode == ThemeMode.dark ? 'dark' : mode == ThemeMode.system ? 'system' : 'light';
    await _prefs.setString(_keyThemeMode, v);
  }

  // Locale
  Locale getLocale() {
    final code = _prefs.getString(_keyLocale) ?? 'ar';
    return Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_keyLocale, locale.languageCode);
  }

  static Future<AppPrefs> init() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPrefs(prefs);
  }
}

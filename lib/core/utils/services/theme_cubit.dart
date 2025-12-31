// lib/features/settings/manager/theme_cubit/theme_cubit.dart
 import 'package:daad_app/core/utils/services/app_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
class ThemeCubit extends Cubit<ThemeMode> {
  final AppPrefs _prefs;
  ThemeCubit(this._prefs) : super(ThemeMode.light);

  Future<void> load() async {
    emit(_prefs.getThemeMode());
  }

  Future<void> setTheme(ThemeMode mode) async {
    await _prefs.setThemeMode(mode);
    emit(mode);
  }

  Future<void> toggleDark(bool isDark) async {
    await setTheme(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}

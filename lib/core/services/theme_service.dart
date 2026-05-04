import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer le thème de l'application
class ThemeService {
  static const String _themeModeKey = 'app_theme_mode';
  static const ThemeMode _defaultThemeMode = ThemeMode.system;
  
  final SharedPreferences _prefs;
  
  ThemeService(this._prefs);
  
  /// Récupère le mode de thème actuel
  ThemeMode getCurrentThemeMode() {
    final themeModeString = _prefs.getString(_themeModeKey);
    if (themeModeString != null) {
      switch (themeModeString) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        case 'system':
          return ThemeMode.system;
        default:
          return _defaultThemeMode;
      }
    }
    return _defaultThemeMode;
  }
  
  /// Définit le mode de thème
  Future<void> setThemeMode(ThemeMode mode) async {
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    await _prefs.setString(_themeModeKey, modeString);
    // Notifier le changement de thème
    _notifyThemeChange(mode);
  }
  
  /// Callback pour notifier les changements de thème
  void Function(ThemeMode)? onThemeChanged;
  
  void _notifyThemeChange(ThemeMode mode) {
    onThemeChanged?.call(mode);
  }
}


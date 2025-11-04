import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';

/// Service pour gérer la langue de l'application
class LanguageService {
  static const String _languageKey = 'app_language';
  static const Locale _defaultLocale = Locale('fr', '');
  
  final SharedPreferences _prefs;
  
  LanguageService(this._prefs);
  
  /// Récupère la locale actuelle
  Locale getCurrentLocale() {
    final languageCode = _prefs.getString(_languageKey);
    if (languageCode != null) {
      return Locale(languageCode);
    }
    return _defaultLocale;
  }
  
  /// Définit la langue de l'application
  Future<void> setLanguage(Locale locale) async {
    await _prefs.setString(_languageKey, locale.languageCode);
    // Notifier le changement de langue
    _notifyLanguageChange(locale);
  }
  
  /// Callback pour notifier les changements de langue
  void Function(Locale)? onLanguageChanged;
  
  void _notifyLanguageChange(Locale locale) {
    onLanguageChanged?.call(locale);
  }
  
  /// Récupère la liste des langues supportées
  List<Locale> getSupportedLocales() {
    return [
      const Locale('fr', ''),
      const Locale('en', ''),
      const Locale('de', ''),
      const Locale('ja', ''),
      const Locale('ko', ''),
      const Locale('pt', ''),
      const Locale('es', ''),
    ];
  }

  /// Récupère le nom de la langue pour l'affichage
  String getLanguageName(Locale locale, BuildContext context) {
    // Utiliser les traductions si disponibles, sinon les noms par défaut
    switch (locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      case 'pt':
        return 'Português';
      case 'es':
        return 'Español';
      default:
        return locale.languageCode;
    }
  }
}

/// Extension pour obtenir le LanguageService depuis GetIt
extension LanguageServiceExtension on BuildContext {
  LanguageService get languageService => getIt<LanguageService>();
}


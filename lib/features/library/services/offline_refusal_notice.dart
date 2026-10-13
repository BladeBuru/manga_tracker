import 'package:flutter/widgets.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/language_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Prévient l'utilisateur qu'une progression enregistrée hors ligne a été
/// refusée pour de bon au rejeu de la file (avant : abandonnée en silence,
/// la lecture faite dans le métro disparaissait sans un mot).
///
/// Pas de `BuildContext` ici : textes dans la langue choisie
/// (`lookupAppLocalizations`) et message via le [Notifier] global. Sans
/// effet si l'interface n'est pas prête (démarrage, tests).
void notifyOfflineProgressRefused(OfflineAction action) {
  try {
    final l10n = _localizations();
    getIt<Notifier>().warning(
      l10n.offlineProgressRefused(action.readChapters ?? 0),
    );
  } catch (e) {
    debugPrint('⚠️ Progression hors ligne refusée (${action.muId}) : $e');
  }
}

AppLocalizations _localizations() {
  try {
    return lookupAppLocalizations(getIt<LanguageService>().getCurrentLocale());
  } catch (_) {
    return lookupAppLocalizations(const Locale('fr'));
  }
}

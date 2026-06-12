import 'package:mangatracker/l10n/app_localizations.dart';

/// Format email — détection volontairement large pour l'affichage public.
final RegExp _emailLike = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Defense-in-depth RGPD (hotfix-v0-10-1 US-3) — miroir du
/// `stripEmailFormat` côté API.
///
/// Le fix racine est côté API (validation + migration des usernames au
/// format email), mais si une donnée legacy passe quand même, on ne doit
/// JAMAIS afficher une adresse email comme nom d'auteur : l'OS
/// l'auto-linkifie (tap = mailto) et c'est une donnée personnelle.
///
/// Retourne la part locale (`jean@mail.com` → `jean`), sinon [value] intact.
String stripEmailFormat(String value) {
  return _emailLike.hasMatch(value.trim()) ? value.split('@')[0] : value;
}

/// Variante l10n : remplace un nom au format email par la clé ARB
/// `anonymousUser` (à préférer quand un BuildContext est disponible et que
/// la part locale serait trop identifiante pour le contexte d'affichage).
String safeDisplayName(String raw, AppLocalizations? l10n) {
  if (_emailLike.hasMatch(raw.trim())) {
    return l10n?.anonymousUser ?? 'Utilisateur anonyme';
  }
  return raw;
}

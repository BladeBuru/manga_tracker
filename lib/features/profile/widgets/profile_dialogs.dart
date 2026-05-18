import 'package:flutter/material.dart';

import 'package:mangatracker/features/profile/widgets/dialogs/biometric_reconnect_dialog.dart';
import 'package:mangatracker/features/profile/widgets/dialogs/change_password_dialog.dart'
    as cp;
import 'package:mangatracker/features/profile/widgets/dialogs/delete_account_dialog.dart';
import 'package:mangatracker/features/profile/widgets/dialogs/logout_dialog.dart';
import 'package:mangatracker/features/profile/widgets/dialogs/theme_selector_dialog.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  ProfileDialogs — façade statique pour tous les dialogs Profile (V1). ║
// ║                                                                       ║
// ║  Les implémentations vivent dans `widgets/dialogs/*.dart` pour rester ║
// ║  sous la limite 400 lignes/fichier (CLAUDE.md). Cette classe préserve ║
// ║  l'API existante consommée par `profile.dart` et `profile_body.dart`. ║
// ╚═══════════════════════════════════════════════════════════════════════╝

class ProfileDialogs {
  ProfileDialogs._();

  /// Sélecteur de thème (clair / sombre / système).
  /// Retourne le `ThemeMode` choisi ou `null` si annulé.
  static Future<ThemeMode?> showThemeSelector({
    required BuildContext context,
    required ThemeMode currentMode,
  }) =>
      showThemeSelectorDialog(context: context, currentMode: currentMode);

  /// Dialog de confirmation de suppression de compte.
  /// Le caller exécute la suppression si `true` est renvoyé.
  static Future<bool> showDeleteAccountConfirm(BuildContext context) =>
      showDeleteAccountConfirmDialog(context);

  /// Dialog de changement de mot de passe.
  /// Retourne le nouveau mot de passe ou `null` si annulé / invalide.
  static Future<String?> showChangePasswordDialog(BuildContext context) =>
      cp.showChangePasswordDialog(context);

  /// Dialog de confirmation de déconnexion.
  /// Retourne `true` si l'utilisateur a confirmé.
  static Future<bool> showLogoutConfirm(BuildContext context) =>
      showLogoutConfirmDialog(context);

  /// Dialog "biométrie nécessite une reconnexion". Retourne `true` si
  /// l'utilisateur a choisi de se déconnecter immédiatement.
  static Future<bool> showBiometricReconnectDialog(BuildContext context) =>
      showBiometricReconnectInfoDialog(context);

  /// Retourne le nom localisé d'un `ThemeMode`.
  static String themeModeName(ThemeMode mode, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case ThemeMode.light:
        return l10n.lightMode;
      case ThemeMode.dark:
        return l10n.darkMode;
      case ThemeMode.system:
        return l10n.systemMode;
    }
  }
}

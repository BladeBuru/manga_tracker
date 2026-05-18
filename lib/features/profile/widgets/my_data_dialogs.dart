import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  Dialogs de la page « Mes données » (RGPD).                           ║
// ║  Style aligné Design System V1 « Refined Classic » — bg-light, radius ║
// ║  xxxl, hairline outline. Découpé de `my_data_view.dart` pour rester   ║
// ║  sous la limite 400 lignes / fichier (CLAUDE.md).                     ║
// ╚═══════════════════════════════════════════════════════════════════════╝

class MyDataDialogs {
  MyDataDialogs._();

  /// Affiche le résumé JSON des données utilisateur (article 15).
  static Future<void> showSummary(
    BuildContext context,
    Map<String, dynamic> summary,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final formatted = const JsonEncoder.withIndent('  ').convert(summary);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.dsSurfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circularXxxl,
          side: BorderSide(color: AppColors.dsHairline(brightness), width: 1),
        ),
        title: Text(
          l10n.myDataSummaryTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360, maxWidth: 480),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.dsBgInset(brightness),
                borderRadius: AppRadius.circularLg,
              ),
              child: SelectableText(
                formatted,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.dsText2(brightness),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(foregroundColor: scheme.primary),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  /// Affiche un document légal (politique de confidentialité ou CGU)
  /// dans un dialog. `isPrivacy` détermine le titre et le contenu.
  static Future<void> showLegalDoc(
    BuildContext context, {
    required bool isPrivacy,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.dsSurfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circularXxxl,
          side: BorderSide(color: AppColors.dsHairline(brightness), width: 1),
        ),
        title: Text(
          isPrivacy ? l10n.privacyPolicyTitle : l10n.termsOfServiceTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360, maxWidth: 480),
          child: SingleChildScrollView(
            child: Text(
              isPrivacy ? l10n.privacyShortVersion : l10n.tosShortVersion,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.dsText2(brightness),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(foregroundColor: scheme.primary),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}

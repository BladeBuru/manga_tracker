import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';

/// Bannière "action en cours" V1 — spinner + texte.
///
/// **Refactor 2026-05-18** : remplace l'ancien `Container` `Colors.blue`
/// hardcodé (border + bg + text) par un design hairline avec `dsBgInset`
/// et `colorScheme.primary`. Cohérent avec ProfileEditSection.
class LibraryActionBanner extends StatelessWidget {
  final String action;

  const LibraryActionBanner({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.dsBgInset(brightness),
        border: Border.all(color: AppColors.dsHairline(brightness)),
        borderRadius: AppRadius.circularMd,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              action,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

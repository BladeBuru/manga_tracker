import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/recommendations/dto/dismissal_reason.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Feuille modale « ne plus me recommander ce titre ».
///
/// Retourne la [DismissalReason] choisie, ou `null` si l'utilisateur ferme
/// la feuille sans choisir (glissement, bouton Annuler, retour système).
///
/// La raison est demandée plutôt que déduite : c'est elle qui a de la valeur
/// pour un futur moteur de recommandation, pas le simple fait du rejet.
Future<DismissalReason?> showDismissRecommendationSheet(
  BuildContext context, {
  required String mangaTitle,
}) {
  return showModalBottomSheet<DismissalReason>(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.jumbo),
      ),
    ),
    builder: (sheetContext) =>
        _DismissRecommendationSheet(mangaTitle: mangaTitle),
  );
}

class _DismissRecommendationSheet extends StatelessWidget {
  final String mangaTitle;

  const _DismissRecommendationSheet({required this.mangaTitle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          AppSpacing.m,
          AppSpacing.m,
          AppSpacing.s,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n?.dismissRecommendationSheetTitle ??
                  'Ne plus me recommander ce titre',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n?.dismissRecommendationSheetSubtitle(mangaTitle) ??
                  '« $mangaTitle » disparaîtra de tes recommandations.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            _ReasonRow(
              icon: Icons.menu_book_outlined,
              label: l10n?.dismissReasonAlreadyRead ?? 'Déjà lu',
              hint:
                  l10n?.dismissReasonAlreadyReadHint ??
                  'Je l’ai lu, plus rien à découvrir',
              reason: DismissalReason.alreadyRead,
            ),
            _ReasonRow(
              icon: Icons.thumb_down_outlined,
              label: l10n?.dismissReasonNotInterested ?? 'Pas intéressé',
              hint:
                  l10n?.dismissReasonNotInterestedHint ??
                  'Ce n’est pas mon genre',
              reason: DismissalReason.notInterested,
            ),
            _ReasonRow(
              icon: Icons.live_tv_outlined,
              label: l10n?.dismissReasonSeenElsewhere ?? 'Vu ailleurs',
              hint:
                  l10n?.dismissReasonSeenElsewhereHint ??
                  'En animé, en drama ou au cinéma',
              reason: DismissalReason.seenElsewhere,
            ),
            const SizedBox(height: AppSpacing.s),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n?.cancel ?? 'Annuler'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une raison sélectionnable — ferme la feuille en renvoyant sa valeur.
class _ReasonRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final DismissalReason reason;

  const _ReasonRow({
    required this.icon,
    required this.label,
    required this.hint,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.circularXl),
      leading: Icon(icon, color: scheme.primary),
      title: Text(label),
      subtitle: Text(
        hint,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      onTap: () => Navigator.of(context).pop(reason),
    );
  }
}

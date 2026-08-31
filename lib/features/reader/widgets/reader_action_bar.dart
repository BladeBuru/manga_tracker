import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Actions reléguées derrière le menu « trois points ».
enum ReaderOverflowAction {
  /// Enregistrer la page courante pour la lecture hors ligne.
  downloadPage,

  /// Copier l'URL courante dans le presse-papiers.
  copyUrl,

  /// Basculer le mode « désigner une pub pour la bloquer ».
  toggleInteractiveAdBlock,

  /// Afficher l'explication du bloqueur de publicités.
  adBlockerInfo,
}

/// Barre d'actions de la vue de lecture en ligne.
///
/// Deux niveaux. Restent visibles les deux gestes que l'on fait *pendant* la
/// lecture, sur la page que l'on est en train de lire : rafraîchir quand elle
/// a mal chargé, et couper le bloqueur quand il casse le site. Le reste — une
/// fois par chapitre (télécharger, copier l'URL) ou une fois pour toutes
/// (mode désignation, explication) — part dans l'overflow.
class ReaderActionBar extends StatelessWidget {
  const ReaderActionBar({
    super.key,
    required this.adBlockerEnabled,
    required this.interactiveAdBlockMode,
    required this.onRefresh,
    required this.onToggleAdBlocker,
    required this.onOverflowAction,
  });

  /// État courant du bloqueur de publicités.
  final bool adBlockerEnabled;

  /// État courant du mode de désignation interactive des publicités.
  final bool interactiveAdBlockMode;

  /// Recharge la page en préservant le contexte de lecture.
  final VoidCallback onRefresh;

  /// Reçoit l'état *souhaité* du bloqueur, pas l'état courant.
  final ValueChanged<bool> onToggleAdBlocker;

  final ValueChanged<ReaderOverflowAction> onOverflowAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    // Le libellé décrit l'action à venir, pas l'état : c'est ce qu'attend un
    // lecteur d'écran sur un bouton, l'état étant porté par `isSelected`.
    final adBlockerLabel = adBlockerEnabled
        ? (l10n?.adBlockerDisableAction ??
            'Désactiver le bloqueur de publicités')
        : (l10n?.adBlockerEnableAction ?? 'Activer le bloqueur de publicités');

    final refreshLabel = l10n?.readerRefresh ?? 'Rafraîchir la page';

    // `tooltip` renseigne la propriété sémantique du même nom, mais laisse le
    // `label` du nœud vide : un lecteur d'écran qui navigue par libellés
    // n'annoncerait qu'« bouton ». Le `semanticLabel` de l'icône comble ce
    // manque — d'où les deux, volontairement identiques.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onRefresh,
          tooltip: refreshLabel,
          icon: Icon(Icons.refresh_outlined, semanticLabel: refreshLabel),
        ),
        IconButton(
          isSelected: adBlockerEnabled,
          onPressed: () => onToggleAdBlocker(!adBlockerEnabled),
          tooltip: adBlockerLabel,
          icon: Icon(
            Icons.block_outlined,
            semanticLabel: adBlockerLabel,
            color: adBlockerEnabled ? colors.primary : colors.onSurfaceVariant,
          ),
        ),
        _buildOverflowMenu(l10n),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  Widget _buildOverflowMenu(AppLocalizations? l10n) {
    final moreLabel = l10n?.readerMoreActions ?? "Plus d'actions";
    final interactiveLabel = interactiveAdBlockMode
        ? (l10n?.adBlockerInteractiveDisable ??
            'Désactiver le mode détection de pub')
        : (l10n?.adBlockerInteractiveEnable ??
            'Activer le mode détection de pub');

    return PopupMenuButton<ReaderOverflowAction>(
      icon: Icon(Icons.more_vert_outlined, semanticLabel: moreLabel),
      tooltip: moreLabel,
      onSelected: onOverflowAction,
      itemBuilder: (context) => [
        _item(
          ReaderOverflowAction.downloadPage,
          Icons.download_outlined,
          l10n?.readerDownloadPage ?? 'Télécharger cette page',
        ),
        _item(
          ReaderOverflowAction.copyUrl,
          Icons.content_copy_outlined,
          l10n?.copyUrl ?? "Copier l'URL",
        ),
        _item(
          ReaderOverflowAction.toggleInteractiveAdBlock,
          Icons.touch_app_outlined,
          interactiveLabel,
        ),
        _item(
          ReaderOverflowAction.adBlockerInfo,
          Icons.info_outline,
          l10n?.adBlockerTooltip ?? 'Informations sur le bloqueur de pub',
        ),
      ],
    );
  }

  PopupMenuItem<ReaderOverflowAction> _item(
    ReaderOverflowAction value,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem<ReaderOverflowAction>(
      value: value,
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: AppSpacing.m),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

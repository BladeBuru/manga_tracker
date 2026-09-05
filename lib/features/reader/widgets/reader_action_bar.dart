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
///
/// Le bloqueur est un **interrupteur** (`Switch`), pas un bouton : son état
/// doit se lire d'un coup d'œil, sans avoir à deviner si l'icône est
/// « allumée ». Il se coupe de lui-même pendant une vérification anti-robot
/// et se rallume ensuite — l'interrupteur le montre en temps réel.
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
        _AdBlockerSwitch(enabled: adBlockerEnabled, onChanged: onToggleAdBlocker),
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

/// Interrupteur du bloqueur de publicités.
///
/// L'icône dans le pommeau rappelle ce que l'interrupteur commande ; le
/// tooltip décrit l'action à venir (ce qu'attend un lecteur d'écran), l'état
/// étant porté par la sémantique `toggled` du `Switch` lui-même.
class _AdBlockerSwitch extends StatelessWidget {
  const _AdBlockerSwitch({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actionLabel = enabled
        ? (l10n?.adBlockerDisableAction ??
            'Désactiver le bloqueur de publicités')
        : (l10n?.adBlockerEnableAction ?? 'Activer le bloqueur de publicités');

    // Un seul nœud sémantique : libellé (action à venir), tooltip et état
    // « toggled » du Switch, sinon un lecteur d'écran annonce trois choses.
    return MergeSemantics(
      child: Tooltip(
        message: actionLabel,
        child: Semantics(
          label: actionLabel,
          child: Switch(
            value: enabled,
            onChanged: onChanged,
            thumbIcon: WidgetStateProperty.resolveWith(
              (states) => Icon(
                states.contains(WidgetState.selected)
                    ? Icons.block
                    : Icons.block_outlined,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

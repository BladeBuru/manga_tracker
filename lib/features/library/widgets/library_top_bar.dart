import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';

/// Top bar V1 « Refined Classic » de la bibliothèque.
///
/// Source : `.claude-design/manga-tracker/project/screen-library.jsx`
/// (lignes 44-64). Remplace l'AppBar Material 3 par :
///  - Un titre **"Bibliothèque"** large (24px / 900 / letterSpacing -0.025em)
///  - 3 boutons à droite **36×36 radius 10** :
///    - Téléchargement (toggle "downloaded only" filter)
///    - Dossier (navigation `/downloads`)
///    - List/Grid toggle (active state = bg `red-tile` + icône rouge)
///  - **Pas de fond pleine largeur** ni shadow — la top bar respire dans
///    le fond `dsBg` de la page.
class LibraryTopBar extends StatelessWidget {
  final String title;
  final bool showDownloadedOnly;
  final bool isCardView;
  final VoidCallback onToggleDownloadedFilter;
  final VoidCallback onOpenDownloads;
  final VoidCallback onToggleView;
  final String? toggleDownloadedTooltip;
  final String? openDownloadsTooltip;
  final String? toggleViewTooltip;

  const LibraryTopBar({
    super.key,
    required this.title,
    required this.showDownloadedOnly,
    required this.isCardView,
    required this.onToggleDownloadedFilter,
    required this.onOpenDownloads,
    required this.onToggleView,
    this.toggleDownloadedTooltip,
    this.openDownloadsTooltip,
    this.toggleViewTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6, // -0.025em × 24
                color: scheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _LibActionButton(
            icon: showDownloadedOnly
                ? Icons.download_rounded
                : Icons.download_outlined,
            active: showDownloadedOnly,
            onTap: onToggleDownloadedFilter,
            tooltip: toggleDownloadedTooltip,
          ),
          const SizedBox(width: 6),
          _LibActionButton(
            icon: Icons.folder_outlined,
            active: false,
            onTap: onOpenDownloads,
            tooltip: openDownloadsTooltip,
          ),
          const SizedBox(width: 6),
          _LibActionButton(
            // L'icône REPRÉSENTE le mode VERS lequel on bascule (UX standard
            // « toggle » : l'icône montre la destination, pas l'état courant).
            icon: isCardView ? Icons.view_list_outlined : Icons.grid_view_outlined,
            active: true,
            onTap: onToggleView,
            tooltip: toggleViewTooltip,
          ),
        ],
      ),
    );
  }
}

/// Bouton d'action 36×36 du design V1 — fond surface + hairline OU rouge
/// soft + icône rouge quand actif.
class _LibActionButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String? tooltip;

  const _LibActionButton({
    required this.icon,
    required this.active,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final bg = active
        ? AppColors.dsRedSoft(brightness)
        : (brightness == Brightness.dark
            ? AppColors.dsSurfaceDark
            : Colors.white);
    final iconColor =
        active ? scheme.primary : AppColors.dsText2(brightness);
    final borderColor = active
        ? Colors.transparent
        : AppColors.dsHairline(brightness);

    final button = Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Center(
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

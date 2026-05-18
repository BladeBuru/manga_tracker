import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Barre de recherche pilule du Design System V1 « Refined Classic ».
///
/// Source : `.claude-design/manga-tracker/project/screen-search.jsx`.
///
/// Spécifications visuelles :
///  - Container padding 12x14, fond `surface`, radius 14.
///  - Border 1.5px : rouge primary si query non vide, hairline sinon.
///  - 🦊 emoji à gauche (18px).
///  - TextField sans bordure ni outline.
///  - Bouton « x » à droite quand query non vide (clear).
class SearchBarInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SearchBarInput({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final hasQuery = controller.text.isNotEmpty;
    final bg = brightness == Brightness.dark
        ? AppColors.dsSurfaceDark
        : Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasQuery
              ? scheme.primary
              : AppColors.dsHairline(brightness),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // **Fix 2026-05-18 v3** : le logo app à 22×22 rendait mal (logo
          // pensé pour icône lanceur, pas pour inline UI). On utilise une
          // icône magnifying glass outlined — pattern universel pour les
          // search bars, et cohérent avec le set V1 d'icônes outlined.
          Icon(
            Icons.search_outlined,
            size: 20,
            color: hasQuery
                ? scheme.primary
                : AppColors.dsText3(brightness),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: l10n.searchPlaceholder,
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.dsText3(brightness),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (hasQuery)
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.dsText3(brightness),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


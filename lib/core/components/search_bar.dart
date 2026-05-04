import 'package:flutter/material.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mangatracker/core/theme/app_radius.dart';

/// Composant réutilisable de barre de recherche moderne avec Material Design 3
class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String)? onChanged;
  final String? hintText;
  final bool showLogo;
  final bool showClearButton;

  const CustomSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.hintText,
    this.showLogo = false,
    this.showClearButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.circularXl,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              if (showLogo)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: SizedBox(
                    height: 20,
                    child: Image.asset('assets/images/mask_logo.png'),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hintText ?? (l10n?.searchPlaceholder ?? 'Rechercher...'),
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (showClearButton && value.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}


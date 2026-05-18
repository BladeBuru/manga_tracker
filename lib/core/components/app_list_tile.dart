import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';

/// Tile de liste générique avec slots leading/title/subtitle/trailing.
///
/// Wrapper opinionné autour de `ListTile` qui force :
///  - background `surfaceContainerLow` avec radius `md`
///  - leading avec ressort container coloré pour les icônes
///  - typographie `titleSmall` / `bodySmall` cohérente
///
/// Pour les avatars circulaires : passer un `CircleAvatar` directement
/// en `leadingWidget` plutôt que `leadingIcon`.
class AppListTile extends StatelessWidget {
  final IconData? leadingIcon;
  final Widget? leadingWidget;
  final Color? leadingIconBackgroundColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AppListTile({
    super.key,
    this.leadingIcon,
    this.leadingWidget,
    this.leadingIconBackgroundColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  }) : assert(
          leadingIcon != null || leadingWidget != null,
          'Must provide either leadingIcon or leadingWidget',
        );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final leading = leadingWidget ??
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: leadingIconBackgroundColor ?? scheme.primaryContainer,
            borderRadius: AppRadius.circularMd,
          ),
          child: Icon(
            leadingIcon!,
            size: 22,
            color: scheme.onPrimaryContainer,
          ),
        );

    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.circularMd),
      child: InkWell(
        borderRadius: AppRadius.circularMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

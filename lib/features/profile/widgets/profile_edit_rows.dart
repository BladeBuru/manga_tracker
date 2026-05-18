import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  Design System V1 — rows tappables (date + privacy).                  ║
// ║  Source : .claude-design/manga-tracker/project/profile-v1.jsx         ║
// ║  Extrait de profile_edit_sections.dart pour rester sous la limite    ║
// ║  400 lignes par fichier (CLAUDE.md).                                  ║
// ╚═══════════════════════════════════════════════════════════════════════╝

// ─────────────────────────────────────────────────────────────────────────────
// ProfileEditDateField — clickable row : label uppercase + (cake icon rouge +
// date) + chevron right. Clear button optionnel inline (× discret).
// ─────────────────────────────────────────────────────────────────────────────

class ProfileEditDateField extends StatelessWidget {
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const ProfileEditDateField({
    super.key,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final hasValue = value != null;
    return InkWell(
      onTap: onPick,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.profileFieldDateOfBirth.toUpperCase(),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.63,
                color: AppColors.dsText3(brightness),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.cake_outlined,
                        size: 16,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasValue
                            ? DateFormat.yMMMMd(locale).format(value!)
                            : l10n.profileNotSet,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: hasValue
                              ? scheme.onSurface
                              : AppColors.dsText3(brightness),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasValue)
                  InkWell(
                    onTap: onClear,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.dsText3(brightness),
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.dsText3(brightness),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProfileEditPrivacyRow — eye/eye-off icon rouge + titre + sous-titre + switch.
// Toute la row est cliquable (toggle le switch).
// ─────────────────────────────────────────────────────────────────────────────

class ProfileEditPrivacyRow extends StatelessWidget {
  final bool isPublic;
  final ValueChanged<bool> onToggle;

  const ProfileEditPrivacyRow({
    super.key,
    required this.isPublic,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () => onToggle(!isPublic),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Icon(
              isPublic
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 22,
              color:
                  isPublic ? scheme.primary : AppColors.dsText2(brightness),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileFieldIsPublic,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.profileFieldIsPublicSubtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: AppColors.dsText2(brightness),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Switch natif Material — colorScheme.primary géré par le thème.
            Switch(value: isPublic, onChanged: onToggle),
          ],
        ),
      ),
    );
  }
}

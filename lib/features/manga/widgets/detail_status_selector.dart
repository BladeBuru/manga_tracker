import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/manga/bloc/detail_bloc.dart';
import 'package:mangatracker/features/manga/bloc/detail_event.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  V1 « Refined Classic » — Sélecteur de statut horizontal scrollable.  ║
// ║  Chaque chip : default = hairline + dsText2,                          ║
// ║  actif = bg dsRedSoft + border primary + text primary + ✓ check icon. ║
// ║  AnimatedContainer 150ms. Dispatche UpdateReadingStatus au BLoC.      ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// Sélecteur horizontal de statut de lecture pour un manga déjà en bibliothèque.
///
/// - Si [status] est `null` (manga pas en bibliothèque), ce widget retourne
///   un `SizedBox.shrink` (la CTA "Ajouter à la bibliothèque" est gérée
///   ailleurs par [DetailAddToLibraryButton]).
/// - Tap sur un chip non actif → dispatche `UpdateReadingStatus(newStatus)`.
/// - Tap sur le chip actif → ouvre la sheet de gestion via [onManageRequested]
///   (qui permet aussi de retirer le manga de la bibliothèque).
class DetailStatusSelector extends StatelessWidget {
  final ReadingStatus? status;
  final void Function(ReadingStatus status) onStatusChanged;
  final VoidCallback onManageRequested;

  const DetailStatusSelector({
    super.key,
    required this.status,
    required this.onStatusChanged,
    required this.onManageRequested,
  });

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final l10n = AppLocalizations.of(context)!;

    final entries = <(ReadingStatus, String)>[
      (ReadingStatus.reading, l10n.reading),
      (ReadingStatus.readLater, l10n.readLater),
      (ReadingStatus.caughtUp, l10n.upToDate),
      (ReadingStatus.completed, l10n.completed),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.changeStatus.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.63,
              color: AppColors.dsText3(brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s),
              itemBuilder: (context, index) {
                final (value, label) = entries[index];
                final selected = value == status;
                return _StatusChip(
                  value: value,
                  label: label,
                  selected: selected,
                  onTap: () {
                    if (selected) {
                      onManageRequested();
                    } else {
                      onStatusChanged(value);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ReadingStatus value;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.value,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final isDark = brightness == Brightness.dark;
    final bg = selected
        ? AppColors.dsRedSoft(brightness)
        : (isDark ? AppColors.dsSurfaceDark : Colors.white);
    final borderColor =
        selected ? scheme.primary : AppColors.dsBorder(brightness);
    final textColor =
        selected ? scheme.primary : AppColors.dsText2(brightness);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check : value.icon,
              size: 14,
              color: textColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA "Ajouter à la bibliothèque" — full-width red filled, V1 style.
// Utilisé quand le manga n'est pas encore dans la bibliothèque.
// ─────────────────────────────────────────────────────────────────────────────

class DetailAddToLibraryButton extends StatelessWidget {
  final int muId;
  final VoidCallback? onAdded;

  const DetailAddToLibraryButton({
    super.key,
    required this.muId,
    this.onAdded,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withAlpha(95),
              blurRadius: 20,
              spreadRadius: -8,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: () {
            context.read<DetailBloc>().add(AddToLibrary(muId));
            onAdded?.call();
          },
          icon: const Icon(Icons.bookmark_add_outlined, size: 18),
          label: Text(l10n.addToLibrary),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.15,
            ),
          ),
        ),
      ),
    );
  }
}

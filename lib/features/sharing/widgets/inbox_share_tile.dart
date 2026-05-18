import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mangatracker/core/components/app_avatar.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/sharing/dto/share.dto.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Row d'une recommandation reçue dans l'inbox.
///
/// Design System V1 « Refined Classic » :
///  - Padding 14/16 dans une `ProfileEditSection` (le card est porté par
///    le parent, avec hairline divider entre tiles).
///  - Layout : avatar 44px · bloc texte (sender / titre / méta) · chevron.
///  - Row "non-vue" → bg subtil `red-soft` + barre verticale rouge 3px à
///    gauche (cohérent avec le focused state de ProfileEditField).
///  - Pill "NOUVEAU" rouge solide pour les non-vues, fontSize 10.5.
///  - Message optionnel dans un blockquote inset.
class InboxShareTile extends StatelessWidget {
  final MangaShareDto share;
  final VoidCallback onTap;

  const InboxShareTile({
    super.key,
    required this.share,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final isNew = share.isNew;

    return Stack(
      children: [
        if (isNew)
          Positioned(
            top: 10,
            bottom: 10,
            left: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        Material(
          color: isNew
              ? AppColors.dsRedSoft(brightness).withValues(alpha: 0.35)
              : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppAvatar(
                    url: share.senderAvatarUrl,
                    fallback: share.senderUsername,
                    size: AppAvatarSize.large,
                  ),
                  const SizedBox(width: AppSpacing.m - 2),
                  Expanded(
                    child: _InboxShareTileBody(
                      share: share,
                      brightness: brightness,
                      isNew: isNew,
                      l10n: l10n,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.dsText3(brightness),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InboxShareTileBody extends StatelessWidget {
  final MangaShareDto share;
  final Brightness brightness;
  final bool isNew;
  final AppLocalizations l10n;

  const _InboxShareTileBody({
    required this.share,
    required this.brightness,
    required this.isNew,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasMessage = share.message != null && share.message!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne 1 : "{sender} vous a partagé"
        Text(
          l10n.inboxSharedYouLabel(share.senderUsername),
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.dsText2(brightness),
            letterSpacing: -0.05,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        // Ligne 2 : titre du manga (l'élément principal)
        Text(
          share.mangaTitle,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
            letterSpacing: -0.2,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (hasMessage) ...[
          const SizedBox(height: 8),
          _MessageQuote(message: share.message!, brightness: brightness),
        ],
        const SizedBox(height: 6),
        // Ligne 3 : date relative + pill NOUVEAU
        Row(
          children: [
            Flexible(
              child: Text(
                _formatRelative(share.createdAt, context),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.dsText3(brightness),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isNew) ...[
              const SizedBox(width: 8),
              _NewBadge(label: l10n.inboxBadgeNew),
            ],
          ],
        ),
      ],
    );
  }

  String _formatRelative(DateTime utc, BuildContext context) {
    final local = utc.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) {
      return DateFormat.Hm(Localizations.localeOf(context).toString())
          .format(local);
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes} min';
    }
    if (diff.inDays < 1 && now.day == local.day) {
      return DateFormat.Hm(Localizations.localeOf(context).toString())
          .format(local);
    }
    if (diff.inDays < 7) {
      return DateFormat.EEEE(Localizations.localeOf(context).toString())
          .add_Hm()
          .format(local);
    }
    return DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(local);
  }
}

class _MessageQuote extends StatelessWidget {
  final String message;
  final Brightness brightness;

  const _MessageQuote({required this.message, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      decoration: BoxDecoration(
        color: AppColors.dsBgInset(brightness),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: AppColors.dsBorder(brightness),
            width: 2,
          ),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic,
          color: AppColors.dsText2(brightness),
          height: 1.35,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  final String label;
  const _NewBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: scheme.onPrimary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

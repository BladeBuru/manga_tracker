import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_avatar.dart';
import 'package:mangatracker/core/components/app_chip.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/authors/dto/author_details.dto.dart';
import 'package:mangatracker/features/authors/widgets/author_bio.dart';
import 'package:mangatracker/features/home/helpers/home_section_l10n.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// En-tête de la page auteur : portrait, noms, repères biographiques,
/// genres de prédilection et mini bio.
class AuthorHeader extends StatelessWidget {
  final AuthorDetailsDto author;

  const AuthorHeader({super.key, required this.author});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final facts = [
      if (author.birthday != null) l10n.authorBirthday(author.birthday!),
      if (author.birthplace != null) l10n.authorBirthplace(author.birthplace!),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppAvatar(
          url: author.imageUrl,
          fallback: author.name,
          size: AppAvatarSize.hero,
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          author.name,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (author.actualName != null && author.actualName != author.name)
          Text(
            author.actualName!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.dsText2(brightness),
            ),
          ),
        if (author.associatedNames.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              l10n.authorOtherNames(author.associatedNames.join(', ')),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.dsText3(brightness),
              ),
            ),
          ),
        if (facts.isNotEmpty || author.genres.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.m),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final fact in facts)
                AppChip(label: fact, icon: Icons.info_outline_rounded),
              for (final genre in author.genres)
                AppChip.outlined(label: HomeSectionL10n.genre(l10n, genre)),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.m),
        AuthorBio(bio: author.bio),
        if (author.officialSite != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s),
            child: FilledButton.tonalIcon(
              onPressed:
                  () => launchUrl(
                    Uri.parse(author.officialSite!),
                    mode: LaunchMode.externalApplication,
                  ),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(l10n.authorOfficialSite),
            ),
          ),
      ],
    );
  }
}

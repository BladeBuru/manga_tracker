import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/app_chip.dart';
import 'package:mangatracker/core/components/offline_banner.dart';
import 'package:mangatracker/core/components/session_rejected_banner.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/home/bloc/home_section_page_state.dart';
import 'package:mangatracker/features/home/dto/home_section_kind.dart';
import 'package:mangatracker/features/home/helpers/home_section_l10n.dart';
import 'package:mangatracker/features/home/widgets/home_section_header.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// En-tete de la page « Tout voir » : meme composant que sur l'accueil
/// (icone + titre), avec le total de titres a droite, puis les bandeaux
/// d'etat (hors ligne / session rejetee — invitation, jamais redirection).
class HomeSectionPageHeader extends StatelessWidget {
  final String title;
  final HomeSectionKind? kind;
  final HomeSectionPageState state;

  const HomeSectionPageHeader({
    super.key,
    required this.title,
    required this.kind,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = state;
    final total = current is HomeSectionPageLoaded
        ? (current.total > 0 ? current.total : current.items.length)
        : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          icon: HomeSectionL10n.icon(kind),
          tileColor: HomeSectionL10n.tileColor(kind),
          title: title,
          trailing: total > 0
              ? AppChip.primary(label: l10n.homeSectionTitlesCount(total))
              : null,
        ),
        if (current.requiresReauth)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s + AppSpacing.xs),
            child: SessionRejectedBanner(
              onReconnect: () => context.push('/login'),
            ),
          )
        else if (current.isOffline)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.s + AppSpacing.xs),
            child: OfflineBanner(),
          ),
      ],
    );
  }
}

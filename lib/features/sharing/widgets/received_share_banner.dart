import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/core/theme/app_surfaces.dart';
import 'package:mangatracker/features/sharing/dto/share.dto.dart';
import 'package:mangatracker/features/sharing/services/sharing.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Qui m'a recommandé ce titre, et avec quel message. Pur, testé seul.
class ReceivedSharesSummary {
  /// Expéditeurs distincts, du plus récent au plus ancien.
  final List<String> senders;

  /// Message le plus récent joint à une recommandation, s'il y en a un.
  final String? message;

  const ReceivedSharesSummary({required this.senders, this.message});

  /// `null` si personne n'a recommandé [muId].
  static ReceivedSharesSummary? forManga(List<MangaShareDto> inbox, int muId) {
    final shares = inbox.where((s) => s.mangaMuId == '$muId').toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (shares.isEmpty) return null;
    final seen = <int>{};
    final senders = <String>[
      for (final s in shares)
        if (seen.add(s.senderId)) s.senderName,
    ];
    final message =
        shares.map((s) => s.trimmedMessage).whereType<String>().firstOrNull;
    return ReceivedSharesSummary(senders: senders, message: message);
  }
}

/// Bandeau de la fiche : « Recommandé par Léa : « message » ».
///
/// Avant, une recommandation reçue n'apparaissait que dans « Recommandations
/// reçues » : sur la fiche, rien ne disait qu'un ami l'avait conseillée.
/// Données : la boîte de réception gardée en mémoire par `SharingService`
/// (interrogée toutes les 60 s) — pas d'appel à chaque ouverture. Invisible
/// si personne ne l'a recommandé ou en cas d'échec.
class ReceivedShareBanner extends StatefulWidget {
  final int muId;

  /// Injectable pour les tests.
  final Future<List<MangaShareDto>> Function()? loadInbox;

  const ReceivedShareBanner({super.key, required this.muId, this.loadInbox});

  @override
  State<ReceivedShareBanner> createState() => _ReceivedShareBannerState();
}

class _ReceivedShareBannerState extends State<ReceivedShareBanner> {
  late final Future<ReceivedSharesSummary?> _summary = _load();

  Future<ReceivedSharesSummary?> _load() async {
    if (widget.muId <= 0) return null;
    try {
      final inbox = await (widget.loadInbox?.call() ??
          getIt<SharingService>().getInboxCached());
      return ReceivedSharesSummary.forManga(inbox, widget.muId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReceivedSharesSummary?>(
      future: _summary,
      builder: (context, snapshot) {
        final summary = snapshot.data;
        if (summary == null) return const SizedBox.shrink();
        return _BannerCard(summary: summary);
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  final ReceivedSharesSummary summary;
  const _BannerCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final first = summary.senders.first;
    final others = summary.senders.length - 1;
    final title = others > 0
        ? l10n.receivedShareByMany(first, others)
        : l10n.receivedShareBy(first);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.s,
        AppSpacing.m,
        AppSpacing.s,
      ),
      child: Material(
        color: AppSurfaces.muted(scheme),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circularXxxl,
          side: BorderSide(color: AppSurfaces.hairline(scheme)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/inbox'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s + AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.recommend_outlined, color: scheme.primary),
                const SizedBox(width: AppSpacing.s + AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (summary.message != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            l10n.receivedShareMessage(summary.message!),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/recommendations/services/recommendation_tip_store.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Astuce d'usage montrée **une seule fois**, en tête de la page « Toutes les
/// recommandations » : elle apprend le geste « pas intéressé ».
///
/// Pourquoi elle existe : le geste de rejet est un appui long, sans le
/// moindre indice visuel. Résultat mesuré en production, zéro rejet depuis la
/// mise en service — la seule information négative que le produit sache
/// capter était inaccessible. L'astuce ne remplace pas le geste, elle le
/// rend découvrable.
///
/// Pourquoi ici et pas sur l'accueil : le carrousel de l'accueil doit rester
/// dense et sans surcharge, alors que cette page est un contexte délibéré —
/// l'utilisateur y est venu pour parcourir ses recommandations.
///
/// Le widget gère lui-même son « une seule fois » : la page hôte n'a qu'à
/// l'insérer, sans état ni condition à porter.
class DismissRecommendationTip extends StatefulWidget {
  /// Injectable pour les tests ; en production, la persistance locale.
  final RecommendationTipStore store;

  const DismissRecommendationTip({
    super.key,
    this.store = const RecommendationTipStore(),
  });

  @override
  State<DismissRecommendationTip> createState() =>
      _DismissRecommendationTipState();
}

class _DismissRecommendationTipState extends State<DismissRecommendationTip> {
  /// `null` tant que la préférence n'est pas lue : on n'affiche rien, pour ne
  /// pas faire clignoter l'astuce chez quelqu'un qui l'a déjà vue.
  bool? _visible;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final seen = await widget.store.hasSeenDismissTip();
    if (!mounted) return;
    setState(() => _visible = !seen);
    // Marquée dès l'affichage, et pas seulement sur « Compris » : une astuce
    // vue puis quittée par le bouton retour a rempli son rôle. La consigne
    // est « une seule fois », pas « jusqu'à ce qu'on l'acquitte ».
    if (!seen) await widget.store.markDismissTipSeen();
  }

  void _hide() => setState(() => _visible = false);

  @override
  Widget build(BuildContext context) {
    if (_visible != true) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s + 4,
          AppSpacing.s + 4,
          AppSpacing.s + 4,
          0,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.xxxl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TipHeader(l10n: l10n),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n?.recommendationsTipBody ??
                    'Appuie longuement sur une carte, ou touche le bouton en '
                        'haut à droite, pour ne plus le voir dans tes '
                        'recommandations.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer
                          .withValues(alpha: 0.85),
                    ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _hide,
                  child: Text(l10n?.recommendationsTipAction ?? 'Compris'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icône + titre de l'astuce. Icône Material outlined, jamais d'émoji.
class _TipHeader extends StatelessWidget {
  final AppLocalizations? l10n;

  const _TipHeader({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          Icons.touch_app_outlined,
          size: 22,
          color: scheme.onSecondaryContainer,
        ),
        const SizedBox(width: AppSpacing.s + AppSpacing.xs),
        Expanded(
          child: Text(
            l10n?.recommendationsTipTitle ?? 'Un titre qui ne t’intéresse pas ?',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSecondaryContainer,
                ),
          ),
        ),
      ],
    );
  }
}

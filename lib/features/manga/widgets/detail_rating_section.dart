import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/manga/bloc/detail_bloc.dart';
import 'package:mangatracker/features/manga/bloc/detail_event.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  V1 « Refined Classic » — Section rating (votre note + communauté).   ║
// ║  Container hairline 14px padding, radius 14.                          ║
// ║  Gauche : 5 étoiles tappables (animate scale 1.15 sur tap).            ║
// ║  Droite : note numérique (XX/10) bold + label "Votre note".            ║
// ║  Si communautaire fournie : ligne séparée avec moyenne + "X votes".    ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// Section de notation V1 affichée dans la fiche détail (manga en bibliothèque).
///
/// - Tap sur une étoile → dispatche `UpdateUserRating(muId, rating)`.
/// - Affiche la note utilisateur (en gros) à droite.
/// - Si [communityRating] ou [communityRatingCount] est non vide → seconde
///   ligne avec la moyenne communautaire et le nombre de votes.
class DetailRatingSection extends StatelessWidget {
  final int muId;
  final int userRating; // 0-10, 0 = pas noté
  final double? communityRating;
  final int communityRatingCount;

  const DetailRatingSection({
    super.key,
    required this.muId,
    required this.userRating,
    this.communityRating,
    this.communityRatingCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = brightness == Brightness.dark;
    final showCommunity =
        communityRating != null && communityRatingCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.xs,
        AppSpacing.m,
        AppSpacing.s,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.dsSurfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.dsHairline(brightness),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.yourRating.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.63,
                          color: AppColors.dsText3(brightness),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _AnimatedStarsRow(
                        rating: userRating,
                        onChanged: (newRating) {
                          context.read<DetailBloc>().add(
                                UpdateUserRating(muId, newRating),
                              );
                        },
                      ),
                    ],
                  ),
                ),
                _RatingNumeric(
                  rating: userRating,
                  scheme: scheme,
                  brightness: brightness,
                ),
              ],
            ),
            if (showCommunity) ...[
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: AppColors.dsHairline(brightness),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 16,
                    color: AppColors.dsText2(brightness),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.votesCount(communityRatingCount),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.dsText2(brightness),
                      ),
                    ),
                  ),
                  Text(
                    communityRating!.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  Text(
                    '/10',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.dsText3(brightness),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RatingNumeric extends StatelessWidget {
  final int rating;
  final ColorScheme scheme;
  final Brightness brightness;

  const _RatingNumeric({
    required this.rating,
    required this.scheme,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    if (rating == 0) {
      return Text(
        '—',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.dsText3(brightness),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$rating',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: scheme.primary,
            height: 1,
          ),
        ),
        Text(
          '/10',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.dsText3(brightness),
          ),
        ),
      ],
    );
  }
}

class _AnimatedStarsRow extends StatefulWidget {
  final int rating; // 0-10
  final ValueChanged<int> onChanged;

  const _AnimatedStarsRow({
    required this.rating,
    required this.onChanged,
  });

  @override
  State<_AnimatedStarsRow> createState() => _AnimatedStarsRowState();
}

class _AnimatedStarsRowState extends State<_AnimatedStarsRow> {
  int? _animatingIndex;

  void _handleTap(int starIndex) {
    final tapped = starIndex * 2;
    final newRating = widget.rating == tapped ? 0 : tapped;
    setState(() => _animatingIndex = starIndex);
    widget.onChanged(newRating);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _animatingIndex = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final inactiveColor = AppColors.dsText3(brightness);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 5; i++)
          GestureDetector(
            onTap: () => _handleTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedScale(
              scale: _animatingIndex == i ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _StarIcon(
                  filled: widget.rating >= i * 2,
                  halfFilled: widget.rating == i * 2 - 1,
                  active: scheme.primary,
                  inactive: inactiveColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StarIcon extends StatelessWidget {
  final bool filled;
  final bool halfFilled;
  final Color active;
  final Color inactive;

  const _StarIcon({
    required this.filled,
    required this.halfFilled,
    required this.active,
    required this.inactive,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    if (filled) {
      icon = Icons.star_rounded;
      color = active;
    } else if (halfFilled) {
      icon = Icons.star_half_rounded;
      color = active;
    } else {
      icon = Icons.star_outline_rounded;
      color = inactive;
    }
    return Icon(icon, size: 28, color: color);
  }
}

import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_card.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Mini bio repliable : 4 lignes, puis « Lire la suite ».
class AuthorBio extends StatefulWidget {
  final String? bio;

  const AuthorBio({super.key, required this.bio});

  @override
  State<AuthorBio> createState() => _AuthorBioState();
}

class _AuthorBioState extends State<AuthorBio> {
  static const int _collapsedLines = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bio = widget.bio;
    if (bio == null) {
      return Text(
        l10n.authorNoBio,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.dsText3(theme.brightness),
        ),
      );
    }
    final long = bio.length > 220 || '\n'.allMatches(bio).length >= 3;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bio,
            maxLines: _expanded || !long ? null : _collapsedLines,
            overflow: _expanded || !long ? null : TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          if (long)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? l10n.authorBioLess : l10n.authorBioMore,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

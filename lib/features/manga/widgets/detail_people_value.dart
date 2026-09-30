import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/manga/dto/author.dto.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Noms d'auteurs / dessinateurs de la fiche, chacun cliquable quand
/// MangaUpdates lui connaît une fiche (`authorId > 0`) : l'appui ouvre la
/// page de la personne (mini bio + œuvres).
class DetailPeopleValue extends StatelessWidget {
  final List<AuthorDto> people;
  final ValueChanged<AuthorDto>? onPersonTap;

  const DetailPeopleValue({super.key, required this.people, this.onPersonTap});

  static bool isLinkable(AuthorDto person) => (person.authorId ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    if (people.isEmpty) {
      return Text('—', style: _style(AppColors.dsText3(brightness)));
    }
    return Wrap(
      children: [
        for (var i = 0; i < people.length; i++)
          _PersonName(
            person: people[i],
            trailing: i < people.length - 1 ? ', ' : '',
            color: scheme.onSurface,
            linkColor: scheme.primary,
            onTap:
                onPersonTap != null && isLinkable(people[i])
                    ? () => onPersonTap!(people[i])
                    : null,
          ),
      ],
    );
  }
}

TextStyle _style(Color color, {bool link = false}) => TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.15,
  height: 1.2,
  color: color,
  decoration: link ? TextDecoration.underline : null,
  decorationColor: color.withValues(alpha: 0.4),
);

class _PersonName extends StatelessWidget {
  final AuthorDto person;
  final String trailing;
  final Color color;
  final Color linkColor;
  final VoidCallback? onTap;

  const _PersonName({
    required this.person,
    required this.trailing,
    required this.color,
    required this.linkColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: person.name,
            style: _style(
              onTap != null ? linkColor : color,
              link: onTap != null,
            ),
          ),
          TextSpan(text: trailing, style: _style(color)),
        ],
      ),
    );
    if (onTap == null) return text;
    return Semantics(
      button: true,
      label: AppLocalizations.of(context)!.authorOpenAccessibility(person.name),
      excludeSemantics: true,
      child: InkWell(onTap: onTap, child: text),
    );
  }
}

import 'dart:convert';

import 'package:mangatracker/core/router/route_extras.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/dto/home_section_kind.dart';

/// Sérialise les extras de navigation dans l'état de l'historique.
///
/// Sans codec, go_router remplace tout extra non JSON par `null` quand une
/// entrée est restaurée (retour / avance du navigateur) : le titre et la
/// couverture pré-remplis disparaissaient. Seuls des types primitifs sont
/// produits (l'état passe par `history.pushState`).
///
/// Volontairement **non** sérialisés (→ `null`, la page recharge) :
/// [ReaderWebExtras] (contient un rappel), `UserInformationDto` (avatar en
/// data URL jusqu'à 300 ko — trop lourd pour l'historique), et tout type
/// inconnu.
class RouteExtrasCodec extends Codec<Object?, Object?> {
  const RouteExtrasCodec();

  @override
  Converter<Object?, Object?> get encoder => const _ExtrasEncoder();

  @override
  Converter<Object?, Object?> get decoder => const _ExtrasDecoder();
}

const String _typeKey = 't';

/// Au-delà, une URL d'avatar (souvent une data URL) n'est pas conservée.
const int _maxAvatarLength = 2048;

class _ExtrasEncoder extends Converter<Object?, Object?> {
  const _ExtrasEncoder();

  @override
  Object? convert(Object? input) => switch (input) {
        MangaDetailExtras(:final title, :final coverPath) => {
            _typeKey: 'manga',
            'title': title,
            'cover': coverPath,
          },
        HomeSectionExtras(:final kind, :final params) => {
            _typeKey: 'section',
            'kind': kind.wireValue,
            'params': params.toJson(),
          },
        AuthorPageExtras(:final name) => {_typeKey: 'author', 'name': name},
        FriendProfileExtras(:final displayName, :final avatarUrl) => {
            _typeKey: 'friend',
            'name': displayName,
            'avatar': _lightAvatar(avatarUrl),
          },
        OfflineReaderExtras(:final mangaTitle) => {
            _typeKey: 'offline',
            'title': mangaTitle,
          },
        _ => null,
      };

  static String? _lightAvatar(String? url) {
    if (url == null || url.startsWith('data:')) return null;
    return url.length > _maxAvatarLength ? null : url;
  }
}

class _ExtrasDecoder extends Converter<Object?, Object?> {
  const _ExtrasDecoder();

  @override
  Object? convert(Object? input) {
    if (input is! Map) return null;
    String? text(String key) {
      final value = input[key];
      return value is String ? value : null;
    }

    switch (input[_typeKey]) {
      case 'manga':
        return MangaDetailExtras(title: text('title'), coverPath: text('cover'));
      case 'section':
        final kind = HomeSectionKind.tryParse(input['kind']);
        if (kind == null) return null;
        final params = input['params'];
        return HomeSectionExtras(
          kind: kind,
          params: params is Map
              ? HomeSectionParams.fromJson(Map<String, dynamic>.from(params))
              : HomeSectionParams.none,
        );
      case 'author':
        final name = text('name');
        return name == null ? null : AuthorPageExtras(name: name);
      case 'friend':
        final name = text('name');
        if (name == null) return null;
        return FriendProfileExtras(displayName: name, avatarUrl: text('avatar'));
      case 'offline':
        final title = text('title');
        return title == null ? null : OfflineReaderExtras(mangaTitle: title);
    }
    return null;
  }
}

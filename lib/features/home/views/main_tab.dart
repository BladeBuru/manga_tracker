import 'package:flutter/widgets.dart';

/// Onglets de la barre du bas — chacun a son URL (`/home`, `/library`,
/// `/search`, `/profile`) : F5 et le bouton retour du navigateur restent
/// sur l'onglet affiché. L'ordre est celui des branches du
/// `StatefulShellRoute` (`main_shell_route.dart`).
enum MainTab {
  home('/home'),
  library('/library'),
  search('/search'),
  profile('/profile');

  const MainTab(this.path);

  final String path;
}

/// Ce que la coque des onglets partage avec les pages d'onglet.
///
/// Les pages sont construites par le routeur (une branche par onglet), plus
/// par la barre elle-même : ce qui leur était passé en paramètre transite
/// par ce widget hérité.
class MainShellScope extends InheritedWidget {
  /// Demande au profil d'amener l'utilisateur à ce qui l'attend (pastille
  /// de l'onglet « Mon compte »).
  final ValueNotifier<int> profileFocusRequests;

  const MainShellScope({
    super.key,
    required this.profileFocusRequests,
    required super.child,
  });

  static ValueNotifier<int>? profileFocusRequestsOf(BuildContext context) =>
      context
          .getInheritedWidgetOfExactType<MainShellScope>()
          ?.profileFocusRequests;

  @override
  bool updateShouldNotify(MainShellScope oldWidget) =>
      oldWidget.profileFocusRequests != profileFocusRequests;
}

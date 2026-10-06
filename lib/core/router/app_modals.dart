import 'package:flutter/material.dart';

/// Ouverture des fenêtres modales (dialogues, feuilles du bas, sélecteur de
/// date) — **seul** point d'entrée de l'application.
///
/// Problème corrigé : deux appuis rapides sur un bouton ouvraient deux fois la
/// même fenêtre, l'une sur l'autre (surtout quand le bouton attend une donnée
/// avant d'ouvrir : les deux appuis passent l'attente, puis ouvrent chacun la
/// leur). Règle : si une fenêtre ouverte par ces fonctions il y a moins de
/// [duplicateWindow] est au premier plan, et que l'appel vient de la page
/// qu'elle recouvre (et non de la fenêtre elle-même), c'est un doublon → il
/// est ignoré et renvoie `null`.
///
/// Restent permis : une fenêtre ouverte depuis une autre fenêtre (feuille →
/// sélecteur), une fenêtre ouverte juste après la fermeture de la précédente,
/// et une fenêtre ouverte délibérément par-dessus une autre après le délai.
///
/// Les feuilles du bas évitent aussi par défaut les zones système (encoche,
/// barre de navigation à boutons) : contenu jamais caché dessous.
///
/// Verrouillé par `test/core/router/app_modals_test.dart` (comportement) et
/// par un fil de détente qui interdit `showDialog` / `showModalBottomSheet` /
/// `showDatePicker` en direct ailleurs dans `lib/`.
const Duration duplicateWindow = Duration(milliseconds: 1200);

Route<dynamic>? _lastOpened;
DateTime? _lastOpenedAt;

/// Route au premier plan du navigateur (sans rien retirer).
Route<dynamic>? _topRoute(NavigatorState navigator) {
  Route<dynamic>? top;
  navigator.popUntil((route) {
    top = route;
    return true;
  });
  return top;
}

/// `true` si l'appel serait un doublon d'une fenêtre tout juste ouverte.
@visibleForTesting
bool isDuplicateModalRequest(
  BuildContext context, {
  bool useRootNavigator = true,
}) {
  if (!context.mounted) return true;
  final navigator = Navigator.maybeOf(context, rootNavigator: useRootNavigator);
  final openedAt = _lastOpenedAt;
  if (navigator == null || openedAt == null) return false;
  final top = _topRoute(navigator);
  if (top is! PopupRoute) return false;
  // Ouverte depuis la fenêtre au premier plan elle-même : légitime.
  if (identical(top, ModalRoute.of(context))) return false;
  return identical(top, _lastOpened) &&
      DateTime.now().difference(openedAt) < duplicateWindow;
}

Future<T?> _openOnce<T>(
  BuildContext context,
  bool useRootNavigator,
  Future<T?> Function() open,
) {
  if (isDuplicateModalRequest(context, useRootNavigator: useRootNavigator)) {
    return Future<T?>.value();
  }
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final result = open();
  // L'ouverture est synchrone : la nouvelle route est déjà au premier plan.
  _lastOpened = _topRoute(navigator);
  _lastOpenedAt = DateTime.now();
  return result;
}

/// Équivalent de [showDialog], protégé contre les doubles appuis.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  return _openOnce<T>(
    context,
    useRootNavigator,
    () => showDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
    ),
  );
}

/// Équivalent de [showModalBottomSheet], protégé contre les doubles appuis.
///
/// Différence voulue : le contenu évite la barre de navigation du système
/// (boutons retour / accueil) et l'encoche — [useSafeArea] vaut `true` et le
/// bas est protégé même quand la feuille ne le fait pas elle-même.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  String? barrierLabel,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = true,
  RouteSettings? routeSettings,
}) {
  return _openOnce<T>(
    context,
    useRootNavigator,
    () => showModalBottomSheet<T>(
      context: context,
      builder: (sheetContext) =>
          SafeArea(top: false, child: builder(sheetContext)),
      backgroundColor: backgroundColor,
      barrierLabel: barrierLabel,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      barrierColor: barrierColor,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      useSafeArea: useSafeArea,
      routeSettings: routeSettings,
    ),
  );
}

/// Équivalent de [showDatePicker], protégé contre les doubles appuis.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? initialDate,
  Locale? locale,
  String? helpText,
  String? cancelText,
  String? confirmText,
  DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
  TransitionBuilder? builder,
}) {
  return _openOnce<DateTime>(
    context,
    true,
    () => showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: initialDate,
      locale: locale,
      helpText: helpText,
      cancelText: cancelText,
      confirmText: confirmText,
      initialEntryMode: initialEntryMode,
      builder: builder,
    ),
  );
}

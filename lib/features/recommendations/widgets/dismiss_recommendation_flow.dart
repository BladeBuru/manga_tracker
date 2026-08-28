import 'package:flutter/material.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/recommendations/services/recommendation_dismissal.service.dart';
import 'package:mangatracker/features/recommendations/widgets/dismiss_recommendation_sheet.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Enchaînement complet du rejet d'une recommandation : feuille modale →
/// appel API → SnackBar de confirmation avec annulation immédiate.
///
/// Retourne `true` si le titre a bien été écarté — l'appelant peut alors le
/// retirer de sa liste. Retourne `false` si l'utilisateur a annulé la
/// feuille ou si l'appel a échoué (le titre reste affiché : mieux vaut ça
/// qu'une carte qui disparaît alors que le serveur n'a rien enregistré).
///
/// L'annulation est proposée dans le SnackBar plutôt que reléguée aux
/// réglages : un rejet accidentel doit être réversible sur-le-champ, sans
/// rien avoir à chercher.
Future<bool> runDismissRecommendationFlow(
  BuildContext context, {
  required num muId,
  required String mangaTitle,
  required VoidCallback onRestored,
}) async {
  final reason = await showDismissRecommendationSheet(
    context,
    mangaTitle: mangaTitle,
  );
  if (reason == null || !context.mounted) return false;

  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final service = getIt<RecommendationDismissalService>();

  try {
    await service.dismiss(muId, reason);
  } on SocketException {
    _show(messenger, l10n?.dismissRecommendationOffline ?? 'Indisponible hors ligne.');
    return false;
  } catch (_) {
    _show(
      messenger,
      l10n?.dismissRecommendationError ??
          'Impossible d’écarter ce titre pour le moment. Réessaie plus tard.',
    );
    return false;
  }

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          l10n?.dismissRecommendationSuccess(mangaTitle) ??
              '« $mangaTitle » n’apparaîtra plus dans tes recommandations',
        ),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: l10n?.dismissRecommendationUndo ?? 'Annuler',
          onPressed: () => _restore(
            messenger: messenger,
            service: service,
            muId: muId,
            l10n: l10n,
            onRestored: onRestored,
          ),
        ),
      ),
    );

  return true;
}

/// Annulation du rejet. Un 404 signifie que le rejet n'existe déjà plus :
/// le résultat voulu est atteint, on le traite comme un succès.
Future<void> _restore({
  required ScaffoldMessengerState messenger,
  required RecommendationDismissalService service,
  required num muId,
  required AppLocalizations? l10n,
  required VoidCallback onRestored,
}) async {
  try {
    await service.restore(muId);
  } on DismissalException catch (e) {
    if (e.failure != DismissalFailure.notFound) {
      _show(
        messenger,
        l10n?.dismissRecommendationError ??
            'Impossible d’écarter ce titre pour le moment. Réessaie plus tard.',
      );
      return;
    }
  } on SocketException {
    _show(
      messenger,
      l10n?.dismissRecommendationOffline ?? 'Indisponible hors ligne.',
    );
    return;
  } catch (_) {
    _show(
      messenger,
      l10n?.dismissRecommendationError ??
          'Impossible d’écarter ce titre pour le moment. Réessaie plus tard.',
    );
    return;
  }

  onRestored();
  _show(messenger, l10n?.dismissRecommendationUndone ?? 'Recommandation rétablie');
}

void _show(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/manga/services/notification_payload.dart';

void main() {
  test('demande d\'ami → Mes amis, onglet Demandes', () {
    expect(
      NotificationPayload.routeFor(NotificationPayload.friendRequest),
      '/friends?tab=pending',
    );
  });

  test('recommandation reçue → Recommandations reçues', () {
    expect(
      NotificationPayload.routeFor(NotificationPayload.share('42')),
      '/inbox',
    );
  });

  test('nouveaux chapitres (et anciennes notifications) → fiche du titre', () {
    expect(
      NotificationPayload.routeFor(NotificationPayload.chapter('42')),
      '/manga/42',
    );
    expect(NotificationPayload.routeFor('42'), '/manga/42');
  });

  test('contenu inconnu ou vide → rien', () {
    expect(NotificationPayload.routeFor(null), isNull);
    expect(NotificationPayload.routeFor(''), isNull);
    expect(NotificationPayload.routeFor('0'), isNull);
    expect(NotificationPayload.routeFor('n\'importe quoi'), isNull);
  });
}

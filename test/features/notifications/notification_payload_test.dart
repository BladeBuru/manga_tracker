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

  test('demande acceptée → profil de l\'ami ; lecture partagée → le groupe ; '
      'centre → /notifications', () {
    expect(NotificationPayload.routeFor(NotificationPayload.friend('42')),
        '/friends/42');
    expect(NotificationPayload.routeFor(NotificationPayload.readingGroup('5')),
        '/reading-groups/5');
    expect(NotificationPayload.routeFor(NotificationPayload.centre),
        '/notifications');
    expect(NotificationPayload.routeFor('friend:abc'), '/friends');
    expect(NotificationPayload.routeFor('group:'), '/reading-groups');
  });

  test('contenu inconnu ou vide → rien', () {
    expect(NotificationPayload.routeFor(null), isNull);
    expect(NotificationPayload.routeFor(''), isNull);
    expect(NotificationPayload.routeFor('0'), isNull);
    expect(NotificationPayload.routeFor('n\'importe quoi'), isNull);
  });
}

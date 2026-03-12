# Nouvelles fonctionnalités de téléchargement et de traduction

Cette PR ajoute plusieurs fonctionnalités importantes pour améliorer votre expérience de lecture.

<!-- CHANGELOG:START -->
### Ajouts
- Vous pouvez maintenant télécharger des chapitres pour les lire hors ligne
- Les chapitres téléchargés sont accessibles depuis une page dédiée dans les téléchargements
- Un bloqueur de publicités intégré bloque automatiquement les publicités pendant la lecture
- Vous pouvez bloquer manuellement des éléments indésirables pendant la lecture
- Les descriptions de mangas sont automatiquement traduites dans votre langue préférée
- Les notes de mise à jour sont traduites automatiquement dans votre langue
- L'application sauvegarde automatiquement votre position de lecture dans chaque chapitre pour reprendre où vous vous êtes arrêté
- Vous pouvez personnaliser les sélecteurs de chapitres selon vos préférences
- Des liens vers notre serveur Discord ont été ajoutés dans les paramètres
<!-- CHANGELOG:END -->

## Détails techniques (pour les développeurs)

Cette section contient des détails techniques pour les développeurs et ne sera pas affichée aux utilisateurs.

### Traduction automatique
- Implémentation d'un service de traduction avec support de Google Translate, LibreTranslate et MyMemory
- Cache par version pour les changelogs afin d'éviter les retraductions inutiles
- Détection automatique de la langue source
- Traduction progressive des changelogs avec mise à jour en temps réel

### Suivi de progression
- Sauvegarde automatique de la position de scroll dans SharedPreferences
- Restauration automatique de la position lors de la réouverture d'un chapitre
- Détection intelligente de la fin de chapitre (dans les 15% de la fin)
- Helper partagé (`ReadingProgressHelper`) pour éviter la duplication de code

### Mode hors ligne
- Blocage complet des requêtes réseau non-file:// dans `OfflineReaderView`
- Nettoyage HTML pour supprimer les références externes avant chargement
- Gestion correcte du meta viewport pour éviter les problèmes de zoom
- CSS responsive injecté pour un meilleur affichage

### Services en arrière-plan
- `ChapterCheckService` optimisé avec timeouts réduits
- Vérification des nouveaux chapitres déplacée en arrière-plan après le chargement de l'UI
- Timer de gestion pour annuler les vérifications si l'utilisateur navigue ailleurs

### Composants réutilisables
- Création de `ChangelogDialog` pour éviter la duplication de code entre `startup_page.dart` et `changelog_card.dart`
- Refactorisation de la logique de traduction dans un composant centralisé

### Améliorations de code
- Suppression de tous les logs de debug
- Simplification de la détection de langue (remplacement des regex complexes par des Sets)
- Nettoyage du code et amélioration de la maintenabilité

# VERSIONNING — reader

| Version | Date | Artefact/Composant | Changement | Auteur |
|---------|------|--------------------|------------|--------|
| 0.1.0 | 2026-06-04 | Module complet | Documentation initiale (rétro-ingénierie) | Rétro |
| 0.2.0 | 2026-06-19 | `web_view_io.dart`, `offline_reader_view_io.dart` | Ajout `recordChapterLog` fire-and-forget (journal lecture stats v2) | Sprint responsive/social/stats-v2 |
| 0.3.0 | 2026-09-04 | `challenge_allowlist.dart`, `challenge_loop_detector.dart`, `web_view_user_agent.dart`, `reader_web_view_settings.dart`, `challenge_escape_dialog.dart`, `reader_action_bar.dart` | Correctif boucle Cloudflare : liste blanche vérifications anti-robot, détecteur de boucle + porte de sortie, user-agent honnête, barre d'actions 2 niveaux, script JS arrêtable | fix/reader-cloudflare |
| 0.4.0 | 2026-09-05 | `reader_navigation_policy.dart` (nouveau), `reader_web_view_settings.dart`, `web_view_io.dart`, `reader_action_bar.dart` ; suppression `web_view_user_agent.dart` | Fix régression v0.13.0 : `controller.setSettings(...)` post-chargement rendait `shouldOverrideUrlLoading` inopérant sur Android. Retour à `initialUrlRequest` + `initialSettings` ; politique de navigation extraite dans `ReaderNavigationPolicy` ; UA plateforme restauré ; interrupteur `Switch` bloqueur rétabli | fix/reader-redirect-regression |

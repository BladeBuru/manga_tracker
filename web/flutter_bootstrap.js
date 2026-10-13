{{flutter_js}}
{{flutter_build_config}}

// Démarrage SANS service worker (pas de `serviceWorkerSettings`) : chaque
// chargement récupère la version déployée. L'ancien service worker « hors
// ligne d'abord » servait une version périmée de l'application depuis son
// cache jusqu'à l'effacement manuel des données du site — cf.
// deploy/web/README.md (« Cache et service worker »).
_flutter.loader.load();

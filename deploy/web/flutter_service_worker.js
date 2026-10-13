// Interrupteur d'arrêt — remplace l'ancien service worker Flutter
// (« hors ligne d'abord », versions web ≤ 0.18).
//
// L'application ne s'inscrit plus comme service worker (cf.
// web/flutter_bootstrap.js). Mais un navigateur qui a gardé l'ancien
// continue de servir l'application depuis son cache. Lors de sa vérification
// de mise à jour, il télécharge ce fichier (servi sans cache par nginx) : ce
// script s'active aussitôt, vide tous les caches, se désinscrit et recharge
// les onglets ouverts — qui repartent alors du réseau, à jour.
//
// Copié par-dessus le fichier vide que génère `flutter build web
// --pwa-strategy=none` (cf. deploy/web/Dockerfile). Pas de gestionnaire
// `fetch` : rien n'est intercepté.

self.addEventListener('install', function () {
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil(
    (async function () {
      try {
        const keys = await caches.keys();
        await Promise.all(keys.map(function (key) { return caches.delete(key); }));
      } catch (_) {}
      try {
        await self.clients.claim();
      } catch (_) {}
      await self.registration.unregister();
      const windows = await self.clients.matchAll({ type: 'window' });
      windows.forEach(function (client) {
        if (typeof client.navigate !== 'function') return;
        client.navigate(client.url).catch(function () {});
      });
    })()
  );
});

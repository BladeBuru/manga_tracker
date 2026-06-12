# RETRO-013 — Queue offline pour les mutations de la bibliothèque

| Champ      | Valeur              |
|------------|---------------------|
| Statut     | Documenté (rétro)   |
| Date       | 2026-06-04          |
| Source     | Rétro-ingénierie    |
| Features   | library             |

## Justification (politique ADR v2.3.0)

| Champ | Valeur |
|-------|--------|
| Catégorie | DB-STRATEGY |
| Q1 — Coût de revert > 1j ? | OUI — supprimer la queue implique de modifier les 6 méthodes de mutation dans `LibraryService`, de retirer le type `OfflineAction` et ses 6 factories, de désactiver la logique de replay dans `SyncService`, et de changer le contrat de retour (les mutations retournent actuellement `true` même en mode queue) — refactoring transverse sur au minimum 3 services et le BLoC |
| Q2 — Non-déductible du code ? | OUI — `pubspec.yaml` et `shared_preferences` n'indiquent pas que les mutations retournent `true` quand elles sont queued plutôt qu'exécutées, ni que la queue est persistée entre sessions dans `shared_preferences` (clé `offline_queue`), ni que `SyncService` rejoue automatiquement à la reconnexion |
| Q3 — Impact transverse (≥ 2 specs) ? | OUI — impacte `library` (mutations BLoC), `manga/detail` (qui appelle aussi `LibraryService` pour add/remove/status depuis la fiche), et `core/sync` (`SyncService` qui consomme la queue) |
| Q4 — Casse un invariant si ignoré ? | OUI — sans cette décision, un dev pourrait lever une exception ou retourner `false` sur erreur réseau, ce qui détruirait silencieusement les actions de l'utilisateur hors ligne (ajouts, changements de statut, progression) sans qu'il soit averti |

> ✅ Validé contre la politique `.claude/rules/06-adr-policy.md`.

---

## Contexte

L'application cible un usage mobile avec une connectivité variable. La bibliothèque est le module le plus utilisé et ses mutations (ajouter, retirer, changer le statut, sauvegarder la progression) doivent fonctionner que l'utilisateur soit en ligne ou non. Une mutation perdue hors ligne (ex. : l'utilisateur marque un chapitre comme lu dans le métro) serait une régression fonctionnelle majeure.

---

## Décision identifiée

Toutes les mutations de la bibliothèque sauf la notation suivent ce pattern dans `LibraryService` :

```
if (isOnline) {
  try {
    appel API
    return résultat
  } catch {
    queueOfflineAction(...)
    return false   // échec réseau → en queue
  }
} else {
  queueOfflineAction(...)
  return true    // en queue = réussi du point de vue UI
}
```

Les `OfflineAction` sont persistées en JSON dans `shared_preferences` (clé `offline_queue`). `SyncService` écoute `ConnectivityService.connectivityStream` et rejoue la queue à la reconnexion.

La notation (`updateRating`) est explicitement exclue de ce pattern : elle retourne `false` hors ligne sans queuer — commentaire dans le code : "action non critique".

---

## Conséquences observées

### Positives

- L'utilisateur peut modifier sa bibliothèque hors ligne sans perte de données.
- Le BLoC traite les mutations comme réussies immédiatement, ce qui préserve la fluidité de l'UI.
- La queue est persistée entre les sessions — les actions survivent à un redémarrage de l'application.

### Négatives / Dette

- La valeur de retour `true` en mode queue peut tromper les appelants : un `true` ne signifie pas que l'API a répondu avec succès, mais que l'action a été mise en queue.
- Les mutations queued ne sont pas reflétées dans le cache local (`cached_library`) — après un ajout hors ligne, la liste affichée ne montre pas immédiatement le nouveau manga.
- La notation hors ligne est silencieusement abandonnée, sans message à l'utilisateur.
- `SyncService` rejoue la queue dans l'ordre FIFO, sans dédoublonnage — si l'utilisateur change le statut d'un manga 3 fois hors ligne, les 3 requêtes seront envoyées séquentiellement à la reconnexion.

---

## Recommandation

Garder. Le pattern est cohérent, testé implicitement à chaque usage hors ligne, et aligné avec la stratégie offline-first documentée dans `.claude/docs/offline-architecture.md`.

À reconsidérer si la dédoublonnage devient un problème de performance (ex. queue de centaines d'actions) : ajouter un mécanisme de compaction dans `SyncService` qui ne garde que la dernière action par `muId` + type.

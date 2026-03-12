# Problèmes Connus — Manga Tracker Flutter

**Dernière mise à jour :** Mars 2026

---

## 🐛 Problèmes Actifs

_(À compléter lors de la découverte de problèmes)_

---

## ✅ Problèmes Résolus

### Race conditions sur DetailBloc
- **Feature** : manga/detail
- **Résolu le** : 2025-11
- **Symptôme** : En naviguant rapidement entre plusieurs pages de détails, les états se mélangeaient entre les pages.
- **Solution** : `DetailBloc` enregistré en **factory** dans GetIt (une nouvelle instance par page), et non en singleton.

### Détection offline incorrecte (faux positifs)
- **Feature** : mode offline / tous les BLoCs
- **Résolu le** : 2025-11
- **Symptôme** : L'app passait en mode offline alors que la connexion était présente.
- **Solution** : Détection basée sur les **erreurs réseau** (`SocketException`) plutôt que sur l'état de `ConnectivityService`. La connectivité peut indiquer "connecté" sans accès internet réel.

### Perte silencieuse des actions offline
- **Feature** : library / offline queue
- **Résolu le** : 2025-11
- **Symptôme** : Les actions effectuées offline (ajout/suppression de manga) disparaissaient sans être synchronisées.
- **Solution** : Gestion explicite des échecs dans `SyncService` — conservation de l'action dans la queue pour un retry ultérieur.

### `readChaptersCount` incorrect après suppression
- **Feature** : manga/detail, library
- **Résolu le** : 2025-11
- **Symptôme** : Après suppression d'un manga de la bibliothèque, le compteur de chapitres lus affichait une valeur incorrecte.
- **Solution** : Reset explicite de `readChaptersCount` lors de la suppression.

---

## ⚠️ Workarounds Temporaires

_(À compléter)_

---

## 💡 Améliorations Identifiées

_(À compléter)_

---

## 📋 Format d'un problème

```
### [Titre court du problème]

- **Feature** : [auth | home | library | manga | profile | search | reader]
- **Sévérité** : [Critique | Haute | Moyenne | Basse]
- **Découvert le** : AAAA-MM-JJ
- **Statut** : [Actif | En cours | Résolu]

**Symptôme** : Ce que l'utilisateur observe.

**Reproduction** :
1. Étape 1
2. Étape 2

**Cause** : Explication technique.

**Solution / Workaround** : Ce qui a été fait ou ce qui est prévu.
```

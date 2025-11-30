

## 🚀 Workflow de publication automatique

Ce projet utilise un **système CI/CD automatisé** pour :

* 🆙 Gérer automatiquement les versions dans `pubspec.yaml`
* 📦 Générer l’APK de production (`prod`)
* 📝 Mettre à jour `version.json` avec le changelog et la version
* 🚀 Publier une release GitHub avec le changelog et l’APK attaché

Tout cela se déclenche **automatiquement lors du merge d'une PR**, mais **uniquement si on le souhaite**.

---

## ✅ Comment préparer une PR pour une release

Si votre PR **contient une nouvelle fonctionnalité, un correctif visible, ou une mise à jour pour les utilisateurs**, suivez ces étapes :

### 1. 🏷 Ajoutez un label de version :

* `patch` → petite correction ou amélioration mineure
* `minor` → ajout de fonctionnalités ou changement visible
* `major` → changement important ou rupture de compatibilité

📌 **Sans label, aucune release ne sera générée.**

### 2. 🧾 Rédigez un changelog dans la description de la PR :

**⚠️ IMPORTANT : Le changelog est destiné aux UTILISATEURS FINAUX, pas aux développeurs !**

Il doit être :
- **Simple et compréhensible** : Pas de jargon technique
- **Centré sur les bénéfices utilisateur** : Ce que l'utilisateur peut voir/faire de nouveau
- **Sans détails techniques** : Pas de noms de fichiers, de services, de configurations internes

Entourez les notes de publication entre les balises :

```
<!-- CHANGELOG:START -->
### ✨ Ajouts
- Vous pouvez maintenant choisir la langue de l'application dans les paramètres
- L'application charge plus rapidement les informations de profil

### 🐛 Corrections
- Correction du bug d'affichage sur la page d'accueil
- Les mises à jour s'installent maintenant correctement
<!-- CHANGELOG:END -->
```

Le contenu entre ces balises sera utilisé pour la **release GitHub** et pour mettre à jour automatiquement le fichier `version.json` qui sera affiché aux utilisateurs dans l'application.

---

## ❌ Que se passe-t-il si je ne mets **pas** de label ?

➡️ La PR sera mergée, mais **aucune release ne sera générée**, **l’APK ne sera pas mis à jour**, et **aucun bump de version ne sera appliqué**.

Cela est **normal et souhaité** dans les cas suivants :

* Modifications du pipeline CI
* Refactoring interne
* Ajout de tests
* Mise à jour de README, docs, etc.

---

## 📌 Exemple de bonne PR prête pour release

**Titre :** Nouvelles fonctionnalités de téléchargement et de traduction

**Labels :** `minor`

**Description de la PR :**

```
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
```

### ⚠️ Règles importantes pour le changelog

1. **Pas d'emojis** : Utilisez uniquement `### Ajouts`, `### Améliorations`, `### Corrections`
2. **Pas de numéros de build** : Les versions sont automatiquement gérées (ex: `0.7.1` et non `0.7.1+16`)
3. **Centré utilisateur** : Décrivez ce que l'utilisateur peut faire ou voir, pas comment c'est implémenté
4. **Langage simple** : Évitez le jargon technique, les noms de fichiers, de services ou de configurations
5. **Format cohérent** : Utilisez des phrases courtes commençant par un verbe à l'infinitif ou "Vous pouvez..."
6. **Pas de corrections internes** : Ne mentionnez que les corrections visibles par l'utilisateur final

---

## 👨‍💻 Et si j’oublie un label ?

Tu peux toujours :

* Éditer la PR avant merge pour ajouter un label
* Ou merge sans label → aucun impact côté utilisateur


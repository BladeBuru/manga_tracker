

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

**Titre :** Ajout du système de mises à jour automatiques

**Labels :** `minor`

**Description de la PR :**

```
Cette PR ajoute un système qui détecte la version actuelle et propose une mise à jour si une nouvelle version est disponible.

<!-- CHANGELOG:START -->
### ✨ Ajouts
- L'application vous notifie automatiquement quand une nouvelle version est disponible
- Vous pouvez mettre à jour l'application directement depuis l'app

### 🐛 Corrections
- Correction du problème de redirection au démarrage de l'application
<!-- CHANGELOG:END -->

## 📋 Détails techniques (pour les développeurs)

Cette section peut contenir des détails techniques pour les développeurs, mais ne sera PAS affichée aux utilisateurs.
```

---

## 👨‍💻 Et si j’oublie un label ?

Tu peux toujours :

* Éditer la PR avant merge pour ajouter un label
* Ou merge sans label → aucun impact côté utilisateur


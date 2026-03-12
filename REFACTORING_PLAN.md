# Plan de Refactoring - web_view.dart

## 📊 Analyse actuelle

**Fichier** : `lib/features/manga/views/web_view.dart`  
**Taille** : 2530 lignes  
**Problèmes identifiés** : Violation du principe de responsabilité unique (SRP)

## 🔍 Responsabilités identifiées

### 1. **Gestion du WebView** (~200 lignes)
- Création et configuration du WebView
- Gestion du cycle de vie
- ✅ **OK** : Reste dans la View

### 2. **Blocage de publicités** (~500 lignes)
- Liste de domaines à bloquer (`_denyHosts`)
- Génération de `ContentBlocker` (`_getBlockers`)
- Script JavaScript de blocage (`_buildAdBlockScript`)
- Mode interactif (`_toggleInteractiveAdBlockMode`, `_handleAdBlockClick`)
- ❌ **À extraire** → `AdBlockerService`

### 3. **Gestion du scroll** (~300 lignes)
- Sauvegarde de position (`_saveScrollPosition`)
- Restauration de position (`_restoreScrollPosition`)
- Timer de sauvegarde (`_startScrollSaveTimer`)
- ❌ **À extraire** → `ScrollPositionService` (partagé avec `offline_reader_view.dart`)

### 4. **Détection de captcha** (~100 lignes)
- Détection dans l'URL (`_urlContainsCaptcha`)
- Détection dans le DOM (`_detectAndHandleCaptcha`)
- Gestion de l'état (`_captchaDetected`, `_adBlockerWasEnabled`)
- ❌ **À extraire** → `CaptchaDetectionService`

### 5. **Navigation et détection de chapitres** (~200 lignes)
- Détection de changement de chapitre (`_handleDetected`)
- Gestion de la progression (`_commitIfNeeded`)
- Mise à jour des liens (`_updateNextLinkFrom`)
- Validation de lecture (`_onWillPop`)
- ❌ **À extraire** → `WebViewNavigationService`

### 6. **Téléchargement de chapitres** (~200 lignes)
- Téléchargement depuis WebView (`_downloadCurrentPage`)
- Gestion des cookies (`_saveCookiesForDomain`)
- ✅ **OK** : Utilise déjà `DownloadManagerService` et `ChapterDownloadService`

### 7. **UI et callbacks** (~200 lignes)
- AppBar avec actions
- Dialogs (captcha, saut de chapitres, validation)
- Fallback web (`_buildWebFallback`)
- ✅ **OK** : Reste dans la View

## 🏗️ Architecture proposée

```
lib/features/reader/
├── services/
│   ├── ad_blocker_service.dart          # Blocage de pub
│   ├── scroll_position_service.dart     # Gestion du scroll
│   ├── captcha_detection_service.dart   # Détection captcha
│   └── webview_navigation_service.dart  # Navigation chapitres
├── utils/
│   ├── chapter_link_resolver.dart       # ✅ Existe déjà
│   └── reading_progress_helper.dart     # ✅ Existe déjà
└── views/
    ├── web_view.dart                    # ~500 lignes (au lieu de 2530)
    └── offline_reader_view.dart         # Utilisera aussi ScrollPositionService
```

## 📝 Services à créer

### 1. `AdBlockerService`
**Responsabilités** :
- Gestion de la liste de domaines à bloquer
- Génération de `ContentBlocker`
- Génération du script JavaScript de blocage
- Mode interactif de détection
- Gestion des sélecteurs personnalisés

**Méthodes publiques** :
```dart
class AdBlockerService {
  Future<List<ContentBlocker>> getBlockers({bool enabled = true});
  Future<String> buildAdBlockScript(String? domain);
  Future<void> toggleInteractiveMode(InAppWebViewController controller, bool enabled);
  Future<void> handleAdBlockClick(InAppWebViewController controller, String selector);
  bool isAllowedDomain(String host, String originHost);
  bool shouldBlockRequest(String url);
}
```

### 2. `ScrollPositionService`
**Responsabilités** :
- Sauvegarde de la position de scroll
- Restauration de la position
- Gestion du timer de sauvegarde
- Nettoyage des anciennes positions

**Méthodes publiques** :
```dart
class ScrollPositionService {
  Future<void> saveScrollPosition(InAppWebViewController controller, int muId, int chapter);
  Future<void> restoreScrollPosition(InAppWebViewController controller, int muId, int chapter);
  void startSaveTimer(InAppWebViewController controller, int muId, int chapter, {Duration interval = const Duration(seconds: 5)});
  void stopSaveTimer();
  Future<void> deleteScrollPosition(int muId, int chapter);
  Future<void> cleanOldPositions(int muId, int currentChapter);
}
```

### 3. `CaptchaDetectionService`
**Responsabilités** :
- Détection de captcha dans l'URL
- Détection de captcha dans le DOM
- Gestion de l'état du bloqueur lors de la détection

**Méthodes publiques** :
```dart
class CaptchaDetectionService {
  bool urlContainsCaptcha(String url);
  bool isCaptchaDomain(String host);
  Future<String?> detectCaptcha(InAppWebViewController controller);
  Future<bool> isCaptchaResolved(InAppWebViewController controller, WebUri url);
}
```

### 4. `WebViewNavigationService`
**Responsabilités** :
- Détection de changement de chapitre
- Gestion de la progression de lecture
- Mise à jour des liens personnalisés
- Validation de lecture

**Méthodes publiques** :
```dart
class WebViewNavigationService {
  Future<void> handleChapterChange(Uri uri, int? currentChapter, int lastCommitted, {
    required Function(int) onChapterDetected,
    required Function(int) onCommitChapter,
    required Function(String, {int? currentChapter}) onUpdateLink,
  });
  Future<bool?> promptJumpConfirm(BuildContext context, {required int prev, required int next});
  Future<bool> validateReading(BuildContext context, InAppWebViewController controller, int chapter, int lastCommitted);
  bool sameProvider(String a, String b);
}
```

## 🎯 Bénéfices attendus

1. **Réduction de la taille** : `web_view.dart` passera de 2530 à ~500 lignes
2. **Réutilisabilité** : Services réutilisables dans `offline_reader_view.dart`
3. **Testabilité** : Services testables indépendamment
4. **Maintenabilité** : Code organisé selon l'architecture feature-based
5. **Séparation des responsabilités** : Chaque service a une responsabilité unique

## 📋 Ordre de refactoring recommandé

1. ✅ **ScrollPositionService** (priorité haute - utilisé par 2 fichiers)
2. ✅ **AdBlockerService** (priorité haute - ~500 lignes)
3. ✅ **CaptchaDetectionService** (priorité moyenne)
4. ✅ **WebViewNavigationService** (priorité moyenne)
5. ✅ **Refactoriser ReaderWebView** pour utiliser les services

## ⚠️ Points d'attention

- Les services doivent être enregistrés dans `service_locator.dart`
- Préserver la compatibilité avec `offline_reader_view.dart`
- Les scripts JavaScript peuvent rester dans `AdBlockerService` ou être dans des fichiers `.js` séparés
- Tester chaque service indépendamment avant l'intégration


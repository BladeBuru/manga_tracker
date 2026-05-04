# `pubspec.yaml` — Vérifications avant ajout d'une dépendance

> Snippet injecté quand vous éditez `pubspec.yaml`.

## Règle d'or (évolution iOS/Web)

**Avant d'ajouter un package**, vérifier sa **compatibilité plateforme** sur pub.dev :
- Android ✅
- iOS ✅
- Web ✅

L'app cible aujourd'hui Android, mais iOS et Web sont planifiés. **Un package Android-only sans alternative cross-platform = drapeau rouge.**

## Checklist avant ajout

- [ ] Le package est-il sur pub.dev avec un **score Pub Points élevé** (≥ 130) ?
- [ ] **Plateformes supportées** : Android + iOS + Web (sinon documenter pourquoi et abstraire) ?
- [ ] **Maintenu activement** : dernière version < 12 mois ?
- [ ] **Licence compatible** (MIT, Apache 2.0, BSD) ?
- [ ] **Pas de doublon** avec un package déjà présent ?
- [ ] **Surface d'API minimale** : pas un méga-package qui fait dix choses ?

## Packages Android-only actuels (à abstraire)

L'audit a relevé :

| Package | Plateforme | Action |
|---------|-----------|--------|
| `workmanager` | Android-only | À abstraire derrière `BackgroundTaskService` (impl iOS via BGTaskScheduler, web via service worker) |
| `flutter_local_notifications` (avec `AndroidFlutterLocalNotificationsPlugin` explicite) | Multi-plateforme mais usage Android-spécifique | Forcer Darwin fallback pour iOS dans `notification_service.dart` |
| `android_intent_plus` | Android-only | Vérifier qu'il est vraiment utilisé. Si non utilisé → retirer |
| `local_auth` | iOS + Android | OK |
| `flutter_secure_storage` | iOS + Android + Web | OK |

## Sécurité

- ❌ **JAMAIS** committer un package fork sans audit de sécurité.
- ❌ **JAMAIS** un package avec dépendances natives non auditées (les `.aar` Android tiers).
- ✅ Vérifier les vulnérabilités connues : `dart pub outdated`, `dart pub deps`, audit GitHub.

## Versionning

- ✅ Pin avec `^x.y.z` (compat semver) — pas `>=` lâche.
- ✅ Mettre à jour `pubspec.lock` (versionné).

## Si vous ajoutez un package

1. Documenter dans `.claude/memory-bank/decisions.md` (section "Décisions Prises") :
   - Pourquoi ce package
   - Alternative considérée
   - Plateformes supportées
2. Si Android-only : créer l'abstraction dans `core/services/` (interface + impl conditionnelle).
3. Mettre à jour `.claude/memory-bank/architecture.md` si stack significativement modifiée.

## Plateformes prises en charge dans `pubspec.yaml`

À terme, vérifier que `flutter:` déclare bien :

```yaml
flutter:
  uses-material-design: true
  generate: true
  # Pour iOS/Web futur :
  # assets:
  #   - assets/icons/
```

Et que les configs `android/`, `ios/`, `web/` sont synchronisées avec la `version:` du pubspec.

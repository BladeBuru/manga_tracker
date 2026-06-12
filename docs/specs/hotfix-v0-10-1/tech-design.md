# Tech Design — Hotfix v0.10.1 (Flutter)

> Intention technique avant implémentation. Décisions D1 (volet client), D4, D5 (volet front), D6
> (la numérotation D1-D6 est partagée avec la spec API `API-mangaTracker/docs/specs/hotfix-v0-10-1/`).

---

## D1 (volet client) — Toutes les images via le proxy, mode stream sur web

**Problème** : `manga_card.dart:150-156` charge l'URL MU brute (`useProxy: false`) → CORS bloqué sur web. Et même via le proxy, le 302 vers le CDN MU reste bloqué en CanvasKit (le navigateur exige les headers CORS sur la réponse finale).

**Décision** :
- `useProxy: true` partout (uniformise aussi mobile : un seul chemin de chargement, le fallback `refresh-cover` existant reste le filet).
- `refreshable_manga_image.dart` ajoute `mode=stream` aux query params **uniquement si `kIsWeb`** — le mobile garde le 302 (plus rapide, pas de bande passante serveur).

**Écarté** : renderer HTML (casse cached_network_image), URLs MU directes avec crossOrigin (le CDN MU n'enverra jamais les headers).

## D4 — Seuil de lecture unique à 85 %

**Problème vérifié** : popup « fini ? » si `percentageFromEnd <= 15` (`reading_progress_helper.dart:35`) mais rejet de sauvegarde si `percentage > 95` (`scroll_position_service.dart:89,254`). Les deux échelles sont inversées (% restant vs % position) et laissent un trou : à 90 % de position, l'utilisateur n'est ni sauvegardé ni détecté en fin.

**Décision** : une seule constante `kReadingEndThresholdPercent = 85`, une seule échelle (% de position depuis le haut) :
- position < 85 % → zone « lecture en cours » : sauvegarde/restauration du scroll
- position ≥ 85 % → zone « fin de chapitre » : pas de sauvegarde, popup de validation au retour

**Pourquoi 85** : la fin d'un scan contient commentaires/credits (~10-15 % de la page) ; 85 % couvre la fin réelle de lecture sans faux positifs en milieu de chapitre. Ajustable en une seule ligne si feedback.

**Bonus fiabilité** (audit) : timeout images 5 s → 10 s (`maxAttempts` 25 → 50) ; fallback iframe `window.parent.scrollY` avec try/catch (cross-origin lève) ; en cas d'échec total de mesure → ne PAS afficher la popup (préférer un faux négatif à un faux « chapitre fini »).

## D5 (volet front) — TTL réel sur le cache recos

**Problème vérifié** : `isCacheExpired()` (`offline_cache_service.dart:317-319`) est un stub legacy qui retourne `false` ; le service recos ne vérifie aucun TTL → refetch complet à chaque retour sur la page ; la pagination refetch des pages déjà chargées.

**Décision** :
- Utiliser la méthode existante et fonctionnelle `isCacheExpiredFor('recommendations', maxHours: 2)` (lignes 380-393) dans le service recos — stale-while-revalidate cohérent avec RETRO-005.
- Supprimer le stub `isCacheExpired()` (grep des usages d'abord — l'audit indique qu'il n'est pas appelé).
- Cache in-memory par page (`Map<int, List>`) dans la vue paginée, durée de vie = celle de la vue.
- TTL 2 h front vs 1 h back (D5 API) : le front peut servir un cache légèrement plus vieux, le back garantit la fraîcheur réelle.

## D6 — Investigation tablette Huawei (PAS de fix aveugle)

**Contexte** : l'audit API a **infirmé** l'hypothèse de révocation de session côté serveur (sessions indépendantes, rotation propre, preuves `auth.helper.ts:54-61`, `auth.service.ts:109-137`). La déconnexion répétée de la tablette Huawei vient donc du client.

**Hypothèse principale** : `flutter_secure_storage` s'appuie sur le keystore Android ; sur EMUI/HarmonyOS sans Google Services, des pertes de clés au reboot/mise à jour sont documentées par la communauté → tokens perdus → re-login forcé.

**Décision** : instrumenter avant de corriger.
1. Logs diagnostiques (debugPrint en build debug uniquement) : présence/longueur des tokens au boot, après refresh, après retour de background. **Jamais le contenu des tokens** (règle RGPD projet).
2. Builder un APK debug, tester sur la tablette de l'utilisateur, collecter le log d'une session jusqu'à la déconnexion.
3. Selon le résultat : fallback storage (ex. `shared_preferences` chiffré AES avec clé dérivée) ou patch de config `flutter_secure_storage` (option `encryptedSharedPreferences: true` sur Android — connue pour stabiliser EMUI).

**Pourquoi pas de fix direct** : changer le storage des tokens sans diagnostic risque une déconnexion massive de TOUS les utilisateurs Android à la migration. Le coût d'un APK debug est faible.

---

## Ordre d'implémentation conseillé

1. US-1 autofill (2 fichiers, zéro risque)
2. US-2 images web (dépend du déploiement API US-2 — coordonner)
3. US-3 masque email (helper + ARB)
4. US-4 seuils lecture (tests unitaires obligatoires)
5. US-5 cache recos + bandeau cold start
6. D6 instrumentation (en parallèle, APK debug pour la tablette)

Release `v0.10.1` via `/release` (bump patch) une fois les US validées sur Android + Web, light + dark.

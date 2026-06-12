# RETRO-023 — Stratégie offline : HTML complet avec réécriture des URLs d'images en chemins locaux

| Champ      | Valeur                          |
|------------|---------------------------------|
| Statut     | Documenté (rétro)               |
| Date       | 2026-06-04                      |
| Source     | Rétro-ingénierie                |
| Features   | download                        |

## Justification (politique ADR v2.3.0)

| Champ | Valeur |
|-------|--------|
| Catégorie | DATA-MODEL |
| Q1 — Coût de revert > 1j ? | OUI — Changer la stratégie (ex : ne stocker que les images en liste ordonnée, ou produire un PDF, ou stocker le JSON des images depuis une API) implique de réécrire `processHtmlForOffline()` (logique DOM), de changer le modèle `DownloadedChapter` (supprimer `htmlPath`, ajouter d'autres champs), de modifier le lecteur offline (`offline_reader_view.dart` qui charge un fichier HTML via WebView), et de migrer les données existantes. Plus d'une journée transverse. |
| Q2 — Non-déductible du code ? | OUI — `pubspec.yaml` montre `package:html` (pour le parsing) mais ne dit pas pourquoi on télécharge le HTML entier plutôt que d'appeler une éventuelle API qui fournirait une liste d'URLs d'images. La décision de télécharger la page web telle quelle (pour préserver la mise en page, le CSS, les scripts du site) n'est lisible que dans le code et cet ADR. |
| Q3 — Impact transverse (≥ 2 specs) ? | OUI — La feature `download` produit le bundle `chapter.html` + `images/` ; la feature `reader` (spec `offline_reader`) consomme ce bundle en chargeant `htmlPath` dans une WebView locale. Le format du bundle est le contrat entre les deux features. |
| Q4 — Casse un invariant si ignoré ? | OUI — Le lecteur offline (`offline_reader_view.dart`) s'attend à ouvrir un `chapter.html` via une WebView locale. Si un dev modifie le téléchargement pour ne sauvegarder que les images (sans HTML) sans adapter le lecteur, la lecture offline est cassée silencieusement : la WebView ouvre un fichier inexistant ou un HTML vide. |

> Validé contre la politique `.claude/rules/06-adr-policy.md`.

## Contexte

Les chapitres de manga sont hébergés sur des sites tiers avec des mises en page variées, des scripts de défilement, et des images chargées dynamiquement (lazy loading via `data-src`, `data-lazy-src`, etc.). Il n'existe pas d'API unifiée fournissant une liste ordonnée des images d'un chapitre pour tous les sites supportés.

Deux approches principales étaient envisageables :
1. Extraire uniquement les URLs d'images depuis le HTML, les télécharger en liste ordonnée et afficher les images dans un lecteur custom Flutter.
2. Télécharger la page HTML entière, réécrire les URLs des images en chemins locaux, et ouvrir le HTML dans une WebView locale.

## Décision identifiée

L'approche **HTML complet avec réécriture d'URLs** a été retenue. `ChapterDownloadService.processHtmlForOffline()` :

1. Parse le HTML de la page de chapitre via `package:html`.
2. Pour chaque balise `<img>`, résout l'URL source en absolu (gère les URLs relatives, `//`-prefixed, et absolues). Inspecte en priorité : `src`, `data-src`, `data-lazy-src`, `data-original`, `data-url`, `data-image` (couverture des patterns de lazy loading courants).
3. Télécharge l'image (HTTP GET sans auth) dans `images/<filename>` et remplace l'attribut `src` par un chemin relatif local.
4. Traite également les balises `<source srcset="...">` (images responsives) en téléchargeant le premier candidat du srcset.
5. Supprime les attributs de lazy loading (`loading`, `data-src`, `data-lazy-src`).
6. Injecte `<base href="file://<chapterPath>/">` dans le `<head>` pour résoudre les ressources CSS/JS restantes.
7. Retourne le HTML complet reconstruit (`<!DOCTYPE html><html>...</html>`).

Le bundle résultant est : `chapter.html` (auto-contenu pour les images) + `images/<n>.ext`.

## Conséquences observées

### Positives
- Compatible avec tous les sites tiers sans nécessiter d'API ni de scraping spécifique par site.
- Préserve la mise en page et les interactions CSS/JS du site source (navigation entre pages, contrôles de zoom propres au site).
- Lecture offline identique à la lecture en ligne (même WebView, même rendu).

### Négatives / Dette
- Les ressources CSS, JS, polices non téléchargées sont manquantes hors-ligne (seules les images sont localisées). La mise en page peut être dégradée si le CSS du site est sur un CDN externe.
- Le champ `imageCount` du modèle est initialisé à 0 et jamais mis à jour — dette connue.
- Les images qui répondent 403 (protection anti-bot) sont ignorées silencieusement — le chapitre est marqué `completed` même si des images manquent.
- Pas de déduplication des images : si deux balises `<img>` pointent vers la même URL, l'image est téléchargée deux fois (mais écrasée — `imageFile.exists()` guard présent).
- La taille des bundles peut être significative (100–500 Mo pour les longs chapitres avec images HD).

## Recommandation

Garder. Cette stratégie est la seule viable sans API tierce. Pour améliorer la robustesse : (1) mettre à jour `imageCount` après le traitement, (2) logger les images manquantes dans `errorMessage`, (3) proposer un feedback utilisateur sur les images non téléchargées.
